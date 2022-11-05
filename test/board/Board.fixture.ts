import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers } from "hardhat";

import type { Board } from "../../types/contracts/Board";
import type { Board__factory } from "../../types/factories/contracts/Board__factory";

export async function deployBoardFixture(): Promise<{ board: Board }> {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const admin: SignerWithAddress = signers[0];

  const boardFactory: Board__factory = <Board__factory>await ethers.getContractFactory("Board");
  const board: Board = <Board>await boardFactory.connect(admin).deploy();
  await board.deployed();

  return { board };
}
