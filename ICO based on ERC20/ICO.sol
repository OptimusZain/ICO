pragma solidity ^0.5.3;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns(uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);
}

contract myERC20 is IERC20{
    
    address public creator;
    address payable public recipient;
    
    mapping (address => mapping (address => uint)) public allowed;
    
    mapping (address => uint) public balances;
    
    uint public _totalSupply = 50000;
    
    // name, symbol decimal
    
    string public name = "BLTKRN";
    string public symbol = "BJ";
    uint public decimal = 0;
    
    constructor(address payable _recipient) public{
        creator = msg.sender;
        recipient = _recipient;
        balances[creator] = _totalSupply;
    }

    function totalSupply() external view returns(uint256){
        return _totalSupply;
    }
    
    function balanceOf(address account) external view returns(uint256){
        return balances[account];
    }
    
    function transfer(address _recipient, uint256 amount) public returns (bool){
        
        require(amount > 0 && balances[msg.sender] >= amount, "Insufficient funds!");
        balances[msg.sender] -= amount;
        balances[_recipient] += amount;

        emit Transfer(msg.sender, _recipient, amount);
        
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool){
        require(amount > 0 && balances[msg.sender] >= amount, "Insufficient funds!");
        
        allowed[msg.sender][spender] += amount; 

        emit Approval(msg.sender, spender, amount);
        
        return true;        
    }
    
     function allowance(address owner, address spender) external view returns (uint256){
            return allowed[owner][spender];
     }
     
     function transferFrom(address _from, address _to, uint256 amount) public returns(bool){
         require(amount > 0 && balances[msg.sender] >= amount && allowed[_from][_to] >= amount, "Insufficient funds!");
         
         balances[_from] -= amount;
         balances[_to] += amount;
         allowed[_from][_to] -= amount;
         
        emit Transfer(_from, _to, amount);
         
         return true;
     }
    
}

contract myICO is myERC20{

    // Admin of the contract
    address public administrator;
    
    // the account that's going to receive funds
    address payable public DepositAcc;
    
    // Total Funds received
    uint public receivedFunds;

    //0.01 ether = 1 token
    uint public TokenPrice = 10000000000000000;
    
    // 500 ether
    uint public ICOgoal = 500000000000000000000;
    
    // 10 ether per investment
    uint public maxInvest = 10000000000000000000;
    
    // 0.01 ether per investment
    uint public minInvest = 10000000000000000;
    
    // ICO Statuses
    
    enum status {inactive, active, stopped, completed}
    
    status public ICOstatus;
    
    // ICO timing
    
    uint public ICOstarttime = now;
    
    uint public ICOendtime = ICOstarttime + 432000;
    
    uint public tradeStarttime = ICOstarttime;
    
    constructor(address payable _DepositAcc) public{
        administrator = msg.sender;
        DepositAcc = _DepositAcc;
    }

    modifier adminOnly{
        if(administrator == msg.sender){
            _;
        }
    }
    
    function stopICO() public{
        ICOstatus = status.stopped;
    }
    
    function startICO() public{
        ICOstatus = status.active;
    }
    
    function getICOstatus() public view returns(status){
        
        if(ICOstatus == status.stopped)
            return status.stopped;
        else if(block.timestamp >= ICOstarttime && block.timestamp <= ICOendtime)
            return status.active;
        else if(block.timestamp < ICOstarttime)
            return status.inactive;
        else
            return status.completed;
    }
    
    function Investing() payable public returns(bool){
        
        require(msg.value + receivedFunds <= ICOgoal, "Goal acheived, not accepting more investment.");
        require(msg.value >= minInvest && msg.value <= maxInvest);
        
        recipient.transfer(msg.value);
        
        receivedFunds += msg.value;
        
        return true;
    } 
    
    function burn() adminOnly public{
        ICOstatus = getICOstatus();
        
        require(ICOstatus == status.completed, "ICO hasnt finished yet!");
        
        balances[creator] = 0;
    }
    
    function transfer(address _recipient, uint256 amount) public returns (bool){
        require(block.timestamp >= tradeStarttime,"ICO is in Progress");
        
        super.transfer(_recipient, amount);
        
        return true;
    }
    
     function transferFrom(address _from, address _to, uint256 amount) public returns(bool){
         require(block.timestamp >= tradeStarttime,"ICO is in Progress");
         
         super.transferFrom(_from, _to, amount);
         
         return true;
     }

    
}