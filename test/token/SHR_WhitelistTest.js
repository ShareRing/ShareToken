var assertRevert = require('../helpers/assertRevert.js');
var expectEvent = require('../helpers/expectEvent.js');
var utilities = require('../helpers/utilities.js');
var constants = require('../config/ShareTokenFigures.js');

const Whitelist = artifacts.require('ShareToken');


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

//*****************************************************************************************
//                         TEST CASES 
//*****************************************************************************************

contract('Whitelist Testcases', function ([OWNER, NEW_OWNER, RECIPIENT, ANOTHER_ACCOUNT]) {
    var accounts = [OWNER, NEW_OWNER, RECIPIENT, ANOTHER_ACCOUNT];
    console.log("OWNER: ", OWNER);
    console.log("NEW OWNER: ", NEW_OWNER);
    console.log("RECIPIENT: ", RECIPIENT);
    console.log("ANOTHER ACCOUNT:", ANOTHER_ACCOUNT);

    var testAccounts = [NEW_OWNER, ANOTHER_ACCOUNT];

    beforeEach(async function () {
       this.whitelist = await Whitelist.new();

    });

    it('set must be called by owner only', async function(){
        await assertRevert(this.whitelist.set(NEW_OWNER, {from: ANOTHER_ACCOUNT}));
    })

    it('unset must be called by owner only', async function(){
        await assertRevert(this.whitelist.unset(NEW_OWNER, {from: ANOTHER_ACCOUNT}));
    })

    it('set many must be called by owner only', async function(){
        await assertRevert(this.whitelist.setMany(testAccounts, {from: ANOTHER_ACCOUNT}));
    })

    it('unset many must be called by owner only', async function(){
        await assertRevert(this.whitelist.unsetMany(testAccounts, {from: ANOTHER_ACCOUNT}))
    })

    it('set single address and check', async function(){
        await this.whitelist.set(NEW_OWNER);
        const res = await this.whitelist.isWhitelisted.call(NEW_OWNER);
        assert.equal(res, true);
    })

    it('unset single address and check', async function(){
        await this.whitelist.set(NEW_OWNER);
        const res = await this.whitelist.isWhitelisted.call(NEW_OWNER);
        assert.equal(res, true);

        await this.whitelist.unset(NEW_OWNER);
        const res1 = await this.whitelist.isWhitelisted.call(NEW_OWNER);
        assert.equal(res1, false);
    })

    it('set many addresses and check', async function(){
        await this.whitelist.setMany(testAccounts);

        for(var i=0; i < testAccounts.length; i++){
            const res = await this.whitelist.isWhitelisted.call(testAccounts[i]);
            assert.equal(res, true);
        }
    })

    it('unset many address and check', async function() {
        await this.whitelist.setMany(testAccounts);
        for(var i=0; i < testAccounts.length; i++){
            const res = await this.whitelist.isWhitelisted.call(testAccounts[i]);
            assert.equal(res, true);
        }

        await this.whitelist.unsetMany(testAccounts);
        for(var i=0; i < testAccounts.length; i++){
            const res = await this.whitelist.isWhitelisted.call(testAccounts[i]);
            assert.equal(res, false);
        }
    })
    
});
