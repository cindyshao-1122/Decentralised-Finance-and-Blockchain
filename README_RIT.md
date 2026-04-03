# Rental Income Token (RIT) — README

## 1. Overview

This project implements a **Rental Income Token (RIT)** using the ERC-20 standard on Ethereum.  
The contract is designed to support a tokenised rental-income model based on the coursework report. It combines:

- a **fixed token supply**
- standard **ERC-20 transferability**
- **primary-sale lock-up logic**
- **on-chain rental-income settlement**
- a **project-led redemption / repurchase mechanism**

The deployed Sepolia testnet contract address is:

```text
https://sepolia.etherscan.io/address/0xaED35AE0aAE637B7D557703ab33acB570273d2B2
```

---

## 2. What the contract is designed to do

The contract supports the following functions:

### Core ERC-20 functions
These are the standard token functions required for transferability and compatibility with wallets, DEXs, and DeFi protocols:

- `totalSupply()` — returns the total number of RIT tokens in existence
- `balanceOf(address)` — returns the token balance of a wallet
- `transfer(address to, uint256 amount)` — transfers tokens from the caller to another address
- `approve(address spender, uint256 amount)` — authorises another address or contract to spend tokens on the holder’s behalf
- `allowance(address owner, address spender)` — checks how many tokens a spender is allowed to use
- `transferFrom(address from, address to, uint256 amount)` — transfers tokens using prior approval

### Primary issuance and lock-up
The contract includes staged release logic for primary-sale tokens:

- `allocatePrimarySale(address investor, uint256 tokenAmount)`  
  Allocates tokens to an investor under the lock-up schedule.
- `claimLockedTokens()`  
  Allows an investor to claim tokens once the unlock timestamp has passed.

The lock-up structure is:

- **40% unlocked after the first release date**
- **60% unlocked after the second release date**

### Rental-income settlement
The contract supports rental-income distribution using a separate payment token (such as a mock stablecoin in testing):

- `depositRentalIncome(uint256 amount)`  
  Deposits payment tokens into the contract before distribution.
- `distributeRentalIncome(address[] investors, uint256[] amounts)`  
  Sends payment-token distributions to token holders.

### Liquidity-support function
- `fundLiquidityIncentives(address target, uint256 tokenAmount)`  
  Transfers RIT from the project treasury to a target address used for liquidity incentives or market-support purposes.

### Redemption / repurchase
The contract includes a project-led redemption mechanism:

- `fundRedemption(uint256 amount)`  
  Deposits reserves for future token repurchase.
- `openRedemption(uint256 pricePerToken)`  
  Opens the redemption window and sets the repurchase price.
- `redeem(uint256 tokenAmount)`  
  Allows token holders to redeem RIT for the payment token once redemption is open.

---

## 3. How to interact with the contract in Remix

### Step 1 — Open Remix
Go to Remix Ethereum IDE and open the **Deploy & Run Transactions** panel.

### Step 2 — Connect MetaMask
Set the environment to:

- **Sepolia Testnet - MetaMask**

Make sure your MetaMask wallet is connected to Sepolia and has test ETH.

### Step 3 — Load the compiled contract
Open the Solidity file, compile it, and make sure the correct contract is selected in the deploy panel.

If you already deployed the contract, use **At Address** and paste:

```text
0xaED35AE0aAE637B7D557703ab33acB570273d2B2
```

This will attach the deployed instance to Remix.

### Step 4 — Expand the deployed contract
Once attached, Remix will display all public and external functions.  
You can then call read functions directly or submit transactions for write functions.

---

## 4. Recommended demonstration sequence

For coursework purposes, the simplest demonstration is:

### A. Show token creation
1. Call `totalSupply()`
2. Call `balanceOf(your_address)`

This shows that the token exists on-chain and that the initial supply was successfully created.

### B. Show transferability
1. Copy a second Sepolia wallet address
2. Call `transfer(second_address, 1000000000000000000)`

This transfers **1 RIT** if the token has 18 decimals.

3. Call `balanceOf(second_address)`

