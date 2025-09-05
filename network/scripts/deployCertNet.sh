#!/bin/bash

CHANNEL_NAME=${1:-"certificationchannel"}
CC_NAME=${2:-"certnet"}
# Using an absolute path inside the container
CC_SRC_PATH=${3:-"/opt/gopath/src/github.com/hyperledger/fabric/peer/chaincode-go"}
CC_VERSION=${4:-"1.0"}
CC_SEQUENCE=${5:-"1"}
DELAY=${6:-"3"}
MAX_RETRY=${7:-"5"}
VERBOSE=${8:-"false"}

echo "executing with the following"
echo "CHANNEL_NAME: ${CHANNEL_NAME}"
echo "CC_NAME: ${CC_NAME}"
echo "CC_SRC_PATH: ${CC_SRC_PATH}"
echo "CC_VERSION: ${CC_VERSION}"
echo "CC_SEQUENCE: ${CC_SEQUENCE}"
echo "DELAY: ${DELAY}"
echo "MAX_RETRY: ${MAX_RETRY}"
echo "VERBOSE: ${VERBOSE}"

# import utils
. scripts/envVar.sh

# Set FABRIC_CFG_PATH to the correct directory inside the CLI container
export FABRIC_CFG_PATH=/etc/hyperledger/fabric

packageChaincode() {
  setGlobals "iit"
  peer lifecycle chaincode package ${CC_NAME}.tar.gz --path ${CC_SRC_PATH} --lang golang --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! Chaincode packaging has failed !!!!!!!!!!!!!!!!"
    exit 1
  fi
  echo "===================== Chaincode is packaged ===================== "
}

installChaincode() {
  for org in iit mhrd upgrad; do
    for peer in 0 1; do
        setGlobalsForPeer $org $peer
        peer lifecycle chaincode install ${CC_NAME}.tar.gz >&log.txt
        res=$?
        cat log.txt
        if [ $res -ne 0 ]; then
            echo "!!!!!!!!!!!!!!! Chaincode installation on peer${peer}.${org} has failed !!!!!!!!!!!!!!!!"
            exit 1
        fi
        echo "===================== Chaincode is installed on peer${peer}.${org} ===================== "
    done
  done
}

queryInstalled() {
  setGlobals "iit"
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  cat log.txt
  export PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  if [ $res -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! Query installed failed !!!!!!!!!!!!!!!!"
    exit 1
  fi
  echo "===================== Query installed successful on peer0.iit ===================== "
  echo "PackageID is ${PACKAGE_ID}"
}

approveForMyOrg() {
    for org in iit mhrd upgrad; do
        setGlobals $org
        peer lifecycle chaincode approveformyorg -o orderer.certification-network.com:7050 --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} >&log.txt
        res=$?
        cat log.txt
        if [ $res -ne 0 ]; then
            echo "!!!!!!!!!!!!!!! chaincode approve for org ${org} failed !!!!!!!!!!!!!!!!"
            exit 1
        fi
        echo "===================== chaincode approved for org ${org} ===================== "
    done
}

checkCommitReadiness() {
    for org in iit mhrd upgrad; do
        setGlobals $org
        peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} --output json >&log.txt
        res=$?
        cat log.txt
        if [ $res -ne 0 ]; then
            echo "!!!!!!!!!!!!!!! check commit readiness for org ${org} failed !!!!!!!!!!!!!!!!"
            exit 1
        fi
    done
}

commitChaincodeDefinition() {
  PEER_CONN_PARMS="--peerAddresses peer0.iit.certification-network.com:7051 --peerAddresses peer0.mhrd.certification-network.com:9051 --peerAddresses peer0.upgrad.certification-network.com:11051"
  setGlobals "iit"
  peer lifecycle chaincode commit -o orderer.certification-network.com:7050 --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${PEER_CONN_PARMS} >&log.txt
  res=$?
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! Commit chaincode definition failed !!!!!!!!!!!!!!!!"
    exit 1
  fi
  echo "===================== Chaincode definition committed ===================== "
}

queryCommitted() {
  setGlobals "iit"
  peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
  res=$?
  cat log.txt
  if [ $res -ne 0 ]; then
    echo "!!!!!!!!!!!!!!! Query committed failed !!!!!!!!!!!!!!!!"
    exit 1
  fi
}

packageChaincode
installChaincode
queryInstalled
approveForMyOrg
checkCommitReadiness
commitChaincodeDefinition
queryCommitted

exit 0

