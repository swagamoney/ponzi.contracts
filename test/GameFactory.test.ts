import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { ethers } from "hardhat";
import { beforeEach } from "mocha";
import { expect } from "chai";
import {Game, Game__factory, GameFactory, GameFactory__factory} from "../typechain";
import {constants} from "ethers";

describe("GameFactory", () => {
    let owner: SignerWithAddress;
    let alice: SignerWithAddress;

    let gameFactory: GameFactory;
    let game: Game;

    let gameFactory_factory: GameFactory__factory;
    let game_factory: Game__factory;

    before(async () => {
        gameFactory_factory = await ethers.getContractFactory("GameFactory");
        game_factory = await ethers.getContractFactory("Game");
      })

    beforeEach(async () => {
        [owner, alice] = await ethers.getSigners()

        game = await game_factory.deploy();
        await game.deployed();

        gameFactory = await gameFactory_factory.deploy(game.address);
        await gameFactory.deployed();
    })

    describe('after deploy', () => {
        it('should have correct values', async () => {
            expect(await gameFactory.master()).eq(game.address);
            expect(await gameFactory.owner()).eq(owner.address);
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

    describe('function createGame', () => {
        it("should create game", async () => {
            await gameFactory.createGame(10,1000, 100, 5, "", "");
            expect(await gameFactory.gamesCount()).eq(1);
        })

        it("should emit CreateGame event", async () => {
            await expect(gameFactory.createGame(10,1000, 100, 5, "", ""))
                .to.emit(gameFactory, "CreateGame")
        })
    })

})