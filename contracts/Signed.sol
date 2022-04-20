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

    mapping(address => bool) public signers;

    /// @notice Wallet creator is first signer
    constructor() {
        signers[msg.sender] = true;
        signersCount = 1;
    }

    /// @notice Counts signers
    uint256 public signersCount;
    /// @notice Represents how much signatures are needed for action
    uint256 public requiredSignatures;

    modifier onlySigner {
        require(signers[msg.sender], "Signed: Caller is not signer");
        _;
    }

    /// @notice Adds new signer
    function addSigner(address _who) public onlySigner {
        require(_who != address(0), "Signed: New signer cannot be 0 address.");
        signers[_who] = true;
        if (requiredSignatures + 1 <= signersCount) {
            requiredSignatures++;
        }
        emit NewSigner(_who);
    }

}