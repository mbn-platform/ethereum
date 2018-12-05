const should = require('should');

const {snapshot, rollback, ether} = require('./util/helpers');

module.exports = ({describe, define, before, after, it}) => {
  describe('Treasure', function() {
    before(snapshot);
    after(rollback);

    define(async ({accounts, contracts}) => {
      const treasure = await contracts.treasure.deploy(3)
      .send({
        from: accounts.main,
        value: ether(100),
      });

      const {addParty, finalize} = treasure.methods;

      await addParty(accounts.member1).send(accounts.main);
      await addParty(accounts.member2).send(accounts.main);
      await addParty(accounts.member3).send(accounts.main);
      await addParty(accounts.member4).send(accounts.main);

      await finalize().send();

      return {
        treasure,
      };
    });

    describe('#constructor()', () => {
      it(
        'Should be payable',
        async ({treasure, web3, fromWei}) => {
          const balance = await web3.eth.getBalance(treasure.options.address);

          should(fromWei(balance, 'ether')).be.equal('100');
        }
      );
    });

    describe('#addParty()', () => {
      it(
        'Should to revert after finalization',
        async ({treasure, accounts}) => {
          let caught = false;

          try {
            await treasure.methods.addParty(accounts.user1).send();
          }
          catch (err) {
            caught = /revert finalized_only/.test(err.message);
          }

          should(caught).be.True();
        }
      );
    });

    describe('#quorum()', () => {
      it(
        'Should return quorum number passed at deploy time',
        async ({treasure}) => {
          const quorum = await treasure.methods.quorum().call();

          should(quorum).be.equal('3');
        }
      );
    });

    describe('#initTransfer() and #voteUp', () => {
      before(snapshot);
      after(rollback);

      it(
        'Should set one vote at creation',
        async ({toWei, treasure, accounts}) => {
          const {member1, member4} = accounts;
          const {initTransfer, votesOf} = treasure.methods;
          const amount = toWei('10', 'ether');

          await initTransfer(member4, amount).send({from:member1});

          const votes = await votesOf(member4, amount).call();

          should(votes).be.equal('1');
        }
      );

      it(
        'Should increase votes on voteUp',
        async ({toWei, treasure, accounts}) => {
          const {member2, member4} = accounts;
          const {voteUp, votesOf} = treasure.methods;
          const amount = toWei('10', 'ether');

          await voteUp(member4, amount).send({from: member2});

          const votes = await votesOf(member4, amount).call();

          should(votes).be.equal('2');
        }
      );

      it(
        'Should transfer when quorum reached',
        async ({toWei, treasure, accounts, getBalance}) => {
          const {member3, member4} = accounts;
          const {voteUp, votesOf} = treasure.methods;
          const amount = toWei('10', 'ether');

          await voteUp(member4, amount).send({from:member3});

          const votes = await votesOf(member4, amount).call();
          should(votes).be.equal('0');

          const balance = await getBalance(accounts.member4);
          should(balance).be.equal('1010');
        }
      );
    })
  });
};
