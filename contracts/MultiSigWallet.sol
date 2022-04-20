// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Signed.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** 
 * @author kchn9
 */
contract MultiSigWallet is Signed, Ownable {

    event FundsDeposit(address who, uint256 amount);
    event FundsWithdraw(address who, uint256 amount);
    
    /// @notice Keep track of users balances
    mapping (address => uint256) private _balances;
    
    /// @notice Deposit user funds 
    function deposit() public payable {
        require(msg.value > 0, "Wallet: Value cannot be 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposit(msg.sender, msg.value);
    }

    /// @notice Fallback - any funds sent directly to contract will be deposited
    receive() external payable {
        deposit();
    }
    
    /// @notice Allow owner to withdraw only their funds
    function withdraw(uint256 _amount) external onlySigner {
        require(_amount <= getBalance(), "Wallet: Callers balance is insufficient");
        payable(msg.sender).transfer(_amount);
        emit FundsWithdraw(msg.sender, _amount);
    }

    function withdrawAll() external onlySigner {
        uint256 amount = getBalance();
        payable(msg.sender).transfer(amount);
        emit FundsWithdraw(msg.sender, amount);
    }

    /// @notice Getter for user balance
    function getBalance() public onlySigner view returns(uint256) {
        return _balances[msg.sender];
    }

    /// @notice Getter for contract balance
    function getContractBalance() public onlySigner view returns(uint256) {
        return address(this).balance;
    }

}