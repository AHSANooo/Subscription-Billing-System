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
const MAX_APPROVAL = BigInt(2) ** BigInt(256) - BigInt(1);
const FIVE_DAYS_SECONDS = BigInt(5 * 24 * 60 * 60);
const ZERO = BigInt(0);

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
  }, [isConnected, address, isPending, refetchBalance, refetchAllowance, refetchActive, refetchExpiry]);

  const balanceHasFunds = usdtBalance ? usdtBalance >= PLAN_PRICE_RAW : false;
  const allowanceApproved = usdtAllowance ? usdtAllowance >= PLAN_PRICE_RAW : false;
  const hasActivePlan = expiryTimestamp ? expiryTimestamp > ZERO : false;
  const currentTime = BigInt(Math.floor(Date.now() / 1000));
  const renewalWindowStart = expiryTimestamp && expiryTimestamp > FIVE_DAYS_SECONDS
    ? expiryTimestamp - FIVE_DAYS_SECONDS
    : ZERO;
  const renewalAllowed = !hasActivePlan || currentTime >= renewalWindowStart;
  const renewalButtonDisabled = hasActivePlan && !renewalAllowed;
  const expiryDate = hasActivePlan && expiryTimestamp
    ? new Date(Number(expiryTimestamp) * 1000).toLocaleDateString()
    : 'No active window';

  const handleApprove = () => {
    writeContract({
      address: MOCK_USDT_ADDRESS,
      abi: MOCK_USDT_ABI,
      functionName: 'approve',
      args: [SUBSCRIPTION_BILLING_ADDRESS, MAX_APPROVAL],
    });
  };

  const handleSubscribeOrRenew = () => {
    if (!balanceHasFunds || renewalButtonDisabled) return;

    writeContract({
      address: SUBSCRIPTION_BILLING_ADDRESS,
      abi: SUBSCRIPTION_BILLING_ABI,
      functionName: hasActivePlan ? 'renew' : 'subscribe',
      args: [PLAN_ID],
    });
  };

  return (
    <main className="min-h-screen bg-slate-900 px-6 py-8 text-slate-100">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-8 lg:flex-row lg:items-stretch lg:justify-center">
        <section className="w-full max-w-xl overflow-hidden rounded-2xl border border-slate-700 bg-slate-800 shadow-xl">
          <div className="border-b border-slate-700 bg-[#0F3460] p-6 text-center">
            <h1 className="text-xl font-bold tracking-tight text-white">SaaS Billing Node</h1>
            <p className="mt-1 text-xs text-slate-400">Multi-Tier Smart Contract Interface</p>
          </div>

          <div className="space-y-6 p-6">
            {!isConnected ? (
              <div className="space-y-4 text-center">
                <p className="text-sm text-slate-400">
                  Connect an authorized Web3 provider to verify access clearance details.
                </p>
                <button
                  onClick={() => connect({ connector: injected() })}
                  className="w-full rounded-xl bg-[#1F2394] px-4 py-3 text-sm font-semibold text-white shadow-md transition-all hover:bg-[#151763] active:scale-[0.98]"
                >
                  Connect Ethereum Wallet
                </button>
              </div>
            ) : (
              <div className="space-y-5">
                <div className="flex items-center justify-between rounded-xl border border-slate-700 bg-slate-900 p-3">
                  <span className="font-mono text-xs text-slate-400">
                    {address?.slice(0, 6)}...{address?.slice(-4)}
                  </span>
                  <button
                    onClick={() => disconnect()}
                    className="rounded-lg border border-red-800 bg-red-950 px-2.5 py-1 text-xs font-medium text-red-400 transition-colors hover:bg-red-900"
                  >
                    Log Out Wallet
                  </button>
                </div>

                <div className="space-y-3 rounded-xl border border-slate-700 bg-slate-900 p-4 text-sm">
                  <div className="flex justify-between">
                    <span className="text-slate-400">Mock USDT Balance:</span>
                    <span className="font-bold text-slate-200">
                      {usdtBalance ? Number(formatUnits(usdtBalance, 6)).toFixed(2) : '0.00'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Access Status:</span>
                    <span className={`font-bold ${isActive ? 'text-green-400' : 'text-amber-500'}`}>
                      {isActive ? 'Active Access Granted' : 'Access Suspended'}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-400">Plan Expiration:</span>
                    <span className="font-mono text-slate-300">{expiryDate}</span>
                  </div>
                </div>

                <div className="space-y-3 pt-2">
                  {!allowanceApproved ? (
                    <div>
                      <button
                        onClick={handleApprove}
                        disabled={isPending}
                        className="w-full rounded-xl bg-[#1F2394] px-4 py-3 text-sm font-semibold text-white transition-colors hover:bg-[#151763] disabled:cursor-not-allowed disabled:opacity-50"
                      >
                        {isPending ? 'Processing Approval...' : 'Approve 30.00 USDT Transfer Line'}
                      </button>
                    </div>
                  ) : (
                    <div>
                      <button
                        onClick={handleSubscribeOrRenew}
                        disabled={isPending || !balanceHasFunds || renewalButtonDisabled}
                        className="w-full rounded-xl bg-[#1F2394] px-4 py-3 text-sm font-semibold text-white transition-colors hover:bg-[#151763] disabled:cursor-not-allowed disabled:bg-slate-700 disabled:text-slate-400"
                      >
                        {isPending
                          ? 'Processing Blockchain Action...'
                          : renewalButtonDisabled
                            ? 'Subscription Safe & Active'
                            : hasActivePlan
                              ? 'Renew Subscription'
                              : 'Purchase Tier 1 Access'}
                      </button>

                      {renewalButtonDisabled && (
                        <p className="mt-2 text-center text-[11px] text-slate-400">
                          Renewal unlocks only inside the 5-day pre-expiry window or during grace handling.
                        </p>
                      )}

                      {!balanceHasFunds && (
                        <p className="mt-2 text-center text-xs font-medium text-red-400">
                          Pre-flight Guard: Insufficient USDT balance to fulfill transaction.
                        </p>
                      )}
                    </div>
                  )}
                </div>
              </div>
            )}
          </div>
        </section>

        <section className="w-full max-w-xl overflow-hidden rounded-2xl border border-slate-700 bg-slate-800 p-6 shadow-xl">
          <div className="mb-4">
            <h2 className="text-lg font-bold tracking-tight text-white">Enterprise Analytics Dashboard</h2>
            <p className="mt-1 text-xs text-slate-400">Gated Application Feature Space</p>
          </div>

          {isActive ? (
            <div className="flex min-h-[380px] flex-col items-center justify-center space-y-3 rounded-xl border border-emerald-900/30 bg-slate-900/50 p-4 text-center">
              <div className="flex h-12 w-12 items-center justify-center rounded-full border border-emerald-500/30 bg-emerald-950">
                <span className="text-xl text-emerald-400">✓</span>
              </div>
              <h3 className="text-sm font-semibold text-emerald-400">Premium Stream Active</h3>
              <p className="max-w-xs text-xs leading-relaxed text-slate-400">
                Your subscription is validated on-chain. Live backend data channels are open and premium functionality is unlocked.
              </p>
            </div>
          ) : (
            <div className="flex min-h-[380px] flex-col items-center justify-center space-y-3 rounded-xl border border-dashed border-slate-700 bg-slate-950 p-4 text-center">
              <div className="text-2xl">🔒</div>
              <h3 className="text-sm font-semibold text-slate-400">Locked Premium Feature</h3>
              <p className="max-w-xs text-xs leading-relaxed text-slate-500">
                Access requires an authorized subscription. Use the control panel on the left to approve USDT and activate Tier 1 access when the renewal gate is open.
              </p>
            </div>
          )}

          <div className="mt-4 text-center font-mono text-[10px] text-slate-500">
            Engine Condition: {isActive ? 'CLEAR_RUN' : 'ACCESS_RESTRICTED'}
          </div>
        </section>
      </div>
    </main>
  );
}
