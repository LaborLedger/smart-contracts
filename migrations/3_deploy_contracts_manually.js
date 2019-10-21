module.exports = async function(deployer, network, accounts) {

    // exit silently if not in 'manual tests mode'
    if (!process.env._PROTOTYPE_MANUAL) return;

    console.warn("3_deploy_contracts_manually.js called");

    if (!/^(development)$/.test(network)) {
        console.log(`deployment to development network only implemented ("${network}" ordered)`);
        return;
    }

    const Prototype = artifacts.require("LaborLedgerImplementation");

    // [terms, startWeek, equity, memberWeights]
    deployer.deploy(
        Prototype,
        web3.utils.fromAscii( process.env._PROTOTYPE_TERMS || ''),
        Number.parseInt(process.env._PROTOTYPE_STARTWEEK || '0'),
    ).then(function() {
        console.log("LaborLedger contract successfully deployed");
        console.log(`..at adreess:        ${Prototype.address}`);
    });

    console.warn("ethereum/migrations/3_deploy_contracts_manually.js executed");
};
