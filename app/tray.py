"""Clean Tray module — no system tray icon created (single-window GUI mode)."""
from PySide6.QtCore import QObject


class Tray(QObject):
    """Clean no-op Tray (no tray icon created)."""

    def __init__(self, on_quit=None, on_settings=None, hotkey="ctrl+space"):
        super().__init__()

    def set_hotkey_label(self, hotkey: str):
        pass

    def set_state(self, state: str, title: str = None):
        pass

    def notify(self, title: str, msg: str, level: str = "info"):
        pass

    def stop(self):
        pass
