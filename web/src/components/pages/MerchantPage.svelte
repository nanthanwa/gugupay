<script lang="ts">
  import MerchantModal from "@components/common/MerchantModal.svelte";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import { walletStatus } from "@components/wallet/SuiModule.svelte";
  import { suiToString } from "@utils/sui";

  let merchantModal: MerchantModal;
</script>

{#if walletStatus.isConnected}
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <div class="flex w-full flex-row items-center justify-between">
      <div class="text-xl font-bold">Merchants</div>
      <button
        class="btn btn-primary"
        onclick={() => {
          merchantModal.open();
        }}>New Merchant</button
      >
    </div>
    <div class="w-full">
      <div class="flex flex-col gap-2">
        {#if false}
          <div
            class="card bg-base-100 flex cursor-pointer flex-col items-start justify-start gap-8 rounded-2xl p-4 shadow-xl lg:flex-row lg:items-center"
          >
            <img
              class="mx-auto h-20 w-20 rounded-full object-cover lg:mx-0"
              src="/apple-touch-icon.png"
              alt="Merchant Test"
              onerror={() => {}}
            />
            <div class="mr-0 flex flex-col gap-2 lg:mr-auto">
              <div class="text-xl">Merchant Test</div>
              <div class="text-md">Description</div>
            </div>
            <div
              class="ml-auto flex flex-row items-center justify-end gap-2 lg:ml-0"
            >
              {suiToString(15500000000)} SUI
            </div>
          </div>
        {:else}
          <div class="mx-auto my-8">
            You don't have a merchnat, Please create one.
          </div>
        {/if}
      </div>
    </div>
  </div>
  <MerchantModal bind:this={merchantModal} />
{:else}
  <div
    class="flex h-[70vh] w-full flex-col items-center justify-center gap-8 px-4 py-6 lg:px-6"
  >
    <div class="text-lg">Your Sui Wallet is not connect.</div>
    <ConnectButton
      class="btn btn-primary border-base-300 w-full max-w-screen-md rounded-full"
    ></ConnectButton>
  </div>
{/if}
