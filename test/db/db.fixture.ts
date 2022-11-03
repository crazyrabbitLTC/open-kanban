import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers } from "hardhat";

import type { DB } from "../../types/contracts/DB";
import type { DB__factory } from "../../types/factories/contracts/DB__factory";

export async function deployDBFixture(dbController: string): Promise<{ db: DB }> {
  const signers: SignerWithAddress[] = await ethers.getSigners();
  const admin: SignerWithAddress = signers[0];

  const dbFactory: DB__factory = <DB__factory>await ethers.getContractFactory("DB");
  const db: DB = <DB>await dbFactory.connect(admin).deploy();
  await db.deployed();
  await db.initialize(dbController);

  return { db };
}
