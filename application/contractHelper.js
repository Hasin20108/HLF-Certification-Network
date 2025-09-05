const fs = require('fs');
const yaml = require('js-yaml');
const { Wallets, Gateway } = require('fabric-network');
let gateway;


async function getContractInstance() {
	
	// A gateway defines which peer is used to access Fabric network
	gateway = new Gateway();
	
	// A wallet is where the credentials to be used for this transaction exist
	const walletPath = './identity/mhrd';
	const wallet = await Wallets.newFileSystemWallet(walletPath);
	
	// What is the username of this Client user accessing the network?
	const fabricUserName = 'MHRD_ADMIN';
	
	// Load connection profile; will be used to locate a gateway; The CCP is converted from YAML to JSON.
	let connectionProfile = yaml.load(fs.readFileSync('./connection-profile-mhrd.yaml', 'utf8'));
	
	// Set connection options; identity and wallet
	let connectionOptions = {
		wallet: wallet,
		identity: fabricUserName,
		discovery: { enabled: true, asLocalhost: true }
	};
	
	// Connect to gateway using specified parameters
	console.log('.....Connecting to Fabric Gateway');
	await gateway.connect(connectionProfile, connectionOptions);
	
	// Access certification channel
	console.log('.....Connecting to channel - certificationchannel');
	const channel = await gateway.getNetwork('certificationchannel');
	
	// Get instance of deployed Certnet contract
	// The contract name is omitted as there is only one contract in the chaincode
	console.log('.....Connecting to Certnet Smart Contract');
	return channel.getContract('certnet');
}

function disconnect() {
	console.log('.....Disconnecting from Fabric Gateway');
	gateway.disconnect();
}

module.exports.getContractInstance = getContractInstance;
module.exports.disconnect = disconnect;

