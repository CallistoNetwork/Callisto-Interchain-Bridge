const Web3 = require('web3');
const BnbApiClient = require('@binance-chain/javascript-sdk');
const axios = require('axios');

// Binance settings
const BINANCE_ASSET = 'CLOBNB';
const BINANCE_NETWORK = process.env.BINANCE_NETWORK || 'testnet';
const BINANCE_PK = process.env.BINANCE_PK || '';
const BINANCE_API = process.env.BINANCE_API || 'https://testnet-dex.binance.org/';
const bnbClient = new BnbApiClient(BINANCE_API);
// Callisto settings
const CALLISTO_ADDRESS = process.env.CALLISTO_ADDRESS || '';
const CALLISTO_PK = process.env.CALLISTO_PK || '';

bnbClient.chooseNetwork(BINANCE_NETWORK); // or this can be "mainnet"
bnbClient.setPrivateKey(BINANCE_PK);
bnbClient.initChain();

const web3 = new Web3('http://localhost:8545');

// Binance

const getSequence = async (fromAddress) => {
	const httpClient = axios.create({ baseURL: BINANCE_API });
	const sequenceURL = `${BINANCE_API}api/v1/account/${fromAddress}/sequence`;
	let res = await httpClient.get(sequenceURL);
	return res.data.sequence || 0;
};

const sendCLOBNB = async (fromAddress, toAddress, amount, sequence) => {
	return await bnbClient.transfer(fromAddress, toAddress, amount, BINANCE_ASSET, 'Enjoy Callisto Network', sequence);
};

const mintCLOBNB = async (fromAddress, amount) => {
	return await bnbClient.TokenManagement.mint(fromAddress, BINANCE_ASSET, amount);
};

const burnCLOBNB = async (fromAddress, amount) => {
	return await bnbClient.TokenManagement.burn(fromAddress, BINANCE_ASSET, amount);
};

const swapCLOtoBNB = async (toAddress, amount) => {
	const fromAddress = bnbClient.getClientKeyAddress();
	try {
		await mintCLOBNB(fromAddress, amount);
		const sequence = await getSequence(fromAddress);
		await sendCLOBNB(fromAddress, toAddress, amount, sequence);
	} catch (error) {
		console.log(error);
	}
};

// Callisto

const swapBNBtoCLO = async (toAddress, amount) => {
	// Callist code ...
	const fromAddress = bnbClient.getClientKeyAddress();
	try {
		await burnCLOBNB(fromAddress, amount);
	} catch (error) {
		console.log(error);
	}
};
