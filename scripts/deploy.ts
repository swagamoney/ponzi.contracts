import {ethers, run} from "hardhat";

const BASE_URI = ""
const TOKEN = ""
const CHAINLINK_TOKEN = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"
const CHAINLINK_ORACLE = "0x6c2e87340Ef6F3b7e21B2304D6C057091814f25E"
const JOB_ID = "0xb4bb896b5d9b4dc694e84479563a537a"
const ENDPOINT = ""

async function main() {
  const game_factory = await ethers.getContractFactory("Game");
  const game = await game_factory.deploy();
  await game.deployed();

  const token_factory = await ethers.getContractFactory("MockERC20");
  const token = await token_factory.deploy();
  await token.deployed();

  const gameFactory_factory = await ethers.getContractFactory("GameFactory");
  const gameFactory = await gameFactory_factory.deploy(game.address, token.address, 1000, "", "", CHAINLINK_TOKEN, CHAINLINK_ORACLE, ethers.utils.hexZeroPad(JOB_ID, 32));
  await gameFactory.deployed();

  console.log("GameFactory:", gameFactory.address);
  console.log("Payment Token:", token.address);
  console.log("Game (reference):", token.address);

  await sleep(30000);

  await run("verify:verify", {
    address: game.address,
    constructorArguments: [],
  });

  await run("verify:verify", {
    address: gameFactory.address,
    constructorArguments: [game.address, token.address, 1000, "", "", CHAINLINK_TOKEN, CHAINLINK_ORACLE, ethers.utils.hexZeroPad(JOB_ID, 32)],
  });

  await run("verify:verify", {
    address: token.address,
    constructorArguments: [],
  });

}

// GameFactory: 0x54cbEa0EecF978b50248D04C558d46e8eCCc9Db6
// Payment Token: 0x61C31Bf9a7E1C28e335D8415739E3Ba0240Eab06
// Game (reference): 0x61C31Bf9a7E1C28e335D8415739E3Ba0240Eab06


function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
