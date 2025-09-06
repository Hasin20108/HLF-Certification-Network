/*
* This script is used to query the blockchain and get the details of a student.
*/

'use strict';

const contractHelper = require('./contractHelper.js');

async function main(studentId) {
	
	try {
		// Get contract instance
		const contract = await contractHelper.getContractInstance();
		
		console.log('.....Get Student Details for Student ID: ' + studentId);
		const studentBuffer = await contract.evaluateTransaction('GetStudent', studentId);
		
		console.log('.....Processing Get Student Transaction Response');
		
		let student = JSON.parse(studentBuffer.toString());
		console.log(JSON.stringify(student, null, 2));
		
		console.log('\n\n.....Get Student Transaction Complete!');
		return student;
		
	} catch (error) {
		
		console.log(`\n\n..... DANGER: ${error}`);
		throw new Error(error);
		
	} finally {
		// Disconnect from the gateway
		console.log('.....Disconnecting from Fabric Gateway');
		contractHelper.disconnect();
	}
}

// The script requires a studentId as a command line argument
if (process.argv.length < 3) {
	console.log('Please provide a Student ID as a command line argument. e.g. node 3_getStudents.js 101');
	process.exit(1);
}

main(process.argv[2]);

