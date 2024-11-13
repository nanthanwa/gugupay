import {SuiObjectData, SuiValidatorSummary} from '@mysten/sui/dist/cjs/client';

export interface MerchantObjectData extends SuiObjectData {
  content: {
    dataType: 'moveObject';
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
