"""
bridge.py — SWI-Prolog ↔ Python bridge via pyswip.

Coordinate convention (matches controller.pl public API):
    All public methods use (row, col) order — row first.
    The Prolog controller swaps to internal (col, row) before calling
    get_piece/valid_move/apply_move.

Prolog predicates expected (defined in controller.pl):
    init_game/0
    get_board/1            → Board = list-of-rows, each row a list of atoms
    get_current_player/1   → attacker | defender
    get_game_status/1      → ongoing | attacker_won | defender_won
    make_human_move/4      → make_human_move(FromRow, FromCol, ToRow, ToCol)
    make_ai_move/1         → make_ai_move(easy | medium | hard)
    get_valid_moves_for_piece/3  → get_valid_moves_for_piece(Row, Col, Moves)
                                   Moves = list of move(ToRow, ToCol)
"""

from __future__ import annotations

import random
from pathlib import Path
from typing import Any

from pyswip import Prolog


# ---------------------------------------------------------------------------
# Real Bridge (connects to SWI-Prolog)
# ---------------------------------------------------------------------------

class HnefataflBridge:
    """Bridge to Prolog controller predicates."""

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
        self._prolog.consult(str(self._controller_path.resolve()))

    def _init_game(self) -> None:
        try:
            list(self._prolog.query("init_game"))
        except Exception as e:
            raise RuntimeError(
                "Failed to run init_game/0. Is controller.pl loadable?"
            ) from e

    # ------------------------------------------------------------------
    # Atom parsing helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _atom(x: Any) -> str:
        """Convert a pyswip value (Atom, bytes, or str) to a plain str."""
        if hasattr(x, "value"):          # pyswip Atom
            return str(x.value)
        if isinstance(x, bytes):
            return x.decode("utf-8", errors="replace")
        s = str(x)
        # Strip surrounding single-quotes if present
        if len(s) >= 2 and s[0] == "'" == s[-1]:
            return s[1:-1]
        return s

    def _parse_board(self, raw: list[dict[str, Any]]) -> list[tuple[int, int, str]]:
        """
        Parse get_board/1 result into [(row, col, piece_str), ...].

        Expected raw pyswip shape:
            [{'Board': [[atom, atom, ...], ...]}]

        Skips: e (empty), t (vacant throne), c (corner marker).
        Returns only actual pieces: b, w, k.
        """
        if not raw:
            return []
        board = raw[0].get("Board")
        if board is None:
            return []

        out: list[tuple[int, int, str]] = []
        for r, row in enumerate(board):
            if row is None:
                continue
            for c, cell in enumerate(row):
                piece = self._atom(cell).lower()
                if piece in ("b", "w", "k"):
                    out.append((r, c, piece))
        return out

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def get_board(self) -> list[tuple[int, int, str]]:
        """Return occupied cells as (row, col, piece_str)."""
        try:
            raw = list(self._prolog.query("get_board(Board)"))
        except Exception as e:
            raise RuntimeError("get_board/1 query failed.") from e
        return self._parse_board(raw)

    def human_move(self, fr: int, fc: int, tr: int, tc: int) -> bool:
        """
        Apply human move from (fr,fc) to (tr,tc).
        Returns True on success, False on illegal move.
        """
        q = f"make_human_move({int(fr)}, {int(fc)}, {int(tr)}, {int(tc)})"
        try:
            # make_human_move/4 succeeds (returns [{}]) on legal move,
            # fails (returns []) on illegal move.
            result = list(self._prolog.query(q))
            return len(result) > 0
        except Exception as e:
            raise RuntimeError(f"make_human_move/4 query failed: {q}") from e

    def ai_move(self, difficulty: str = "medium") -> None:
        """
        Run the AI turn.
        Does NOT raise if AI has no moves (that's a valid game-over state).
        """
        diff = difficulty.strip().lower()
        if diff not in ("easy", "medium", "hard"):
            raise ValueError("difficulty must be easy, medium, or hard")
        q = f"make_ai_move({diff})"
        try:
            list(self._prolog.query(q))
            # We intentionally ignore the return value:
            # - [] means no moves (AI forfeits) — controller.pl handles the status update
            # - [{}] means move was applied successfully
        except Exception as e:
            raise RuntimeError(f"make_ai_move/1 query failed: {q}") from e

    def current_player(self) -> str:
        """Return 'attacker' or 'defender'."""
        try:
            raw = list(self._prolog.query("get_current_player(P)"))
        except Exception as e:
            raise RuntimeError("get_current_player/1 query failed.") from e
        if not raw:
            raise RuntimeError("get_current_player/1 had no binding.")
        return self._atom(raw[0]["P"]).lower()

    def game_status(self) -> str:
        """Return 'ongoing', 'attacker_won', or 'defender_won'."""
        try:
            raw = list(self._prolog.query("get_game_status(S)"))
        except Exception as e:
            raise RuntimeError("get_game_status/1 query failed.") from e
        if not raw:
            raise RuntimeError("get_game_status/1 had no binding.")
        return self._atom(raw[0]["S"]).lower()

    def get_valid_moves_for_piece(self, row: int, col: int) -> list[tuple[int, int]]:
        """
        Return list of (to_row, to_col) the piece at (row,col) can legally move to.
        Used by the GUI to highlight valid destination squares.
        Returns [] on any failure (graceful degradation).
        """
        q = f"get_valid_moves_for_piece({int(row)}, {int(col)}, Moves)"
        try:
            raw = list(self._prolog.query(q))
        except Exception:
            return []
        if not raw:
            return []

        moves_raw = raw[0].get("Moves", [])
        result: list[tuple[int, int]] = []
        for m in moves_raw:
            # Each move is a compound term move(ToRow, ToCol)
            try:
                args = m.args  # pyswip compound term
                tr = int(args[0])
                tc = int(args[1])
                result.append((tr, tc))
            except (AttributeError, IndexError, TypeError):
                pass
        return result


