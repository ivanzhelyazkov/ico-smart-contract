const Privileged = artifacts.require("Privileged");

contract("Privileged", function (accounts) {
  beforeEach(async function () {
    this.privileged = await Privileged.new();
  });
  
  it('Only owner account should be privileged by default', async function() {
    const result = await this.privileged.isPrivileged(accounts[0]);

    for(i = 1; i < accounts.length; ++i) {
      assert.equal(await this.privileged.isPrivileged(accounts[i]), false);
    }

    assert.equal(result, true);
  });

it('Account status works as expected', async function(){
    var result = await this.privileged.privilegedAccountStatus(accounts[1]);
    assert.equal(result, 0)
    
    // Accounts which are privileged have a status 2
    await this.privileged.addToPrivileged(accounts[1]);

    result = await this.privileged.privilegedAccountStatus(accounts[1]);
    assert.equal(result, 2)

    // Accounts which have been removed from privileged have a status 1
    await this.privileged.removeFromPrivileged(accounts[1]);

    result = await this.privileged.privilegedAccountStatus(accounts[1]);
    assert.equal(result, 1)
});

it('Adding and removing privileged accounts works correctly', async function() {
    var result = await this.privileged.isPrivileged(accounts[1]);
    assert.equal(result, false);

    await this.privileged.addToPrivileged(accounts[1]);

    result = await this.privileged.isPrivileged(accounts[1]);
    assert.equal(result, true);

    await this.privileged.removeFromPrivileged(accounts[1]);

    result = await this.privileged.isPrivileged(accounts[1]);
    assert.equal(result, false);
});

it('Verify that accounts which are whitelisting work as expected', async function() {
  await this.privileged.addWhitelistingAccount(web3.eth.accounts[1]);

  // Account should be whitelisting
  var result = await this.privileged.isWhitelisting(web3.eth.accounts[1]);

  // Account status should be '3'
  var status = await this.privileged.privilegedAccountStatus(web3.eth.accounts[1]);

  assert.equal(result,true);
  assert.equal(status,3);

  await this.privileged.removeFromPrivileged(web3.eth.accounts[1]);

  // Account should be deactivated
  result = await this.privileged.isWhitelisting(web3.eth.accounts[1]);

  // Account status should be '1'
  status = await this.privileged.privilegedAccountStatus(web3.eth.accounts[1]);

  assert.equal(result,false);
  assert.equal(status, 1);
});
});
