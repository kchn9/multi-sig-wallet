const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");
const BN = require("bn.js");
const chai = require("chai");
const should = chai.should();
chai.use(require('chai-bn')(BN));

const MultiSigWallet = artifacts.require("./MultiSigWallet.sol");

contract("MultiSigWallet", async function(accounts) {
    // A and B accounts for testing purposes
    // alice = owner
    const [alice, bob, ...rest] = accounts;

    beforeEach("should prepare new contract instance", async function() {
        this.instance = await MultiSigWallet.new({ from: alice, nonce: await web3.eth.getTransactionCount(alice) });
    })

    it("should allow user to deposit 1 ether by [1] deposit()", async function() {
        const expectedBalance = new BN(web3.utils.toWei("1"));

        await this.instance.deposit({
            from: alice,
            value: expectedBalance
        })

        const result = await this.instance.getBalance({ from: alice });

        result.should.be.a.bignumber.that.equals(expectedBalance);
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

        expectEvent(
            await this.instance.withdraw(amount, { from: alice }),
            "FundsWithdraw",
            {
                who: alice,
                amount: web3.utils.toWei("1")
            }
        )
    })
 
    it("should allow owner to withdrawAll() funds", async function() {
        // deposit setup
        const amount = new BN(web3.utils.toWei("1"));
        await this.instance.deposit({
            from: alice,
            value: amount
        })

        expectEvent(
            await this.instance.withdraw(amount, { from: alice }),
            "FundsWithdraw",
            {
                who: alice,
                amount: web3.utils.toWei("1")
            }
        )
    })

    it("should create ADD_SIGNER request", async function() {
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") }); // add signer requirement

        expectEvent(
            await this.instance.addSigner(bob, { from: alice }),
            "NewRequest",
            {
                requestType: new BN(0)
            }
        )
    })

    it("should allow signer to sign request", async function() {
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") }); // add signer requirement
        await this.instance.addSigner(bob, { from: alice }); // sign requirement
        
        const expectedId = 0;
        
        expectEvent(
            await this.instance.sign(expectedId, { from: alice }),
            "RequestSigned",
            {
                id: new BN(expectedId)
            }
        );
    })

    it("should allow anybody to execute signed request", async function() {
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") }); // add signer requirement
        await this.instance.addSigner(bob, { from: alice }); // sign requirement

        const expectedId = 0;
    
        await this.instance.sign(expectedId, { from: alice }); // execute requirement

        expectEvent(
            await this.instance.execute(expectedId, { from: bob }),
            "RequestExecuted",
            {
                id: new BN(expectedId)
            }
        )
    })

    it("should create REMOVE_SIGNER request", async function() {
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") }); // add signer requirement
        await this.instance.addSigner(bob, { from: alice }); // sign requirement
        await this.instance.sign(0, { from: alice }); // execute requirement
        await this.instance.execute(0, { from: alice }); // execute new signer request

        expectEvent(
            await this.instance.removeSigner(bob, { from: alice }),
            "NewRequest",
            {
                requestType: new BN(1)
            }
        )
    })

    it("should create INCREASE_REQ_SIGNATURES request", async function() {
        // add two signers
        for (let id = 0; id < 2; id++) {
            await this.instance.deposit({ from: rest[id], value: web3.utils.toWei("1") });
            await this.instance.addSigner(rest[id], { from: alice });
            await this.instance.sign(id, { from: alice });
            await this.instance.execute(id, { from: alice });
        } 
        // required signatures = 1, signers count = 3, next request id = 2

        expectEvent(
            await this.instance.increaseRequiredSignatures({ from: alice }),
            "NewRequest",
            {
                requestType: new BN(2)
            }
        )
    })

    it("should create DECREASE_REQ_SIGNATURES request", async function() {
        // add signer
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") });
        await this.instance.addSigner(bob, { from: alice });
        await this.instance.sign(0, { from: alice });
        await this.instance.execute(0, { from: alice });

        //increment require statements 
        await this.instance.increaseRequiredSignatures({ from: bob });
        await this.instance.sign(1, { from: alice });
        await this.instance.execute(1, { from: alice });
        // requiredSignatures = 2

        expectEvent(
            await this.instance.decreaseRequiredSignatures({ from: alice }),
            "NewRequest",
            {
                requestType: new BN(3)
            }
        )
    })

    it("should create SEND_TRANSACTION request", async function() {
        expectEvent(
            await this.instance.sendTx(bob, 1_000_000_000_000_000, "0x", { from: alice }),
            "NewRequest",
            {
                requestType: new BN(4)
            }
        )
    })
    
    it("should send transaction", async function() {
        const expectedValue = web3.utils.toWei("1");
        // add 5 eth to contract balance
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("5") }); 
        await this.instance.sendTx(bob, expectedValue, "0x", { from: alice });
        await this.instance.sign(0, { from: alice });
        expectEvent(
            await this.instance.execute(0, { from: alice }),
            "TransactionSent",
            {
                to: bob,
                value: expectedValue
            }
        )
    })

    it("should add new signer", async function() {
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") });
        await this.instance.addSigner(bob, { from: alice });
        await this.instance.sign(0, { from: alice });
        
        expectEvent(
            await this.instance.execute(0, { from: alice }),
            "NewSigner",
            {
                who: bob
            }
        );
    })

    it("should remove signer", async function() {
        // add signer
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") });
        await this.instance.addSigner(bob, { from: alice });
        await this.instance.sign(0, { from: alice });
        await this.instance.execute(0, { from: alice });

        //remove signer
        await this.instance.removeSigner(bob, { from: alice });
        await this.instance.sign(1, { from: alice });
        expectEvent(
            await this.instance.execute(1, { from: alice }),
            "DeleteSigner",
            {
                who: bob
            }
        )
    })

    it("should increment required signatures", async function() {
        // add signer and create request
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") });
        await this.instance.addSigner(bob, { from: alice });
        await this.instance.sign(0, { from: alice });
        await this.instance.execute(0, { from: alice });
        await this.instance.increaseRequiredSignatures({ from: bob });
        await this.instance.sign(1, { from: alice });
        
        expectEvent(
            await this.instance.execute(1, { from: bob }),
            "RequiredSignaturesIncreased",
            {
                oldVal: new BN(1),
                newVal: new BN(2)
            }
        )
        
    })

    it("should reduce required signatures", async function() {
        // add signer, increment required signatures and create request
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") });
        await this.instance.addSigner(bob, { from: alice });
        for (let id = 0; id < 3; id++) {
            await this.instance.sign(id, { from: alice });
            if (id == 2) await this.instance.sign(2, { from: bob }); 
            if (id < 2)  await this.instance.execute(id, { from: alice });
            if (id == 0) await this.instance.increaseRequiredSignatures({ from: bob });
            if (id == 1) await this.instance.decreaseRequiredSignatures({ from: bob });
        }
        
        expectEvent(
            await this.instance.execute(2, { from: bob }),
            "RequiredSignaturesDecreased",
            {
                oldVal: new BN(2),
                newVal: new BN(1)
            }
        )
    })

    it("should revoke request transaction", async function() {
        
    })

    it("should reject INCREASE_REQ_SIGNATURES request creation to prevent exceeding requiredSignatures over signerCount", async function() {
        await expectRevert(
            this.instance.increaseRequiredSignatures({ from: alice }),
            "MultiSigWallet: Required signatures cannot exceed signers count"
        )
    })

    it("should reject DECREASE_REQ_SIGNATURES request creation to avoid requiredSignatures = 0", async function() {
        await expectRevert(
            this.instance.decreaseRequiredSignatures({ from: alice }),
            "MultiSigWallet: Required signatures cannot be 0."
        )
    })

    it("should reject unsigned request execution", async function() {
        await this.instance.deposit({ from: bob, value: web3.utils.toWei("1") }); // add signer requirement
        await this.instance.addSigner(bob, { from: alice });

        await expectRevert(
            this.instance.execute(0, { from: alice }),
            "MultiSigWallet: Called request is not fully signed yet."
        )
    })

    it("should reject create request action from 'non-signer' account", async function() {
        await expectRevert(
            this.instance.addSigner(rest[0], { from: bob }),
            "SignedWallet: Caller is not signer"
        )
    })

    it("should reject withdraw() for not owner account", async function() {
        const amount = new BN(web3.utils.toWei("1"));
        await expectRevert(
            this.instance.withdraw(amount, { from: bob }),
            "MultiSigWallet: Callers balance is insufficient"
        )
    })

    it("should reject withdrawAll() for not owner account", async function() {
        await expectRevert(
            this.instance.withdrawAll({ from: bob }),
            "Wallet: Specified address has no balance"
        )
    })

})