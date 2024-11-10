import { SuiClient, getFullnodeUrl } from "@mysten/sui/client";
import { network } from "@utils/configs";

export const client = new SuiClient({
  url: getFullnodeUrl(network),
});
