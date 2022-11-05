import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { ethers } from "hardhat";

import { deployBoardFixture } from "../board/Board.fixture";
import { deployDBFixture } from "../db/db.fixture";
import type { Column, Kanban, ManagerInitParams, Signers, Status, UserWithRoles } from "../types";
import { shouldBehaveLikeManager } from "./Manager.behavior";
import { deployManagerFixture } from "./Manager.fixture";

describe("Unit tests", function () {
  before(async function () {
    this.signers = {} as Signers;

    const signers: SignerWithAddress[] = await ethers.getSigners();
    this.signers.admin = signers[0];
    this.signers.manager = signers[1];
    this.signers.noRoles = signers[2];

    this.loadFixture = loadFixture;
  });

  describe("Manager", function () {
    beforeEach(async function () {
      const formatBytes32String = ethers.utils.formatBytes32String;
      const { board } = await this.loadFixture(deployBoardFixture);
      const DBFixture = () => deployDBFixture(this.signers.admin.address);
      const { db } = await this.loadFixture(DBFixture);

      const userAdmin: UserWithRoles = {
        account: this.signers.admin.address,
        uri: formatBytes32String("https://example.com/user/1"),
        roles: ["KANBAN_ADMIN"],
        data: formatBytes32String("0x"),
      };
      const userManager: UserWithRoles = {
        account: this.signers.manager.address,
        uri: formatBytes32String("https://example.com/user/1"),
        roles: ["KANBAN_MEMBER"],
        data: formatBytes32String("0x"),
      };
      const userWithNoRoles: UserWithRoles = {
        account: this.signers.noRoles.address,
        uri: formatBytes32String("https://example.com/user/1"),
        roles: [],
        data: formatBytes32String("0x"),
      };

      const usersWithRoles: UserWithRoles[] = [userAdmin, userManager, userWithNoRoles];

      const statusAssigned: Status = {
        name: "Assigned",
        uri: formatBytes32String("https://example.com/status/1"),
        data: formatBytes32String("0x"),
      };
      const statusBlocked: Status = {
        name: "Blocked",
        uri: formatBytes32String("https://example.com/status/2"),
        data: formatBytes32String("0x"),
      };
      const statusApproved: Status = {
        name: "Approved",
        uri: formatBytes32String("https://example.com/status/3"),
        data: formatBytes32String("0x"),
      };

      const statusLevels: Status[] = [statusAssigned, statusBlocked, statusApproved];

      const columnTodo: Column = {
        name: "To Do",
        uri: formatBytes32String("https://example.com/column/1"),
        database: "0x0000000000000000000000000000000000000000",
        data: formatBytes32String("0x"),
      };
      const columnInProgress: Column = {
        name: "In Progress",
        uri: formatBytes32String("https://example.com/column/2"),
        database: "0x0000000000000000000000000000000000000000",
        data: formatBytes32String("0x"),
      };
      const columnDone: Column = {
        name: "Done",
        uri: formatBytes32String("https://example.com/column/3"),
        database: "0x0000000000000000000000000000000000000000",
        data: formatBytes32String("0x"),
      };

      const columns: Column[] = [columnTodo, columnInProgress, columnDone];

      const kanban: Kanban = {
        name: "Test Kanban",
        description: "Test Kanban Description",
        uri: formatBytes32String("https://testkanban.com"),
        data: formatBytes32String("0x"),
      };

      const constructorArgs: ManagerInitParams = {
        superAdmin: this.signers.admin.address,
        databaseImplementation: db.address,
        boardImplementation: board.address,
        usersWithRoles,
        statusLevels,
        columns,
        kanban,
      };

      const deployFixture = () => deployManagerFixture(constructorArgs);
      const { manager } = await this.loadFixture(deployFixture);
      this.manager = manager;
    });

    shouldBehaveLikeManager();
  });
});
