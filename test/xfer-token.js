const { expect } = require("chai");
const { ethers } = require("hardhat");

const RANDOM_ADDRESS = '0x1111111111111111111111111111111111111111';

function zerosAndOnes(data) {
  let zeros = 0;
  for (let i = 2; i < data.length; i += 2) {
    if (data.substr(i, 2) == '00') {
      zeros++;
    }
  }
  const ones = ((data.length - 2) / 2) - zeros;
  return { zeros, ones };
}

function logCalldataGas(data) {
  const { zeros, ones } = zerosAndOnes(data);
  const gas = (4 * zeros) + (16 * ones);
  console.log({ gas, zeros, ones });
}

function padNumber(num, padAmount) {
  const amountHex = ethers.utils.hexValue(num);
  const _padAmount = padAmount || Math.floor(amountHex.length / 2);
  return ethers.utils.arrayify(ethers.utils.hexZeroPad(amountHex, _padAmount));
}

describe("XferToken", function () {
  let token;
  let signer;

  beforeEach(async () => {
    const Token = await ethers.getContractFactory("TestToken");
    token = await Token.deploy();

    signer = await ethers.getSigner();
  });

  it("Should transfer a token using the fallback function", async function () {
    const XferToken = await ethers.getContractFactory("XferToken");
    const factory = await XferToken.deploy(token.address, ethers.constants.AddressZero);
    await factory.deployed();

    await token.approve(factory.address, ethers.constants.MaxUint256);

    const amountHex = ethers.utils.hexValue(ethers.constants.WeiPerEther)
    const tx = await signer.sendTransaction({
      to: factory.address,
      data: ethers.utils.concat([
        RANDOM_ADDRESS,
        ethers.utils.arrayify(ethers.utils.hexZeroPad(amountHex, Math.floor(amountHex.length / 2))),
      ])
    })

    logCalldataGas(tx.data);

    expect(await token.balanceOf(RANDOM_ADDRESS)).to.equal(ethers.constants.WeiPerEther);
  });

  it("Should transfer a token using address registry", async function () {
    const AddressRegistry = await ethers.getContractFactory("AddressRegistry");
    const registry = await AddressRegistry.deploy();
    await registry.deployed();

    const XferToken = await ethers.getContractFactory("XferToken");
    const factory = await XferToken.deploy(token.address, registry.address);
    await factory.deployed();

    await registry.getId(RANDOM_ADDRESS);

    await token.approve(factory.address, registry.address);

    console.log(await registry.peekId(RANDOM_ADDRESS), padNumber(await registry.peekId(RANDOM_ADDRESS), 2));

    const tx = await signer.sendTransaction({
      to: factory.address,
      data: ethers.utils.concat([
        padNumber(await registry.peekId(RANDOM_ADDRESS), 2),
        padNumber(ethers.constants.WeiPerEther),
      ]),
    })

    logCalldataGas(tx.data);

    expect(await token.balanceOf(RANDOM_ADDRESS)).to.equal(ethers.constants.WeiPerEther);
  });
});
