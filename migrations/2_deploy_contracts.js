var MarketPlace = artifacts.require('./MarketPlace.sol');

module.exports = async function(deployer, network, accounts) {
  const [deployerAccount, owner, oracle, feeAuthority, fundsWallet] = accounts;
  await deployer.deploy(MarketPlace, { from: owner });
};
