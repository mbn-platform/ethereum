pragma solidity 0.5.6;

contract ICollectableCalls {
  function makeCall(uint256 _n)
    internal
    returns(bytes memory);

  function _getTarget(uint _n)
    internal
    view
    returns(address);

  function _getCallData(uint _n)
    internal
    view
    returns(bytes memory);

  function _hasExpectation(uint _n)
    internal
    view
    returns(bool);

  function _getValue(uint _n)
    internal
    view
    returns(uint);

  function _getExpectation(uint _n)
    internal
    view
    returns(bytes32);
}
