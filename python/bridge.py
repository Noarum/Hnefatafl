"""SWI-Prolog bridge via pyswip. Expects predicates from controller.pl (see class docstring)."""

from __future__ import annotations

import random
from pathlib import Path
from typing import Any

from pyswip import Prolog


class HnefataflBridge:
    """Bridge to Prolog controller predicates.

    Assumes ``controller.pl`` defines (or will define):

    - ``init_game/0`` — set up dynamic game state
    - ``get_board/1`` — unifies ``Board`` with a list of rows (each row a list of piece atoms)
    - ``get_current_player/1`` — ``attacker`` or ``defender`` (atoms)
    - ``get_game_status/1`` — status atom, e.g. ``ongoing``, ``attacker_won``, ``defender_won``
    - ``make_human_move/4`` — ``FR, FC, TR, TC`` (integer coordinates, 0-based)
    - ``make_ai_move/1`` — difficulty atom: ``easy``, ``medium``, or ``hard``
    """

    def __init__(self) -> None:
        self._prolog = Prolog()
        self._prolog_dir = Path(__file__).resolve().parent.parent / "prolog"
        self._controller_path = self._prolog_dir / "controller.pl"
        self._consult_controller()
        self._init_game()

    def _consult_controller(self) -> None:
        if not self._controller_path.is_file():
            raise FileNotFoundError(
                f"Prolog controller not found: {self._controller_path}"
            )
        # Absolute path so SWI resolves sibling consults relative to controller.pl's directory.
        self._prolog.consult(str(self._controller_path.resolve()))

    def _init_game(self) -> None:
        try:
            solutions = list(self._prolog.query("init_game"))
        except Exception as e:  # noqa: BLE001 — surface Prolog/SWI errors clearly
            raise RuntimeError(
                "Failed to run init_game/0. Is controller.pl implemented and loadable?"
            ) from e
        if not solutions:
            raise RuntimeError(
                "init_game/0 failed (no solution). Check Prolog game initialization."
            )

    @staticmethod
    def _atom_to_str(x: Any) -> str:
        if hasattr(x, "value"):
            return str(x.value)
        if isinstance(x, bytes):
            return x.decode("utf-8", errors="replace")
        s = str(x)
        if len(s) >= 2 and s[0] == s[-1] == "'":
            return s[1:-1]
        return s

    def _parse_board(self, raw_result: list[dict[str, Any]]) -> list[tuple[int, int, str]]:
        """Parse board query output into a list of (row, col, piece_type).

        Expected raw pyswip shape (example):
        [
            {
                'Board': [
                    ['c', 'e', ...],   # row 0
                    ...
                ]
            }
        ]

        Atoms may appear as strings or pyswip ``Atom`` objects depending on version.
        """
        if not raw_result:
            return []
        board = raw_result[0].get("Board")
        if board is None:
            return []
        out: list[tuple[int, int, str]] = []
        for r, row in enumerate(board):
            if row is None:
                continue
            for c, cell in enumerate(row):
                piece = self._atom_to_str(cell).lower()
                if piece in ("e", "", "_"):
                    continue
                out.append((r, c, piece))
        return out

    def get_board(self) -> list[tuple[int, int, str]]:
        """Return occupied cells as (row, col, piece_type_string)."""
        try:
            raw = list(self._prolog.query("get_board(Board)"))
        except Exception as e:  # noqa: BLE001
            raise RuntimeError("get_board/1 query failed.") from e
        return self._parse_board(raw)

    def human_move(self, fr: int, fc: int, tr: int, tc: int) -> bool:
        """Apply a human move; return True if Prolog reports success."""
        q = f"make_human_move({int(fr)}, {int(fc)}, {int(tr)}, {int(tc)})"
        try:
            return bool(list(self._prolog.query(q)))
        except Exception as e:  # noqa: BLE001
            raise RuntimeError(f"make_human_move/4 query failed: {q}") from e

    def ai_move(self, difficulty: str = "medium") -> None:
        """Run the AI turn for the current side."""
        diff = difficulty.strip().lower()
        if diff not in ("easy", "medium", "hard"):
            raise ValueError("difficulty must be easy, medium, or hard")
        q = f"make_ai_move({diff})"
        try:
            solutions = list(self._prolog.query(q))
        except Exception as e:  # noqa: BLE001
            raise RuntimeError(f"make_ai_move/1 query failed: {q}") from e
        if not solutions:
            raise RuntimeError(f"make_ai_move/1 failed (no solution) for {diff!r}")

    def current_player(self) -> str:
        """Return ``attacker`` or ``defender`` (lowercase string)."""
        try:
            raw = list(self._prolog.query("get_current_player(P)"))
        except Exception as e:  # noqa: BLE001
            raise RuntimeError("get_current_player/1 query failed.") from e
        if not raw:
            raise RuntimeError("get_current_player/1 had no binding.")
        return self._atom_to_str(raw[0]["P"]).lower()

    def game_status(self) -> str:
        """Return game status as a lowercase string (atom from Prolog)."""
        try:
            raw = list(self._prolog.query("get_game_status(S)"))
        except Exception as e:  # noqa: BLE001
            raise RuntimeError("get_game_status/1 query failed.") from e
        if not raw:
            raise RuntimeError("get_game_status/1 had no binding.")
        return self._atom_to_str(raw[0]["S"]).lower()


