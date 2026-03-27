# IPL BTC Full Analysis V2 - Fixed P0 issues
# 修复: ICT趋势判断 + RSI指标 + 信号计算bug

$ErrorActionPreference = 'SilentlyContinue'

# ===== Step 1: Fetch data from alternative.me =====
$price = $null; $chg1h = $null; $chg24h = $null; $chg7d = $null; $vol24h = $null

try {
    $r = Invoke-WebRequest -Uri 'https://api.alternative.me/v2/ticker/bitcoin/?format=json' -TimeoutSec 12 -UseBasicParsing
    $data = $r.Content | ConvertFrom-Json
    $btc = $data.data.'1'
    $price = [double]$btc.quotes.USD.price
    $chg1h = [double]$btc.quotes.USD.percentage_change_1h
    $chg24h = [double]$btc.quotes.USD.percentage_change_24h
    $chg7d = [double]$btc.quotes.USD.percentage_change_7d
    $vol24h = [double]$btc.quotes.USD.volume_24h
    Write-Host "API:OK"
    Write-Host ("P:" + $price)
    Write-Host ("C1:" + $chg1h)
    Write-Host ("C24:" + $chg24h)
    Write-Host ("C7:" + $chg7d)
    Write-Host ("V24:" + [math]::Round($vol24h/1e9,2))
} catch {
    Write-Host ("API_ERR:" + $_.Exception.Message)
    exit 1
}

# ===== Step 2: Load history & Calculate BB/SMA/RSI =====
$hf = "C:\Users\86131\.qclaw\workspace\btc_price_history.md"
$prices = @()
Get-Content $hf | ForEach-Object {
    if ($_ -match "^\d{4}-\d{2}-\d{2}\s*\|\s*([\d.]+)") { $prices += [double]$Matches[1] }
}
# Add current price
$prices += $price

if ($prices.Count -lt 14) { Write-Host "NO_DATA"; exit 1 }

# Calculate SMAs
$sm5 = ($prices | Select-Object -Last 5 | Measure-Object -Average).Average
$sm20 = ($prices | Select-Object -Last 20 | Measure-Object -Average).Average
$sm14 = $null
if ($prices.Count -ge 14) { $sm14 = ($prices | Select-Object -Last 14 | Measure-Object -Average).Average }

# Calculate Standard Deviations
$r5 = $prices | Select-Object -Last 5
$r20 = $prices | Select-Object -Last 20
$sd5 = [math]::Sqrt(($r5 | ForEach-Object { [math]::Pow($_ - $sm5, 2) } | Measure-Object -Average).Average)
$sd20 = [math]::Sqrt(($r20 | ForEach-Object { [math]::Pow($_ - $sm20, 2) } | Measure-Object -Average).Average)

# Calculate BB Deviations
$cp = $prices[-1]
$bb5 = ($cp - $sm5) / (2 * $sd5)
$bb20 = ($cp - $sm20) / (2 * $sd20)

# Calculate RSI(14)
$rsi14 = $null
if ($prices.Count -ge 15) {
    $gains = 0; $losses = 0
    for ($i = $prices.Count - 14; $i -lt $prices.Count; $i++) {
        $delta = $prices[$i] - $prices[$i-1]
        if ($delta -gt 0) { $gains += $delta } else { $losses += [math]::Abs($delta) }
    }
    $avgGain = $gains / 14
    $avgLoss = $losses / 14
    if ($avgLoss -eq 0) { $rsi14 = 100 }
    else { $rs = $avgGain / $avgLoss; $rsi14 = 100 - (100 / (1 + $rs)) }
}

# Calculate momentum
$r5d = if ($prices.Count -ge 7) { (($cp - $prices[-7]) / $prices[-7]) * 100 } else { 0 }
$r20d = if ($prices.Count -ge 21) { (($cp - $prices[-21]) / $prices[-21]) * 100 } else { 0 }

Write-Host ("SM5:" + [math]::Round($sm5,2))
Write-Host ("SM20:" + [math]::Round($sm20,2))
Write-Host ("RSI14:" + [math]::Round($rsi14,2))

# ===== Step 3: LPPLS Scoring =====
$lBB = 0
if ($bb5 -ge 2.0) { $lBB = -15 } elseif ($bb5 -ge 1.5) { $lBB = -8 } elseif ($bb5 -ge 0.5) { $lBB = 0 } elseif ($bb5 -ge -1.0) { $lBB = 6 } elseif ($bb5 -ge -1.5) { $lBB = 8 } else { $lBB = 10 }
$lMo = 0
if ($r5d -gt 10) { $lMo = -8 } elseif ($r5d -gt 5) { $lMo = -4 } elseif ($r5d -gt 2) { $lMo = 0 } elseif ($r5d -gt -2) { $lMo = 3 } elseif ($r5d -gt -5) { $lMo = 4 } else { $lMo = 5 }
if ($r20d -gt 20) { $lMo -= 5 } elseif ($r20d -gt 10) { $lMo -= 2 } elseif ($r20d -lt -15) { $lMo += 5 } elseif ($r20d -lt -5) { $lMo += 2 }
$lSc = $lBB + $lMo
if ($lSc -gt 30) { $lSc = 30 }; if ($lSc -lt -10) { $lSc = -10 }

