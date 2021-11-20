const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SlpManager", function () {
  it("Should return the new greeting once it's changed", async function () {
    const SlpManager = await ethers.getContractFactory("SlpManager");
    const slpManager = await SlpManager.deploy("0x57e90deA536a1b42cF7b728576609A55938cC12d");
    await slpManager.deployed();

    expect(await slpManager.paymentToken()).to.equal("0x57e90deA536a1b42cF7b728576609A55938cC12d");
  });

  it()
});
