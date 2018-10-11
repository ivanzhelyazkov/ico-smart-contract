pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Privileged is Ownable {

    event ChangePrivilegedAccount(address addr);

    /**
     * @dev Privileged account status :
     * 0 - address never added
     * 1 - address deactivated
     * 2 - privileged address
     * 3 - whitelisting address (Is able to whitelist investors)
     */
    mapping(address => uint8) public status;

    address[] public privilegedAccounts;

    /**
     * @dev The constructor makes the message sender
     *      Privileged.
     */
    constructor() public {
        privilegedAccounts.push(msg.sender);
        status[msg.sender] = 2;
        emit ChangePrivilegedAccount(msg.sender);
    }

    /**
     * @dev check if address is privileged.
     * @param addr The address for verification.
     */
    function isPrivileged(address addr) external view returns (bool) {
        return status[addr] == 2;
    }

    /**
     * @dev check if address is able to whitelist investors.
     * @param addr The address for verification.
     */
    function isWhitelisting(address addr) external view returns (bool) {
        return status[addr] == 2 || status[addr] == 3;
    }

    /**
     * @dev add a privileged address.
     */
    function addToPrivileged(address addr) external onlyOwner returns (bool) {
        require(addr != address(0));

        if (status[addr] == 2) {
            return true;
        }
        if (status[addr] == 1 || status[addr] == 3) {
            status[addr] = 2;
            emit ChangePrivilegedAccount(addr);
            return true;
        }
        if (status[addr] == 0) {
            privilegedAccounts.push(addr);
            status[addr] = 2;
            emit ChangePrivilegedAccount(addr);
            return true;
        }
        return false;
    }

    /**
     * @dev Add address to be whitelisting.
     */
    function addWhitelistingAccount(address addr) external onlyOwner returns (bool) {
        require(addr != address(0));

        if (status[addr] == 2 || status[addr] == 3) {
            return true;
        }
        if (status[addr] == 1) {
            status[addr] = 3;
            emit ChangePrivilegedAccount(addr);
            return true;
        }
        if (status[addr] == 0) {
            privilegedAccounts.push(addr);
            status[addr] = 3;
            emit ChangePrivilegedAccount(addr);
            return true;
        }
    }

    /**
     * @dev deactivates a privileged address.
     */
    function removeFromPrivileged(address addr) external onlyOwner returns (bool) {
        require(addr != owner);
        require(status[addr] == 2 || status[addr] == 3);

        status[addr] = 1;
        emit ChangePrivilegedAccount(addr);
        return true;
    }

    /**
     * @dev the number of privileged addresses ever added. (including deactivated addresses)
     * @dev Only the owner can view
     */
    function privilegedAccountsCount() external view onlyOwner returns (uint256) {
        return privilegedAccounts.length;
    }

    /**
     * @dev get privileged address by index.
     * @dev only the owner can view
     */
    function privilegedAddress(uint256 index) external view onlyOwner returns (address) {
        return privilegedAccounts[index];
    }

    /**
     * @dev get privileged status by address.
     * @dev Only the owner can view
     * @param addr address Address
     * @return uint8 Status by address.
     * 0 - address never added
     * 1 - address deactivated
     * 2 - privileged address
     * 3 - whitelisting address
     */
    function privilegedAccountStatus(address addr) external view onlyOwner returns (uint8) {
        return status[addr];
    }

}
