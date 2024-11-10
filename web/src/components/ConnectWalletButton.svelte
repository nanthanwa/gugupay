<script lang="ts">
  import { connectWallet } from "../stores/walletStore";
</script>

<button class="btn btn-primary rounded-full" onclick={connectWallet}>
  Connect Wallet
</button>
