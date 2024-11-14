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
</script>

<div
  class="bg-base-100 flex w-full max-w-screen-md flex-col items-center justify-center gap-8 rounded-xl px-4 py-6 lg:px-6"
>
  <div class="text-lg">Pay via GuguPay</div>
  <div>
    <img class="h-44 w-44" src={qrDataURL} alt="qr" />
  </div>
  <div class="flex w-full items-center justify-start gap-4">
    <img
      class="mx-auto h-12 w-12 rounded-full object-cover lg:mx-0"
      src="/apple-touch-icon.png"
      alt="Merchant Image"
      onerror={() => {}}
    />
    <div class="text-xl font-bold">{merchantName}</div>
  </div>
  <div class="flex w-full items-center justify-between gap-4">
    <div>Amount</div>
    <div>{suiToString(10)} SUI</div>
  </div>
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
