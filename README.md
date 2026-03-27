# IPL Trading System

整合 LPPLS + ICT + PA + 归纳演绎验证 的加密货币交易分析系统

## 核心文件

- `run_ipl.ps1` - 主分析脚本（V2优化版）

## 功能

1. **LPPLS 泡沫分析** - BB偏离度判断超买超卖
2. **ICT 结构分析** - 趋势判断、MSS识别
3. **PA 形态确认** - K线形态信号
4. **RSI 指标** - 超买超卖辅助判断
5. **综合评分** - 多空信号量化输出

## 使用方法

```powershell
powershell -ExecutionPolicy Bypass -File "run_ipl.ps1"
```

## 数据源

- alternative.me API (https://api.alternative.me/v2/ticker/bitcoin/)

## 输出示例

```json
{
  "price": 68580,
  "bb5": -0.49,
  "bb20": -0.83,
  "rsi14": 41.84,
  "trend": "DOWNTREND",
  "mss": "BEARISH_MSS",
  "longScore": 8,
  "shortScore": 30,
  "finalSignal": "WATCH"
}
```

## 信号阈值

- 70+ : 强烈信号
- 50-70 : 轻度信号
- <50 : 观望
