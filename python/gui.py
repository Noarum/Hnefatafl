"""Pygame UI for Hnefatafl."""

from __future__ import annotations

import sys
from pathlib import Path
from typing import Optional

import pygame

from bridge import HnefataflBridge, MockHnefataflBridge


# Constants
BOARD_SIZE = 11
CELL_SIZE = 64
MARGIN = 40
UI_BAR_HEIGHT = 56
COLORS = {
    "bg": (40, 40, 40),
    "cell_light": (210, 180, 140),
    "cell_dark": (160, 120, 80),
    "throne": (180, 140, 60),
    "corner": (100, 160, 100),
    "highlight": (255, 255, 0),
    "attacker": (50, 50, 150),
    "defender": (220, 220, 220),
    "king": (255, 215, 0),
    "text": (255, 255, 255),
}


class HnefataflGUI:
    """Pygame-based renderer and interaction loop for Hnefatafl."""

    def __init__(
        self,
        bridge: HnefataflBridge | MockHnefataflBridge,
        difficulty: str = "medium",
    ) -> None:
        self._bridge = bridge
        self._difficulty = difficulty.strip().lower()
        self._selected: Optional[tuple[int, int]] = None
        self._font: Optional[pygame.font.Font] = None
        self._error_msg: Optional[str] = None
        self._error_until_ms = 0

        pygame.init()
        grid_px = BOARD_SIZE * CELL_SIZE + 2 * MARGIN
        win_w = grid_px
        win_h = UI_BAR_HEIGHT + grid_px
        self._screen = pygame.display.set_mode((win_w, win_h))
        pygame.display.set_caption("Hnefatafl")
        self._clock = pygame.time.Clock()
        self._font = pygame.font.SysFont("dejavusans,sans", 22)

    def _cell_to_pixel(self, row: int, col: int) -> tuple[int, int]:
        """Top-left pixel of the cell (row, col), including UI bar offset."""
        x = MARGIN + col * CELL_SIZE
        y = UI_BAR_HEIGHT + MARGIN + row * CELL_SIZE
        return x, y

    def _pixel_to_cell(self, pixel_x: int, pixel_y: int) -> Optional[tuple[int, int]]:
        """Board (row, col) from window pixel coords, or None if outside the grid."""
        x = pixel_x - MARGIN
        y = pixel_y - UI_BAR_HEIGHT - MARGIN
        if x < 0 or y < 0:
            return None
        col = x // CELL_SIZE
        row = y // CELL_SIZE
        if row < 0 or col < 0 or row >= BOARD_SIZE or col >= BOARD_SIZE:
            return None
        return row, col

    @staticmethod
    def _piece_owner(piece: str) -> Optional[str]:
        p = piece.lower()
        if p == "b":
            return "attacker"
        if p in ("w", "k"):
            return "defender"
        return None

    def _show_transient_error(self, message: str, duration_ms: int = 3500) -> None:
        self._error_msg = message
        self._error_until_ms = pygame.time.get_ticks() + duration_ms

    def _maybe_clear_error(self) -> None:
        if self._error_msg and pygame.time.get_ticks() >= self._error_until_ms:
            self._error_msg = None

    def draw_board(self) -> None:
        """Draw grid, throne, corners, pieces, selection."""
        assert self._screen is not None
        self._screen.fill(COLORS["bg"])

        center = BOARD_SIZE // 2
        corners = {
            (0, 0),
            (0, BOARD_SIZE - 1),
            (BOARD_SIZE - 1, 0),
            (BOARD_SIZE - 1, BOARD_SIZE - 1),
        }

        for r in range(BOARD_SIZE):
            for c in range(BOARD_SIZE):
                x, y = self._cell_to_pixel(r, c)
                rect = pygame.Rect(x, y, CELL_SIZE, CELL_SIZE)
                is_dark = (r + c) % 2 == 1
                base = COLORS["cell_dark"] if is_dark else COLORS["cell_light"]
                pygame.draw.rect(self._screen, base, rect)
                if (r, c) == (center, center):
                    pygame.draw.rect(self._screen, COLORS["throne"], rect.inflate(-6, -6))
                elif (r, c) in corners:
                    pygame.draw.rect(self._screen, COLORS["corner"], rect.inflate(-10, -10))

        if self._selected is not None:
            sr, sc = self._selected
            sx, sy = self._cell_to_pixel(sr, sc)
            pygame.draw.rect(
                self._screen,
                COLORS["highlight"],
                pygame.Rect(sx, sy, CELL_SIZE, CELL_SIZE),
                width=4,
            )

        try:
            pieces = self._bridge.get_board()
        except RuntimeError as e:
            self._show_transient_error(str(e))
            pieces = []

        for r, c, piece in pieces:
            if r < 0 or c < 0 or r >= BOARD_SIZE or c >= BOARD_SIZE:
                continue
            cx, cy = self._cell_to_pixel(r, c)
            center_xy = (cx + CELL_SIZE // 2, cy + CELL_SIZE // 2)
            pl = piece.lower()
            if pl == "b":
                color = COLORS["attacker"]
            elif pl == "k":
                color = COLORS["king"]
            elif pl == "w":
                color = COLORS["defender"]
            else:
                continue
            radius = CELL_SIZE // 2 - 8
            pygame.draw.circle(self._screen, color, center_xy, radius)

    def draw_ui(self) -> None:
        """Top bar: player, difficulty, errors / game over overlay."""
        assert self._screen is not None and self._font is not None
        self._maybe_clear_error()
        bar = pygame.Rect(0, 0, self._screen.get_width(), UI_BAR_HEIGHT)
        pygame.draw.rect(self._screen, (25, 25, 25), bar)

        try:
            player = self._bridge.current_player()
            status = self._bridge.game_status()
        except RuntimeError as e:
            player = "?"
            status = "error"
            self._show_transient_error(str(e))

        line1 = f"Player: {player}   |   Difficulty: {self._difficulty}   |   Status: {status}"
        surf1 = self._font.render(line1, True, COLORS["text"])
        self._screen.blit(surf1, (12, 8))

        if self._error_msg:
            surf_e = self._font.render(self._error_msg[:120], True, (255, 180, 80))
            self._screen.blit(surf_e, (12, 30))

        if status != "ongoing":
            overlay = pygame.Surface(self._screen.get_size(), pygame.SRCALPHA)
            overlay.fill((0, 0, 0, 160))
            self._screen.blit(overlay, (0, 0))
            big = pygame.font.SysFont("dejavusans,sans", 36)
            msg = f"Game over: {status.replace('_', ' ')}"
            ts = big.render(msg, True, COLORS["text"])
            tx = (self._screen.get_width() - ts.get_width()) // 2
            ty = (self._screen.get_height() - ts.get_height()) // 2
            self._screen.blit(ts, (tx, ty))

    def handle_click(self, pixel_x: int, pixel_y: int) -> None:
        """Select a friendly piece, then attempt move; optionally trigger AI reply."""
        cell = self._pixel_to_cell(pixel_x, pixel_y)
        if cell is None:
            return

        try:
            status = self._bridge.game_status()
        except RuntimeError as e:
            self._show_transient_error(str(e))
            return

        if status != "ongoing":
            return

        try:
            current = self._bridge.current_player()
        except RuntimeError as e:
            self._show_transient_error(str(e))
            return

        row, col = cell
        piece_map = { (r, c): p for r, c, p in self._bridge.get_board() }
        piece_here = piece_map.get((row, col))

        if self._selected is None:
            if piece_here is None:
                return
            owner = self._piece_owner(piece_here)
            if owner != current:
                return
            self._selected = (row, col)
            return

        sr, sc = self._selected
        if (row, col) == (sr, sc):
            self._selected = None
            return

        try:
            ok = self._bridge.human_move(sr, sc, row, col)
        except RuntimeError as e:
            self._show_transient_error(str(e))
            return

        self._selected = None
        if not ok:
            self._show_transient_error("Illegal move.")
            return

        try:
            status_after = self._bridge.game_status()
        except RuntimeError as e:
            self._show_transient_error(str(e))
            return

        if status_after == "ongoing":
            try:
                self._bridge.ai_move(self._difficulty)
            except RuntimeError as e:
                self._show_transient_error(str(e))

    def run(self) -> None:
        """Main loop."""
        running = True
        while running:
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    self.handle_click(event.pos[0], event.pos[1])

            self.draw_board()
            self.draw_ui()
            pygame.display.flip()
            self._clock.tick(60)

        pygame.quit()


def main() -> None:
    """Allow ``python gui.py`` when PYTHONPATH includes this directory."""
    pkg = Path(__file__).resolve().parent
    if str(pkg) not in sys.path:
        sys.path.insert(0, str(pkg))
    use_mock = "--mock" in sys.argv
    bridge = MockHnefataflBridge() if use_mock else HnefataflBridge()
    HnefataflGUI(bridge, difficulty="medium").run()


if __name__ == "__main__":
    main()
