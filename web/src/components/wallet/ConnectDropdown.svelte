<script lang="ts">
  import { loadingWalletDataAtom } from "@stores/loadingStore";
  import { shortAddress, suiToString } from "@utils/sui";
  import ConnectButton from "./ConnectButton.svelte";
  import {
    disconnectWallet,
    selectWalletAccount,
    walletAccounts,
    walletAccount,
    walletAccountIdx,
  } from "./SuiModule.svelte";
</script>

{#if walletAccount.value}
  <div
    class="dropdown dropdown-bottom dropdown-end w-48 lg:w-64 {$loadingWalletDataAtom &&
      'pointer-events-none animate-pulse blur-sm'}"
  >
    <button
      class="btn btn-sm lg:btn-md bg-base-100 border-base-300 m-0 flex w-full justify-between rounded-full"
    >
      <div class="text-xs lg:text-base">
        {shortAddress(walletAccount.value.walletAccount.address)}
      </div>
      <div class="lg:gap-x flex gap-x-1 text-xs">
        <div class="text-right">
          {suiToString(walletAccount.value.suiBalance)}
        </div>
        <div class="text-left">SUI</div>
      </div>
    </button>
    <div
      class="dropdown-content text-primary-content z-[1] flex w-full flex-col gap-1 pt-1"
    >
      {#each walletAccounts.value as wallet, index}
        {#if index !== walletAccountIdx.value}
          <button
            class="btn btn-sm lg:btn-md bg-base-100 border-base-300 m-0 flex w-full justify-between rounded-full"
            onclick={() => {
              selectWalletAccount(index);
            }}
          >
            <div class="text-xs lg:text-base">
              {shortAddress(wallet.walletAccount.address)}
            </div>
            <div class="flex gap-x-1 text-xs lg:gap-x-2">
              <div class="text-right">
                {suiToString(wallet.suiBalance)}
              </div>
              <div class="text-left">SUI</div>
            </div>
          </button>
        {/if}
      {/each}
      <button
        class="btn btn-sm lg:btn-md btn-error border-base-300 w-full rounded-full"
        onclick={disconnectWallet}>Disconnect</button
      >
    </div>
  </div>
{:else}
  <ConnectButton
    class="btn btn-sm lg:btn-md bg-base-100 border-base-300 rounded-full"
  />
{/if}
