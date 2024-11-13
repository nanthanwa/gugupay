<script lang="ts">
  import MerchantModal from "@components/common/MerchantModal.svelte";

  let merchantModal: MerchantModal;
</script>

<div class="flex w-full flex-col gap-4 px-4 py-6 lg:px-6">
  <div class="flex w-full flex-row items-center justify-between">
    <div class="text-lg">Merchants</div>
    <button
      class="btn btn-primary"
      on:click={() => {
        merchantModal.open();
      }}>New Merchant</button
    >
  </div>
  <div class="bg-base-300 w-full">
    <div class="flex flex-col gap-2">
      <div></div>
    </div>
  </div>
</div>
<MerchantModal bind:this={merchantModal} />
