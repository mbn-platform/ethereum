const {web3, evm} = require('./util/web3');
const sources = {
  Distribution: require('../dist/distrib.json'),
  Token: require('../dist/token.json'),
  Treasure: require('../dist/treasure.json'),
  Reseller: require('../dist/reseller.json'),
};
const {getContracts, getAccounts} = require('../util/web3');

const {toWei, fromWei} = web3.utils;

module.exports = (test) => {
  test.define(() => {
    return {
      web3,
      evm,
      toWei: web3.utils.toWei,
      fromWei: web3.utils.fromWei,
      getBalance: (address, units = 'ether') => web3.eth.getBalance(address)
      .then((balance) => web3.utils.fromWei(balance, units)),
    };
  });

  test.define(async ({web3}) => {
    accounts = await getAccounts(web3, [
      'main',
      'member1',
      'member2',
      'member3',
      'member4',
      'user1',
      'user2',
      'user3',
      'user4',
    ]);

    contracts = await getContracts(web3, {
      distribution: sources.Distribution,
      token: sources.Token,
      treasure: sources.Treasure,
      reseller: sources.Reseller,
    });

    return {contracts, accounts};
  });

  require('./distribution.spec')(test);
  require('./token.spec')(test);
  require('./treasure.spec')(test);
  require('./reseller.spec')(test);
};
