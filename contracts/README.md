# Environment variables

PACKAGE_ID=0xbe89f332c52be4d38351a0d23d404cc917b672cc05fb1ccd2fdf9518907b2f41
STATE_OBJECT_ID=0x49a411c0f66aecee659647d945688637712166c858dc1dab341f481a95f5c0c7
CLOCK_OBJECT_ID=0x6
TREASURY_COIN_OBJECT_ID=0xf68f46e831063816099522c5ebd5a82503484a0f8048dc75bbe2eeccc9c65563
MERCHANT_NFT_ID=0x444d54d97ea74c5334351bff9d9aa8f0e13f7003589ba4a9d7ad479ea521c370

## Create merchant

```
sui client call \
  --package 0xbe89f332c52be4d38351a0d23d404cc917b672cc05fb1ccd2fdf9518907b2f41 \
  --module gugupay \
  --function create_merchant \
  --args \
    "0x49a411c0f66aecee659647d945688637712166c858dc1dab341f481a95f5c0c7" \
    "Test Merchant" \
    "Test Description" \
    "test_logo.png" \
  --gas-budget 10000000
```

## Create invoice

```
sui client call \
  --package 0xbe89f332c52be4d38351a0d23d404cc917b672cc05fb1ccd2fdf9518907b2f41 \
  --module gugupay \
  --function create_invoice \
  --args \
    "0x49a411c0f66aecee659647d945688637712166c858dc1dab341f481a95f5c0c7" \
    "0x444d54d97ea74c5334351bff9d9aa8f0e13f7003589ba4a9d7ad479ea521c370" \
    "Test Invoice" \
    "1" \
    "0x6" \
  --gas-budget 10000000
```

## Pay invoice

```
sui client call \
  --package 0xbe89f332c52be4d38351a0d23d404cc917b672cc05fb1ccd2fdf9518907b2f41 \
  --module gugupay \
  --function pay_invoice \
  --args \
    "0x49a411c0f66aecee659647d945688637712166c858dc1dab341f481a95f5c0c7" \
    "1" \
    "0x444d54d97ea74c5334351bff9d9aa8f0e13f7003589ba4a9d7ad479ea521c370" \
    "0x3b7e6781ff94d2fe4557fc79ab0c9d1c0ef247730530a6106f852c0075ad6406" \
    "0x6" \
  --gas-budget 10000000
```

## Withdraw funds

```
sui client call \
  --package 0xbe89f332c52be4d38351a0d23d404cc917b672cc05fb1ccd2fdf9518907b2f41 \
  --module gugupay \
  --function withdraw_sui \
  --args \
    "0x444d54d97ea74c5334351bff9d9aa8f0e13f7003589ba4a9d7ad479ea521c370" \
    "0x2ccdb80e0d85f536dad59cdb83e3e3f82fddb9a0bd9b0ed39ace36549eb3b0ed" \
  --gas-budget 10000000
```
