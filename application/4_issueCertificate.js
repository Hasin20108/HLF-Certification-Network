'use strict';

const contractHelper = require('./contractHelper.js');
const crypto = require('crypto');

async function main() {
    try {
        // Connect to the fabric network and get the contract instance from MHRD org
        const contract = await contractHelper.getContractInstance('mhrd', 'mhrd');

        console.log('.....Issue a new Certificate');
        
        // Example certificate data
        const studentId = '101';
        const courseId = 'COURSE01';
        const grade = 'A';
        const certificateData = studentId + courseId + grade;
        const originalHash = crypto.createHash('sha256').update(certificateData).digest('hex');

        const certificateBuffer = await contract.submitTransaction(
            'IssueCertificate',
            studentId,
            courseId,
            grade,
            originalHash
        );

        // process response
        console.log('.....Processing Issue Certificate Transaction Response \n\n');
        let certificate = JSON.parse(certificateBuffer.toString());
        console.log(certificate);
        console.log('\n\n.....Issue Certificate Transaction Complete!');
        return certificate;

    } catch (error) {
        console.log(`\n\n ..... DANGER: ${error} \n\n`);
        throw new Error(error);
    } finally {
        // Disconnect from the fabric gateway
        contractHelper.disconnect();
    }
}

main();
