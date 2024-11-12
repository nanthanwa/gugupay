module gugupay::payment_service {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use std::string::{Self, String};
    use std::option::{Self, Option};
    use sui::event;
    use sui::clock::{Self, Clock};
    use sui::table::{Self, Table};

    // ======== Errors ========
    const ENotMerchantOwner: u64 = 0;
    const EInvoiceExpired: u64 = 1;
    const EInvoiceAlreadyPaid: u64 = 2;
    const EInsufficientPayment: u64 = 3;
    const EInvalidAmount: u64 = 4;
    const EInvalidExpiryTime: u64 = 5;

    // ======== Events ========
    public struct MerchantCreated has copy, drop {
        merchant_id: ID,
        name: String,
        owner: address
    }

    public struct InvoiceCreated has copy, drop {
        invoice_id: ID,
        merchant_id: ID,
        amount_usd: u64,
        expires_at: u64
    }

    public struct InvoicePaid has copy, drop {
        invoice_id: ID,
        merchant_id: ID,
        paid_by: address,
        amount_sui: u64
    }

    public struct MerchantUpdated has copy, drop {
        merchant_id: ID,
        name: String,
        owner: address
    }

    public struct InvoiceUpdated has copy, drop {
        invoice_id: ID,
        merchant_id: ID,
        amount_usd: u64,
        expires_at: u64
    }

    // ======== Objects ========
    public struct PaymentStore has key {
        id: UID,
        merchants: Table<ID, Merchant>,
        invoices: Table<ID, Invoice>,
        last_merchant_id: Option<ID>,
        last_invoice_id: Option<ID>
    }

    public struct Merchant has store {
        id: ID,
        name: String,
        description: String,
        logo_url: String,
        callback_url: String,
        owner: address,
        balance: Balance<SUI>
    }

    public struct Invoice has store {
        id: ID,
        merchant_id: ID,
        description: String,
        amount_usd: u64,
        expires_at: u64,
        is_paid: bool
    }

    // ======== Init Function ========
    fun init(ctx: &mut TxContext) {
        let store = PaymentStore {
            id: object::new(ctx),
            merchants: table::new(ctx),
            invoices: table::new(ctx),
            last_merchant_id: option::none(),
            last_invoice_id: option::none()
        };
        transfer::share_object(store);
    }

    #[test_only]
    public(package) fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }

    // ======== Public Functions ========
    public entry fun create_merchant(
        store: &mut PaymentStore,
        name: vector<u8>,
        description: vector<u8>,
        logo_url: vector<u8>,
        callback_url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let merchant_id = object::new(ctx);
        let id = object::uid_to_inner(&merchant_id);
        object::delete(merchant_id);

        let name_str = string::utf8(name);
        let owner = tx_context::sender(ctx);

        let merchant = Merchant {
            id,
            name: name_str,
            description: string::utf8(description),
            logo_url: string::utf8(logo_url),
            callback_url: string::utf8(callback_url),
            owner,
            balance: balance::zero()
        };

        table::add(&mut store.merchants, id, merchant);
        store.last_merchant_id = option::some(id);

        event::emit(MerchantCreated {
            merchant_id: id,
            name: name_str,
            owner
        });
    }

    public entry fun create_invoice(
        store: &mut PaymentStore,
        merchant_id: ID,
        description: vector<u8>,
        amount_usd: u64,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let merchant = table::borrow(&store.merchants, merchant_id);
        assert!(tx_context::sender(ctx) == merchant.owner, ENotMerchantOwner);
        assert!(amount_usd > 0, EInvalidAmount);
        assert!(expires_at > clock::timestamp_ms(clock), EInvoiceExpired);

        let invoice_id = object::new(ctx);
        let id = object::uid_to_inner(&invoice_id);
        object::delete(invoice_id);

        let invoice = Invoice {
            id,
            merchant_id,
            description: string::utf8(description),
            amount_usd,
            expires_at,
            is_paid: false
        };

        table::add(&mut store.invoices, id, invoice);
        store.last_invoice_id = option::some(id);

        event::emit(InvoiceCreated {
            invoice_id: id,
            merchant_id,
            amount_usd,
            expires_at
        });
    }

    public entry fun pay_invoice(
        store: &mut PaymentStore,
        invoice_id: ID,
        mut payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let invoice = table::borrow_mut(&mut store.invoices, invoice_id);
        let merchant = table::borrow_mut(&mut store.merchants, invoice.merchant_id);
        
        // In real implementation, we would get this from Pyth Oracle
        let sui_usd_rate = 40; // Assuming 1 SUI = $40 USD
        
        assert!(!invoice.is_paid, EInvoiceAlreadyPaid);
        assert!(clock::timestamp_ms(clock) <= invoice.expires_at, EInvoiceExpired);
        
        let payment_value = coin::value(&payment);
        let required_sui = (invoice.amount_usd * 1000000000) / sui_usd_rate; // Convert to SUI with 9 decimals
        
        assert!(payment_value >= required_sui, EInsufficientPayment);

        // Split excess payment if any
        if (payment_value > required_sui) {
            let excess = coin::split(&mut payment, payment_value - required_sui, ctx);
            transfer::public_transfer(excess, tx_context::sender(ctx));
        };

        // Add payment to merchant balance
        let balance = coin::into_balance(payment);
        balance::join(&mut merchant.balance, balance);

        // Mark invoice as paid
        invoice.is_paid = true;

        event::emit(InvoicePaid {
            invoice_id,
            merchant_id: invoice.merchant_id,
            paid_by: tx_context::sender(ctx),
            amount_sui: required_sui
        });
    }

    public entry fun withdraw_balance(
        store: &mut PaymentStore,
        merchant_id: ID,
        ctx: &mut TxContext
    ) {
        let merchant = table::borrow_mut(&mut store.merchants, merchant_id);
        assert!(tx_context::sender(ctx) == merchant.owner, ENotMerchantOwner);
        
        let amount = balance::value(&merchant.balance);
        let withdrawn = coin::from_balance(balance::split(&mut merchant.balance, amount), ctx);
        transfer::public_transfer(withdrawn, merchant.owner);
    }

    public entry fun update_merchant(
        store: &mut PaymentStore,
        merchant_id: ID,
        name: vector<u8>,
        description: vector<u8>,
        logo_url: vector<u8>,
        callback_url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let merchant = table::borrow_mut(&mut store.merchants, merchant_id);
        // Verify sender is merchant owner
        assert!(tx_context::sender(ctx) == merchant.owner, ENotMerchantOwner);
        
        // Update merchant details
        merchant.name = string::utf8(name);
        merchant.description = string::utf8(description);
        merchant.logo_url = string::utf8(logo_url);
        merchant.callback_url = string::utf8(callback_url);

        event::emit(MerchantUpdated {
            merchant_id: merchant.id,
            name: merchant.name,
            owner: merchant.owner
        });
    }

    public entry fun update_invoice(
        store: &mut PaymentStore,
        invoice_id: ID,
        description: vector<u8>,
        amount_usd: u64,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        let invoice = table::borrow_mut(&mut store.invoices, invoice_id);
        let merchant = table::borrow(&store.merchants, invoice.merchant_id);
        
        // Verify sender is merchant owner
        assert!(tx_context::sender(ctx) == merchant.owner, ENotMerchantOwner);
        
        // Cannot update paid invoices
        assert!(!invoice.is_paid, EInvoiceAlreadyPaid);
        
        // Validate new values
        assert!(amount_usd > 0, EInvalidAmount);
        assert!(expires_at > clock::timestamp_ms(clock), EInvalidExpiryTime);

        // Update invoice details
        invoice.description = string::utf8(description);
        invoice.amount_usd = amount_usd;
        invoice.expires_at = expires_at;

        event::emit(InvoiceUpdated {
            invoice_id,
            merchant_id: invoice.merchant_id,
            amount_usd,
            expires_at
        });
    }

    // ======== View Functions ========
    public fun get_merchant_owner(store: &PaymentStore, merchant_id: ID): address {
        let merchant = table::borrow(&store.merchants, merchant_id);
        merchant.owner
    }

    public fun get_invoice_merchant_id(store: &PaymentStore, invoice_id: ID): ID {
        let invoice = table::borrow(&store.invoices, invoice_id);
        invoice.merchant_id
    }

    public fun is_invoice_paid(store: &PaymentStore, invoice_id: ID): bool {
        let invoice = table::borrow(&store.invoices, invoice_id);
        invoice.is_paid
    }

    public fun get_merchant_balance(store: &PaymentStore, merchant_id: ID): u64 {
        let merchant = table::borrow(&store.merchants, merchant_id);
        balance::value(&merchant.balance)
    }

    // Add these helper functions after the view functions
    #[test_only]
    public(package) fun get_merchant_id_for_testing(store: &PaymentStore): ID {
        assert!(option::is_some(&store.last_merchant_id), 0);
        *option::borrow(&store.last_merchant_id)
    }

    #[test_only]
    public(package) fun get_invoice_id_for_testing(store: &PaymentStore, _merchant_id: ID): ID {
        assert!(option::is_some(&store.last_invoice_id), 0);
        *option::borrow(&store.last_invoice_id)
    }

    // Add new helper functions for testing
    #[test_only]
    public(package) fun get_merchant_for_testing(store: &PaymentStore, merchant_id: ID): &Merchant {
        table::borrow(&store.merchants, merchant_id)
    }

    #[test_only]
    public(package) fun get_invoice_for_testing(store: &PaymentStore, invoice_id: ID): &Invoice {
        table::borrow(&store.invoices, invoice_id)
    }
}
