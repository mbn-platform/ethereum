const {
  getDir,
  getPrivate,
} = require('../util/web3-local.js');

const web3 = require('./web3');

module.exports = async function([units = 'ether']) {
  const dir = getDir();
  const account = getPrivate(dir);

  const balance = await web3.eth.getBalance(account.address);

  console.log(web3.utils.fromWei(balance, units));
};
