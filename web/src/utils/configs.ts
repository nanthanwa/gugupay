export const pageDescription = 'A decentralized payment solution on the Sui blockchain.';

export const githubLink = 'https://github.com/gugupay/gugupay';

export const network: "mainnet" | "testnet" | "devnet" | "localnet" =
  import.meta.env.PUBLIC_NETWORK;

export const NAVIGATION_MENU = [
  {
    label: "Learn",
    items: [
      {
        label: "What is Gugupay?",
        link: "/docs/learn/what-is-gugupay",
      },
      {
        label: "Tutorial",
        link: "/docs/learn/tutorial",
      },
      {
        label: "FAQ",
        link: "/docs/learn/faq",
      },
    ],
  },
  {
    label: "Developer",
    items: [
      {
        label: "Integration SDK",
        link: "/docs/developer/sdk",
      },
      {
        label: "API Reference",
        link: "/docs/developer/api-reference",
      },
      {
        label: "GitHub",
        link: githubLink,
      },
    ],
  },
]
