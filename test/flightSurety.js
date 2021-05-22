
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeCaller(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];
    let fundPrice = web3.utils.toWei("9", "ether");

    
    // ACT
    try {
        await config.flightSuretyApp.payRegistrationFee({from: newAirline,value: fundPrice});

        await config.flightSuretyApp.registerAirline(newAirline,true, {from: config.firstAirline});
    }
    catch(e) {


    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 

    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

  it(`(Only existing airline may register a new airline until there are at least four airlines registered`, async function () {

   // ARRANGE
   let airline1 = accounts[1];
   let airline2 = accounts[2];

   let fundPrice = web3.utils.toWei("10", "ether");


   
   

   
   try{
       await config.flightSuretyApp.payRegistrationFee({from: airline2,value: fundPrice});

       await config.flightSuretyApp.registerAirline(airline2,true,  {from: airline1});

       
   }catch(e){

   }

   let result = await config.flightSuretyData.isAirline.call(airline2); 

   // ASSERT
   assert.equal(result, false, "can not rigester airline, if calling (admin) airline is not rigestered ");
});

it(`(Registration of fifth and subsequent airlines requires multi-party consensus of 50% of registered airlines)`, async function () {

    // ARRANGE
    let airline1 = accounts[4];
    let airline2 = accounts[5];
    let airline3 = accounts[6];
    let airline4 = accounts[7];
 
    let fundPrice = web3.utils.toWei("10", "ether");

    
 
    
    try{
        
        await config.flightSuretyApp.payRegistrationFee({from: airline1,value: fundPrice});
        await config.flightSuretyApp.payRegistrationFee({from: airline2,value: fundPrice});
        await config.flightSuretyApp.payRegistrationFee({from: airline3,value: fundPrice});
        await config.flightSuretyApp.payRegistrationFee({from: airline4,value: fundPrice});
        let registration_status=await config.flightSuretyApp.registerAirline(airline1,true,  {from: config.owner});
        console.log(registration_status[0]);
        console.log(registration_status[1]);
        await config.flightSuretyApp.registerAirline(airline2,true,  {from: config.owner});
        await config.flightSuretyApp.registerAirline(airline3,true,  {from: config.owner});
        await config.flightSuretyApp.registerAirline(airline4,false,  {from: config.owner});


 
        
    }catch(e){
        console.error("Exception thrown", e);

    }
 
    let result1 = await config.flightSuretyData.isRegisteredAirline.call(airline1); 
    console.log(result1);

    let result2 = await config.flightSuretyData.isRegisteredAirline.call(airline2); 
    console.log(result2);

    let result3 = await config.flightSuretyData.isRegisteredAirline.call(airline3); 
    console.log(result3);

    let result4 = await config.flightSuretyData.isRegisteredAirline.call(airline4); 
    console.log(result4);

    


 
    // ASSERT
    assert.equal(result3, true, "trying multi-party consensus ");
 });
 
 it(`(Passengers may pay up to 1 ether for purchasing flight insurance.)`, async function () {

    // ARRANGE
    let passanger = accounts[10];
 
    let insurancePrice = web3.utils.toWei("1", "ether");

 
    
    try{
        


        await config.flightSuretyApp.purchaseInsurance(1,{from: passanger,value: insurancePrice});



    }catch(e){

        console.error("Exception thrown", e);

    }
    let result= await config.flightSuretyData.getInsurance(1);
 
    // ASSERT
    console.log(result[3]);
    assert.equal(result[3], passanger, "could not find insurance record");
 });

 

 

});
