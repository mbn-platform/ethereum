const should = require('should');

const {mountWeb3, mountEvm, mountAccounts, snapshot} = require('./util/web3');
const {createDeployment} = require('../util/web3');
const {throws} = require('./util/helpers');

const contracts = {
  assistant: require('../dist/PersonalAssistant.js'),
  token: require('../dist/Token.js'),
};

module.exports = ({describe, use, it}) => {
  describe('PersonalAssistant', function() {
    use(mountWeb3());
    use(mountEvm());
    use(snapshot);

    use(mountAccounts({
      main: 0,
      member1: 1,
      member2: 2,
    }));

    use(async (ctx, next) => {
      const {web3, accounts} = ctx;
      const {main} = accounts;

      const assistant = await createDeployment(web3, contracts.assistant)
      .deploy(main)
      .send({from: main});

      const token = await createDeployment(web3, contracts.token)
      .deploy(assistant.options.address)
      .send({from: main});

      return next({
        ...ctx,
        assistant,
        token,
      });
    });

    describe('#read()', () => {
      it(
        'Should read data',
        snapshot,
        async ({web3, token, assistant, accounts}) => {
          const {main} = accounts;
          const {balanceOf} = token.methods;
          const {read} = assistant.methods;

          const balance = await read(
            token.options.address, balanceOf(assistant.options.address).encodeABI(),
          ).call({from: main});

          const value = web3.eth.abi.decodeParameter('uint256', balance);
          should(value.toString()).be.equal('1000000000000000000000000000');
        }
      );
    });

    describe('#write()', () => {
      it(
        'Should write changes with owner account',
        snapshot,
        async ({token, assistant, accounts}) => {
          const {main, member1} = accounts;
          const {setPrivileged, isPrivileged} = token.methods;
          const {write, addMinion} = assistant.methods;

          await addMinion(member1).send({from: main});

          const before = await isPrivileged(assistant.options.address)
          .call();
          should(before).be.equal(false);

          await write(
            token.options.address, setPrivileged(assistant.options.address).encodeABI(),
          ).send({from: member1});

          const after = await isPrivileged(assistant.options.address)
          .call();
          should(after).be.equal(true);
        }
      );

      it(
        'Should write changes with minion account',
        snapshot,
        async ({token, assistant, accounts}) => {
          const {main} = accounts;
          const {setPrivileged, isPrivileged} = token.methods;
          const {write} = assistant.methods;

          const before = await isPrivileged(assistant.options.address)
          .call();
          should(before).be.equal(false);

          await write(
            token.options.address, setPrivileged(assistant.options.address).encodeABI(),
          ).send({from: main});

          const after = await isPrivileged(assistant.options.address)
          .call();
          should(after).be.equal(true);
        }
      );

      it(
        'Should revert changes from another accounts',
        snapshot,
        async ({token, assistant, accounts}) => {
          const {member2} = accounts;
          const {setPrivileged} = token.methods;
          const {write} = assistant.methods;

          await throws(
            /owner_or_minion_access/,
            () => write(
              token.options.address, setPrivileged(assistant.options.address).encodeABI(),
            ).send({from: member2}),
          );
        }
      );

      it(
        'Should be inaccessible when locked',
        snapshot,
        async ({token, assistant, accounts}) => {
          const {main} = accounts;
          const {setPrivileged} = token.methods;
          const {write, lock} = assistant.methods;

          await lock().send({
            from: main,
          });

          await throws(
            /unlocked_only/,
            () => write(
              token.options.address, setPrivileged(assistant.options.address).encodeABI(),
            ).send({from: main}),
          );
        }
      );
    });
  });
};
