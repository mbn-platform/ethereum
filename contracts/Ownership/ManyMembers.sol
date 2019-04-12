pragma solidity 0.5.6;

import './IManyMembers.sol';

// Need to be ownable
contract ManyMembers is IManyMembers {
  mapping(address => bool) private members_;

  event MemberAdded(address indexed member);
  event MemberRemoved(address indexed member);

  modifier memberOnly() {
    require(members_[msg.sender], 'member_access');
    _;
  }

  modifier ownerOnly() {
    require(_isOwner(msg.sender), 'owner_access');
    _;
  }

  modifier ownerOrMemberOnly() {
    require(_isOwner(msg.sender) || _isMember(msg.sender), 'owner_or_member_access');
    _;
  }

  function _isMember(address _sender)
    internal
    view
    returns(bool)
  {
    return members_[_sender];
  }

  function isMember(address _sender)
    public
    view
    returns(bool)
  {
    return _isMember(_sender);
  }

  function addMember(address _member)
    public
    ownerOnly
  {
    require(_member != address(0), 'member_req');

    members_[_member] = true;

    emit MemberAdded(_member);
  }

  function removeMember(address _member)
    public
    ownerOnly
  {
    require(_member != address(0), 'member_req');

    members_[_member] = false;

    emit MemberRemoved(_member);
  }
}
