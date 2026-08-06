from __future__ import annotations

import argparse
import logging
import sys

from family_price_tracker import refresh


def main(argv: list[str] | None = None) -> int:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
    )
    parser = argparse.ArgumentParser(prog="family_price_tracker")
    sub = parser.add_subparsers(dest="cmd", required=True)

    sub.add_parser("list-items", help="List items from the Sheet")

    p_refresh = sub.add_parser("refresh", help="Refresh prices for tracked items")
    p_refresh.add_argument("--item", help="Item id to refresh")
    p_refresh.add_argument(
        "--due",
        action="store_true",
        help="Refresh all wanted tracked items",
    )

    p_add = sub.add_parser("add-tracked", help="Append a tracked item with Amazon URL")
    p_add.add_argument("--url", required=True)
    p_add.add_argument("--name", required=True)
    p_add.add_argument("--notes", default="")
    p_add.add_argument("--priority", type=int, default=3)
    p_add.add_argument("--list", dest="list_owner", default="Me")
    p_add.add_argument(
        "--refresh",
        action="store_true",
        help="Fetch price immediately after insert",
    )

    sub.add_parser("doctor", help="Show registered fetchers")

    args = parser.parse_args(argv)
    if args.cmd == "list-items":
        return refresh.cmd_list_items()
    if args.cmd == "refresh":
        return refresh.cmd_refresh(args.item, args.due)
    if args.cmd == "add-tracked":
        return refresh.cmd_add_tracked(
            args.url,
            args.name,
            args.notes,
            args.priority,
            args.list_owner,
            args.refresh,
        )
    if args.cmd == "doctor":
        return refresh.cmd_doctor()
    return 2


if __name__ == "__main__":
    sys.exit(main())
