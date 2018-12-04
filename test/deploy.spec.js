const should = require('should');

module.exports = ({describe, define, before, after, it}) => {
  describe('Deploy', function() {
    before(({snapshot}) => snapshot());

    define(async ({accounts, contracts}) => {
      const deploy = await contracts.deploy.deploy()
      .send(accounts.main);

      return {deploy};
    });

    after(({rollback}) => rollback());

    describe('#presale()', function() {
      it('Should return presale address', async function({deploy, web3}) {
        const address = await deploy.methods.presale().call();

        should(web3.utils.isAddress(address)).be.True();
      });

      it('Should return same token addresses', async function({deploy, contracts}) {
        const address = await deploy.methods.presale().call();
        const token = await deploy.methods.token().call();

        const Presale = contracts.presale.at(address);
        const presaleToken = await Presale.methods.token().call();

        should(presaleToken).be.equal(token);
      });
    });

    describe('#token()', function() {
      it('Should return token address', async function({deploy, contracts}) {
        const address = await deploy.methods.token().call();

        const token = contracts.token.at(address);
        const name = await token.methods.name().call();

        should(name).be.equal('Membrana');
      });

      it(
        'Should return same address from presale and token.controller()',
        async function({contracts, deploy}) {
          const address = await deploy.methods.token().call();
          const presale = await deploy.methods.presale().call();

          const controller = await contracts.token.at(address)
          .methods.controller().call();

          should(controller).be.equal(presale);
        }
      );
    });

    describe('#treasure()', function() {
      it('Should return treasure address', async function({web3, deploy}) {
        const address = await deploy.methods.treasure().call();

        should(web3.utils.isAddress(address)).be.True();
      });
    });
  });
};
