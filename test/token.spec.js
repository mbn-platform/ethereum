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
      .send(main);

      return next({
        ...ctx,
        token,
      });
    });

    describe('#mint()', () => {
      use(snapshot);

      it(
        'Should increase balanceOf',
        async ({token, accounts}) => {
          const {main, member1} = accounts;
          const {mint, balanceOf} = token.methods;

          await mint(member1, '10').send(main);
          const balance = await balanceOf(member1).call();

          should(balance).be.equal('10');
        }
      );

      it(
        'Should increase total supply',
        async ({token, accounts}) => {
          const {main, member1} = accounts;
          const {mint, totalSupply} = token.methods;

          await mint(member1, '10').send(main);
          const balance = await totalSupply().call();

          should(balance).be.equal('20');
        }
      );
    });

    describe('#release()', () => {
      use(snapshot);

      it(
        'Should change #isReleased() value',
        async ({token, accounts}) => {
          const [main] = accounts;
          const {isReleased, release} = token.methods;

          const before = await isReleased().call();
          should(before).be.equal(false);

          await release().send(main);

          const after = await isReleased().call();
          should(after).be.equal(true);
        }
      );

      it(
        'Should deprecate minting',
        async ({token, accounts}) => {
          const {main, member1} = accounts;
          const {isReleased, mint} = token.methods;

          const before = await isReleased().call();
          should(before).be.equal(true);

          const caught = await throws(
            /not_released_only/,
            () => mint(member1, 1).send({from:main})
          );

          should(caught).be.equal(true);
        }
      );
    });
  });
};
