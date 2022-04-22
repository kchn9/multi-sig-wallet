// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Wallet.sol";

/**
 * @notice Contract that adds potential 'signing' mechanism used for authenticating some calls in future contracts.
 * @author kchn9
 */

contract SignedWallet is Wallet {

    /**
     * @notice Indicates if signer was added/removed
     * @param who new/removed signed address
     */
    event NewSigner(address who); 
    event DeleteSigner(address who);
    
    /// @notice Keep track of users with signer role
    mapping(address => bool) internal _signers;

    /// @notice Check if specified address is signer
    modifier isSigner(address _who) {
        require(!_signers[_who], "SignedWallet: Indicated address to delete is not signer.");
        _;
    }

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

    /// @notice Adds role 'signer' to specified address
    function _addSigner(address _who) internal {
        require(_who != address(0), "SignedWallet: New signer cannot be address 0.");
        _signers[_who] = true;
        _signersCount++;
        if (_requiredSignatures + 1 <= _signersCount) {
            _requiredSignatures++;
        }
        emit NewSigner(_who);
    }

    /// @notice Removes role 'signer' from specified address
    function _removeSigner(address _who) internal onlySigner isSigner(_who) {
        _signers[_who] = false;
        _signersCount--;
        if (_requiredSignatures - 1 <= _signersCount) {
            _requiredSignatures--;
        }
        emit DeleteSigner(_who);
    }

}