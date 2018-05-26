var ShareToken = artifacts.require('./ShareToken.sol');

contract('ShareToken', function(accounts){
    it('ShareToken', function(){
        return ShareToken.deployed().then(function(result){
            console.log("ShareToken:", result.address);
            return result.totalSupply();
        }).then(function(res){
            console.log("res:", res);
        })
    })
})
