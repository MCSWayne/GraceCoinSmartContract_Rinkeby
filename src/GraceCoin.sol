pragma solidity ^0.4.11;

contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() {
    owner = msg.sender;
  }

  function setCompleted(uint completed) restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

contract Ownable {
  address public owner;
  /** 
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = 0xf324D0588A8575877062842361a314A40AA1AD4B;
  }
  /**
   * @dev Throws if called by any account other than the owner. 
   */
  modifier onlyOwner() {
    assert (msg.sender == owner);
    _;
  }
  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();
  bool public paused = true;
  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    assert(paused!=true);
    _;
  }
  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    assert(paused==true);
    _;
  }
  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }
  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
/*  ERC 20 token */
contract StandardToken is Token, Pausable{
    function transfer(address _to, uint256 _value) whenNotPaused returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
    function transferFrom(address _from, address _to, uint256 _value) whenNotPaused returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

contract ethPausable is Ownable {
  event ethPause();
  event ethUnpause();
  bool public ethpaused = true;
  modifier ethwhenNotPaused() {
    assert(ethpaused!=true);
    _;
  }
  modifier ethwhenPaused {
    assert(ethpaused==true);
    _;
  }
  function ethpause() onlyOwner ethwhenNotPaused returns (bool) {
    ethpaused = true;
    ethPause();
    return true;
  }
  function ethunpause() onlyOwner ethwhenPaused returns (bool) {
    ethpaused = false;
    ethUnpause();
    return true;
  }
}

contract GraceCoin is StandardToken, SafeMath, ethPausable {
    string public constant name = "Grace Coin";
    string public constant symbol = "GRACE";
    uint256 public constant decimals = 8;
    string public version = "1.0";
    address public G2UFundDeposit;
    address public ETHFundDeposit;
    address public GraceFund;
    uint256 public constant G2Ufund = 6300*10000*10**decimals;
    uint256 public buyExchangeRate = 1*10**8; // per 1 ETH buy 1 Grace Coin  
    uint256 public sellExchangeRate = 1*10**8; // per 1 Grace Coin buy 1 ETH
    uint256 public constant ETHfund= 2100*10000*10**decimals;
    event LogRefund(address indexed _to, uint256 _value);
    event CreateBAT(address indexed _to, uint256 _value);
    function GraceCoin()
    {
      G2UFundDeposit = 0x9131332541BE541f14a36Fa285D4B28d80D00365;
      ETHFundDeposit = 0x6fa5de2663660BCB161CDF69583E1189373849de;
      totalSupply = G2Ufund+ETHfund;
      balances[G2UFundDeposit] = G2Ufund;
      balances[ETHFundDeposit] = ETHfund;
      CreateBAT(G2UFundDeposit, G2Ufund);
    }
    function setBuyExchangeRate(uint rate) returns(uint){
        assert(msg.sender==owner);
        buyExchangeRate = rate;
        return rate;
    }
    function setSellExchangeRate(uint rate) returns(uint){
        assert(msg.sender==owner);
        sellExchangeRate = rate;
        return rate;
    }
    function buyCoins() ethwhenNotPaused payable external {
        uint256 tokens = safeMult(msg.value, buyExchangeRate)/(10**18); 
        assert(balances[ETHFundDeposit]>=tokens);
        balances[ETHFundDeposit] -= tokens;
        balances[msg.sender] += tokens;
        Transfer(ETHFundDeposit, msg.sender, tokens);
    }
    function sellCoins(uint G2Uamount) ethwhenNotPaused payable external {
        assert(balances[msg.sender] >= G2Uamount);
        uint256 etherAmount = safeMult(G2Uamount,sellExchangeRate)*100;
        assert(etherAmount <= this.balance);
        msg.sender.transfer(etherAmount);
        balances[msg.sender] = safeSubtract(balances[msg.sender],G2Uamount);
        Transfer(msg.sender, ETHFundDeposit, G2Uamount);
    }
    function getBalance() constant returns(uint){
        return this.balance;  
    }
    function getEther(uint balancesNum){
        assert(msg.sender == G2UFundDeposit);
        assert(balancesNum <= this.balance);
        G2UFundDeposit.transfer(balancesNum);
    }
    function putEther() payable returns(bool){
        return true;
    }
    function graceTransfer(address _to, uint256 _value) returns (bool success) {
      assert(msg.sender==G2UFundDeposit||msg.sender==ETHFundDeposit||msg.sender==owner);
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }
}
