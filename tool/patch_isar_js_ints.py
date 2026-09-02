#!/usr/bin/env python3
"""Rewrite Isar schema ids so dart2js can compile them.

Isar hashes are 64-bit. JavaScript numbers are IEEE-754, so a literal such as
313749700063086650 is a compile error. int.parse keeps the exact value on the
VM (native Isar) and a rounded value on web (Isar 3 cannot open on web anyway).

Run after `dart run build_runner build`.
"""

from __future__ import annotations

import re
from pathlib import Path

MAX_SAFE = 9007199254740991
ID_RE = re.compile(r"(id:\s*)(-?\d+)(\s*,)")
ROOT = Path(__file__).resolve().parents[1] / "lib" / "data" / "isar"


def patch(path: Path) -> None:
    text = path.read_text()

    def repl(match: re.Match[str]) -> str:
        value = int(match.group(2))
        if abs(value) <= MAX_SAFE:
            return match.group(0)
        return f"{match.group(1)}int.parse('{match.group(2)}'){match.group(3)}"

    text = ID_RE.sub(repl, text)
    text = re.sub(r"^const (\w+Schema = )", r"final \1", text, flags=re.M)
    path.write_text(text)


def main() -> None:
    for path in sorted(ROOT.glob("*.g.dart")):
        patch(path)


if __name__ == "__main__":
    main()
