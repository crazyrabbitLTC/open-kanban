import { expect } from "chai";
import { ethers } from "hardhat";

import { Ticket } from "../types";

const formatBytes32String = ethers.utils.formatBytes32String;
export function shouldBehaveLikeManager(): void {
  it("should be true", async function () {
    expect(true).to.equal(true);
  });

  it("can open a ticket", async function () {
    const column = await this.manager.columnId("To Do");
    console.log("🚀 ~ file: Manager.behavior.ts ~ line 14 ~ column", column);

    const ticket: Ticket = {
      id: 1,
      name: "Test Ticket",
      uri: "https://example.com/ticket/1",
      columnId: column,
      statusId: 1,
      data: formatBytes32String("0x"),
    };
    await expect(this.manager.openTicket(ticket, this.signers.admin.address)).to.emit(this.manager, "TicketCreated");
  });
}
