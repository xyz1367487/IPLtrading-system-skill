---
name: trading-system
description: 加密货币交易分析系统。用于：(1) 获取实时价格 (2) 市场分析 (3) 制定交易计划 (4) 计算止盈止损 (5) 仓位管理建议。触发条件：用户提到交易、炒币、买币、卖币、BTC、ETH、价格、持仓、盈利、亏损、止损、止盈、仓位、入场、出场等技术分析相关内容。
---

# Trading System

加密货币交易分析系统

## 1. 获取实时价格

按优先级尝试以下数据源：

### Primary - Kraken
```
https://www.kraken.com/charts
https://www.kraken.com/prices/bitcoin
```

### Secondary - CoinGecko (推荐)
```
https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd,cny
```
通过 r.jina.ai 代理访问：`https://r.jina.ai/https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd`

### Tertiary - 其他交易所
- Binance: `/en/price/bitcoin`
- Coinbase: `/en/coins/bitcoin`

### 获取方式
使用 web-markdown skill 的方法：
1. **CoinGecko** - 首选，通过 r.jina.ai 代理
2. `r.jina.ai` - 通用
3. `markdown.new` - Cloudflare 网站
4. `defuddle.md` - 备选

## 2. 市场分析模板

### 基础数据
| 项目 | 数据 |
|------|------|
| 当前价格 | $XX,XXX |
| 24h 涨跌 | ±X.XX% |
| 7日涨跌 | ±X.XX% |
| 成交量 | $XX B |

### 情绪指标
- 买卖比: XX% 买入 / XX% 卖出
- 恐惧贪婪指数: XX (XX-XX)
- 合约持仓量变化
- ETF 资金流向

### 技术面
- 支撑位: $XX,XXX
- 阻力位: $XX,XXX
- MA 均线的位置关系
- RSI: XX (超买/超卖/中性)

### 基本面
- 机构动态
- 监管消息
- 链上数据变化
- 热点新闻

## 3. 交易计划模板

### 短线策略 (1-7天)
- 入场区间: $XX,XXX - $XX,XXX
- 止损: $XX,XXX (-X%)
- 目标1: $XX,XXX (+X%)
- 目标2: $XX,XXX (+X%)

### 中线策略 (1-3月)
- 支撑位分批建仓: $XX,XXX / $XX,XXX
- 目标: $XX,XXX - $XX,XXX

### 仓位建议
| 风险偏好 | 建议仓位 |
|----------|----------|
| 保守 | 20-30% |
| 均衡 | 40-50% |
| 激进 | 60-70% |

## 4. 止盈止损计算

### 固定比例法
- 止盈: 入场价 × (1 + 目标比例)
- 止损: 入场价 × (1 - 止损比例)
- 盈亏比: (目标涨幅) / (止损跌幅)

### 移动止盈
- 价格上涨 X% 后，调整止损至成本价
- 继续上涨 Y% 后，移动止盈

## 5. 风险提示

- 市场有风险，投资需谨慎
- 建议设置止盈止损
- 不要 FOMO 入场
- 分散投资，不要 All In

## 数据来源

- 价格: CoinGecko, Kraken, Binance, Coinbase
- 情绪: Santiment, Alternative.me
- 资金流: SoSoValue, Glassnode
- 新闻: 吴说区块链, The Block, Cointelegraph
