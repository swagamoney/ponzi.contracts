import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import {beforeEach, describe} from "mocha";
import { expect } from "chai";
import {Game, Game__factory, GameFactory, GameFactory__factory, MockERC20, MockERC20__factory} from "../typechain";
import {constants} from "ethers";

async function signClaimMessage(signer: SignerWithAddress, contractAddress: string, amount: number, nonce: number, recipient: string) {
    const domain = {
        name: 'GameContractDomain',
        version: '1',
        chainId: await signer.getChainId(),
        verifyingContract: contractAddress
    };

    const types = {
        Claim: [
            { name: 'amount', type: 'uint256' },
            { name: 'nonce', type: 'uint256' },
            { name: 'recipient', type: 'address' }
        ]
    };

    const value = {
        amount,
        nonce,
        recipient
    };

    return await signer._signTypedData(domain, types, value);
}

describe.only("Game", () => {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let bob: SignerWithAddress;

    let gameFactory: GameFactory;
    let game: Game;
    let createdGame: Game;

    let gameFactory_factory: GameFactory__factory;
    let game_factory: Game__factory;

    before(async () => {
        gameFactory_factory = await ethers.getContractFactory("GameFactory");
        game_factory = await ethers.getContractFactory("Game");
    })

    beforeEach(async () => {
        [owner, alice, bob] = await ethers.getSigners();

        game = await game_factory.deploy();
        await game.deployed();

        gameFactory = await gameFactory_factory.deploy(game.address);
        await gameFactory.deployed();

        const tx = await (await gameFactory.connect(alice).createGame(1000, 0, 0, 0, "", "", {value: 100000})).wait();
        createdGame = game_factory.attach(tx.events![2].args!.contractAddress);
    })

    describe('after deploy', () => {
        it('should have correct values', async () => {
            expect(await createdGame.id()).eq(0);
            expect(await createdGame.owner()).eq(gameFactory.address);
            expect(await createdGame.creator()).eq(alice.address);
            expect(await createdGame.creatorFee()).eq(1000);
        })
    })

    describe("deposit", () => {
        it("should emit Deposit event", async () => {
            await expect(createdGame.deposit({value: 100})).to.emit(createdGame, "Deposit").withArgs(owner.address, 0, 80);
        })

        it("should transfer fees", async () => {
            await createdGame.deposit({value: 100});
        })
    })

    describe.only("withdraw", () => {
        it("should withdraw", async () => {
            const nonce = await createdGame.nonce();
            const signature = await signClaimMessage(owner, createdGame.address, 100, nonce.toNumber(), alice.address);
            await createdGame.connect(alice).withdraw(false, "", 100, nonce, signature)
        })

        it("should revert if wrong nonce", async () => {
            const signature = await signClaimMessage(owner, createdGame.address, 100, 2, alice.address);
            await expect(createdGame.connect(alice).withdraw(false, "", 100, 2, signature)).revertedWith("Invalid nonce")
        })

        it("should revert if wrong signature", async () => {
            const signature = await signClaimMessage(owner, createdGame.address, 103, 0, bob.address);
            await expect(createdGame.connect(alice).withdraw(false, "", 100, 0, signature)).revertedWith("Invalid signature")
        })
    })

})