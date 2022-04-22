// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Wallet.sol";

/**
 * @notice Contract that adds potential 'signing' mechanism used for authenticating some calls in future contracts.
 * @author kchn9
 */

contract SignedWallet is Wallet {

    /**
     * @notice Emited whenever someone becomes signer
     * @param who address of new signer
     */
    event NewSigner(address who);
    
    /// @notice Keep track of users with signer role
    mapping(address => bool) private _signers;

    /// @notice Access modifier to prevent calls from 'not-signer' user
    modifier onlySigner {
        require(_signers[msg.sender], "SignedWallet: Caller is not signer");
        _;
    }

    /// @notice Wallet creator is first signer
    constructor() {
        _signers[msg.sender] = true;
        _signersCount = 1;
        _requiredSignatures = 1;
    }

    /// @notice Counts signers
    uint internal _signersCount;
    /// @notice Represents how much signatures are needed for action
    uint internal _requiredSignatures;

    /// @notice Adds role 'signer' to wallet user if he has balance
    function _addSigner(address _who) internal {
        require(_who != address(0), "SignedWallet: New signer cannot be address 0.");
        _signers[_who] = true;
        _signersCount++;
        if (_requiredSignatures + 1 <= _signersCount) {
            _requiredSignatures++;
        }
        emit NewSigner(_who);
    }

}