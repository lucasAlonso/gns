const { expect } = require("chai");
const { ethers, waffle } = require("hardhat");
const { provider } = waffle;

const amountA = ethers.utils.parseEther("2000");
const amountB = ethers.utils.parseEther("1000");


describe("Exchange", function () {
  beforeEach(async function () {
    const Token = await ethers.getContractFactory("GnsCoin");
    token = await Token.deploy("GnsCoin", "GNSC", ethers.utils.parseEther("10000"));
    await token.deployed();

    const Exchange = await ethers.getContractFactory("Exchange");
    exchange = await Exchange.deploy(token.address);
    await exchange.deployed();
  });
  it("adds liquidity", async function () {
    await token.approve(exchange.address, 200);
    await exchange.addLiquidity(200, { value: 100 });

    expect(await provider.getBalance(exchange.address)).to.equal(100);
    expect(await exchange.getReserve()).to.equal(200);
  });

  it("devuelve la cantidad correcta de token", async () => {
    await token.approve(exchange.address, amountA);
    await exchange.addLiquidity(amountA, { value: amountB });

    let tokenOut = await exchange.getTokenAmount(ethers.utils.parseEther("1"));
    expect(ethers.utils.formatEther(tokenOut)).to.equal("1.998001998001998001");
    //crear una automatizacion que tire muchos valores correctos de la BC
  })

  it("devuelve la cantidad correcta de ether", async () => {
    await token.approve(exchange.address, amountA);
    await exchange.addLiquidity(amountA, { value: amountB });

    let ethOut = await exchange.getEthAmount(ethers.utils.parseEther("2"));
    expect(ethers.utils.formatEther(ethOut)).to.equal("0.999000999000999");
    //crear una automatizacion que tire muchos valores correctos de la BC
  })
});