# --- GUI / integration testing without Prolog --------------------------------

def _initial_mock_grid_11() -> list[list[str]]:
    """11×11 layout aligned with ``prolog/Hnefatafl.pl`` ``initial_board_11``; throne holds ``k`` for rendering."""
    rows = [
        list("ceebbbbbeeec"),
        list("eeeeebeeeeee"),
        list("eeeeeweeeeee"),
        list("beeeeweeeeeb"),
        list("beeeeweeeeeb"),
        list("bbeeekeeebb"),  # king on throne (Prolog uses ``t``; GUI draws ``k``)
        list("beeeeweeeeeb"),
        list("beeeeweeeeeb"),
        list("eeeeeweeeeee"),
        list("eeeeebeeeeee"),
        list("ceebbbbbeeec"),
    ]
    return rows


class MockHnefataflBridge:
    """In-memory stand-in for `HnefataflBridge` when Prolog `controller.pl` is not ready.

    Supports orthogonal slides with a clear path (no real capture / win rules).
    Use this only to exercise the Pygame UI.
    """

    _MOVERS = frozenset("bwk")

    def __init__(self) -> None:
        self._grid: list[list[str]] = _initial_mock_grid_11()
        self._current: str = "attacker"
        self._status: str = "ongoing"

    def _cell(self, r: int, c: int) -> str:
        return self._grid[r][c]

    def _set_cell(self, r: int, c: int, ch: str) -> None:
        self._grid[r][c] = ch

    def get_board(self) -> list[tuple[int, int, str]]:
        out: list[tuple[int, int, str]] = []
        for r in range(11):
            for c in range(11):
                p = self._cell(r, c).lower()
                if p in self._MOVERS:
                    out.append((r, c, p))
        return out

    @staticmethod
    def _owner(piece: str) -> str | None:
        p = piece.lower()
        if p == "b":
            return "attacker"
        if p in ("w", "k"):
            return "defender"
        return None

    def current_player(self) -> str:
        return self._current

    def game_status(self) -> str:
        return self._status

    def _path_clear(self, fr: int, fc: int, tr: int, tc: int) -> bool:
        if fr == tr:
            lo, hi = sorted((fc, tc))
            for c in range(lo + 1, hi):
                if self._cell(fr, c).lower() in self._MOVERS:
                    return False
            return True
        if fc == tc:
            lo, hi = sorted((fr, tr))
            for r in range(lo + 1, hi):
                if self._cell(r, fc).lower() in self._MOVERS:
                    return False
            return True
        return False

    def human_move(self, fr: int, fc: int, tr: int, tc: int) -> bool:
        if self._status != "ongoing":
            return False
        piece = self._cell(fr, fc).lower()
        if self._owner(piece) != self._current:
            return False
        if (fr, fc) == (tr, tc):
            return False
        if fr != tr and fc != tc:
            return False
        dest = self._cell(tr, tc).lower()
        if dest != "e":
            return False
        if not self._path_clear(fr, fc, tr, tc):
            return False

        self._set_cell(tr, tc, piece)
        self._set_cell(fr, fc, "e")
        self._current = "defender" if self._current == "attacker" else "attacker"
        return True

    def ai_move(self, difficulty: str = "medium") -> None:
        del difficulty  # mock ignores difficulty
        if self._status != "ongoing":
            return
        moves: list[tuple[int, int, int, int]] = []
        for r in range(11):
            for c in range(11):
                p = self._cell(r, c).lower()
                if self._owner(p) != self._current:
                    continue
                for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    for step in range(1, 11):
                        tr, tc = r + dr * step, c + dc * step
                        if tr < 0 or tc < 0 or tr > 10 or tc > 10:
                            break
                        mid = self._cell(tr, tc).lower()
                        if mid in self._MOVERS:
                            break
                        if mid == "e":
                            moves.append((r, c, tr, tc))
        if not moves:
            return
        fr, fc, tr, tc = random.choice(moves)
        piece = self._cell(fr, fc).lower()
        self._set_cell(tr, tc, piece)
        self._set_cell(fr, fc, "e")
        self._current = "defender" if self._current == "attacker" else "attacker"
