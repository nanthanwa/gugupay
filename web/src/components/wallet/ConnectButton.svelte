<script lang="ts">
  import SuiModule, {
    connectWithModal,
    disconnect,
    account,
  } from "@components/wallet/SuiModule.svelte";

  interface IProps {
    class?: string;
    style?: string;
  }

  const { class: className = "", style = "" }: IProps = $props();

  const onClick = function () {
    if (!account.value) {
      connectWithModal();
    } else {
      disconnect();
    }
  };
</script>

<SuiModule onConnect={() => {}} />
<button type="button" class={className} {style} onclick={onClick}>
  {account.value ? "Disconnect" : "Connect"}
</button>
