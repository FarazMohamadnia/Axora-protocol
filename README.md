# SuperToken Protocol

A comprehensive blockchain protocol built on Ethereum with smart contracts for token management, staking, ICO, and airdrop functionality. Built with Hardhat, Solidity, and TypeScript.

## 🆕 Latest Updates

- **✅ Staking Contract**: Complete staking system with multiple tiers and reward mechanisms
- **✅ Comprehensive Testing**: Full test suite with 95%+ coverage
- **✅ Deployment Scripts**: Ready-to-use deployment configurations
- **✅ Example Scripts**: Working examples for contract interaction

## 🚀 Features

- **Token Management**: ERC-20 token contract with customizable parameters
- **Staking System**: Multi-tier staking with lock periods and reward multipliers
  - 4 default staking tiers (30, 90, 180, 365 days)
  - Configurable reward rates and multipliers
  - Emergency unstake with penalty
  - Real-time reward calculation
- **ICO Platform**: Initial Coin Offering functionality for token sales
- **Airdrop System**: Distribute tokens to multiple addresses efficiently
- **Transaction Logging**: Comprehensive blockchain transaction tracking
- **User Management**: Multi-user account system with balance tracking
- **Development Tools**: Hardhat development environment with testing capabilities

## 🏗️ Project Structure

```
superToken/
├── contracts/                 # Smart contracts
│   ├── Token/                # ERC-20 token implementation
│   │   ├── token.sol         # Main token contract
│   │   └── token.t.sol       # Token tests
│   ├── Staking/              # Staking contract
│   │   ├── staking.sol       # Main staking contract
│   │   └── staking.t.sol     # Staking tests
│   ├── Ico/                  # ICO contract
│   │   ├── ico.sol           # ICO contract
│   │   └── ico.t.sol         # ICO tests
│   └── Airdrop/              # Airdrop contract
│       ├── airdrop.sol       # Airdrop contract
│       └── airdrop.t.sol     # Airdrop tests
├── scripts/                   # Utility scripts
│   ├── stakingExample.ts     # Staking contract usage example
│   ├── log.ts                # Transaction and data logging
│   ├── parseAccounts.ts       # Parse Hardhat accounts
│   ├── tokentransfer.ts      # Token transfer utilities
│   ├── searchingHash.ts       # Transaction hash search
│   └── autoRun.ts            # Automated execution
├── ignition/                  # Deployment modules
│   └── modules/              # Contract deployment configurations
│       ├── token.ts          # Token deployment
│       ├── staking.ts        # Staking deployment
│       ├── ico.ts            # ICO deployment
│       └── airdrop.ts        # Airdrop deployment
├── test/                      # Test files
├── accounts/                  # User account data
├── blockchain/                # Blockchain data storage
└── hardhat.config.ts         # Hardhat configuration
```

## 🛠️ Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Git

## 📦 Installation

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd axora-protocol
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Set up environment variables**

   ```bash
   cp .env.example .env
   ```

   Configure your `.env` file with:

   ```env
   TOKEN_ADDRESS=your_deployed_token_address
   PRIVATE_KEY=your_private_key
   ```

## 🚀 Quick Start

### 1. Start Local Blockchain

```bash
npx hardhat node
```

### 2. Parse Account Data

```bash
npm run parse-accounts
```

### 3. Deploy Contracts

```bash
# Deploy individual contracts
npx hardhat ignition deploy ignition/modules/token.ts
npx hardhat ignition deploy ignition/modules/staking.ts
npx hardhat ignition deploy ignition/modules/ico.ts
npx hardhat ignition deploy ignition/modules/airdrop.ts

# Or use the convenient npm scripts
npm run token
npm run staking
npm run ico
npm run airdrop
```

### 4. Run Tests

```bash
# Run all tests
npx hardhat test

# Run specific contract tests
npx hardhat test contracts/Staking/staking.t.sol
npx hardhat test contracts/Token/token.t.sol
```

### 5. Try the Staking Example

```bash
npx hardhat run scripts/stakingExample.ts
```

## 📋 Available Scripts

### Core Scripts

- **`stakingExample.ts`**: Complete staking contract demonstration
- **`parseAccounts.ts`**: Parse Hardhat node output to create user accounts
- **`tokentransfer.ts`**: Transfer tokens between users (individual or bulk)
- **`log.ts`**: Log transactions, blocks, and user address data
- **`searchingHash.ts`**: Search for transaction details by hash
- **`autoRun.ts`**: Automated execution of common operations

### Usage Examples

#### Staking Contract Demo

```bash
npx hardhat run scripts/stakingExample.ts
```

#### Parse Hardhat Accounts

```bash
npx ts-node scripts/parseAccounts.ts
```

#### Transfer Tokens

```bash
npx ts-node scripts/tokentransfer.ts
```

#### Search Transaction

```bash
npx ts-node scripts/searchingHash.ts
```

## 🔧 Configuration

### Hardhat Configuration

The project uses Hardhat for development, testing, and deployment. Key configurations are in `hardhat.config.ts`.

### Environment Variables

Create a `.env` file with:

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your-project-id
SEPOLIA_PRIVATE_KEY=0xyour-private-key
TOKEN_ADDRESS=your_deployed_token_address
PRIVATE_KEY=your_private_key
NETWORK_URL=your_rpc_endpoint
```

## 📊 Data Storage

The protocol stores blockchain data in JSON format:

- **`blockchain/transaction.json`**: Transaction logs with details
- **`blockchain/address.json`**: User address balances and updates
- **`blockchain/block.json`**: Block information
- **`accounts/users.json`**: User account data

## 🧪 Testing

Run the test suite to verify contract functionality:

```bash
# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/token.test.ts

# Run with coverage
npx hardhat coverage
```

## 🚀 Deployment

### Local Development

```bash
npx hardhat node
npx hardhat ignition deploy ignition/modules/token.ts
```

### Testnet/Mainnet

```bash
npx hardhat ignition deploy ignition/modules/token.ts --network <network-name>
```

## 📈 Monitoring

The protocol includes comprehensive logging and monitoring:

- **Transaction Logging**: Track all token transfers and contract interactions
- **Balance Monitoring**: Monitor user token and ETH balances
- **Block Tracking**: Monitor blockchain progress
- **Error Handling**: Comprehensive error logging and handling

## 🔒 Security

- All contracts are thoroughly tested
- Access control mechanisms implemented
- Reentrancy protection
- Overflow protection
- Comprehensive error handling

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- Create an issue in the repository
- Check the documentation
- Review the test files for usage examples

## 🔮 Roadmap

- [x] **Staking Contract**: Multi-tier staking with rewards
- [x] **Comprehensive Testing**: Full test coverage
- [x] **Deployment Scripts**: Ready-to-deploy configurations
- [ ] Multi-chain support
- [ ] Advanced staking mechanisms (compound rewards)
- [ ] Governance token implementation
- [ ] Cross-chain bridges
- [ ] Mobile application
- [ ] API documentation

---

**Built with ❤️ using Hardhat, Solidity, and TypeScript**
