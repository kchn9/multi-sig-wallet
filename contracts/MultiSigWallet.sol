// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SignedWallet } from "./SignedWallet.sol";
import { RequestFactory } from "./RequestFactory.sol";

/** 
 * @title Ethereum multi user wallet implementation.
 * @notice Wallet uses 'signer' role from SignedWallet to prevent calling vital methods.
 * @notice Every wallet action is represented by Request from RequestFactory.
 * @notice To 'run' any of request action (i.e sending transaction) required signatures must be collected from signers.
 * @notice If such requirement is satisfied anyone may execute that request.
 * @author kchn9
 */
contract MultiSigWallet is SignedWallet, RequestFactory {

    /// @notice Request state tracking events, emitted whenever Request of id is signed, signature is revoked or request is executed
    event RequestSigned(uint128 indexed id, address who);
    event RequestSignatureRevoked(uint128 indexed id, address who);
    event RequestExecuted(uint128 indexed id, address by);

    /// @notice Tracker of sent transaction, emitted when SEND_TRANSACTION request is executed
    event TransactionSent(address to, uint256 value, bytes txData);

    /// @notice Runs execution of Request with specified request _idx
    function execute(uint128 _idx) external checkOutOfBounds(_idx) notExecuted(_idx) {
        require(_requests[_idx].requiredSignatures <= _requests[_idx].currentSignatures, 
            "MultiSigWallet: Called request is not fully signed yet.");
        (/*idx*/,
        /*requiredSignatures*/,
        /*currentSignatures*/,
        RequestType requestType,
        bytes memory data,
        /*isExecuted*/) = _getRequest(_idx);
        if (requestType == RequestType.ADD_SIGNER || requestType == RequestType.REMOVE_SIGNER) {
            address who = abi.decode(data, (address));
            if (requestType == RequestType.ADD_SIGNER) {
                _addSigner(who);
            }
            if (requestType == RequestType.REMOVE_SIGNER) {
                _removeSigner(who);
            }
            emit RequestExecuted(_idx, msg.sender);
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.INCREASE_REQ_SIGNATURES) {
            _increaseRequiredSignatures();
            emit RequestExecuted(_idx, msg.sender);
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.DECREASE_REQ_SIGNATURES) {
            _decreaseRequiredSignatures();
            emit RequestExecuted(_idx, msg.sender);
            _requests[_idx].isExecuted = true;
        }
        else if (requestType == RequestType.SEND_TRANSACTION){
            (address to, uint256 value, bytes memory txData) = abi.decode(data, (address, uint256, bytes));
            (bool success, /*data*/) = to.call{ value: value }(txData);
            _requests[_idx].isExecuted = true;
            emit TransactionSent(to, value, txData);
            emit RequestExecuted(_idx, msg.sender);
            require(success, "MultiSigWallet: Ether transfer failed");
        }
        else {
            revert("MultiSigWallet: Specified request type does not exist.");
        }
    }

    /// @notice On-chain mechanism of signing contract of specified _idx
    function sign(uint128 _idx) external checkOutOfBounds(_idx) notExecuted(_idx) onlySigner {
        require(!isRequestSignedBy[_idx][msg.sender], "MultiSigWallet: Called request has been signed by sender already.");
        RequestFactory.Request storage requestToSign = _requests[_idx];
        isRequestSignedBy[_idx][msg.sender] = true;
        requestToSign.currentSignatures++;
        emit RequestSigned(_idx, msg.sender);
    }

    /// @notice Revokes the signature provided under the request
    function revokeSignature(uint128 _idx) external checkOutOfBounds(_idx) notExecuted(_idx) onlySigner {
        require(isRequestSignedBy[_idx][msg.sender], "MultiSigWallet: Caller has not signed request yet.");
        RequestFactory.Request storage requestToRevokeSignature = _requests[_idx];
        isRequestSignedBy[_idx][msg.sender] = false;
        requestToRevokeSignature.currentSignatures--;
        emit RequestSignatureRevoked(_idx, msg.sender);
    }

    /// @notice Wrapped call of internal _createAddSignerRequest from RequestFactory
    /// @param _who address of new signer
    function addSigner(address _who) external onlySigner hasBalance(_who) {
        _createAddSignerRequest(uint64(_requiredSignatures), _who);
    }

    /// @notice Wrapped call of internal _createRemoveSignerRequest from RequestFactory
    /// @param _who address of signer to remove
    function removeSigner(address _who) external onlySigner {
        require(_signers[_who], "MultiSigWallet: Indicated address to delete is not signer.");
        _createRemoveSignerRequest(uint64(_requiredSignatures), _who); 
    }

    /// @notice Wrapped call of internal _createIncrementReqSignaturesRequest from RequestFactory
    function increaseRequiredSignatures() external onlySigner {
        require(_requiredSignatures + 1 <= _signersCount, "MultiSigWallet: Required signatures cannot exceed signers count");
        _createIncrementReqSignaturesRequest(uint64(_requiredSignatures));
    }

    /// @notice Wrapped call of internal _createDecrementReqSignaturesRequest from RequestFactory
    function decreaseRequiredSignatures() external onlySigner {
        require(_requiredSignatures - 1 > 0, "MultiSigWallet: Required signatures cannot be 0.");
        _createDecrementReqSignaturesRequest(uint64(_requiredSignatures));
    }

    /** 
     * @notice Wrapped call of internal _createSendTransactionRequest from RequestFactory
     * @param _to address receiving transaction
     * @param _value ETH value to send
     * @param _data transaction data
     */
    function sendTx(
        address _to, 
        uint256 _value, 
        bytes memory _data
    ) external onlySigner {
        require(_to != address(0), "MultiSigWallet: Cannot send transaction to address 0.");
        _createSendTransactionRequest(uint64(_requiredSignatures), _to, _value, _data);
    }

    /// @notice Getter for contract balance
    function getContractBalance() hasBalance(msg.sender) public view returns(uint256) {
        return address(this).balance;
    }

    /// @notice WALLET OVERRIDDEN FUNCTIONS (PROVIDING STANDARD WALLET FUNCTIONALITY)
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

}