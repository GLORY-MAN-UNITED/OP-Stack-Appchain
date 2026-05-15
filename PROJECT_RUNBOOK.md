# Payment Appchain Project Runbook

本项目对应 `requirement.md` 的 Option 2：`Payment Appchain Built on OP Stack`。

当前最小可汇报版本是：已经基于 OP Stack 在本地启动一条 L2 appchain，并使用 Ethereum Sepolia 作为 L1。后续 02/03/04/05 会在这条链上继续做支付合约、压测、前端和结果分析。

## 1. 如何启动项目

### 前置条件

- 已打开 Docker Desktop。
- 网络可以访问 Sepolia RPC 和 Beacon API。校园网偶尔会屏蔽部分区块链节点，如果失败优先换热点或 VPN。
- `01-node-infra/.env` 已经填好，不要提交这个文件。

### 启动命令

在 PowerShell 进入项目根目录：

```powershell
cd D:\code_SG\6109
```

先检查网络、Docker、Sepolia 余额：

```powershell
.\01-node-infra\scripts\test-network.ps1
```

启动 OP Stack 本地运行组件：

```powershell
.\01-node-infra\scripts\up.ps1
```

查看容器状态：

```powershell
.\01-node-infra\scripts\status.ps1
```

查看日志：

```powershell
.\01-node-infra\scripts\logs.ps1
```

停止项目：

```powershell
.\01-node-infra\scripts\down.ps1
```

注意：不要随便运行下面这个命令：

```powershell
.\01-node-infra\scripts\setup-rollup.ps1 -Reset
```

`-Reset` 会重新生成部署状态并可能再次消耗 Sepolia ETH。日常启动只需要 `up.ps1`。

## 2. 当前 01 是否符合 requirement

`requirement.md` 要求项目做一个基于 OP Stack 的 payment appchain，核心包括：

- 部署基础 payment appchain。
- 实现支付应用逻辑。
- 设计适合小额高频支付的 fee model。
- 提供支付 UI。
- 做 TPS、确认时间、费用对比分析。

当前 `01-node-infra` 已经完成的是第一部分：Appchain 底层与运维。

### 已完成内容

- 已部署 OP Stack L2 appchain。
- L1 使用 Ethereum Sepolia。
- 本地运行 `op-geth`、`op-node`、`op-batcher`、`op-proposer`。
- Sequencer 可以持续出块。
- Local L2 RPC 可以接收 JSON-RPC 请求。
- Batcher 已经可以向 Sepolia 提交 calldata batch。
- Proposer 已经连接到 DisputeGameFactory 并启动。

### 当前链信息

- L2 chain ID: `61091`
- L2 RPC: `http://localhost:8545`
- Rollup RPC: `http://localhost:8547`
- Sepolia 部署交易: `0x7f7b1f1036b392122900a9ca3c22fb8ea84208bf7a68cb6d6efb0cead9fa0dee`
- SystemConfigProxy: `0xcfa802ec1973a2f40d715df39582f6fe61595dc4`
- DisputeGameFactoryProxy: `0xf328b35415aa79a1b279881d739fbbe78e04f041`

更详细记录见：

```text
01-node-infra/notes/deployment-status.md
```

### 对“一号位 Node & Infra Lead”的完成情况

已经满足：

- 本地部署 OP Stack 测试网。
- 配置 Sequencer 和 RPC 节点。
- 配置 L1 Sepolia 与 L2 appchain 的运行关系。
- 使用 Docker Compose 管理节点。
- 编写 PowerShell 自动化脚本。
- 能通过命令检查节点运行状态。

尚未完全覆盖：

- 云服务器部署还没做，目前是本地单机部署。
- 桥接机制只做到 OP Stack 基础 L1/L2 数据提交，还没有做用户侧 bridge UI。
- 高并发稳定性还需要 03 的压测数据证明。

结论：01 角色可以认为已经完成 MVP，足够向老师汇报“底层链已经跑起来”。整个课程项目还没完成，因为 02/03/04/05 还要继续。

## 3. 后续 02/03 应该怎么做

### 02-smart-contract

目标：在本地 L2 上部署支付相关智能合约。

建议最小实现：

- `MockUSDC`: 测试用 ERC-20，模拟稳定币。
- `PaymentLedger`: 记录付款人、商户、金额、订单号、时间。
- `FeeVault`: 收取极低比例手续费，例如 `0.1%` 或固定小额 fee。
- 合约测试：正常支付、余额不足、重复订单、手续费计算。

推荐技术栈：

- Foundry。
- Solidity。
- OpenZeppelin Contracts。

部署目标：

```text
RPC_URL=http://localhost:8545
CHAIN_ID=61091
```

