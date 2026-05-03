"""Entry point: ensure imports work when run from any working directory."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Directory containing this file (the ``python`` package folder).
_PKG_DIR = Path(__file__).resolve().parent
if str(_PKG_DIR) not in sys.path:
    sys.path.insert(0, str(_PKG_DIR))

from bridge import HnefataflBridge, MockHnefataflBridge  # noqa: E402
from gui import HnefataflGUI  # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="Hnefatafl Pygame client")
    parser.add_argument(
        "--mock",
        action="store_true",
        help="Use in-memory board (no SWI-Prolog); for GUI testing only.",
    )
    parser.add_argument(
        "--difficulty",
        default="medium",
        choices=("easy", "medium", "hard"),
        help="Passed to Prolog make_ai_move/1 when not using --mock.",
    )
    args = parser.parse_args()

    bridge = MockHnefataflBridge() if args.mock else HnefataflBridge()
    gui = HnefataflGUI(bridge, difficulty=args.difficulty)
    gui.run()


if __name__ == "__main__":
    main()
