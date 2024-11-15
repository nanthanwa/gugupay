<script lang="ts">
  import { Byte, Encoder } from "@nuintun/qrcode";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import { walletStatus } from "@components/wallet/SuiModule.svelte";
  import { suiToString } from "@utils/sui";
  import Toast from "@components/common/Toast.svelte";

  const urlParams = new URLSearchParams(window.location.search);
  const invoiceId = urlParams.get("invoiceId");

  const qrDataURL = new Encoder({
    level: "H",
  })
    .encode(new Byte(location.href))
    .toDataURL(undefined, {});

  if (invoiceId) {
  }

  let merchantName = "Merchant Name";
  let merchnatLogo = "/apple-touch-icon.png";
  let expiredTime = Math.floor(Date.now() / 1000) + 61;
  let invoiceAmount = 10000000000;
  let exchangeRate = 12000000;
  let gasFee = 10000000;
  let totalAmount = invoiceAmount + exchangeRate + gasFee;

  let countdownMin = $state(0);
  let countdownSec = $state(0);
  let isExpired = $state(false);

  const intervalId = setInterval(() => {
    const currentTIme = Math.floor(Date.now() / 1000);
    const timeLeft = expiredTime - currentTIme;
    if (timeLeft < 0) {
      isExpired = true;
      clearInterval(intervalId);
      return;
    }
    countdownMin = Math.floor(timeLeft / 60);
    countdownSec = timeLeft % 60;
  }, 500);
</script>

<div
  class="bg-base-100 flex w-full max-w-screen-md flex-col items-center justify-center gap-8 rounded-xl px-4 py-6 lg:px-6"
>
  <div class="text-md">Pay via GuguPay</div>
  <div class="flex w-full items-center justify-center gap-4">
    <img
      class="h-12 w-12 rounded-full object-cover lg:mx-0"
      src={merchnatLogo}
      alt="Merchant Image"
      onerror={() => {}}
    />
    <div class="text-xl font-bold">{merchantName}</div>
  </div>
  <div>
    <img class="h-44 w-44" src={qrDataURL} alt="qr" />
  </div>
  <div class="flex gap-2">
    {#if isExpired}
      <div class="text-error">Invoice is expired</div>
    {:else}
      <div>Expires in</div>
      <div>
        <span class="countdown font-mono text-lg">
          <span style="--value:{countdownMin};"></span>
        </span>
        min
      </div>
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
        <dd class="font-bold">{suiToString(invoiceAmount)} SUI</dd>
      </dl>
      <dl class="flex w-full items-center justify-between gap-4">
        <dt>Exchange Rate</dt>
        <dd class="text-error font-bold">+ {suiToString(exchangeRate)} SUI</dd>
      </dl>
      <dl class="flex w-full items-center justify-between gap-4">
        <dt>Gas Fee</dt>
        <dd class="text-error font-bold">+ {suiToString(gasFee)} SUI</dd>
      </dl>
    </div>
    <dl class="flex items-center justify-between gap-4 border-t pt-2">
      <dt class="text-base font-bold">Pay Amount</dt>
      <dd class="text-base font-bold">
        ~{suiToString(totalAmount)} SUI
      </dd>
    </dl>
  </div>
  {#if walletStatus.isConnected}
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
</div>

<Toast />
