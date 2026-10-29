import sys
sys.path.insert(0, 'tools/sprites')
import set_dressing as sd
from pathlib import Path

out = Path('game/assets/sprites')
jobs = {
    'luggage_scale.png': sd.luggage_scale_sheet,
    'flight_kiosk.png': sd.flight_kiosk_sheet,
    'wall_clock.png': sd.wall_clock_sheet,
    'notice_board.png': sd.notice_board_sheet,
    'sign_gantry.png': sd.sign_gantry_sheet,
    'gate_totem.png': sd.gate_totem_sheet,
    'atm.png': sd.atm_sheet,
}
for name, fn in jobs.items():
    img = fn()
    img.save(out / name)
    print(name, img.size)
