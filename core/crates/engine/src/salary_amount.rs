use rust_decimal::Decimal;

/// 兼容已有 Decimal 输入格式。超出其小数容量的尾数向零截断。
pub(crate) fn parse_monthly_amount(raw: &str) -> Option<Decimal> {
    if let Ok(amount) = Decimal::from_str_exact(raw) {
        return (amount >= Decimal::ZERO).then_some(amount);
    }
    // 保留旧版对科学计数法等格式的接受范围，只修正默认解析的舍入。
    raw.parse::<Decimal>().ok()?;
    let (base, exponent) = match raw.split_once(['e', 'E']) {
        Some((base, exponent)) => (base, exponent.parse::<i32>().ok()?),
        None => (raw, 0),
    };
    let fractional_digits = base.split_once('.').map_or(0, |(_, part)| {
        part.bytes().filter(u8::is_ascii_digit).count()
    });
    let mut digits: Vec<_> = base.bytes().filter(u8::is_ascii_digit).collect();
    if base.starts_with('-') && digits.iter().any(|digit| *digit != b'0') {
        return None;
    }
    let mut scale = (fractional_digits as i32).checked_sub(exponent)?;
    if scale > Decimal::MAX_SCALE as i32 {
        let excess = (scale - Decimal::MAX_SCALE as i32) as usize;
        digits.truncate(digits.len().saturating_sub(excess));
        scale = Decimal::MAX_SCALE as i32;
    }
    let limit = Decimal::MAX.mantissa();
    let mut mantissa = 0;
    for (index, digit) in digits.iter().enumerate() {
        let next = mantissa * 10 + i128::from(*digit - b'0');
        if next > limit {
            scale -= (digits.len() - index) as i32;
            return Decimal::try_from_i128_with_scale(mantissa, scale.try_into().ok()?).ok();
        }
        mantissa = next;
    }
    if scale < 0 {
        mantissa = mantissa.checked_mul(10_i128.checked_pow(scale.unsigned_abs())?)?;
        scale = 0;
    }
    Decimal::try_from_i128_with_scale(mantissa, scale as u32).ok()
}
