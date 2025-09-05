#!/bin/bash

# Import utils
. scripts/envVar.sh

CHANNEL_NAME="certificationchannel"
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"

createChannel() {
    setGlobals "iit"
    
    # Set FABRIC_CFG_PATH to the correct directory inside the CLI container
    export FABRIC_CFG_PATH=/etc/hyperledger/fabric

    echo "Creating channel ${CHANNEL_NAME}"
    peer channel create -o orderer.certification-network.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --outputBlock ./channel-artifacts/${CHANNEL_NAME}.block
    echo "===================== Channel '$CHANNEL_NAME' created ===================== "
}

joinChannel() {
    for org in iit mhrd upgrad; do
        for peer in 0 1; do
            setGlobalsForPeer $org $peer
            peer channel join -b ./channel-artifacts/$CHANNEL_NAME.block
            echo "===================== peer${peer}.${org} joined channel '$CHANNEL_NAME' ===================== "
            sleep $DELAY
        done
    done
}

updateAnchorPeers() {
    for org in iit mhrd upgrad; do
        setGlobals $org
        peer channel update -o orderer.certification-network.com:7050 --ordererTLSHostnameOverride orderer.certification-network.com -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx
        echo "===================== Anchor peers updated for '${CORE_PEER_LOCALMSPID}' ===================== "
        sleep $DELAY
    done
}


echo " ____    _____      _      ____    _____"
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |"
echo " ___) |   | |    / ___ \  |  _ <    | |"
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|"
echo
echo "Setting Up Hyperledger Fabric Network"
echo

createChannel
joinChannel
updateAnchorPeers

echo
echo "========= All GOOD, Hyperledger Fabric Certification Network Is Now Up and Running! =========== "
echo

exit 0
