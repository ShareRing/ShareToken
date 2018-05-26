pragma solidity ^0.4.21;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ShareToken.sol";


contract MainSale is Ownable {
    
    using SafeMath for uint256;

    ShareToken public shrToken;

    bool public isIcoRunning = false;

    uint256 public tokenPriceInCent = 2; // cent or $0.02
    uint256 public ethUsdRateInCent = 0;// cent

    // Any token amount must be multiplied by this const to reflect decimals
    uint256 constant E2 = 10**2;

    /* Allow whitelisted users to send ETH to token contract for buying tokens */
    function () external payable {
        require (isIcoRunning);
        require (ethUsdRateInCent != 0);

        // Only whitelisted address can buy tokens. Otherwise, refund
        require (shrToken.isWhitelisted(msg.sender));

        // Calculate the amount of tokens based on the received ETH
        uint256 tokens = msg.value.mul(ethUsdRateInCent).mul(E2).div(tokenPriceInCent).div(10**18);

        uint256 totalIssuedTokens = shrToken.totalMainSaleTokenIssued();
        uint256 totalMainSaleLimit = shrToken.totalMainSaleTokenLimit();

        // If the allocated tokens exceed the limit, must refund to user
        if (totalIssuedTokens.add(tokens) > totalMainSaleLimit) {

            uint256 tokensAvailable = totalMainSaleLimit.sub(totalIssuedTokens);
            uint256 tokensToRefund = tokens.sub(tokensAvailable);
            uint256 ethToRefundInWei = tokensToRefund.mul(tokenPriceInCent).mul(10**18).div(E2).div(ethUsdRateInCent);
            
            // Refund
            msg.sender.transfer(ethToRefundInWei);

            // Update actual tokens to be sold
            tokens = tokensAvailable;

            // Stop ICO
            isIcoRunning = false;
        }

        shrToken.sell(msg.sender, tokens);
    }

    function withdrawTo(address _to) public onlyOwner {

        require(_to != address(0));
        _to.transfer(address(this).balance);
    }

    function withdrawToOwner() public onlyOwner {

        withdrawTo(owner);
    }

    function setEthUsdRateInCent(uint256 _ethUsdRateInCent) public onlyOwner {
        
        ethUsdRateInCent = _ethUsdRateInCent; // "_ethUsdRateInCent"
    }

    function setTokenPriceInCent(uint256 _tokenPriceInCent) public onlyOwner {
        
        tokenPriceInCent = _tokenPriceInCent;
    }

    function stopICO() public onlyOwner {

        isIcoRunning = false;
    }

    function startICO(uint256 _ethUsdRateInCent, address _tokenAddress) public onlyOwner {

        require(_ethUsdRateInCent > 0);
        require( _tokenAddress != address(0x0) );

        ethUsdRateInCent = _ethUsdRateInCent;
        shrToken = ShareToken(_tokenAddress);

        isIcoRunning = true;
    }

    function remainingTokensForSale() public view returns (uint256) {
        
        uint256 totalMainSaleLimit = shrToken.totalMainSaleTokenLimit();
        return totalMainSaleLimit.sub(shrToken.totalMainSaleTokenIssued());
    }
}
