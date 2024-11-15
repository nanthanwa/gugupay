<script lang="ts">
  import { gugupayClient } from "@client/client";
  import MerchantModal from "@components/common/MerchantModal.svelte";
  import Toast from "@components/common/Toast.svelte";
  import WalletConnectGuard from "@components/common/WalletConnectGuard.svelte";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import {
    walletAccount,
    walletStatus,
  } from "@components/wallet/SuiModule.svelte";
  import type { MerchantObject } from "@gugupay/sdk";
  import { suiToString } from "@utils/sui";

  const urlParams = new URLSearchParams(window.location.search);
  const merchantId = urlParams.get("merchantId");

  let merchant = $state<MerchantObject | undefined>(undefined);
  let merchantModal: MerchantModal | undefined = $state();

  async function init() {
    if (!walletStatus.isConnected || !walletAccount.value) {
      throw Error("wallet not connect");
    }

    if (merchantId) {
      merchant = await gugupayClient.getMerchantDetails(
        walletAccount.value.walletAccount.address,
        merchantId,
      );
    }
  }
</script>

<WalletConnectGuard>
  <div class="hidden">{init()}</div>
  {#if merchant}
    <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
      <div class="flex w-full items-center justify-between gap-4">
        <div class="flex flex-row items-center justify-start gap-4">
          <img
            class="h-12 w-12 rounded-full object-cover lg:mx-0"
            src={merchant.logo_url}
            alt="Merchant Image"
            onerror={() => {}}
          />
          <div class="text-xl font-bold">{merchant.name}</div>
        </div>
        <button class="btn btn-primary" onclick={() => merchantModal?.open()}>
          Edit
        </button>
      </div>
    </div>
    <MerchantModal bind:this={merchantModal} bind:merchant />
  {:else}
    <div class="mx-auto my-8">Merchant not found</div>
  {/if}
</WalletConnectGuard>
<Toast />
