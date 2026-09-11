from datetime import datetime

import requests
from waste_collection_schedule import Collection, Icons  # type: ignore[attr-defined]

TITLE = "Dover District Council"
DESCRIPTION = "Source for Dover District Council."
URL = "https://www.dover.gov.uk"
TEST_CASES = {
    "Ranelagh Road": {"uprn": "10034882837", "postcode": "CT14 7BG"},
}


ICON_MAP = {
    "Garden Waste Collection": Icons.GARDEN,
    "Food Collection": Icons.BIO_KITCHEN,
    "Refuse Collection": Icons.GENERAL_WASTE,
    "Paper/Card Collection": Icons.PAPER,
    "Recycling Collection": Icons.RECYCLING,
}

# Dover District Council's portal ID within their WasteWorks-style backend.
# Confirmed live via browser Network tab capture, 29 Aug 2026 - not documented
# anywhere, but has been stable and is unlikely to change per-council.
COUNCIL_ID = "39"

BASE_URL = "https://portal.waste.dover.gov.uk/api"
SEARCH_URL = f"{BASE_URL}/getPropertySearch"
COLLECTIONS_URL = f"{BASE_URL}/getCollectionDays"

HEADERS = {"Content-Type": "application/json"}


class Source:
    def __init__(self, uprn: str | int, postcode: str):
        self._uprn: str = str(uprn)
        self._postcode: str = postcode.replace(" ", "")
        self._point_id: str | None = None

    def _resolve_point_id(self) -> str:
        """Dover's API only supports searching by postcode/address text, not
        UPRN directly. Search by postcode, then match on the returned UPRN
        to find the property's internal pointId."""
        response = requests.post(
            SEARCH_URL,
            json={"councilId": COUNCIL_ID, "searchQuery": self._postcode},
            headers=HEADERS,
        )
        response.raise_for_status()
        data = response.json()

        for match in data.get("data", []):
            if str(match.get("uprn", "")) == self._uprn:
                return str(match["id"])

        raise ValueError(
            f"No property found for UPRN {self._uprn} at postcode "
            f"{self._postcode}. Check both values are correct."
        )

    def fetch(self) -> list[Collection]:
        if self._point_id is None:
            self._point_id = self._resolve_point_id()

        response = requests.post(
            COLLECTIONS_URL,
            json={
                "pointId": self._point_id,
                "pointType": "PointAddress",
                "councilId": COUNCIL_ID,
            },
            headers=HEADERS,
        )
        response.raise_for_status()
        data = response.json()

        entries = []

        for service in data.get("activeServices", []):
            service_name = service.get("serviceName", "")

            for schedule in service.get("serviceSchedules", []):
                date_str = schedule.get("currentScheduledDate") or schedule.get(
                    "originalScheduledDate"
                )
                if not date_str:
                    continue

                # e.g. "2026-09-04T00:00:00+01:00"
                collection_date = datetime.strptime(
                    date_str[:10], "%Y-%m-%d"
                ).date()

                entries.append(
                    Collection(
                        date=collection_date,
                        t=service_name,
                        icon=ICON_MAP.get(service_name),
                    )
                )

        return entries
