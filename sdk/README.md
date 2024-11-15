## Usage

```
import { GugupayClient } from "@gugupay/sdk";

// Initialize client
const client = new GugupayClient("testnet");

const txb = new Transaction();

// Create merchant
client.createMerchantObject({
  txb,
  name: "Coffee Shop",
  imageURL: "logo.png",
  callbackURL: "https://myshop.com/callback",
  description: "Best coffee in town"
});

// Create invoice
await client.createInvoice({
  txb,
  merchantId,
  amount_usd: 5.00,
  description: "Large Coffee"
});

// Create transaction to pay
client.payInvoice({
  txb,
  invoiceId,
  amountSui: invoiceDetails.amountSui,
});
```
