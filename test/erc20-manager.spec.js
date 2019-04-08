const should = require('should');

const {mountWeb3, mountWeb3Utils, mountEvm, mountAccounts, snapshot} = require('./util/web3');
const {createDeployment} = require('../util/web3');

const contracts = {
  erc20Management: require('../dist/Erc20Manager'),
  token: require('../dist/Token'),
};

module.exports = ({describe, use, it}) => {
  describe('Erc20Manager', function() {
    use(mountWeb3());
    use(mountWeb3Utils());
    use(mountEvm());
    use(snapshot);

    use(mountAccounts({
      main: 0,
      member1: 1,
      member2: 2,
      member3: 3,
      member4: 4,
      user1: 5,
      user2: 6,
      user3: 7,
      user4: 8,
    }));

    use(async (ctx, next) => {
      const {web3, accounts} = ctx;
      const {main} = accounts;
      const token = await createDeployment(web3, contracts.token)
      .deploy(main)
      .send({
        from: main,
      });

      const {release, transfer} = token.methods;
      // Release token
      await release().send({from : main});

      const manager = await createDeployment(web3, contracts.erc20Management)
      .deploy(main, token.options.address)
      .send({
        from: main,
      });
      // Fill manager adress
      await transfer(manager.options.address, '1000').send({from: main});

      const {addVoter} = manager.methods;

      await addVoter(accounts.member1, 1).send({from: main});
      await addVoter(accounts.member2, 1).send({from: main});
      await addVoter(accounts.member3, 1).send({from: main});
      await addVoter(accounts.member4, 1).send({from: main});

      return next({
        ...ctx,
        manager,
        token,
      });
    });

    describe('#constructor()', () => {
      it(
        'Should set owner',
        async ({manager, accounts}) => {
          const {main} = accounts;
          const {owner} = manager.methods;

          const result = await owner().call();

          should(result).be.equal(main);
        }
      );
    });

    describe('#addVoter() && #removeVoter())', () => {
      use(snapshot);

      it(
        'Should add voters',
        async ({manager, accounts}) => {
          const {main, user1} = accounts;
          const {addVoter, powerOf} = manager.methods;

          const before = await powerOf(user1).call();
          should(before).be.equal('0');

          await addVoter(user1).send(main);

          const after = await powerOf(user1).call();
          should(after).be.equal('1');
        }
      );

      it(
        'Should set custom votes power',
        async ({manager, accounts}) => {
          const {main, user2} = accounts;
          const {addVoter, powerOf, totalPower} = manager.methods;

          const before = await powerOf(user2).call();
          should(before).be.equal('0');

          await addVoter(user2, '100').send({from: main});

          const after = await powerOf(user2).call();
          should(after).be.equal('100');

          const total = await totalPower().call();
          should(total).be.equal('105');
        }
      );

      it(
        'Should remove votes power',
        async ({manager, accounts}) => {
          const {main, user2} = accounts;
          const {removeVoter, powerOf, totalPower} = manager.methods;

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
        async ({manager}) => {
          const totalPower = await manager.methods.totalPower().call();
          should(totalPower).be.equal('4');
        }
      );
    });

    describe('#proposeTransfer() and #vote', () => {
      use(snapshot);

      it(
        'Should set one vote at creation',
        async ({manager, token, accounts}) => {
          const {member1, member4} = accounts;
          const {proposeCall, votesOf} = manager.methods;
          const {transfer} = token.methods;

          const data = transfer(member4, '100').encodeABI();

          await proposeCall(data)
          .send({from:member1});

          const votes = await votesOf(1).call();

          should(votes).be.equal('1');
        }
      );

      it(
        'Should increase votes on vote',
        async ({manager, accounts}) => {
          const {member2} = accounts;
          const {vote, votesOf} = manager.methods;

          await vote(1).send({from: member2});

          const votes = await votesOf(1).call();

          should(votes).be.equal('2');
        }
      );

      it(
        'Should transfer when quorum reached',
        async ({manager, token, accounts}) => {
          const {member3, member4} = accounts;
          const {vote, votesOf, isCompleted} = manager.methods;
          const {balanceOf} = token.methods;

          await vote(1).send({from: member3});

          const votes = await votesOf(1).call();
          should(votes).be.equal('3');

          const status = await isCompleted(1).call();
          should(status).be.True();

          const balance = await balanceOf(member4).call();
          should(balance).be.equal('100');
        }
      );
    });
  });
};
