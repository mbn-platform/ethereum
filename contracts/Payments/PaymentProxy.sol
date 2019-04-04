pragma solidity 0.5.6;

contract PaymentProxy {
  address payable public target;

  uint256 private ownersCount_;
  mapping(address => bool) private owners_;
  mapping(address => uint256) private suggestions_;
  mapping(address => mapping(address => bool)) private status_;

  constructor() internal {}

  function() external payable {}

  modifier ownerOnly() {
    require(owners_[msg.sender] == true, 'ownerAccess');
    _;
  }

  modifier targetOnly() {
    require(target != address(0), 'target_only');
    _;
  }

  modifier nonTargetOnly() {
    require(target == address(0), 'non_target_only');
    _;
  }

  function _addOwner(address owner)
    internal
  {
    owners_[owner] = true;
    ownersCount_ += 1;
  }

  function suggest(address payable _target)
    public
    ownerOnly
    nonTargetOnly
  {
    require(_target != address(0), 'target_req');
    require(status_[_target][msg.sender] == false, 'no_double');

    if ((suggestions_[_target] + 1) > (ownersCount_ / 2)) {
      target = _target;
    }
    else {
      status_[_target][msg.sender] = true;
      suggestions_[_target] += 1;
    }
  }

  function getSuggestions(address _target)
    public
    view
    returns(uint256)
  {
    return suggestions_[_target];
  }

  function withdraw()
    public
    targetOnly
  {
    target.transfer(address(this).balance);
  }
}
