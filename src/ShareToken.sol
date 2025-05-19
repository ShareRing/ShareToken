// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./interfaces/IPrevShareToken.sol";

contract ShareToken is ERC20, ERC20Burnable, ERC20Pausable, AccessControl, ERC20Permit {
    uint256 public constant PREV_DECIMALS = 2;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    IPrevShareToken public prevShareToken;

    /**
     * @dev Keep track of whether a specific address's balance has been migrated.
     * true when: an address has previous SHR, and already migrated
     * false when: an address has previous SHR but has not yet migrated, or when an address does not have previous SHR
     */
    mapping(address => bool) public balanceMigrated;

    /**
     * @dev Keep track of whether a specific address's allowance for a spender has been migrated.
     * true when: an address has previous SHR allowance for a spender, and already migrated
     * false when: an address has previous SHR allowance for a spender but has not yet migrated,
     * or when an address does not have previous SHR allowance for a spender
     */
    mapping(address => mapping(address => bool)) public allowanceMigrated;

    error PrevShareTokenContractNotLocked();

    event MigrateBalance(address indexed owner, uint256 amount);
    event MigrateAllowance(address indexed owner, address spender, uint256 amount);

    constructor(address prevShareTokenAddress, address defaultAdmin, address pauser, address minter)
        ERC20("ShareToken", "SHR")
        ERC20Permit("ShareToken")
    {
        prevShareToken = IPrevShareToken(prevShareTokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(PAUSER_ROLE, pauser);
        _grantRole(MINTER_ROLE, minter);
    }

    /**
     * @dev Returns the previous balance of the specified `owner`.
     * The previous balance of the `owner` converted to the decimals of this contract.
     */
    function _prevBalance(address owner) private view returns (uint256) {
        return prevShareToken.balanceOf(owner) * 10 ** decimals() / 10 ** PREV_DECIMALS;
    }

    /**
     * @dev Returns the previous allowance of the `spender` for the `owner` converted to the decimals of this contract.
     * The previous allowance of the `spender` for the `owner` converted to the decimals of this contract.
     */
    function _prevAllowance(address owner, address spender) private view returns (uint256) {
        return prevShareToken.allowance(owner, spender) * 10 ** decimals() / 10 ** PREV_DECIMALS;
    }

    /**
     * @dev Returns the balance of the specified `owner`.
     * If the balance has been migrated, return the balance of the `owner`.
     * Otherwise, return the sum of the current balance of the `owner` and their previous balance.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (balanceMigrated[owner]) {
            return super.balanceOf(owner);
        }
        return super.balanceOf(owner) + _prevBalance(owner);
    }

    /**
     * @dev Returns the allowance of the specified `owner` for the `spender`.
     * If the allowance has been migrated, return the allowance of the `owner` for the `spender`.
     * Otherwise, return the sum of the current allowance of the `owner` for the `spender` and their previous allowance for the `spender`.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        if (allowanceMigrated[owner][spender]) {
            return super.allowance(owner, spender);
        }
        return super.allowance(owner, spender) + _prevAllowance(owner, spender);
    }

    /**
     * @dev Migrates the balance of a given `owner` from a previous ShareToken contract to the current contract.
     * @return A abitrary boolean value indicating whether the migration executed. Note that false does not mean that the
     * migration failed, but rather that the migration was skipped because it had already been executed.
     * Emits a {MigrateBalance} event.
     */
    function _migrateBalance(address owner) internal returns (bool) {
        // if already migrated, just return false and skip the migration
        if (balanceMigrated[owner]) {
            return false;
        }

        balanceMigrated[owner] = true;

        // If the main sale token is not locked in the previous ShareToken, reverts
        if (!prevShareToken.mainSaleTokenLocked()) {
            revert PrevShareTokenContractNotLocked();
        }

        uint256 prevBalance = _prevBalance(owner);

        // mint new ShareToken to the caller
        _mint(owner, prevBalance);

        emit MigrateBalance(owner, prevBalance);

        return true;
    }

    /**
     * @dev Migrates the allowance from the previous ShareToken contract to the current contract.
     * @return A abitrary boolean value indicating whether the migration executed. Note that false does not mean that the
     * migration failed, but rather that the migration was skipped because it had already been executed.
     * Emits a {MigrateAllowance} event.
     */
    function _migrateAllowance(address owner, address spender) internal returns (bool) {
        // if already migrated, just return false and skip the migration
        if (allowanceMigrated[owner][spender]) {
            return false;
        }

        allowanceMigrated[owner][spender] = true;

        // If the main sale token is not locked in the previous ShareToken, reverts
        if (!prevShareToken.mainSaleTokenLocked()) {
            revert PrevShareTokenContractNotLocked();
        }

        uint256 prevAllowance = _prevAllowance(owner, spender);

        // approve the spender to spend the same amount of ShareToken
        _approve(owner, spender, prevAllowance);

        emit MigrateAllowance(owner, spender, prevAllowance);

        return true;
    }

    /**
     * @dev The first time a `msg.sender` transfers tokens, this function migrates their token balance
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _migrateBalance(msg.sender);
        return super.transfer(recipient, amount);
    }

    /**
     * @dev The first time a `msg.sender` calls this funcion, migrate `from`'s balance and `from`'s allowance for `msg.sender`.
     * This means that if `from` approves `msg.sender` in the previous contract, `msg.sender` can spend it in this contract.
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _migrateBalance(from);
        _migrateAllowance(from, msg.sender);
        return super.transferFrom(from, to, value);
    }

    /**
     * @dev The first time a `msg.sender` calls this function, mark the allowance as migrated, so it won't include the previous allowance in allowance().
     * i.e. the allowance will be the new amount, not the sum of the previous allowance and the new amount.
     * This is because the nature of the approve function is to override the allowance, not increase/decrease it.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        if (!allowanceMigrated[msg.sender][spender]) {
            allowanceMigrated[msg.sender][spender] = true;
        }
        return super.approve(spender, amount);
    }

    /**
     * @dev The first time a `msg.sender` calls this function, mark the allowance of the owner for the spender as migrated.
     * Same as approve function, this function marks the allowance as migrated so it won't include the previous allowance in allowance().
     */
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        override
    {
        if (!allowanceMigrated[owner][spender]) {
            allowanceMigrated[owner][spender] = true;
        }

        super.permit(owner, spender, value, deadline, v, r, s);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    /**
     * @dev The first time a `msg.sender` calls this function, migrate the `msg.sender`'s balance. Then, burns the specified amount of tokens.
     */
    function burn(uint256 value) public override {
        _migrateBalance(msg.sender);
        return super.burn(value);
    }

    /**
     * @dev The first time a `msg.sender` calls this funcion, migrate `account`'s balance and `account`'s allowance for `msg.sender`.
     * Then, burns the specified amount of tokens.
     */
    function burnFrom(address account, uint256 value) public override {
        _migrateBalance(account);
        _migrateAllowance(account, msg.sender);
        return super.burnFrom(account, value);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // The following functions are overrides required by Solidity.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
