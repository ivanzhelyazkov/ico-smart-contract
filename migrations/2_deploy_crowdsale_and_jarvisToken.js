const Crowdsale = artifacts.require('./Crowdsale.sol');
const JarvisToken = artifacts.require('./JarvisToken.sol');

module.exports = function(deployer) {
    deployer.deploy(Crowdsale, 30000, {gas:6000000})
    .then(async function() {
        let crowInstance = await Crowdsale.deployed();
        let privAddresses = await crowInstance.privileged.call();
        await deployer.deploy(JarvisToken, Crowdsale.address, privAddresses, {gas:3000000});
        crowInstance.setTokenContract(JarvisToken.address);
    });
}
