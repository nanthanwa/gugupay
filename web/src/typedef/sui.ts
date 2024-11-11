import type {
  SuiObjectData,
  SuiSystemStateSummary,
  SuiValidatorSummary,
} from "@mysten/sui/client";
import type { WalletAccount } from "@mysten/wallet-standard";

export interface MerchantObjectData extends SuiObjectData {
  content: {
    dataType: "moveObject";
    fields: {
      id: {
        id: string;
      };
      pool_id: string;
      principal: string;
      stake_activation_epoch: string;
    }; // custom fields for staked sui object
    hasPublicTransfer: boolean;
    type: string;
  };
  validator?: SuiValidatorSummary; // custom type
}

export interface WalletAccountData {
  walletAccount: WalletAccount;
  suiBalance: bigint;
  merchantObjs: MerchantObjectData[];
}

export interface SuiSystemStateSummaryData extends SuiSystemStateSummary {}
