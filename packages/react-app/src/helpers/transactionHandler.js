import React from 'react'
import { ethers } from "ethers";
import { Modal } from 'antd';
import { getSignature } from "./getSignature";
import { default as Transactor } from "./Transactor";

export async function transactionHandler(c) {

    function chainWarning(network, chainId) {
        Modal.warning({
          title: 'MetaMask Network Mismatch',
          content: <>Please connect to <b>https://dai.poa.network</b></>,
        });
      }

    function showXDaiModal() {
      Modal.info({
        title: 'You need some xDai!',
        content: (
          <a target="_blank" href={"https://xdai.io"}>Take it to the bridge.</a>
        ),
        onOk() {},
      });
    }

      let contractAddress = require("../contracts/"+c['contractName']+".address.js")
      let contractAbi = require("../contracts/"+c['contractName']+".abi.js")

      let balance = await c['localProvider'].getBalance(c['address'])
      console.log('artist balance', balance)
      let injectedNetwork = await c['injectedProvider'].getNetwork()
      let localNetwork = await c['localProvider'].getNetwork()
      console.log('networkcomparison',injectedNetwork,localNetwork)

      if (parseFloat(ethers.utils.formatEther(balance))>0.001){
        if (injectedNetwork.chainId === localNetwork.chainId) {
          console.log('Got xDai + on the right network, so kicking it old school')

            let contract = new ethers.Contract(
                contractAddress,
                contractAbi,
                c['injectedProvider'].getSigner(),
              );

            let metaData = {}
            if(c['payment']) {
              metaData['value'] = c['payment']
            }

            let result = await contract[c['regularFunction']](...c['regularFunctionArgs'], metaData)
            console.log("Regular RESULT!!!!!!",result)
          return result
        } else {
          chainWarning()
          throw 'Got xDai, but Metamask is on the wrong network'
        }
      }
      else if (process.env.REACT_APP_USE_GSN === 'true') {

        if (injectedNetwork.chainId === localNetwork.chainId && ['injectedGsnSigner'] in c) {
          console.log('Got a signer on the right network and GSN is go!')
          let contract = new ethers.Contract(
              contractAddress,
              contractAbi,
              c['injectedGsnSigner'],
            );
            let result = await contract[c['regularFunction']](...c['regularFunctionArgs'])
          console.log("Regular GSN RESULT!!!!!!",result)
        return result
        }
        else if (c['signatureFunction'] &&
          c['signatureFunctionArgs'] &&
          c['getSignatureTypes'] &&
          c['getSignatureArgs']) {
          console.log('Doing it the chain-agnostic signature way!')
          let signature = await getSignature(
            c['injectedProvider'],
            c['address'],
            c['getSignatureTypes'],
            c['getSignatureArgs'])

          console.log("Got signature: ",signature)

          let contract = new ethers.Contract(
              contractAddress,
              contractAbi,
              c['metaSigner'],
            );

          let result = await contract[c['signatureFunction']](...[...c['signatureFunctionArgs'],signature])
          console.log("Fancy signature RESULT!!!!!!",result)
          return result
        }
        else if (injectedNetwork.chainId !== localNetwork.chainId) {
          chainWarning()
          throw 'Metamask is on the wrong network'
        }
      }
      else {
        showXDaiModal()
        throw 'Need XDai'
      }

  }