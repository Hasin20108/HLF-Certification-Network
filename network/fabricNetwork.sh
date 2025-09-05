#!/bin/bash

export PATH=${PWD}/bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
export VERBOSE=false

# Print the usage message
function printHelp() {
  echo "Usage: "
  echo "  fabricNetwork.sh <mode>"
  echo "    <mode> - one of 'up', 'down', 'restart', 'generate', 'deploy'"
  echo "      - 'up' - bring up the network with docker-compose up"
  echo "      - 'down' - clear the network with docker-compose down"
  echo "      - 'restart' - restart the network"
  echo "      - 'generate' - generate required certificates and genesis block"
  echo "      - 'deploy' - deploy the chaincode to the network"
  echo
  echo "Examples:"
  echo "  fabricNetwork.sh up"
  echo "  fabricNetwork.sh generate"
  echo "  fabricNetwork.sh deploy"
  echo "  fabricNetwork.sh down"
}

# Obtain CONTAINER_IDS and remove them
function clearContainers() {
  CONTAINER_IDS=$(docker ps -a | awk '($2 ~ /dev-peer.*/) {print $1}')
  if [ -z "$CONTAINER_IDS" -o "$CONTAINER_IDS" == " " ]; then
    echo "---- No containers available for deletion ----"
  else
    docker rm -f $CONTAINER_IDS
  fi
}

# Delete any images that were generated as a part of this setup
function removeUnwantedImages() {
  DOCKER_IMAGE_IDS=$(docker images | awk '($1 ~ /dev-peer.*/) {print $3}')
  if [ -z "$DOCKER_IMAGE_IDS" -o "$DOCKER_IMAGE_IDS" == " " ]; then
    echo "---- No images available for deletion ----"
  else
    docker rmi -f $DOCKER_IMAGE_IDS
  fi
}

# Generates Org certs using cryptogen tool
function generateCerts() {
  which cryptogen
  if [ "$?" -ne 0 ]; then
    echo "cryptogen tool not found. exiting"
    exit 1
  fi
  echo
  echo "##########################################################"
  echo "##### Generate certificates using cryptogen tool #########"
  echo "##########################################################"

  if [ -d "crypto-config" ]; then
    rm -Rf crypto-config
  fi
  set -x
  cryptogen generate --config=./crypto-config.yaml
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
  echo
}

# Generate orderer genesis block, channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  echo "##########################################################"
  echo "#########  Generating Orderer Genesis block ##############"
  echo "##########################################################"
  set -x
  configtxgen -profile OrdererGenesis -channelID system-channel -outputBlock ./channel-artifacts/genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "### Generating channel configuration transaction 'channel.tx' ###"
  echo "#################################################################"
  set -x
  configtxgen -profile CertificationChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for iitMSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile CertificationChannel -outputAnchorPeersUpdate ./channel-artifacts/iitMSPanchors.tx -channelID $CHANNEL_NAME -asOrg iitMSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for iitMSP..."
    exit 1
  fi

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for mhrdMSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile CertificationChannel -outputAnchorPeersUpdate ./channel-artifacts/mhrdMSPanchors.tx -channelID $CHANNEL_NAME -asOrg mhrdMSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for mhrdMSP..."
    exit 1
  fi
  echo

  echo
  echo "#################################################################"
  echo "#######    Generating anchor peer update for upgradMSP   ##########"
  echo "#################################################################"
  set -x
  configtxgen -profile CertificationChannel -outputAnchorPeersUpdate ./channel-artifacts/upgradMSPanchors.tx -channelID $CHANNEL_NAME -asOrg upgradMSP
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate anchor peer update for upgradMSP..."
    exit 1
  fi
  echo
}

# Bring up the network
function networkUp() {
  # generate artifacts if they don't exist
  if [ ! -d "crypto-config" ]; then
    generateCerts
    generateChannelArtifacts
  fi
  
  COMPOSE_FILE=docker-compose-e2e.yml
  # Use "docker compose" instead of "docker-compose"
  IMAGE_TAG=latest docker compose -f $COMPOSE_FILE up -d 2>&1
  docker ps -a
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Unable to start network"
    exit 1
  fi
  
  echo "Sleeping 10s to allow cluster to complete booting"
  sleep 10

  # now run the bootstrap script
  docker exec cli scripts/bootstrap.sh
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Test failed"
    exit 1
  fi
}

# Deploy the chaincode
function deployCC() {
  docker exec cli scripts/deployCertNet.sh
  if [ $? -ne 0 ]; then
    echo "ERROR !!!! Deploying chaincode failed"
    exit 1
  fi
  echo "SUCCESS: Chaincode deployed"
}

# Tear down running network
function networkDown() {
  # Use "docker compose" instead of "docker-compose"
  COMPOSE_FILE=docker-compose-e2e.yml
  docker compose -f $COMPOSE_FILE down --volumes --remove-orphans
  
  if [ "$MODE" != "restart" ]; then
    clearContainers
    removeUnwantedImages
    rm -rf channel-artifacts/*.block channel-artifacts/*.tx crypto-config
  fi
}

CHANNEL_NAME="certificationchannel"
MODE=$1

if [ "$MODE" == "up" ]; then
  networkUp
elif [ "$MODE" == "down" ]; then
  networkDown
elif [ "$MODE" == "restart" ]; then
  networkDown
  networkUp
elif [ "$MODE" == "generate" ]; then
  generateCerts
  generateChannelArtifacts
elif [ "$MODE" == "deploy" ]; then
  deployCC
else
  printHelp
  exit 1
fi

