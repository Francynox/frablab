#!/usr/bin/env python3
"""
Checks Nix flake module and option naming conventions in frablab/parts/.
"""

import re
import sys
from pathlib import Path

# Regex patterns
MODULE_RE = re.compile(r"flake\.nixosModules\.([\w-]+)\s*=")
OPTION_RE = re.compile(r"options\.frablab\.([\w.-]+)\s*=")


def main():
    # Use current directory/parts or provided argument
    parts_dir = (
        Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).parent / "parts"
    )

    if not parts_dir.is_dir():
        print(f"Error: {parts_dir} is not a directory.", file=sys.stderr)
        sys.exit(1)

    total_violations = 0
    files_with_violations = 0

    # Walk through all .nix files
    for filepath in sorted(parts_dir.rglob("*.nix")):
        rel_path = filepath.relative_to(parts_dir)
        parts = rel_path.parts

        # Skip root files or files without enough folder structure
        if len(parts) < 2:
            continue

        # --- Calculate Expectations ---
        folder_parts = parts[:-1]
        filename = parts[-1]
        stem = filepath.stem

        folder_kebab = "-".join(folder_parts)
        folder_dot = ".".join(folder_parts)

        if filename == "default.nix":
            exp_mod = folder_kebab
            exp_opt = folder_dot
        else:
            exp_mod = f"{folder_kebab}-{stem}"
            exp_opt = f"{folder_dot}.{stem}"

        # --- Check Content ---
        try:
            content = filepath.read_text()
        except Exception as e:
            print(f"\n{rel_path}:")
            print(f"  ✗ Error reading file: {e}")
            total_violations += 1
            files_with_violations += 1
            continue

        file_violations = []

        # Check Modules
        for found in MODULE_RE.findall(content):
            if found != exp_mod:
                file_violations.append(f"Module: found '{found}', expected '{exp_mod}'")

        # Check Options
        option_matches = OPTION_RE.findall(content)
        if len(option_matches) > 1:
            file_violations.append(
                f"Options: found {len(option_matches)} 'options.frablab' definitions, expected at most 1 (grouped)"
            )

        for found in option_matches:
            # Valid if it matches exactly OR matches prefix followed by a dot
            is_valid = found == exp_opt or (
                found.startswith(f"{exp_opt}.") and len(found) > len(exp_opt)
            )

            if not is_valid:
                file_violations.append(
                    f"Option: found 'options.frablab.{found}', expected prefix 'options.frablab.{exp_opt}'"
                )

        # --- Print Results for File ---
        if file_violations:
            print(f"\n{rel_path}:")
            for v in file_violations:
                print(f"  ✗ {v}")

            total_violations += len(file_violations)
            files_with_violations += 1

    if total_violations > 0:
        print(f"\n{total_violations} violation(s) in {files_with_violations} file(s).")
        sys.exit(1)
    else:
        print("\n✓ All files follow conventions.")
        sys.exit(0)


if __name__ == "__main__":
    main()
