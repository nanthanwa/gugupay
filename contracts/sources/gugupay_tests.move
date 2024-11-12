#[test_only]
module gugupay::payment_service_tests {
    use sui::test_scenario::{Self as ts};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::object;
    use gugupay::payment_service::{Self, PaymentStore};
    use sui::tx_context;

    // Test constants
    const MERCHANT_NAME: vector<u8> = b"Test Merchant";
    const MERCHANT_DESCRIPTION: vector<u8> = b"A test merchant";
    const MERCHANT_LOGO_URL: vector<u8> = b"https://example.com/logo.png";
    const MERCHANT_CALLBACK_URL: vector<u8> = b"https://example.com/callback";
    const INVOICE_DESCRIPTION: vector<u8> = b"Test Invoice";
    const INVOICE_AMOUNT_USD: u64 = 100; // $100
    const INVOICE_EXPIRES_AT: u64 = 1000000000000; // Some future timestamp

    // Error test constants
    const INVALID_AMOUNT: u64 = 0;
    const CURRENT_TIMESTAMP: u64 = 1000000000000; // Base timestamp for tests
    const FUTURE_TIMESTAMP: u64 = 1100000000000; // Future (valid) timestamp
    const PAST_TIMESTAMP: u64 = 900000000000; // Definitely in the past

    // Helper function to setup store and merchant
    fun setup_test_store(scenario: &mut ts::Scenario): object::ID {
        let ctx = ts::ctx(scenario);
        payment_service::init_for_testing(ctx);
        
        ts::next_tx(scenario, @0x1);
        {
            let mut store = ts::take_shared<PaymentStore>(scenario);
            let ctx = ts::ctx(scenario);
            payment_service::create_merchant(
                &mut store,
                MERCHANT_NAME,
                MERCHANT_DESCRIPTION,
                MERCHANT_LOGO_URL,
                MERCHANT_CALLBACK_URL,
                ctx
            );
            let merchant_id = payment_service::get_merchant_id_for_testing(&store);
            ts::return_shared(store);
            merchant_id
        }
    }

    // Helper function to setup test invoice
    fun setup_test_invoice(scenario: &mut ts::Scenario, clock: &Clock): (object::ID, object::ID) {
        let merchant_id = setup_test_store(scenario);
        
        ts::next_tx(scenario, @0x1);
        {
            let mut store = ts::take_shared<PaymentStore>(scenario);
            let ctx = ts::ctx(scenario);
            payment_service::create_invoice(
                &mut store,
                merchant_id,
                INVOICE_DESCRIPTION,
                INVOICE_AMOUNT_USD,
                FUTURE_TIMESTAMP,
                clock,
                ctx
            );
            let invoice_id = payment_service::get_invoice_id_for_testing(&store, merchant_id);
            ts::return_shared(store);
            (merchant_id, invoice_id)
        }
    }

