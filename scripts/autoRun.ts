import { spawn, exec } from "child_process";
import { promisify } from "util";
import { existsSync } from "fs";
import * as dotenv from "dotenv";

// Load environment variables
dotenv.config();

const execAsync = promisify(exec);

console.log("🚀 Starting SuperToken Automation...\n");

// Function to run commands
function runCommand(command: string, args: string[], options: any = {}) {
  const defaultCwd = process.env.PROJECT_PATH;
  const cwd = options.cwd || defaultCwd;

  if (!existsSync(cwd)) {
    return Promise.reject(new Error(`Directory ${cwd} does not exist`));
  }

  return new Promise<void>((resolve, reject) => {
    const child = spawn(command, args, {
      stdio: "inherit",
      shell: true,
      cwd,
      ...options,
    });

    child.on("close", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`Command failed with exit code ${code}`));
      }
    });

    child.on("error", (error: any) => {
      if (error.code === "EACCES") {
        reject(
          new Error(
            `Permission denied for directory ${cwd}. Check access rights.`
          )
        );
      } else {
        reject(error);
      }
    });
  });
}

// Function to check if Hardhat node is running
async function isNodeRunning() {
  try {
    await execAsync("curl -s http://localhost:8545");
    return true;
  } catch {
    return false;
  }
}

// Main automation function
export async function runAutomation() {
  let nodeProcess: any;

  try {
    console.log("📡 Starting Hardhat node...");

    // Start Hardhat node with inherited stdio
    nodeProcess = spawn("npm", ["run", "node"], {
      stdio: "inherit",
      shell: true,
    });

    nodeProcess.on("error", (error: any) => {
      console.error("❌ Error starting node:", error);
      process.exit(1);
    });

    // Wait for node to start
    console.log("⏳ Waiting for node to start...");
    let nodeReady = false;
    const maxAttempts = 10;
    let attempts = 0;

    while (!nodeReady && attempts < maxAttempts) {
      nodeReady = await isNodeRunning();
      if (!nodeReady) {
        await new Promise((resolve) => setTimeout(resolve, 2000));
        attempts++;
      }
    }

    if (!nodeReady) {
      console.error("❌ Hardhat node failed to start after waiting.");
      nodeProcess.kill();
      process.exit(1);
    }

    console.log(
      "✅ Hardhat node is running. Starting contract deployment...\n"
    );

    // Deploy token
    console.log("🪙 Deploying Token contract...");
    await runCommand("npm", ["run", "token"]);
    console.log("✅ Token deployed successfully!\n");

    // Deploy airdrop
    console.log("🎁 Deploying Airdrop contract...");
    await runCommand("npm", ["run", "airdrop"]);
    console.log("✅ Airdrop deployed successfully!\n");

    console.log("🎉 All contracts deployed successfully!");
    console.log("💡 You can now run your test scripts.");
  } catch (error) {
    console.error("❌ Error during automation:", error);
    nodeProcess.kill();
    process.exit(1);
  }
}

runAutomation();
