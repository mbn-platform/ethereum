pragma solidity 0.5.6;

import 'openzeppelin-solidity/contracts/token/ERC20/IERC20.sol';

import '../Voting/Votable.sol';
import '../Ownership/SingleOwner.sol';

contract Erc20Manager is Votable, SingleOwner {
  IERC20 public token;

  bytes[] private proposals_;

  constructor(address _owner, address _token)
    public
    SingleOwner(_owner)
  {
    require(_token != address(0), 'token_req');
    token = IERC20(_token);
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
    (bool success, bytes memory returndata) = address(token).call(
      proposals_[_n - 1]
    );
    require(success);

    if (returndata.length > 0) { // Return data is optional
      require(abi.decode(returndata, (bool)));
    }
  }
}
