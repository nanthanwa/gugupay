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
PACKAGE_ID=0xd5ed14767ae11ddabaf0502839e83bcf628e5a8b8bbc584ecf8de98d9ef3b686
SHARED_ID=0x80976d983484dee65f26e4c5c0d8e1ee610f977c233f73b554db7d01d20b4a33
MERCHANT_ID=0x134d1e8e4cfcd79e3996862ed77f4ee39c32cf9afbfb41417ca4dec9ed010ca9
INVOICE_ID=0xa664eaa910490c3e054b50841a81e511e3d118f853e5f265cea7229751300fa4
CLOCK_ID=0x6
PYTH_PACKAGE_ID=0xf7114cc10266d90c0c9e4b84455bddf29b40bd78fe56832c7ac98682c3daa95b
PYTH_PRICE_FEED_ID=0xf47329f4344f3bf0f8e436e2f7b485466cff300f12a166563995d3888c296a94
COIN_ID=0xbc4304f48baf53d21243c9d879211036cac0a8dd92fd2254932a7ba8117dc97a
WORMHOLE_STATE_ID=0xebba4cc4d614f7a7cdbe883acc76d1cc767922bc96778e7b68be0d15fce27c02
PYTH_STATE_ID=0x2d82612a354f0b7e52809fc2845642911c7190404620cec8688f68808f8800d8
PRICE_INFO_OBJECT_ID=0x1ebb295c789cc42b3b2a1606482cd1c7124076a0f5676718501fda8c7fd075a0
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
    "$CLOCK_ID" \
    "0x1ebb295c789cc42b3b2a1606482cd1c7124076a0f5676718501fda8c7fd075a0" \
  --gas-budget 10000000
```

sui client call \
  --package $PACKAGE_ID \
  --module payment_service \
  --function create_invoice \
  --args \
    "$CLOCK_ID" \
    "0x1ebb295c789cc42b3b2a1606482cd1c7124076a0f5676718501fda8c7fd075a0" \
  --gas-budget 10000000


#### Create a PTB that:
1. Updates Pyth price feed
2. Uses the result to create an invoice

```bash
sui client ptb \
--move-call pyth::pyth::update_price_feeds \
"[price_update_data]" "[price_feed_ids]" \
--assign price_info \
--move-call payment_service::payment_service::create_invoice \
"$SHARED_ID" "$MERCHANT_ID" "Invoice Description" 10 "$CLOCK_ID" price_info \
--gas-budget 100000000


# Add --preview flag to see the transaction sequence without executing
sui client ptb \
--move-call pyth::pyth::update_price_feeds \
"$WORMHOLE_STATE_ID" "$PYTH_STATE_ID" \
--assign price_info \
--move-call "$PACKAGE_ID"::payment_service::create_invoice \
"$SHARED_ID" "$MERCHANT_ID" "Invoice Description" 10 "$CLOCK_ID" price_info \
--gas-budget 100000000


sui client ptb \
--move-call "$PYTH_PACKAGE_ID"::pyth::update_price_feeds \
"$WORMHOLE_STATE_ID" "$PYTH_STATE_ID" \
--assign price_info \
--gas-budget 100000000
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
