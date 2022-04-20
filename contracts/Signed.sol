// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Implementation of mechanism which allow to set access role 'signer' for wallet user
 * @author kchn9
 */
contract Signed {

    /**
     * @notice Emited whenever someone becomes signer
     * @param who address of new signer
     */
    event NewSigner(address who);

    /// @notice Keep track of users with signer role
    mapping(address => bool) public signers;

    uint64 private _addSignerIdx;
    struct AddSignerRequest {
        address who;
        bool isExected;
        uint128 requiredSigns;
        uint64 currentSigns;
        uint64 idx;
    }
    AddSignerRequest[] public addSignerRequests;
    mapping(uint => mapping(address => bool)) hasSigned;

    /// @notice Wallet creator is first signer
    constructor() {
        _addSigner(msg.sender);
    }

    /// @notice Counts signers
    uint256 public signersCount;
    /// @notice Represents how much signatures are needed for action
    uint128 public requiredSignatures;

    modifier onlySigner {
        require(signers[msg.sender], "Signed: Caller is not signer");
        _;
    }

    function requestNewSigner(address _who) public onlySigner {
        AddSignerRequest memory newRequest = AddSignerRequest(_who, false, requiredSignatures, 0, _addSignerIdx);
        _addSignerIdx++;
        addSignerRequests.push(newRequest);
    }

    function sign(uint256 _idx) public onlySigner {
        require(_idx < addSignerRequests.length, "Signed: Called idx parameter does not exist yet.");
        require(!hasSigned[_idx][msg.sender], "Signed: Caller already signed the request.");
        addSignerRequests[_idx].currentSigns++;
    } 

    function execute(uint256 _idx) public {
        require(_idx < addSignerRequests.length, "Signed: Called idx parameter does not exist yet.");
        require(!addSignerRequests[_idx].isExected, "Signed: Called request has been executed already.");
        require(addSignerRequests[_idx].currentSigns == addSignerRequests[_idx].requiredSigns, "Signed: Called request is not signed yet.");
        _addSigner(addSignerRequests[_idx].who);
    }

    /// @notice Adds new signer
    function _addSigner(address _who) internal onlySigner {
        signers[_who] = true;
        signersCount++;
        if (requiredSignatures + 1 <= signersCount) {
            requiredSignatures++;
        }
        emit NewSigner(_who);
    }

}