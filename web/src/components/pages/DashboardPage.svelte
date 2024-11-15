<script lang="ts">
  import { gugupayClient } from "@client/client";
  import MerchantModal from "@components/common/MerchantModal.svelte";
  import Toast from "@components/common/Toast.svelte";
  import WalletConnectGuard from "@components/common/WalletConnectGuard.svelte";
  import {
    walletAccount,
    walletStatus,
  } from "@components/wallet/SuiModule.svelte";
  import type { MerchantObject } from "@gugupay/sdk";
  import { suiToString } from "@utils/sui";

  let merchantModal: MerchantModal | undefined = $state();
  const merchants = $state<(MerchantObject & { balance: number })[]>([]);

  async function init() {
    if (!walletStatus.isConnected || !walletAccount.value) {
      throw Error("wallet not connect");
    }

    const merchantIds = await gugupayClient.getMerchantsByOwner(
      walletAccount.value.walletAccount.address,
    );

    for (let i = 0; i < merchantIds.length; i++) {
      const merchantId = merchantIds[i];
      const merchantDetail = await gugupayClient.getMerchantDetails(
        walletAccount.value.walletAccount.address,
        merchantId,
      );
      const merchantBalance = await gugupayClient.getMerchantBalance(
        walletAccount.value.walletAccount.address,
        merchantId,
      );

      merchants.push({
        ...merchantDetail,
        balance: merchantBalance,
      });
    }
  }
</script>

<WalletConnectGuard>
  <div class="hidden">{init()}</div>
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <div class="flex w-full flex-row items-center justify-between">
      <div class="text-xl font-bold">Merchants</div>
      <button
        class="btn btn-primary"
        onclick={() => {
          merchantModal?.open();
        }}>New Merchant</button
      >
    </div>
    <div class="w-full">
      <div class="flex flex-col gap-2">
        {#if merchants.length > 0}
          {#each merchants as merchant}
            <a
              href={`/app/merchant?merchantId=${merchant.merchantId}`}
              class="card bg-base-100 flex cursor-pointer flex-col items-start justify-start gap-8 rounded-2xl p-4 shadow-xl lg:flex-row lg:items-center"
            >
              <img
                class="mx-auto h-20 w-20 rounded-full object-cover lg:mx-0"
                src={merchant.logo_url}
                alt="Merchant Test"
                onerror={() => {}}
              />
              <div class="mr-0 flex flex-col gap-2 lg:mr-auto">
                <div class="text-2xl">{merchant.name}</div>
                <div class="text-lg">{merchant.description}</div>
              </div>
              <div
                class="ml-auto flex flex-row items-center justify-end gap-2 text-xl lg:ml-0"
              >
                {suiToString(merchant.balance)} SUI
              </div>
            </a>
          {/each}
        {:else}
          <div class="mx-auto my-8">
            You don't have a merchnat, Please create one.
          </div>
        {/if}
      </div>
    </div>
  </div>
  <MerchantModal bind:this={merchantModal} />
</WalletConnectGuard>
<Toast />
