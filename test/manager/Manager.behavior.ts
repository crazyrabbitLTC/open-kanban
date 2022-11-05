import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers } from "hardhat";

import { Ticket } from "../types";

const formatBytes32String = ethers.utils.formatBytes32String;
export function shouldBehaveLikeManager(): void {
  it("should be true", async function () {
    expect(true).to.equal(true);
  });

  it("can open a ticket", async function () {
    const column = await this.manager.columnId("To Do");

    const ticket: Ticket = {
      id: 1,
      name: "Test Ticket",
      uri: "https://example.com/ticket/1",
      columnId: column,
      statusId: 1,
      data: formatBytes32String("0x"),
    };

    const storedTicket = [
      BigNumber.from(0),
      "Test Ticket",
      "https://example.com/ticket/1",
      column,
      BigNumber.from(1),
      formatBytes32String("0x"),
    ];

    await expect(this.manager.openTicket(ticket, this.signers.admin.address))
      .to.emit(this.manager, "TicketCreated")
      .withArgs(storedTicket);

    // check the board minted an nft
    const res = await this.manager.tickets(0);

    expect(storedTicket[0]).equal(res[0]);
    expect(storedTicket[1]).equal(res[1]);
    expect(storedTicket[2]).equal(res[2]);
    expect(storedTicket[3]).equal(res[3]);
    expect(storedTicket[4]).equal(res[4]);
    expect(storedTicket[5]).equal(res[5]);

    // check the mapping of tickets
  });
}
