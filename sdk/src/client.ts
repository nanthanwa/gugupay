import {SuiClient, getFullnodeUrl} from '@mysten/sui/client';
import {Transaction} from '@mysten/sui/dist/cjs/transactions';
import {Transaction as Transaction2} from '@mysten/sui/transactions';
import {Buffer} from 'buffer';
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
import {InvoiceObjectData} from './typedef';

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

  getInvoice = async (invoiceId: string) => {
    return this.SuiClient.getObject({
      id: invoiceId,
      options: {
        showContent: true,
      },
    }) as any;
    // }) as Promise<SuiObjectResponse<InvoiceObjectData>>;
  };

  getMerchantByInvoiceId = async (invoiceId: string) => {
    const invoice = await this.getInvoice(invoiceId);
    if (invoice.data?.content?.dataType === 'package') {
      throw new Error('Invoice not found');
    }

    const invoiceData = invoice.data as InvoiceObjectData;
    console.log('invoiceData', invoiceData);

    return invoiceData.content?.fields?.value.fields.merchant_id;
  };

  payInvoice = ({
    txb,
    invoiceId,
    amountSui,
    invoiceId2,
  }: {
    txb: Transaction;
    invoiceId: string;
    amountSui: number;
    invoiceId2: string;
  }) => {
    // Get invoice details to determine payment amount
    // const merchant_id = await this.getMerchantByInvoiceId(invoiceId);
    // console.log('merchant_id', merchant_id);
    // console.log('invoiceId', invoiceId);

    console.log('invoiceId', invoiceId2);
    console.log('amountSui', amountSui);

    // Split coin to get exact payment amount
    // console.log('txb.gas', txb.gas);
    const [splitCoin] = txb.splitCoins(txb.gas, [txb.pure.u64(amountSui)]);

    console.log('splitCoin', splitCoin);
    console.log('this.SHARED_ID', this.SHARED_ID);
    console.log('invoiceId2', invoiceId2);
    txb.setGasBudget(10000000);
    txb.moveCall({
      package: this.PACKAGE_ID,
      module: 'payment_service',
      function: 'pay_invoice',
      arguments: [
        txb.object(this.SHARED_ID),
        txb.object(invoiceId2),
        txb.object(splitCoin),
        txb.object(this.CLOCK_ID),
      ],
    });
    return txb;
  };

  getMerchantsByOwner = async (ownerAddress: string) => {
    const tx = new Transaction2();

    tx.moveCall({
      target: `${this.PACKAGE_ID}::payment_service::get_merchant_by_owner`,
      arguments: [tx.object(this.SHARED_ID), tx.pure.address(ownerAddress)],
    });

    // Execute the transaction
    const resultCall = await this.SuiClient.devInspectTransactionBlock({
      sender: ownerAddress,
      transactionBlock: tx,
    });

    const merchantIds = [];
    if (
      resultCall.results &&
      resultCall.results[0] &&
      resultCall.results[0].returnValues
    ) {
      const bufferRaw = resultCall.results[0].returnValues[0][0];
      const returnValueBuffer = Buffer.from(bufferRaw);

      for (let i = 1; i < returnValueBuffer.length; i += 32) {
        const id = returnValueBuffer.slice(i, i + 32).toString('hex');
        merchantIds.push('0x' + id);
      }
    }
    return merchantIds;
  };
}
