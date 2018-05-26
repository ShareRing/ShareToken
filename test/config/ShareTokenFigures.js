const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const DECIMAL_PLACES = 2;
const TOTAL_AIRDROP = 6666666667;
const TOTAL_BOUNTY = 33333333333;
const TOTAL_SED = 5 * Math.pow(10, 8) * Math.pow(10, DECIMAL_PLACES);
const TOTAL_MAINSALE = 1000000000 * 10**DECIMAL_PLACES; 
const LARGER_THAN_TOTAL = 10 * Math.pow(10, 9) * Math.pow(10, DECIMAL_PLACES); // 10 billion with 2 decimal places
const TEST_BALANCE = 3; // already including 2 decimal places
const ETH_USD_RATE = 40000; // 400 USD in cent
const TOKEN_PRICE = 0.02; // 2 cent

module.exports = {
    ZERO_ADDRESS,
    DECIMAL_PLACES,
    TOTAL_MAINSALE,
    TOTAL_AIRDROP,
    TOTAL_BOUNTY,
    TOTAL_SED,
    LARGER_THAN_TOTAL,
    TEST_BALANCE,
    ETH_USD_RATE,
    TOKEN_PRICE,
}


