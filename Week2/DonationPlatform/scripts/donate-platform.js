// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function getBalance(address) {
  const balanceBigInt = await hre.waffle.provider.getBalance(address);
  return hre.ethers.utils.formatEther(balanceBigInt);
}

async function printBalances(addresses) {
  let idx = 0;
  for (const address of addresses) {
    console.log(`Address ${idx} balance:`, await getBalance(address));
    idx++;
  }
}

async function printDonations(donations) {
  for (const donation of donations) {
    const tipperAddress = donation.from;
    const tipper = donation.name;
    const message = donation.message;
    const timestamp = donation.timestamp;
    console.log(
      `At ${timestamp}, ${tipper} (${tipperAddress}) said: "${message}"`
    );
  }
}

async function main() {
  // get example accounts and smart contract address to deploy
  const [owner, donor, donor0, donor1] = await hre.ethers.getSigners();
  // deploy, check balances before donations, and donate to the platform owner
  const DonatePlatform = await hre.ethers.getContractFactory("DonatePlatform");
  const donatePlatform = await DonatePlatform.deploy();
  await donatePlatform.deployed();
  const addresses = [owner.address, donor.address, donatePlatform.address];
  console.log("DonatePlatform deployed to: ", donatePlatform.address);
  console.log("=== start ===");
  await printBalances(addresses);
  const donationAmount = { value: hre.ethers.utils.parseEther("1") };
  await donatePlatform.connect(donor).donateETH("Fran", "cool", donationAmount);
  await donatePlatform.connect(donor0).donateETH("Germ", "wow", donationAmount);
  await donatePlatform.connect(donor1).donateETH("Gene", "lol", donationAmount);

  // check balances after withdrawal, read donations left for owner, and withdraw funds
  console.log("=== donated ===");
  await printBalances(addresses);
  await donatePlatform.connect(owner).withdrawDonations();
  console.log("=== withdrawn ===");
  await printBalances(addresses);
  console.log("=== donations ===");
  const donations = await donatePlatform.getDonations();
  printDonations(donations);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
