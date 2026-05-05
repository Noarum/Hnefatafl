"""
gui.py — Pygame UI for Hnefatafl.

Fixes vs. original:
  1. AI runs in a background thread → UI never freezes / crashes
  2. Valid destination squares are highlighted when a piece is selected
  3. Clicking an enemy piece while something is selected resets selection
     (does not attempt an illegal move)
  4. Start screen: player chooses Human side (attacker / defender), board size (9x9 / 11x11), and difficulty
  5. Game-over overlay blocks further clicks correctly
  6. Throne and corner squares visually marked
  7. Status bar shows whose turn it is with color coding
"""

from __future__ import annotations

import sys
import threading
from pathlib import Path
from typing import Optional, Union

import pygame

from bridge import HnefataflBridge, MockHnefataflBridge

# ── Layout defaults (actual window size is dynamic) ─────────────────────────
CELL_SIZE     = 60
MARGIN        = 40
UI_BAR_HEIGHT = 60

# ── Color palette ─────────────────────────────────────────────────────────────
C = {
    "bg":           (28,  28,  28),
    "ui_bar":       (18,  18,  18),
    "cell_light":   (205, 175, 130),
    "cell_dark":    (170, 130,  80),
    "throne":       (200, 160,  50),
    "corner":       ( 90, 160,  90),
    "highlight_sel":(255, 220,   0),   # selected piece border
    "highlight_dst":(100, 220, 100),   # valid destination tint
    "attacker":     ( 55,  80, 180),
    "attacker_rim": (100, 130, 220),
    "defender":     (230, 230, 225),
    "defender_rim": (180, 180, 170),
    "king":         (220, 180,  30),
    "king_rim":     (255, 230, 100),
    "text":         (240, 240, 240),
    "text_dim":     (160, 160, 160),
    "attacker_col": ( 80, 120, 255),
    "defender_col": (255, 255, 255),
    "error":        (255, 140,  60),
    "overlay":      (  0,   0,   0, 180),
    "btn":          ( 50,  50,  50),
    "btn_hover":    ( 80,  80,  80),
    "btn_active":   ( 40, 100, 180),
}

BridgeType = Union[HnefataflBridge, MockHnefataflBridge]

# ─────────────────────────────────────────────────────────────────────────────
# Start screen
# ─────────────────────────────────────────────────────────────────────────────

