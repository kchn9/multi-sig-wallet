// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SignedWallet } from "./SignedWallet.sol";
import { RequestFactory } from "./RequestFactory.sol";

/** 
 * @author kchn9
 */
contract MultiSigWallet is SignedWallet, RequestFactory {

    function execute(uint128 _idx) external notExecuted(_idx) onlyFullySigned(_idx) {
        (/*idx*/,
        /*requiredSignatures*/,
        /*currentSignatures*/,
        RequestFactory.RequestType requestType, bytes memory data, /*isExecuted*/) = getRequest(_idx);
        if (requestType == RequestFactory.RequestType.ADD_SIGNER) {
            address newSignerAddress = abi.decode(data, (address));
            _addSigner(newSignerAddress);
            _requests[_idx].isExecuted = true;
        }
    }

    function sign(uint128 _idx) external onlySigner notSignedBy(_idx) notExecuted(_idx) {
        RequestFactory.Request storage requestToSign = _requests[_idx];
        isRequestSignedBy[_idx][msg.sender] = true;
        requestToSign.currentSignatures++;
    }

    function addSigner(address _who) external onlySigner hasBalance(_who) {
        _createAddSignerRequest(_who, uint64(_requiredSignatures));
    }

    /// @notice Getter for contract balance
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function deposit() public override payable {
        require(msg.value > 0, "MultiSigWallet: Value cannot be 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposit(msg.sender, msg.value);
    }

    receive() external override payable {
        deposit();
    }
    
    function withdraw(uint256 _amount) external override hasBalance(msg.sender) {
        require(_amount <= getBalance(), "MultiSigWallet: Callers balance is insufficient");
        _balances[msg.sender] -= _amount;
        emit FundsWithdraw(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
    }

    function withdrawAll() external override hasBalance(msg.sender) {
        uint256 amount = getBalance();
        _balances[msg.sender] = 0;
        emit FundsWithdraw(msg.sender, amount);
        payable(msg.sender).transfer(amount);
    }

    function getBalance() public override view returns(uint256) {
        return _balances[msg.sender];
    }

}