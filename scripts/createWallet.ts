import { ethers } from "ethers";
import * as fs from "fs";
import * as path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function main() {
  console.log("🔐 Creating wallet and network configuration...");

  // Generate a new wallet
  const wallet = ethers.Wallet.createRandom();

  console.log("✅ New wallet created:");
  console.log("📱 Address (Public Key):", wallet.address);
  console.log("🔑 Private Key:", wallet.privateKey);
  console.log("📝 Mnemonic:", wallet.mnemonic?.phrase);

  // Network configuration
  const networkConfig = {
    name: "Sepolia Testnet",
    chainId: 11155111, // Sepolia testnet chain ID
    rpcUrl: "https://sepolia.infura.io/v3/YOUR-PROJECT-ID", // Sepolia RPC URL
    nativeCurrency: {
      name: "Sepolia Ether",
      symbol: "SEP",
      decimals: 18,
    },
    blockExplorerUrls: ["https://sepolia.etherscan.io"],
  };

  // Local network configuration (commented out)
  /*
  const localNetworkConfig = {
    name: "Local Hardhat Network",
    chainId: 1337, // Local network ID
    rpcUrl: "http://127.0.0.1:8545", // Local Hardhat node
    nativeCurrency: {
      name: "Ether",
      symbol: "ETH",
      decimals: 18,
    },
    blockExplorerUrls: [],
  };
  */

  // Save wallet info to a secure file
  const walletData = {
    address: wallet.address,
    privateKey: wallet.privateKey,
    mnemonic: wallet.mnemonic?.phrase,
    network: networkConfig,
  };

  const walletPath = path.join(__dirname, "../accounts/wallet.json");
  fs.writeFileSync(walletPath, JSON.stringify(walletData, null, 2));

  console.log("\n💾 Wallet information saved to:", walletPath);
  console.log(
    "\n⚠️  IMPORTANT: Keep your private key secure and never share it!"
  );
  console.log("🔗 Network RPC URL:", networkConfig.rpcUrl);
  console.log("🆔 Chain ID:", networkConfig.chainId);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Error:", error);
    process.exit(1);
  });
