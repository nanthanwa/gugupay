<script lang="ts">
  import {
    connectWithModal,
    disconnect,
    account,
    SuiModule,
  } from "@components/wallet/SuiModule";

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
