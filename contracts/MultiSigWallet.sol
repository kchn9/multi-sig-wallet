// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SignedWallet.sol";

/** 
 * @author kchn9
 */
contract MultiSigWallet is SignedWallet {

    function deposit() public override payable {
        require(msg.value > 0, "Wallet: Value cannot be 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposit(msg.sender, msg.value);
    }

    receive() external override payable {
        deposit();
    }
    
    function withdraw(uint256 _amount) override external onlySigner {
        require(_amount <= getBalance(), "Wallet: Callers balance is insufficient");
        payable(msg.sender).transfer(_amount);
        emit FundsWithdraw(msg.sender, _amount);
    }

    function withdrawAll() override external onlySigner {
        uint256 amount = getBalance();
        payable(msg.sender).transfer(amount);
        emit FundsWithdraw(msg.sender, amount);
    }

    function getBalance() override public view onlySigner returns(uint256) {
        return _balances[msg.sender];
    }

    /// @notice Getter for contract balance
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

}