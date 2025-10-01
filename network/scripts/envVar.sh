#!/bin/bash
# This is a collection of bash functions used by different scripts

export CORE_PEER_TLS_ENABLED=false
export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/com/orderers/orderer.com/msp/tlscacerts/tlsca.com-cert.pem

# Set environment variables for the peer org
setGlobals() {
  local ORG_NAME=$1
  echo "Setting environment for org ${ORG_NAME}"
  
  if [ "$ORG_NAME" == "ru" ]; then
    export CORE_PEER_LOCALMSPID="ruMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ru.com/peers/peer0.ru.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/ru.com/users/Admin@ru.com/msp
    export CORE_PEER_ADDRESS=peer0.ru.com:7051
  elif [ "$ORG_NAME" == "me" ]; then
    export CORE_PEER_LOCALMSPID="meMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/me.com/peers/peer0.me.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/me.com/users/Admin@me.com/msp
    export CORE_PEER_ADDRESS=peer0.me.com:9051
  elif [ "$ORG_NAME" == "authenticator" ]; then
    export CORE_PEER_LOCALMSPID="authenticatorMSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/authenticator.com/peers/peer0.authenticator.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/authenticator.com/users/Admin@authenticator.com/msp
    export CORE_PEER_ADDRESS=peer0.authenticator.com:11051
  else
    echo "================== ERROR !!! ORG Unknown =================="
  fi
}

setGlobalsForPeer() {
    local ORG_NAME=$1
    local PEER_NUM=$2
    setGlobals $ORG_NAME

    if [ $PEER_NUM -eq 1 ]; then
        if [ "$ORG_NAME" == "ru" ]; then
            export CORE_PEER_ADDRESS=peer1.ru.com:8051
        elif [ "$ORG_NAME" == "me" ]; then
            export CORE_PEER_ADDRESS=peer1.me.com:10051
        elif [ "$ORG_NAME" == "authenticator" ]; then
            export CORE_PEER_ADDRESS=peer1.authenticator.com:12051
        fi
    fi
}

