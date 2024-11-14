<script lang="ts" module>
  import { Transaction } from "@mysten/sui/transactions";
  import {
    AllDefaultWallets,
    ConnectionStatus,
    WalletRadar,
    type IDefaultWallet,
    type IWallet,
    type IWalletAdapter,
  } from "@suiet/wallet-sdk";
  import type { IdentifierString } from "@wallet-standard/base";
  import ConnectModal, { type IConnectModal } from "./ConnectModal.svelte";
  import type { SuiSignAndExecuteTransactionOutput } from "@mysten/wallet-standard";
  import { gugupayClient } from "@client/client";
  import type { WalletAccountData } from "@typedef/sui";
  import type { MerchantObjectData } from "@gugupay/sdk";

  const selectedWalletKey = "selectedWallet";

  let _walletAdapter = $state<IWalletAdapter>();
  let _walletStatus = $state<ConnectionStatus>(ConnectionStatus.DISCONNECTED);
  let _walletAccounts = $state<WalletAccountData[]>([]);
  let _walletAccountIdx = $state<number>(0);
  let _walletAccount = $state<WalletAccountData>();
  let connectModal = $state<IConnectModal>();

  const selectedWalletName = localStorage.getItem(selectedWalletKey);

  export const getConnectModal = () => {
    return connectModal;
  };
  let _onConnect = $state<() => void>(() => {});

  export const walletAdapter = {
    get value() {
      return _walletAdapter;
    },
  };

  export const walletStatus = {
    get value() {
      return _walletStatus;
    },
    get isConnected() {
      return _walletStatus === ConnectionStatus.CONNECTED;
    },
  };

  export const walletAccounts = {
    get value() {
      return _walletAccounts;
    },
  };

  export const walletAccountIdx = {
    get value() {
      return _walletAccountIdx;
    },
  };

  export const walletAccount = {
    get value() {
      return _walletAccount;
    },
  };

  export const connectWithModal = async () => {
    let selectedWallet = await connectModal?.openAndWaitForResponse();
    if (selectedWallet) {
      await connect(selectedWallet);
    }
  };

  export const connect = async (wallet: IWallet) => {
    _walletAdapter = wallet?.adapter;
    if (_walletAdapter) {
      _walletStatus = ConnectionStatus.CONNECTING;
      try {
        await _walletAdapter.connect();

        const walletAccountPromise = _walletAdapter.accounts.map(
          async (account) => {
            // get sui balance
            const suiCoinBalance = await gugupayClient.getSuiBalance(
              account.address,
            );

            // get merchants objects
            const getMerchantObjectsResp =
              await gugupayClient.getMerchantObjects(account.address);
            let merchantObjs: MerchantObjectData[] = getMerchantObjectsResp.data
              .filter((obj) => obj.data)
              .map((obj) => obj.data as unknown as MerchantObjectData);

            return {
              walletAccount: account,
              suiBalance: BigInt(suiCoinBalance.totalBalance),
              merchantObjs: merchantObjs,
            };
          },
        );

        const newWalletAccount: WalletAccountData[] =
          await Promise.all(walletAccountPromise);

        _walletAccounts = newWalletAccount;
        _walletAccountIdx = 0;
        _walletAccount = newWalletAccount[0];

        localStorage.setItem(selectedWalletKey, wallet.name);

        _walletStatus = ConnectionStatus.CONNECTED;
        _onConnect();
      } catch (error: any) {
        console.error("error connecting wallet", error);
        _walletStatus = ConnectionStatus.DISCONNECTED;
      }
    }
  };

  export const selectWalletAccount = (index: number) => {
    const newWalletAccount = _walletAccounts[index];
    if (!newWalletAccount) {
      throw Error("wallet account index not found");
    }
    _walletAccountIdx = index;
    _walletAccount = newWalletAccount;
  };

  export const disconnectWallet = () => {
    _walletAdapter?.disconnect();
    _walletStatus = ConnectionStatus.DISCONNECTED;
    _walletAccounts = [];
    _walletAccountIdx = 0;
    _walletAccount = undefined;
    localStorage.removeItem(selectedWalletKey);
  };

  export const signAndExecuteTransactionBlock = async (
    transaction: Transaction,
  ): Promise<SuiSignAndExecuteTransactionOutput> => {
    if (_walletStatus !== ConnectionStatus.CONNECTED) {
      throw Error("wallet is not connected");
    }

    return await _walletAdapter!!.signAndExecuteTransaction({
      account: walletAccount.value?.walletAccount!!,
      chain: walletAccount.value?.walletAccount!!.chains[0] as IdentifierString,
      transaction,
    });
  };

  const getAvailableWallets = (defaultWallets: IDefaultWallet[]): IWallet[] => {
    const walletAdapters = detectWalletAdapters();
    return defaultWallets
      .map((item) => {
        const foundAdapter = walletAdapters.find(
          (walletAdapter) => item.name === walletAdapter.name,
        );

        return {
          ...item,
          adapter: foundAdapter ? foundAdapter : undefined,
          installed: foundAdapter ? true : false,
        };
      })
      .filter((item) => item.installed == true);
  };

  const detectWalletAdapters = (): IWalletAdapter[] => {
    const walletRadar = new WalletRadar();
    walletRadar.activate();
    const walletAdapters = walletRadar.getDetectedWalletAdapters();
    walletRadar.deactivate();

    return walletAdapters;
  };

  let availableWallets = getAvailableWallets(AllDefaultWallets);

  // auto connect wallet
  if (selectedWalletName) {
    const selectedWallet = availableWallets.find(
      (wallet) => wallet.name === selectedWalletName,
    );
    if (selectedWallet) {
      connect(selectedWallet);
    }
  }
</script>

<script lang="ts">
  interface IProps {
    onConnect?: () => void;
    children?: () => any;
  }

  const { onConnect, children }: IProps = $props();
  if (onConnect) {
    _onConnect = onConnect;
  }
</script>

<ConnectModal bind:this={connectModal} {availableWallets} />
