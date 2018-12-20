const web3 = require('web3');

const {
  getDir,
  getPrivate,
} = require('../util/web3-local.js');

module.exports = function() {
  const dir = getDir();
  const account = getPrivate(dir);

  console.log(account.address);
};
