import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers } from "hardhat";

import type { Board } from "../../types/contracts/Board";
import type { CloneMock } from "../../types/contracts/CloneMock";
import type { Board__factory } from "../../types/factories/contracts/Board__factory";
import type { CloneMock__factory } from "../../types/factories/contracts/CloneMock__factory";

type FixtureType = {
  board: Board;
  cloneMock: CloneMock;
};

export async function deployBoardFixture(): Promise<FixtureType> {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const admin: SignerWithAddress = signers[0];

  const boardFactory: Board__factory = <Board__factory>await ethers.getContractFactory("Board");
  const board: Board = <Board>await boardFactory.connect(admin).deploy();
  await board.deployed();

  const mockFactory: CloneMock__factory = <CloneMock__factory>await ethers.getContractFactory("CloneMock");
  const cloneMock: CloneMock = <CloneMock>await mockFactory.connect(admin).deploy();
  await cloneMock.deployed();

  return { board, cloneMock };
}
