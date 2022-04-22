// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
 * Abstract contract implementing core features of wallet
 * @author kchn9
 */
contract Wallet {

    event FundsDeposit(address who, uint256 amount);
    event FundsWithdraw(address who, uint256 amount);

    /// @notice Keep track of users balances
    mapping (address => uint256) internal _balances;

    /// @notice Checks if specified user has
    modifier hasBalance(address _who) {
        require(_balances[_who] > 0, "Wallet: Caller has no balance");
        _;
    }
    
    /// @notice Deposit user funds 
    function deposit() public virtual payable {}

    /// @notice Fallback - any funds sent directly to contract will be deposited
    receive() external virtual payable {}
    
    /// @notice Allow owner to withdraw only their funds
    function withdraw(uint256 _amount) virtual external {}

    function withdrawAll() virtual external {}

    /// @notice Getter for user balance
    function getBalance() public view virtual returns(uint256) {}

}