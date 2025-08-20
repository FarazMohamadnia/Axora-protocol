import * as fs from "fs/promises";
import * as path from "path";
import { fileURLToPath } from "url";


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

// Function to log transaction
async function transactionLog(tx: any) {
  const transactionData = {
    hash: tx.hash,
    blockNumber: tx.blockNumber,
    gasUsed: tx.gasUsed.toString(),
    status: tx.status === 1 ? "Success" : "Failed",
    from: tx.from,
    to: tx.to,
    tokenAmount: tx.tokenAmount || 0,
    timestamp: new Date().toISOString(),
  };

  await appendToJsonFile(TRANSACTION_FILE_PATH, transactionData);
}

async function blok(blockNumber: number) {
  const blockData = {
    blockNumber,
    timestamp: new Date().toISOString(),
  };

  await appendToJsonFile(BLOCK_FILE_PATH, blockData);
}

async function address(account: string) {
  const addressData = {
    address: account,
    timestamp: new Date().toISOString(),
  };

  await appendToJsonFile(ADDRESS_FILE_PATH, addressData);
}

export { transactionLog, blok, address };
