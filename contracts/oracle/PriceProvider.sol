pragma solidity^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./usingOraclize.sol";
import "./PriceReceiver.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract PriceProvider is Ownable, usingOraclize {
    using SafeMath for uint;

    bool state = false;

    uint public updateInterval = 7200; // 2 hours

    uint public currentPrice;

    string public url = "json(https://api.coinbase.com/v2/prices/ETH-USD/spot).data.amount";

    PriceReceiver public priceReceiver;

    mapping (bytes32 => bool) validIds;

    event InsufficientFunds();

    constructor() public payable {
        update(0);
    }

    function() public payable {

    }

    function startUpdate(uint startingPrice) public payable onlyOwner {
        require(state == false);
        state = true;
        
        currentPrice = startingPrice;
        update(updateInterval);
    }

    function stopUpdate() external onlyOwner {
        require(state == true);
        state = false;
    }

    function setListener(address priceReceiverAddress) public onlyOwner {
        require(priceReceiverAddress != 0x0);
        priceReceiver = PriceReceiver(priceReceiverAddress);
    }

    function setUpdateInterval(uint newInterval) external onlyOwner {
        require(newInterval > 0);
        updateInterval = newInterval;
    }

    function setUrl(string newUrl) external onlyOwner {
        require(bytes(newUrl).length > 0);
        url = newUrl;
    }

    function __callback(bytes32 myid, string result, bytes proof) {
        require(msg.sender == oraclize_cbAddress() && validIds[myid]);
        delete validIds[myid];

        uint newPrice = parseInt(result, 2);
        require(newPrice > 0);

        currentPrice = newPrice;

        if (state == true) {
            priceReceiver.receiveEthPrice(currentPrice);
            update(updateInterval);
        }
    }

    function update(uint delay) private {
        if (oraclize_getPrice("URL") > this.balance) {
            //stop if we don't have enough funds anymore
            state = false;
            emit InsufficientFunds();
        } else {
            bytes32 queryId = oraclize_query(delay, "URL", url);
            validIds[queryId] = true;
        }
    }

    //we need to get back our funds if we don't need this oracle anymore
    function withdraw(address receiver) external onlyOwner {
        require(state == false);
        require(receiver != 0x0);
        receiver.transfer(this.balance);
    }
}