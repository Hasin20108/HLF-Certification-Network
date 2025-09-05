'use strict';

const contractHelper = require('./contractHelper.js');
const crypto = require('crypto');

async function main() {
    try {
        // Connect to the fabric network and get the contract instance from UpGrad org
        const contract = await contractHelper.getContractInstance('upgrad', 'upgrad');

        console.log('.....Verify a Certificate');

        // Example data for verification
        const studentId = '101';
        const courseId = 'COURSE01';
        const grade = 'A'; // The grade that was originally used
        const certificateData = studentId + courseId + grade;
        const currentHash = crypto.createHash('sha256').update(certificateData).digest('hex');

        const verificationBuffer = await contract.submitTransaction(
            'VerifyCertificate',
            studentId,
            courseId,
            currentHash
        );

        // process response
        console.log('.....Processing Verify Certificate Transaction Response \n\n');
        let result = JSON.parse(verificationBuffer.toString());
        console.log(result);
        console.log('\n\n.....Verify Certificate Transaction Complete!');
        return result;

    } catch (error) {
        console.log(`\n\n ..... DANGER: ${error} \n\n`);
        throw new Error(error);
    } finally {
        // Disconnect from the fabric gateway
        contractHelper.disconnect();
    }
}

main();
