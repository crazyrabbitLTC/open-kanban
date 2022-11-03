import { expect } from "chai";

export function shouldBehaveLikeDB(): void {
  it("should be true", async function () {
    expect(true).to.equal(true);
  });

  it("should grant dbController, the DB_CONTROLLER role", async function () {
    const DB_CONTROLLER_ROLE = await this.db.DB_CONTROLLER();
    const hasRole = await this.db.hasRole(DB_CONTROLLER_ROLE, this.signers.admin.address);
    expect(hasRole).to.equal(true);
  });

  it("Should create a list", async function () {
    expect(await this.db.listExists()).to.equal(false);
    await this.db.pushBack(1);
    expect(await this.db.listExists()).to.equal(true);
    expect(await this.db.sizeOf()).to.equal(1);
  });

  it("Should allow multiple entries", async function () {
    await this.db.pushBack(1);
    await this.db.pushBack(2);
    await this.db.pushBack(3);
    expect(await this.db.sizeOf()).to.equal(3);
  });
}
