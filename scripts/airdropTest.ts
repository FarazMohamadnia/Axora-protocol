import { network } from "hardhat";
import * as dotenv from "dotenv";
import * as fs from "fs";

dotenv.config();

interface User {
  address: string;
  privateKey: string;
}

const { ethers } = await network.connect({
  network: "localhost",
});

const usersData = JSON.parse(fs.readFileSync("accounts/users.json", "utf8"));

const usersList: User[] = [];

// Generate usersList dynamically using a loop
for (const key in usersData) {
  if (usersData.hasOwnProperty(key)) {
    usersList.push({
      address: usersData[key].address,
      privateKey: usersData[key].privateKey,
    });
  }
}

const [sender] = await ethers.getSigners();

const airdrop = await ethers.getContractAt(
  "Airdrop",
  process.env.AIRDROP_ADDRESS || ""
);
const token = await ethers.getContractAt(
  "Token",
  process.env.TOKEN_ADDRESS || ""
);

console.log(
  "➡️  Check : Airdrop Time Data: ",
  await airdrop.getAirdropStatus()
);
console.log("➡️  Owner Address : ", await airdrop.owner());
console.log("➡️  Token Address : ", await airdrop.tokenAddress());
console.log("➡️  Total Airdrop : ", await airdrop.totalAmount());
console.log(
  "➡️Contract Balance (Token) : ",
  await token.balanceOf(process.env.AIRDROP_ADDRESS || "")
);
const sendToken = async () => {
  try {
    await token.transfer(
      process.env.AIRDROP_ADDRESS || "",
      await airdrop.totalAmount()
    );
  } catch (err) {
    console.log("➡️  sendToken Function Error : ", err);
  }
};

const addUser = async (userAddress: string) => {
  try {
    console.log(`➡️  Adding user: ${userAddress}`);
    const tx = await airdrop.addUser(userAddress);
    await tx.wait();
    console.log(`✅  User ${userAddress} added successfully!`);

    // Get updated airdrop status
    console.log("➡️  Updated Total Airdrop: ", await airdrop.totalAmount());
  } catch (err) {
    console.log("➡️  addUser Function Error : ", err);
  }
};

const withdrawUser = async (userAddress: string) => {
  try {
    // Find the user and create their signer
    const user = usersList.find((u) => u.address === userAddress);
    if (!user) {
      throw new Error(`User ${userAddress} not found`);
    }

    const userSigner = new ethers.Wallet(user.privateKey, ethers.provider);
    const airdropWithUserSigner = airdrop.connect(userSigner);

    console.log(`➡️  Withdrawing for user: ${userAddress}`);
    const tx = await airdropWithUserSigner.airdrop();
    await tx.wait();
    console.log(`✅  User ${userAddress} withdrawn successfully!`);
  } catch (err) {
    console.log("➡️  withdrawUser Function Error : ", err);
  }
};

// First send tokens to the airdrop contract, then add user and withdraw
// sendToken().then(() => {
//   addUser(usersList[3].address).then(() => {
// withdrawUser(usersList[3].address);
//   });
// });

// Test 2

async function test2() {
  console.log("➡️  Test 2 ================================= ");
  const AirdropUserList = usersList.slice(0, 7);
  console.log("➡️  AirdropUserList : ", AirdropUserList);

  try {
    await token.transfer(
      process.env.AIRDROP_ADDRESS || "",
      await airdrop.totalAmount()
    );
    console.log(
      "✅  Send Token to Airdrop Contract : ",
      await token.balanceOf(process.env.AIRDROP_ADDRESS || "")
    );

    for (const user of AirdropUserList) {
      await addUser(user.address);
    }
    console.log(
      "✅  All users added successfully!",
      await airdrop.getUserList()
    );
    console.log(
      "➡️  Total Airdrop : ",
      await token.balanceOf(process.env.AIRDROP_ADDRESS || "")
    );
    const deleteUserList = AirdropUserList.slice(2, 6);
    for (const user of deleteUserList) {
      await airdrop.deleteUser(user.address);
      console.log("✅  User ", user.address, " deleted successfully!");
    }

    const currentAirdropUsers = [];
    for (const user of AirdropUserList) {
      if (deleteUserList.find((u: any) => u.user != user.address)) {
        currentAirdropUsers.push(user);
      }
    }
    console.log("➡️  Current Airdrop Users : ", currentAirdropUsers);
    
    // Use Promise.all to handle all airdrop operations concurrently
    const airdropPromises = currentAirdropUsers.map(async (user) => {
      const userSigner = new ethers.Wallet(user.privateKey, ethers.provider);
      const airdropWithUserSigner = airdrop.connect(userSigner);
      await airdropWithUserSigner.airdrop();
      console.log("✅  User ", user.address, " withdrawn successfully!");
    });
    try {
        await Promise.all(airdropPromises);
    
    } catch (error) {
        console.log('You are not a user of the airdrop');
        
    }
    console.log(
      "✅  All users withdrawn successfully!",
      await airdrop.getUserList()
    );
    console.log(
      "➡️  Total Airdrop : ",
      await token.balanceOf(process.env.AIRDROP_ADDRESS || "")
    );

    for (const user of AirdropUserList) {
      const balance = await token.balanceOf(user.address);
      console.log("➡️  User ", user.address, " balance : ", balance);
    }
  } catch (err) {
    console.log("➡️  ERROR  === TEST 2 : ", err);
  }
}
test2();
