pragma solidity ^0.4.21;

import "./ERC20Interface.sol";
import "./SafeMath.sol";

contract ERC20Token is ERC20Interface {

    using SafeMath for uint256;

    // Total amount of tokens issued
    uint256 internal totalTokenIssued;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) internal allowed;

    function totalSupply() public view returns (uint256) {
        return totalTokenIssued;
    }

    /* Get the account balance for an address */
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /* Check whether an address is a contract address */
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return (size > 0);
    }


    /* Transfer the balance from owner's account to another account */
    function transfer(address _to, uint256 _amount) public returns (bool) {

        require(_to != address(0x0));

        // Do not allow to transfer token to contract address to avoid tokens getting stuck
        require(isContract(_to) == false);

        // amount sent cannot exceed balance
        require(balances[msg.sender] >= _amount);

        
        // update balances
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to]        = balances[_to].add(_amount);

        // log event
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    

    /* Allow _spender to withdraw from your account up to _amount */
    function approve(address _spender, uint256 _amount) public returns (bool) {
        
        require(_spender != address(0x0));

        // update allowed amount
        allowed[msg.sender][_spender] = _amount;

        // log event
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Spender of tokens transfers tokens from the owner's balance */
    /* Must be pre-approved by owner */
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool) {
        
        require(_to != address(0x0));
        
        // Do not allow to transfer token to contract address to avoid tokens getting stuck
        require(isContract(_to) == false);

        // balance checks
        require(balances[_from] >= _amount);
        require(allowed[_from][msg.sender] >= _amount);

        // update balances and allowed amount
        balances[_from]            = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to]              = balances[_to].add(_amount);

        // log event
        emit Transfer(_from, _to, _amount);
        return true;
    }

    /* Returns the amount of tokens approved by the owner */
    /* that can be transferred by spender */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
}
