import type { WalletAccount } from "@mysten/wallet-standard";

export interface WalletAccountData {
  walletAccount: WalletAccount;
  suiBalance: bigint;
}
