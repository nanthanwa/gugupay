export const pageDescription = 'A decentralized payment solution on the Sui blockchain.';

export const githubLink = 'https://github.com/gugupay/gugupay';

export const network: "mainnet" | "testnet" | "devnet" | "localnet" =
  import.meta.env.PUBLIC_NETWORK;


export const NAVIGATION_MENU = {
  "Learn": {
    "What is Gugupay?": "/docs/learn/what-is-gugupay",
    "Tutorial": "/docs/learn/tutorial",
    "FAQ": "/docs/learn/faq",
  },
  "Developer": {
    "Gugupay SDK": "/docs/developer/sdk",
    "API Reference": "/docs/developer/api-reference",
    "GitHub": githubLink,
  },
};
