<script lang="ts">
  import MerchantModal from "@components/common/MerchantModal.svelte";
  import { suiToString } from "@utils/sui";

  let merchantModal: MerchantModal;
</script>

<div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
  <div class="flex w-full flex-row items-center justify-between">
    <div class="text-lg">Merchants</div>
    <button
      class="btn btn-primary"
      onclick={() => {
        merchantModal.open();
      }}>New Merchant</button
    >
  </div>
  <div class="w-full">
    <div class="flex flex-col gap-2">
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
    </div>
  </div>
</div>
<MerchantModal bind:this={merchantModal} />
