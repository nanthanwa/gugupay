# GuguPay Smart Contract

A payment processing smart contract built on Sui Move that allows merchants to create invoices and accept SUI tokens as payment. The contract uses a shared object design for better scalability and user experience.

## Features

- Shared object design for better scalability
- Merchant registration and management
- Invoice creation with USD pricing
- Payment processing with automatic SUI/USD conversion
- Balance withdrawal for merchants
- Merchant profile updates
- Invoice updates before payment

## Contract Objects

### PaymentStore (Shared Object)

The main store that holds all merchants and invoices:

- Table of merchants indexed by ID
- Table of invoices indexed by ID
- Last created merchant and invoice IDs for testing

### Merchant (Store Object)

Represents a merchant account with:

- Name, description, and logo URL
- Callback URL for payment notifications
- Balance in SUI tokens
- Owner address

### Invoice (Store Object)

Represents a payment request with:

- Amount in USD
- Description
- Expiration timestamp
- Payment status
- Reference to merchant ID

## Environment Variables

```bash
# Replace these with your deployed contract values
PACKAGE_ID=0x528b84ea98af7e92c3cd27db185f49855c47c7215c33e75b1a97e3887ed36b3c
SHARED_ID=0x6c687caf6368e765d624e522a837eb22eae12c614cdf782919b41b0aa883a5b5
MERCHANT_ID=0x0a2fd63bf8d7514d1bbe5cb1910115aa5de3e45050ca257702e8ef60eed75055
INVOICE_ID=0xf53af58adbe95c3106572945d8302409dafeb0bdb751afc8758358cd2ba40e16
CLOCK_ID=0x6
COIN_ID=0x9144b267acc9f06532c8677a2d3df1cf229edc62a36570fc8e981fea4715d02f
```

## CLI Commands

### Create a Merchant

Creates a new merchant in the shared store.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function create_merchant \
  --args \
    "$SHARED_ID" \
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
    "$SHARED_ID" \
    "$MERCHANT_ID" \
    "Invoice for Product XYZ" \
    10 \
    1734025535000 \
    "$CLOCK_ID" \
  --gas-budget 10000000
```

### Pay an Invoice

Pays an invoice using SUI tokens. Anyone can pay any valid invoice.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function pay_invoice \
  --args \
    "$SHARED_ID" \
    "$INVOICE_ID" \
    "$COIN_ID" \
    "$CLOCK_ID" \
  --gas-budget 10000000
```

### Withdraw Balance

Allows a merchant owner to withdraw their accumulated balance.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function withdraw_balance \
  --args \
    "$SHARED_ID" \
    "$MERCHANT_ID" \
  --gas-budget 10000000
```

### Update Merchant Profile

Updates merchant details. Only the merchant owner can update.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function update_merchant \
  --args \
    "$SHARED_ID" \
    "$MERCHANT_ID" \
    "Updated Name" \
    "Updated Description" \
    "https://example.com/new-logo.png" \
    "https://api.merchant.com/new-callback" \
  --gas-budget 10000000
```

### Update Invoice

Updates an unpaid invoice's details. Only the merchant owner can update.

```bash
sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function update_invoice \
  --args \
    "$SHARED_ID" \
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

1. The contract uses a shared object design:
   - All merchants and invoices are stored in a single shared object
   - No need to own NFTs to interact with the contract
   - Better scalability and user experience
2. The contract uses a fixed SUI/USD rate (1 SUI = $40 USD) for demonstration
3. All USD amounts are in cents (e.g., 10000 = $100.00)
4. Timestamps are in milliseconds since Unix epoch
5. Only merchant owners can:
   - Create invoices
   - Update merchant details
   - Update invoice details
   - Withdraw balance
6. Anyone can:
   - Pay any valid invoice
   - View merchant and invoice details

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
