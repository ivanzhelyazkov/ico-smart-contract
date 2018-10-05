const Whitelist = artifacts.require('./Whitelist.sol');
const Privileged = artifacts.require('./Privileged.sol')
const Crowdsale = artifacts.require('./Crowdsale.sol');
const JarvisToken = artifacts.require('./JarvisToken.sol');

module.exports = function(deployer) {
	deployer.deploy(Whitelist, {gas: 1000000, gasPrice: 11000000000})
	.then(async function() {
        let WhitelistInstance = await Whitelist.deployed();

        await deployer.deploy(Privileged, {gas: 1000000, gasPrice: 11000000000});
        let PrivilegedInstance = await Privileged.deployed();

        await deployer.deploy(Crowdsale, 20000, PrivilegedInstance.address, WhitelistInstance.address, {gas:6000000, gasPrice: 11000000000});
        let crowInstance = await Crowdsale.deployed();

        await deployer.deploy(JarvisToken, Crowdsale.address, PrivilegedInstance.address, {gas:3500000,gasPrice: 11000000000});
        crowInstance.setTokenContract(JarvisToken.address);
    });
}
