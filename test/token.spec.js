const should = require('should');

const snapshot = (ctx) => ctx.snapshot();
const rollback = (ctx) => ctx.rollback();

module.exports = ({describe, define, before, after, it}) => {
  describe('Token', function() {
    before(snapshot);

    define(async ({accounts, contracts}) => {
      const token = await contracts.token.deploy(accounts.main)
      .send(accounts.main);

      return {token};
    });

    after(rollback);

    describe('#release()', () => {
      before(snapshot);
      after(rollback);

      it(
        'Should change #isReleased() value',
        async ({token, accounts}) => {
          const {main} = accounts;
          const {isReleased, release} = token.methods;

          const before = await isReleased().call();
          should(before).be.equal(false);

          await release().send(main);

          const after = await isReleased().call();
          should(after).be.equal(true);
        }
      );

      it(
        'Should return true after release',
        async ({token, accounts}) => {
          const {isReleased} = token.methods;

          const result = await isReleased().call();

          should(result).be.equal(false);
        }
      );
    });

    describe('#mint()', () => {
      it(
        'Should increase total supply',
        async ({token, accounts}) => {
          const {main, member1} = accounts;
          const {mint, balanceOf} = token.methods;

          await mint(member1, '10').send(main);
          const balance = await balanceOf(member1).call();

          should(balance).be.equal('10');
        }
      );
    });
  });
};
