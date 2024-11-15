<script lang="ts">
  import { gugupayClient } from "@client/client";
  import { signAndExecuteTransactionBlock } from "@components/wallet/SuiModule.svelte";
  import { Transaction } from "@mysten/sui/transactions";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import {
    walletStatus,
    walletAccount,
  } from "@components/wallet/SuiModule.svelte";
  import Toast from "@components/common/Toast.svelte";

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
    if (!walletAccount.value?.walletAccount.address) {
      return;
    }
    const merchantIds = await gugupayClient.getMerchantsByOwner(
      walletAccount.value?.walletAccount.address,
    );
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
      merchantId: merchantIds[merchantIds.length - 1],
      amount_usd: 1,
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

  const payInvoice = async () => {
    if (!walletAccount.value?.walletAccount.address) {
      return;
    }
    const merchantIds = await gugupayClient.getMerchantsByOwner(
      walletAccount.value?.walletAccount.address,
    );
    const invoiceIds = await gugupayClient.getMerchantInvoices(
      walletAccount.value?.walletAccount.address,
      merchantIds[merchantIds.length - 1],
    );
    if (!walletAccount.value?.walletAccount.address) {
      return;
    }
    const invoiceDetails = await gugupayClient.getInvoiceDetails(
      walletAccount.value?.walletAccount.address,
      invoiceIds[invoiceIds.length - 1],
    );

    const txb = new Transaction();
    gugupayClient.payInvoice({
      txb,
      invoiceId: invoiceIds[invoiceIds.length - 1],
      amountSui: invoiceDetails.amountSui,
    });
    // console.log('txb', txb);
    signAndExecuteTransactionBlock(txb)
      .then((result) => {
        console.log("result", result);
      })
      .catch((err) => {
        console.error("errpr", err);
      });
  };
  const getMerchantsByOwner = async () => {
    if (!walletAccount.value?.walletAccount.address) {
      return;
    }
    const merchantIds = await gugupayClient.getMerchantsByOwner(
      walletAccount.value?.walletAccount.address,
    );
    console.log("merchantIds", merchantIds);
  };

  const getInvoicesByMerchant = async () => {
    if (!walletAccount.value?.walletAccount.address) {
      return;
    }
    const merchantIds = await gugupayClient.getMerchantsByOwner(
      walletAccount.value?.walletAccount.address,
    );
    if (!walletAccount.value?.walletAccount.address) {
      return;
    }
    const invoiceIds = await gugupayClient.getMerchantInvoices(walletAccount.value?.walletAccount.address, merchantIds[merchantIds.length - 1]);
    console.log('invoiceIds', invoiceIds);
  }

  const getMerchantBalance = async () => {
    if (!walletAccount.value?.walletAccount.address) {
      return;
    }
    const merchantIds = await gugupayClient.getMerchantsByOwner(walletAccount.value?.walletAccount.address);
    const balance = await gugupayClient.getMerchantBalance(walletAccount.value?.walletAccount.address, merchantIds[merchantIds.length - 1]);
    console.log('balance', balance);
  }

  const withdrawMerchantBalance = async () => {
    if (!walletAccount.value?.walletAccount.address) {
      return;
    }
    const merchantIds = await gugupayClient.getMerchantsByOwner(walletAccount.value?.walletAccount.address);
    const txb = new Transaction();
    gugupayClient.withdrawMerchantBalance(txb, merchantIds[merchantIds.length - 1]);
    signAndExecuteTransactionBlock(txb)
      .then((result) => {
        console.log("result", result);
      })
      .catch((err) => {
        console.error("errpr", err);
      });
  }
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
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <button class="btn btn-primary" onclick={payInvoice}>payInvoice</button>
  </div>
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <button class="btn btn-primary" onclick={getMerchantsByOwner}
      >getMerchantsByOwner</button
    >
  </div>
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <button class="btn btn-primary" onclick={getInvoicesByMerchant}
      >getInvoicesByMerchant</button
    >
  </div>
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <button class="btn btn-primary" onclick={getMerchantBalance}
      >getMerchantBalance</button
    >
  </div>
  <div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
    <button class="btn btn-primary" onclick={withdrawMerchantBalance}
      >withdrawMerchantBalance</button
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

<Toast />
