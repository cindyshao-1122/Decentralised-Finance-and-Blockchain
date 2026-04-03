// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts@5.0.0/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts@5.0.0/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts@5.0.0/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts@5.0.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@5.0.0/token/ERC20/utils/SafeERC20.sol";

/// @title Rental Income Token (RIT)
/// @notice Coursework-friendly implementation of a tokenised rental-income model.
/// @dev This contract keeps the ERC-20 core simple, while adding:
///      1) fixed supply,
///      2) staged primary-sale lock-up (40% / 60%),
///      3) on-chain rental-income settlement in a payment token,
///      4) project-led redemption / repurchase.
contract RentalIncomeToken is ERC20, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable paymentToken; // e.g. USDC / mock stablecoin used for income distributions and redemption

    uint256 public immutable unlock40Timestamp;
    uint256 public immutable unlock60Timestamp;
    uint256 public immutable redemptionTimestamp;

    uint256 public totalEscrowed;
    uint256 public redemptionPrice; // payment-token smallest units per 1 RIT (1e18 token units)
    bool public redemptionOpened;

    struct Allocation {
        uint256 tranche40;
        uint256 tranche60;
        uint256 claimed40;
        uint256 claimed60;
    }

    mapping(address => Allocation) public allocations;

    event PrimarySaleAllocated(address indexed investor, uint256 totalAmount, uint256 tranche40, uint256 tranche60);
    event LockedTokensClaimed(address indexed investor, uint256 amount);
    event RentalIncomeDeposited(uint256 amount);
    event RentalIncomePaid(address indexed investor, uint256 amount);
    event RentalIncomeBatchPaid(uint256 totalAmount, uint256 recipientCount);
    event LiquidityIncentivesFunded(address indexed target, uint256 amount);
    event RedemptionFunded(uint256 amount);
    event RedemptionOpened(uint256 pricePerToken);
    event Redeemed(address indexed investor, uint256 tokenAmount, uint256 paymentAmount);

    constructor(
        address paymentToken_,
        uint256 initialSupply_,
        uint256 unlock40Timestamp_,
        uint256 unlock60Timestamp_,
        uint256 redemptionTimestamp_
    ) ERC20("Rental Income Token", "RIT") Ownable(msg.sender) {
        require(paymentToken_ != address(0), "payment token is zero");
        require(unlock40Timestamp_ < unlock60Timestamp_, "invalid unlock schedule");
        require(unlock60Timestamp_ < redemptionTimestamp_, "invalid redemption time");

        paymentToken = IERC20(paymentToken_);
        unlock40Timestamp = unlock40Timestamp_;
        unlock60Timestamp = unlock60Timestamp_;
        redemptionTimestamp = redemptionTimestamp_;

        // Fixed supply minted once to the project treasury / owner.
        _mint(msg.sender, initialSupply_ * 10 ** decimals());
    }

    // ------------------------------------------------------------------------
    // Primary issuance with staged lock-up
    // ------------------------------------------------------------------------

    /// @notice Records a primary-sale allocation and escrows the tokens in the contract.
    /// @dev 40% is claimable after the first unlock date, 60% after the second unlock date.
    function allocatePrimarySale(address investor, uint256 tokenAmount) external onlyOwner {
        require(investor != address(0), "invalid investor");
        require(tokenAmount > 0, "amount is zero");

        uint256 amount = tokenAmount * 10 ** decimals();
        uint256 tranche40 = (amount * 40) / 100;
        uint256 tranche60 = amount - tranche40;

        _transfer(owner(), address(this), amount);

        allocations[investor].tranche40 += tranche40;
        allocations[investor].tranche60 += tranche60;
        totalEscrowed += amount;

        emit PrimarySaleAllocated(investor, amount, tranche40, tranche60);
    }

    function claimable40(address investor) public view returns (uint256) {
        if (block.timestamp < unlock40Timestamp) return 0;
        return allocations[investor].tranche40 - allocations[investor].claimed40;
    }

    function claimable60(address investor) public view returns (uint256) {
        if (block.timestamp < unlock60Timestamp) return 0;
        return allocations[investor].tranche60 - allocations[investor].claimed60;
    }

    function totalClaimable(address investor) public view returns (uint256) {
        return claimable40(investor) + claimable60(investor);
    }

    function claimLockedTokens() external nonReentrant {
        uint256 amount40 = claimable40(msg.sender);
        uint256 amount60 = claimable60(msg.sender);
        uint256 totalAmount = amount40 + amount60;

        require(totalAmount > 0, "nothing claimable");

        if (amount40 > 0) {
            allocations[msg.sender].claimed40 += amount40;
        }
        if (amount60 > 0) {
            allocations[msg.sender].claimed60 += amount60;
        }

        totalEscrowed -= totalAmount;
        _transfer(address(this), msg.sender, totalAmount);

        emit LockedTokensClaimed(msg.sender, totalAmount);
    }

    // ------------------------------------------------------------------------
    // Rental income settlement (payment token)
    // ------------------------------------------------------------------------

    /// @notice Deposits stablecoin / payment-token funds into the contract before distribution.
    function depositRentalIncome(uint256 amount) external onlyOwner {
        require(amount > 0, "amount is zero");
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RentalIncomeDeposited(amount);
    }

    /// @notice Batch-pays rental income to token holders.
    /// @dev The owner calculates each holder's share off-chain, then settles it on-chain.
    function distributeRentalIncome(
        address[] calldata investors,
        uint256[] calldata amounts
    ) external onlyOwner nonReentrant {
        require(investors.length == amounts.length, "length mismatch");

        uint256 totalAmount;
        for (uint256 i = 0; i < investors.length; i++) {
            require(investors[i] != address(0), "invalid investor");
            require(amounts[i] > 0, "zero payment");
            totalAmount += amounts[i];
        }

        require(paymentToken.balanceOf(address(this)) >= totalAmount, "insufficient payment balance");

        for (uint256 i = 0; i < investors.length; i++) {
            paymentToken.safeTransfer(investors[i], amounts[i]);
            emit RentalIncomePaid(investors[i], amounts[i]);
        }

        emit RentalIncomeBatchPaid(totalAmount, investors.length);
    }

    // ------------------------------------------------------------------------
    // Liquidity-support helper
    // ------------------------------------------------------------------------

    /// @notice Sends treasury tokens to a liquidity-mining / market-making address.
    /// @dev AMM pools themselves are external protocols; this function just funds the incentive side.
    function fundLiquidityIncentives(address target, uint256 tokenAmount) external onlyOwner {
        require(target != address(0), "invalid target");
        require(tokenAmount > 0, "amount is zero");

        uint256 amount = tokenAmount * 10 ** decimals();
        _transfer(owner(), target, amount);

        emit LiquidityIncentivesFunded(target, amount);
    }

    // ------------------------------------------------------------------------
    // Redemption / repurchase
    // ------------------------------------------------------------------------

    /// @notice Deposits payment-token reserves for future redemption.
    function fundRedemption(uint256 amount) external onlyOwner {
        require(amount > 0, "amount is zero");
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        emit RedemptionFunded(amount);
    }

    /// @notice Opens the year-5 redemption window and sets the buy-back price.
    /// @param pricePerToken Payment-token smallest units per 1 full RIT token.
    ///        Example with 6-decimal stablecoin: 1.25 USDC => 1_250_000.
    function openRedemption(uint256 pricePerToken) external onlyOwner {
        require(block.timestamp >= redemptionTimestamp, "too early");
        require(pricePerToken > 0, "price is zero");

        redemptionPrice = pricePerToken;
        redemptionOpened = true;

        emit RedemptionOpened(pricePerToken);
    }

    function redeem(uint256 tokenAmount) external nonReentrant {
        require(redemptionOpened, "redemption closed");
        require(tokenAmount > 0, "amount is zero");

        uint256 paymentAmount = (tokenAmount * redemptionPrice) / 10 ** decimals();
        require(paymentToken.balanceOf(address(this)) >= paymentAmount, "insufficient redemption reserve");

        _burn(msg.sender, tokenAmount);
        paymentToken.safeTransfer(msg.sender, paymentAmount);

        emit Redeemed(msg.sender, tokenAmount, paymentAmount);
    }
}

/// @title MockUSDC
/// @notice Optional helper token for Remix VM testing.
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USD Coin", "mUSDC") {
        _mint(msg.sender, 1_000_000_000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}