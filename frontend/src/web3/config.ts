import { http, createConfig } from 'wagmi';
import { sepolia, localhost } from 'wagmi/chains';

// Define a custom local chain instance mapping to your background Anvil container
export const anvilChain = {
  ...localhost,
  id: 31337, // Explicit Anvil Chain ID assignment
};

export const config = createConfig({
  chains: [sepolia, anvilChain],
  ssr: true, // Crucial for hydration alignment within the Next.js App Router framework
  transports: {
    [sepolia.id]: http(),
    [anvilChain.id]: http('http://127.0.0.1:8545'),
  },
});