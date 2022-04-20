// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Wallet.sol";

/**
 * Implementation of mechanism which allow to set access role 'signer' for wallet user
 * @author kchn9
 */
contract SignedWallet is Wallet {

    /**
     * @notice Emited whenever someone becomes signer
     * @param who address of new signer
     */
    event NewSigner(address who);
    
    /// @notice Keep track of users with signer role
    mapping(address => bool) public signers;

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

    function sign() public onlySigner {
    } 

    function execute() public {
    }

    /// @notice Adds new signer
    function _addSigner(address _who) internal {
        signers[_who] = true;
        signersCount++;
        if (requiredSignatures + 1 <= signersCount) {
            requiredSignatures++;
        }
        emit NewSigner(_who);
    }

}