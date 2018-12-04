pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol';
import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

import './Token.sol';

contract Presale {
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    Token private token_;

    // Contract operator address
    address private operator_;
    // Contract treasure
    address private treasure_;
    // Maximum token supply which could be created via Presale process
    uint256 public maxSupply;
    // Timestamp when token release is enabled
    uint256 private releaseTime_;
    // Time when bonus lock is disabled
    uint256 private unlockTime_;

    constructor(
      address _operator,
      address _treasure,
      uint256 _releaseTime,
      uint256 _unlockTime,
      uint256 _maxSupply
    )
      public
    {
      require(_operator != address(0));
      require(_treasure != address(0));
      require(_releaseTime > block.timestamp);
      require(_unlockTime > _releaseTime);
      require(_maxSupply > 0);

      operator_ = _operator;
      treasure_ = _treasure;
      releaseTime_ = _releaseTime;
      unlockTime_ = _unlockTime;
      maxSupply = _maxSupply;
    }

    // Events
    event Locked(address receiver, uint256 amount, address lock);
    event Transferred(address receiver, uint256 amount);
    event Received(address sender, uint256 amount);

    // Modifiers
    modifier operatorOnly() {
      require(msg.sender == operator_);
      _;
    }

    // Methods

    // Increase balance from ICO Cab address. _receiver is address defined in
    // the cab as token's beneficiary.
    function increaseBalance()
      public
      payable
    {
      treasure_.transfer(msg.value);

      emit Received(msg.sender, msg.value);
    }

    function transfer(address _to, uint256 _tokens, uint256 _bonus)
      public
      operatorOnly
    {
      require(_to != address(0));
      require(token_.totalSupply().add(_tokens).add(_bonus) <= maxSupply);

      token_.mint(_to, _tokens);

      // Send locked bonuses to timelock contract
      if (_bonus > 0) {
        _transferLocked(_to, _bonus, unlockTime_);
      }

      emit Transferred(_to, _tokens);
    }

    function _transferLocked(address _to, uint256 _tokens, uint256 _unlockTime)
      internal
    {
      TokenTimelock lock = new TokenTimelock(token_, _to, _unlockTime);
      token_.mint(lock, _tokens);
      emit Locked(_to, _tokens, lock);
    }

    function transferLocked(address _to, uint256 _tokens, uint256 _unlockTime)
      public
      operatorOnly
    {
      require(_to != address(0));
      require(_tokens > 0);
      require(token_.totalSupply().add(_tokens) <= maxSupply);
      require(_unlockTime >= unlockTime_);

      _transferLocked(_to, _tokens, _unlockTime);
    }

    function setOperator(address _operator)
      public
      operatorOnly
    {
      require(_operator != address(0));

      operator_ = _operator;
    }

    function setToken(address _token)
      public
    {
      require(token_ == address(0));
      require(_token != address(0));

      token_ = Token(_token);
    }

    // Anyone could call release method if the release date is arrived.
    function release()
      public
    {
      require(releaseTime_ > block.timestamp);

      token_.release();
    }

    function token()
      public
      view
      returns(address)
    {
      return token_;
    }

    function releaseTime()
      public
      view
      returns(uint256)
    {
      return releaseTime_;
    }

    function unlockTime()
      public
      view
      returns(uint256)
    {
      return unlockTime_;
    }
}
