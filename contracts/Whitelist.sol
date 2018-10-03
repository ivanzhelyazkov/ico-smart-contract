pragma solidity ^0.4.24;
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract Whitelist is Ownable {
    mapping (address => bool) public investorWhiteList;

    constructor() public {

    }

    function addInvestorToWhitelist(address investor) external onlyOwner {
        require(investor != 0x0 && !investorWhiteList[investor]);
        investorWhiteList[investor] = true;
    }

    function addInvestorsToWhitelist(address[] investors) external onlyOwner {
        uint256 len = investors.length;
        
        for (uint256 i = 0; i < len; ++i) {
            if (investors[i] == 0x0 || investorWhiteList[investors[i]])
                continue;
            investorWhiteList[investors[i]] = true;
        }
    }

    function removeInvestorFromWhitelist(address investor) external onlyOwner {
        require(investor != 0x0 && investorWhiteList[investor]);
        investorWhiteList[investor] = false;
    }

    function isWhitelisted(address investor) external view returns (bool) {
        return investorWhiteList[investor];
    }
}