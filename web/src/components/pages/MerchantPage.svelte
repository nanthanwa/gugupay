<script lang="ts">
  import ConnectButton from "@components/wallet/ConnectButton.svelte";
  import { walletStatus } from "@components/wallet/SuiModule.svelte";
  import { suiToString } from "@utils/sui";

  const urlParams = new URLSearchParams(window.location.search);
  const merchantId = urlParams.get("merchantId");
</script>
