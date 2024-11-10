module gugupay::gugupay {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use sui::clock::{Self, Clock};
    use sui::event;
    use std::string::{Self, String};
    use std::option::{Self, Option};

    // ======== Errors ========
    const ENotOwner: u64 = 0;
    const EInvoiceAlreadyPaid: u64 = 1;
    const EInvoiceExpired: u64 = 2;
    const EInsufficientPayment: u64 = 3;
    const EInsufficientBalance: u64 = 4;

    // ======== Objects ========
    public struct AdminCap has key {
        id: UID
    }

    public struct Merchant has key, store {
        id: UID,
        merchant_id: u64,
        name: String,
        description: String,
        logo: String,
        owner: address
    }

    public struct Invoice has key, store {
        id: UID,
        invoice_id: u64,
        merchant_id: u64,
        description: String,
        amount: u64,
        is_paid: bool,
        deadline: u64,
        merchant_owner: address
    }

    public struct GugupayState has key {
        id: UID,
        merchant_count: u64,
        invoice_count: u64,
        merchants: Table<u64, Merchant>,
        invoices: Table<u64, Invoice>,
        merchant_balances: Table<address, u64>
    }

    public struct MerchantNFT has key, store {
        id: UID,
        name: String,
        symbol: String,
        merchant_id: u64,
        owner: address,
        balance: u64
    }

    public struct InvoiceNFT has key, store {
        id: UID,
        name: String,
        symbol: String,
        invoice_id: u64,
        owner: address
    }

    // ======== Events ========
    public struct MerchantCreated has copy, drop {
        merchant_id: u64,
        name: String,
        description: String,
        logo: String
    }

    public struct InvoiceCreated has copy, drop {
        invoice_id: u64,
        amount: u64
    }

    // ======== Functions ========
    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };
        
        let state = GugupayState {
            id: object::new(ctx),
            merchant_count: 0,
            invoice_count: 0,
            merchants: table::new(ctx),
            invoices: table::new(ctx),
            merchant_balances: table::new(ctx)
        };

        transfer::transfer(admin_cap, tx_context::sender(ctx));
        transfer::share_object(state);
    }

    // Add test-only init function
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }

    public entry fun create_merchant(
        state: &mut GugupayState,
        name: vector<u8>,
        description: vector<u8>,
        logo: vector<u8>,
        ctx: &mut TxContext
    ) {
        let merchant_id = state.merchant_count + 1;
        let merchant = Merchant {
            id: object::new(ctx),
            merchant_id,
            name: string::utf8(name),
            description: string::utf8(description),
            logo: string::utf8(logo),
            owner: tx_context::sender(ctx)
        };

        table::add(&mut state.merchants, merchant_id, merchant);
        state.merchant_count = merchant_id;

        // Mint and transfer NFT to merchant
        let nft = mint_merchant_nft(merchant_id, ctx);
        transfer::transfer(nft, tx_context::sender(ctx));

        // Emit event
        event::emit(MerchantCreated {
            merchant_id,
            name: string::utf8(name),
            description: string::utf8(description),
            logo: string::utf8(logo)
        });
    }

    public entry fun create_invoice(
        state: &mut GugupayState,
        merchant_nft: &MerchantNFT,
        description: vector<u8>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Verify the caller owns the merchant NFT
        assert!(merchant_nft.owner == tx_context::sender(ctx), ENotOwner);

        let invoice_id = state.invoice_count + 1;
        let invoice = Invoice {
            id: object::new(ctx),
            invoice_id,
            merchant_id: merchant_nft.merchant_id,
            description: string::utf8(description),
            amount,
            is_paid: false,
            deadline: clock::timestamp_ms(clock) + 86400000,
            merchant_owner: merchant_nft.owner
        };

        table::add(&mut state.invoices, invoice_id, invoice);
        state.invoice_count = invoice_id;

        // Mint and transfer NFT to merchant owner
        let nft = mint_invoice_nft(invoice_id, ctx);
        transfer::transfer(nft, merchant_nft.owner);

        // Emit event
        event::emit(InvoiceCreated {
            invoice_id,
            amount
        });
    }

    public entry fun pay_invoice(
        state: &mut GugupayState,
        invoice_id: u64,
        merchant_nft: &mut MerchantNFT,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let invoice = table::borrow_mut(&mut state.invoices, invoice_id);
        
        assert!(!invoice.is_paid, EInvoiceAlreadyPaid);
        assert!(invoice.deadline > clock::timestamp_ms(clock), EInvoiceExpired);
        assert!(coin::value(&payment) >= invoice.amount, EInsufficientPayment);
        assert!(merchant_nft.merchant_id == invoice.merchant_id, ENotOwner);

        // Update merchant NFT balance
        merchant_nft.balance = merchant_nft.balance + invoice.amount;
        invoice.is_paid = true;

        // Transfer payment to contract treasury
        transfer::public_transfer(payment, tx_context::sender(ctx)); // TODO: change to contract treasury
    }

    fun mint_merchant_nft(
        merchant_id: u64,
        ctx: &mut TxContext
    ): MerchantNFT {
        MerchantNFT {
            id: object::new(ctx),
            name: string::utf8(b"GugupayM"),
            symbol: string::utf8(b"GUGUMERCHANT"),
            merchant_id,
            owner: tx_context::sender(ctx),
            balance: 0
        }
    }

    fun mint_invoice_nft(
        invoice_id: u64,
        ctx: &mut TxContext
    ): InvoiceNFT {
        InvoiceNFT {
            id: object::new(ctx),
            name: string::utf8(b"GugupayI"),
            symbol: string::utf8(b"GUGUINVOICE"),
            invoice_id,
            owner: tx_context::sender(ctx)
        }
    }

    public entry fun delete_merchant(
        state: &GugupayState,
        merchant_nft: MerchantNFT,
        ctx: &mut TxContext
    ) {
        // Verify the caller owns the merchant NFT
        assert!(merchant_nft.owner == tx_context::sender(ctx), ENotOwner);
        
        // Verify merchant exists and matches the NFT
        let merchant = table::borrow(&state.merchants, merchant_nft.merchant_id);
        assert!(merchant.owner == tx_context::sender(ctx), ENotOwner);
        
        let MerchantNFT { 
            id, 
            name: _, 
            symbol: _, 
            merchant_id: _, 
            owner: _, 
            balance: _ 
        } = merchant_nft;
        object::delete(id);
    }

    public entry fun delete_invoice(
        state: &GugupayState,
        merchant_nft: &MerchantNFT,
        invoice_nft: InvoiceNFT,
        ctx: &mut TxContext
    ) {
        let invoice = table::borrow(&state.invoices, invoice_nft.invoice_id);
        
        // Verify the caller owns the merchant NFT and it matches the invoice's merchant
        assert!(merchant_nft.owner == tx_context::sender(ctx), ENotOwner);
        assert!(merchant_nft.merchant_id == invoice.merchant_id, ENotOwner);
        
        let InvoiceNFT { id, name: _, symbol: _, invoice_id: _, owner: _ } = invoice_nft;
        object::delete(id);
    }

    public entry fun withdraw_sui(
        merchant_nft: &mut MerchantNFT,
        treasury: &mut Coin<SUI>,
        ctx: &mut TxContext
    ) {
        // Verify the caller is the merchant NFT owner
        assert!(merchant_nft.owner == tx_context::sender(ctx), ENotOwner);
        
        // Verify there's balance to withdraw
        assert!(merchant_nft.balance > 0, EInsufficientBalance);
        
        // Split coins from treasury
        let payment = coin::split(treasury, merchant_nft.balance, ctx);
        
        // Reset merchant NFT balance
        merchant_nft.balance = 0;
        
        // Transfer to merchant owner
        transfer::public_transfer(payment, merchant_nft.owner);
    }

    // Add public accessor functions
    public fun merchant_id(nft: &MerchantNFT): u64 {
        nft.merchant_id
    }

    public fun merchant_owner(nft: &MerchantNFT): address {
        nft.owner
    }

    public fun merchant_balance(nft: &MerchantNFT): u64 {
        nft.balance
    }

    public fun invoice_id(nft: &InvoiceNFT): u64 {
        nft.invoice_id
    }

    public fun invoice_owner(nft: &InvoiceNFT): address {
        nft.owner
    }
} 