# Risk Level - FIX: properly check both BB5 and BB20
$rl = "NORMAL"
if ($bb20 -ge 2.0 -or $bb5 -ge 2.0) { $rl = "EXTREME_BUBBLE" }
elseif ($bb20 -ge 1.5 -or $bb5 -ge 1.5) { $rl = "BUBBLE" }
elseif ($bb20 -ge 0.5 -or $bb5 -ge 0.5) { $rl = "OVERHEATED" }
elseif ($bb20 -lt -1.5 -and $bb5 -lt -1.5) { $rl = "OVERSOLD" }
elseif ($bb20 -lt -0.5 -or $bb5 -lt -0.5) { $rl = "COOLING" }

$ld = "NEUTRAL"
if ($lSc -ge 25) { $ld = "STRONG_BUY" } elseif ($lSc -ge 20) { $ld = "BUY" } elseif ($lSc -ge 12) { $ld = "NEUTRAL" } elseif ($lSc -ge 5) { $ld = "CAUTION" } elseif ($lSc -ge -5) { $ld = "WARM" } else { $ld = "DANGER" }

Write-Host ("BB5:" + [math]::Round($bb5,4))
Write-Host ("BB20:" + [math]::Round($bb20,4))
Write-Host ("LSC:" + $lSc)
Write-Host ("RLE:" + $rl)

# ===== Step 4: ICT Trend (FIXED) =====
$trend = "RANGE"
$ts = 0

# Price vs SMA20 percentage
$priceVsSMA20 = ($cp - $sm20) / $sm20 * 100

if ($priceVsSMA20 -gt 1.0) {
    if ($r5d -gt 2) { $trend = "STRONG_UP"; $ts = 8 }
    elseif ($r5d -gt 0) { $trend = "UPTREND"; $ts = 5 }
    else { $trend = "WEAK_UP"; $ts = 2 }
}
elseif ($priceVsSMA20 -lt -1.0) {
    if ($r5d -lt -2) { $trend = "STRONG_DOWN"; $ts = -8 }
    elseif ($r5d -lt 0) { $trend = "DOWNTREND"; $ts = -5 }
    else { $trend = "WEAK_DOWN"; $ts = -2 }
}
# else: RANGE, ts = 0

# MSS Detection
$mss = "NONE"
if ($trend -eq "UPTREND" -or $trend -eq "STRONG_UP") { $mss = "BULLISH_MSS" }
elseif ($trend -eq "DOWNTREND" -or $trend -eq "STRONG_DOWN") { $mss = "BEARISH_MSS" }

Write-Host ("TR:" + $trend)
Write-Host ("TS:" + $ts)
Write-Host ("MSS:" + $mss)
Write-Host ("PVSMA20:" + [math]::Round($priceVsSMA20,4))

# ===== Step 5: PA Signal =====
$ps = 0; $pa = "NEUTRAL"
if ($chg1h -gt 1.5 -and $chg24h -gt 2) { $ps = 15; $pa = "STRONG_BULL" }
elseif ($chg1h -gt 0.5 -and $chg24h -gt 1) { $ps = 10; $pa = "BULL" }
elseif ($chg1h -lt -1.5 -and $chg24h -lt -2) { $ps = -15; $pa = "STRONG_BEAR" }
elseif ($chg1h -lt -0.5 -and $chg24h -lt -1) { $ps = -10; $pa = "BEAR" }
elseif ($chg24h -gt 0) { $ps = 3; $pa = "SLIGHT_BULL" }
elseif ($chg24h -lt 0) { $ps = -3; $pa = "SLIGHT_BEAR" }

Write-Host ("PA:" + $pa); Write-Host ("PSC:" + $ps)

# ===== Step 6: RSI Score =====
$rsiScore = 0
if ($rsi14 -ne $null) {
    if ($rsi14 -ge 70) { $rsiScore = -5 }
    elseif ($rsi14 -ge 60) { $rsiScore = -2 }
    elseif ($rsi14 -le 30) { $rsiScore = 5 }
    elseif ($rsi14 -le 40) { $rsiScore = 2 }
}
Write-Host ("RSI:" + [math]::Round($rsi14,2))
Write-Host ("RSI_SCORE:" + $rsiScore)

# ===== Step 7: Volume Score =====
$volScore = 0
if ($vol24h -gt 55e9) { $volScore = 2 }
elseif ($vol24h -lt 35e9) { $volScore = -2 }
Write-Host ("VOL_SCORE:" + $volScore)

