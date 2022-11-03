import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers } from "hardhat";

import type { Board } from "../../types/contracts/Board";
import type { DB } from "../../types/contracts/DB";
import type { Manager } from "../../types/contracts/Manager";
import type { Board__factory } from "../../types/factories/contracts/Board__factory";
import type { DB__factory } from "../../types/factories/contracts/DB__factory";
import type { Manager__factory } from "../../types/factories/contracts/Manager__factory";
// init types
import type { ManagerInitParams } from "../types";

export async function deployManagerFixture(init: ManagerInitParams): Promise<{ manager: Manager }> {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const admin: SignerWithAddress = signers[0];
  const { superAdmin, databaseImplementation, boardImplementation, usersWithRoles, statusLevels, columns, kanban } =
    init;

  const managerFactory: Manager__factory = <Manager__factory>await ethers.getContractFactory("Manager");
  const manager: Manager = <Manager>await managerFactory.connect(admin).deploy();
  await manager.deployed();
  await manager.initialize(
    superAdmin,
    databaseImplementation,
    boardImplementation,
    usersWithRoles,
    statusLevels,
    columns,
    kanban,
  );

  return { manager };
}

// export async function deployDBImplementation(): Promise<{ db: DB }> {
//   const signers: SignerWithAddress[] = await ethers.getSigners();
//   const admin: SignerWithAddress = signers[0];

//   const dbFactory: DB__factory = <DB__factory>await ethers.getContractFactory("DB");
//   const db: DB = <DB>await dbFactory.connect(admin).deploy();
//   await db.deployed();

//   return { db };
// }

// export async function deployBoardImplementation(): Promise<{ board: Board }> {
//   const signers: SignerWithAddress[] = await ethers.getSigners();
//   const admin: SignerWithAddress = signers[0];

//   const boardFactory: Board__factory = <Board__factory>await ethers.getContractFactory("Board");
//   const board: Board = <Board>await boardFactory.connect(admin).deploy();
//   await board.deployed();

//   return { board };
// }
