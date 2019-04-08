const should = require('should');

const {mountWeb3, mountEvm, mountAccounts, snapshot} = require('./util/web3');
const {createDeployment} = require('../util/web3');
const {throws} = require('./util/helpers');

const contract = require('../dist/Token.js');

module.exports = ({describe, use, it}) => {
  describe('Token', function() {
    use(mountWeb3());
    use(mountEvm());
    use(snapshot);

    use(mountAccounts({
      main: 0,
      member1: 1,
    }));

    use(async (ctx, next) => {
      const {web3, accounts} = ctx;
      const {main} = accounts;

      const token = await createDeployment(web3, contract)
      .deploy(main)
      .send({from: main});

      return next({
        ...ctx,
        token,
      });
    });

    describe('#setPrivileged', () => {
      it(
        'Should allow address to transfer tokens before release',
        snapshot,
        async ({token, accounts}) => {
          const {main, member1} = accounts;
          const {setPrivileged, transfer, balanceOf} = token.methods;

          await setPrivileged(main).send({from: main});
          await transfer(member1, '1000').send({from: main});
          const balance = await balanceOf(member1)
          .call();

          should(balance).be.equal('1000');
        }
      );
    });

    describe('#setUnprivileged', () => {
      it(
        'Should decline address to transfer tokens before release',
        snapshot,
        async ({token, accounts}) => {
          const {main, member1} = accounts;
          const {setPrivileged, setUnprivileged, transfer, balanceOf} = token.methods;

          await setPrivileged(main).send({from: main});
          // Ensure setPrivileged set
          await transfer(member1, '1000').send({from: main});
          const balance = await balanceOf(member1).call();
          should(balance).be.equal('1000');

          // Check privelegy unset correctly
          await setUnprivileged(main).send({from: main});
          await throws(
            /released_or_privileged_only/,
            () => transfer(member1, '1000').send({from: main}),
          );
        }
      );
    });

    describe('#release()', () => {
      it(
        'Should change #isReleased() value',
        snapshot,
        async ({token, accounts}) => {
          const {main} = accounts;
          const {isReleased, release} = token.methods;

          const before = await isReleased().call();
          should(before).be.equal(false);

          await release().send({from: main});

          const after = await isReleased().call();
          should(after).be.equal(true);
        }
      );

      it(
        'Should set #releasedDate value',
        snapshot,
        async ({token, accounts}) => {
          const {main} = accounts;
          const {releaseDate, release} = token.methods;

          const before = await releaseDate().call();
          should(before).be.equal('0');

          await release().send({from: main});

          const after = await releaseDate().call();
          should(parseInt(after, 10)).be.greaterThan(0);
        }
      );

      // it(
      //   'Should allow transfers to anyone',
      //   snapshot,
      //   async ({token, accounts}) => {
      //     const {main}
      //   }
      // )
    });
  });
};
