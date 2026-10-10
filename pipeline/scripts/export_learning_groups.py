"""Offline extension through the existing verified editorial exporter."""
import argparse
import json
from pathlib import Path
from import_editorial_patch import export_offline
from sprachpipe.learning_groups import apply_learning_groups


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--groups', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    pack = apply_learning_groups(args.source.read_bytes(), json.loads(args.groups.read_text(encoding='utf-8')))
    export_offline(pack, args.out)


if __name__ == '__main__':
    main()
