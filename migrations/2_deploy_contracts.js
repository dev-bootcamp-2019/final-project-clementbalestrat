const Proxy = artifacts.require('Proxy');
const MarketPlaceState = artifacts.require('MarketPlaceState');
const MarketPlace = artifacts.require('MarketPlace');

const ZERO_ADDRESS = '0x' + '0'.repeat(40);

module.exports = async function(deployer, network, accounts) {
  const [deployerAccount, owner, oracle, feeAuthority, fundsWallet] = accounts;

	const marketPlaceProxy = await Proxy.new({ from: deployerAccount });
	// const marketPlaceState = await deployer.deploy(MarketPlaceState, ZERO_ADDRESS, {
	// 	from: deployerAccount,
	// });
 
	const marketPlace = await deployer.deploy(MarketPlace, marketPlaceProxy.address, { from: deployerAccount });

	// await marketPlaceState.setAssociatedContract(marketPlace.address, { from: deployerAccount });
};
