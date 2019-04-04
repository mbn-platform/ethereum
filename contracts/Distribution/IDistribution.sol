pragma solidity 0.5.6;

contract IDistribution {
  function getRate(uint256 time)
    public view returns(uint256);

  function transferTokens(address _to, uint256 _tokens, uint256 _locked)
    public payable returns(uint256);
}
