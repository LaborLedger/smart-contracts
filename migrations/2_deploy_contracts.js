module.exports = async function(deployer, network, accounts) {

    console.warn("2_deploy_contract.js called");

    if ( network === "test" ) {
        console.warn("Truffle test suites run - no pre-deployed contracts needed");
        return;
    }

    if (!/^(development|develop|truffle)$/.test(network)) {
        // "main", "ropsten", "kovan" ...
        console.log(`deployment to development network(s) only implemented ("${network}" ordered)`);
        return;
    }

    const Prototype = artifacts.require("Prototype");

    deployer.deploy(Prototype)
    .then(function() {
        console.log("Prototype contract successfully deployed");
        console.log(`..at adreess:        ${Prototype.address}`);
    });

    console.warn("2_deploy_contract.js executed");
};
