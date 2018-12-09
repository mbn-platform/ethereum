const should = require('should');
const dayjs = require('dayjs');

const {snapshot, rollback, ether, throws} = require('./util/helpers');

module.exports = ({describe, define, before, after, it}) => {
  describe('Reseller', () => {
    before(snapshot);
    after(rollback);

    define(async ({accounts, contracts}) => {
      const {main} = accounts;

      const releaseTime = dayjs('1971-06-01T00:00:00');
      const unlockTime = releaseTime.add(1, 'month').endOf('day');

      // Create token
      const token = await contracts.token.deploy(
        main
      )
      .send(main);

      // Create distribution contract
      const distribution = await contracts.distribution.deploy(
        main,
        token.options.address,
        main,
        releaseTime.unix().toString(),
        unlockTime.unix().toString(),
        10000000000,
        ether(0.0001),
      ).send(main);

      // Create reseller contract
      const reseller = await contracts.reseller.deploy(
        main,
        distribution.options.address,
      )
      .send(main);

      await token.methods.setController(distribution.options.address).send({
        from: main,
      });

      // Add reseller to distribution ccontract and allow to sell 1000 tokens
      await distribution.methods.addReseller(reseller.options.address, 1000000000)
      .send({from: main, gas: '5000000'});

      const addStage = (start, bonus) => {
        return distribution.methods.addStage(
          start.unix().toString(),
          start.add(7, 'day').unix().toString(),
          bonus
        ).send({from: main});
      };

      const startTime = dayjs('1970-12-31T00:00:00');
      // Add distribution stages since startTime
      await addStage(startTime, 50);
      await addStage(startTime.add(14, 'day'), 30);
      await addStage(startTime.add(28, 'day'), 10);

      return {token, reseller, distribution, startTime, releaseTime, unlockTime};
    });

    describe('#fillBalance()', () => {
      before(snapshot);
      after(rollback);

      it('Should increase balance', async ({reseller, accounts}) => {
        const {user1, user2} = accounts;
        const {fillBalance, getBalance} = reseller.methods;

        const balanceBefore = await getBalance(user1).call();
        should(balanceBefore).be.equal(ether(0));

        await fillBalance(user1).send({
          from: user1,
          value: ether(1),
        });

        const balanceAfter = await getBalance(user1).call();
        should(balanceAfter).be.equal(ether(1));
      });

      it('Should set ref', async ({reseller, accounts}) => {
        const {user1, user2} = accounts;
        const {fillBalance, getRef} = reseller.methods;

        const refBefore = await getRef(user1).call();
        should(refBefore).be.equal('0x' + ('0'.repeat(40)));

        await fillBalance(user1, user2).send({
          from: user1,
          value: ether(1),
        });

        const refAfter = await getRef(user1).call();
        should(refAfter).be.equal(user2);
      });

      it('Should fail on wrong ref', async ({reseller, accounts}) => {
        const {user1, user2, user3} = accounts;
        const {fillBalance, getRef} = reseller.methods;

        const caught = await throws(
          /ref_mismatch/,
          () => fillBalance(user1, user3).send({
            from: user1,
            value: ether(1),
          })
        );

        should(caught).be.equal(true);
      });
    });

    describe('#transferTokens()', () => {
      before(snapshot);
      after(rollback);

      it('Should provide tokens transfer', async ({
        token,
        reseller,
        distribution,
        accounts,
        evm,
        startTime,
      }) => {
        const {main, member1, user1} = accounts;
        const {
          fillBalance,
          getBalance,
          transferTokens,
          getIncomesCount,
          getLastIncome,
        } = reseller.methods;

        await fillBalance(member1).send({
          from: member1,
          value: ether(1),
        });

        const balanceA = await getBalance(member1).call();
        should(balanceA).be.equal(ether(1));

        // Move forward to 14 days
        await evm.increaseTime(14 * 24 * 60 * 60);

        await fillBalance(member1).send({
          from: member1,
          value: ether(1),
        });

        const balanceB = await getBalance(member1).call();
        should(balanceB).be.equal(ether(2));

        const result = await transferTokens(member1, user1, main, '0')
        .send({
          from: main,
        });

        const incomes = await getIncomesCount(member1).call();
        should(incomes).be.equal('2');

        const lastIncome = await getLastIncome(member1).call();
        should(incomes).be.equal('2');

        const tokens = await token.methods.balanceOf(user1).call();
        should(tokens).be.equal('24000');

        const locked = await distribution.methods.getLockedBalance(user1).call();
        should(locked).be.equal('4000');
      });
    });

    it('Should fail on changed refs', async ({accounts, contracts, reseller}) => {
      const {main, member1, member2, member3} = accounts;
      const {fillBalance, transferTokens} = reseller.methods;

      await fillBalance(member2, member1).send({
        from: member2,
        value: ether(1),
      });

      const caught = await throws(
        /ref_mismatch/,
        () => transferTokens(member2, member2, member3, '0')
        .send({from: main})
      );

      should(caught).be.equal(true);
    });
  });
};
