use super::{Clock, schedule::WorkSchedule};
use crate::{
    calendar::Calendar,
    contract::{Salary, SalaryBasis, Settings, region_currency},
    salary_amount::parse_monthly_amount,
};
use rust_decimal::Decimal;
use serde::Serialize;

/// 供所有界面消费的金额投影。隐藏时不带真实金额。
#[derive(Serialize)]
pub(super) struct SalaryMetric<'a> {
    status: &'static str,
    currency: &'a str,
    precision: u8,
    basis: &'a SalaryBasis,
    hidden: bool,
    scheduled_workdays: u32,
    today_earned: Option<String>,
    month_earned: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    today_progress: Option<f64>,
    #[serde(skip_serializing_if = "Option::is_none")]
    month_progress: Option<f64>,
}

pub(super) fn compute<'a>(
    clock: &Clock,
    calendar: &Calendar,
    schedule: &WorkSchedule,
    settings: &'a Settings,
) -> SalaryMetric<'a> {
    let Some(salary) = &settings.salary else {
        return SalaryMetric {
            status: "unconfigured",
            currency: region_currency(&settings.region),
            precision: 2,
            basis: &SalaryBasis::Gross,
            hidden: settings.hide_amount,
            scheduled_workdays: 0,
            today_earned: None,
            month_earned: None,
            today_progress: None,
            month_progress: None,
        };
    };
    let accrual = accrue(clock, calendar, schedule);
    let (today_earned, month_earned) = if settings.hide_amount {
        ("****".into(), "****".into())
    } else {
        amounts(salary, &accrual)
    };
    let today_progress =
        (accrual.duration > 0).then(|| accrual.elapsed as f64 / accrual.duration as f64);
    let month_progress = (!settings.hide_amount && accrual.days > 0)
        .then(|| (accrual.completed as f64 + today_progress.unwrap_or(0.0)) / accrual.days as f64);
    SalaryMetric {
        status: match (accrual.days, accrual.working) {
            (0, _) => "no_workdays",
            (_, true) => "earning",
            _ => "paused",
        },
        currency: salary.currency.as_deref().expect("币种已补齐"),
        precision: salary.precision,
        basis: &salary.basis,
        hidden: settings.hide_amount,
        scheduled_workdays: accrual.days,
        today_earned: Some(today_earned),
        month_earned: Some(month_earned),
        today_progress: today_progress.filter(|_| !settings.hide_amount),
        month_progress,
    }
}

/// 每个应出勤日分配同一份日薪，按当天实际有效时长累计。
struct Accrual {
    /// 当月有有效工作时段的工作日总数。
    days: u32,
    /// 本月已经过完的工作日。
    completed: u32,
    /// 当天工作进度的分子和分母。
    elapsed: u64,
    duration: u64,
    /// 当前时刻是否处于有效工作区间。
    working: bool,
}

fn accrue(clock: &Clock, calendar: &Calendar, schedule: &WorkSchedule) -> Accrual {
    let today = clock.date();
    let mut result = Accrual {
        days: 0,
        completed: 0,
        elapsed: 0,
        duration: 1,
        working: false,
    };
    let mut date = today.first_of_month();
    let last = today.last_of_month();
    loop {
        if calendar.is_workday(date)
            && let Some((elapsed, duration, working)) =
                schedule.bounds(clock, date).elapsed(clock.millis())
        {
            result.days += 1;
            if date < today {
                result.completed += 1;
            } else if date == today {
                result.elapsed = elapsed;
                result.duration = duration;
                result.working = working;
            }
        }
        if date == last {
            return result;
        }
        date = date.tomorrow().expect("日期仍在当月");
    }
}

fn amounts(salary: &Salary, accrual: &Accrual) -> (String, String) {
    let monthly = match salary.basis {
        SalaryBasis::Gross => salary.gross_monthly.as_str(),
        SalaryBasis::Net => salary.net_monthly.as_deref().expect("税后月薪已校验"),
    };
    let monthly = parse_monthly_amount(monthly).expect("月薪已校验");
    let duration = u128::from(accrual.duration);
    let elapsed = u128::from(accrual.elapsed);
    let denominator = u128::from(accrual.days.max(1)) * duration;
    let month = u128::from(accrual.completed) * duration + elapsed;
    (
        prorate(monthly, elapsed, denominator, salary.precision),
        prorate(monthly, month, denominator, salary.precision),
    )
}

/// 以 Decimal 尾数和整数比例计算，直到输出才截断一次。
fn prorate(amount: Decimal, numerator: u128, denominator: u128, precision: u8) -> String {
    let mantissa = amount.mantissa() as u128;
    let remainder_product = mantissa % denominator * numerator;
    let units = mantissa / denominator * numerator + remainder_product / denominator;
    let scale = amount.scale();
    let precision = u32::from(precision);
    let scaled = if precision >= scale {
        let factor = 10_u128.pow(precision - scale);
        units * factor + remainder_product % denominator * factor / denominator
    } else {
        units / 10_u128.pow(scale - precision)
    };
    let factor = 10_u128.pow(precision);
    format!(
        "{}.{:0width$}",
        scaled / factor,
        scaled % factor,
        width = precision as usize
    )
}