02 完成后，项目就能从“链跑起来”变成“链上真的有支付应用”。

### 03-backend-simulation

目标：模拟大量用户和商户交易，产生性能数据。

建议最小实现：

- 读取 02 部署后的合约地址。
- 创建一批测试钱包。
- 批量发送 `payMerchant(...)` 交易。
- 记录每笔交易的发送时间、上链时间、gasUsed、effectiveGasPrice。
- 输出 CSV 或 JSON 报告。

核心指标：

- TPS: 单位时间内确认的支付交易数。
- 平均确认时间: `receipt timestamp - send timestamp`。
- 平均 gas: 每笔支付的 `gasUsed`。
- 费用估算: `gasUsed * gasPrice`。
- 对比 Sepolia 普通 ERC-20 transfer 的成本和确认时间。

建议先用 Node.js + Ethers.js 做，因为和前端/合约部署衔接最简单。

## 4. 如何做链测试

### 基础连通性测试

检查 L2 chain ID：

```powershell
$body = @{jsonrpc="2.0";id=1;method="eth_chainId";params=@()} | ConvertTo-Json -Compress
Invoke-RestMethod -Method Post -Uri "http://localhost:8545" -Body $body -ContentType "application/json"
```

期望返回：

```text
0xeea3
```

`0xeea3` 转成十进制就是 `61091`。

检查 L2 当前区块：

```powershell
$body = @{jsonrpc="2.0";id=1;method="eth_blockNumber";params=@()} | ConvertTo-Json -Compress
Invoke-RestMethod -Method Post -Uri "http://localhost:8545" -Body $body -ContentType "application/json"
```

如果区块号持续增长，说明 Sequencer 正在出块。

检查 rollup 同步状态：

```powershell
$body = @{jsonrpc="2.0";id=1;method="optimism_syncStatus";params=@()} | ConvertTo-Json -Compress
Invoke-RestMethod -Method Post -Uri "http://localhost:8547" -Body $body -ContentType "application/json"
```

重点看：

- `unsafe_l2.number` 是否增长。
- `current_l1.number` 是否能跟上 Sepolia。

### 运维日志测试

查看 op-node 是否出块：

```powershell
docker logs --tail 50 op-node
```

看到 `Sequencer inserted block` 说明 Sequencer 正常。

查看 batcher 是否提交到 Sepolia：

```powershell
docker logs --tail 80 op-batcher
```

看到 `Transaction confirmed` 和 `Channel is fully submitted` 说明 L2 数据已经提交到 L1。

查看 proposer：

```powershell
docker logs --tail 80 op-proposer
```

看到 `Connected to DisputeGameFactory` 和 `Proposer started` 说明 proposer 正常启动。

### 应用层测试

02 完成后再做：

- 部署 MockUSDC。
- 给测试钱包 mint 代币。
- 调用支付合约付款。
- 用 `eth_getTransactionReceipt` 验证交易成功。
- 对 100、1000、10000 笔支付做批量测试。

## 5. 为什么 Docker Desktop 里可能看不到

命令行已经是最准确的判断方式。只要下面命令能看到容器，就说明 Docker 正在运行：

```powershell
docker ps
```

当前应该能看到：

- `op-geth`
- `op-node`
- `op-batcher`
- `op-proposer`

如果 Docker Desktop 图形界面看不到，常见原因是：

- Docker Desktop UI 没刷新，切换到 `Containers` 页面再刷新。
- 容器被折叠在 compose project 分组里，不一定直接显示为四个大卡片。
- 当前看的是 `Images` 页面，不是 `Containers` 页面。
- Docker Desktop 只显示运行中的容器，如果刚执行过 `down.ps1` 就不会看到。
- Windows Docker context 和终端 context 不一致，可以用 `docker context ls` 检查。

建议以这两个命令为准：

```powershell
.\01-node-infra\scripts\status.ps1
docker ps
```

如果这两个命令能看到容器，项目就是在跑的。

## 6. 给老师的简短汇报说法

我们选择了 Option 2，做一个面向支付场景的 OP Stack appchain。当前 01 号位已经完成底层链部署：L1 使用 Ethereum Sepolia，本地通过 Docker Compose 运行 op-geth、op-node、op-batcher 和 op-proposer，L2 chain ID 是 61091，本地 RPC 是 `http://localhost:8545`。目前 Sequencer 可以持续出块，batcher 已经能把 L2 数据提交到 Sepolia，说明 appchain 的基础运行链路已经打通。

下一步会在 02 中实现支付合约，例如 MockUSDC 和 merchant payment ledger；03 会写压测脚本模拟大量支付交易，统计 TPS、确认时间和费用；04 做一个简单支付 UI；05 汇总性能数据并和 Sepolia 普通交易做对比。
