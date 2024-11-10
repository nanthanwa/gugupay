import { atom } from "nanostores";
import type { MerchantObjectData, WalletData, WalletState } from "@typedef/sui";
import {
  getMerchantObjects,
  getSuiBalance,
} from "@client/sui";
import type { SuiObjectData, SuiValidatorSummary } from "@mysten/sui/client";
import { suiSystemStateAtom } from "./suiSystemStateStore";
import { loadingWalletDataAtom } from "./loadingStore";
import { addToastMessage } from "./toastStore";

const validatorsMap: { [name: string]: SuiValidatorSummary } = {}; // map pool id to validator summary
suiSystemStateAtom.subscribe((suiSystemState) => {
  suiSystemState?.activeValidators.forEach((validator) => {
    validatorsMap[validator.stakingPoolId] = validator;
  });
});

const SUI_WALLET_NAME = "Sui Wallet";
const defaultWallet = {
  wallets: [],
  walletIdx: 0,
};

// export const walletKit: WalletKitCore = createWalletKitCore({
//   preferredWallets: [SUI_WALLET_NAME],
// });
export const walletStateAtom = atom<WalletState>(defaultWallet);

export const getWalletAddresses = async () => {
  let wallets: WalletData[] = [];
  // walletKit.getState().accounts.forEach((ac) => {
  //   wallets.push({
  //     walletAccount: ac,
  //     suiBalance: BigInt(0),
  //     merchantObjs: [],
  //   });
  // });

  walletStateAtom.set({
    wallets,
    walletIdx: 0,
  });
};

export const getWalletBalances = async () => {
  const newWallets = walletStateAtom.get().wallets.map(async (wallet) => {
    // get sui balance
    const suiCoinBalance = await getSuiBalance(wallet.walletAccount.address);
    wallet.suiBalance = BigInt(suiCoinBalance.totalBalance);

    // get merchants objects
    const getMerchantObjectsResp = await getMerchantObjects(
      wallet.walletAccount.address
    );
    let merchantObjs: SuiObjectData[] = [];
    getMerchantObjectsResp.data.forEach((obj) => {
      if (obj.data) {
        merchantObjs.push(obj.data);
      }
    });
    wallet.merchantObjs = merchantObjs as MerchantObjectData[];

    return wallet;
  });

  loadingWalletDataAtom.set(true);
  Promise.all(newWallets)
    .then((wallets) => {
      walletStateAtom.set({
        wallets: wallets,
        walletIdx: walletStateAtom.get().walletIdx,
      });

      loadingWalletDataAtom.set(false);
    })
    .catch((e) => {
      addToastMessage(`Error to get wallet data: ${e}`, "error");
    });
};

export const connectWallet = async () => {
  // await walletKit.connect(SUI_WALLET_NAME);
  await getWalletAddresses();
  await getWalletBalances();
};

export const disconnectWallet = async () => {
  // await walletKit.disconnect();
  walletStateAtom.set(defaultWallet);
};

export const changeWallet = async (newIdx: number) => {
  const newWalletState = walletStateAtom.get();

  // walletKit.selectAccount(newWalletState.wallets[newIdx].walletAccount);
  newWalletState.walletIdx = newIdx;

  walletStateAtom.set({ ...newWalletState });
};
