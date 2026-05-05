"""
main.py — Entry point for Hnefatafl.

Usage:
    python main.py                        # real Prolog AI, medium difficulty
    python main.py --difficulty hard      # override difficulty
    python main.py --mock                 # in-memory mock (no SWI-Prolog needed)
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Ensure sibling modules are importable when run from any working directory.
_PKG_DIR = Path(__file__).resolve().parent
if str(_PKG_DIR) not in sys.path:
    sys.path.insert(0, str(_PKG_DIR))

import pygame  # noqa: E402  (pygame must be imported after sys.path is set)
from bridge import HnefataflBridge, MockHnefataflBridge  # noqa: E402
from gui import HnefataflGUI, run_start_screen           # noqa: E402


def main() -> None:
    parser = argparse.ArgumentParser(description="Hnefatafl — Viking Chess")
    parser.add_argument(
        "--mock",
        action="store_true",
        help="Use in-memory board instead of SWI-Prolog (for GUI testing).",
    )
    parser.add_argument(
        "--difficulty",
        default=None,
        choices=("easy", "medium", "hard"),
        help="Skip the start screen and use this difficulty directly.",
    )
    parser.add_argument(
        "--side",
        default=None,
        choices=("attacker", "defender"),
        help="Skip the start screen and play as this side.",
    )
    args = parser.parse_args()

    # Initialise pygame early so the start screen can display.
    pygame.init()
    from gui import WIN_W, WIN_H  # noqa: E402
    screen = pygame.display.set_mode((WIN_W, WIN_H))
    pygame.display.set_caption("Hnefatafl — Viking Chess")

    # Determine side and difficulty (start screen or CLI flags).
    if args.difficulty is not None and args.side is not None:
        human_side = args.side
        difficulty = args.difficulty
    else:
        # Show the start screen for any missing option.
        human_side, difficulty = run_start_screen(screen)
        if args.difficulty:
            difficulty = args.difficulty
        if args.side:
            human_side = args.side

    # Build bridge.
    if args.mock:
        bridge = MockHnefataflBridge()
    else:
        try:
            bridge = HnefataflBridge()
        except FileNotFoundError as e:
            print(f"[ERROR] {e}", file=sys.stderr)
            print("Tip: Run from the project root, or use --mock to test without Prolog.",
                  file=sys.stderr)
            sys.exit(1)
        except RuntimeError as e:
            print(f"[ERROR] Prolog initialisation failed: {e}", file=sys.stderr)
            sys.exit(1)

    gui = HnefataflGUI(bridge, difficulty=difficulty, human_side=human_side)
    gui.run()


if __name__ == "__main__":
    main()