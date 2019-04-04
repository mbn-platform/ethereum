pragma solidity 0.5.6;

contract IOwnable {
  function isOwner(address who)
    public view returns(bool);

  function _isOwner(address)
    internal view returns(bool);
}