# ===== Step 8: Final Score =====
# 修正逻辑：
# - LPPLS高分(+20~30) = 超卖 = 利多；LPPLS低分(-10~0) = 超买 = 利空
# - ICT上涨 = 利多；ICT下跌 = 利空
# - PA看多 = 利多；PA看空 = 利空
# - RSI<40 = 超卖 = 利多；RSI>60 = 超买 = 利空

# Long: 利多因素
$longScore = 0
# LPPLS: 高分=超卖=利多 (LSC 20-30 = +15分, 10-20 = +10分, <10 = +5分)
if ($lSc -ge 20) { $longScore += 15 }
elseif ($lSc -ge 10) { $longScore += 10 }
else { $longScore += 5 }
# ICT: 上涨趋势 = 利多
$longScore += [math]::Max(0, $ts)
# PA: 看多信号 = 利多
$longScore += [math]::Max(0, $ps)
# RSI: 超卖 = 利多 (RSI < 30 = +5, < 40 = +3)
if ($rsi14 -lt 30) { $longScore += 5 }
elseif ($rsi14 -lt 40) { $longScore += 3 }
# Volume: 高成交量 = 利多
$longScore += [math]::Max(0, $volScore)

# Short: 利空因素
$shortScore = 0
# LPPLS: 低分=超买=利空 (LSC < 0 = +15分, < 10 = +10分)
if ($lSc -le 0) { $shortScore += 15 }
elseif ($lSc -le 10) { $shortScore += 10 }
else { $shortScore += 5 }
# ICT: 下跌趋势 = 利空
$shortScore += [math]::Max(0, -$ts)
# PA: 看空信号 = 利空
$shortScore += [math]::Max(0, -$ps)
# RSI: 超买 = 利空 (RSI > 70 = +5, > 60 = +3)
if ($rsi14 -gt 70) { $shortScore += 5 }
elseif ($rsi14 -gt 60) { $shortScore += 3 }
# Volume: 低成交量 = 利空
$shortScore += [math]::Max(0, -$volScore)

# Scale to 0-100
# Max long: 15+8+15+5+2 = 45
# Max short: 15+8+15+5+2 = 45
$longNorm = [math]::Round($longScore / 45 * 100)
$shortNorm = [math]::Round($shortScore / 45 * 100)
if ($longNorm -gt 100) { $longNorm = 100 }
if ($shortNorm -gt 100) { $shortNorm = 100 }

# Normalize to 0-100 scale
# Max possible: LSC(30) + TS(8) + PS(15) + RSI(5) + VOL(2) = 60
$longNorm = [math]::Round($longScore / 60 * 100)
$shortNorm = [math]::Round($shortScore / 60 * 100)
if ($longNorm -gt 100) { $longNorm = 100 }
if ($shortNorm -gt 100) { $shortNorm = 100 }

Write-Host ("LNG_RAW:" + $longScore)
Write-Host ("SHT_RAW:" + $shortScore)
Write-Host ("LNG:" + $longNorm)
Write-Host ("SHT:" + $shortNorm)

# Final Signal
$fs = "WATCH"; $cf = [math]::Max($longNorm,$shortNorm)
if ($longNorm -gt 70) { $fs = "STRONG_LONG" }
elseif ($longNorm -gt 50) { $fs = "LIGHT_LONG" }
elseif ($shortNorm -gt 70) { $fs = "STRONG_SHORT" }
elseif ($shortNorm -gt 50) { $fs = "LIGHT_SHORT" }

Write-Host ("FS:" + $fs)
Write-Host ("CF:" + $cf)
Write-Host ("DP:" + $prices.Count)

# ===== JSON Output =====
$j = @{
    price = [math]::Round($price,2)
    chg1h = [math]::Round($chg1h,4)
    chg24h = [math]::Round($chg24h,4)
    chg7d = [math]::Round($chg7d,4)
    vol24h = [math]::Round($vol24h/1e9,2)
    bb5 = [math]::Round($bb5,4)
    bb20 = [math]::Round($bb20,4)
    sma5 = [math]::Round($sm5,2)
    sma20 = [math]::Round($sm20,2)
    rsi14 = [math]::Round($rsi14,2)
    ret5d = [math]::Round($r5d,2)
    ret20d = [math]::Round($r20d,2)
    volatility20 = [math]::Round($sd20,2)
    lpplsScore = $lSc
    lpplsDesc = $ld
    riskLevel = $rl
    trend = $trend
    trendScore = $ts
    mss = $mss
    paSignal = $pa
    paScore = $ps
    rsiScore = $rsiScore
    volScore = $volScore
    longScore = $longNorm
    shortScore = $shortNorm
    finalSignal = $fs
    confidence = $cf
    dataPoints = $prices.Count
} | ConvertTo-Json -Compress
Write-Host ("JSON:" + $j)
