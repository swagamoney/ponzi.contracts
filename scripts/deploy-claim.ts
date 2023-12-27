import {ethers, run} from "hardhat";

async function main() {
    const token_factory = await ethers.getContractFactory("MockToken");
    const claim_factory = await ethers.getContractFactory("Claim");

    const token1 = await token_factory.deploy();
    await token1.deployed();

    const token2 = await token_factory.deploy();
    await token2.deployed();

    const claim = await claim_factory.deploy(token1.address, token2.address);
    await claim.deployed();

    console.log("Holding token:", token1.address);
    console.log("Funds token:", token2.address);
    console.log("Claim:", claim.address);

    await sleep(30000);

    await run("verify:verify", {
        address: claim.address,
        constructorArguments: [token1.address, token2.address],
    });

    await run("verify:verify", {
        address: token1.address,
        constructorArguments: [],
    });

    await run("verify:verify", {
        address: token2.address,
        constructorArguments: [],
    });

}

// Holding token: 0xf953F2EFa6b875800A8B8042949B0e9cA6784c10
// Funds token: 0x19bFEef1Dd934E9BaCD5593EaF53d236EBBe7D85
// Claim: 0x86B630Df46B80919CcC1013889a9bC7D7B3f1a42

function sleep(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
