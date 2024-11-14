<script lang="ts">
  import { Byte, Encoder } from "@nuintun/qrcode";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import { walletStatus } from "@components/wallet/SuiModule.svelte";
  import { suiToString } from "@utils/sui";

  const encoder = new Encoder({
    level: "H",
  });
  const qrcode = encoder.encode(new Byte(location.href));

  const qrDataURL = qrcode.toDataURL(undefined, {});

  const merchantName = "Merchant Name";

  const expiredTime = 1731597294 + 6000;
  let countdownMin = $state(0);
  let countdownSec = $state(0);

  setInterval(() => {
    const currentTIme = Math.floor(Date.now() / 1000);
    const timeLeft = expiredTime - currentTIme;
    countdownMin = Math.floor(timeLeft / 60);
    countdownSec = timeLeft % 60;
  }, 500);
</script>

<div
  class="bg-base-100 flex w-full max-w-screen-md flex-col items-center justify-center gap-8 rounded-xl px-4 py-6 lg:px-6"
>
  <div class="text-lg">Pay via GuguPay</div>
  <div class="flex w-full items-center justify-center gap-4">
    <img
      class="h-12 w-12 rounded-full object-cover lg:mx-0"
      src="/apple-touch-icon.png"
      alt="Merchant Image"
      onerror={() => {}}
    />
    <div class="text-xl font-bold">{merchantName}</div>
  </div>
  <div class="flex items-end gap-2">
    <div>Expire in</div>
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
  </div>
  <div>
    <img class="h-44 w-44" src={qrDataURL} alt="qr" />
  </div>
  <div class="flex w-full flex-col gap-4">
    <div class="flex w-full flex-col gap-2">
      <dl class="flex w-full items-center justify-between gap-4">
        <dt>Original Amount</dt>
        <dd class="font-bold">{suiToString(10000000000)} SUI</dd>
      </dl>
      <dl class="flex w-full items-center justify-between gap-4">
        <dt>Exchange Rate</dt>
        <dd class="text-error font-bold">+ {suiToString(10000000000)} SUI</dd>
      </dl>
      <dl class="flex w-full items-center justify-between gap-4">
        <dt>Gas Fee</dt>
        <dd class="text-error font-bold">+ {suiToString(100000000)} SUI</dd>
      </dl>
    </div>
    <dl class="flex items-center justify-between gap-4 border-t pt-2">
      <dt class="text-base font-bold">Pay Amount</dt>
      <dd class="text-base font-bold">
        {suiToString(10000000000)} SUI
      </dd>
    </dl>
  </div>
  <!-- <div
    class="space-y-4 rounded-lg border border-gray-100 bg-gray-50 p-6 dark:border-gray-600 dark:bg-gray-700"
  >
    <div class="space-y-2">
      <dl class="flex items-center justify-between gap-4">
        <dt class="text-base font-normal text-gray-500 dark:text-gray-400">
          Original price
        </dt>
        <dd class="text-base font-medium text-gray-900 dark:text-white">
          $6,592.00
        </dd>
      </dl>

      <dl class="flex items-center justify-between gap-4">
        <dt class="text-base font-normal text-gray-500 dark:text-gray-400">
          Savings
        </dt>
        <dd class="text-base font-medium text-green-500">-$299.00</dd>
      </dl>

      <dl class="flex items-center justify-between gap-4">
        <dt class="text-base font-normal text-gray-500 dark:text-gray-400">
          Store Pickup
        </dt>
        <dd class="text-base font-medium text-gray-900 dark:text-white">$99</dd>
      </dl>

      <dl class="flex items-center justify-between gap-4">
        <dt class="text-base font-normal text-gray-500 dark:text-gray-400">
          Tax
        </dt>
        <dd class="text-base font-medium text-gray-900 dark:text-white">
          $799
        </dd>
      </dl>
    </div>

    <dl
      class="flex items-center justify-between gap-4 border-t border-gray-200 pt-2 dark:border-gray-600"
    >
      <dt class="text-base font-bold text-gray-900 dark:text-white">Total</dt>
      <dd class="text-base font-bold text-gray-900 dark:text-white">
        $7,191.00
      </dd>
    </dl>
  </div> -->
  {#if walletStatus.isConnected}
    <div class="flex w-full flex-col items-center justify-center">
      <button
        class="btn btn-primary border-base-300 w-full max-w-screen-md rounded-full"
      >
        Transfer
      </button>
    </div>
  {:else}
    <div class="flex w-full flex-col items-center justify-center">
      <ConnectButton
        class="btn btn-primary border-base-300 w-full max-w-screen-md rounded-full"
      ></ConnectButton>
    </div>
  {/if}
</div>
