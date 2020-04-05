/* global artefacts, before, contract, it, web3 */

const {advanceBlock, advanceTimeAndBlock} = require('../scripts/truffle-test-helper')(web3);

const CollaborationProxy = artifacts.require("CollaborationProxy");
const CollaborationImpl = artifacts.require("CollaborationImpl");
const LaborLedgerImpl = artifacts.require("LaborLedgerImpl");
const OzProxyAdmin = artifacts.require("OzProxyAdmin");

contract("single-project base e2e test", async accounts => {
    let [deployer, member1, member2, member3, user4, quorum, inviter, lead, arbiter, operator] = accounts;
    let defaultOpts = {from: deployer, gas: 5000000};

    let proxyAdmin, collabProxy, collabImpl, collab, ledgerImpl, ledger;

    before(async () =>{
        while ((await web3.eth.getBlockNumber()) < 2) {
            await advanceBlock();
        }
    });

    before(async () => {
        proxyAdmin = await OzProxyAdmin.new(defaultOpts);
        assert(web3.utils.isAddress(proxyAdmin.address), 'OzProxyAdmin deployment failed');

        collabImpl = await CollaborationImpl.new(defaultOpts);
        assert(web3.utils.isAddress(collabImpl.address), 'CollaborationImpl deployment failed');

        ledgerImpl = await LaborLedgerImpl.new(defaultOpts);
        assert(web3.utils.isAddress(ledgerImpl.address), 'LaborLedgerImpl deployment failed');
    });

    beforeEach(async () => {
        collabProxy = await CollaborationProxy.new(
            collabImpl.address,
            proxyAdmin.address,
            '0x33ff',
            quorum,
            inviter,
            300000, 200000, 500000,
            ledgerImpl.address,
            lead,
            arbiter,
            operator,
            2500,
            0x04030201,
            defaultOpts
        );
        assert(web3.utils.isAddress(collabProxy.address), 'CollaborationProxy deployment failed');

        collab = new web3.eth.Contract(CollaborationImpl.abi, collabProxy.address);
        let ldgrAddr = await collab.methods.getLaborLedger().call();
        ledger = new web3.eth.Contract(LaborLedgerImpl.abi, ldgrAddr);
    });

    it("shall start", (cb) => {
       cb();
    });
});
