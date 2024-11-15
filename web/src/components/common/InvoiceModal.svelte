<script lang="ts">
  import { gugupayClient } from "@client/client";
  import { signAndExecuteTransactionBlock } from "@components/wallet/SuiModule.svelte";
  import type { MerchantObject } from "@gugupay/sdk";
  import { Transaction } from "@mysten/sui/transactions";
  import { addToastMessage } from "@stores/toastStore";

  type Props = { merchant: MerchantObject };

  const { merchant = $bindable() }: Props = $props();

  let isModalOpen: boolean = $state(false);

  // form data
  let amount = $state("0");
  let amountError = $state("");
  let amountNumber = $state(0);
  let description = $state("");
  let descriptionError = $state("");

  $effect(() => {
    amountNumber = parseFloat(amount);
  });

  $effect(() => {
    if (isNaN(amountNumber) || amountNumber < 0) {
      amountError = "Amount is invalid";
    } else {
      amountError = "";
    }
  });

  export function open() {
    isModalOpen = true;
  }

  function unsaveClose() {
    isModalOpen = false;
  }

  async function submit() {
    const txb = new Transaction();
    const createInvoiceTxb = await gugupayClient.createInvoice({
      txb,
      merchantId: merchant?.merchantId,
      amount_usd: amountNumber,
      description,
    });
    signAndExecuteTransactionBlock(createInvoiceTxb)
      .then((result) => {
        if (result) {
          addToastMessage("Invoice created success", "success");
          isModalOpen = false;
        }
      })
      .catch((error) => {
        console.error(error);
        addToastMessage("Failed to create invoice", "error");
      });
  }
</script>

<input type="checkbox" class="modal-toggle" bind:checked={isModalOpen} />
<dialog class="modal modal-bottom sm:modal-middle">
  <div class="modal-box rounded-none">
    <div class="flex flex-col gap-4">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold">New Merchant</h3>
        <button
          type="button"
          class="ml-auto inline-flex items-center p-1.5 text-sm"
          onclick={unsaveClose}
        >
          <svg
            aria-hidden="true"
            class="h-5 w-5"
            fill="currentColor"
            viewBox="0 0 20 20"
            xmlns="http://www.w3.org/2000/svg"
            ><path
              fill-rule="evenodd"
              d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
              clip-rule="evenodd"
            ></path></svg
          >
          <span class="sr-only">Close modal</span>
        </button>
      </div>
      <div class="flex flex-col gap-2">
        <label class="form-control w-full">
          <div class="label">
            <span class="label-text">Amount (USD) *</span>
            <span class="label-text-alt text-error">{amountError}</span>
          </div>
          <input
            type="number"
            placeholder="Enter amount"
            class="input input-bordered w-full"
            bind:value={amount}
          />
        </label>
        <label class="form-control w-full">
          <div class="label">
            <span class="label-text">Description</span>
            <span class="label-text-alt text-error">{descriptionError}</span>
          </div>
          <textarea
            class="textarea textarea-bordered"
            placeholder="Enter description"
            bind:value={description}
          ></textarea>
        </label>
      </div>
      <div class="modal-action mt-0">
        <form method="dialog">
          <button class="btn btn-ghost" onclick={unsaveClose}>Cancel</button>
        </form>
        <form method="dialog">
          <button class="btn btn-primary" onclick={submit}>Create</button>
        </form>
      </div>
    </div>
  </div>
  <!-- Modal backdrop, close when click outside -->
  <form method="dialog" class="modal-backdrop bg-black opacity-30">
    <button>close</button>
  </form>
</dialog>

<svelte:window
  on:keydown={(e) => {
    if (e.key === "Escape") {
      isModalOpen = false;
    }
  }}
/>
