pragma solidity 0.5.6;

import '../Voting/Votable.sol';
import '../Ownership/SingleOwner.sol';

contract ContractManager is Votable, SingleOwner {
  address public target;

  bytes[] private proposals_;

  constructor(address _owner, address _target)
    public
    SingleOwner(_owner)
  {
    require(_target != address(0), 'target_req');

    target = _target;
  }

  // Events
  event Transferred(address receiver, uint256 amount);

  // Methods
  function proposeCall(bytes memory _data)
    public
    voterOnly
    nonReentrant
    returns(uint256)
  {
    proposals_.push(_data);
    uint256 n = proposals_.length;

    super.initVoting(n);
    return n;
  }

  function isAccepted(uint256, uint256 _votes, uint256 _totalPower)
    internal
    view
    returns(bool)
  {
    return _votes >= _totalPower / 2 + 1;
  }

  function applyProposal(uint256 _n)
    internal
  {
    (bool success, bytes memory returndata) = target.call(
      proposals_[_n - 1]
    );
    require(success);

    if (returndata.length > 0) { // Return data is optional
      require(abi.decode(returndata, (bool)));
    }
  }
}
