// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice RequestFactory implements way to create Request [i.e. adding new signer, sending funds] of any type defined in RequestType.
 * @notice Every Request has data field which stores required data to execute requested action [i.e. address of new signer].
 * @notice Whenever Request is created it emits NewRequest event. All requests are tracked by their ids and stored in _request array.
 * @author kchn9
 */
contract RequestFactory {

    event NewRequest(uint128 indexed idx, uint64 requiredSignatures, RequestType requestType, bytes data);

    /// @notice Requests are defined here
    enum RequestType { ADD_SIGNER, REMOVE_SIGNER, INCREASE_REQ_SIGNATURES, DECREASE_REQ_SIGNATURES, SEND_TRANSACTION }

    /// @notice Request, apart from idx, request type and data stores info about required/current signatures and if it was executed before.
    struct Request {
        uint128 idx;
        uint64 requiredSignatures;
        uint64 currentSignatures;
        RequestType requestType;
        bytes data;
        bool isExecuted;
    }

    /// @notice Checks if address(signer) already signded Request of given id
    mapping(uint128 => mapping(address => bool)) internal isRequestSignedBy;

    /// @notice Keep track of next request id and store all requests
    uint128 internal _requestIdx;
    Request[] internal _requests;

    /// @notice Check if called id is in _requests[id]
    modifier checkOutOfBounds(uint128 _idx) {
        require(_idx < _requests.length, "RequestFactory: Called request does not exist yet.");
        _;
    }

    /// @notice Allow call only requests not executed before
    modifier notExecuted(uint128 _idx) {
        require(!_requests[_idx].isExecuted, "RequestFactory: Called request has been executed already.");
        _;
    }

    /**
     * @notice Creates ADD_SIGNER request
     * @param _who address of new signer
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createAddSignerRequest(
        uint64 _requiredSignatures,
        address _who
    ) internal {
        Request memory addSignerRequest = Request(
            _requestIdx, 
            _requiredSignatures,
            0,
            RequestType.ADD_SIGNER,
            abi.encode(_who),
            false
        );
        _requests.push(addSignerRequest);
        _requestIdx++;
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.ADD_SIGNER, abi.encode(_who));
    }

    /**
     * @notice Creates REMOVE_SIGNER request
     * @param _who address of signer to remove
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createRemoveSignerRequest(
        uint64 _requiredSignatures,
        address _who
    ) internal {
        Request memory removeSignerRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.REMOVE_SIGNER,
            abi.encode(_who),
            false
        );
        _requests.push(removeSignerRequest);
        _requestIdx++;
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.REMOVE_SIGNER, abi.encode(_who));
    }

    /**
     * @notice Creates INCREASE_REQ_SIGNATURES request
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createIncrementReqSignaturesRequest(
        uint64 _requiredSignatures
    ) internal {
        Request memory incrementReqSignaturesRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.INCREASE_REQ_SIGNATURES,
            bytes(""),
            false
        );
        _requests.push(incrementReqSignaturesRequest);
        _requestIdx++;
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.INCREASE_REQ_SIGNATURES, bytes(""));
    }

    /**
     * @notice Creates DECREASE_REQ_SIGNATURES request
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createDecrementReqSignaturesRequest(
        uint64 _requiredSignatures
    ) internal {
        Request memory decrementReqSignaturesRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.DECREASE_REQ_SIGNATURES,
            bytes(""),
            false
        );
        _requests.push(decrementReqSignaturesRequest);
        _requestIdx++;
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.DECREASE_REQ_SIGNATURES, bytes(""));
    }

    function _createSendTransactionRequest(
        uint64 _requiredSignatures,
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        Request memory sendTransactionRequest = Request(
            _requestIdx,
            _requiredSignatures,
            0,
            RequestType.SEND_TRANSACTION,
            abi.encode(_to, _value, _data),
            false
        );
        _requests.push(sendTransactionRequest);
        _requestIdx++;
        emit NewRequest(_requestIdx, _requiredSignatures, RequestType.SEND_TRANSACTION, abi.encodePacked(_to, _value, _data));
    }

    function _getRequest(
        uint128 _idx
    ) internal view returns (
        uint128,
        uint64,
        uint64,
        RequestType,
        bytes memory,
        bool
    ) {
        Request memory r = _requests[_idx];
        return (
            r.idx,
            r.requiredSignatures,
            r.currentSignatures,
            r.requestType,
            r.data,
            r.isExecuted
        );
    }

}