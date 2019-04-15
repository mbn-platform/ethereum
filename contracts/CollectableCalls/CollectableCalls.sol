pragma solidity 0.5.6;

import './ICollectableCalls.sol';

contract CollectableCalls is ICollectableCalls {
  function makeCall(uint256 _n)
    internal
    returns(bytes memory)
  {
    (bool success, bytes memory result) = _getTarget(_n).call.value(
      _getValue(_n)
    )(
      _getCallData(_n)
    );

    require(success, 'call_succeed');

    if (_hasExpectation(_n) == false) {
      return result;
    }

    require(keccak256(result) == _getExpectation(_n), 'expectation_fulfilled');
    return result;
  }

  // Getters

  function getTarget(uint _n)
    public
    view
    returns(address)
  {
    return _getTarget(_n);
  }

  function getCallData(uint _n)
    public
    view
    returns(bytes memory)
  {
    return _getCallData(_n);
  }

  function hasExpectation(uint _n)
    public
    view
    returns(bool)
  {
    return _hasExpectation(_n);
  }

  function getExpectation(uint _n)
    public
    view
    returns(bytes32)
  {
    return _getExpectation(_n);
  }

  function getValue(uint _n)
    public
    view
    returns(uint)
  {
    return _getValue(_n);
  }

}
