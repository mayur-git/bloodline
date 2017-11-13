// Wow Internet Labz Pvt. Ltd. (connect@wowlabz.com)

pragma solidity ^0.4.15;

import './token/StandardToken.sol';
import './token/BurnableToken.sol';
import './ownership/Ownable.sol';
import './math/SafeMath.sol';

/**
 * The Bloodline BLC token (RBC) has a fixed supply and restricts the ability
 * to transfer tokens until the owner has called the enableTransfer()
 * function.
 *
 * The owner can associate the token with a token sale contract. In that
 * case, the token balance is moved to the token sale contract, which
 * in turn can transfer its tokens to contributors to the sale.
 */
contract BloodlineBLCToken is StandardToken, BurnableToken, Ownable {

    // Constants
    string  public constant name = "Bloodline BLC Token";
    string  public constant symbol = "BLC";
    uint8   public constant decimals = 18;
    uint256 public constant INITIAL_SUPPLY      = 200000000 * (10 ** uint256(decimals));
    uint256 public constant CROWDSALE_ALLOWANCE =  100000000 * (10 ** uint256(decimals));
    uint256 public constant ADMIN_ALLOWANCE     =  100000000 * (10 ** uint256(decimals));
    uint256 public constant BLC_ALLOWANCE       = 100 * (10 ** uint256(decimals));
    uint256 public constant DONATION_PRICE      = 50 * (10 ** uint256(decimals));

    // Properties
    uint256 public crowdSaleAllowance;      // the number of tokens available for crowdsales
    uint256 public adminAllowance;          // the number of tokens available for the administrator
    address public crowdSaleAddr;           // the address of a crowdsale currently selling this token
    address public adminAddr;               // the address of a crowdsale currently selling this token
    bool    public transferEnabled = false; // indicates if transferring tokens is enabled or not

    // Mapping of user account address to specific request id and it's status
    mapping (address => mapping (bytes32 => bool)) bloodRequests;

    // Modifiers
    modifier onlyWhenTransferEnabled() {
        if (!transferEnabled) {
            require(msg.sender == adminAddr || msg.sender == crowdSaleAddr);
        }
        _;
    }

    /**
     * The listed addresses are not valid recipients of tokens.
     *
     * 0x0           - the zero address is not valid
     * this          - the contract itself should not receive tokens
     * owner         - the owner has all the initial tokens, but cannot receive any back
     * adminAddr     - the admin has an allowance of tokens to transfer, but does not receive any
     * crowdSaleAddr - the crowdsale has an allowance of tokens to transfer, but does not receive any
     */
    modifier validDestination(address _to) {
        require(_to != address(0x0));
        require(_to != address(this));
        require(_to != owner);
        require(_to != address(adminAddr));
        require(_to != address(crowdSaleAddr));
        _;
    }

    /**
     * Constructor - instantiates token supply and allocates balanace of
     * to the owner (msg.sender).
     */
    function BloodlineBLCToken(address _admin) {
        // the owner is a custodian of tokens that can
        // give an allowance of tokens for crowdsales
        // or to the admin, but cannot itself transfer
        // tokens; hence, this requirement
        require(msg.sender != _admin);

        totalSupply = INITIAL_SUPPLY;
        crowdSaleAllowance = CROWDSALE_ALLOWANCE;
        adminAllowance = ADMIN_ALLOWANCE;

        // mint all tokens
        balances[msg.sender] = totalSupply;
        Transfer(address(0x0), msg.sender, totalSupply);

        adminAddr = _admin;
        approve(adminAddr, adminAllowance);
    }

    /**
     * Associates this token with a current crowdsale, giving the crowdsale
     * an allowance of tokens from the crowdsale supply. This gives the
     * crowdsale the ability to call transferFrom to transfer tokens to
     * whomever has purchased them.
     *
     * Note that if _amountForSale is 0, then it is assumed that the full
     * remaining crowdsale supply is made available to the crowdsale.
     *
     * @param _crowdSaleAddr The address of a crowdsale contract that will sell this token
     * @param _amountForSale The supply of tokens provided to the crowdsale
     */
    function setCrowdsale(address _crowdSaleAddr, uint256 _amountForSale) external onlyOwner {
        require(!transferEnabled);
        require(_amountForSale <= crowdSaleAllowance);

        // if 0, then full available crowdsale supply is assumed
        uint amount = (_amountForSale == 0) ? crowdSaleAllowance : _amountForSale;

        // Clear allowance of old, and set allowance of new
        approve(crowdSaleAddr, 0);
        approve(_crowdSaleAddr, amount);

        crowdSaleAddr = _crowdSaleAddr;
    }

    /**
     * Enables the ability of anyone to transfer their tokens. This can
     * only be called by the token owner. Once enabled, it is not
     * possible to disable transfers.
     */
    function enableTransfer() external onlyOwner {
        transferEnabled = true;
        approve(crowdSaleAddr, 0);
        approve(adminAddr, 0);
        crowdSaleAllowance = 0;
        adminAllowance = 0;
    }

    /**
     * Overrides ERC20 transfer function with modifier that prevents the
     * ability to transfer tokens until after transfers have been enabled.
     */
    function transfer(address _to, uint256 _value) public onlyWhenTransferEnabled validDestination(_to) returns (bool) {
        return super.transfer(_to, _value);
    }

    /**
     * Overrides ERC20 transferFrom function with modifier that prevents the
     * ability to transfer tokens until after transfers have been enabled.
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyWhenTransferEnabled validDestination(_to) returns (bool) {
        bool result = super.transferFrom(_from, _to, _value);
        if (result) {
            if (msg.sender == crowdSaleAddr)
                crowdSaleAllowance = crowdSaleAllowance.sub(_value);
            if (msg.sender == adminAddr)
                adminAllowance = adminAllowance.sub(_value);
        }
        return result;
    }

    /**
     * Overrides the burn function so that it cannot be called until after
     * transfers have been enabled.
     *
     * @param _value    The amount of tokens to burn in mini-RBC
     */
    function burn(uint256 _value) public {
        require(transferEnabled || msg.sender == owner);
        super.burn(_value);
        Transfer(msg.sender, address(0x0), _value);
    }

    /**
     * Transfers BLC_ALLOWANCE to every new user
     */
    function registerUser() public returns (uint256) {
        address _from = adminAddr;
        address _to = msg.sender;
        if(super.transferFrom(_from, _to, BLC_ALLOWANCE)) {
            return balances[msg.sender];
        }
    }

    /**
     * Transfers DONATION_PRICE to Donor
     */
    function confirmDonation(address _to) public returns (uint256) {
        address _from = msg.sender;
        if(super.transferFrom(_from, _to, DONATION_PRICE)) {
            return balances[msg.sender];
        }
    }

    /**
     * Check if requester has sufficient BLC balance
     * Create request and return id of new request
     */
    function createBloodRequest() public returns (bytes32){
        if(balances[msg.sender] >= DONATION_PRICE) {
            bytes32 id = keccak256(msg.sender, now);
            bloodRequests[msg.sender][id] = true;
            return id;
        } else {
            return 0;
        }
    }

    /**
     * Check if request is still open
     * Close request
     *
     * @param _id    The id of the request to be closed
     */
    function closeBloodRequest(bytes32 _id) public returns (bool) {
        if(!bloodRequests[msg.sender][_id]) {
            bloodRequests[msg.sender][_id] = false;
            return true;
        }
    }

}
