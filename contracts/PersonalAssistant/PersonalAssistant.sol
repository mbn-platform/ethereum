pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol';

import '../Ownership/ManyOwners.sol';
import '../Ownership/Minions.sol';

contract PersonalAssistant is ManyOwners, Minions, ReentrancyGuard {
  bool public isLocked;

  constructor(address _owner)
    public
  {
    require(_owner != address(0), 'owner_req');

    super._addOwner(_owner);
  }

  modifier unlockedOnly() {
    require(isLocked == false, 'unlocked_only');
    _;
  }

  function ()
    external
    payable
  {
    require(msg.data.length == 0, 'data_empty');
  }

  function lock()
    public
    ownerOnly
  {
    isLocked = true;
  }

  function unlock()
    public
    ownerOnly
  {
    isLocked = false;
  }

  /// Call _target contract method with _data and send 0 weis
  function write(address _target, bytes memory _data)
    public
    returns(bytes memory)
  {
    return write(_target, 0, _data);
  }

  /// Call _target contract method with _data and send _value weis
  function write(address _target, uint256 _value, bytes memory _data)
    public
    payable
    ownerOrMinionOnly
    nonReentrant
    unlockedOnly
    returns(bytes memory)
  {
    (bool success, bytes memory returndata) = _target.call.value(_value)(_data);
    require(success);

    return returndata;
  }

  /// Read contract state method using this contract as sender
  function read(address _target, bytes memory _data)
    public
    view
    returns(bytes memory)
  {
    (bool success, bytes memory returndata) = _target.staticcall(_data);
    require(success);

    return returndata;
  }
}
