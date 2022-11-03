import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers } from "hardhat";

import type { Signers } from "../types";
import { shouldBehaveLikeDB } from "./db.behavior";
import { deployDBFixture } from "./db.fixture";

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await ethers.getSigners();
    this.signers.admin = signers[0];

    this.loadFixture = loadFixture;
  });

  describe("DB", function () {
    beforeEach(async function () {
      const deployFixture = () => deployDBFixture(this.signers.admin.address);
      const { db } = await this.loadFixture(deployFixture);
      this.db = db;
    });

    shouldBehaveLikeDB();
  });
});
