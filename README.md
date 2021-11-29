# SLP Manager

> Eases pain to anyone who runs Axie Infinity's scholarship program

## Introduction

The SLP liquidity pool that can help every Axie manager to send SLP to scholar to their scholar. With dynamic NFT which setup by Axie manger manager, their scholar can easily check how many SLP they be able to claim and use the NFT as a key to claim their SLP credit without 15 days waiting time period. This solution will cut time and human error for everyone who run Axie scholarship and create more utility on SLP single pool as a pool that can generate income from claiming fee.

## Demo on Kovan
https://main.d3cjaoysd24hs7.amplifyapp.com/scholar-info/

## Technologies

* Chainlink Custom API - Fetches API from Axie Infinity, the data validity been proven by reputated Chainlink nodes.
* Chainlink Keeper - Periodically invokes the endpoint without human intervention, the data will be updated in the smart contract automatically.


## Install

This project comprises of 2 modules, the frontend UI and the smart contract.

### Solidity contracts

To test it, make sure you have Hardhat in your machine then run

cd contracts
npx hardhat test

### Frontend UI

This made by react-create-app that compatible to most modern browsers, to run it locally just run

cd client
npm install
npm start

## Deployment

### Ethereum Kovan

Contract Name | Contract Address 
--- | --- 
SLP Manager | 0x85CbD680Cc1b3a899cf25A7c43395762b4F916eE 


## License

MIT ©
