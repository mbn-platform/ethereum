const ganache = require('ganache-cli');
const Web3 = require('web3');

// Create web3 instance
const provider = ganache.provider({
  total_accounts: 100,
  default_balance_ether: 1000,
});
provider.setMaxListeners(0);

const web3 = new Web3(provider);

const snapshots = [];

function snapshot() {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_snapshot',
      params: [],
      id: new Date().getTime()
    }, (err, {result} = {}) => {
      if (err) {
        reject(err);
      }
      else {
        snapshots.push(result);
        resolve();
      }
    })
  });
}

function rollback() {
  return new Promise((resolve, reject) => {
    web3.currentProvider.send({
      jsonrpc: '2.0',
      method: 'evm_revert',
      params: [snapshots.pop()],
      id: new Date().getTime()
    }, (err, result) => {
      if (err) {
        reject(err);
      }
      else {
        resolve();
      }
    });
  });
}

exports.web3 = web3;
exports.snapshot = snapshot;
exports.rollback = rollback;
