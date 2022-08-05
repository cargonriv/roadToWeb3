const hre = require("hardhat");
async function main() {
  const DonatePlatform = await hre.ethers.getContractFactory("DonatePlatform");
  const donatePlatform = await DonatePlatform.deploy();
  await donatePlatform.deployed();
  console.log("DonatePlatform deployed to: ", donatePlatform.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
