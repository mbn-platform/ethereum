const Web3 = require('web3');

const {selectNetwork} = require('./util/web3-local');

const network = selectNetwork();

module.exports = new Web3(`wss://${network}.infura.io/ws/v3/a70f05fab96f4984802264acb4fc3d13`);
