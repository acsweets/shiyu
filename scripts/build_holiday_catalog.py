"""将已核对的 2026–2027 年官方假日和补班日期转成应用离线数据。"""

import csv
from datetime import date, timedelta
import hashlib
import io
import json
from pathlib import Path
from urllib.request import urlopen

YEARS = (2026, 2027)
VERSION = 2026110501
JP = "https://www8.cao.go.jp/chosei/shukujitsu/gaiyou.html"
US = "https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/"
HK = "https://data.gov.hk/en-data/dataset/hk-dpo-statistic-cal"
TW = "https://data.gov.tw/dataset/14718"
KR_NEW = "https://www.kasa.go.kr/prog/plcyBrf/brief/kor/sub01_01_04/view.do?plcyBrfNo=431"
SOURCES = {
    "CN": (
        ["https://www.beijing.gov.cn/cs/gncs/zcwj/202603/t20260327_4568275.html"],
        ["https://www2.xinhuanet.com/politics/20261105/f90cd6ad4df94ab4833b141e52ccfc13/c.html"],
    ),
    "US": ([US], [US]),
    "JP": ([JP], [JP]),
    "KR": (
        [
            "https://www.kasa.go.kr/prog/plcyBrf/brief/kor/sub01_01_04/view.do?plcyBrfNo=202",
            "https://www.law.go.kr/lsInfoP.do?lsiSeq=285779&viewCls=lsRvsDocInfoR",
        ],
        [KR_NEW],
    ),
    "HK": ([HK], [HK]),
    "TW": ([TW], [TW]),
}

# 斜线表示连续区间，区间的两个端点都放假。
REST = {
    "CN": (
        "01-01/01-03 02-15/02-23 04-04/04-06 05-01/05-05 06-19/06-21 09-25/09-27 10-01/10-07",
        "01-01/01-03 02-05/02-13 04-03/04-05 05-01/05-05 06-09 09-15 10-01/10-07",
    ),
    "US": (
        "01-01 01-19 02-16 05-25 06-19 07-03 09-07 10-12 11-11 11-26 12-25",
        "01-01 01-18 02-15 05-31 06-18 07-05 09-06 10-11 11-11 11-25 12-24",
    ),
    "JP": (
        "01-01 01-12 02-11 02-23 03-20 04-29 05-03/05-06 07-20 08-11 09-21/09-23 10-12 11-03 11-23",
        "01-01 01-11 02-11 02-23 03-21/03-22 04-29 05-03/05-05 07-19 08-11 09-20 09-23 10-11 11-03 11-23",
    ),
    "KR": (
        "01-01 02-16/02-18 03-01/03-02 05-01 05-05 05-24/05-25 06-03 06-06 07-17 08-15 08-17 09-24/09-26 10-03 10-05 10-09 12-25",
        "01-01 02-06/02-09 03-01 05-01 05-03 05-05 05-13 06-06 07-17 07-19 08-15/08-16 09-14/09-16 10-03/10-04 10-09 10-11 12-25 12-27",
    ),
}
CN_WORK = ("01-04 02-14 02-28 05-09 09-20 10-10", "01-31 02-14 05-08 09-26 10-09")
TW_FILES = (
    "202506%2Fa52331bd-a189-466b-b0f0-cae3062bbf74.csv",
    "202607%2Ff538b1ff-ba60-4c63-9477-10db8e6612d1.csv",
)


def download(url):
    with urlopen(url, timeout=20) as response:
        return response.read().decode("utf-8-sig")


def expand(year, intervals):
    for interval in intervals.split():
        limits = interval.split("/")
        start = date.fromisoformat(f"{year}-{limits[0]}")
        end = date.fromisoformat(f"{year}-{limits[-1]}")
        for offset in range((end - start).days + 1):
            yield (start + timedelta(days=offset)).isoformat()


def iso_day(raw):
    return date(int(raw[:4]), int(raw[4:6]), int(raw[6:8]))


def hk_dates():
    data = json.loads(download("https://www.1823.gov.hk/common/ical/en.json"))
    events = data["vcalendar"][0]["vevent"]
    days = [iso_day(event["dtstart"][0]) for event in events]
    for year in YEARS:
        if len({day for day in days if day.year == year}) != 17:
            raise ValueError(f"Unexpected HK holiday count for {year}")
    return {day.isoformat(): False for day in days if day.year in YEARS}


def tw_dates():
    overrides = {}
    for year, path in zip(YEARS, TW_FILES):
        url = f"https://www.dgpa.gov.tw/FileConversion?filename=dgpa%2Ffiles%2F{path}&name=calendar.csv&nfix="
        rows = csv.DictReader(io.StringIO(download(url)))
        seen = set()
        for row in rows:
            day = iso_day(row["西元日期"])
            status = row["是否放假"]
            if day.year != year or day in seen or status not in ("0", "2"):
                raise ValueError(f"Unexpected TW record: {row}")
            seen.add(day)
            weekly_rest = day.weekday() >= 5
            if (status == "2") != weekly_rest or (status == "2" and row["備註"].strip()):
                overrides[day.isoformat()] = status == "0"
        if len(seen) != (date(year + 1, 1, 1) - date(year, 1, 1)).days:
            raise ValueError(f"Incomplete TW calendar for {year}")
    return overrides


def build():
    dates = {
        region: {day: False for year, slots in zip(YEARS, records) for day in expand(year, slots)}
        for region, records in REST.items()
    }
    for year, slots in zip(YEARS, CN_WORK):
        dates["CN"].update(dict.fromkeys(expand(year, slots), True))
    dates["HK"] = hk_dates()
    dates["TW"] = tw_dates()
    packs = {}
    for region, sources in SOURCES.items():
        payload = {
            "schema_version": 1,
            "region": region,
            "years": list(YEARS),
            "sources": dict(zip(map(str, YEARS), sources)),
            "date_overrides": dict(sorted(dates[region].items())),
        }
        encoded = json.dumps(
            [VERSION, payload], ensure_ascii=False, separators=(",", ":")
        ).encode("utf-8")
        packs[region] = {
            "version": VERSION,
            "sha256": hashlib.sha256(encoded).hexdigest(),
            "payload": payload,
        }
    target = Path(__file__).resolve().parents[1] / "app/assets/holidays/calendar.json"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(
        json.dumps({"schema_version": 1, "packs": packs}, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
        newline="\n",
    )


if __name__ == "__main__":
    build()
