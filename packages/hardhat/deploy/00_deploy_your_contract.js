// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  const ECommerceBaseUrl = process.env.BASE_URL || "https://your-url.com";

  await deploy("ECommerce", {
    // Learn more about args here: https://www.npmjs.com/package/hardhat-deploy#deploymentsdeploy
    from: deployer,
    args: [ECommerceBaseUrl],
    log: true,
  });

  // Getting a previously deployed contract
  const ECommerce = await ethers.getContract("ECommerce", deployer);


  await deploy("Store", {
    from: deployer,
    args: [ECommerce.address],
    log: true,
  });

  const Store = await ethers.getContract("Store", deployer);

  const minterRole = await ethers.utils.id("MINTER_ROLE");
  console.log(minterRole)
  await ECommerce.grantRole(minterRole, Store.address);

  /*  await YourContract.setPurpose("Hello");
  
    To take ownership of yourContract using the ownable library uncomment next line and add the 
    address you want to be the owner. 
    // yourContract.transferOwnership(YOUR_ADDRESS_HERE);

    //const yourContract = await ethers.getContractAt('YourContract', "0xaAC799eC2d00C013f1F11c37E654e59B0429DF6A") //<-- if you want to instantiate a version of a contract at a specific address!
  */

  /*
  //If you want to send value to an address from the deployer
  const deployerWallet = ethers.provider.getSigner()
  await deployerWallet.sendTransaction({
    to: "0x34aA3F359A9D614239015126635CE7732c18fDF3",
    value: ethers.utils.parseEther("0.001")
  })
  */

  /*
  //If you want to send some ETH to a contract on deploy (make your constructor payable!)
  const yourContract = await deploy("YourContract", [], {
  value: ethers.utils.parseEther("0.05")
  });
  */

  /*
  //If you want to link a library into your contract:
  // reference: https://github.com/austintgriffith/scaffold-eth/blob/using-libraries-example/packages/hardhat/scripts/deploy.js#L19
  const yourContract = await deploy("YourContract", [], {}, {
   LibraryName: **LibraryAddress**
  });
  */

  // Verify your contracts with Etherscan
  // You don't want to verify on localhost
  if (chainId !== localChainId) {
    await run("verify:verify", {
      address: ECommerce.address,
      contract: "contracts/ECommerce.sol:ECommerce",
      contractArguments: [ECommerceBaseUrl],
    });

    await run("verify:verify", {
      address: Store.address,
      contract: "contracts/Store.sol:Store",
      contractArguments: [ECommerce.address],
    });
  }
};
module.exports.tags = ["ECommerce"];
