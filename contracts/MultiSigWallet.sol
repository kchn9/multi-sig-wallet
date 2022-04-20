// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/** 
 * @author kchn9
 */
contract MultiSigWallet {

    event FundsDeposit(address who, uint256 amount);
    event FundsWithdraw(address who, uint256 amount);
    event NewOwner(address who);
    
    /// @notice Keep track of users balances
    mapping (address => uint256) private _balances;

    /// @notice Wallet owners - allowed to perform any action with it
    mapping (address => bool) public owners;
    modifier onlyOwner {
        require(owners[msg.sender], "Wallet: [onlyOwner]: caller is not the owner");
        _;
    }

    /// Represents amount of signatures required to   transaction
    uint256 requiredSignatures;

    /// Keep an eye on owner amount
    uint256 ownerAmount;

    /// @notice Set contract creator as first owner
    constructor() {
        owners[msg.sender] = true;
        requiredSignatures = 1;
        ownerAmount = 1;
    }
    
    /**
     * @notice Adds new owner, emits event and increases requiredSignatures by 1 if ownerAmount allows
     * @param _newOwner address of new wallet user
     */
    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Wallet: Address 0 cannot be owner");
        ownerAmount++;
        owners[_newOwner] = true;
        emit NewOwner(_newOwner);
        if (ownerAmount > requiredSignatures) {
            requiredSignatures++;
        }
    }
    
    /// @notice Deposit user funds 
    function deposit() public payable {
        require(msg.value > 0, "Wallet: Value cannot be 0");
        _balances[msg.sender] += msg.value;
        emit FundsDeposit(msg.sender, msg.value);
    }

    /// @notice Fallback - any funds sent directly to contract will be deposited
    receive() external payable {
        deposit();
    }
    
    /// @notice Allow owner to withdraw only their funds
    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= getBalance(), "Wallet: Callers balance is insufficient");
        payable(msg.sender).transfer(_amount);
        emit FundsWithdraw(msg.sender, _amount);
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = getBalance();
        payable(msg.sender).transfer(amount);
        emit FundsWithdraw(msg.sender, amount);
    }

    /// @notice Getter for user balance
    function getBalance() public onlyOwner view returns(uint256) {
        return _balances[msg.sender];
    }

    /// @notice Getter for contract balance
    function getContractBalance() public onlyOwner view returns(uint256) {
        return address(this).balance;
    }

}