# ---------------------------------------------------------------------------
# Mock Board (for GUI testing without Prolog)
# ---------------------------------------------------------------------------

def _initial_mock_grid() -> list[list[str]]:
    """
    Correct 11×11 layout matching Hnefatafl.pl initial_board_11.
    Defenders (w): rows 1-4 and 6-9 at col 5, plus row 5 at cols 3,4,6,7 → 12 pieces ✓
    Attackers (b): 24 pieces ✓
    King (k): center (row 5, col 5) ✓
    Corner marker (c), empty (e).
    """
    #         col: 0    1    2    3    4    5    6    7    8    9   10
    return [
        ['c', 'e', 'e', 'b', 'b', 'b', 'b', 'b', 'e', 'e', 'c'],  # row 0
        ['e', 'e', 'e', 'e', 'e', 'w', 'e', 'e', 'e', 'e', 'e'],  # row 1
        ['e', 'e', 'e', 'e', 'e', 'w', 'e', 'e', 'e', 'e', 'e'],  # row 2
        ['b', 'e', 'e', 'e', 'e', 'w', 'e', 'e', 'e', 'e', 'b'],  # row 3
        ['b', 'e', 'e', 'e', 'e', 'w', 'e', 'e', 'e', 'e', 'b'],  # row 4
        ['b', 'b', 'e', 'w', 'w', 'k', 'w', 'w', 'e', 'b', 'b'],  # row 5
        ['b', 'e', 'e', 'e', 'e', 'w', 'e', 'e', 'e', 'e', 'b'],  # row 6
        ['b', 'e', 'e', 'e', 'e', 'w', 'e', 'e', 'e', 'e', 'b'],  # row 7
        ['e', 'e', 'e', 'e', 'e', 'w', 'e', 'e', 'e', 'e', 'e'],  # row 8
        ['e', 'e', 'e', 'e', 'e', 'w', 'e', 'e', 'e', 'e', 'e'],  # row 9
        ['c', 'e', 'e', 'b', 'b', 'b', 'b', 'b', 'e', 'e', 'c'],  # row 10
    ]


