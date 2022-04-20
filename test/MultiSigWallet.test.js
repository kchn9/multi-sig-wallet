const { balance, expectRevert } = require("@openzeppelin/test-helpers");
const BN = require("bn.js");
const chai = require("chai");
const { expect } = chai;
const should = chai.should();
chai.use(require('chai-bn')(BN));

const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");

contract("MultiSigWallet", async function(accounts) {
    // A and B accounts for testing purposes
    // alice = owner
    const [alice, bob, ...rest] = accounts;

    beforeEach("should prepare new contract instance", async function() {
        this.instance = await MultiSigWallet.new({ from: alice });
    })

    it("should set contract creator as owner", async function() {
        expect(await this.instance.owner()).to.equal(alice);
    })

    it("should allow user to deposit 1 ether by [1] deposit()", async function() {
        const expectedBalance = new BN(web3.utils.toWei('1', 'ether'));

        await this.instance.deposit({
            from: alice,
            value: expectedBalance
        })
        const result = await this.instance.getBalance({ from: alice });

        (result).should.be.bignumber.equal(expectedBalance);
    })

    
    it("should allow user to deposit 1 ether by [2] receive()", async function() {
        const expectedBalance = new BN(web3.utils.toWei("1"));

        await this.instance.send(expectedBalance, { 
            from: alice,
        })
        const result = await this.instance.getBalance({ from: alice });

        result.should.be.a.bignumber.that.equals(expectedBalance);
    })

    it("should allow owner to withdraw() funds", async function() {
        // deposit setup
        const amount = new BN(web3.utils.toWei("1"));
        await this.instance.deposit({
            from: alice,
            value: amount
        })

        // measure balance delta (omitting fees)
        const tracker = await balance.tracker(alice);
        await tracker.get();
        // withdraw
        await this.instance.withdraw(amount, { from: alice });
        const result = await tracker.delta();

        // estimated spent gas since tests started - not accurate
        const estimatedGasSpent = new BN(web3.utils.toWei("100", "szabo"));
        const threshold = (new BN(web3.utils.toWei("1"))).sub(estimatedGasSpent);

        result.should.be.a.bignumber.that.is.above(threshold);
    })
 
    it("should allow owner to withdrawAll() funds", async function() {
        // deposit setup
        const amount = new BN(web3.utils.toWei("1"));
        await this.instance.deposit({
            from: alice,
            value: amount
        })

        // measure balance delta (omitting fees)
        const tracker = await balance.tracker(alice);
        await tracker.get();
        // withdraw
        await this.instance.withdrawAll({ from: alice });
        const result = await tracker.delta();

        // estimated spent gas since tests started - not accurate
        const estimatedGasSpent = new BN(web3.utils.toWei("100", "szabo"));
        const threshold = (new BN(web3.utils.toWei("1"))).sub(estimatedGasSpent);

        result.should.be.a.bignumber.that.is.above(threshold);
    })

    it("should reject withdraw() for not owner account", async function() {
        const amount = new BN(web3.utils.toWei("1"));
        expectRevert(
            this.instance.withdraw(amount, { from: bob }),
            "Wallet: [onlyOwner]: caller is not the owner"
        )
    })

    it("should reject withdrawAll() for not owner account", async function() {
        expectRevert(
            this.instance.withdrawAll({ from: bob }),
            "Wallet: [onlyOwner]: caller is not the owner"
        )
    })

})