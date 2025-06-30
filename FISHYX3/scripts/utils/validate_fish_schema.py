#!/usr/bin/env python3
###############################################################
# scripts/utils/validate_fish_schema.py
# Key funcs/classes: \u2022 main() – validates fish species JSON files
# Critical consts    \u2022 SCHEMA_PATH, SPECIES_DIR
###############################################################
"""Validate fish species JSON files against the schema."""

import json
from pathlib import Path
import sys
from jsonschema import Draft202012Validator

SCHEMA_PATH = Path(__file__).resolve().parents[2] / "data" / "fish_schema.json"
SPECIES_DIR = Path(__file__).resolve().parents[2] / "data" / "species"


def main() -> int:
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        schema = json.load(f)

    validator = Draft202012Validator(schema)
    errors_found = False

    for file in SPECIES_DIR.glob("*.json"):
        with open(file, "r", encoding="utf-8") as f:
            data = json.load(f)
        errors = sorted(validator.iter_errors(data), key=lambda e: e.path)
        if errors:
            errors_found = True
            print(f"Errors in {file}:")
            for err in errors:
                print(f"  {list(err.path)}: {err.message}")

    if errors_found:
        return 1

    print("All species files valid.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
