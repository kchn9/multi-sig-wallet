// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice RequestFactory implements way to create Request [i.e. adding new signer, sending funds] of any type defined in RequestType.
 * @notice Every Request has data field which stores required data to execute requested action [i.e. address of new signer].
 * @notice Whenever Request is created it emits NewRequest event. All requests are tracked by their ids and stored in _request array.
 * @author kchn9
 */
contract RequestFactory {

    event NewRequest(uint128 idx, uint64 requiredSignatures, bytes data);

    /// @notice Requests are defined here
    enum RequestType { ADD_SIGNER, DELETE_SIGNER }

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
    mapping(uint128 => mapping(address => bool)) isRequestSignedBy;

    /// @notice Keep track of next request id and store all requests
    uint128 public _requestIdx;
    Request[] public _requests;

    /// @notice Check if called id is in _requests[id]
    modifier checkOutOfBounds(uint128 _idx) {
        require(_idx < _requests.length, "RequestFactory: Called request does not exist yet.");
        _;
    }

    /// @notice Allow call only if the signer has not signed the request in advance
    modifier notSignedBy(uint128 _idx) {
        require(!isRequestSignedBy[_idx][msg.sender], "RequestFactory: Called request has been signed by sender already.");
        _;
    }

    /// @notice Allow call only requests not executed before
    modifier notExecuted(uint128 _idx) {
        require(!_requests[_idx].isExecuted, "RequestFactory: Called request has been executed already.");
        _;
    }

    /// @notice Allows calling request execution only if enough signatures are collected.
    modifier onlyFullySigned(uint128 _idx) {
        Request storage r = _requests[_idx];
        require(r.requiredSignatures <= r.currentSignatures, "RequestFactory: Called request is not fully signed yet.");
        _;
    }

    /**
     * @notice Creates ADD_SIGNER request
     * @param _who address of new signer
     * @param _requiredSignatures amount of signatures required to execute request
     */
    function _createAddSignerRequest(
        address _who, 
        uint64 _requiredSignatures
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
        emit NewRequest(_requestIdx, _requiredSignatures, abi.encode(_who));
    }

    function getRequest(
        uint128 _idx
    ) public view returns (
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