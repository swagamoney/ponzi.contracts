import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { beforeEach } from "mocha";
import { expect } from "chai";
import {Game, Game__factory, GameFactory, GameFactory__factory, MockERC20, MockERC20__factory} from "../typechain";
import {constants} from "ethers";

describe("GameFactory", () => {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;
    let oracle: SignerWithAddress;

    let gameFactory: GameFactory;
    let game: Game;
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
        [owner, oracle, alice] = await ethers.getSigners();

        paymentToken = await mockERC20_factory.deploy();
        await paymentToken.deployed();

        link = await mockERC20_factory.deploy();
        await link.deployed();

        game = await game_factory.deploy();
        await game.deployed();

        gameFactory = await gameFactory_factory.deploy(game.address, paymentToken.address, 100, "", "", link.address, oracle.address, constants.HashZero);
        await gameFactory.deployed();
    })

    describe('after deploy', () => {
        it('should have correct values', async () => {
            expect(await gameFactory.master()).eq(game.address);
            expect(await gameFactory.paymentToken()).eq(paymentToken.address);
            expect(await gameFactory.chainlinkToken()).eq(link.address);
            expect(await gameFactory.chainlinkOracle()).eq(oracle.address);
            expect(await gameFactory.platformFee()).eq(100);
            expect(await gameFactory.owner()).eq(owner.address);
        })
    })

    describe("setPaymentToken", () => {
        it('should revert if caller is not owner', async () => {
            await expect(gameFactory.connect(alice).setPaymentToken(constants.AddressZero)).revertedWith("Ownable: caller is not the owner");
        })

        it('should set payment token', async () => {
            await gameFactory.setPaymentToken(alice.address);
            expect(await gameFactory.paymentToken()).eq(alice.address);
        })
    })

    describe("setPlatformFee", () => {
        it('should revert if caller is not owner', async () => {
            await expect(gameFactory.connect(alice).setPlatformFee(200)).revertedWith("Ownable: caller is not the owner");
        })

        it('should set platform fee', async () => {
            await gameFactory.setPlatformFee(200);
            expect(await gameFactory.platformFee()).eq(200);
        })
    })

    describe("setMaster", () => {
        it('should revert if caller is not owner', async () => {
            await expect(gameFactory.connect(alice).setMaster(constants.AddressZero)).revertedWith("Ownable: caller is not the owner");
        })

        it('should set master', async () => {
            await gameFactory.setMaster(alice.address);
            expect(await gameFactory.master()).eq(alice.address);
        })
    })

    describe("withdrawLink", () => {
        it('should revert if caller is not owner', async () => {
            await expect(gameFactory.connect(alice).withdrawLink()).revertedWith("Ownable: caller is not the owner");
        })

        it('should withdraw link', async () => {
            await link.mint(gameFactory.address, 1000);
            await gameFactory.withdrawLink();
            expect(await link.balanceOf(gameFactory.address)).eq(0);
        })
    })

    describe('function createGame', () => {
        it("should create game", async () => {
            await paymentToken.approve(gameFactory.address, 1000);
            await gameFactory.createGame(1000, 100);
            expect(await gameFactory.gamesCount()).eq(1);
        })

        it("should emit CreateGame event", async () => {
            await paymentToken.approve(gameFactory.address, 1000);
            await expect(gameFactory.createGame(1000, 100))
                .to.emit(gameFactory, "CreateGame")
        })
    })

})