#!/usr/bin/env python3
"""MD5 uniqueness gate for sky_gatekeeper_judge engine frames.

Fails (exit 1) if any two frames share a hash, or if a required state
is missing. Use before any commit of judge frames.
"""
from __future__ import annotations

import argparse
import hashlib
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_DIR = ROOT / "assets" / "sprites" / "monsters" / "sky_gatekeeper"

REQUIRED = {
    "idle": 6,
    "move": 6,
    "attack": 7,
    "skill": 8,
    "hurt": 3,
    "death": 6,
    "evolve": 8,
}


def md5(path: Path) -> str:
    h = hashlib.md5()
    h.update(path.read_bytes())
    return h.hexdigest()


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--dir", default=str(DEFAULT_DIR))
    p.add_argument(
        "--allow-partial",
        action="store_true",
        help="only check frames that exist (skip missing-state failure)",
    )
    args = p.parse_args()
    root = Path(args.dir)
    if not root.is_absolute():
        root = ROOT / root

    by_hash: dict[str, list[str]] = {}
    present: dict[str, list[str]] = {s: [] for s in REQUIRED}
    missing: list[str] = []

    for state, count in REQUIRED.items():
        for i in range(count):
            name = f"sky_gatekeeper_judge_{state}_{i:02d}.png"
            path = root / name
            if not path.is_file():
                missing.append(name)
                continue
            digest = md5(path)
            by_hash.setdefault(digest, []).append(name)
            present[state].append(name)

    print(f"scanned {sum(len(v) for v in present.values())} frames in {root}")
    for state, names in present.items():
        print(f"  {state}: {len(names)}/{REQUIRED[state]}")

    failed = False
    if missing and not args.allow_partial:
        failed = True
        print(f"MISSING ({len(missing)}):")
        for name in missing:
            print(f"  - {name}")
    elif missing:
        print(f"partial: {len(missing)} missing (allowed)")

    dups = {h: names for h, names in by_hash.items() if len(names) > 1}
    if dups:
        failed = True
        print(f"DUPLICATE MD5 groups ({len(dups)}):")
        for h, names in dups.items():
            print(f"  {h}: {', '.join(names)}")
    else:
        print(f"MD5 unique: {len(by_hash)} distinct hashes")

    if failed:
        print("CHECK_JUDGE_UNIQ_FAIL")
        return 1
    print("CHECK_JUDGE_UNIQ_OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
