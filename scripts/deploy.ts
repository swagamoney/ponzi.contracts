import {ethers, run} from "hardhat";

const BASE_URI = ""
const CHAINLINK_TOKEN = "0x326C977E6efc84E512bB9C30f76E30c160eD06FB"
const CHAINLINK_ORACLE = "0x6c2e87340Ef6F3b7e21B2304D6C057091814f25E"
const JOB_ID = "0xb4bb896b5d9b4dc694e84479563a537a"
const ENDPOINT = ""

async function main() {
  const game_factory = await ethers.getContractFactory("Game");
  const game = await game_factory.deploy();
  await game.deployed();

  const gameFactory_factory = await ethers.getContractFactory("GameFactory");
  const gameFactory = await gameFactory_factory.deploy(game.address,"", "", CHAINLINK_TOKEN, CHAINLINK_ORACLE, ethers.utils.hexZeroPad(JOB_ID, 32));
  await gameFactory.deployed();

  console.log("GameFactory:", gameFactory.address);
  console.log("Game (reference):", game.address);

  await sleep(30000);

  await run("verify:verify", {
    address: game.address,
    constructorArguments: [],
  });

  await run("verify:verify", {
    address: gameFactory.address,
    constructorArguments: [game.address, "", "", CHAINLINK_TOKEN, CHAINLINK_ORACLE, ethers.utils.hexZeroPad(JOB_ID, 32)],
  });

}

// GameFactory: 0x24349E967275D23656822EA6093A753EF055289C
// Game (reference): 0x367a957b29107AE56b6AfFffC2e8476d3B667b62

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
