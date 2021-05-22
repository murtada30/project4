pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false

    //struct used for all registered airlines
    struct AirLine {
        address airLineAddress;
        bool isRegestered;
 
    }

    //struct used for alirlines who paied the fees
    struct PaymentAirLine {
        address airLineAddress;
        bool isPayed;
 
    }
    //defining mapping for above
    mapping(address => AirLine) private regesteredAirLines;
    mapping(address => PaymentAirLine) private paidAirlines;


    //needed for voting process  
    address[] multiCalls = new address[](0);
    mapping(address => uint) private voteCount;


// Insurance Resource
    uint public insuranceCount;
    struct Insurance {
        uint id;
        uint flightId;
        uint amountPaid;
        address owner;
    }

    //capturing insurance information using diffrent ways
    mapping(uint => Insurance) public insurancesById;
    mapping(address => uint[]) private passengerToInsurances;
    mapping(uint => uint[]) private flightToInsurances;
    mapping(address => uint) public creditedAmounts;


    mapping(bytes32 => uint) flightKeyToId;
    mapping(address => uint256) private authorizedCaller;


// defininsg events
    event InsurancePurchased(uint id);
    event InsuranceCredited(uint id);
    event AmountWithdrawn(address _address, uint amountWithdrawn);
    event AuthorizedContract(address authContract);





    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                ) 
                                public 
    {
        contractOwner = msg.sender;
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational() 
                            public 
                            view 
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    // a function to identify if a given airline is regestered
    function isRegisteredAirline(address airLineAddress)external requireIsOperational returns(bool)
    {
        return (regesteredAirLines[airLineAddress].isRegestered== true);

    }



    function getMultiCall() external requireIsOperational returns(uint){
        return multiCalls.length;
    }

    // required to count votes
     function addVoterCounter(address airline) external requireIsOperational{
        uint vote = voteCount[airline];
        voteCount[airline] = vote.add(1); 
    }

//returning vote counts per airline 
    function getVoterCounter(address airline) external requireIsOperational returns(uint){
        return voteCount[airline];
        
    }

    //retrive insurance records using diffrent ways

    function getInsurancesByFlight(uint _flightId)
    requireIsOperational
    public
    view
    returns (uint [])
    {
        return flightToInsurances[_flightId];
    }

    function getInsurance(uint _id)
    requireIsOperational
    public
    view
    returns (uint id, uint flightId, uint amountPaid, address owner)
    {
        Insurance memory insurance = insurancesById[_id];
        id = insurance.id;
        flightId = insurance.flightId;
        amountPaid = insurance.amountPaid;
        owner = insurance.owner;
    }

function authorizeCaller
                            (
                                address contractAddress
                            )
                            external
                            requireContractOwner
    {
        authorizedCaller[contractAddress] = 1;
        emit AuthorizedContract(contractAddress);
    }
    
    // find if a given airline is a registered airline
function isAirline
                            (
                                address account
                            )
                            external
                            
                            returns(bool)
    {


        return (regesteredAirLines[account].isRegestered== true);
    }

// record the registeration for a given aireline
    function registerPayment
                            (
                                address account
                            )
                            external
                            
    {


        paidAirlines[account]=PaymentAirLine(account,true);
    }

// find if a given airline has paied the fees
    function isPaidAirline
                            (
                                address account
                            )
                            external
                            returns(bool)
    {


        return (paidAirlines[account].isPayed == true);

    }

   


    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (   
                                address LocalAirLineAddress
                            )
                            external
                            requireIsOperational
                            
    {
        regesteredAirLines[LocalAirLineAddress]=AirLine(LocalAirLineAddress,true);
        multiCalls.push(LocalAirLineAddress);

    }

// passingers

/**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
    (uint _flightId, address _owner,uint _amountPaid)
    requireIsOperational
    external
    {
        insuranceCount = insuranceCount.add(1);
        insurancesById[insuranceCount] = Insurance({id: insuranceCount,flightId: _flightId, amountPaid: _amountPaid,owner: _owner});
        flightToInsurances[_flightId].push(insuranceCount);
        passengerToInsurances[_owner].push(insuranceCount);
        emit InsurancePurchased(insurancesById[insuranceCount].id);
    }

    function getFlightIdByKey(bytes32 _key)
    requireIsOperational
    external
    view
    returns (uint)
    {
        return flightKeyToId[_key];
    }

   

    

    /**
     *  @dev Credits payouts to insurees, multiply by 1.5
    */
    function creditInsurance
    (uint _id, uint _amountToCredit)
    requireIsOperational
    public
    {
        Insurance memory insurance = insurancesById[_id];
        creditedAmounts[insurance.owner] = creditedAmounts[insurance.owner].add(_amountToCredit.mul(3).div(2));
        emit InsuranceCredited(_id);
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */

    function pay
    (uint _amountToWithdraw, address _address)
    requireIsOperational
    public
    payable
    {
        creditedAmounts[_address] = creditedAmounts[_address].sub(_amountToWithdraw);
        _address.transfer(_amountToWithdraw);
        emit AmountWithdrawn(_address, _amountToWithdraw);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string  flight,
                            uint256 timestamp
                        )
                        
                        external
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }


}

