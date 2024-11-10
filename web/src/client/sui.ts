import { client } from "./client";

const merchantObjType = "0x3::staking_pool::StakedSui";

export const getSuiBalance = (address: string) => {
  return client.getBalance({
    owner: address,
  });
};

export const getMerchantObjects = (address: string) => {
  return client.getOwnedObjects({
    owner: address,
    filter: {
      StructType: merchantObjType,
    },
    options: {
      showContent: true,
    },
  });
};

export const getLatestSuiSystemState = () => {
  return client.getLatestSuiSystemState();
};

export const getValidatorAPY = () => {
  return client.getValidatorsApy();
};
