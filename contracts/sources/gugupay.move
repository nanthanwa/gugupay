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
        owner: address
    }

    public struct GugupayState has key {
        id: UID,
        merchant_count: u64,
        invoice_count: u64,
        merchants: Table<u64, Merchant>,
        invoices: Table<u64, Invoice>,
        merchant_balances: Table<address, u64>
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
        merchant_id: u64,
        description: vector<u8>,
        amount: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let merchant = table::borrow(&state.merchants, merchant_id);
        assert!(merchant.owner == tx_context::sender(ctx), ENotOwner);

        let invoice_id = state.invoice_count + 1;
        let invoice = Invoice {
            id: object::new(ctx),
            invoice_id,
            merchant_id,
            description: string::utf8(description),
            amount,
            is_paid: false,
            deadline: clock::timestamp_ms(clock) + 86400000, // 24 hours in milliseconds
            owner: tx_context::sender(ctx)
        };

        table::add(&mut state.invoices, invoice_id, invoice);
        state.invoice_count = invoice_id;

        // Emit event
        event::emit(InvoiceCreated {
            invoice_id,
            amount
        });
    }

    public entry fun pay_invoice(
        state: &mut GugupayState,
        invoice_id: u64,
        payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let invoice = table::borrow_mut(&mut state.invoices, invoice_id);
        
        assert!(!invoice.is_paid, EInvoiceAlreadyPaid);
        assert!(invoice.deadline > clock::timestamp_ms(clock), EInvoiceExpired);
        assert!(coin::value(&payment) >= invoice.amount, EInsufficientPayment);

        // Update merchant balance
        let merchant = table::borrow(&state.merchants, invoice.merchant_id);
        let current_balance = *table::borrow_mut(&mut state.merchant_balances, merchant.owner);
        table::add(&mut state.merchant_balances, merchant.owner, current_balance + invoice.amount);

        invoice.is_paid = true;
        
        // Transfer payment to contract
        transfer::public_transfer(payment, merchant.owner);
    }
} 