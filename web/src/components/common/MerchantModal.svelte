<script lang="ts">
  import { gugupayClient } from "@client/client";
  import { signAndExecuteTransactionBlock } from "@components/wallet/SuiModule.svelte";
  import type { MerchantObject } from "@gugupay/sdk";
  import { Transaction } from "@mysten/sui/transactions";
  import { addToastMessage } from "@stores/toastStore";

  type Props = {
    merchant?: MerchantObject;
    onCreated?: () => void;
  };

  const { merchant, onCreated }: Props = $props();

  let isModalOpen: boolean = $state(false);

  // elements
  let image: HTMLImageElement;

  // form data
  let name: string = $state(merchant?.name || "");
  let nameError: string = $state("");
  let imageURL: string = $state(merchant?.logo_url || "");
  let imageError: string = $state("");
  let callbackURL: string = $state(merchant?.callback_url || "");
  let callbackURLError: string = $state("");
  let description: string = $state(merchant?.description || "");
  let descriptionError: string = $state("");

  export function open() {
    isModalOpen = true;
  }

  function unsaveClose() {
    isModalOpen = false;
  }

  async function submit() {
    const txb = new Transaction();
    let merchantTxb;
    if (merchant) {
      merchantTxb = await gugupayClient.updateMerchant(
        txb,
        merchant.merchantId,
        name,
        description,
        imageURL,
        callbackURL,
      );
    } else {
      merchantTxb = gugupayClient.createMerchantObject({
        txb,
        name,
        imageURL,
        callbackURL,
        description,
      });
    }
    signAndExecuteTransactionBlock(merchantTxb)
      .then((result) => {
        if (result) {
          addToastMessage("Merchant created successfully", "success");
          isModalOpen = false;
          onCreated?.();
        }
      })
      .catch((error) => {
        console.error(error);
        addToastMessage("Failed to create merchant", "error");
      });
  }

  $effect(() => {
    imageError = "";
    if (imageURL) {
      image.src = imageURL;
    } else {
      image.src = "/apple-touch-icon.png";
    }
  });
</script>

<input type="checkbox" class="modal-toggle" bind:checked={isModalOpen} />
<dialog class="modal modal-bottom sm:modal-middle">
  <div class="modal-box rounded-none">
    <div class="flex flex-col gap-4">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-semibold">
          {merchant ? "Edit" : "New"} Merchant
        </h3>
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
        <img
          bind:this={image}
          class="mx-auto h-24 w-24 rounded-full object-cover"
          src="/apple-touch-icon.png"
          alt="Merchant Test"
          onerror={() => {
            image.src = "/apple-touch-icon.png";
            imageError = "Invalid image URL";
          }}
        />
        <label class="form-control w-full">
          <div class="label">
            <span class="label-text">Name *</span>
            <span class="label-text-alt text-error">{nameError}</span>
          </div>
          <input
            type="text"
            placeholder="Enter merchant name"
            class="input input-bordered w-full"
            bind:value={name}
          />
        </label>
        <label class="form-control w-full">
          <div class="label">
            <span class="label-text">Image URL</span>
            <span class="label-text-alt text-error">{imageError}</span>
          </div>
          <input
            type="text"
            placeholder="Enter image URL"
            class="input input-bordered w-full"
            bind:value={imageURL}
          />
        </label>
        <label class="form-control w-full">
          <div class="label">
            <span class="label-text">Callback URL</span>
            <span class="label-text-alt text-error">{callbackURLError}</span>
          </div>
          <input
            type="text"
            placeholder="Enter callback URL"
            class="input input-bordered w-full"
            bind:value={callbackURL}
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
          <button class="btn btn-primary" onclick={submit}
            >{merchant ? "Save" : "Create"}</button
          >
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
