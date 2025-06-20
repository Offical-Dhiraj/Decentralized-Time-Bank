const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying DecentralizedTimeBank contract to Core Blockchain...");

  // Get the ContractFactory and Signers
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy the contract
  const DecentralizedTimeBank = await ethers.getContractFactory("DecentralizedTimeBank");
  const timeBankContract = await DecentralizedTimeBank.deploy();

  await timeBankContract.deployed();

  console.log("DecentralizedTimeBank deployed to:", timeBankContract.address);
  console.log("Transaction hash:", timeBankContract.deployTransaction.hash);
  
  // Verify deployment
  console.log("Verifying deployment...");
  const code = await ethers.provider.getCode(timeBankContract.address);
  if (code === "0x") {
    console.log("❌ Contract deployment failed!");
  } else {
    console.log("✅ Contract deployed successfully!");
    console.log("Contract address:", timeBankContract.address);
    console.log("Network: Core Testnet");
    console.log("Chain ID: 1114");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });