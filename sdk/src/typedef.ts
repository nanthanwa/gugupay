import {SuiObjectData, SuiValidatorSummary} from '@mysten/sui/dist/cjs/client';

export interface InvoiceObjectData extends SuiObjectData {
  content: {
    dataType: 'moveObject';
    fields: {
      value: {
        fields: {
          id: string;
          merchant_id: string;
          invoice_id: string;
          amount_sui: string;
          amount_usd: string;
          description: string;
          exchange_rate: string;
          expires_at: string;
          is_paid: boolean;
          rate_timestamp: string;
        };
      };
    }; // custom fields for staked sui object
    hasPublicTransfer: boolean;
    type: string;
  };
  validator?: SuiValidatorSummary; // custom type
}

export interface MerchantObject {
  merchantId: string;
  name: string;
  description: string;
  logo_url: string;
  callback_url: string;
}

export interface InvoiceObject {
  merchantId: string;
  description: string;
  amountUsd: number;
  amountSui: number;
  exchangeRate: number;
  rateTimestamp: number;
  expiresAt: number;
  isPaid: boolean;
}
