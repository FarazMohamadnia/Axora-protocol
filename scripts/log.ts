import { network } from "hardhat";
import * as fs from "fs/promises";
import * as path from "path";
import { fileURLToPath } from "url";
import * as dotenv from "dotenv";

// Load environment variables
dotenv.config();

const { ethers } = await network.connect({
  network: "localhost",
  chainType: "l1",
});

const usersData = JSON.parse(await fs.readFile("accounts/users.json", "utf8"));

// Get token address from environment variable
const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "";

// Get current directory for ES modules
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Paths for the files - create in project root
const TRANSACTION_FILE_PATH = path.join(
  __dirname,
  "..",
  "blockchain",
  "transaction.json"
);
const ADDRESS_FILE_PATH = path.join(
  __dirname,
  "..",
  "blockchain",
  "address.json"
);
const BLOCK_FILE_PATH = path.join(__dirname, "..", "blockchain", "block.json");

// Function to ensure the directory exists
async function ensureDirectoryExists(filePath: string) {
  const dir = path.dirname(filePath);
  await fs.mkdir(dir, { recursive: true });
}

// Function to initialize the JSON file with an empty array
async function initializeJsonFile(filePath: string) {
  try {
    const fileContent = await fs.readFile(filePath, "utf-8");
    // Try to parse existing content, if it fails, recreate the file
    JSON.parse(fileContent);
  } catch {
    // File doesn't exist or is corrupted, create new one
    await fs.writeFile(filePath, JSON.stringify([]));
  }
}

// Function to append data to the JSON file
async function appendToJsonFile(filePath: string, data: any) {
  try {
    await ensureDirectoryExists(filePath);
    await initializeJsonFile(filePath);

    let jsonData = [];
    try {
      const fileContent = await fs.readFile(filePath, "utf-8");
      jsonData = JSON.parse(fileContent);
    } catch {
      // If file is corrupted, start with empty array
      jsonData = [];
    }

    jsonData.push(data);
    await fs.writeFile(filePath, JSON.stringify(jsonData, null, 2));
    console.log(`Data successfully appended to ${filePath}`);
  } catch (error) {
    console.error(`Error appending to JSON file (${filePath}):`, error);
  }
}

// Function to update existing data in the JSON file (only for address function)
async function updateJsonFile(filePath: string, data: any) {
  try {
    await ensureDirectoryExists(filePath);
    await initializeJsonFile(filePath);

    let jsonData = [];
    try {
      const fileContent = await fs.readFile(filePath, "utf-8");
      jsonData = JSON.parse(fileContent);
    } catch {
      // If file is corrupted, start with empty array
      jsonData = [];
    }

    // Update existing entries or add new ones
    for (const newUser of data.users) {
      const existingIndex = jsonData.findIndex(
        (user: any) => user.address === newUser.address
      );
      if (existingIndex !== -1) {
        // Update existing user's balances
        jsonData[existingIndex].tokenBalance = newUser.tokenBalance;
        jsonData[existingIndex].ethBalance = newUser.ethBalance;
        jsonData[existingIndex].lastUpdated = new Date().toISOString();
      } else {
        // Add new user if not exists
        jsonData.push({
          ...newUser,
          lastUpdated: new Date().toISOString(),
        });
      }
    }

    await fs.writeFile(filePath, JSON.stringify(jsonData, null, 2));
    console.log(`Data successfully updated in ${filePath}`);
  } catch (error) {
    console.error(`Error updating JSON file (${filePath}):`, error);
  }
}

// Function to log transaction
async function transactionLog(tx: any) {
  const transactionData = {
    hash: tx.hash,
    blockNumber: tx.blockNumber,
    gasUsed: tx?.gasUsed?.toString(),
    status: tx.status === 1 ? "Success" : "Failed",
    from: tx.from,
    to: tx.to,
    tokenAmount: tx.tokenAmount || 0,
    timestamp: new Date().toISOString(),
  };

  await appendToJsonFile(TRANSACTION_FILE_PATH, transactionData);
}

async function blok(blokData: any) {
  const blockData = {
    blockNumber: blokData.blockNumber,
    timestamp: new Date().toISOString(),
  };

  await appendToJsonFile(BLOCK_FILE_PATH, blockData);
}

async function address() {
  const token = await ethers.getContractAt("Token", TOKEN_ADDRESS);
  const users = [];

  for (const key in usersData) {
    const user = usersData[key];
    const ethBalance = await ethers.provider.getBalance(user.address);
    const tokenBalance = await token.balanceOf(user.address);
    users.push({
      name: key,
      address: user.address,
      tokenBalance: tokenBalance.toString(), // Convert BigInt to string
      ethBalance: ethers.formatEther(ethBalance),
    });
  }

  const addressData = {
    users,
    timestamp: new Date().toISOString(),
  };

  await updateJsonFile(ADDRESS_FILE_PATH, addressData);
  console.log("Address data logged successfully");
}
export { transactionLog, blok, address };
