<script lang="ts">
  import { gugupayClient } from "@client/client";
  import InvoiceModal from "@components/common/InvoiceModal.svelte";
  import MerchantModal from "@components/common/MerchantModal.svelte";
  import Toast from "@components/common/Toast.svelte";
  import WalletConnectGuard from "@components/common/WalletConnectGuard.svelte";
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import {
    signAndExecuteTransactionBlock,
    walletAccount,
    walletStatus,
  } from "@components/wallet/SuiModule.svelte";
  import type { InvoiceObject, MerchantObject } from "@gugupay/sdk";
  import { Transaction } from "@mysten/sui/transactions";
  import { addToastMessage } from "@stores/toastStore";
  import { shortAddress, suiToString } from "@utils/sui";

  const urlParams = new URLSearchParams(window.location.search);
  const merchantId = urlParams.get("merchantId");

  let merchant = $state<MerchantObject | undefined>({
    name: "",
    logo_url: "",
    callback_url: "",
    description: "",
    merchantId: "",
  });
  let merchantBalance = $state<number>(0);
  let merchantModal: MerchantModal | undefined = $state();
  let invoiceModal: InvoiceModal | undefined = $state();
  let invoiceIds = $state<string[]>([]);
  let invoices = $state<(InvoiceObject & { id: string })[]>([]);

  async function init() {
    try {
      if (!walletStatus.isConnected || !walletAccount.value) {
        throw Error("Wallet not connected");
      }
      if (!merchantId) {
        throw new Error("Merchant not found");
      }

      if (merchantId) {
        merchant = await gugupayClient.getMerchantDetails(
          walletAccount.value.walletAccount.address,
          merchantId,
        );
        merchantBalance = await gugupayClient.getMerchantBalance(
          walletAccount.value.walletAccount.address,
          merchantId,
        );

        if (!merchant.name) {
          merchant = undefined;
          return;
        }

        invoiceIds = await gugupayClient.getMerchantInvoices(
          walletAccount.value.walletAccount.address,
          merchantId,
        );

        const newInvoices = [];
        for (let i = 0; i < invoiceIds.length; i++) {
          const invoiceId = invoiceIds[i];
          const invoice = await gugupayClient.getInvoiceDetails(
            walletAccount.value.walletAccount.address,
            invoiceId,
          );
          newInvoices.unshift({
            ...invoice,
            id: invoiceId,
          });
        }
        invoices = newInvoices;
      }
    } catch (error: any) {
      console.error(error);
      addToastMessage("Get merchant failed: " + error.message, "error");
    }
  }

  async function withdraw() {
    try {
      if (!walletStatus.isConnected || !walletAccount.value) {
        throw Error("Wallet not connected");
      }
      if (!merchantId) {
        throw new Error("Merchant not found");
      }

      const txb = new Transaction();
      const withdrawTxb = await gugupayClient.withdrawMerchantBalance(
        txb,
        merchantId,
      );
      await signAndExecuteTransactionBlock(withdrawTxb);

      addToastMessage("Withdraw success", "success");
    } catch (error: any) {
      addToastMessage("Withdraw failed: " + error.message, "error");
    }
  }

  function onInvoiceCreated() {
    init();
  }
</script>

<WalletConnectGuard>
  <div class="hidden">{init()}</div>
  {#if merchant}
    <div class="flex w-full flex-col gap-8 px-4 py-6 lg:px-6">
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
      <div class="flex flex-row items-center justify-between">
        <div class="flex flex-row items-center justify-start gap-4">
          <div class="text-xl font-bold">Balance</div>
          <div
            class="ml-auto flex flex-row items-center justify-end gap-2 text-xl lg:ml-0"
          >
            {suiToString(merchantBalance)} SUI
          </div>
        </div>
        <button
          class="btn btn-primary"
          onclick={() => {
            withdraw();
          }}
        >
          Withdraw
        </button>
      </div>
      <div class="divider"></div>
      <div class="flex flex-row items-center justify-between">
        <div class="text-xl font-bold">Invoices</div>
        <button class="btn btn-primary" onclick={invoiceModal?.open}>
          New Invoice</button
        >
      </div>
      <div class="flex flex-col gap-4 rounded-lg">
        {#if invoices.length > 0}
          {#each invoices as invoice}
            <a
              href={`/pay?invoiceId=${invoice.id}`}
              class="bg-base-100 flex w-full flex-row items-center justify-between rounded-lg p-4"
            >
              <div class="flex flex-row justify-start gap-4">
                {#if invoice.isPaid}
                  <div class="text-success text-lg">Success</div>
                {:else if invoice.expiresAt < Date.now()}
                  <div class="text-error text-lg">Expired</div>
                {:else}
                  <div class="text-lg">Pending</div>
                {/if}
                <div class="text-lg font-bold">{shortAddress(invoice.id)}</div>
              </div>
              <div class="flex flex-col items-end gap-1">
                <div class="text-lg">{invoice.amountUsd} USD</div>
                <div class="text-lg">
                  {suiToString(invoice.amountSui)} SUI
                </div>
              </div>
            </a>
          {/each}
        {:else}
          <div class="mx-auto my-8 w-full text-center text-lg">
            Invoices not found
          </div>
        {/if}
      </div>
    </div>
    <InvoiceModal
      bind:this={invoiceModal}
      bind:merchant
      onCreated={onInvoiceCreated}
    />
    {#if merchant.name}
      <MerchantModal bind:this={merchantModal} {merchant} />
    {/if}
  {:else}
    <div class="mx-auto my-8 w-full text-center text-lg">
      Merchant not found
    </div>
  {/if}
</WalletConnectGuard>
<Toast />
