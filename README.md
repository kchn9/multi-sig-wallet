
# Ethereum Multi-Signature Wallet w/requests

This project is implementation of ethereum wallet that gives users opportunity to better control their shared funds by specific **signer** role.
It prevents from problem where one of users of shared wallet is running off with all funds.

Every vital change to wallet state (balance, change signer role, change required amount of signatures) is represented by **request** that before being executed must be signed by required amount of signatues.


## Features

- Access **signer** role 
- RequestFactory that creates any pre-defined request
- Modifiers providing safety before request execution
- Events tracking every change of wallet state
- Shared wallet functionality


## Created with (dependencies)

- Truffle v5.5.10 (core: 5.5.10)
- Ganache v^7.0.3
- Solidity - ^0.8.0 (solc-js)
- Node v16.14.2
- Web3.js v1.5.3



## Installation

Clone the project

```bash
  git clone https://github.com/kchn9/multi-sig-wallet
```

Go to the project directory

```bash
  cd multi-sig-wallet
```

Install

```bash
  npm install
```
    
## Running Tests

To run tests, run the following command

```bash
  truffle test
```


## Authors

- [@kchn9](https://www.github.com/kchn9)


## License

[MIT](https://choosealicense.com/licenses/mit/)

