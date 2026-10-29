import re

from kittens.tui.handler import result_handler
from kitty.key_encoding import KeyEvent, parse_shortcut

# moving the divider in a direction shrinks or grows the active window,
# depending on which side its neighbor is on
OPPOSITE = {'left': 'right', 'right': 'left', 'top': 'bottom', 'bottom': 'top'}
GROW = {'left': 'wider', 'right': 'wider', 'top': 'taller', 'bottom': 'taller'}
SHRINK = {'left': 'narrower', 'right': 'narrower', 'top': 'shorter', 'bottom': 'shorter'}


def is_window_vim(window, vim_id):
    fp = window.child.foreground_processes
    return any(re.search(vim_id, p['cmdline'][0] if len(p['cmdline']) else '', re.I) for p in fp)


def encode_key_mapping(window, key_mapping):
    mods, key = parse_shortcut(key_mapping)
    event = KeyEvent(
        mods=mods,
        key=key,
        shift=bool(mods & 1),
        alt=bool(mods & 2),
        ctrl=bool(mods & 4),
        super=bool(mods & 8),
        hyper=bool(mods & 16),
        meta=bool(mods & 32),
    ).as_window_system_event()

    return window.encoded_key(event)


def resize(tab, direction, increment):
    if tab.neighboring_group_id(OPPOSITE[direction]) is not None:
        tab.resize_window(SHRINK[direction], increment)
    elif tab.neighboring_group_id(direction) is not None:
        tab.resize_window(GROW[direction], increment)


def main():
    pass


# args: direction key_mapping [vim_id | "force"]
# "force" skips passing the key on (used when herdr/nvim hand the resize back to kitty)
@result_handler(no_ui=True)
def handle_result(args, result, target_window_id, boss):
    window = boss.window_id_map.get(target_window_id)
    direction = args[1]
    key_mapping = args[2]
    vim_id = args[3] if len(args) > 3 else "n?vim"
    tab = boss.active_tab

    if window is None or tab is None:
        return
    if vim_id != "force" and is_window_vim(window, vim_id):
        window.write_to_child(encode_key_mapping(window, key_mapping))
    else:
        resize(tab, direction, 2)
