import pygame

from bridge import HnefataflBridge


# Constants
BOARD_SIZE = 11
CELL_SIZE = 64
MARGIN = 40
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

    def __init__(self, bridge: HnefataflBridge, difficulty="medium"):
        """Initialize pygame, window state, and selected-cell tracking."""
        pass

    def _cell_to_pixel(self, row: int, col: int) -> tuple[int, int]:
        """Convert board coordinates into top-left pixel coordinates."""
        pass

    def _pixel_to_cell(self, pixel_x: int, pixel_y: int) -> tuple[int, int] | None:
        """Convert pixel coordinates into board coordinates if in bounds."""
        pass

    def draw_board(self):
        """Draw the board grid, special cells, pieces, and selected highlight."""
        pass

    def handle_click(self, pixel_x, pixel_y):
        """Handle selection/move flow and trigger AI reply when needed."""
        pass

    def draw_ui(self):
        """Draw player turn, difficulty, and game-over overlay."""
        pass

    def run(self):
        """Run the main pygame event/render loop."""
        pass
