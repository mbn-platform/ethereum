pragma solidity 0.5.6;

contract Privileged {
  /// List of privileged users who can transfer token before release
  mapping(address => bool) privileged;

  function isPrivileged(address _addr)
    public
    view
    returns(bool)
  {
    return privileged[msg.sender];
  }

  function _setPrivileged(address _addr)
    internal
  {
    require(_addr != address(0), 'addr_req');

    privileged[_addr] = true;
  }

  function _setUnprivileged(address _addr)
    internal
  {
    privileged[_addr] = false;
  }
}
