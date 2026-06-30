#!/usr/bin/env python3
"""
Read simple Arduino serial commands and send keyboard taps to the focused game.

Expected serial lines:
  UP, DOWN, LEFT, RIGHT, SPACE, E, SHIFT, R

The game already maps:
  UP    -> W
  DOWN  -> S
  LEFT  -> A
  RIGHT -> D
  SPACE -> Space
  E     -> E
  SHIFT -> Shift
  R     -> R
"""

from __future__ import annotations

import argparse
import sys
import time
from dataclasses import dataclass
from typing import Iterable


@dataclass(frozen=True)
class KeyTap:
    label: str
    key_name: str


COMMAND_MAP = {
    "UP": KeyTap("w", "w"),
    "ARROWUP": KeyTap("w", "w"),
    "W": KeyTap("w", "w"),
    "DOWN": KeyTap("s", "s"),
    "ARROWDOWN": KeyTap("s", "s"),
    "S": KeyTap("s", "s"),
    "LEFT": KeyTap("a", "a"),
    "ARROWLEFT": KeyTap("a", "a"),
    "A": KeyTap("a", "a"),
    "RIGHT": KeyTap("d", "d"),
    "ARROWRIGHT": KeyTap("d", "d"),
    "D": KeyTap("d", "d"),
    "SPACE": KeyTap("space", "space"),
    "PLACE": KeyTap("space", "space"),
    "BUTTON": KeyTap("space", "space"),
    "BUTTON1": KeyTap("space", "space"),
    "BTN": KeyTap("space", "space"),
    "BTNA": KeyTap("space", "space"),
    "E": KeyTap("e", "e"),
    "SWITCH": KeyTap("e", "e"),
    "SHIFT": KeyTap("shift", "shift"),
    "MODIFIER": KeyTap("shift", "shift"),
    "BACKSPACE": KeyTap("backspace", "backspace"),
    "REMOVE": KeyTap("backspace", "backspace"),
    "R": KeyTap("r", "r"),
    "RESTART": KeyTap("r", "r"),
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Bridge Arduino serial commands to W/A/S/D/Space/E/Shift/R key taps."
    )
    parser.add_argument("--port", help="Serial port, for example /dev/cu.usbmodem1101.")
    parser.add_argument("--baud", type=int, default=115200, help="Serial baud rate.")
    parser.add_argument("--list", action="store_true", help="List serial ports and exit.")
    parser.add_argument("--stdin", action="store_true", help="Read commands from stdin instead of serial.")
    parser.add_argument("--dry-run", action="store_true", help="Print mapped keys without pressing them.")
    parser.add_argument("--tap-ms", type=float, default=0.035, help="How long to hold each key tap.")
    return parser.parse_args()


def normalize_command(line: str) -> str:
    return line.strip().upper().replace(" ", "").replace("-", "").replace("_", "")


def iter_stdin_lines() -> Iterable[str]:
    for line in sys.stdin:
        yield line


def iter_serial_lines(port: str, baud: int) -> Iterable[str]:
    try:
        import serial
    except ImportError as exc:
        raise SystemExit("Missing dependency: run `python3 -m pip install pyserial`.") from exc

    with serial.Serial(port, baudrate=baud, timeout=1) as connection:
        print(f"Listening on {port} at {baud} baud. Press Ctrl+C to stop.")
        time.sleep(1.8)
        connection.reset_input_buffer()

        while True:
            raw_line = connection.readline()
            if not raw_line:
                continue
            yield raw_line.decode("utf-8", errors="replace")


def list_serial_ports() -> None:
    try:
        from serial.tools import list_ports
    except ImportError as exc:
        raise SystemExit("Missing dependency: run `python3 -m pip install pyserial`.") from exc

    ports = list(list_ports.comports())
    if not ports:
        print("No serial ports found.")
        return

    for port in ports:
        print(f"{port.device}\t{port.description}")


def make_keyboard_controller():
    try:
        from pynput.keyboard import Controller, Key
    except ImportError as exc:
        raise SystemExit("Missing dependency: run `python3 -m pip install pynput`.") from exc

    return Controller(), Key


def press_key(controller, key_module, tap: KeyTap, tap_ms: float) -> None:
    if tap.key_name == "space":
        key = key_module.space
    elif tap.key_name == "shift":
        key = key_module.shift
    elif tap.key_name == "backspace":
        key = key_module.backspace
    else:
        key = tap.key_name

    controller.press(key)
    time.sleep(tap_ms)
    controller.release(key)


def run_bridge(args: argparse.Namespace) -> None:
    if args.list:
        list_serial_ports()
        return

    if not args.stdin and not args.port:
        raise SystemExit("Choose `--list`, `--stdin`, or provide `--port /dev/cu...`.")

    controller = None
    key_module = None
    if not args.dry_run:
        controller, key_module = make_keyboard_controller()
        print("Keyboard bridge active. Click the Summer game window so it has focus.")

    lines = iter_stdin_lines() if args.stdin else iter_serial_lines(args.port, args.baud)

    try:
        for line in lines:
            command = normalize_command(line)
            if not command:
                continue

            tap = COMMAND_MAP.get(command)
            if tap is None:
                print(f"Ignored unknown command: {line.strip()}", file=sys.stderr)
                continue

            print(f"{command} -> {tap.label}")
            if controller is not None and key_module is not None:
                press_key(controller, key_module, tap, args.tap_ms)
    except KeyboardInterrupt:
        print("\nStopped.")


if __name__ == "__main__":
    run_bridge(parse_args())
