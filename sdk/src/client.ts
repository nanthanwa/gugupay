import {SuiClient, getFullnodeUrl} from '@mysten/sui/client';
import {Transaction} from '@mysten/sui/dist/cjs/transactions';
import {
  TESTNET_PACKAGE_ID,
  TESTNET_SHARED_ID,
  PYTH_PRICE_FEED_ID,
  PYTH_STATE_ID,
  WORMHOLE_STATE_ID,
  CLOCK_ID,
  PRICE_INFO_OBJECT_ID,
  HERMES_URL,
} from './const';
import {
  SuiPythClient,
  SuiPriceServiceConnection,
} from '@pythnetwork/pyth-sui-js';

// TODO: Replace with actual type
const merchantObjType = '0x3::staking_pool::StakedSui';

export class GugupayClient {
  SuiClient: SuiClient;
  PYTH_CLIENT: SuiPythClient;
  connection: SuiPriceServiceConnection;
  PACKAGE_ID: string;
  SHARED_ID: string;
  PYTH_PRICE_FEED_ID: string;
  PYTH_STATE_ID: string;
  WORMHOLE_STATE_ID: string;
  CLOCK_ID: string;
  PRICE_INFO_OBJECT_ID: string;
  HERMES_URL: string;

  constructor(network: 'mainnet' | 'testnet' | 'devnet' | 'localnet') {
    switch (network) {
      case 'testnet':
        this.PACKAGE_ID = TESTNET_PACKAGE_ID;
        this.SHARED_ID = TESTNET_SHARED_ID;
        this.PYTH_PRICE_FEED_ID = PYTH_PRICE_FEED_ID;
        this.PYTH_STATE_ID = PYTH_STATE_ID;
        this.WORMHOLE_STATE_ID = WORMHOLE_STATE_ID;
        this.CLOCK_ID = CLOCK_ID;
        this.PRICE_INFO_OBJECT_ID = PRICE_INFO_OBJECT_ID;
        this.HERMES_URL = HERMES_URL;
        this.SuiClient = new SuiClient({
          url: getFullnodeUrl(network),
        });
        this.connection = new SuiPriceServiceConnection(this.HERMES_URL);
        this.PYTH_CLIENT = new SuiPythClient(
          this.SuiClient,
          this.PYTH_STATE_ID,
          this.WORMHOLE_STATE_ID,
        );
        break;
      default:
        throw new Error(`Invalid network '${network}'`);
    }
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

  updateOraclePrice = ({
    txb,
    priceInfoObjectId,
  }: {
    txb: Transaction;
    priceInfoObjectId: string;
  }) => {
    txb.moveCall({
      package: this.PACKAGE_ID,
      module: 'payment_service',
      function: 'update_oracle_price',
    });
    return txb;
  };

  createInvoice = ({
    txb,
    merchantId,
    description,
    amount_usd,
  }: {
    txb: Transaction;
    merchantId: string;
    description: string;
    amount_usd: number;
  }) => {
    txb.moveCall({
      package: this.PACKAGE_ID,
      module: 'payment_service',
      function: 'create_invoice',
      arguments: [
        txb.object(this.SHARED_ID),
        txb.object(merchantId),
        txb.pure.string(description),
        txb.pure.u64(amount_usd),
        txb.object(this.CLOCK_ID),
        txb.object(this.PRICE_INFO_OBJECT_ID),
      ],
    });
    return txb;
  };
}
