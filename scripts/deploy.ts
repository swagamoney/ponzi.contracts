import {ethers, run} from "hardhat";

async function main() {
  const game_factory = await ethers.getContractFactory("Game");
  const game = await game_factory.deploy();
  await game.deployed();

  const gameFactory_factory = await ethers.getContractFactory("GameFactory");
  const gameFactory = await gameFactory_factory.deploy(game.address);
  await gameFactory.deployed();

  console.log("GameFactory:", gameFactory.address);
  console.log("Game (reference):", game.address);

  await sleep(50000);

  await run("verify:verify", {
    address: game.address,
    constructorArguments: [],
  });

  await run("verify:verify", {
    address: gameFactory.address,
    constructorArguments: [game.address],
  });

}
//
// GameFactory: 0x519d76A95545ef8c230505858305D23f3E1cff76
// Game (reference): 0x058783D01bAc1d9490de9632561D22c671080844

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
