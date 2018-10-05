const whitelist = artifacts.require("Whitelist");

const errorMessage = 'VM Exception while processing transaction: revert';

const should = require('chai')
  .use(require('chai-as-promised'))
  .should();

contract("Whitelist", function (accounts) {
  beforeEach(async function () {
    this.whitelist = await whitelist.new();
  });

  it('should allow only owner to add new investor to whitelist', async function () {
    await this.whitelist.addInvestorToWhitelist(accounts[1]);
    const result = await this.whitelist.isWhitelisted.call(accounts[1]);

    assert.equal(true, result);

    //should not allow to add 1 more time
    await this.whitelist.addInvestorToWhitelist(accounts[1]).should.be.rejectedWith(errorMessage);

    //should not allow to call by not owner
    await this.whitelist.addInvestorToWhitelist(accounts[2], { from: accounts[2] }).should.be.rejectedWith(errorMessage);
  });

  it('should allow only owner to remove investor from whitelist', async function () {
    await this.whitelist.addInvestorToWhitelist(accounts[1]);

    //should not allow to call by not owner
    await this.whitelist.removeInvestorFromWhitelist(accounts[1], { from: accounts[2] }).should.be.rejectedWith(errorMessage);

    await this.whitelist.removeInvestorFromWhitelist(accounts[1]);

    const result = await this.whitelist.isWhitelisted.call(accounts[1]);
    assert.equal(false, result);

    //should not allow to remove 1 more time
    await this.whitelist.removeInvestorFromWhitelist(accounts[1]).should.be.rejectedWith(errorMessage);
  });

  it('should allow only owner to add multiple accounts to whitelist', async function () {
      await this.whitelist.addInvestorsToWhitelist(accounts);

      for(let i = 0; i < 10; i++) {
        const result = await this.whitelist.isWhitelisted.call(accounts[i]);
        assert.equal(true, result);
      }

      // Should not allow to add already added accounts again
      await this.whitelist.addInvestorsToWhitelist(accounts);

      //should not allow to call by not owner
      await this.whitelist.addInvestorsToWhitelist(accounts, { from: accounts[2] }).should.be.rejectedWith(errorMessage);
  });
});