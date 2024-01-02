import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import {beforeEach, describe} from "mocha";
import { expect } from "chai";
import {Game, Game__factory, GameFactory, GameFactory__factory, MockERC20, MockERC20__factory} from "../typechain";
import {constants} from "ethers";

describe.only("Game", () => {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let oracle: SignerWithAddress;
    let bob: SignerWithAddress;

    let gameFactory: GameFactory;
    let game: Game;
    let createdGame: Game;
    let paymentToken: MockERC20;
    let link: MockERC20;

    let gameFactory_factory: GameFactory__factory;
    let game_factory: Game__factory;
    let mockERC20_factory: MockERC20__factory;

    before(async () => {
        gameFactory_factory = await ethers.getContractFactory("GameFactory");
        game_factory = await ethers.getContractFactory("Game");
        mockERC20_factory = await ethers.getContractFactory("MockERC20");
    })

    beforeEach(async () => {
        [owner, oracle, alice, bob] = await ethers.getSigners();

        paymentToken = await mockERC20_factory.deploy();
        await paymentToken.deployed();

        link = await mockERC20_factory.deploy();
        await link.deployed();

        game = await game_factory.deploy();
        await game.deployed();

        gameFactory = await gameFactory_factory.deploy(game.address, paymentToken.address, 1000, "", "", link.address, oracle.address, constants.HashZero);
        await gameFactory.deployed();
        await gameFactory.transferOwnership(bob.address)

        await paymentToken.mint(alice.address, 1000);
        await paymentToken.connect(alice).approve(gameFactory.address, constants.MaxUint256);
        const tx = await (await gameFactory.connect(alice).createGame(1000, 1000)).wait();
        createdGame = game_factory.attach(tx.events![4].args!.contractAddress);
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
            await paymentToken.approve(createdGame.address, 1000);
            await expect(createdGame.deposit(100)).to.emit(createdGame, "Deposit").withArgs(owner.address, 0, 80);
        })

        it("should transfer fees", async () => {
            await paymentToken.approve(createdGame.address, 1000);
            await createdGame.deposit(100);

            expect(await paymentToken.balanceOf(createdGame.address)).eq(980);
            expect(await paymentToken.balanceOf(alice.address)).eq(10);
            expect(await paymentToken.balanceOf(bob.address)).eq(110);
        })
    })

})