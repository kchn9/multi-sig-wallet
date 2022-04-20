import Web3 from "web3";

const LOCALHOST_PORT = "8545";

const getWeb3 = () =>
  new Promise((resolve, reject) => {
    // Wait for loading completion to avoid race conditions with web3 injection timing.
    window.addEventListener("load", async () => {
      if (window.ethereum) {
        const web3 = new Web3(window.ethereum);
        try {
          // Modern dapp browser - use metamask provider - window.ethereum
          await window.ethereum.request({ method: "eth_requestAccounts" });
          resolve(web3);
        } catch (error) {
          if (error.code === 4001) {
            console.log("getWeb3 - window.ethereum: User rejected connection");
          } else {
            console.log("getWeb3 - window.ethereum: Internal error / The parameters were invalid");
          }
          reject(error);
        }
      }
      else if (window.web3) {
        // Legacy browsers - use window.web3 provider
        const web3 = window.web3;
        try {
          await web3.eth.getAccounts();
          resolve(web3);
        } catch (error) {
          console.log(error);
          reject(web3)
        }
      }
      else {
        // use local WebsocketProvider - it supports events
        console.log("No web3 instance injected, using Local web3.");
        const provider = new Web3.providers.WebsocketProvider(
          `ws://127.0.0.1:${LOCALHOST_PORT}`
        );
        const web3 = new Web3(provider);
        resolve(web3)
      }
    });
});

export default getWeb3;
