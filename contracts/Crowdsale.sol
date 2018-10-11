pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./JarvisToken.sol";
import "./Privileged.sol";
import "./Whitelist.sol";
import "./oracle/PriceReceiver.sol";

contract Crowdsale is Pausable, PriceReceiver {

    event Investment(address addr, uint256 value);

    using SafeMath for uint256;

    /**
     * @dev Transaction structure to keep information about investments.
     * @param addr Address of the investor.
     * @param investment Amount of investment in wei.
     * @param tokens Amount of tokens without bonus to receive.
     * @param bonus Amount of bonus tokens to receive.
     * @param timestamp UNIX timestamp of investment.
     * @param processed Flag indicating if the transaction has been processed by one of the distribution functions.
     * @param isContract Flag indicating if the investor's address is a smart contract.
     */
    struct Transaction {
        address addr;
        uint256 investment;
        uint256 tokens;
        uint256 bonus;
        uint256 timestamp;
        bool processed;
        bool isContract;
    }

    // Array of Transaction structures for investment.

    Transaction[] public history;

    // Counter of processed investments.

    uint256 public processedCount;

    // Array of addresses of investors in Pre-ICO and ICO stages.

    address[] public preIcoInvestorsAddresses;

    address[] public icoInvestorsAddresses;

    // Mapping of investments of Pre-ICO and ICO investors. Key = Investor address, Value = Amount of wei invested in ICO.

    mapping(address => uint256) public preIcoInvestors;

    mapping(address => uint256) public icoInvestors;

    // Mapping of tokens to be received by Pre-ICO and ICO investors. Key = Investor address, Value = Total amount of tokens to receive.

    mapping(address => uint256) public icoInvestorsTokens;

    // Amount of wei collected in Pre-ICO and ICO stages.

    uint256 public preIcoTotalCollected;

    uint256 public icoTotalCollected;

    // Total number of tokens with bonus to be distributed to investors during the crowdsale

    uint256 public totalIcoTokens;

    // 1 Jarvis Reward Token = 10 cents

    uint256 public constant jrtUsdRate = 10*1e16;

    // Jarvis Reward Token contract.

    JarvisToken public token;

    // Privileged contract.

    Privileged public privileged;

    // Whitelist contract.

    Whitelist public whitelist;

    // Start and finish time of Pre-ICO and ICO stages.

    uint256 public preIcoStartTime;

    uint256 public preIcoFinishTime;

    uint256 public icoStartTime;

    uint256 public icoFinishTime;

    // Flag indicating that the ICO dates were set

    bool public installed;

    // Number of tokens without bonus and bonus tokens distributed to investors.

    uint256 public soldTokens;

    uint256 public bonusTokens;

    // Number of tokens without bonus to be distributed in each ICO stage

    uint256[] public icoTokens;

    // Hard cap amount in every ICO Stage = 40 000 000 tokens (Unsold tokens are transferred to stage 3 of the ICO)

    uint256[] public icoHardCaps;

    // Indicators for hit hard caps for each stage

    bool[] public icoHardCapsHit;

    // Pre-allocated tokens for private investors, team (includes advisors, DAO and Partnership pool) and bounty campaign participants

    uint256 public constant investorsAllocation = 76000000*1e2;

    uint256 public constant teamAllocation = 140000000*1e2;

    uint256 public constant bountyAllocation = 20000000*1e2;

    // Currently allocated amounts using one of the functions for allocation

    uint256 public investorsTotalAllocated = 0;

    uint256 public teamTotalAllocated = 0;

    uint256 public bountyTotalAllocated = 0;

    // Counters of processed investors, team and bounty program participants

    uint256 public investorsProcessed;

    uint256 public teamProcessed;

    uint256 public bountyProcessed;

    // Adresses and values of pre-allocated tokens for investors, team and bounty program participants

    address[] public investorsAllocatedAddresses;

    address[] public teamAllocatedAddresses;

    address[] public bountyAllocatedAddresses;

    mapping(address => uint256) public investorsAllocated;

    mapping(address => uint256) public teamAllocated;

    mapping(address => uint256) public bountyAllocated;

    // referrals[addr] => returns the address which referred 'addr' to this ICO (if any).

    mapping(address => address) public referrals;

    constructor(uint256 _baseEthUsdPrice, address privilegedAddress, address whitelistAddress) public {
        privileged = Privileged(privilegedAddress);
        whitelist = Whitelist(whitelistAddress);
        installed = false;

        for (uint8 i = 0; i < 4; ++i) {
            icoTokens.push(0);
            icoHardCapsHit.push(false);
            icoHardCaps.push(40000000*1e2);
        }

        ethUsdRate = _baseEthUsdPrice;
    }

    // Fallback investor function.

    function() public payable {
        buy(msg.sender, msg.value);
    }

    function setTokenContract(address tokenAddress) public onlyOwner {
        require(tokenAddress != 0x0);
        token = JarvisToken(tokenAddress);
    }

    function setEthProvider(address provider) external onlyOwner {
        require(provider != 0x0);
        priceProvider = provider;
    }

    /**
     * @dev (Comment valid for the next three functions)
     * @dev Functions to set the pre-allocated amount of tokens of addresses to receive
     * @dev Only the owner can call the functions
     * @param destination Array of addresses to receive tokens.
     * @param value  Amount of tokens for each address to receive.
     */
    function addInvestorAllocation(address[] destination, uint256[] value) external onlyOwner {
        require(destination.length == value.length);
        uint256 len = destination.length;
        uint256 sum = 0;

        for (uint256 i = 0; i < len; ++i) {
            require(destination[i] != 0x0);
            sum = sum.add(value[i]);
        }

        investorsTotalAllocated = investorsTotalAllocated.add(sum);

        require(investorsTotalAllocated < investorsAllocation);

        for (uint256 j = 0; j < len; ++j) {
            if (investorsAllocated[destination[j]] == 0)
                investorsAllocatedAddresses.push(destination[j]);

            investorsAllocated[destination[j]] = investorsAllocated[destination[j]].add(value[j]);
        }
    }

    function addTeamAllocation(address[] destination, uint256[] value) external onlyOwner {
        require(destination.length == value.length);
        uint256 len = destination.length;
        uint256 sum = 0;

        for (uint256 i = 0; i < len; ++i) {
            require(destination[i] != 0x0);
            sum = sum.add(value[i]);
        }

        teamTotalAllocated = teamTotalAllocated.add(sum);

        require(teamTotalAllocated < teamAllocation);

        for (uint256 j = 0; j < len; ++j) {
            if (teamAllocated[destination[j]] == 0)
                teamAllocatedAddresses.push(destination[j]);

            teamAllocated[destination[j]] = teamAllocated[destination[j]].add(value[j]);
        }
    }

    function addBountyAllocation(address[] destination, uint256[] value) external onlyOwner {
        require(destination.length == value.length);
        uint256 len = destination.length;
        uint256 sum = 0;

        for (uint256 i = 0; i < len; ++i) {
            require(destination[i] != 0x0);
            sum = sum.add(value[i]);
        }

        bountyTotalAllocated = bountyTotalAllocated.add(sum);

        require(bountyTotalAllocated < bountyAllocation);

        for (uint256 j = 0; j < len; ++j) {
            if (bountyAllocated[destination[j]] == 0)
                bountyAllocatedAddresses.push(destination[j]);

            bountyAllocated[destination[j]] = bountyAllocated[destination[j]].add(value[j]);
        }
    }

    /**
     * @dev (Comment valid for the next three functions)
     * @dev Functions to distribute tokens to the pre-allocated addresses
     * @dev Every address is processed only once.
     * @dev Privileged users or owner can call the functions
     * @param count count of addresses to process.
     */
    function distributeToPrivateInvestors(uint256 count) external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoFinished());

        uint256 addressesLeft = investorsAllocatedAddresses.length.sub(investorsProcessed);
        uint256 top = investorsProcessed.add(count);

        if (count > addressesLeft)
            top = investorsProcessed.add(addressesLeft);

        for (uint256 i = investorsProcessed; i < top; ++i) {
            token.transfer(investorsAllocatedAddresses[i], investorsAllocated[investorsAllocatedAddresses[i]]);
            ++investorsProcessed;
        }
    }

    function distributeToTeam(uint256 count) external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoFinished());

        uint256 addressesLeft = teamAllocatedAddresses.length.sub(teamProcessed);
        uint256 top = teamProcessed.add(count);

        if (count > addressesLeft)
            top = teamProcessed.add(addressesLeft);

        for (uint256 i = teamProcessed; i < top; ++i) {
            token.transfer(teamAllocatedAddresses[i], teamAllocated[teamAllocatedAddresses[i]]);
            ++teamProcessed;
        }
    }

    function distributeToBountyParticipants(uint256 count) external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoFinished());

        uint256 addressesLeft = bountyAllocatedAddresses.length.sub(bountyProcessed);
        uint256 top = bountyProcessed.add(count);

        if (count > addressesLeft)
            top = bountyProcessed.add(addressesLeft);

        for (uint256 i = bountyProcessed; i < top; ++i) {
            token.transfer(bountyAllocatedAddresses[i], bountyAllocated[bountyAllocatedAddresses[i]]);
            ++bountyProcessed;
        }
    }

    /**
    * @dev Function for manual transfer of tokens to investors.
    * @dev As soon as the function processes the entire array of transaction indices, it stops executing successfully.
    * @dev The owner or privileged users can call the function
    * @param transactions Exact history transaction indices to be processed
    */
    function distributeManual(uint256[] transactions) external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoFinished());

        uint256 j = 0;
        uint256 i = 0;
        uint len = transactions.length;

        while (j < len) {
            i = transactions[j];
            processTransaction(history[i], i);
            ++j;
        }
    }

    /**
    * @dev Function for automatic transfer of tokens to investors.
    * @dev The owner or privileged users can call the function
    * @param transactions Number of transactions to process
    */
    function distributeAutomatic(uint256 transactions) external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoFinished());
        require(processedCount < history.length);

        uint256 count = 0;

        for (uint256 i = processedCount; i < history.length; ++i) {
            if (count >= transactions)
                break;
            processTransaction(history[i], i);
            ++count;
            ++processedCount;
        }
    }

    /**
    * @dev Function to transfer the number of tokens to investors
    * @param transaction Transaction log
    * @param index Index of transaction in history
    */
    function processTransaction(Transaction transaction, uint256 index) private {

        if (transaction.processed) {
            return;
        }

        if (isContract(transaction.addr) && !history[index].isContract) {
            history[index].isContract = true;
            return;
        }

        if (!isWhitelisted(transaction.addr)) {
            transaction.addr.transfer(transaction.investment);
            history[index].processed = true;
            return;
        }

        soldTokens = soldTokens.add(transaction.tokens);
        bonusTokens = bonusTokens.add(transaction.bonus);

        uint256 total = transaction.tokens.add(transaction.bonus);
        token.transfer(transaction.addr, total);
        history[index].processed = true;
    }

    /**
     * @dev function for receiving investment.
     * @dev is only called from payable function.
     * @dev Contract should not be in a paused state
     * @param addr Investor's address.
     * @param investment Amount of investment.
     */
    function buy(address addr, uint256 investment) private whenNotPaused {
        require(addr != address(0));
        require(preIcoStage() || icoStage1() || icoStage2() || icoStage3());

        //Investment should be at least 0.1 Ether
        require(investment >= 1e17);
        uint256 tokens = investment.mul(ethUsdRate).div(jrtUsdRate);
        uint256 bonus = 0;

        if (preIcoStage()) {
            (investment, tokens) = hardCapCheck(addr, tokens, investment, 0);

            bonus = tokens.mul(3).div(10);

            if (preIcoInvestors[addr] == 0)
                preIcoInvestorsAddresses.push(addr);

            preIcoInvestors[addr] = preIcoInvestors[addr].add(investment);
            preIcoTotalCollected = preIcoTotalCollected.add(investment);
        }
        else {
            if (icoStage1()) {
                (investment, tokens) = hardCapCheck(addr, tokens, investment, 1);

                bonus = tokens.mul(2).div(10);
            }

            else if (icoStage2()) {
                (investment, tokens) = hardCapCheck(addr, tokens, investment, 2);

                bonus = tokens.mul(1).div(10);
            }

            else if (icoStage3()) {
                (investment, tokens) = hardCapCheck(addr, tokens, investment, 3);
            }

            if (icoInvestors[addr] == 0)
                icoInvestorsAddresses.push(addr);

            icoInvestors[addr] = icoInvestors[addr].add(investment);
            icoTotalCollected = icoTotalCollected.add(investment);
        }

        uint256 total = tokens.add(bonus);

        icoInvestorsTokens[addr] = icoInvestorsTokens[addr].add(total);
        history.push(Transaction(addr, investment, tokens, bonus, block.timestamp, false, false));
        emit Investment(addr, investment);

        totalIcoTokens = totalIcoTokens.add(total);
    }

    function hardCapCheck(address addr, uint256 tokens, uint256 investment, uint8 stage) private returns (uint256, uint256) {
        require(!icoHardCapsHit[stage]);

        icoTokens[stage] = icoTokens[stage].add(tokens);

        if (icoTokens[stage] > icoHardCaps[stage]) {
            icoHardCapsHit[stage] = true;
            uint256 actualTokens = icoHardCaps[stage].sub(icoTokens[stage].sub(tokens));
            uint256 overhead = (tokens.sub(actualTokens)).mul(jrtUsdRate).div(ethUsdRate);

            investment = investment.sub(overhead);
            tokens = actualTokens;
            addr.transfer(overhead);
        }
        return (investment, tokens);
    }

    /**
     * @dev Function for withdrawing ethereum.
     * @dev The owner or privileged users can call the function
     * @dev Contract should not be in a paused state
     * @param weiToWithdraw  Amount of wei for transaction.
     */
    function withdraw(uint256 weiToWithdraw) external whenNotPaused {
        require(icoFinished());
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(weiToWithdraw <= address(this).balance);
        require(weiToWithdraw != 0);

        msg.sender.transfer(weiToWithdraw);
    }

    /**
    * @dev Function for manual refunding of users.
    * @dev Privileged users or owner can call the function.
    */
    function refund(address toBeRefunded) external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoFinished());

        if (preIcoInvestors[toBeRefunded] > 0)
            toBeRefunded.transfer(preIcoInvestors[toBeRefunded]);
        if (icoInvestors[toBeRefunded] > 0)
            toBeRefunded.transfer(icoInvestors[toBeRefunded]);
    }

     /**
    * @dev If the hard cap of the stage 0, 1 or 2 wasn't hit,
    * @dev transfer remaining tokens to last stage of the ico.
    * @dev Privileged users or owner can call the function.
    */
    function moveUnsold() external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoStage3());

        if (!icoHardCapsHit[0])
            icoHardCaps[3] = icoHardCaps[3].add(icoHardCaps[0].sub(icoTokens[0]));

        if (!icoHardCapsHit[1])
            icoHardCaps[3] = icoHardCaps[3].add(icoHardCaps[1].sub(icoTokens[1]));

        if (!icoHardCapsHit[2])
            icoHardCaps[3] = icoHardCaps[3].add(icoHardCaps[2].sub(icoTokens[2]));
    }

    /**
     * @dev set Ico and PreIco Stages start time.
     * @dev Only the owner can call the function
     * @param preIcoStart Unix timestamp PreIco start time.
     * @param preIcoDuration  PreIco duration.
     * @param icoDuration Ico duration.
     */
    function setDates(uint256 preIcoStart, uint256 preIcoDuration, uint256 icoDuration) public onlyOwner {
        require(!installed);
        require(preIcoStart != 0);
        require(preIcoDuration != 0 && icoDuration != 0);
        require(preIcoFinishTime == 0 && icoFinishTime == 0);

        preIcoStartTime = preIcoStart;
        preIcoFinishTime = preIcoStart.add(preIcoDuration);

        icoStartTime = preIcoFinishTime + 1 seconds;
        icoFinishTime = icoStartTime.add(icoDuration);

        installed = true;
    }

    /**
     * @dev check PreIco Stage.
     * @return bool true if PreIco Stage is now.
     */
    function preIcoStage() public view returns (bool) {
        return (installed && block.timestamp >= preIcoStartTime &&
                                block.timestamp <= preIcoFinishTime);
    }

    /**
     * @dev check which stage the ico is in.
     */
    function icoStage1() public view returns (bool) {
        return (installed && block.timestamp >= icoStartTime &&
                                block.timestamp <= icoStartTime + 1 weeks);
    }

    function icoStage2() public view returns (bool) {
        return (installed && block.timestamp > icoStartTime + 1 weeks &&
                                block.timestamp <= icoStartTime + 2 weeks);
    }

    function icoStage3() public view returns (bool) {
        return (installed && block.timestamp > icoStartTime + 2 weeks &&
                                block.timestamp <= icoFinishTime);
    }

    /**
     * @dev check Ico Finish.
     * @return bool true if Ico Finished.
     */
    function icoFinished() public view returns (bool) {
        return (installed && icoFinishTime != 0 && block.timestamp >= icoFinishTime);
    }

    /**
     * @dev Function returns the investments count.
     */
    function historyLength() public view returns (uint256) {
        return history.length;
    }

    /**
     * @dev Function returns information about the investment.
     * @param index emit Investment sequence number.
     */
    function historyRecord(uint256 index) public view returns (address addr, uint256 investment,
                                                                uint256 tokens, uint256 bonus,
                                                                uint256 timestamp, bool processed, bool isContract) {
        Transaction memory h = history[index];
        return (h.addr, h.investment, h.tokens, h.bonus, h.timestamp, h.processed, h.isContract);
    }

    /**
     * @dev returns the number of investors in Pre-ICO stage.
     */
    function preIcoInvestorsCount() public view returns (uint256) {
        return preIcoInvestorsAddresses.length;
    }

    /**
     * @dev returns the number of investors in ICO stage.
     */
    function icoInvestorsCount() public view returns (uint256) {
        return icoInvestorsAddresses.length;
    }

    // Proxy functions to interact with token, whitelist and privileged contracts

    // Token functions

    /**
     * @dev Change the owner of the JRT token contract.
     */
    function tokenTransferOwnership(address owner) external onlyOwner {
        token.transferOwnership(owner);
    }

    /**
     * @dev Transfer of tokens from the Crowdsale address to another address.
     * @dev The owner or privileged users can call the function
     * @param addr Address to receive tokens.
     * @param amount Amount of tokens for transfer.
     */
    function privilegedTokenTransfer(address addr, uint256 amount) external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoFinished());
        token.transfer(addr, amount);
    }

    /**
     * @dev Token burning.
     * @dev The owner or privileged users can call the function
     * @param amount Amount JRT tokens for Burning.
     */
    function privilegedBurn(uint256 amount) external {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(icoFinished());
        token.privilegedBurn(amount);
    }

    // Privileged functions

    /**
     * @dev Add a privileged account.
     * @dev The owner can call the function
     * @param addr Account address.
     */
    function addToPrivileged(address addr) external onlyOwner {
        privileged.addToPrivileged(addr);
    }

    /**
     * @dev Add a whitelisting account (Account is only able to add to whitelist).
     * @dev The owner can call the function
     * @param addr Account address.
     */
    function addWhitelistingAccount(address addr) external onlyOwner {
        privileged.addWhitelistingAccount(addr);
    }

    /**
     * @dev Del a privileged account.
     * @dev The owner can call the function
     * @param addr Account address.
     */
    function removeFromPrivileged(address addr) external onlyOwner {
        privileged.removeFromPrivileged(addr);
    }

    /**
    * @dev count of privileged addresses ever added (including deactivated addresses).
    * @dev Only the owner can view
    * @return uint256 number of privileged addresses ever added
    */
    function privilegedAccountsCount() external view onlyOwner returns (uint256) {
        return privileged.privilegedAccountsCount();
    }

    /**
    * @dev get privileged address by index.
    * @dev only the owner can view
    */
    function privilegedAccountAddress(uint256 index) external view onlyOwner returns (address) {
        return privileged.privilegedAddress(index);
    }

    /**
     * @dev get privileged status by address.
     * @dev Only the owner can view
     * @param addr Address
     * @return uint8 Status by address.
     * 0 - address never added
     * 1 - address deactivated
     * 2 - privileged address
     */
    function privilegedAccountStatus(address addr) external view onlyOwner returns (uint8) {
        return privileged.privilegedAccountStatus(addr);
    }

    /**
     * @dev Change the owner of the Privileged contract.
     * @param newOwner New owner address.
     */
    function privilegedTransferOwnership(address newOwner) external onlyOwner {
        privileged.transferOwnership(newOwner);
    }

    // Referral functions

    function addReferralOf(address investor, address ref) external {
        require(investor != 0x0 && ref != 0x0);
        require(referrals[investor] == 0x0 && investor != ref);
        referrals[investor] = ref;
    }

    function getReferralOf(address investor) public view returns (address result) {
        return referrals[investor];
    }

    // Whitelisting functions

    function isWhitelisted(address addr) public view returns (bool) {
        return whitelist.isWhitelisted(addr);
    }

    function addToWhitelist(address whitelisted) external {
        require(msg.sender == owner ||
        privileged.isWhitelisting(msg.sender));

        whitelist.addInvestorToWhitelist(whitelisted);
    }

    function addInvestorsToWhitelist(address[] whitelisted) external {
        require(msg.sender == owner ||
        privileged.isWhitelisting(msg.sender));

        whitelist.addInvestorsToWhitelist(whitelisted);
    }

    function removeFromWhitelist(address whitelisted) external {
        require(msg.sender == owner ||
        privileged.isPrivileged(msg.sender));

        whitelist.removeInvestorFromWhitelist(whitelisted);
    }

    function whitelistTransferOwnership(address owner) external onlyOwner {
        whitelist.transferOwnership(owner);
    }

    // Utility functions

    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

}
