<script lang="ts">
  import { connectWithModal } from "@components/wallet/SuiModule.svelte";

  interface IProps {
    class?: string;
    style?: string;
  }

  const { class: className = "", style = "" }: IProps = $props();
</script>

<button type="button" class={className} {style} onclick={connectWithModal}>
  Connect Wallet
</button>
