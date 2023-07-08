const { ethers,} = require("hardhat");

async function main() {
  // Deploy the AptosExchange contract
  const AptosExchange = await ethers.getContractFactory("AptosExchange");
  const aptosExchange = await upgrades.deployProxy(AptosExchange);

  // Print the contract address to the console
  console.log("AptosExchange contract deployed at:", aptosExchange.address);
}

// Execute the deployment script
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
