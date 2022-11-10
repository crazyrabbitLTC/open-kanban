import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers } from "hardhat";

import type { Signers } from "../types";
import { shouldBehaveLikeBoard } from "./Board.behavior";
import { deployBoardFixture } from "./Board.fixture";

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await ethers.getSigners();
    this.signers.admin = signers[0];

    this.loadFixture = loadFixture;
  });

  describe("Board", function () {
    beforeEach(async function () {
      const { board, cloneMock } = await this.loadFixture(deployBoardFixture);

      await cloneMock.deploy(board.address);
      const clonedBoard = await cloneMock.clone();

      this.board = board.attach(clonedBoard).connect(this.signers.admin);
      await this.board.initialize(this.signers.admin.address, "Test Board", "TB");
    });

    shouldBehaveLikeBoard();
  });
});
