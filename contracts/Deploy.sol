pragma solidity ^0.4.24;

import './Presale.sol';
import './Token.sol';
import './Treasure.sol';

contract Deploy {
  address private treasure_;
  address private presale_;
  address private token_;

  constructor()
    public
  {
    Treasure treasure = new Treasure(2);
    treasure.addParty(address(0x0000000000000000000000000000000000000001));
    // treasure.addParty(address(0x0000000000000000000000000000000000000002));
    // treasure.addParty(address(0x0000000000000000000000000000000000000003));
    treasure.finalize();
    treasure_ = treasure;

    Presale presale = new Presale(
      this,
      address(treasure),
      1556658000000, // 2019-05-01T00:00:00
      1559336400000, // 2019-06-01T00:00:00
      1000000000
    );

    presale_ = presale;

    token_ = new Token(presale);

    presale.setToken(token_);

    // TODO add team wallets, shares and unlock date
    uint256 teamUnlock = 1567285200000; // 2019-09-01T00:00:00
    // presale.transferLocked(address(0x0000000000000000000000000000000000000001), 1000000, teamUnlock);
    //presale.transferLocked(address(0x0000000000000000000000000000000000000002), 1000000, teamUnlock);
    // presale.transferLocked(address(0x0000000000000000000000000000000000000003), 1000000, teamUnlock);

    // TODO add advisors wallets, shares and unlock date
    uint256 adviseUnlock = 1564606800000; // 2019-08-01T00:00:00
    presale.transferLocked(address(0x0000000000000000000000000000000000000001), 1000000, adviseUnlock);

    // TODO add investors wallets, shares and unlock date
    uint256 investUnlock = 1561928400000; // 2019-07-01T00:00:00
    presale.transferLocked(address(0x0000000000000000000000000000000000000001), 1000000, investUnlock);

    // TODO Add presale contract operator
    // Transfer presale control
    presale.setOperator(address(0x0000000000000000000000000000000000000011));
  }

  function presale()
    public
    view
    returns(address)
  {
    return presale_;
  }

  function token()
    public
    view
    returns(address)
  {
    return token_;
  }

  function treasure()
    public
    view
    returns(address)
  {
    return treasure_;
  }
}
