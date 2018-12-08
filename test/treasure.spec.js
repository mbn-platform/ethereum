const should = require('should');

const {snapshot, rollback, ether} = require('./util/helpers');

module.exports = ({describe, define, before, after, it}) => {
  describe('Treasure', function() {
    before(snapshot);
    after(rollback);

    define(async ({accounts, contracts}) => {
      const {main} = accounts;
      const treasure = await contracts.treasure.deploy(main)
      .send({
          from: main,
          value: ether(100),
      });

      const {addVoter, finalize} = treasure.methods;

      await addVoter(accounts.member1, 1).send(main);
      await addVoter(accounts.member2, 1).send(main);
      await addVoter(accounts.member3, 1).send(main);
      await addVoter(accounts.member4, 1).send(main);

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

    describe('#addVoter() && #removeVoter())', () => {
      before(snapshot);
      after(rollback);

      it(
        'Should add voters',
        async ({treasure, accounts}) => {
          const {main, user1} = accounts;
          const {addVoter, powerOf} = treasure.methods;

          const before = await powerOf(user1).call();
          should(before).be.equal('0');

          await addVoter(user1).send(main);

          const after = await powerOf(user1).call();
          should(after).be.equal('1');
        }
      );

      it(
        'Should set custom votes power',
        async ({treasure, accounts}) => {
          const {main, user2} = accounts;
          const {addVoter, powerOf, totalPower} = treasure.methods;

          const before = await powerOf(user2).call();
          should(before).be.equal('0');

          await addVoter(user2, 100).send(main);

          const after = await powerOf(user2).call();
          should(after).be.equal('100');

          const total = await totalPower().call();
          should(total).be.equal('105');
        }
      );

      it(
        'Should remove votes power',
        async ({treasure, accounts}) => {
          const {main, user2} = accounts;
          const {removeVoter, powerOf, totalPower} = treasure.methods;

          const before = await powerOf(user2).call();
          should(before).be.equal('100');

          await removeVoter(user2).send(main);

          const after = await powerOf(user2).call();
          should(after).be.equal('0');

          const total = await totalPower().call();
          should(total).be.equal('5');
        }
      );
    });

    describe('#totalPower()', () => {
      it(
        'Should return totalPower number',
        async ({treasure}) => {
          const totalPower = await treasure.methods.totalPower().call();
          should(totalPower).be.equal('4');
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
          const {addProposal, votesOf, lastProposal, totalPower, powerOf} = treasure.methods;
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
          const {vote, votesOf, powerOf, totalPower, isCompleted} = treasure.methods;

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
