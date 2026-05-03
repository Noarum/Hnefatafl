from pyswip import Prolog


class HnefataflBridge:
    """Bridge layer between Python UI and SWI-Prolog predicates."""

    def __init__(self):
        """Consult Prolog controller and initialize game state."""
        pass

    def _parse_board(self, raw_result):
        """Parse board query output into a list of (row, col, piece_type).

        Expected raw pyswip shape (example):
        [
            {
                'Board': [
                    ['c', 'e', ...],
                    ...
                ]
            }
        ]
        """
        pass

    def get_board(self) -> list[tuple]:
        """Return board as a list of (row, col, piece_type_string)."""
        pass

    def human_move(self, fr, fc, tr, tc) -> bool:
        """Apply a human move and return True on success."""
        pass

    def ai_move(self, difficulty: str = "medium") -> None:
        """Trigger an AI move using the provided difficulty level."""
        pass

    def current_player(self) -> str:
        """Return the current player as a string."""
        pass

    def game_status(self) -> str:
        """Return current game status as a string."""
        pass
