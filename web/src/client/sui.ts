import { client } from "./client";
import { Transaction } from "@mysten/sui/transactions";

const merchantObjType = "0x3::staking_pool::StakedSui";

// TODO: move to SDK
const packageId =
  "0x528b84ea98af7e92c3cd27db185f49855c47c7215c33e75b1a97e3887ed36b3c";
const stateObjectId =
  "0x6c687caf6368e765d624e522a837eb22eae12c614cdf782919b41b0aa883a5b5";

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

export const createMerchantObject = ({
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
    package: packageId,
    module: "payment_service",
    function: "create_merchant",
    arguments: [
      txb.object(stateObjectId),
      txb.pure.string(name),
      txb.pure.string(description),
      txb.pure.string(imageURL),
      txb.pure.string(callbackURL),
    ],
  });
  return txb;
};
