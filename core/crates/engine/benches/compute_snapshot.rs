use serde_json::{Value, json};
use shiyu_core::compute_snapshot;
use std::{
    alloc::{GlobalAlloc, Layout, System},
    hint::black_box,
    sync::atomic::{AtomicU64, Ordering::Relaxed},
    time::Instant,
};

/// 统计调用过程中分配次数和申请字节数，包含重新分配。
struct CountingAllocator;

static REQUESTS: AtomicU64 = AtomicU64::new(0);
static BYTES: AtomicU64 = AtomicU64::new(0);

#[global_allocator]
static ALLOCATOR: CountingAllocator = CountingAllocator;

// 安全性：布局、指针与分配结果原样交给 System，计数不参与分配。
unsafe impl GlobalAlloc for CountingAllocator {
    unsafe fn alloc(&self, layout: Layout) -> *mut u8 {
        record(layout.size());
        unsafe { System.alloc(layout) }
    }

    unsafe fn alloc_zeroed(&self, layout: Layout) -> *mut u8 {
        record(layout.size());
        unsafe { System.alloc_zeroed(layout) }
    }

    unsafe fn realloc(&self, ptr: *mut u8, layout: Layout, new_size: usize) -> *mut u8 {
        record(new_size);
        unsafe { System.realloc(ptr, layout, new_size) }
    }

    unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout) {
        unsafe { System.dealloc(ptr, layout) }
    }
}

fn record(bytes: usize) {
    REQUESTS.fetch_add(1, Relaxed);
    BYTES.fetch_add(bytes as u64, Relaxed);
}

fn main() {
    measure("defaults", "{}", "{}");
    let custom: Vec<_> = (0..20)
        .map(|index| {
            json!({
                "id": format!("sample-{index}"),
                "name": format!("合成项目 {index}"),
                "target": "2026-11-09T18:00:00",
                "order": 20 - index
            })
        })
        .collect();
    let mut settings = json!({
        "time_zone": "Asia/Shanghai",
        "birth": {"date": "1996-02-29", "life_expectancy_years": "100.5"},
        "retirement_date": "2065-05-01",
        "hide_amount": false,
        "salary": {"gross_monthly":"22000", "precision": 4},
        "payday": {"rule":"twice_monthly", "days":[15,31]},
        "date_overrides": {"2026-11-07":true}
    });
    let catalog: Value = serde_json::from_str(include_str!(
        "../../../../app/assets/holidays/calendar.json"
    ))
    .expect("内置日历 JSON 合法");
    let payload = &catalog["packs"]["CN"]["payload"];
    let holidays = json!({
        "schema_version": 1, "region": "CN", "years": payload["years"],
        "date_overrides": payload["date_overrides"]
    });
    let holidays = holidays.to_string();
    measure("all_builtin_metrics", &settings.to_string(), &holidays);
    settings["custom_countdowns"] = json!(custom);
    measure("salary_and_20_countdowns", &settings.to_string(), &holidays);
}

/// 单线程固定输入，报告完整 JSON 计算和序列化的延迟。
fn measure(label: &str, settings: &str, holidays: &str) {
    const WARMUP: usize = 1_000;
    const SAMPLES: usize = 10_000;
    const NOW: i64 = 1_793_764_800_000;
    let compute = || compute_snapshot(black_box(settings), black_box(holidays), black_box(NOW));
    let verified: Value = serde_json::from_str(&compute()).expect("基准输入可序列化");
    assert_eq!(verified["ok"], true);
    for _ in 0..WARMUP {
        black_box(compute());
    }
    let mut samples = Vec::with_capacity(SAMPLES);
    let requests = REQUESTS.load(Relaxed);
    let bytes = BYTES.load(Relaxed);
    for _ in 0..SAMPLES {
        let start = Instant::now();
        black_box(compute());
        samples.push(start.elapsed().as_nanos());
    }
    let allocations = REQUESTS.load(Relaxed) - requests;
    let allocated = BYTES.load(Relaxed) - bytes;
    samples.sort_unstable();
    let mean = samples.iter().sum::<u128>() as f64 / SAMPLES as f64 / 1000.0;
    let percentile =
        |percent: usize| samples[(SAMPLES * percent).div_ceil(100) - 1] as f64 / 1000.0;
    println!(
        "{label} samples={SAMPLES} mean_us={mean:.2} p50_us={:.2} p95_us={:.2} p99_us={:.2} allocations_per_call={:.1} allocated_bytes_per_call={:.1}",
        percentile(50),
        percentile(95),
        percentile(99),
        allocations as f64 / SAMPLES as f64,
        allocated as f64 / SAMPLES as f64,
    );
}
