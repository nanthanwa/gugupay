module gugupay::payment_service {
    use sui::object::{Self, ID, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use std::string::{Self, String};
    use std::vector;
    use sui::event;
    use sui::clock::{Self, Clock};

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
    public struct Merchant has key, store {
        id: UID,
        name: String,
        description: String,
        logo_url: String,
        callback_url: String,
        owner: address,
        balance: Balance<SUI>
    }

    public struct Invoice has key, store {
        id: UID,
        merchant_id: ID,
        description: String,
        amount_usd: u64,
        expires_at: u64,
        is_paid: bool
    }

    // ======== Public Functions ========
    public fun create_merchant(
        name: vector<u8>,
        description: vector<u8>,
        logo_url: vector<u8>,
        callback_url: vector<u8>,
        ctx: &mut TxContext
    ) {
        let merchant = Merchant {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            logo_url: string::utf8(logo_url),
            callback_url: string::utf8(callback_url),
            owner: tx_context::sender(ctx),
            balance: balance::zero()
        };

        event::emit(MerchantCreated {
            merchant_id: object::uid_to_inner(&merchant.id),
            name: merchant.name,
            owner: merchant.owner
        });

        transfer::transfer(merchant, tx_context::sender(ctx));
    }

    public entry fun create_invoice(
        merchant: &Merchant,
        description: vector<u8>,
        amount_usd: u64,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == merchant.owner, ENotMerchantOwner);
        assert!(amount_usd > 0, EInvalidAmount);
        assert!(expires_at > clock::timestamp_ms(clock), EInvoiceExpired);

        let invoice = Invoice {
            id: object::new(ctx),
            merchant_id: object::uid_to_inner(&merchant.id),
            description: string::utf8(description),
            amount_usd: amount_usd,
            expires_at: expires_at,
            is_paid: false
        };

        event::emit(InvoiceCreated {
            invoice_id: object::uid_to_inner(&invoice.id),
            merchant_id: invoice.merchant_id,
            amount_usd: amount_usd,
            expires_at: expires_at
        });

        transfer::transfer(invoice, tx_context::sender(ctx));
    }

    public entry fun pay_invoice(
        merchant: &mut Merchant,
        invoice: &mut Invoice,
        mut payment: Coin<SUI>,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // In real implementation, we would get this from Pyth Oracle
        let sui_usd_rate = 40; // Assuming 1 SUI = $40 USD
        
        assert!(!invoice.is_paid, EInvoiceAlreadyPaid);
        assert!(clock::timestamp_ms(clock) <= invoice.expires_at, EInvoiceExpired);
        
        let payment_value = coin::value(&payment);
        let required_sui = (invoice.amount_usd * 1000000000) / sui_usd_rate; // Convert to SUI with 8 decimals
        
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
            invoice_id: object::uid_to_inner(&invoice.id),
            merchant_id: invoice.merchant_id,
            paid_by: tx_context::sender(ctx),
            amount_sui: required_sui
        });
    }

    public entry fun withdraw_balance(
        merchant: &mut Merchant,
        ctx: &mut TxContext
    ) {
        assert!(tx_context::sender(ctx) == merchant.owner, ENotMerchantOwner);
        
        let amount = balance::value(&merchant.balance);
        let withdrawn = coin::from_balance(balance::split(&mut merchant.balance, amount), ctx);
        // Automatically transfer the withdrawn coins to the merchant owner
        transfer::public_transfer(withdrawn, merchant.owner);
    }

    public entry fun update_merchant(
        merchant: &mut Merchant,
        name: vector<u8>,
        description: vector<u8>,
        logo_url: vector<u8>,
        callback_url: vector<u8>,
        ctx: &mut TxContext
    ) {
        // Verify sender is merchant owner
        assert!(tx_context::sender(ctx) == merchant.owner, ENotMerchantOwner);
        
        // Update merchant details
        merchant.name = string::utf8(name);
        merchant.description = string::utf8(description);
        merchant.logo_url = string::utf8(logo_url);
        merchant.callback_url = string::utf8(callback_url);

        event::emit(MerchantUpdated {
            merchant_id: object::uid_to_inner(&merchant.id),
            name: merchant.name,
            owner: merchant.owner
        });
    }

    public entry fun update_invoice(
        merchant: &Merchant,
        invoice: &mut Invoice,
        description: vector<u8>,
        amount_usd: u64,
        expires_at: u64,
        clock: &Clock,
        ctx: &mut TxContext
    ) {
        // Verify sender is merchant owner
        assert!(tx_context::sender(ctx) == merchant.owner, ENotMerchantOwner);
        
        // Verify invoice belongs to this merchant
        assert!(invoice.merchant_id == object::uid_to_inner(&merchant.id), ENotMerchantOwner);
        
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
            invoice_id: object::uid_to_inner(&invoice.id),
            merchant_id: invoice.merchant_id,
            amount_usd: amount_usd,
            expires_at: expires_at
        });
    }

    // ======== View Functions ========
    public fun get_merchant_owner(merchant: &Merchant): address {
        merchant.owner
    }

    public fun get_invoice_merchant_id(invoice: &Invoice): ID {
        invoice.merchant_id
    }

    public fun is_invoice_paid(invoice: &Invoice): bool {
        invoice.is_paid
    }

    public fun get_merchant_balance(merchant: &Merchant): u64 {
        balance::value(&merchant.balance)
    }
}
