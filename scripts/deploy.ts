import {ethers, run} from "hardhat";

const BASE_URI = ""
const TOKEN = ""
const CHAINLINK_TOKEN = "0xd14838A68E8AFBAdE5efb411d5871ea0011AFd28"
const CHAINLINK_ORACLE = ""
const JOB_ID = ""
const ENDPOINT = ""

async function main() {
  const vaultkeeper_factory = await ethers.getContractFactory("VaultKeeper");
  const vaultkeeper = await vaultkeeper_factory.deploy(BASE_URI, TOKEN, CHAINLINK_TOKEN, CHAINLINK_ORACLE, JOB_ID, ENDPOINT);
  await vaultkeeper.deployed();

  await run("verify:verify", {
    address: vaultkeeper.address,
    constructorArguments: [BASE_URI, TOKEN, CHAINLINK_TOKEN, CHAINLINK_ORACLE, JOB_ID, ENDPOINT],
  });

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
