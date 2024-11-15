<script lang="ts">
  import { Byte, Encoder } from "@nuintun/qrcode";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import {
    signAndExecuteTransactionBlock,
    walletAccount,
    walletStatus,
  } from "@components/wallet/SuiModule.svelte";
  import { suiToString } from "@utils/sui";
  import Toast from "@components/common/Toast.svelte";
  import type { InvoiceObject, MerchantObject } from "@gugupay/sdk";
  import { addToastMessage } from "@stores/toastStore";
  import { gugupayClient } from "@client/client";
  import { loadingWalletDataAtom } from "@stores/loadingStore";
  import { Transaction } from "@mysten/sui/transactions";

  const urlParams = new URLSearchParams(window.location.search);
  const invoiceId = urlParams.get("invoiceId");

  let countdownMin = $state(0);
  let countdownSec = $state(0);
  let isExpired = $state(false);

  const qrDataURL = new Encoder({
    level: "H",
  })
    .encode(new Byte(location.href))
    .toDataURL(undefined, {});

  let invoice = $state<InvoiceObject | undefined>({
    amountSui: 100000000000,
    amountUsd: 10,
    isPaid: false,
    description: "",
    exchangeRate: 0,
    expiresAt: 0,
    merchantId: "",
    rateTimestamp: 0,
  });
  let merchant = $state<MerchantObject | undefined>({
    name: "Mock Merchant",
    logo_url: "/apple-touch-icon.png",
    callback_url: "",
    description: "",
    merchantId: "",
  });

  async function init() {
    loadingWalletDataAtom.set(true);
    try {
      if (!invoiceId) {
        throw new Error("Invoice not found");
      }

      // random wallet is use to similate transaction without wallet
      const randomWallet =
        "0xac5bceec1b789ff840d7d4e6ce4ce61c90d190a7f8c4f4ddf0bff6ee2413c33c";

      invoice = await gugupayClient.getInvoiceDetails(
        walletAccount.value?.walletAccount.address || randomWallet,
        invoiceId,
      );

      merchant = await gugupayClient.getMerchantDetails(
        walletAccount.value?.walletAccount.address || randomWallet,
        invoice.merchantId,
      );

      const intervalId = setInterval(() => {
        if (!invoice) {
          clearInterval(intervalId);
          return;
        }
        const currentTIme = Math.floor(Date.now() / 1000);
        const timeLeft = invoice.expiresAt / 1000 - currentTIme;
        if (timeLeft < 0) {
          isExpired = true;
          clearInterval(intervalId);
          return;
        }
        countdownMin = Math.floor(timeLeft / 60);
        countdownSec = timeLeft % 60;
      }, 500);
    } catch (error: any) {
      console.error(error);
      invoice = undefined;
      merchant = undefined;
      addToastMessage("Get invoice error: " + error.message, "error");
    } finally {
      loadingWalletDataAtom.set(false);
    }
  }
  init();

  async function transfer() {
    try {
      if (!invoiceId || !invoice) {
        throw new Error("Invoice not found");
      }

      const txb = new Transaction();
      gugupayClient.payInvoice({
        txb,
        invoiceId: invoiceId,
        amountSui: invoice.amountSui,
      });
      await signAndExecuteTransactionBlock(txb);
      addToastMessage("Payment success", "success");

      if (merchant?.callback_url) {
        var callbackURL = new URL(merchant.callback_url);
        callbackURL.searchParams.append("invoiceId", invoiceId);
        callbackURL.searchParams.append("merchantId", invoice.merchantId);
        location.href = callbackURL.toString();
      }
    } catch (error: any) {
      console.error(error);
      addToastMessage("Payment failed: " + error.message, "error");
    }
  }
</script>

<div
  class="bg-base-100 flex w-full max-w-screen-md flex-col items-center justify-center gap-8 rounded-xl px-4 py-6 lg:px-6 {$loadingWalletDataAtom &&
    'pointer-events-none animate-pulse blur-sm'}"
>
  {#if invoice && merchant}
    <div class="text-md">Pay via GuguPay</div>
    <div class="flex w-full items-center justify-center gap-4">
      <img
        class="h-12 w-12 rounded-full object-cover lg:mx-0"
        src={merchant.logo_url}
        alt="Merchant Image"
        onerror={() => {
          if (merchant) merchant.logo_url = "/apple-touch-icon.png";
        }}
      />
      <div class="text-xl font-bold">{merchant.name}</div>
    </div>
    <div>
      <img class="h-44 w-44" src={qrDataURL} alt="qr" />
    </div>
    <div class="flex gap-2">
      {#if invoice.isPaid}
        <div class="text-success text-xl">Invoice is paid</div>
      {:else if isExpired}
        <div class="text-error text-xl">Invoice is expired</div>
      {:else}
        <div>Expires in</div>
        {#if countdownMin > 0}
          <div>
            <span class="countdown font-mono text-lg">
              <span style="--value:{countdownMin};"></span>
            </span>
            min
          </div>
        {/if}
        <div>
          <span class="countdown font-mono text-lg">
            <span style="--value:{countdownSec};"></span>
          </span>
          sec
        </div>
      {/if}
    </div>
    <div class="flex w-full flex-col gap-4">
      <div class="flex w-full flex-col gap-2">
        <dl class="flex w-full items-center justify-between gap-4">
          <dt>Original Amount</dt>
          <dd class="font-bold">{invoice.amountUsd} USD</dd>
        </dl>
        <dl class="flex w-full items-center justify-between gap-4">
          <dt>Exchange Rate</dt>
          <dd class="font-bold">
            {suiToString(invoice.exchangeRate)} SUI / USD
          </dd>
        </dl>
      </div>
      <dl class="flex items-center justify-between gap-4 border-t pt-2">
        <dt class="text-base font-bold">Pay Amount</dt>
        <dd class="text-base font-bold">
          {suiToString(invoice.amountSui)} SUI
        </dd>
      </dl>
    </div>
    {#if invoice.isPaid}
      <div
        class="btn btn-success border-base-300 w-full max-w-screen-md rounded-full"
      >
        Transaction Success
      </div>
    {:else if walletStatus.isConnected}
      <div class="flex w-full flex-col items-center justify-center">
        {#if isExpired}
          <button
            class="btn btn-error border-base-300 w-full max-w-screen-md rounded-full"
            disabled
          >
            Invoice is expired
          </button>
        {:else}
          <button
            class="btn btn-primary border-base-300 w-full max-w-screen-md rounded-full"
            onclick={transfer}
          >
            Transfer
          </button>
        {/if}
      </div>
    {:else}
      <div class="flex w-full flex-col items-center justify-center">
        <ConnectButton
          class="btn btn-primary border-base-300 w-full max-w-screen-md rounded-full"
        ></ConnectButton>
      </div>
    {/if}
  {:else}
    <div
      class="bg-base-100 flex w-full max-w-screen-md flex-col items-center justify-center gap-8 rounded-xl px-4 py-6 lg:px-6"
    >
      <div class="text-md">Invoice not found</div>
    </div>
  {/if}
</div>
<Toast />
