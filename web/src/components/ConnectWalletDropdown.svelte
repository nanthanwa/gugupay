<script lang="ts">
  import { loadingWalletDataAtom } from "@stores/loadingStore";
  import {
    disconnectWallet,
    walletStateAtom,
    changeWallet,
  } from "@stores/walletStore";
  import { shortAddress, suiToString } from "@utils/sui";
  import ConnectWalletButton from "./ConnectWalletButton.svelte";
</script>

{#if $walletStateAtom.wallets.length > 0}
  <div
    class="dropdown dropdown-bottom dropdown-end w-72 {$loadingWalletDataAtom &&
      'pointer-events-none animate-pulse blur-sm'}"
  >
    <button
      class="btn bg-base-100 border-base-300 flex w-full justify-between rounded-full"
    >
      <div>
        {shortAddress(
          $walletStateAtom.wallets[$walletStateAtom.walletIdx].walletAccount
            .address,
        )}
      </div>
      <div class="flex flex-col text-xs">
        <div class="flex gap-x-2">
          <div class="text-right">
            {suiToString(
              $walletStateAtom.wallets[$walletStateAtom.walletIdx].suiBalance,
            )}
          </div>
          <div class="text-left">SUI</div>
        </div>
        <div class="flex gap-x-2">
          <div class="text-right">
            {$walletStateAtom.wallets[$walletStateAtom.walletIdx].merchantObjs
              .length}
          </div>
          <div class="text-left">Merchant</div>
        </div>
      </div>
    </button>
    <div
      class="dropdown-content text-primary-content z-[1] flex w-full flex-col gap-1 pt-1"
    >
      {#each $walletStateAtom.wallets as wallet, index}
        {#if index !== $walletStateAtom.walletIdx}
          <button
            class="btn bg-base-100 border-base-300 flex w-full justify-between rounded-full"
            onclick={() => {
              changeWallet(index);
            }}
          >
            <div>
              {shortAddress(wallet.walletAccount.address)}
            </div>
            <div class="flex flex-col text-xs">
              <div class="flex gap-x-2">
                <div class="text-right">
                  {suiToString(wallet.suiBalance)}
                </div>
                <div class="text-left">SUI</div>
              </div>
              <div class="flex gap-x-2">
                <div class="text-right">
                  {wallet.merchantObjs.length}
                </div>
                <div class="text-left">Merchant</div>
              </div>
            </div>
          </button>
        {/if}
      {/each}
      <button
        class="btn btn-error border-base-300 w-full rounded-full"
        onclick={async () => {
          await disconnectWallet();
        }}>Disconnect</button
      >
    </div>
  </div>
{:else}
  <ConnectWalletButton />
{/if}
