pragma solidity 0.5.6;

import './IDistribution.sol';

contract IStagedDistribution is IDistribution {
  function getStageByTime(uint256 time)
    public view returns(uint256,bool);

  function getStageStart(uint256 stage)
    public view returns(uint256);

  function getStageEnd(uint256 stage)
    public view returns(uint256);

  function getStageBonus(uint256 stage)
    public view returns(uint256);
}
