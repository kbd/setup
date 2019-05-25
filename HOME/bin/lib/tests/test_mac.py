from unittest.mock import patch

from lib import mac

def test_defaults_write():
    with patch('lib.mac.run') as run:
        mac.defaults['com.apple.menuextra.clock']['DateFormat'] = "EEE MMM d  h:mm a"

    run.assert_called_once_with([
        'defaults', 'write', 'com.apple.menuextra.clock', 'DateFormat',
        '-string', "EEE MMM d  h:mm a"
    ])


def test_defaults_write_global():
    with patch('lib.mac.run') as run:
        mac.defaults.g['com.apple.keyboard.fnState'] = True

    run.assert_called_once_with([
        'defaults', 'write', '-g', 'com.apple.keyboard.fnState', '-bool', 'True'
    ])


def test_defaults_write_dict():
    with patch('lib.mac.run') as run:
        mac.defaults['com.generalarcade.flycut']['ShortcutRecorder mainHotkey'] = {
            'keyCode': 47,
            'modifierFlags': 1310720,
        }

    run.assert_called_once_with(
        [
            'defaults', 'write', 'com.generalarcade.flycut', "ShortcutRecorder mainHotkey",
            '-dict', 'keyCode', '-int', '47', 'modifierFlags', '-int', '1310720'
        ]
    )
