import { spawn, exec } from "child_process";
import { promisify } from "util";
import { existsSync } from "fs";
import * as dotenv from "dotenv";

// Load environment variables from .env file
dotenv.config();

// Convert exec to promise-based for async/await usage
const execAsync = promisify(exec);

console.log("🚀 Starting SuperToken Automation...\n");

/**
 * @dev Executes shell commands with proper error handling and directory management
 * @param command The command to execute (e.g., "npm", "npx")
 * @param args Array of command arguments
 * @param options Additional options including working directory
 * @returns Promise that resolves when command completes successfully
 * @notice Inherits stdio for real-time output display
 */
function runCommand(command: string, args: string[], options: any = {}) {
  // Get working directory from environment or use provided option
  const defaultCwd = process.env.PROJECT_PATH;
  const cwd = options.cwd || defaultCwd;

  // Validate that the working directory exists
  if (!existsSync(cwd)) {
    return Promise.reject(new Error(`Directory ${cwd} does not exist`));
  }

  return new Promise<void>((resolve, reject) => {
    // Spawn child process with specified options
    const child = spawn(command, args, {
      stdio: "inherit", // Show real-time output
      shell: true, // Use shell for command execution
      cwd, // Set working directory
      ...options, // Apply any additional options
    });

    // Handle successful command completion
    child.on("close", (code) => {
      if (code === 0) {
        resolve(); // Command succeeded
      } else {
        reject(new Error(`Command failed with exit code ${code}`));
      }
    });

    // Handle command execution errors
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

/**
 * @dev Checks if Hardhat node is running by testing the RPC endpoint
 * @returns Promise<boolean> True if node is responding, false otherwise
 * @notice Uses curl to test localhost:8545 (default Hardhat port)
 */
async function isNodeRunning() {
  try {
    // Test if Hardhat node responds on port 8545
    await execAsync("curl -s http://localhost:8545");
    return true; // Node is responding
  } catch {
    return false; // Node is not responding
  }
}

/**
 * @dev Main automation function that orchestrates the entire deployment process
 * @notice This function:
 * 1. Starts a Hardhat node in the background
 * 2. Waits for the node to be ready
 * 3. Deploys the Token contract
 * 4. Deploys the Airdrop contract
 * 5. Provides status updates throughout the process
 */
export async function runAutomation() {
  let nodeProcess: any; // Store reference to node process for cleanup

  try {
    console.log("📡 Starting Hardhat node...");

    // Start Hardhat node with inherited stdio for real-time output
    nodeProcess = spawn("npm", ["run", "node"], {
      stdio: "inherit", // Show node output in real-time
      shell: true, // Use shell for command execution
    });

    // Handle errors during node startup
    nodeProcess.on("error", (error: any) => {
      console.error("❌ Error starting node:", error);
      process.exit(1);
    });

    // Wait for Hardhat node to be ready and responding
    console.log("⏳ Waiting for node to start...");
    let nodeReady = false;
    const maxAttempts = 10; // Maximum attempts to check node status
    let attempts = 0; // Current attempt counter

    // Poll the node until it's ready or max attempts reached
    while (!nodeReady && attempts < maxAttempts) {
      nodeReady = await isNodeRunning();
      if (!nodeReady) {
        await new Promise((resolve) => setTimeout(resolve, 2000)); // Wait 2 seconds between checks
        attempts++;
      }
    }

    // If node failed to start, clean up and exit
    if (!nodeReady) {
      console.error("❌ Hardhat node failed to start after waiting.");
      nodeProcess.kill(); // Terminate the node process
      process.exit(1); // Exit with error code
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
