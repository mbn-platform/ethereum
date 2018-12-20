const {readJson} = require('../util/fs.js');

module.exports = function([filepath]) {
  const contract = readJson(filepath);
  console.log(JSON.stringify(contract.abi, null, 2));
};
