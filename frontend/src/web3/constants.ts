export const SUBSCRIPTION_BILLING_ADDRESS = "0x6214f6D729d560286389ff741eDcc794Ec5A522c" as const;
export const MOCK_USDT_ADDRESS = "0xeCd399Aa572a874AdB04544A65675916FD4e6c75" as const;

export const SUBSCRIPTION_BILLING_ABI = [
  // Core State Mutation Signatures
  {
    inputs: [{ name: "_planId", type: "uint256" }],
    name: "subscribe",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "_planId", type: "uint256" }],
    name: "renew",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  // Optimized Read Path Signatures
  {
    inputs: [
      { name: "user", type: "address" },
      { name: "_planId", type: "uint256" },
    ],
    name: "isUserActive",
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "user", type: "address" },
      { name: "_planId", type: "uint256" },
    ],
    name: "getExpiry",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ name: "", type: "uint256" }],
    name: "plans",
    outputs: [
      { name: "price", type: "uint256" },
      { name: "period", type: "uint32" },
      { name: "gracePeriod", type: "uint32" },
      { name: "isActive", type: "bool" },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

export const MOCK_USDT_ABI = [
  {
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    name: "approve",
    outputs: [{ name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [{ name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
    ],
    name: "allowance",
    outputs: [{ name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
] as const;