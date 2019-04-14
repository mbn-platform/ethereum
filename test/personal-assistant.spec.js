const should = require('should');

const {getWeb3, mountWeb3, mountEvm, mountAccounts, snapshot} = require('./util/web3');
const {createDeployment} = require('../util/web3');
const {throws} = require('./util/helpers');

const contracts = {
  assistant: require('../dist/PersonalAssistant.js'),
  token: require('../dist/SimpleToken.js'),
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
      const web3 = getWeb3(ctx);
      const {accounts} = ctx;
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
        async ({token, assistant, accounts, ...ctx}) => {
          const web3 = getWeb3(ctx);
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
          const {main, member2} = accounts;
          const {transfer, balanceOf} = token.methods;
          const {write} = assistant.methods;

          const before = await balanceOf(member2).call();
          should(before).be.equal('0');

          const result = await write(
            token.options.address,
            transfer(member2, '100').encodeABI(),
          ).send({from: main});

          should(result.status).be.equal(true);

          const after = await balanceOf(member2).call();
          should(after).be.equal('100');
        }
      );

      it(
        'Should write changes with member account',
        snapshot,
        async ({token, assistant, accounts}) => {
          const {main, member1, member2} = accounts;
          const {transfer, balanceOf} = token.methods;
          const {write, addMember} = assistant.methods;

          const before = await balanceOf(member2).call();
          should(before).be.equal('0');

          await addMember(member1).send({
            from: main,
          });

          const result = await write(
            token.options.address,
            transfer(member2, '100').encodeABI(),
          ).send({from: member1});

          should(result.status).be.equal(true);

          const after = await balanceOf(member2).call();
          should(after).be.equal('100');
        }
      );

      it(
        'Should revert changes from another accounts',
        snapshot,
        async ({token, assistant, accounts}) => {
          const {member2} = accounts;
          const {transfer} = token.methods;
          const {write} = assistant.methods;

          await throws(
            /owner_or_member_access/,
            () => write(
              token.options.address,
              transfer(assistant.options.address, '100').encodeABI(),
            ).send({from: member2}),
          );
        }
      );

      it(
        'Should be inaccessible when locked',
        snapshot,
        async ({token, assistant, accounts}) => {
          const {main} = accounts;
          const {transfer} = token.methods;
          const {write, lock} = assistant.methods;

          await lock().send({
            from: main,
          });

          await throws(
            /unlocked_only/,
            () => write(
              token.options.address, transfer(assistant.options.address, '100').encodeABI(),
            ).send({from: main}),
          );
        }
      );
    });

    describe('#writeExpect()', () => {
      it('Should succeed when output matches',
        snapshot,
        async ({token, assistant, accounts, ...ctx}) => {
          const web3 = getWeb3(ctx);
          const {main, member2} = accounts;
          const {transfer, balanceOf} = token.methods;
          const {writeExpect} = assistant.methods;

          const before = await balanceOf(member2).call();
          should(before).be.equal('0');

          const result = await writeExpect(
            token.options.address,
            transfer(member2, '100').encodeABI(),
            web3.utils.keccak256(
              web3.eth.abi.encodeParameter('bool', true)
            )
          ).send({from: main});

          should(result.status).be.equal(true);

          const after = await balanceOf(member2).call();
          should(after).be.equal('100');
        }
      );

      it(
        'Should fail when output mismatches',
        snapshot,
        async ({token, assistant, accounts, ...ctx}) => {
          const web3 = getWeb3(ctx);
          const {main, member2} = accounts;
          const {transfer} = token.methods;
          const {writeExpect} = assistant.methods;

          await throws(
            /expectation/,
            () => writeExpect(
              token.options.address,
              transfer(member2, '100').encodeABI(),
              web3.utils.keccak256(
                web3.eth.abi.encodeParameter('bool', false)
              )
            ).send({from: main}),
          );
        }
      );
    });
  });
};
