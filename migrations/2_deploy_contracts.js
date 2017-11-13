var SafeMath = artifacts.require("./math/SafeMath.sol");
var ERC20 = artifacts.require("./token/ERC20.sol");
var ERC20Basic = artifacts.require("./token/ERC20Basic.sol");
var BurnableToken = artifacts.require("./token/BurnableToken.sol");
var BasicToken = artifacts.require("./token/BasicToken.sol");
var StandardToken = artifacts.require("./token/StandardToken.sol");
var Ownable = artifacts.require("./ownership/Ownable.sol");
var Pausable = artifacts.require("./lifecycle/Pausable.sol");
var BloodlineBLCToken = artifacts.require("./BloodlineBLCToken.sol");
//var BloodlineRBCToken = artifacts.require("./BloodlineRBCToken.sol");
var BloodlineBLCSale = artifacts.require("./BloodlineBLCSale.sol");


module.exports = function(deployer, network, accounts) {
    console.log("Accounts: " + accounts);

    deployer.deploy(SafeMath);
    deployer.deploy(Ownable);
    deployer.link(Ownable, Pausable);
    deployer.deploy(Pausable);

    deployer.deploy(BasicToken);
    deployer.link(BasicToken, SafeMath);
    deployer.link(BasicToken, ERC20Basic);

    deployer.deploy(StandardToken);
    deployer.link(StandardToken, BasicToken);

    deployer.deploy(BloodlineBLCToken);
    deployer.link(BloodlineBLCToken, StandardToken);
    deployer.link(BloodlineBLCToken, Ownable);
    deployer.link(BloodlineBLCToken, BurnableToken);
    deployer.link(BloodlineBLCToken, SafeMath);

    // deployer.deploy(BloodlineRBCToken);
    // deployer.link(BloodlineRBCToken, StandardToken);
    // deployer.link(BloodlineRBCToken, Ownable);
    // deployer.link(BloodlineRBCToken, BurnableToken);
    // deployer.link(BloodlineRBCToken, SafeMath);

    var time = new Date().getTime() / 1000;

    var monkey = 1234;

    deployer.deploy(BloodlineBLCToken, accounts[1]).then(function() {
        return deployer.deploy(BloodlineBLCSale, accounts[1], 1000, 2000, 1, time, 10000, 10000, BloodlineBLCToken.address);
    });

};
