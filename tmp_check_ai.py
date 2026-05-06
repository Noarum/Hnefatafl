import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent / 'python'))
from bridge import HnefataflBridge

bridge = HnefataflBridge()
for diff in ['easy','medium','hard']:
    bridge.init_game(11)
    try:
        bridge.ai_move(diff)
        print(diff, 'OK')
    except Exception as e:
        print(diff, 'ERROR', e)
