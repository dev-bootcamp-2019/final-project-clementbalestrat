const MarketPlace = artifacts.require('MarketPlace');

module.exports = async function(deployer, network, accounts) {
  const [deployerAccount, owner] = accounts;
  const marketPlace = await deployer.deploy(MarketPlace);
};
