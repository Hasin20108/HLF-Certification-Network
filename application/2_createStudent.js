'use strict';

const contractHelper = require('./contractHelper.js');

async function main() {
	try {
		// Connect to the fabric network and get the contract instance
		const contract = await contractHelper.getContractInstance('iit', 'iit');
		
		console.log('.....Create a new student');
		const studentBuffer = await contract.submitTransaction(
			'CreateStudent',
			'101',
			'Amit Kumar',
			'amit.k@email.com'
		);

		// process response
		console.log('.....Processing Create Student Transaction Response \n\n');
		let student = JSON.parse(studentBuffer.toString());
		console.log(student);
		console.log('\n\n.....Create Student Transaction Complete!');
		return student;

	} catch (error) {
		console.log(`\n\n ..... DANGER: ${error} \n\n`);
		throw new Error(error);
	} finally {
		// Disconnect from the fabric gateway
		contractHelper.disconnect();
	}
}

main();
