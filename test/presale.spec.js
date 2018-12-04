const should = require('should');

module.exports = ({describe, define, before, after, it}) => {
  describe('Presale', function() {
    before(({snapshot}) => snapshot());

    define(async ({accounts, contracts}) => {
      const deploy = await contracts.deploy.deploy()
      .send(accounts.main);

      return {deploy};
    });

    after(({rollback}) => rollback());

  });
};
