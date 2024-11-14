<script lang="ts">
  import { gugupayClient } from "@client/client";
  import { signAndExecuteTransactionBlock } from "@components/wallet/SuiModule.svelte";
  import { Transaction } from "@mysten/sui/transactions";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import {
    walletStatus,
    walletAccount,
  } from "@components/wallet/SuiModule.svelte";

  const createMerchant = () => {
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

  const createInvoice = async () => {
    const merchantId =
      "0xebd379474995d9a706d5b0f30966d2de02e36beaba5240201a7f33d9c5a3a6fc";
    const txb = new Transaction();
    const priceUpdateData =
      await gugupayClient.connection.getPriceFeedsUpdateData([
        gugupayClient.PYTH_PRICE_FEED_ID,
      ]);
    const priceInfoObjectIds = await gugupayClient.PYTH_CLIENT.updatePriceFeeds(
      txb,
      priceUpdateData,
      [gugupayClient.PYTH_PRICE_FEED_ID],
    );
    console.log("priceInfoObjectIds", priceInfoObjectIds);

    gugupayClient.createInvoice({
      txb,
      merchantId,
      amount_usd: 100,
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
    <button class="btn btn-primary" onclick={createMerchant}
      >createMerchant</button
    >
  </div>
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <button class="btn btn-primary" onclick={createInvoice}
      >createInvoice</button
    >
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
