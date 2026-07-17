'use client';

import { useEffect } from 'react';
import {
  useAccount,
  useConnect,
  useDisconnect,
  useReadContract,
  useWriteContract,
} from 'wagmi';
import { injected } from 'wagmi/connectors';
import { formatUnits } from 'viem';
import {
  SUBSCRIPTION_BILLING_ADDRESS,
  SUBSCRIPTION_BILLING_ABI,
  MOCK_USDT_ADDRESS,
  MOCK_USDT_ABI,
} from '../src/web3/constants';

const PLAN_ID = BigInt(1);
const PLAN_PRICE_RAW = BigInt(30000000);
const MAX_APPROVAL = (BigInt(2) ** BigInt(256)) - BigInt(1);

export default function Dashboard() {
  const { address, isConnected } = useAccount();
  const { connect } = useConnect();
  const { disconnect } = useDisconnect();
  const { writeContract, isPending } = useWriteContract();

  const { data: usdtBalance, refetch: refetchBalance } = useReadContract({
    address: MOCK_USDT_ADDRESS,
    abi: MOCK_USDT_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  const { data: usdtAllowance, refetch: refetchAllowance } = useReadContract({
    address: MOCK_USDT_ADDRESS,
    abi: MOCK_USDT_ABI,
    functionName: 'allowance',
    args: address ? [address, SUBSCRIPTION_BILLING_ADDRESS] : undefined,
  });

  const { data: isActive, refetch: refetchActive } = useReadContract({
    address: SUBSCRIPTION_BILLING_ADDRESS,
    abi: SUBSCRIPTION_BILLING_ABI,
    functionName: 'isUserActive',
    args: address ? [address, PLAN_ID] : undefined,
  });

  const { data: expiryTimestamp, refetch: refetchExpiry } = useReadContract({
    address: SUBSCRIPTION_BILLING_ADDRESS,
    abi: SUBSCRIPTION_BILLING_ABI,
    functionName: 'getExpiry',
    args: address ? [address, PLAN_ID] : undefined,
  });

  useEffect(() => {
    if (isConnected) {
      refetchBalance();
      refetchAllowance();
      refetchActive();
      refetchExpiry();
    }
  }, [isConnected, address, refetchBalance, refetchAllowance, refetchActive, refetchExpiry]);

  const balanceHasFunds = usdtBalance ? usdtBalance >= PLAN_PRICE_RAW : false;
  const allowanceApproved = usdtAllowance ? usdtAllowance >= PLAN_PRICE_RAW : false;
  const expiryDate = expiryTimestamp && expiryTimestamp > BigInt(0)
    ? new Date(Number(expiryTimestamp) * 1000).toLocaleDateString()
    : 'No active window';

  const handleApprove = async () => {
    writeContract({
      address: MOCK_USDT_ADDRESS,
      abi: MOCK_USDT_ABI,
      functionName: 'approve',
      args: [SUBSCRIPTION_BILLING_ADDRESS, MAX_APPROVAL],
    });
  };

  const handleSubscribeOrRenew = async () => {
    if (!balanceHasFunds) return;

    const targetFunction = expiryTimestamp && expiryTimestamp > BigInt(0) ? 'renew' : 'subscribe';

    writeContract({
      address: SUBSCRIPTION_BILLING_ADDRESS,
      abi: SUBSCRIPTION_BILLING_ABI,
      functionName: targetFunction,
      args: [PLAN_ID],
    });
  };

  return (
    <main className="min-h-screen flex flex-col items-center justify-center bg-slate-50 p-6 text-slate-900">
      <div className="w-full max-w-md overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="bg-[#0F3460] p-6 text-center text-white">
          <h1 className="text-xl font-semibold tracking-tight">SaaS Core Access Control</h1>
          <p className="mt-1 text-xs text-slate-300">Enterprise USDT Subscription Node</p>
        </div>

        <div className="space-y-6 p-6">
          {!isConnected ? (
            <div className="space-y-4 text-center">
              <p className="text-sm text-slate-600">
                Secure wallet handshake required to evaluate account eligibility details.
              </p>
              <button
                onClick={() => connect({ connector: injected() })}
                className="w-full rounded-lg bg-[#1F2394] px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-[#151763]"
              >
                Connect Ethereum Wallet
              </button>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="flex items-center justify-between rounded-lg bg-slate-100 p-3 text-xs">
                <span className="font-mono text-slate-600">
                  {address?.slice(0, 6)}...{address?.slice(-4)}
                </span>
                <button onClick={() => disconnect()} className="text-red-600 hover:underline">
                  Disconnect
                </button>
              </div>

              <div className="space-y-2 border-y border-slate-100 py-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-slate-500">Wallet Balance:</span>
                  <span className="font-semibold text-slate-800">
                    {usdtBalance ? Number(formatUnits(usdtBalance, 6)).toFixed(2) : '0.00'} USDT
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Subscription Status:</span>
                  <span className={`font-semibold ${isActive ? 'text-green-600' : 'text-amber-600'}`}>
                    {isActive ? 'Active Access Granted' : 'Access Suspended'}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Window Expiration:</span>
                  <span className="font-mono font-medium text-slate-700">{expiryDate}</span>
                </div>
              </div>

              <div className="space-y-3 pt-2">
                {!allowanceApproved ? (
                  <div>
                    <button
                      onClick={handleApprove}
                      disabled={isPending}
                      className="w-full rounded-lg bg-[#1F2394] px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-[#151763] disabled:opacity-50"
                    >
                      {isPending ? 'Confirming Approval...' : 'Approve Core USDT Operations'}
                    </button>
                    <p className="mt-1.5 text-center text-[11px] text-slate-500">
                      Grants access to execute the required 30.00 USDT secure payment line.
                    </p>
                  </div>
                ) : (
                  <div>
                    <button
                      onClick={handleSubscribeOrRenew}
                      disabled={isPending || !balanceHasFunds}
                      className="w-full rounded-lg bg-[#1F2394] px-4 py-2.5 text-sm font-medium text-white transition-colors hover:bg-[#151763] disabled:opacity-50"
                    >
                      {isPending
                        ? 'Processing On-Chain...'
                        : expiryTimestamp && expiryTimestamp > BigInt(0)
                          ? 'Renew Subscription'
                          : 'Subscribe to Tier 1'}
                    </button>
                    {!balanceHasFunds && (
                      <p className="mt-2 text-center text-xs font-medium text-red-500">
                        Pre-flight Guard: Insufficient USDT balance to fulfill transaction.
                      </p>
                    )}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </main>
  );
}
