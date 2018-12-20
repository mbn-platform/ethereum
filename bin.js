#!/usr/bin/env node

async function main(argv) {
  const [cmd, ...cmdArgv] = argv.slice(2);

  return executable(cmd)(cmdArgv);
}

const map = {
  compile: './commands/compile',
  keygen: './commands/keygen',
  deploy: './commands/deploy',
  balance: './commands/balance',
  address: './commands/address',
  abi: './commands/abi',
};

function executable(cmd) {
  if (cmd in map) {
    return require(map[cmd]);
  }

  return helpCmd;
}

function helpCmd() {
  const commands = Object.keys(map)
  .map(cmd => `* ${cmd}`)
  .join('\n');

  console.log('Available commands are:\n\n%s', commands);
}

main(process.argv)
.catch((error) => {
  console.error(error);
  return 1;
})
.then((code = 0) => process.exit(code));
