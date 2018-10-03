pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol";
import "./Privileged.sol";


    contract JarvisToken is PausableToken {
    
    string public constant name = "Jarvis Reward Token";
    
    string public constant symbol = "JRT";
    
    uint32 public constant decimals = 2;

    event Burn(address indexed burner, uint256 value);

    Privileged public privileged;

    address public tokenStorage;

    /**
     * @dev Constructor : set Privileged contract and tokenStorage address, 
     * @dev mint 420 000 000 tokens to token storage
     */
    constructor(address crowdsaleAddress, address privilegedAddress) public {
        tokenStorage = crowdsaleAddress;
        mintTokens(tokenStorage, 420000000*1E2);
        privileged = Privileged(privilegedAddress);
        transferOwnership(crowdsaleAddress);
    }
    
    /**
    * @dev Mint tokens to a specified address
    * @param _to The address to mint to.
    * @param _amount The amount to be minted.
    */
    function mintTokens(address _to, uint256 _amount) private {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
    }

    /**
    * @dev privileged token transfer from tokenStorage to a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function privilegedTransfer(address _to, uint256 _value) public returns (bool) {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(_to != address(0));
        require(_value <= balances[tokenStorage]);
        require(_value > 0);

        balances[tokenStorage] = balances[tokenStorage].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(tokenStorage, _to, _value);

        return true;
    }

    /**
    * @dev Burns a specific amount of tokens from a preferred address.
    * @param _value The amount of token to be burned.
    */
    function privilegedBurn(uint256 _value) public returns (bool) {
        require(privileged.isPrivileged(msg.sender) || msg.sender == owner);
        require(_value > 0);
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        return true;
    }
    
}