class MockHnefataflBridge:
    """
    In-memory stand-in for HnefataflBridge.
    Use --mock flag to run GUI without SWI-Prolog.

    Rules implemented:
    - Orthogonal rook movement with path-clear check
    - Restricted squares (corners, throne): only king may stop there
    - Basic custodial capture (sandwich between two opponents or wall)
    - King win: reaches a corner
    - King loss: surrounded on all 4 sides by attackers/walls/corners
    """

    _BOARD_SIZE = 11
    _CORNERS = {(0, 0), (0, 10), (10, 0), (10, 10)}
    _THRONE = (5, 5)
    _PIECES = frozenset("bwk")

    def __init__(self) -> None:
        self._grid: list[list[str]] = _initial_mock_grid()
        self._current: str = "attacker"
        self._status: str = "ongoing"

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _cell(self, r: int, c: int) -> str:
        return self._grid[r][c]

    def _set(self, r: int, c: int, v: str) -> None:
        self._grid[r][c] = v

    def _in_bounds(self, r: int, c: int) -> bool:
        return 0 <= r < self._BOARD_SIZE and 0 <= c < self._BOARD_SIZE

    def _is_restricted(self, r: int, c: int) -> bool:
        return (r, c) in self._CORNERS or (r, c) == self._THRONE

    @staticmethod
    def _owner(piece: str) -> str | None:
        p = piece.lower()
        if p == "b":
            return "attacker"
        if p in ("w", "k"):
            return "defender"
        return None

    def _path_clear(self, fr: int, fc: int, tr: int, tc: int) -> bool:
        if fr == tr:
            lo, hi = sorted((fc, tc))
            return all(
                self._cell(fr, c).lower() not in self._PIECES
                for c in range(lo + 1, hi)
            )
        if fc == tc:
            lo, hi = sorted((fr, tr))
            return all(
                self._cell(r, fc).lower() not in self._PIECES
                for r in range(lo + 1, hi)
            )
        return False

    def _is_hostile_to(self, r: int, c: int, player: str) -> bool:
        """True if (r,c) is hostile to the given player (enemy piece, wall, corner)."""
        if not self._in_bounds(r, c):
            return True   # wall
        cell = self._cell(r, c).lower()
        if (r, c) in self._CORNERS:
            return True   # corners are hostile to everyone for capture
        opp = "attacker" if player == "defender" else "defender"
        return self._owner(cell) == opp

    def _apply_captures(self, r: int, c: int, player: str) -> None:
        """Custodial capture: check all 4 directions after a piece lands at (r,c)."""
        piece = self._cell(r, c).lower()
        if piece == "k":
            return  # king is unarmed — does not participate in captures

        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            mr, mc = r + dr, c + dc   # middle (potential victim)
            er, ec = r + 2*dr, c + 2*dc  # other side

            if not self._in_bounds(mr, mc):
                continue
            mid = self._cell(mr, mc).lower()
            if self._owner(mid) != ("attacker" if player == "defender" else "defender"):
                continue
            if mid == "k":
                continue  # king captured separately

            # Other side must be hostile to the victim
            if self._is_hostile_to(er, ec, self._owner(mid) or player):
                self._set(mr, mc, "e")

    def _king_captured(self) -> bool:
        """Check if king is surrounded on all relevant sides."""
        for r in range(self._BOARD_SIZE):
            for c in range(self._BOARD_SIZE):
                if self._cell(r, c).lower() != "k":
                    continue
                hostile = 0
                for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    nr, nc = r + dr, c + dc
                    if not self._in_bounds(nr, nc):
                        hostile += 1  # wall
                        continue
                    cell = self._cell(nr, nc).lower()
                    if cell == "b" or (nr, nc) in self._CORNERS or (nr, nc) == self._THRONE and cell == "e":
                        hostile += 1
                return hostile >= 4
        return True   # king not on board = captured

    def _king_escaped(self) -> bool:
        for r, c in self._CORNERS:
            if self._cell(r, c).lower() == "k":
                return True
        return False

    def _check_win(self) -> str | None:
        if self._king_escaped():
            return "defender_won"
        if self._king_captured():
            return "attacker_won"
        return None

    def _get_moves(self, player: str) -> list[tuple[int, int, int, int]]:
        moves: list[tuple[int, int, int, int]] = []
        for r in range(self._BOARD_SIZE):
            for c in range(self._BOARD_SIZE):
                piece = self._cell(r, c).lower()
                if self._owner(piece) != player:
                    continue
                for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                    for step in range(1, self._BOARD_SIZE):
                        tr, tc = r + dr * step, c + dc * step
                        if not self._in_bounds(tr, tc):
                            break
                        dest = self._cell(tr, tc).lower()
                        if dest in self._PIECES:
                            break
                        if self._is_restricted(tr, tc) and piece != "k":
                            # Non-king can pass through but not stop here
                            continue
                        moves.append((r, c, tr, tc))
        return moves

    def get_valid_moves_for_piece(self, row: int, col: int) -> list[tuple[int, int]]:
        piece = self._cell(row, col).lower()
        if piece not in self._PIECES:
            return []
        result = []
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            for step in range(1, self._BOARD_SIZE):
                tr, tc = row + dr * step, col + dc * step
                if not self._in_bounds(tr, tc):
                    break
                dest = self._cell(tr, tc).lower()
                if dest in self._PIECES:
                    break
                if self._is_restricted(tr, tc) and piece != "k":
                    continue
                result.append((tr, tc))
        return result

    # ------------------------------------------------------------------
    # Public API (mirrors HnefataflBridge)
    # ------------------------------------------------------------------

    def get_board(self) -> list[tuple[int, int, str]]:
        out = []
        for r in range(self._BOARD_SIZE):
            for c in range(self._BOARD_SIZE):
                p = self._cell(r, c).lower()
                if p in self._PIECES:
                    out.append((r, c, p))
        return out

    def current_player(self) -> str:
        return self._current

    def game_status(self) -> str:
        return self._status

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
        if dest in self._PIECES:
            return False
        if self._is_restricted(tr, tc) and piece != "k":
            return False
        if not self._path_clear(fr, fc, tr, tc):
            return False

        # Restore vacated cell
        if (fr, fc) == self._THRONE:
            self._set(fr, fc, "t")
        elif (fr, fc) in self._CORNERS:
            self._set(fr, fc, "c")
        else:
            self._set(fr, fc, "e")

        self._set(tr, tc, piece)
        self._apply_captures(tr, tc, self._current)

        winner = self._check_win()
        if winner:
            self._status = winner
        else:
            self._current = "defender" if self._current == "attacker" else "attacker"
        return True

    def ai_move(self, difficulty: str = "medium") -> None:
        del difficulty  # mock ignores depth
        if self._status != "ongoing":
            return
        moves = self._get_moves(self._current)
        if not moves:
            # No moves — opponent wins
            self._status = "defender_won" if self._current == "attacker" else "attacker_won"
            return
        fr, fc, tr, tc = random.choice(moves)
        piece = self._cell(fr, fc).lower()

        if (fr, fc) == self._THRONE:
            self._set(fr, fc, "t")
        elif (fr, fc) in self._CORNERS:
            self._set(fr, fc, "c")
        else:
            self._set(fr, fc, "e")

        self._set(tr, tc, piece)
        self._apply_captures(tr, tc, self._current)

        winner = self._check_win()
        if winner:
            self._status = winner
        else:
            self._current = "defender" if self._current == "attacker" else "attacker"