This proves that the token can be transferred between addresses.

### C. Show third-party authorisation
1. Call `approve(spender, amount)`
2. Call `allowance(owner, spender)`

This demonstrates standard ERC-20 delegated access, which is important for DEX and DeFi integration.

---

## 5. How to use the main functions

### 5.1 `totalSupply()`
Use this to confirm the token’s fixed supply.

**Type:** read-only  
**Who can use it:** anyone

---

### 5.2 `balanceOf(address account)`
Use this to check the balance of any wallet.

**Type:** read-only  
**Who can use it:** anyone

Example:
- enter your own address to check your holdings
- enter another test wallet to confirm a transfer result

---

### 5.3 `transfer(address to, uint256 amount)`
Use this to send RIT to another address.

**Type:** transaction  
**Who can use it:** any token holder

Example:
```text
to = second wallet address
amount = 1000000000000000000
```

This sends **1 RIT** if the token uses 18 decimals.

---

### 5.4 `approve(address spender, uint256 amount)`
Use this to authorise another wallet or smart contract to use a specified amount of your tokens.

**Type:** transaction  
**Who can use it:** any token holder

This is necessary for integrations with DEXs, AMM pools, and other DeFi applications.

---

### 5.5 `allowance(address owner, address spender)`
Use this to check how many tokens a spender has been approved to use.

**Type:** read-only  
**Who can use it:** anyone

---

### 5.6 `allocatePrimarySale(address investor, uint256 tokenAmount)`
Use this to assign primary-sale tokens to an investor under the lock-up schedule.

**Type:** transaction  
**Who can use it:** contract owner only

Important:
- the contract escrows the tokens first
- the investor cannot access them until the unlock conditions are met

---

### 5.7 `claimLockedTokens()`
Use this to release claimable locked tokens after the unlock date.

**Type:** transaction  
**Who can use it:** investor with an allocation

If called too early, the transaction will fail.

---

### 5.8 `depositRentalIncome(uint256 amount)`
Use this to deposit payment tokens into the contract before making rental-income distributions.

**Type:** transaction  
**Who can use it:** contract owner only

This does **not** transfer RIT.  
It transfers the designated **payment token** used for distributions.

---

### 5.9 `distributeRentalIncome(address[] investors, uint256[] amounts)`
Use this to distribute rental-income payments to a list of investors.

**Type:** transaction  
**Who can use it:** contract owner only

Requirements:
- the two arrays must have the same length
- the contract must already hold enough payment tokens

---

### 5.10 `fundLiquidityIncentives(address target, uint256 tokenAmount)`
Use this to send treasury-held RIT to a target address for liquidity incentives or market-support activity.

**Type:** transaction  
**Who can use it:** contract owner only

This function is useful for demonstrating how the token may support AMM or liquidity arrangements without building an AMM directly into the token contract.

---

### 5.11 `fundRedemption(uint256 amount)`
Use this to deposit payment-token reserves into the contract before opening redemption.

**Type:** transaction  
**Who can use it:** contract owner only

---

### 5.12 `openRedemption(uint256 pricePerToken)`
Use this to activate the redemption window and set the repurchase price.

**Type:** transaction  
**Who can use it:** contract owner only

If the redemption time has not arrived yet, the transaction will fail.

---

### 5.13 `redeem(uint256 tokenAmount)`
Use this to exchange RIT for the payment token after redemption has opened.

**Type:** transaction  
**Who can use it:** token holder

The holder’s RIT is burned and the contract sends the corresponding payment-token amount back to the holder.

---

## 6. Important notes for coursework use

1. This contract is a **coursework demonstration contract**, not a production-ready real-estate tokenisation system.
2. The contract shows how token creation, transferability, lock-up, distribution, and redemption can be represented on-chain.
3. It is sufficient for demonstrating:
   - token deployment on a testnet
   - fixed supply
   - transferability
   - standard ERC-20 compatibility
4. DEX trading and AMM liquidity are supported through **external protocols**, not by embedding a full exchange inside the token contract itself.

---

