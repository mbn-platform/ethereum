const should = require('should');
const dayjs = require('dayjs');

const {snapshot, rollback, ether} = require('./util/helpers');

module.exports = ({describe, define, before, after, it}) => {
  describe('Presale', function() {
    before(snapshot);
    after(rollback);

    define(async ({accounts, contracts, toWei}) => {
      const {main} = accounts;

      const releaseTime = dayjs('1971-06-01T00:00:00');
      const unlockTime = releaseTime.add(1, 'month').endOf('day');

      const token = await contracts.token.deploy(main)
      .send(main);

      const distribution = await contracts.distribution.deploy(
        token.options.address,
        main,
        main,
        releaseTime.unix().toString(),
        unlockTime.unix().toString(),
        10,
        ether(0.0001),
      )
      .send(main);

      await token.methods.setController(distribution.options.address)
      .send(main);

      return {distribution, token, releaseTime, unlockTime};
    });

    describe('#setNextRate() & #getRate()', () => {
      it(
        'Should set next rate',
        async ({accounts, distribution, evm}) => {
          const {main} = accounts;
          const {getCurrentRate, setNextRate} = distribution.methods;

          const rateBefore = await getCurrentRate().call();
          should(rateBefore).be.equal(ether(0.0001));

          await setNextRate(ether(0.0002)).send(main);

          await evm.increaseTime(24 * 60 * 60 + 1);

          const rateAfter = await getCurrentRate().call();
          should(rateAfter).be.equal(ether(0.0002));
        }
      )
    });

    describe('#addStage()', () => {
      it(
        'Should add first stage',
        async ({accounts, distribution, releaseTime}) => {
          const {main} = accounts;
          const {
            addStage,
            getStagesLength,
            getStageStart,
            getStageEnd,
            getStageBonus,
          } = distribution.methods;

          const start = dayjs('1970-12-01').unix().toString();
          const end = dayjs('1970-12-01').endOf('day').unix().toString();
          const bonus = '70';

          await addStage(start, end, bonus).send(main);
          const length = await getStagesLength().call();

          should(length).be.equal('1');

          const i = parseInt(length, 10) - 1;

          const startResult = await getStageStart(i).call();
          const endResult = await getStageEnd(i).call();
          const bonusResult = await getStageBonus(i).call();

          should(startResult).be.equal(start);
          should(endResult).be.equal(end);
          should(bonusResult).be.equal(bonus);
        }
      )
    });

    describe('Reseller management', () => {
      describe('#addReseller()', () => {
        it(
          'Should add reseller if not exists',
          async ({distribution, accounts}) => {
            const {main, member1} = accounts;
            const {addReseller, isReseller} = distribution.methods;

            const before = await isReseller(member1).call();
            should(before).be.equal(false);

            await addReseller(member1, 5).send(main);

            const after = await isReseller(member1).call();
            should(after).be.equal(true);
          }
        )

        it(
          'Should revert if already a reseller',
          async ({distribution, accounts}) => {
            const {main, member1} = accounts;
            const {addReseller} = distribution.methods;

            let caught = false;
            try {
              await addReseller(member1, 0).send(main);
            }
            catch (err) {
              caught = /revert exists/.test(err.message);
              if (! caught) {
                throw err;
              }
            }

            should(caught).be.True();
          }
        )
      });

      describe('#removeReseller()', () => {
        before(async ({accounts, distribution}) => {
          const {main, member2} = accounts;
          const {addReseller} = distribution.methods;

          await addReseller(member2, 0).send(main);
        });

        it(
          'Should remove reseller if not exists',
          async ({distribution, accounts}) => {
            const {main, member2} = accounts;
            const {removeReseller, isReseller} = distribution.methods;

            const before = await isReseller(member2).call();
            should(before).be.equal(true);

            await removeReseller(member2).send(main);

            const after = await isReseller(member2).call();
            should(after).be.equal(false);
          }
        )
      });
    })

    describe('#getCurrentRate()', () => {
      it(
        'Should return proper token amount',
        async ({accounts, distribution}) => {
          const {main} = accounts;
          const {getTokensAmount, getCurrentRate} = distribution.methods;

          const rate = await getCurrentRate().call();

          should(rate).be.equal(ether(0.0002));
        }
      )
    });

    describe('#transferTokens()', () => {
      it(
        'Should transfer tokens to Token contract',
        snapshot,
        async ({accounts, distribution, token, web3}) => {
          const {main, member1, user1} = accounts;
          const {transferTokens, getLockedBalance} = distribution.methods;
          const {balanceOf} = token.methods;

          const balanceOfBalance = await balanceOf(user1).call();
          should(balanceOfBalance).be.equal('0');

          const balanceBefore = await web3.eth.getBalance(main);

          await transferTokens(user1, 1, 2).send({
            from: member1,
            value: ether(10),
          });

          const balanceOfAfter = await balanceOf(user1).call();
          should(balanceOfAfter).be.equal('1');

          const locked = await getLockedBalance(user1).call();
          should(locked).be.equal('2');
        },
        rollback
      );

      it(
        'Should decrease avaiable for reseller tokens count',
        snapshot,
        async ({accounts, distribution, token, web3}) => {
          const {main, member1, user1} = accounts;
          const {transferTokens, getAvailable} = distribution.methods;

          const availableBefore = await getAvailable(member1).call();
          should(availableBefore).be.equal('5');

          const balanceBefore = await web3.eth.getBalance(main);

          await transferTokens(user1, 1, 2).send({
            from: member1,
            value: ether(10),
          });

          const availableAfter = await getAvailable(member1).call();
          should(availableAfter).be.equal('2');
        },
        rollback
      );

      it(
        'Should transfer ethers to Treasurer',
        snapshot,
        async ({accounts, distribution, token, web3}) => {
          const {main, member1, user1} = accounts;
          const {transferTokens} = distribution.methods;

          const balanceBefore = await web3.eth.getBalance(main);

          await transferTokens(user1, 1, 2).send({
            from: member1,
            value: ether(10),
          });

          const balanceAfter = await web3.eth.getBalance(main);
          should(balanceAfter - balanceBefore + '').be.equal(ether(10));
        },
        rollback
      );

      it(
        'Should change locks count',
        snapshot,
        async ({accounts, distribution, token, web3}) => {
          const {main, member1, user1} = accounts;
          const {transferTokens, getAvailable, getLocksCount} = distribution.methods;
          const {balanceOf} = token.methods;

          const locksBefore = await getLocksCount(user1).call();
          should(locksBefore).be.equal('0');

          await transferTokens(user1, 1, 2).send({
            from: member1,
            value: ether(10),
          });

          const locksAfter = await getLocksCount(user1).call();
          should(locksAfter).be.equal('1');
        },
        rollback
      );
    });
  });
};
