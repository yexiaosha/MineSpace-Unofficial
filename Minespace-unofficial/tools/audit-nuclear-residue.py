#!/usr/bin/env python3
"""Counts NCO / QMD item stacks left in the exported recipe tables.

The diagnostics exporter writes one CSV per recipe source.  This script answers
the follow-up question "how much of those mods' own item namespace is still
being produced or consumed, and for which items?" without starting the game.

Usage:

    python tools/audit-nuclear-residue.py D:/minespace-capture-run/minespace-diagnostics
"""

from __future__ import annotations

import collections
import csv
import os
import sys

NAMESPACES = ("nuclearcraft:", "qmd:")

# column name -> whether the column holds outputs
TABLES = {
    "gt-recipes.csv": {
        "inputs": False,
        "outputs": True,
        "chanced_outputs": True,
    },
    "nco-recipes.csv": {
        "item_inputs": False,
        "item_outputs": True,
    },
    "qmd-recipes.csv": {
        "item_inputs": False,
        "item_outputs": True,
    },
}


def ids_in_cell(text):
    for part in text.split(";"):
        part = part.strip()
        if not part:
            continue
        token = part.split(" x", 1)[0].strip()
        if token.startswith(NAMESPACES):
            yield token


def load_ore_names(path):
    names = {}
    if not os.path.exists(path):
        return names
    with open(path, newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            key = f"{row['registry']}:{row['meta']}"
            ore = row.get("ore_dict", "")
            if ore:
                names[key] = ore
    return names


def main():
    folder = sys.argv[1] if len(sys.argv) > 1 else "minespace-diagnostics"
    needle = sys.argv[2] if len(sys.argv) > 2 else None
    if needle == "--unmapped":
        print_unmapped_materials(folder)
        return
    if needle == "--handlers":
        print_handler_counts(folder)
        return
    if needle == "--crafting":
        item = sys.argv[3] if len(sys.argv) > 3 else "nuclearcraft:ingot_block"
        print_crafting(folder, item)
        return
    if needle == "--gt":
        item = sys.argv[3] if len(sys.argv) > 3 else "nuclearcraft:ingot_block"
        print_gt(folder, item)
        return
    if needle == "--outputs":
        item = sys.argv[3] if len(sys.argv) > 3 else "nuclearcraft:part:0"
        print_outputs(folder, item)
        return
    ore_names = load_ore_names(os.path.join(folder, "items.csv"))
    for table, columns in TABLES.items():
        path = os.path.join(folder, table)
        if not os.path.exists(path):
            print(f"{table}: missing")
            continue
        produced = collections.Counter()
        consumed = collections.Counter()
        with open(path, newline="", encoding="utf-8-sig") as handle:
            for row in csv.DictReader(handle):
                if needle and needle in ";".join(row.values()):
                    print(f"  row {row.get('index', '?')}: {row}")
                for column, is_output in columns.items():
                    for item in ids_in_cell(row.get(column, "")):
                        (produced if is_output else consumed)[item] += 1
        print(f"\n== {table} ==")
        print(f"  produced rows : {sum(produced.values())} ({len(produced)} ids)")
        print(f"  consumed rows : {sum(consumed.values())} ({len(consumed)} ids)")
        for label, counter in (("PRODUCED", produced), ("CONSUMED", consumed)):
            for item, count in counter.most_common(25):
                ore = ore_names.get(item, "")
                print(f"  {label:8} {count:4}  {item:42} {ore}")


PREFIXES = ("ingot", "dust", "gem", "block", "plate", "nugget", "rod")

FUEL_FORMS = ("Depleted", "LEU", "HEU", "LEA", "HEA", "LEB", "HEB",
              "LEC", "HEC", "LEP", "HEP", "LEN", "HEN", "MIX", "TBU")

NON_MATERIALS = {
    "Basic", "Advanced", "DU", "Chocolate", "DarkChocolate",
    "UnsweetenedChocolate", "Marshmallow", "CocoaButter",
    "SoullessSand", "SoullessSandstone", "NdYAG",
}


def print_unmapped_materials(folder):
    """Lists material names that NCO/QMD register but GregTech does not.

    The output is grouped by material name, so a name that appears as both an ingot and a
    dust is one GT material, not two.
    """
    path = os.path.join(folder, "ore-dictionary.csv")
    mapped = set()
    targets_path = os.path.join(folder, "material-targets.csv")
    if os.path.exists(targets_path):
        with open(targets_path, newline="", encoding="utf-8-sig") as handle:
            for row in csv.DictReader(handle):
                mapped.add(row["source"])
    grouped = collections.defaultdict(lambda: {"prefixes": set(), "mod_items": set()})
    with open(path, newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            ore = row["ore_name"]
            prefix = next((p for p in PREFIXES if ore.startswith(p)), None)
            if prefix is None:
                continue
            material = ore[len(prefix):]
            if not material:
                continue
            entry = grouped[material]
            entry["prefixes"].add(prefix)
            if row["registry"].startswith(NAMESPACES):
                item = f"{row['registry']}:{row['meta']}"
                if item not in mapped:
                    entry["mod_items"].add(item)
            if row["registry"].startswith("gregtech:"):
                entry["gt"] = True
    for material in sorted(grouped):
        entry = grouped[material]
        if entry.get("gt") or not entry["mod_items"]:
            continue
        if material.endswith("All") or material.startswith(FUEL_FORMS):
            continue
        if material in NON_MATERIALS:
            continue
        if entry["prefixes"] <= {"block"}:
            continue
        print(f"{material:35} {'/'.join(sorted(entry['prefixes'])):22} "
              f"{', '.join(sorted(entry['mod_items']))}")


def print_handler_counts(folder):
    path = os.path.join(folder, "nco-recipes.csv")
    counts = collections.Counter()
    with open(path, newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            counts[row["handler"]] += 1
    for handler, count in sorted(counts.items()):
        print(f"{handler:20} {count}")


def print_crafting(folder, item):
    path = os.path.join(folder, "crafting-recipes.csv")
    with open(path, newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            inputs = row.get("inputs", "")
            output = row.get("output", "")
            if item in inputs or item in output:
                where = []
                if item in output:
                    where.append("OUTPUT")
                if item in inputs:
                    where.append("INPUT")
                print(f"{'/'.join(where):12} {row['name']}")
                print(f"  -> {output}")
                print(f"  <- {inputs}")


def print_gt(folder, item):
    path = os.path.join(folder, "gt-recipes.csv")
    with open(path, newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            haystack = ";".join(row.values())
            if item in haystack:
                print(f"{row['map']}[{row['index']}]")
                print(f"  in : {row.get('inputs', '')}")
                print(f"  out: {row.get('outputs', '')}")
                print(f"  ch : {row.get('chanced_outputs', '')}")


def print_outputs(folder, item):
    path = os.path.join(folder, "crafting-recipes.csv")
    with open(path, newline="", encoding="utf-8-sig") as handle:
        for row in csv.DictReader(handle):
            if item in row.get("output", ""):
                print(f"{row['name']}")
                print(f"  -> {row['output']}")
                print(f"  <- {row['inputs']}")


if __name__ == "__main__":
    main()
