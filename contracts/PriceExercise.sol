pragma solidity ^0.6.6;

// It’s import statements should contain a combination of the existing PriceConsumerV3 and the APIConsumer contract contracts
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.6/vendor/Ownable.sol";

contract PriceExercise is ChainlinkClient {


    AggregatorV3Interface internal priceFeed;
    address private oracle;
    bool public priceFeedGreater;
    bytes32 private jobId;
    int256 public storedPrice;
    uint256 private fee;

    // constructor function should contain a combination of the existing PriceConsumerV3 and the APIConsumer contract contract logic, including taking in the _priceFeed address parameter 
    // like the PriceConsumerV3 contract does, as well as all the parameters in the existing APIConsumer contract
    constructor(address _oracle, string memory _jobId, uint256 _fee, address _link, address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        // oracle = 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e;
        // jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        // fee = 0.1 * 10 ** 18; // 0.1 LINK
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;        
    }

    // The ‘requestPriceData’ function should request the BTC price from cryptocompare
    function requestPriceData() public returns (bytes32 requestId){
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
        
        request.add("get", "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=USD");

        // remembering to set the ‘path’ to the current price returned in the JSON
        request.add("path", "RAW.BTC.USD.PRICE");

        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }

    // take in 2 parameters, a bytes32 type field called _requestId, and an int256 (not uint256) called _price. 
    function fulfill(bytes32 _requestId, int256 _price) public {
        //store the obtained price in the storedPrice variable,
        storedPrice = _price;
        //then compare the returned value from cryptocompare to the current price of the BTC/USD price feed
       
        if (getLatestPrice() > storedPrice) {
           priceFeedGreater = true;
        } else {
           priceFeedGreater = false;
        }
    }

    // should match what’s in the PriceConsumerV3 contract
    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        return price;
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }    
}