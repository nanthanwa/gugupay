import { GugupayClient } from "@gugupay/sdk";
import { network } from "@utils/configs";

export const gugupayClient = new GugupayClient(network);
