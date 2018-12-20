const fs = require('fs');

const chalk = require('chalk');
const web3 = require('../web3');
const abi = require('web3-eth-abi');

const {
  readJson,
  writeJson,
} = require('../util/fs');

const {
  getDir,
  getPrivate,
  getContractPath,
} = require('../util/web3-local.js');

module.exports = async function([filepath, name]) {
  const dir = getDir();
  const account = getPrivate(dir);

  const outPath = getContractPath('./deployed', name);

  if (fs.existsSync(outPath)) {
    throw `Contract ${name} already exists`;
  }

  const contract = readJson(filepath);

  const args = encodeAbi(contract.abi, 'constructor', []);
  const options = {
    data: '0x' + contract.evm.bytecode.object + args,
  };

  const nonce = await web3.eth.getTransactionCount(account.address);
  const gas = await web3.eth.estimateGas(options);
  const tx = await web3.eth.accounts.signTransaction({
    gas,
    nonce,
    ...options,
  }, account.privateKey);

  chalkLog('Message hash', tx.messageHash);
  chalkLog('URL', 'https://etherscan.io/tx/' + tx.messageHash);

  return;

  const {contractAddress} = await web3.eth.sendSignedTransaction(tx.rawTransaction)
  .on('transactionHash', (hash) => {
    chalkLog('Tx hash', hash);
  })
  .on('receipt', (receipt) => {
    chalkDump('Receipt', receipt);
  })
  .on('confirmation', (n) => {
    chalkLog('Confirmation', n);
  });

  chalkLog('Contract address', contractAddress);

  writeJson(
    outPath,
    {
      address: contractAddress,
      abi: contract.abi,
    }
  );

  chalkLog('Contract saved', outPath);
};

function encodeAbi(jsonInterface, methodSignature, args) {
  const paramsABI = jsonInterface.filter(function (json) {
    return ((methodSignature === 'constructor' && json.type === methodSignature) ||
    ((json.signature === methodSignature || json.signature === methodSignature.replace('0x','') || json.name === methodSignature) && json.type === 'function'));
  })
  .map(function (json) {
    var inputLength = (Array.isArray(json.inputs)) ? json.inputs.length : 0;

    if (inputLength !== args.length) {
      throw new Error('The number of arguments is not matching the methods required number. You need to pass '+ inputLength +' arguments.');
    }

    if (json.type === 'function') {
      signature = json.signature;
    }
    return Array.isArray(json.inputs) ? json.inputs : [];
  }).map(function (inputs) {
    return abi.encodeParameters(inputs, args).replace('0x','');
  })[0] || '';

  return paramsABI;
}

function chalkLog(key, value) {
  console.log(chalk.bold(key) + ': ' + value);
}

function chalkDump(key, value) {
  console.log(chalk.bold(key) + ': %o', value);
}
