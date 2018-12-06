const should = require('should');

const {snapshot, rollback, ether} = require('./util/helpers');

module.exports = ({describe, define, before, after, it}) => {
  describe('Treasure', function() {
    before(snapshot);
    after(rollback);

    define(async ({accounts, contracts}) => {
      const {main} = accounts;
      const treasure = await contracts.treasure.deploy()
      .send({
          from: main,
          value: ether(100),
      });

      const {addVoter, finalize} = treasure.methods;

      await addVoter(accounts.member1, 1).send(main);
      await addVoter(accounts.member2, 1).send(main);
      await addVoter(accounts.member3, 1).send(main);
      await addVoter(accounts.member4, 1).send(main);

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

    describe('#addVoter()', () => {
      it(
        'Should to revert after finalization',
        async ({treasure, accounts}) => {
          const {user1} = accounts;
          const {addVoter} = treasure.methods;

          let caught = false;

          try {
            await addVoter(user1).send();
          }
          catch (err) {
            caught = /revert finalized_neq/.test(err.message);
            if (! caught) {
              throw err;
            }
          }

          should(caught).be.True();
        }
      );
    });

    describe('#totalVotes()', () => {
      it(
        'Should return totalVotes number',
        async ({treasure}) => {
          const totalVotes = await treasure.methods.totalVotes().call();

          should(totalVotes).be.equal('4');
        }
      );
    });

    describe('#addProposal() and #vote', () => {
      before(snapshot);
      after(rollback);

      it(
        'Should set one vote at creation',
        async ({toWei, treasure, accounts}) => {
          const {member1, member4} = accounts;
          const {addProposal, votesOf, powerOf} = treasure.methods;
          const amount = toWei('10', 'ether');

          const result = await addProposal(member4, amount).send({from:member1});

          const votes = await votesOf(1).call();

          should(votes).be.equal('1');
        }
      );

      it(
        'Should increase votes on vote',
        async ({toWei, treasure, accounts}) => {
          const {member2, member4} = accounts;
          const {vote, votesOf} = treasure.methods;

          await vote(1).send({from: member2});

          const votes = await votesOf(1).call();

          should(votes).be.equal('2');
        }
      );

      it(
        'Should transfer when quorum reached',
        async ({toWei, treasure, accounts, getBalance}) => {
          const {member3, member4} = accounts;
          const {vote, votesOf, isCompleted} = treasure.methods;

          await vote(1).send({from:member3});

          const votes = await votesOf(1).call();
          should(votes).be.equal('3');

          const status = await isCompleted(1).call();
          should(status).be.True();

          const balance = await getBalance(member4);
          should(balance).be.equal('1010');
        }
      );
    })
  });
};
