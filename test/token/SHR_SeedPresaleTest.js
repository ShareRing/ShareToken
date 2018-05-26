var assertRevert = require('../helpers/assertRevert.js');
var expectEvent = require('../helpers/expectEvent.js');
var utilities = require('../helpers/utilities.js');
var constants = require('../config/ShareTokenFigures.js');

const ShareToken = artifacts.require('ShareToken');
const Whitelist = artifacts.require('WhiteListManager');


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

var seedSingular = async function(contract, account, tokens){
    return await expectTxEvent(contract.handlePresaleToken(account, tokens), "Transfer");
}
var seedPlural = async function(contract, accounts, tokens) {
    return await expectTxEvent(contract.handlePresaleTokenMany(accounts, tokens), "Transfer");
}

var presaleSingular = async function(contract, account, tokens){
    return await expectTxEvent(contract.handlePresaleToken(account, tokens), "Transfer")
}

var presalePlural = async function(contract, accounts, tokens){
    return await expectTxEvent(contract.handlePresaleTokenMany(accounts, tokens), "Transfer")
}

//*****************************************************************************************
//                         TEST CASES
//*****************************************************************************************

contract('Seed and Presale Testcases', function ([OWNER, NEW_OWNER, RECIPIENT, ANOTHER_ACCOUNT, ANOTHER_ACCOUNT2]) {
    console.log("OWNER: ", OWNER);
    console.log("RECIPIENT: ", RECIPIENT);
    console.log("ANOTHER ACCOUNT 1:", ANOTHER_ACCOUNT);
    console.log("ANOTHER ACCOUNT 2:", ANOTHER_ACCOUNT2);

    ACCOUNTS = [ANOTHER_ACCOUNT, ANOTHER_ACCOUNT2];
    TOKENS = [constants.TEST_BALANCE, constants.TEST_BALANCE];

    beforeEach(async function () {
        // this.whitelist = await Whitelist.new();
       this.token = await ShareToken.new();
    });

    
    //*****************************************************************************************
    //                         PRESALE TESTCASES
    //*****************************************************************************************

    it('Transfer presale, account balance should be updated.', async function(){
        await presaleSingular(this.token, ANOTHER_ACCOUNT, constants.TEST_BALANCE);
        const balanceAfter = await getBalance(this.token, ANOTHER_ACCOUNT);

        // handlePresaleToken multiply token with 100 
        assert.equal(balanceAfter, constants.TEST_BALANCE * 10**constants.DECIMAL_PLACES);
    })

    it('Transfer presale, totalSupply shoud reflect', async function(){
        const supplyBefore = await this.token.seedAndPresaleTokenIssuedTotal();

        await presaleSingular(this.token, ANOTHER_ACCOUNT, constants.TEST_BALANCE);
        const supplyAfter = await this.token.seedAndPresaleTokenIssuedTotal();

        assert.notEqual(supplyBefore.toNumber(), supplyAfter.toNumber());
    })

    it('After presale, token should NOT be locked', async function(){
        await presaleSingular(this.token, ANOTHER_ACCOUNT, constants.TEST_BALANCE);

        // unlock mainsale
        await this.token.unlockMainSaleToken();

        await expectTxEvent(this.token.transfer(NEW_OWNER, constants.TEST_BALANCE,
                                        {from: ANOTHER_ACCOUNT}),
                            "Transfer");
    })

    it('Presale a negative number of tokens should revert', async function(){
        await assertRevert(this.token.handlePresaleToken(ANOTHER_ACCOUNT, -1 * constants.TEST_BALANCE));
    })


    it('Presale with an absurdly large amount of tokens should revert', async function(){
        await assertRevert(this.token.handlePresaleToken(ANOTHER_ACCOUNT, constants.LARGER_THAN_TOTAL));

    })

    it('Plural seed with unequal input arrays', async function(){
        const accounts = [ANOTHER_ACCOUNT, ANOTHER_ACCOUNT2, NEW_OWNER];
        await assertRevert(this.token.handlePresaleTokenMany(accounts, TOKENS));
    })

    it('Plural seed with correct input arrays', async function(){
        await this.token.handlePresaleTokenMany(ACCOUNTS, TOKENS);
        for (var i=0; i < ACCOUNTS.length; i++){
            const balanceAfter = await getBalance(this.token, ACCOUNTS[i])
            assert.equal(balanceAfter, TOKENS[i] * 10**constants.DECIMAL_PLACES );
        }
    })
})


