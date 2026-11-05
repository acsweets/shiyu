use serde::{Deserialize, Serialize};
use std::collections::BTreeMap;

use crate::display::DisplaySettings;

pub const SCHEMA_VERSION: u32 = 1;

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Settings {
    /// 当前设置契约版本，未来版本不能静默覆盖。
    pub schema_version: u32,
    /// 显式 IANA 时区，不依赖运行设备的当前时区。
    pub time_zone: String,
    /// 首批六地区之一，节假日数据按地区匹配。
    pub region: String,
    /// 用户指定的退休日期，未填写时不生成虚构目标。
    pub retirement_date: Option<String>,
    /// 生命倒计时输入。
    pub birth: Option<Birth>,
    /// 工作周与每天作息。
    pub schedule: Schedule,
    /// 薪资以十进制字符串保存，未填写时无薪资结果。
    pub salary: Option<Salary>,
    /// 发薪规则。
    pub payday: Option<Payday>,
    /// 是否将每周休息日纳入下次放假指标。
    pub weekly_rest_as_holiday: bool,
    /// 用户日期覆盖，优先级最高。
    pub date_overrides: BTreeMap<String, bool>,
    /// 用户自定义假期。
    pub holidays: Vec<Holiday>,
    /// 桌面自定义倒计时，移动小组件不会呈现这些项目。
    pub custom_countdowns: Vec<CustomCountdown>,
    /// 长期金额遮蔽偏好。
    pub hide_amount: bool,
    /// 客户端显示偏好，包含首次引导状态。
    pub display: DisplaySettings,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            schema_version: SCHEMA_VERSION,
            time_zone: "Asia/Shanghai".into(),
            region: "CN".into(),
            retirement_date: None,
            birth: None,
            schedule: Schedule::default(),
            salary: None,
            payday: None,
            weekly_rest_as_holiday: true,
            date_overrides: BTreeMap::new(),
            holidays: vec![],
            custom_countdowns: vec![],
            hide_amount: true,
            display: DisplaySettings::default(),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct Schedule {
    /// ISO 星期编号，周一为 1。
    pub workdays: Vec<u8>,
    /// 本地上班时间。
    pub start: String,
    /// 本地下班时间，不支持跨夜。
    pub end: String,
    /// 午休关闭时为 None。
    pub lunch: Option<[String; 2]>,
}
impl Default for Schedule {
    fn default() -> Self {
        Self {
            workdays: vec![1, 2, 3, 4, 5],
            start: "09:00".into(),
            end: "18:00".into(),
            lunch: Some(["12:00".into(), "13:00".into()]),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Birth {
    /// 出生日期。
    pub date: String,
    /// 出生时刻，省略时按 00:00 解释。
    pub time: Option<String>,
    /// 日历年寿命，十进制字符串，允许一位小数。
    #[serde(default = "default_lifespan")]
    pub life_expectancy_years: String,
}
fn default_lifespan() -> String {
    "100".into()
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Salary {
    /// 税前月薪，禁止二进制浮点。
    pub gross_monthly: String,
    /// 税后月薪，可选。
    pub net_monthly: Option<String>,
    /// 币种代码。
    #[serde(default)]
    pub currency: Option<String>,
    /// 金额显示小数位。
    #[serde(default = "default_salary_precision")]
    pub precision: u8,
    /// 税前或税后显示口径；默认税前。
    #[serde(default)]
    pub basis: SalaryBasis,
}

fn default_salary_precision() -> u8 {
    2
}

/// 冻结范围内的地区默认币种。
pub(crate) fn region_currency(region: &str) -> &'static str {
    match region {
        "US" => "USD",
        "JP" => "JPY",
        "KR" => "KRW",
        "HK" => "HKD",
        "TW" => "TWD",
        _ => "CNY",
    }
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SalaryBasis {
    #[default]
    Gross,
    Net,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Payday {
    /// 每月固定日、最后工作日或每月两次。
    pub rule: PaydayRule,
    /// 每月最后工作日用空数组，其余规则分别用一项或两项。
    pub days: Vec<u8>,
    /// 休息日顺延、提前或不调整。
    #[serde(default)]
    pub adjustment: PaydayAdjustment,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PaydayRule {
    FixedDay,
    LastWorkday,
    TwiceMonthly,
}

#[derive(Clone, Debug, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PaydayAdjustment {
    #[default]
    NextWorkday,
    PreviousWorkday,
    None,
}
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Holiday {
    /// 假期名称。
    pub name: String,
    /// 包含在假期内的起始日期。
    pub start: String,
    /// 包含在假期内的结束日期。
    pub end: String,
    /// 假期类型，不区分带薪/无薪。
    pub kind: String,
}
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CustomCountdown {
    /// 稳定标识。
    pub id: String,
    /// 桌面展示名称。
    pub name: String,
    /// 设置时区内的本地目标日期时间。
    pub target: String,
    /// 兼容旧配置，默认参与桌面显示列表。
    #[serde(default = "default_countdown_enabled")]
    pub enabled: bool,
    /// 省略时按原数组位置排序，相同排序键保持原先顺序。
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub order: Option<u32>,
}

fn default_countdown_enabled() -> bool {
    true
}

#[derive(Default, Debug, Serialize, Deserialize)]
#[serde(default, deny_unknown_fields)]
pub struct HolidayData {
    /// 数据契约版本；无数据时可省略并采用降级路径。
    pub schema_version: u32,
    /// 数据所属地区。
    pub region: String,
    /// 数据覆盖年份，不在列表内的日期按工作周回退。
    pub years: Vec<i16>,
    /// true 为补班，false 为休息日。
    pub date_overrides: BTreeMap<String, bool>,
}

#[derive(Debug, Serialize, Deserialize, PartialEq)]
pub struct FieldError {
    /// 错误字段路径，绝不含字段原值。
    pub field: String,
    /// 稳定错误码，由各端本地化。
    pub code: String,
}
