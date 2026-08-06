from __future__ import annotations

from typing import Any

from google.oauth2 import service_account
from googleapiclient.discovery import build

from family_price_tracker.config import Settings
from family_price_tracker.models import Item, utc_now_iso

SCOPES = ["https://www.googleapis.com/auth/spreadsheets"]

# Header keys must match sheet/SCHEMA.md row 1
HEADERS = [
    "id",
    "photo",
    "name",
    "list_owner",
    "priority",
    "type",
    "size",
    "color",
    "qty",
    "notes",
    "status",
    "stores",
    "amazon_price",
    "amazon_url",
    "target_price",
    "target_url",
    "walmart_price",
    "walmart_url",
    "last_checked",
    "upc",
    "asin",
    "hot",
]


def _cell(row: list[str], idx: int) -> str:
    return row[idx].strip() if idx < len(row) and row[idx] is not None else ""


class SheetsClient:
    def __init__(self, settings: Settings):
        creds = service_account.Credentials.from_service_account_file(
            str(settings.credentials_path), scopes=SCOPES
        )
        self._service = build("sheets", "v4", credentials=creds, cache_discovery=False)
        self._sheet_id = settings.sheet_id
        self._items_tab = settings.items_tab

    def _values(self) -> Any:
        return self._service.spreadsheets().values()

    def ensure_header(self) -> None:
        result = (
            self._values()
            .get(spreadsheetId=self._sheet_id, range=f"'{self._items_tab}'!1:1")
            .execute()
        )
        rows = result.get("values", [])
        if not rows or not rows[0]:
            self._values().update(
                spreadsheetId=self._sheet_id,
                range=f"'{self._items_tab}'!A1",
                valueInputOption="RAW",
                body={"values": [HEADERS]},
            ).execute()

    def list_items(self) -> list[Item]:
        self.ensure_header()
        result = (
            self._values()
            .get(spreadsheetId=self._sheet_id, range=f"'{self._items_tab}'!A2:V")
            .execute()
        )
        items: list[Item] = []
        for i, row in enumerate(result.get("values", []), start=2):
            item_id = _cell(row, 0)
            if not item_id:
                continue
            priority_raw = _cell(row, 4) or "3"
            try:
                priority = int(priority_raw)
            except ValueError:
                priority = 3
            items.append(
                Item(
                    id=item_id,
                    photo=_cell(row, 1),
                    name=_cell(row, 2),
                    list_owner=_cell(row, 3) or "Shared",
                    priority=priority,
                    type=_cell(row, 5) or "text",
                    size=_cell(row, 6),
                    color=_cell(row, 7),
                    qty=_cell(row, 8),
                    notes=_cell(row, 9),
                    status=_cell(row, 10) or "wanted",
                    stores=_cell(row, 11),
                    amazon_price=_cell(row, 12),
                    amazon_url=_cell(row, 13),
                    target_price=_cell(row, 14),
                    target_url=_cell(row, 15),
                    walmart_price=_cell(row, 16),
                    walmart_url=_cell(row, 17),
                    last_checked=_cell(row, 18),
                    upc=_cell(row, 19),
                    asin=_cell(row, 20),
                    hot=_cell(row, 21),
                    row_index=i,
                )
            )
        return items

    def get_item(self, item_id: str) -> Item | None:
        for item in self.list_items():
            if item.id == item_id:
                return item
        return None

    def append_item(self, item: Item) -> None:
        self.ensure_header()
        row = [
            item.id,
            item.photo,
            item.name,
            item.list_owner,
            str(item.priority),
            item.type,
            item.size,
            item.color,
            item.qty,
            item.notes,
            item.status,
            item.stores,
            item.amazon_price,
            item.amazon_url,
            item.target_price,
            item.target_url,
            item.walmart_price,
            item.walmart_url,
            item.last_checked,
            item.upc,
            item.asin,
            item.hot,
        ]
        self._values().append(
            spreadsheetId=self._sheet_id,
            range=f"'{self._items_tab}'!A:V",
            valueInputOption="USER_ENTERED",
            insertDataOption="INSERT_ROWS",
            body={"values": [row]},
        ).execute()

    def update_amazon_price(self, item: Item, price: str, url: str) -> None:
        if item.row_index is None:
            found = self.get_item(item.id)
            if not found or found.row_index is None:
                raise ValueError(f"Item not found: {item.id}")
            item = found
        checked = utc_now_iso()
        # M=amazon_price, N=amazon_url, S=last_checked
        rng = f"'{self._items_tab}'!M{item.row_index}:N{item.row_index}"
        self._values().update(
            spreadsheetId=self._sheet_id,
            range=rng,
            valueInputOption="USER_ENTERED",
            body={"values": [[price, url]]},
        ).execute()
        self._values().update(
            spreadsheetId=self._sheet_id,
            range=f"'{self._items_tab}'!S{item.row_index}",
            valueInputOption="USER_ENTERED",
            body={"values": [[checked]]},
        ).execute()
