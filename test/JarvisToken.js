const Reward = artifacts.require("JarvisToken");
const Privileged = artifacts.require("Privileged");
const Crowdsale = artifacts.require("Crowdsale");

const errorMessage = 'VM Exception while processing transaction: revert';

const should = require('chai')
  .use(require('chai-as-promised'))
  .should();

contract("JarvisToken", function (accounts) {
  beforeEach(async function () {
    this.privileged = await Privileged.new();
    this.crowdsale = await Crowdsale.new(20000);
    this.jarvistoken = await Reward.new(this.crowdsale.address, this.privileged.address);
  });
 
  it('Check token amount is assigned correctly', async function() {
    var result = await this.jarvistoken.balanceOf(this.crowdsale.address);
    assert.equal(result, 420000000*1E2);
 });

  it('Transfer from non-privileged accounts should fail', async function() {
    await this.jarvistoken.privilegedTransfer.call(accounts[0], 600, { from:accounts[1] }).should.be.rejectedWith(errorMessage);
  });
   
  it('Should not burn more amount of token than available', async function() {
    await this.jarvistoken.privilegedBurn.call(800000000000000000000000000, { from: accounts[0] }).should.be.rejectedWith(errorMessage);
  });

  it('Non-privileged accounts should not able to burn tokens', async function() { 
     await this.jarvistoken.privilegedBurn.call(600, { from: accounts[1] }).should.be.rejectedWith(errorMessage);
  });

  it('Only privileged accounts should be able to make a transfer' , async function(){
    await this.privileged.addToPrivileged(accounts[1]);
    await this.jarvistoken.privilegedTransfer(accounts[0], 600, { from:accounts[1] });
    await this.jarvistoken.privilegedTransfer(accounts[0], 600, { from:accounts[2] }).should.be.rejectedWith(errorMessage);
  })

});
 