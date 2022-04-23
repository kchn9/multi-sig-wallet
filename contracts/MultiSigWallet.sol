// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SignedWallet } from "./SignedWallet.sol";
import { RequestFactory } from "./RequestFactory.sol";

/** 
 * @author kchn9
 */
contract MultiSigWallet is SignedWallet, RequestFactory {

    function execute(uint128 _idx) external checkOutOfBounds(_idx) notExecuted(_idx) {
                        // todo emitEvents
        require(_requests[_idx].requiredSignatures <= _requests[_idx].currentSignatures, 
            "MultiSigWallet: Called request is not fully signed yet.");
        (/*idx*/,
        /*requiredSignatures*/,
        /*currentSignatures*/,
        RequestType requestType, bytes memory data, /*isExecuted*/) = _getRequest(_idx);
        if (requestType == RequestType.ADD_SIGNER || requestType == RequestType.REMOVE_SIGNER) {
            address who = abi.decode(data, (address));
            if (requestType == RequestType.ADD_SIGNER) {
                _addSigner(who);
            }
            if (requestType == RequestType.REMOVE_SIGNER) {
                _removeSigner(who);
            }
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.INCREASE_REQ_SIGNATURES) {
            _increaseRequiredSignatures();
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.DECREASE_REQ_SIGNATURES) {
            _decreaseRequiredSignatures();
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.SEND_TRANSACTION){
            (address to, uint256 value, bytes memory txData) = abi.decode(data, (address, uint256, bytes));
            (bool success, /*data*/) = to.call{ value: value }(txData);
            _requests[_idx].isExecuted = true;
            require(success, "MultiSigWallet: Ether transfer failed");
        }
        else {
            revert("MultiSigWallet: Specified request type does not exist.");
        }
    }

    function sign(uint128 _idx) external checkOutOfBounds(_idx) notExecuted(_idx) onlySigner {
        require(!isRequestSignedBy[_idx][msg.sender], "MultiSigWallet: Called request has been signed by sender already.");
        RequestFactory.Request storage requestToSign = _requests[_idx];
        isRequestSignedBy[_idx][msg.sender] = true;
        requestToSign.currentSignatures++;
    }

    function addSigner(address _who) external onlySigner hasBalance(_who) {
        _createAddSignerRequest(uint64(_requiredSignatures), _who);
    }

    function removeSigner(address _who) external onlySigner {
        require(!_signers[_who], "MultiSigWallet: Indicated address to delete is not signer.");
        _createRemoveSignerRequest(uint64(_requiredSignatures), _who); 
    }

    function increaseRequiredSignatures() external onlySigner {
        require(_requiredSignatures + 1 <= _signersCount, "MultiSigWallet: Required signatures cannot exceed signers count");
        _createIncrementReqSignaturesRequest(uint64(_requiredSignatures));
    }

    function decreaseRequiredSignatures() external onlySigner {
        require(_requiredSignatures - 1 > 0, "MultiSigWallet: Required signatures cannot be 0.");
        _createDecrementReqSignaturesRequest(uint64(_requiredSignatures));
    }

    function sendTransaction(
        address _to, 
        uint256 _value, 
        bytes memory _data
    ) external onlySigner {
        require(_to != address(0), "MultiSigWallet: Cannot send transaction to address 0.");
        _createSendTransactionRequest(uint64(_requiredSignatures), _to, _value, _data);
    }

    function deposit() public override payable {
        require(msg.value > 0, "MultiSigWallet: Value cannot be 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposit(msg.sender, msg.value);
    }

    receive() external override payable {
        deposit();
    }
    
    function withdraw(uint256 _amount) external override {
        require(_amount <= getBalance(), "MultiSigWallet: Callers balance is insufficient");
        _balances[msg.sender] -= _amount;
        emit FundsWithdraw(msg.sender, _amount);
        (bool success, /*data*/) = address(msg.sender).call{ value: _amount}("");
        require(success, "MultiSigWallet: Ether transfer failed");
    }

    function withdrawAll() external override hasBalance(msg.sender) {
        uint256 amount = getBalance();
        _balances[msg.sender] = 0;
        emit FundsWithdraw(msg.sender, amount);
        (bool success, /*data*/) = address(msg.sender).call{ value: amount}("");
        require(success, "MultiSigWallet: Ether transfer failed");
    }

    function getBalance() public override view returns(uint256) {
        return _balances[msg.sender];
    }

    /// @notice Getter for contract balance
    function getContractBalance() hasBalance(msg.sender) public view returns(uint256) {
        return address(this).balance;
    }

}