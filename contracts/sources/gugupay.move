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

    // Rest of the code remains the same...
} 