const should = require('should');
const dayjs = require('dayjs');

const {snapshot, rollback, ether} = require('./util/helpers');

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

    describe('#transferTokens()', () => {
      // before(snapshot);
      // after(rollback);

      it('Should provide tokens transfer', async ({
        token,
        reseller,
        accounts,
        evm,
        startTime,
        web3,
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

        await evm.increaseTime(startTime.add(14, 'day').unix());

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

        console.log('%o', result);

        const incomes = await getIncomesCount(member1).call();
        const lastIncome = await getLastIncome(member1).call();
        console.log({incomes, lastIncome});

        const tokens = await token.methods.balanceOf(user1).call();
        console.log({tokens});
      });
    })
  });
};
