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

type FixtureOutput = {
  board: Board;
  db: DB;
  manager: Manager;
};

export async function deployManagerFixture(init: ManagerInitParams): Promise<FixtureOutput> {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const admin: SignerWithAddress = signers[0];

  const dbFactory: DB__factory = <DB__factory>await ethers.getContractFactory("DB");
  const db: DB = <DB>await dbFactory.connect(admin).deploy();
  await db.deployed();

  const boardFactory: Board__factory = <Board__factory>await ethers.getContractFactory("Board");
  const board: Board = <Board>await boardFactory.connect(admin).deploy();
  await board.deployed();

  const databaseImplementation = db.address;
  const boardImplementation = board.address;

  const { superAdmin, usersWithRoles, columns, kanban } = init;

  const managerFactory: Manager__factory = <Manager__factory>await ethers.getContractFactory("Manager");
  const manager: Manager = <Manager>await managerFactory.connect(admin).deploy();
  await manager.deployed();
  await manager.initialize(superAdmin, databaseImplementation, boardImplementation, usersWithRoles, columns, kanban);

  return { manager, db, board };
}
