/// <reference path="../.astro/types.d.ts" />

interface ImportMetaEnv {
  readonly PUBLIC_NETWORK: "mainnet" | "testnet" | "devnet" | "localnet";
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
