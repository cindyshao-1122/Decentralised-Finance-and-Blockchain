# RentalIncomeToken (RIT)

## 📌 Project Overview

This project implements a tokenised rental income model using an ERC-20 smart contract on the Ethereum Sepolia test network. The token, named **RentalIncomeToken (RIT)**, represents fractional economic rights to rental income generated from residential real estate assets.

Instead of tokenising the physical property itself, the model abstracts the rental income stream as the underlying asset. This allows the transformation of an illiquid and indivisible asset into a divisible, transferable, and blockchain-based financial instrument.

---

## ⚙️ Smart Contract Details

* **Token Name:** RentalIncomeToken
* **Symbol:** RIT
* **Standard:** ERC-20 (OpenZeppelin)
* **Solidity Version:** ^0.8.20
* **Network:** Sepolia Testnet

---

## 📄 Contract Address

```text
0x6f822D85f54C1B8Ca5DE574fF335Cd94C1934B97
```

🔗 View on Etherscan:
https://sepolia.etherscan.io/address/0x6f822D85f54C1B8Ca5DE574fF335Cd94C1934B97

---

## 🚀 Deployment

The smart contract was deployed using Remix IDE and MetaMask connected to the Sepolia test network.

### Steps:

1. Write the contract using OpenZeppelin ERC-20 implementation
2. Compile with Solidity version 0.8.20
3. Connect Remix to MetaMask (Sepolia Testnet)
4. Deploy with an initial supply (e.g., 1,000,000 tokens)
5. Confirm the transaction in MetaMask

---

## 🔑 Core Functionalities

### 1. Token Issuance

Tokens are minted during contract deployment:

* Initial supply is assigned to the deployer
* Tokens are divisible (18 decimals)
* Each token represents a share of rental income

---

### 2. Transfer Function (transfer)

The `transfer` function enables peer-to-peer token transactions.

✔ Demonstration:

* 10 RIT tokens were transferred to another address
* Verified via Remix and Etherscan

✔ Result:

* Sender balance decreased
* Receiver balance increased

---

### 3. Approval Mechanism (approve & allowance)

The ERC-20 approval mechanism enables delegated spending.

#### approve

Allows a third-party address to spend tokens on behalf of the owner.

#### allowance

Returns the authorised spending amount.

✔ Demonstration:

* 50 RIT tokens were approved to another address
* Verified using the `allowance` function

---

## 📊 On-Chain Verification

All interactions were executed on the Sepolia test network and verified via Etherscan.

Evidence includes:

* Successful transfer transactions
* Approval transactions
* ERC-20 token transfer logs

This confirms that the contract behaves correctly according to the ERC-20 standard.

---

## 🧠 Economic Design

The token represents a **cash flow-based asset**, where value is derived from rental income rather than direct property ownership.

Key features:

* Fractionalisation of income rights
* Transferability through blockchain
* Potential integration with DeFi protocols
* Passive income exposure

---

## ⚠️ Limitations

* Token holders do not own the physical property
* Subject to smart contract and market risks
* Dependent on external rental income generation


---

## 📚 References

* OpenZeppelin ERC-20 Documentation
* Ethereum Remix IDE
* Sepolia Testnet
* Etherscan

---

## ✅ Conclusion

The RentalIncomeToken demonstrates how rental income can be tokenised into a standardised ERC-20 asset. The implementation confirms that token issuance, transferability, and approval mechanisms function correctly on-chain, aligning with the requirements of an existing token standard.

---
# Add-file-Upload-files
