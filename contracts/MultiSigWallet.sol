// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** 
 * @author kchn9
 */
contract MultiSigWallet {
    
    /// @notice Keep track of users balances
    uint256 private _balance;

    /// @notice Wallet owner - allowed to perform any action with it
    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner, "Wallet: [onlyOwner]: caller is not the owner");
        _;
    }

    /// @notice Set contract creator as owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Deposit user funds 
    function deposit() public payable {
        require(msg.value > 0, "Wallet: Value cannot be 0");
        _balance += msg.value;
    }

    /// @notice Fallback - any funds sent directly to contract will be deposited
    receive() external payable {
        deposit();
    }
    
    /// @notice Allow owner withdraw funds
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= getBalance(), "Wallet: Callers balance is insufficient");
        payable(owner).transfer(_amount);
    }
    
    function withdrawAll() external onlyOwner {
        payable(owner).transfer(getBalance());
    }

    function getBalance() public onlyOwner view returns(uint256) {
        return _balance;
    }

}