def run_start_screen(screen: pygame.Surface) -> tuple[str, str, int]:
    """
    Show a start screen and return (human_side, difficulty, board_size).
    """
    font_title  = pygame.font.SysFont("dejavusans,sans", 38, bold=True)
    font_sub    = pygame.font.SysFont("dejavusans,sans", 22)
    font_btn    = pygame.font.SysFont("dejavusans,sans", 20, bold=True)
    clock       = pygame.time.Clock()

    human_side  = "defender"
    difficulty  = "medium"
    board_size  = 11

    def draw_btn(label: str, rect: pygame.Rect, active: bool, hover: bool) -> None:
        color = C["btn_active"] if active else (C["btn_hover"] if hover else C["btn"])
        pygame.draw.rect(screen, color, rect, border_radius=8)
        pygame.draw.rect(screen, C["text_dim"], rect, width=1, border_radius=8)
        ts = font_btn.render(label, True, C["text"])
        screen.blit(ts, (rect.centerx - ts.get_width() // 2,
                         rect.centery - ts.get_height() // 2))

    win_w = screen.get_width()
    side_rects = {
        "attacker": pygame.Rect(win_w // 2 - 160, 180, 140, 44),
        "defender": pygame.Rect(win_w // 2 +  20, 180, 140, 44),
    }
    size_rects = {
        9:  pygame.Rect(win_w // 2 - 160, 260, 140, 44),
        11: pygame.Rect(win_w // 2 +  20, 260, 140, 44),
    }
    diff_rects = {
        "easy":   pygame.Rect(win_w // 2 - 185, 340, 110, 44),
        "medium": pygame.Rect(win_w // 2 -  55, 340, 110, 44),
        "hard":   pygame.Rect(win_w // 2 +  75, 340, 110, 44),
    }
    start_rect = pygame.Rect(win_w // 2 - 90, 430, 180, 52)

    while True:
        mx, my = pygame.mouse.get_pos()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                for side, r in side_rects.items():
                    if r.collidepoint(mx, my): human_side = side
                for sz, r in size_rects.items():
                    if r.collidepoint(mx, my): board_size = sz
                for diff, r in diff_rects.items():
                    if r.collidepoint(mx, my): difficulty = diff
                if start_rect.collidepoint(mx, my):
                    return human_side, difficulty, board_size

        screen.fill(C["bg"])

        # Title
        ts = font_title.render("Hnefatafl", True, C["king"])
        screen.blit(ts, (win_w // 2 - ts.get_width() // 2, 60))
        sub = font_sub.render("Viking Chess", True, C["text_dim"])
        screen.blit(sub, (win_w // 2 - sub.get_width() // 2, 106))

        # Side selection
        lbl = font_sub.render("Choose Side:", True, C["text"])
        screen.blit(lbl, (win_w // 2 - lbl.get_width() // 2, 146))
        for side, r in side_rects.items():
            draw_btn(side.capitalize(), r, human_side == side, r.collidepoint(mx, my))

        # Board size selection
        lbl = font_sub.render("Board Size:", True, C["text"])
        screen.blit(lbl, (win_w // 2 - lbl.get_width() // 2, 230))
        for sz, r in size_rects.items():
            draw_btn(f"{sz}x{sz}", r, board_size == sz, r.collidepoint(mx, my))

        # Difficulty selection
        lbl = font_sub.render("AI Difficulty:", True, C["text"])
        screen.blit(lbl, (win_w // 2 - lbl.get_width() // 2, 310))
        for diff, r in diff_rects.items():
            draw_btn(diff.capitalize(), r, difficulty == diff, r.collidepoint(mx, my))

        # Start button
        pygame.draw.rect(screen, C["btn_active"], start_rect, border_radius=10)
        st = font_btn.render("Start Game", True, C["text"])
        screen.blit(st, (start_rect.centerx - st.get_width() // 2,
                         start_rect.centery - st.get_height() // 2))

        pygame.display.flip()
        clock.tick(60)


# ─────────────────────────────────────────────────────────────────────────────
# Main GUI class
# ─────────────────────────────────────────────────────────────────────────────

class HnefataflGUI:
    """Pygame renderer and interaction loop."""

    def __init__(
        self,
        bridge:      BridgeType,
        difficulty:  str = "medium",
        human_side:  str = "defender",
        board_size:  int = 11
    ) -> None:
        self._bridge     = bridge
        self._difficulty = difficulty.strip().lower()
        self._human_side = human_side.strip().lower()
        self._size       = board_size

        self._selected:     Optional[tuple[int, int]]       = None
        self._valid_dsts:   list[tuple[int, int]]            = []
        self._error_msg:    Optional[str]                    = None
        self._error_until:  int                              = 0
        self._ai_thinking:  bool                             = False
        self._font:         Optional[pygame.font.Font]       = None
        self._font_big:     Optional[pygame.font.Font]       = None

        pygame.init()
        # Calculate dynamic window size
        grid_px = self._size * CELL_SIZE + 2 * MARGIN
        self._win_w = grid_px
        self._win_h = UI_BAR_HEIGHT + grid_px
        self._screen = pygame.display.set_mode((self._win_w, self._win_h))
        pygame.display.set_caption(f"Hnefatafl ({self._size}x{self._size})")
        self._clock  = pygame.time.Clock()
        self._font     = pygame.font.SysFont("dejavusans,sans", 18)
        self._font_big = pygame.font.SysFont("dejavusans,sans", 32, bold=True)

    # ── Coordinate helpers ────────────────────────────────────────────────────

    def _cell_to_pixel(self, row: int, col: int) -> tuple[int, int]:
        """Top-left pixel of cell (row, col)."""
        return (MARGIN + col * CELL_SIZE,
                UI_BAR_HEIGHT + MARGIN + row * CELL_SIZE)

    def _pixel_to_cell(self, px: int, py: int) -> Optional[tuple[int, int]]:
        """Board (row, col) from window pixel, or None if outside grid."""
        x = px - MARGIN
        y = py - UI_BAR_HEIGHT - MARGIN
        if x < 0 or y < 0:
            return None
        col, row = x // CELL_SIZE, y // CELL_SIZE
        if not (0 <= row < self._size and 0 <= col < self._size):
            return None
        return row, col

    # ── Error flash ───────────────────────────────────────────────────────────

    def _flash(self, msg: str, ms: int = 3500) -> None:
        self._error_msg   = msg
        self._error_until = pygame.time.get_ticks() + ms

    def _tick_error(self) -> None:
        if self._error_msg and pygame.time.get_ticks() >= self._error_until:
            self._error_msg = None

    # ── Piece helpers ─────────────────────────────────────────────────────────

    @staticmethod
    def _piece_owner(piece: str) -> Optional[str]:
        p = piece.lower()
        if p == "b":       return "attacker"
        if p in ("w","k"): return "defender"
        return None

    # ── Drawing ───────────────────────────────────────────────────────────────

    def _draw_board(self) -> None:
        assert self._screen

        center  = self._size // 2
        corners = {(0,0),(0,self._size-1),(self._size-1,0),(self._size-1,self._size-1)}
        dst_set = set(self._valid_dsts)

        for r in range(self._size):
            for c in range(self._size):
                x, y = self._cell_to_pixel(r, c)
                rect  = pygame.Rect(x, y, CELL_SIZE, CELL_SIZE)

                # Base checkerboard
                base = C["cell_dark"] if (r + c) % 2 else C["cell_light"]
                pygame.draw.rect(self._screen, base, rect)

                # Special squares
                if (r, c) == (center, center):
                    pygame.draw.rect(self._screen, C["throne"],
                                     rect.inflate(-8, -8))
                elif (r, c) in corners:
                    pygame.draw.rect(self._screen, C["corner"],
                                     rect.inflate(-10, -10))

                # Valid destination highlight
                if (r, c) in dst_set:
                    tint = pygame.Surface((CELL_SIZE, CELL_SIZE), pygame.SRCALPHA)
                    tint.fill((*C["highlight_dst"], 90))
                    self._screen.blit(tint, (x, y))
                    pygame.draw.rect(self._screen, C["highlight_dst"], rect, width=2)

                # Grid lines
                pygame.draw.rect(self._screen, (0, 0, 0), rect, width=1)

        # Selection border (drawn after grid so it's on top)
        if self._selected is not None:
            sr, sc = self._selected
            sx, sy = self._cell_to_pixel(sr, sc)
            pygame.draw.rect(self._screen, C["highlight_sel"],
                             pygame.Rect(sx, sy, CELL_SIZE, CELL_SIZE), width=4)

        # Pieces
        try:
            pieces = self._bridge.get_board()
        except RuntimeError as e:
            self._flash(str(e))
            pieces = []

        for r, c, piece in pieces:
            if not (0 <= r < self._size and 0 <= c < self._size):
                continue
            cx, cy = self._cell_to_pixel(r, c)
            center_xy = (cx + CELL_SIZE // 2, cy + CELL_SIZE // 2)
            radius = CELL_SIZE // 2 - 6
            p = piece.lower()
            if p == "b":
                fill, rim = C["attacker"], C["attacker_rim"]
            elif p == "k":
                fill, rim = C["king"],     C["king_rim"]
            elif p == "w":
                fill, rim = C["defender"], C["defender_rim"]
            else:
                continue
            pygame.draw.circle(self._screen, fill, center_xy, radius)
            pygame.draw.circle(self._screen, rim,  center_xy, radius, width=2)
            # King gets a crown dot
            if p == "k":
                pygame.draw.circle(self._screen, (200, 100, 0), center_xy, radius // 3)

    def _draw_ui(self) -> None:
        assert self._screen and self._font

        self._tick_error()
        pygame.draw.rect(self._screen, C["ui_bar"],
                         pygame.Rect(0, 0, self._win_w, UI_BAR_HEIGHT))

        try:
            player = self._bridge.current_player()
            status = self._bridge.game_status()
        except RuntimeError as e:
            player, status = "?", "error"
            self._flash(str(e))

        # Color-code whose turn it is
        p_color = C["attacker_col"] if player == "attacker" else C["defender_col"]

        thinking_tag = "  [Thinking…]" if self._ai_thinking else ""
        line = (f"Turn: "
                f"{player.capitalize()}{thinking_tag}"
                f"   |   Diff: {self._difficulty.capitalize()}"
                f"   |   Size: {self._size}x{self._size}")
        ts = self._font.render(line, True, p_color)
        self._screen.blit(ts, (12, 10))

        if self._error_msg:
            es = self._font.render(self._error_msg[:100], True, C["error"])
            self._screen.blit(es, (12, 34))

        # Game-over overlay
        if status != "ongoing":
            overlay = pygame.Surface((self._win_w, self._win_h), pygame.SRCALPHA)
            overlay.fill(C["overlay"])
            self._screen.blit(overlay, (0, 0))
            assert self._font_big
            winner_text = {
                "attacker_won": "Attackers Win!",
                "defender_won": "King Escaped!",
            }.get(status, f"Game over: {status.replace('_',' ')}")
            ts2 = self._font_big.render(winner_text, True, C["king"])
            self._screen.blit(ts2,
                              (self._win_w // 2 - ts2.get_width() // 2,
                               self._win_h // 2 - ts2.get_height() // 2))
            hint = self._font.render("Close window to exit.", True, C["text_dim"])
            self._screen.blit(hint,
                              (self._win_w // 2 - hint.get_width() // 2,
                               self._win_h // 2 + ts2.get_height()))

    # ── Click handling ────────────────────────────────────────────────────────

    def _handle_click(self, px: int, py: int) -> None:
        cell = self._pixel_to_cell(px, py)
        if cell is None:
            return

        try:
            status  = self._bridge.game_status()
            current = self._bridge.current_player()
        except RuntimeError as e:
            self._flash(str(e))
            return

        # Block clicks when game is over or AI is thinking
        if status != "ongoing" or self._ai_thinking:
            return

        # Block clicks when it is not the human's turn
        if current != self._human_side:
            return

        row, col = cell
        piece_map = {(r, c): p for r, c, p in self._bridge.get_board()}
        piece_here = piece_map.get((row, col))

        # ── No piece currently selected ───────────────────────────────────────
        if self._selected is None:
            if piece_here is None:
                return
            if self._piece_owner(piece_here) != self._human_side:
                self._flash("Not your piece.")
                return
            # Select the piece and highlight its valid destinations
            self._selected  = (row, col)
            self._valid_dsts = self._bridge.get_valid_moves_for_piece(row, col)
            return

        # ── A piece is already selected ───────────────────────────────────────
        sr, sc = self._selected

        # Re-click the same cell → deselect
        if (row, col) == (sr, sc):
            self._selected   = None
            self._valid_dsts = []
            return

        # Click a different friendly piece → reselect (don't attempt move)
        if piece_here is not None and self._piece_owner(piece_here) == self._human_side:
            self._selected   = (row, col)
            self._valid_dsts = self._bridge.get_valid_moves_for_piece(row, col)
            return

        # Attempt the move
        try:
            ok = self._bridge.human_move(sr, sc, row, col)
        except RuntimeError as e:
            self._flash(str(e))
            self._selected   = None
            self._valid_dsts = []
            return

        self._selected   = None
        self._valid_dsts = []

        if not ok:
            self._flash("Illegal move — try again.")
            return

        # ── Trigger AI move in a background thread ────────────────────────────
        try:
            after_status = self._bridge.game_status()
        except RuntimeError:
            return

        if after_status == "ongoing":
            self._trigger_ai_move()

    def _trigger_ai_move(self) -> None:
        """Run the AI in a daemon thread so the UI stays responsive."""
        if self._ai_thinking:
            return
        self._ai_thinking = True

        def _worker() -> None:
            try:
                self._bridge.ai_move(self._difficulty)
            except RuntimeError as e:
                self._flash(str(e))
            finally:
                self._ai_thinking = False

        t = threading.Thread(target=_worker, daemon=True)
        t.start()

    # ── First AI move (attacker goes first, may be AI) ────────────────────────

    def _maybe_start_ai(self) -> None:
        """If the human plays defender, the AI (attacker) moves first."""
        try:
            current = self._bridge.current_player()
            status  = self._bridge.game_status()
        except RuntimeError:
            return
        if status == "ongoing" and current != self._human_side:
            self._trigger_ai_move()

    # ── Main loop ─────────────────────────────────────────────────────────────

    def run(self) -> None:
        self._maybe_start_ai()

        running = True
        while running:
            self._screen.fill(C["bg"])

            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    running = False
                elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
                    self._handle_click(event.pos[0], event.pos[1])

            self._draw_board()
            self._draw_ui()
            pygame.display.flip()
            self._clock.tick(60)

        pygame.quit()