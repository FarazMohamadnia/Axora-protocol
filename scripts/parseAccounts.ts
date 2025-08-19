import * as fs from 'fs';


interface User {
  address: string;
  privateKey: string;
}


interface Users {
  [key: string]: User;
}


const filePath: string = 'accounts/accounts.txt';
if (!fs.existsSync(filePath)) {
  console.error(`Error: File ${filePath} not found. Please create it with the output of 'npx hardhat node'.`);
  process.exit(1);
}

const data: string = fs.readFileSync(filePath, 'utf8');


const users: Users = {};


const lines: string[] = data.split('\n').filter(line => line.trim() !== ''); 
let currentUserIndex: number = 1;
let currentAddress: string | null = null;

lines.forEach((line: string, index: number) => {
  const addressMatch: RegExpMatchArray | null = line.match(/Account #\d+:\s*(0x[a-fA-F0-9]{40})/);
 
  const privateKeyMatch: RegExpMatchArray | null = line.match(/Private Key: (0x[a-fA-F0-9]{64})/);

  if (addressMatch) {
    currentAddress = addressMatch[1];
    console.log(`Line ${index + 1}: Found address - ${currentAddress}`);
  }

  if (privateKeyMatch && currentAddress) {
    const userKey: string = `user${currentUserIndex}`;
    users[userKey] = {
      address: currentAddress,
      privateKey: privateKeyMatch[1],
    };
    console.log(`Line ${index + 1}: Added ${userKey} - Address: ${currentAddress}, PrivateKey: ${privateKeyMatch[1]}`);
    currentUserIndex++;
    currentAddress = null;
  }
});


if (currentUserIndex - 1 !== 20) {
  console.warn(`Warning: Expected 20 users, but only ${currentUserIndex - 1} users were parsed.`);
}


console.log('Users:', JSON.stringify(users, null, 2));

fs.writeFileSync('accounts/users.json', JSON.stringify(users, null, 2));

console.log('Data saved to accounts/users.json');