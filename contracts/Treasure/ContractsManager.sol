pragma solidity 0.5.6;

import '../Ownership/SingleOwner.sol';
import './VotableCalls/ManyTargetsCalls.sol';

contract ContractsManager is ManyTargetsCalls, SingleOwner {
  constructor(address _owner, address _target)
    public
    SingleOwner(_owner)
    ManyTargetsCalls()
  {}
}
