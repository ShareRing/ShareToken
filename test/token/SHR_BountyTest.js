var assertRevert = require('../helpers/assertRevert.js');
var expectEvent = require('../helpers/expectEvent.js');
var utilities = require('../helpers/utilities.js');
var constants = require('../config/ShareTokenFigures.js');

const ShareToken = artifacts.require('ShareToken');


//*****************************************************************************************
//                          UTILITIES
//*****************************************************************************************
var getBalance = utilities.getBalance
var sellToAccount = utilities.sellToAccount
var transferString = utilities.transferString
var approvalString = utilities.approvalString

var expectTxEvent = expectEvent.inTransaction
var expectLogEvent = expectEvent.inLog

var assertRevert = assertRevert.assertRevert

var bounty = async function(contract, account, tokens){
    return await expectTxEvent(contract.rewardBounty(account, tokens), "Transfer");
}

//*****************************************************************************************
//                         TEST CASES
//*****************************************************************************************

contract('Bounty Testcases', function ([OWNER, NEW_OWNER, RECIPIENT, ANOTHER_ACCOUNT]) {

    console.log("OWNER: ", OWNER);
    console.log("RECIPIENT: ", RECIPIENT);
    console.log("ANOTHER ACCOUNT:", ANOTHER_ACCOUNT);

    beforeEach(async function () {
       this.token = await ShareToken.new();
    });

    //*****************************************************************************************
    //                         BOUNTY TESTCASES
    //*****************************************************************************************

    it('Reward Bounty, account balance should be updated.', async function(){
        await bounty(this.token, ANOTHER_ACCOUNT, constants.TEST_BALANCE);
        const balanceAfter = await getBalance(this.token, ANOTHER_ACCOUNT);
        assert.equal(balanceAfter, constants.TEST_BALANCE);
    })

    it('Reward Bounty, totalSupply shoud reflect', async function(){
        const supplyBefore = await this.token.bountyTokenIssuedTotal();

        await bounty(this.token, ANOTHER_ACCOUNT, constants.TEST_BALANCE);
        const supplyAfter = await this.token.bountyTokenIssuedTotal();

        assert.notEqual(supplyBefore.toNumber(), supplyAfter.toNumber());
    })

    it('After bounty, token should be locked', async function(){
        await bounty(this.token, ANOTHER_ACCOUNT, constants.TEST_BALANCE);

        //tokens should be locked so non-transferable
        await assertRevert(this.token.transfer(NEW_OWNER, constants.TEST_BALANCE,
                                              {from: ANOTHER_ACCOUNT}));
    })

    it('After bounty and unlock tokens, the tokens should be transferable', async function(){
        await bounty(this.token, ANOTHER_ACCOUNT, constants.TEST_BALANCE);

        //unlock
        const tx = await this.token.unlockRewardToken(ANOTHER_ACCOUNT);

        // unlock Mainsale
        const tx1 = await this.token.unlockMainSaleToken();

        await expectTxEvent(this.token.transfer(NEW_OWNER, constants.TEST_BALANCE,
                                        {from: ANOTHER_ACCOUNT}),
                            "Transfer");
    })

    it('Reward bounty a negative number of tokens should revert', async function(){
        await assertRevert(this.token.rewardBounty(ANOTHER_ACCOUNT, -3));

    })

    it('Reward Bounty with an absurdly large amount of tokens should revert', async function(){
        await assertRevert(this.token.rewardBounty(ANOTHER_ACCOUNT, constants.LARGER_THAN_TOTAL));
        // const { logs } = await this.token.rewardBounty(ANOTHER_ACCOUNT,
        //                                                constants.LARGER_THAN_TOTAL);
        // const event = logs.find(e => e.event === "Transfer");
        // assert.equal(event.args._value.toNumber(), constants.TOTAL_BOUNTY);
    })
})


