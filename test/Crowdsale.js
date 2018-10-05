const Whitelist = artifacts.require("Whitelist");
const Privileged = artifacts.require("Privileged");
const Crowdsale = artifacts.require("Crowdsale");
const JarvisToken = artifacts.require("JarvisToken");

contract("Crowdsale", function (accounts) {
  beforeEach(async function () {
    this.whitelist = await Whitelist.new();
    this.privileged = await Privileged.new();
    // Set up crowdsale with initial ETH/USD Rate to 200 $
    this.crowdsale = await Crowdsale.new(20000, this.privileged.address, this.whitelist.address);
    this.token = await JarvisToken.new(this.crowdsale.address,this.privileged.address);
    
    await this.crowdsale.setTokenContract(this.token.address);
    await this.whitelist.transferOwnership(this.crowdsale.address);
  });
 
  it('Verify private investor allocation and distribution works as expected', async function() {
    
    // Set ICO to finished
    await this.crowdsale.setDates(Math.floor(Date.now() / 1000) - 4, 1, 1);
    
    await this.crowdsale.addInvestorAllocation([accounts[0],accounts[1]],[10000,20000]);

    let allocatedFirst = await this.crowdsale.investorsAllocated(accounts[0]);
    let allocatedSecond = await this.crowdsale.investorsAllocated(accounts[1]);
    
    assert.equal(allocatedFirst, 10000);
    assert.equal(allocatedSecond, 20000);

    await this.crowdsale.distributeToPrivateInvestors(2);

    let balanceFirst = await this.token.balanceOf(accounts[0]);
    let balanceSecond = await this.token.balanceOf(accounts[1]);

    assert.equal(balanceFirst, 10000);
    assert.equal(balanceSecond, 20000);

    await this.crowdsale.addInvestorAllocation([accounts[1],accounts[2]],[10000,20000]);

    allocatedSecond = await this.crowdsale.investorsAllocated(accounts[1]);
    let allocatedThird = await this.crowdsale.investorsAllocated(accounts[2]);

    assert.equal(allocatedSecond, 30000);
    assert.equal(allocatedThird, 20000);

    await this.crowdsale.distributeToPrivateInvestors(2);

    balanceSecond = await this.token.balanceOf(accounts[1]);
    let balanceThird = await this.token.balanceOf(accounts[2]);

    // Function allows only for one distribution per address

    assert.equal(balanceSecond, 20000);
    assert.equal(balanceThird, 20000);
 });

  it('Verify investment function works correctly', async function() {
    
    // Set ICO Dates
    await this.crowdsale.setDates(Math.floor(Date.now() / 1000), 30, 30);
    let ethUsdRate = await this.crowdsale.ethUsdRate.call();
    let jrtUsdRate = await this.crowdsale.jrtUsdRate.call();

    await this.crowdsale.sendTransaction({value:web3.toWei(10), from:web3.eth.accounts[0], gas: 300000});

    let record1 = await this.crowdsale.historyRecord(0);
    let tokens1 = record1[2];
    let bonusTokens1 = record1[3];

    assert.equal(tokens1, Math.round(web3.toWei(10)*ethUsdRate/jrtUsdRate));
    assert.equal(bonusTokens1, tokens1*3/10);

    await this.crowdsale.sendTransaction({value:web3.toWei(20000), from:web3.eth.accounts[9], gas: 300000});

    let preIcoHardCapWasHit = await this.crowdsale.icoHardCapsHit(0);

    assert.equal(preIcoHardCapWasHit,true);
  });

  it('Verify unsold tokens of previous stages are moved to stage 3 hard cap of the ICO', async function() {

    // Set the ICO to 3 weeks ago to simulate conditions under stage 3
    var week = 604800;
    var date = new Date();
    date.setDate(date.getDate() - 22);
    await this.crowdsale.setDates(Math.floor(date / 1000), week, week*3);

    // Move the unsold tokens to stage 3 hard cap
    await this.crowdsale.moveUnsold();

    // Expected stage 3 hard cap is the sum of all of the stages hard caps, as no tokens have been sold
    let expectedHardCap = await (this.crowdsale.icoHardCaps.call(0))*4;

    let actualHardCap = await this.crowdsale.icoHardCaps.call(3);
    
    assert.equal(expectedHardCap, actualHardCap)
  })

  function wait(ms){
    var start = new Date().getTime();
    var end = start;
    while(end < start + ms) {
      end = new Date().getTime();
   }
 }

  it('Verify ICO investor distribution functions work as expected', async function() {
    
    var week = 604800;
    var date = new Date();
    date.setDate(date.getDate() - 28);
    await this.crowdsale.setDates(Math.floor(date / 1000), week, week*3+3);

    for(let i = 0; i < 5; ++i) {
      await this.crowdsale.sendTransaction({value:web3.toWei(10), from:web3.eth.accounts[i], gas: 300000});
      await this.crowdsale.addToWhitelist(web3.eth.accounts[i]);
      let tx = await this.crowdsale.historyRecord.call(i);
      assert.equal(tx[1], web3.toWei(10));
    }

    // De-whitelist the last investor (account 4)
    await this.crowdsale.removeFromWhitelist(web3.eth.accounts[4]);

    wait(2000);

    // Distribute only to accounts 1 and 3
    await this.crowdsale.distributeManual(['1','3']);

    let tx1 = await this.crowdsale.historyRecord.call(1);
    let tx3 = await this.crowdsale.historyRecord.call(3);

    // Assert transactions 1 and 3 have been processed
    assert.equal(tx1[5], true);
    assert.equal(tx3[5], true);

    let balance1 = await this.token.balanceOf(web3.eth.accounts[1]);
    let balance3 = await this.token.balanceOf(web3.eth.accounts[3]);

    // Assert token balances of accounts are above 0
    assert.isAbove(balance1.toNumber(),0);
    assert.isAbove(balance3.toNumber(),0);

    // Distribute to all investors
    await this.crowdsale.distributeAutomatic(5);

    let tx0 = await this.crowdsale.historyRecord.call(0);
    let tx2 = await this.crowdsale.historyRecord.call(2);
    let tx4 = await this.crowdsale.historyRecord.call(4);

    let balance0 = await this.token.balanceOf(web3.eth.accounts[0]);
    let balance2 = await this.token.balanceOf(web3.eth.accounts[2]);
    let balance4 = await this.token.balanceOf(web3.eth.accounts[4]);

    assert.equal(tx0[5], true);
    assert.equal(tx2[5], true);

    assert.isAbove(balance0.toNumber(),0);
    assert.isAbove(balance2.toNumber(),0);

    // Assert account 4 is processed, but hasn't received tokens, because he isn't whitelisted
    assert.equal(tx4[5], true);
    assert.equal(balance4.toNumber(), 0);
  })

});
 