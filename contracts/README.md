# Environment variables

PACKAGE_ID=0x05961adfbdf23bbef78a35492b84e766775c2c176c5bd7932ff2f32989b35925
STATE_OBJECT_ID=0xaac327f9ef106aea3d9ae2cff4191d10cf1c020d34b7bf65c3acf4d7411c8f8e
CLOCK_OBJECT_ID=0x6
TREASURY_COIN_OBJECT_ID=0xf68f46e831063816099522c5ebd5a82503484a0f8048dc75bbe2eeccc9c65563
MERCHANT_NFT_ID=0xacda49977002ea0bd562e5672b7416512ffbfc38a754bf32c07cd63aeefe072a
INVOICE_NFT_ID=0x05961adfbdf23bbef78a35492b84e766775c2c176c5bd7932ff2f32989b35925

## Create merchant

```
sui client call \
  --package 0x05961adfbdf23bbef78a35492b84e766775c2c176c5bd7932ff2f32989b35925 \
  --module gugupay \
  --function create_merchant \
  --args \
    "0xaac327f9ef106aea3d9ae2cff4191d10cf1c020d34b7bf65c3acf4d7411c8f8e" \
    "Test Merchant" \
    "Test Description" \
    "test_logo.png" \
    "https://example.com" \
  --gas-budget 10000000
```

## Create invoice

```
sui client call \
  --package 0x05961adfbdf23bbef78a35492b84e766775c2c176c5bd7932ff2f32989b35925 \
  --module gugupay \
  --function create_invoice \
  --args \
    "0xaac327f9ef106aea3d9ae2cff4191d10cf1c020d34b7bf65c3acf4d7411c8f8e" \
    "0xacda49977002ea0bd562e5672b7416512ffbfc38a754bf32c07cd63aeefe072a" \
    "Test Invoice" \
    "1" \
    "0x6" \
  --gas-budget 10000000
```

## Pay invoice

```
sui client call \
  --package 0x05961adfbdf23bbef78a35492b84e766775c2c176c5bd7932ff2f32989b35925 \
  --module gugupay \
  --function pay_invoice \
  --args \
    "0xaac327f9ef106aea3d9ae2cff4191d10cf1c020d34b7bf65c3acf4d7411c8f8e" \
    "1" \
    "0xacda49977002ea0bd562e5672b7416512ffbfc38a754bf32c07cd63aeefe072a" \
    "0x85414f3fe9eb34b617afa902ba9f26803d7d77961e6c087044ab0e76f2640e45" \
    "0x6" \
  --gas-budget 10000000
```

## Withdraw funds

```
sui client call \
  --package 0x05961adfbdf23bbef78a35492b84e766775c2c176c5bd7932ff2f32989b35925 \
  --module gugupay \
  --function withdraw_sui \
  --args \
    "0xacda49977002ea0bd562e5672b7416512ffbfc38a754bf32c07cd63aeefe072a" \
    "0xcca5a2ac68d87708d3c6c0fe6cb2a58b1575e011af583ec354739280902d4101" \
  --gas-budget 10000000
```

Deploy
sui client publish --gas-budget 50000000
