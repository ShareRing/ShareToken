var ShareToken = artifacts.require("./ShareToken.sol");
var MainSale = artifacts.require("./MainSale.sol");

module.exports = function(deployer) {
    deployer.deploy(ShareToken).then(function(){
      return deployer.deploy(MainSale);
    });
};
