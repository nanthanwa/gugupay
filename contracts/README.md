# GuguPay Smart Contract

A payment processing smart contract built on Sui Move that allows merchants to create invoices and accept SUI tokens as payment. The contract includes features for merchant management, invoice creation, payment processing, and balance withdrawal.

## Features

- Merchant registration and management
- Invoice creation with USD pricing
- Payment processing with automatic SUI/USD conversion
- Balance withdrawal for merchants
- Merchant profile updates
- Invoice updates before payment

## Contract Objects

### Merchant NFT

Represents a merchant account with:

- Name, description, and logo URL
- Callback URL for payment notifications
- Balance in SUI tokens

### Invoice NFT

Represents a payment request with:

- Amount in USD
- Description
- Expiration timestamp
- Payment status

## Environment Variables

```bash
# Replace these with your deployed contract values
PACKAGE_ID=
MERCHANT_ID=
INVOICE_ID=
CLOCK_ID=0x6
```

## CLI Commands

### Create a Merchant

Creates a new merchant profile.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function create_merchant \
  --args \
    "Merchant Name" \
    "Merchant Description" \
    "https://example.com/logo.png" \
    "https://api.merchant.com/callback" \
  --gas-budget 10000000
```

### Create an Invoice

Creates a new invoice for a specific merchant. Amount is in USD cents (e.g., 10000 = $100.00).

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function create_invoice \
  --args \
    "$MERCHANT_ID" \
    "Invoice for Product XYZ" \
    10000 \
    1703980800000 \
    "$CLOCK_ID" \
  --gas-budget 10000000
```

### Pay an Invoice

Pays an invoice using SUI tokens. The contract automatically converts USD to SUI based on the current rate.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function pay_invoice \
  --args \
    "$MERCHANT_ID" \
    "$INVOICE_ID" \
    "<COIN_OBJECT_ID>" \
    "$CLOCK_ID" \
  --gas-budget 10000000
```

### Withdraw Balance

Allows a merchant to withdraw their accumulated balance.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function withdraw_balance \
  --args \
    "$MERCHANT_ID" \
  --gas-budget 10000000
```

### Update Merchant Profile

Updates merchant details.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function update_merchant \
  --args \
    "$MERCHANT_ID" \
    "Updated Name" \
    "Updated Description" \
    "https://example.com/new-logo.png" \
    "https://api.merchant.com/new-callback" \
  --gas-budget 10000000
```

### Update Invoice

Updates an unpaid invoice's details.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function update_invoice \
  --args \
    "$MERCHANT_ID" \
    "$INVOICE_ID" \
    "Updated Description" \
    15000 \
    1704067200000 \
    "$CLOCK_ID" \
  --gas-budget 10000000
```

## Development

### Build

```bash
sui move build
```

### Test

```bash
sui move test
```

### Deploy

```bash
sui client publish --gas-budget 50000000
```

## Important Notes

1. The contract uses a fixed SUI/USD rate (1 SUI = $40 USD) for demonstration. In production, this should be replaced with an oracle.
2. All USD amounts are in cents (e.g., 10000 = $100.00)
3. Timestamps are in milliseconds since Unix epoch
4. Make sure to keep your merchant NFT secure as it controls the merchant account and funds

## Events

The contract emits the following events:

- `MerchantCreated`: When a new merchant is registered
- `InvoiceCreated`: When a new invoice is created
- `InvoicePaid`: When an invoice is paid
- `MerchantUpdated`: When merchant details are updated
- `InvoiceUpdated`: When invoice details are updated

## Error Codes

- `ENotMerchantOwner`: Operation requires merchant owner permission
- `EInvoiceExpired`: Invoice has expired
- `EInvoiceAlreadyPaid`: Cannot modify or pay an already paid invoice
- `EInsufficientPayment`: Payment amount is less than required
- `EInvalidAmount`: Invalid amount specified
- `EInvalidExpiryTime`: Invalid expiration time specified