    #[test]
    #[expected_failure(abort_code = payment_service::EInvalidAmount)]
    fun test_create_invoice_with_zero_amount() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        let merchant_id = setup_test_store(&mut scenario);
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::create_invoice(
                &mut store,
                merchant_id,
                INVOICE_DESCRIPTION,
                INVALID_AMOUNT,
                INVOICE_EXPIRES_AT,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = payment_service::EInvoiceExpired)]
    fun test_create_invoice_with_past_expiry() {
        let mut scenario = ts::begin(@0x1);
        // Create clock with specific timestamp
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, CURRENT_TIMESTAMP);
        
        let merchant_id = setup_test_store(&mut scenario);
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::create_invoice(
                &mut store,
                merchant_id,
                INVOICE_DESCRIPTION,
                INVOICE_AMOUNT_USD,
                PAST_TIMESTAMP,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = payment_service::ENotMerchantOwner)]
    fun test_unauthorized_invoice_creation() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        let merchant_id = setup_test_store(&mut scenario);
        
        ts::next_tx(&mut scenario, @0x2);
        {
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::create_invoice(
                &mut store,
                merchant_id,
                INVOICE_DESCRIPTION,
                INVOICE_AMOUNT_USD,
                INVOICE_EXPIRES_AT,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = payment_service::EInsufficientPayment)]
    fun test_insufficient_payment() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        let (merchant_id, invoice_id) = setup_test_invoice(&mut scenario, &clock);
        
        ts::next_tx(&mut scenario, @0x2);
        {
            let payment = coin::mint_for_testing<SUI>(1000000, ts::ctx(&mut scenario));
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::pay_invoice(
                &mut store,
                invoice_id,
                payment,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = payment_service::EInvoiceAlreadyPaid)]
    fun test_pay_invoice_twice() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        let (_merchant_id, invoice_id) = setup_test_invoice(&mut scenario, &clock);
        
        // First payment
        ts::next_tx(&mut scenario, @0x2);
        {
            let payment = coin::mint_for_testing<SUI>(3000000000, ts::ctx(&mut scenario));
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::pay_invoice(
                &mut store,
                invoice_id,
                payment,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        // Second payment (should fail)
        ts::next_tx(&mut scenario, @0x3);
        {
            let payment = coin::mint_for_testing<SUI>(3000000000, ts::ctx(&mut scenario));
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::pay_invoice(
                &mut store,
                invoice_id,
                payment,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // Let's also add a test for successful invoice creation
    #[test]
    fun test_create_invoice_success() {
        let mut scenario = ts::begin(@0x1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, CURRENT_TIMESTAMP);
        
        let merchant_id = setup_test_store(&mut scenario);
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::create_invoice(
                &mut store,
                merchant_id,
                INVOICE_DESCRIPTION,
                INVOICE_AMOUNT_USD,
                FUTURE_TIMESTAMP,
                &clock,
                ts::ctx(&mut scenario)
            );

            // Verify invoice was created with correct values
            let invoice_id = payment_service::get_invoice_id_for_testing(&store, merchant_id);
            assert!(payment_service::get_invoice_merchant_id(&store, invoice_id) == merchant_id, 0);
            assert!(!payment_service::is_invoice_paid(&store, invoice_id), 1);
            
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    // And a test for successful payment
    #[test]
    fun test_pay_invoice_success() {
        let mut scenario = ts::begin(@0x1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, CURRENT_TIMESTAMP);
        
        let (merchant_id, invoice_id) = setup_test_invoice(&mut scenario, &clock);
        
        // Customer pays the invoice
        ts::next_tx(&mut scenario, @0x2);
        {
            let payment = coin::mint_for_testing<SUI>(3000000000, ts::ctx(&mut scenario)); // 3 SUI
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            
            // Before payment checks
            assert!(!payment_service::is_invoice_paid(&store, invoice_id), 0);
            assert!(payment_service::get_merchant_balance(&store, merchant_id) == 0, 1);
            
            payment_service::pay_invoice(
                &mut store,
                invoice_id,
                payment,
                &clock,
                ts::ctx(&mut scenario)
            );
            
            // After payment checks
            assert!(payment_service::is_invoice_paid(&store, invoice_id), 2);
            assert!(payment_service::get_merchant_balance(&store, merchant_id) == 2500000000, 3); // 2.5 SUI
            
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_withdraw_balance_success() {
        let mut scenario = ts::begin(@0x1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, CURRENT_TIMESTAMP);
        
        let (merchant_id, invoice_id) = setup_test_invoice(&mut scenario, &clock);
        
        // Customer pays the invoice
        ts::next_tx(&mut scenario, @0x2);
        {
            let payment = coin::mint_for_testing<SUI>(3000000000, ts::ctx(&mut scenario)); // 3 SUI
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::pay_invoice(
                &mut store,
                invoice_id,
                payment,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        // Merchant withdraws balance
        ts::next_tx(&mut scenario, @0x1);
        {
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            
            // Check balance before withdrawal
            assert!(payment_service::get_merchant_balance(&store, merchant_id) == 2500000000, 0); // 2.5 SUI
            
            payment_service::withdraw_balance(
                &mut store,
                merchant_id,
                ts::ctx(&mut scenario)
            );
            
            // Check balance after withdrawal
            assert!(payment_service::get_merchant_balance(&store, merchant_id) == 0, 1);
            
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = payment_service::ENotMerchantOwner)]
    fun test_withdraw_balance_unauthorized() {
        let mut scenario = ts::begin(@0x1);
        let mut clock = clock::create_for_testing(ts::ctx(&mut scenario));
        clock::set_for_testing(&mut clock, CURRENT_TIMESTAMP);
        
        let (merchant_id, invoice_id) = setup_test_invoice(&mut scenario, &clock);
        
        // Customer pays the invoice
        ts::next_tx(&mut scenario, @0x2);
        {
            let payment = coin::mint_for_testing<SUI>(3000000000, ts::ctx(&mut scenario));
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::pay_invoice(
                &mut store,
                invoice_id,
                payment,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        // Non-owner tries to withdraw balance (should fail)
        ts::next_tx(&mut scenario, @0x2);
        {
            let mut store = ts::take_shared<PaymentStore>(&scenario);
            payment_service::withdraw_balance(
                &mut store,
                merchant_id,
                ts::ctx(&mut scenario)
            );
            ts::return_shared(store);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }
}
