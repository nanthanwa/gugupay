<script lang="ts" module>
	export interface IConnectModal {
		openAndWaitForResponse: () => Promise<IWallet | undefined>;
	}

	let _resolve = $state<(value: IWallet | PromiseLike<IWallet | undefined> | undefined) => void>();
	let resolve = {
		get value() {
			return _resolve;
		},
		set(resolve: typeof _resolve) {
			_resolve = resolve;
		}
	};
	let connectModal = $state<HTMLDialogElement>();

	export const getConnectModal = () => {
		return connectModal;
	};
</script>

<script lang="ts">
	import type { IWallet } from '@suiet/wallet-sdk';

	interface IProps {
		availableWallets: IWallet[];
		children: () => any;
	}

	let { availableWallets, children }: IProps = $props();
	let isOpen = $state<boolean>(false);

	$effect(() => {
		if (!connectModal) return;
		if (isOpen) {
			connectModal.show();
		} else {
			connectModal.close();
		}
	});

	export const openAndWaitForResponse = (): Promise<IWallet | undefined> => {
		return new Promise((res) => {
			connectModal?.show();
			resolve.set(res);
		});
	};

	const onClose = () => {
		if (resolve.value) {
			resolve.value(undefined);
		}
		connectModal?.close();
	};

	const onSelected = (wallet: IWallet) => {
		if (resolve.value) {
			resolve.value(wallet);
		}
		connectModal?.close();
	};
</script>

<dialog bind:this={connectModal}  class="modal modal-bottom sm:modal-middle">
	<div
		class="modal-box"
	>
			<div class="grid gap-y-2">
				<div class="grid grid-cols-2">
					<div class="flex items-center text-xl font-bold">Available wallets</div>
					<div class="flex justify-end">
						<button class="btn-icon variant-filled-error btn-sm" onclick={onClose}>
							<svg viewBox="0 0 24 24" width="1.2em" height="1.2em">
								<path
									fill="currentColor"
									d="M19 6.41L17.59 5L12 10.59L6.41 5L5 6.41L10.59 12L5 17.59L6.41 19L12 13.41L17.59 19L19 17.59L13.41 12z"
								>
								</path>
							</svg>
						</button>
					</div>
				</div>
				{#if availableWallets.length == 0}
					<div>
						Please install a Sui wallet, we recommend <a
							href="https://chromewebstore.google.com/detail/suiet-sui-wallet/khpkpbbcccdmmclmpigdgddabeilkdpd"
							target="_blank"
							class="font-bold underline"
						>
							Suiet
						</a>.
					</div>
				{/if}
				{#each availableWallets as wallet (wallet.name)}
					<button
						class="font btn flex items-center justify-start space-x-2 p-2"
						onclick={() => onSelected(wallet)}
					>
						<img src={wallet.iconUrl} alt={wallet.name} />
						<div>{wallet.name}</div>
					</button>
				{/each}
			</div>
	</div>
	<form method="dialog" class="modal-backdrop">
		<button>close</button>
	  </form>
</dialog>
