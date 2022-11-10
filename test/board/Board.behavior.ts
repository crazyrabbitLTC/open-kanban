import { expect } from "chai";

export function shouldBehaveLikeBoard(): void {
  it("should be true", async function () {
    expect(true).to.equal(true);
  });

  it("should mint tokens", async function () {
    expect(await this.board.balanceOf(this.signers.admin.address)).to.equal(0);
    await expect(this.board.safeMint(this.signers.admin.address, "uri")).to.emit(this.board, "Transfer").to.be.not
      .reverted;

    expect(await this.board.balanceOf(this.signers.admin.address)).to.equal(1);
  });
}
