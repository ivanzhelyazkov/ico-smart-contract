pragma solidity ^0.4.24;

contract PriceReceiver {
    address public priceProvider;
    uint256 public ethUsdRate;

    modifier onlyPriceProvider() {
        require(msg.sender == priceProvider);
        _;
    }

    function receiveEthPrice(uint256 ethUsdPrice) external {
        require(msg.sender == priceProvider);
        require(ethUsdPrice > 0);
        ethUsdRate = ethUsdPrice;
    }

    function setEthProvider(address provider) external;
}
