import {SuiClient, getFullnodeUrl} from '@mysten/sui/client';
import {Transaction} from '@mysten/sui/dist/cjs/transactions';
import {TESTNET_PACKAGE_ID, TESTNET_SHARED_ID} from './const';

// TODO: Replace with actual type
const merchantObjType = '0x3::staking_pool::StakedSui';

export class GugupayClient {
  SuiClient: SuiClient;
  PACKAGE_ID: string;
  SHARED_ID: string;

  constructor(network: 'mainnet' | 'testnet' | 'devnet' | 'localnet') {
    switch (network) {
      case 'testnet':
        this.PACKAGE_ID = TESTNET_PACKAGE_ID;
        this.SHARED_ID = TESTNET_SHARED_ID;
        break;
      default:
        throw new Error(`Invalid network '${network}'`);
    }

    this.SuiClient = new SuiClient({
      url: getFullnodeUrl(network),
    });
  }

  getSuiBalance = (address: string) => {
    return this.SuiClient.getBalance({
      owner: address,
    });
  };

  createMerchantObject = ({
    txb,
    name,
    imageURL,
    callbackURL,
    description,
  }: {
    txb: Transaction;
    name: string;
    imageURL: string;
    callbackURL: string;
    description: string;
  }) => {
    txb.moveCall({
      package: this.PACKAGE_ID,
      module: 'payment_service',
      function: 'create_merchant',
      arguments: [
        txb.object(this.SHARED_ID),
        txb.pure.string(name),
        txb.pure.string(description),
        txb.pure.string(imageURL),
        txb.pure.string(callbackURL),
      ],
    });
    return txb;
  };

  getMerchantObjects = (address: string) => {
    return this.SuiClient.getOwnedObjects({
      owner: address,
      filter: {
        StructType: merchantObjType,
      },
      options: {
        showContent: true,
      },
    });
  };
}
