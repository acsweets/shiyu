"""用独立配置启动桌面 Release 验证入口并采样。"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import time

from sample_desktop import collect


def write_profile(folder: Path) -> None:
    folder.mkdir()
    settings = {
        "schema_version": 1,
        "time_zone": "Asia/Shanghai",
        "birth": {"date": "1996-02-29", "life_expectancy_years": "100"},
        "retirement_date": "2065-05-01",
        "salary": {"gross_monthly": "22000"},
        "payday": {"rule": "fixed_day", "days": [15]},
        "hide_amount": True,
    }
    (folder / "settings.json").write_text(json.dumps(settings), encoding="utf-8")
    (folder / ".shiyu-verification").touch()


def run(executable: Path, folder: Path, seconds: int, interval: int) -> int:
    executable = executable.resolve(strict=True)
    folder = folder.resolve()
    write_profile(folder)
    env = {**os.environ, "SHIYU_VERIFY_DIRECTORY": str(folder)}
    ready = folder / "ready"
    begin = time.monotonic()
    process = subprocess.Popen([str(executable)], cwd=executable.parent, env=env)
    try:
        while not ready.is_file():
            if process.poll() is not None:
                raise RuntimeError(f"应用在准备完成前退出，退出码 {process.returncode}")
            if time.monotonic() - begin > 15:
                raise TimeoutError("应用没有发出首帧和窗口可见信号")
            time.sleep(0.01)
        startup = {"cold_start_ms": round((time.monotonic() - begin) * 1000, 1)}
        (folder / "startup.json").write_text(json.dumps(startup), encoding="utf-8")
        print(json.dumps(startup), flush=True)
        return collect(process.pid, seconds, interval, folder / "samples.jsonl")
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--executable", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--seconds", type=int, default=60)
    parser.add_argument("--interval", type=int, default=5)
    args = parser.parse_args()
    if min(args.seconds, args.interval) < 1:
        parser.error("时长和采样间隔必须为正整数")
    return run(args.executable, args.output, args.seconds, args.interval)


if __name__ == "__main__":
    raise SystemExit(main())
