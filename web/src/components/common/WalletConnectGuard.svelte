<script lang="ts">
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import { walletStatus } from "@components/wallet/SuiModule.svelte";

  interface IProps {
    children?: () => any;
  }

  const { children }: IProps = $props();
</script>

{#if walletStatus.isConnected}
  {@render children?.()}
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
