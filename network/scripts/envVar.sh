#!/bin/bash
# This is a collection of bash functions used by different scripts

export CORE_PEER_TLS_ENABLED=false
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/certification-network.com/orderers/orderer.certification-network.com/msp/tlscacerts/tlsca.certification-network.com-cert.pem

# Set environment variables for the peer org
setGlobals() {
  local ORG_NAME=$1
  echo "Setting environment for org ${ORG_NAME}"
  
  if [ "$ORG_NAME" == "iit" ]; then
    export CORE_PEER_LOCALMSPID="iitMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/iit.certification-network.com/peers/peer0.iit.certification-network.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/iit.certification-network.com/users/Admin@iit.certification-network.com/msp
    export CORE_PEER_ADDRESS=peer0.iit.certification-network.com:7051
  elif [ "$ORG_NAME" == "mhrd" ]; then
    export CORE_PEER_LOCALMSPID="mhrdMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mhrd.certification-network.com/peers/peer0.mhrd.certification-network.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/mhrd.certification-network.com/users/Admin@mhrd.certification-network.com/msp
    export CORE_PEER_ADDRESS=peer0.mhrd.certification-network.com:9051
  elif [ "$ORG_NAME" == "upgrad" ]; then
    export CORE_PEER_LOCALMSPID="upgradMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/upgrad.certification-network.com/peers/peer0.upgrad.certification-network.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/upgrad.certification-network.com/users/Admin@upgrad.certification-network.com/msp
    export CORE_PEER_ADDRESS=peer0.upgrad.certification-network.com:11051
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi
}

setGlobalsForPeer() {
    local ORG_NAME=$1
    local PEER_NUM=$2
    setGlobals $ORG_NAME

    if [ $PEER_NUM -eq 1 ]; then
        if [ "$ORG_NAME" == "iit" ]; then
            export CORE_PEER_ADDRESS=peer1.iit.certification-network.com:8051
        elif [ "$ORG_NAME" == "mhrd" ]; then
            export CORE_PEER_ADDRESS=peer1.mhrd.certification-network.com:10051
        elif [ "$ORG_NAME" == "upgrad" ]; then
            export CORE_PEER_ADDRESS=peer1.upgrad.certification-network.com:12051
        fi
    fi
}

