const should = require('should');

const {getWeb3, getEvm, mountWeb3, mountEvm, mountAccounts, snapshot} = require('./util/web3');
// const {createDeployment} = require('../util/web3');
const {throws} = require('./util/helpers');

const contracts = {
  lockups: require('../dist/Lockups.js'),
  token: require('../dist/Token.js'),
};

const releaseToken = async ({accounts, token, ...ctx}, next) => {
  const evm = getEvm(ctx);
  const {main} = accounts;
  const {release} = token.methods;

  await release().send({from: main});
  await evm.increaseTime(1000);

  return next();
};

module.exports = ({describe, use, it}) => {
  describe('Lockups Contract', function() {
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

      const token = await new web3.eth.Contract(contracts.token.abi)
      .deploy({
        data: '0x' + contracts.token.evm.bytecode.object,
        arguments: [main],
      })
      .send({
        from: main,
        gasLimit: '5000000',
      });

      const lockups = await new web3.eth.Contract(contracts.lockups.abi)
      .deploy({
        data: '0x' + contracts.lockups.evm.bytecode.object,
        arguments: [main, token.options.address, '1'],
      })
      .send({
        from: main,
        gasLimit: '5000000',
      });

      await token.methods.setPrivileged(main).send({
        from: main,
      });
      await token.methods.transfer(lockups.options.address, '1000').send({
        from: main,
      });

      await lockups.methods.increase(accounts.member1, '100').send({
        from: main,
      });

      return next({
        ...ctx,
        lockups,
        token,
      });
    });

    describe('#increase()', () => {
      it(
        'Should use specified gas amount',
        snapshot,
        async ({lockups, accounts}) => {
          const {main, member2} = accounts;
          const {increase, balanceOf} = lockups.methods;

          const before = await balanceOf(member2).call();
          should(before).be.equal('0');

          await increase(member2, '100').send({
            from: main,
          });

          const after = await balanceOf(member2).call();
          should(after).be.equal('100');
        }
      );

      it(
        'Should throw if balance value exceed',
        snapshot,
        async ({lockups, accounts}) => {
          const {main, member2} = accounts;
          const {increase} = lockups.methods;

          await throws(
            /balanceOf_gte/,
            () => increase(member2, '1000').send({
              from: main,
            })
          );
        }
      );

      describe('After release and first withdrawal', () => {
        use(snapshot);
        use(releaseToken);

        it('Should throw if withdrawal has already been made',
          snapshot,
          async ({lockups, accounts}) => {
            const {withdraw, increase} = lockups.methods;
            const {main, member1, member2} = accounts;

            await withdraw(member1).send({from: member1});

            await throws(
              /withdrawnAmount_zero/,
              () => increase(member2, '1').send({from: main})
            );
          }
        );
      });
    });

    describe('#release()', () => {
      use(snapshot);

      describe('Before release', () => {
        it(
          'Should throw',
          snapshot,
          async ({lockups, accounts}) => {
            const {withdraw} = lockups.methods;
            const {main, member1} = accounts;

            await throws(
              /released/,
              () => withdraw(member1).send({
                from: main,
              })
            );
          }
        );
      });

      describe('After release', () => {
        use(snapshot);
        use(releaseToken);

        it(
          'Should transfer when released',
          snapshot,
          async ({lockups, token, accounts}) => {
            const {withdraw} = lockups.methods;
            const {balanceOf} = token.methods;
            const {member1} = accounts;

            const before = await balanceOf(member1).call();
            should(before).be.equal('0');

            await withdraw(member1).send({from: member1});

            const after = await balanceOf(member1).call();
            should(after).be.equal('100');
          }
        );

        it(
          'Should throw if has no amount',
          snapshot,
          async ({lockups, accounts}) => {
            const {withdraw} = lockups.methods;
            const {member2} = accounts;

            await throws(
              /amount_gt/,
              () => withdraw(member2).send({from: member2})
            );
          }
        );
      });
    });
  });
};
