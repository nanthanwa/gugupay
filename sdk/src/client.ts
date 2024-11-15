import {
  ObjectResponseError,
  SuiClient,
  getFullnodeUrl,
} from '@mysten/sui/client';
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

  getInvoiceDetails = async (
    ownerAddress: string,
    invoiceId: string,
  ): Promise<{
    merchantId: string;
    description: string;
    amountUsd: number;
    amountSui: number;
    exchangeRate: number;
    rateTimestamp: number;
    expiresAt: number;
    isPaid: boolean;
  }> => {
    const tx = new Transaction2();

    tx.moveCall({
      target: `${this.PACKAGE_ID}::payment_service::get_invoice_details`,
      arguments: [tx.object(this.SHARED_ID), tx.object(invoiceId)],
    });

    // Execute the transaction
    const resultCall = await this.SuiClient.devInspectTransactionBlock({
      sender: ownerAddress,
      transactionBlock: tx,
    });

    const invoiceDetails = {
      merchantId: '',
      description: '',
      amountUsd: 0,
      amountSui: 0,
      exchangeRate: 0,
      rateTimestamp: 0,
      expiresAt: 0,
      isPaid: false,
    };
    if (
      resultCall.results &&
      resultCall.results[0] &&
      resultCall.results[0].returnValues
    ) {
      const returnValueBuffer = Buffer.from(
        resultCall.results[0].returnValues[0][0],
      );
      const merchantId = returnValueBuffer.slice(0, 32).toString('hex');
      const descriptionBuffer = resultCall.results[0].returnValues[1][0];
      const returnValueBuffer2 = Buffer.from(descriptionBuffer);
      const description = returnValueBuffer2.toString();
      const amountUsdBuffer = resultCall.results[0].returnValues[2][0];
      const returnValueBuffer3 = Buffer.from(amountUsdBuffer);
      const amountUsd = returnValueBuffer3.readBigUInt64LE(0);
      const amountSuiBuffer = resultCall.results[0].returnValues[3][0];
      const returnValueBuffer4 = Buffer.from(amountSuiBuffer);
      const amountSui = returnValueBuffer4.readBigUInt64LE(0);
      const exchangeRateBuffer = resultCall.results[0].returnValues[4][0];
      const returnValueBuffer5 = Buffer.from(exchangeRateBuffer);
      const exchangeRate = returnValueBuffer5.readBigUInt64LE(0);
      const rateTimestampBuffer = resultCall.results[0].returnValues[5][0];
      const returnValueBuffer6 = Buffer.from(rateTimestampBuffer);
      const rateTimestamp = returnValueBuffer6.readBigUInt64LE(0);
      const expiresAtBuffer = resultCall.results[0].returnValues[6][0];
      const returnValueBuffer7 = Buffer.from(expiresAtBuffer);
      const expiresAt = returnValueBuffer7.readBigUInt64LE(0);
      const isPaidBuffer = resultCall.results[0].returnValues[7][0];
      const returnValueBuffer8 = Buffer.from(isPaidBuffer);
      const isPaid = returnValueBuffer8.readUInt8(0) === 1;
      Object.assign(invoiceDetails, {
        merchantId: `0x${merchantId}`,
        description,
        amountUsd: Number(amountUsd),
        amountSui: Number(amountSui),
        exchangeRate: Number(exchangeRate),
        rateTimestamp: Number(rateTimestamp),
        expiresAt: Number(expiresAt),
        isPaid,
      });
    }
    return invoiceDetails;
  };

  getMerchantDetails = async (
    ownerAddress: string,
    merchantId: string,
  ): Promise<{
    id: string;
    name: string;
    description: string;
    logo_url: string;
    callback_url: string;
  }> => {
    const tx = new Transaction2();

    tx.moveCall({
      target: `${this.PACKAGE_ID}::payment_service::get_merchant_details`,
      arguments: [tx.object(this.SHARED_ID), tx.object(merchantId)],
    });

    // Execute the transaction
    const resultCall = await this.SuiClient.devInspectTransactionBlock({
      sender: ownerAddress,
      transactionBlock: tx,
    });

    const merchantDetails = {
      id: '',
      name: '',
      description: '',
      logo_url: '',
      callback_url: '',
    };
    if (
      resultCall.results &&
      resultCall.results[0] &&
      resultCall.results[0].returnValues
    ) {
      const merchantId = Buffer.from(resultCall.results[0].returnValues[0][0])
        .slice(0, 32)
        .toString('hex');
      const name = Buffer.from(
        resultCall.results[0].returnValues[1][0],
      ).toString();
      const description = Buffer.from(
        resultCall.results[0].returnValues[2][0],
      ).toString();
      const logo_url = Buffer.from(
        resultCall.results[0].returnValues[3][0],
      ).toString();
      const callback_url = Buffer.from(
        resultCall.results[0].returnValues[4][0],
      ).toString();
      Object.assign(merchantDetails, {
        merchantId: `0x${merchantId}`,
        name,
        description,
        logo_url,
        callback_url,
      });
    }
    return merchantDetails;
  };

  getMerchantBalance = async (ownerAddress: string, merchantId: string) => {
    const tx = new Transaction2();

    tx.moveCall({
      target: `${this.PACKAGE_ID}::payment_service::get_merchant_balance`,
      arguments: [tx.object(this.SHARED_ID), tx.object(merchantId)],
    });

    // Execute the transaction
    const resultCall = await this.SuiClient.devInspectTransactionBlock({
      sender: ownerAddress,
      transactionBlock: tx,
    });

    if (
      resultCall.results &&
      resultCall.results[0] &&
      resultCall.results[0].returnValues
    ) {
      const balance = resultCall.results[0].returnValues[0][0];
      const returnValueBuffer = Buffer.from(balance);
      const balanceValue = returnValueBuffer.readBigUInt64LE(0);
      return Number(balanceValue);
    }
    return 0;
  };

  withdrawMerchantBalance = async (txb: Transaction, merchantId: string) => {
    txb.setGasBudget(10000000);
    txb.moveCall({
      target: `${this.PACKAGE_ID}::payment_service::withdraw_balance`,
      arguments: [txb.object(this.SHARED_ID), txb.object(merchantId)],
    });

    return txb;
  };

  getInvoice = async (invoiceId: string) => {
    return this.SuiClient.getObject({
      id: invoiceId,
      options: {
        showContent: true,
      },
    }) as Promise<{
      data?: InvoiceObjectData | null;
      error?: ObjectResponseError | null;
    }>;
  };

  getMerchantIdByInvoiceId = async (invoiceId: string) => {
    const invoice = await this.getInvoice(invoiceId);
    if (invoice.data?.content?.dataType !== 'moveObject') {
      throw new Error('Invoice not found');
    }

    const invoiceData = invoice.data as InvoiceObjectData;

    return invoiceData.content?.fields?.value.fields.merchant_id;
  };

  payInvoice = ({
    txb,
    invoiceId,
    amountSui,
  }: {
    txb: Transaction;
    invoiceId: string;
    amountSui: number;
  }) => {
    console.log('invoiceId', invoiceId);
    console.log('amountSui', amountSui);

    // Split coin to get exact payment amount
    // console.log('txb.gas', txb.gas);
    const [splitCoin] = txb.splitCoins(txb.gas, [txb.pure.u64(amountSui)]);

    console.log('splitCoin', splitCoin);
    console.log('this.SHARED_ID', this.SHARED_ID);
    console.log('invoiceId', invoiceId);
    txb.setGasBudget(10000000);
    txb.moveCall({
      package: this.PACKAGE_ID,
      module: 'payment_service',
      function: 'pay_invoice',
      arguments: [
        txb.object(this.SHARED_ID),
        txb.object(invoiceId),
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

  getMerchantInvoices = async (ownerAddress: string, merchantId: string) => {
    const tx = new Transaction2();
    tx.moveCall({
      target: `${this.PACKAGE_ID}::payment_service::get_merchant_invoices`,
      arguments: [
        tx.object(this.SHARED_ID),
        tx.object(merchantId),
        tx.pure.option('bool', null),
      ],
    });

    // Execute the transaction
    const resultCall = await this.SuiClient.devInspectTransactionBlock({
      sender: ownerAddress,
      transactionBlock: tx,
    });

    const invoiceIds: string[] = [];
    if (
      resultCall.results &&
      resultCall.results[0] &&
      resultCall.results[0].returnValues
    ) {
      const bufferRaw = resultCall.results[0].returnValues[0][0];
      const returnValueBuffer = Buffer.from(bufferRaw);

      for (let i = 1; i < returnValueBuffer.length; i += 32) {
        const id = returnValueBuffer.slice(i, i + 32).toString('hex');
        invoiceIds.push('0x' + id);
      }
    }
    return invoiceIds;
  };
}
