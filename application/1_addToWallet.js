/*
 * SPDX-License-Identifier: Apache-2.0
 */

'use strict';

const { Wallets } = require('fabric-network');
const fs = require('fs');
const path = require('path');

// Capture the absolute path to the crypto materials
const crypto_materials = path.resolve(__dirname, '../network/crypto-config');

async function main() {
    try {
        // Create a new file system based wallet for managing identities.
        const walletPath = path.join(process.cwd(), 'identity/mhrd');
        const wallet = await Wallets.newFileSystemWallet(walletPath);
        console.log(`Wallet path: ${walletPath}`);

        // Check to see if we've already enrolled the admin user.
        const identityExists = await wallet.get('MHRD_ADMIN');
        if (identityExists) {
            console.log('An identity for the admin user "MHRD_ADMIN" already exists in the wallet');
            return;
        }

        // Identify credentials for MHRD admin
        const keyPath = path.join(crypto_materials, '/peerOrganizations/mhrd.certification-network.com/users/Admin@mhrd.certification-network.com/msp/keystore');
        const certPath = path.join(crypto_materials, '/peerOrganizations/mhrd.certification-network.com/users/Admin@mhrd.certification-network.com/msp/signcerts/Admin@mhrd.certification-network.com-cert.pem');

        // Check if credential files exist
        if (!fs.existsSync(certPath) || !fs.existsSync(keyPath)) {
            console.error('Credential files not found!');
            return;
        }
        
        // Read credentials
        const cert = fs.readFileSync(certPath, 'utf8');
        // Find the private key file name
        const keyFile = fs.readdirSync(keyPath)[0];
        const key = fs.readFileSync(path.join(keyPath, keyFile), 'utf8');
        
        // Create the identity object for the wallet
        const identity = {
            credentials: {
                certificate: cert,
                privateKey: key,
            },
            mspId: 'mhrdMSP',
            type: 'X.509',
        };
        
        // Import the new identity into the wallet.
        await wallet.put('MHRD_ADMIN', identity);
        console.log('Successfully imported MHRD_ADMIN identity into the wallet');

    } catch (error) {
        console.error(`Failed to enroll admin user "MHRD_ADMIN": ${error}`);
        process.exit(1);
    }
}

main();

