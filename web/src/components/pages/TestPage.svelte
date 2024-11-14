<script lang="ts">
  import { gugupayClient } from "@client/client";
  import { signAndExecuteTransactionBlock } from "@components/wallet/SuiModule.svelte";
  import { Transaction } from "@mysten/sui/transactions";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import { walletStatus } from "@components/wallet/SuiModule.svelte";

  const sign = () => {
    const txb = new Transaction();
    gugupayClient.createMerchantObject({
      txb,
      name: "Test Merchant",
      imageURL: "https://example.com/image.png",
      callbackURL: "https://example.com/callback",
      description: "Test Description",
    });
    signAndExecuteTransactionBlock(txb)
      .then((result) => {
        console.log("result", result);
      })
      .catch((err) => {
        console.error("errpr", err);
      });
  };
</script>

{#if walletStatus.isConnected}
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <button class="btn btn-primart" onclick={sign}>Test</button>
  </div>
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
