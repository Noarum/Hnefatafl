from bridge import HnefataflBridge
from gui import HnefataflGUI


if __name__ == "__main__":
    bridge = HnefataflBridge()
    gui = HnefataflGUI(bridge, difficulty="medium")
    gui.run()
