#[test_only]
module gugupay::payment_service_tests {
    use sui::test_scenario::{Self as ts};
    use sui::coin::{Self};
    use sui::sui::SUI;
    use sui::clock::{Self};
    use sui::object;
    use gugupay::payment_service::{Self, Merchant, Invoice};

    // Test constants
    const MERCHANT_NAME: vector<u8> = b"Test Merchant";
    const MERCHANT_DESCRIPTION: vector<u8> = b"A test merchant";
    const MERCHANT_LOGO_URL: vector<u8> = b"https://example.com/logo.png";
    const MERCHANT_CALLBACK_URL: vector<u8> = b"https://example.com/callback";
    const INVOICE_DESCRIPTION: vector<u8> = b"Test Invoice";
    const INVOICE_AMOUNT_USD: u64 = 100; // $100
    const INVOICE_EXPIRES_AT: u64 = 1000000000000; // Some future timestamp

    #[test]
    fun test_create_merchant() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, @0x1);
        {
            payment_service::create_merchant(
                MERCHANT_NAME,
                MERCHANT_DESCRIPTION,
                MERCHANT_LOGO_URL,
                MERCHANT_CALLBACK_URL,
                ts::ctx(&mut scenario)
            );
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let merchant = ts::take_from_sender<Merchant>(&scenario);
            assert!(payment_service::get_merchant_owner(&merchant) == @0x1, 0);
            ts::return_to_sender(&scenario, merchant);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_create_invoice() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, @0x1);
        {
            payment_service::create_merchant(
                MERCHANT_NAME,
                MERCHANT_DESCRIPTION,
                MERCHANT_LOGO_URL,
                MERCHANT_CALLBACK_URL,
                ts::ctx(&mut scenario)
            );
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let merchant = ts::take_from_sender<Merchant>(&scenario);
            payment_service::create_invoice(
                &merchant,
                INVOICE_DESCRIPTION,
                INVOICE_AMOUNT_USD,
                INVOICE_EXPIRES_AT,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_to_sender(&scenario, merchant);
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let invoice = ts::take_from_sender<Invoice>(&scenario);
            let merchant = ts::take_from_sender<Merchant>(&scenario);
            assert!(payment_service::get_invoice_merchant_id(&invoice) == object::id(&merchant), 0);
            assert!(!payment_service::is_invoice_paid(&invoice), 0);
            ts::return_to_sender(&scenario, invoice);
            ts::return_to_sender(&scenario, merchant);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_pay_invoice() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, @0x1);
        {
            payment_service::create_merchant(
                MERCHANT_NAME,
                MERCHANT_DESCRIPTION,
                MERCHANT_LOGO_URL,
                MERCHANT_CALLBACK_URL,
                ts::ctx(&mut scenario)
            );
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let merchant = ts::take_from_sender<Merchant>(&scenario);
            payment_service::create_invoice(
                &merchant,
                INVOICE_DESCRIPTION,
                INVOICE_AMOUNT_USD,
                INVOICE_EXPIRES_AT,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_to_sender(&scenario, merchant);
        };
        
        ts::next_tx(&mut scenario, @0x2);
        {
            let payment = coin::mint_for_testing<SUI>(3000000000, ts::ctx(&mut scenario)); // 3 SUI
            let mut merchant = ts::take_from_address<Merchant>(&scenario, @0x1);
            let mut invoice = ts::take_from_address<Invoice>(&scenario, @0x1);
            
            payment_service::pay_invoice(
                &mut merchant,
                &mut invoice,
                payment,
                &clock,
                ts::ctx(&mut scenario)
            );
            
            assert!(payment_service::is_invoice_paid(&invoice), 0);
            
            ts::return_to_address(@0x1, merchant);
            ts::return_to_address(@0x1, invoice);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_withdraw_balance() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, @0x1);
        {
            payment_service::create_merchant(
                MERCHANT_NAME,
                MERCHANT_DESCRIPTION,
                MERCHANT_LOGO_URL,
                MERCHANT_CALLBACK_URL,
                ts::ctx(&mut scenario)
            );
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let merchant = ts::take_from_sender<Merchant>(&scenario);
            payment_service::create_invoice(
                &merchant,
                INVOICE_DESCRIPTION,
                INVOICE_AMOUNT_USD,
                INVOICE_EXPIRES_AT,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_to_sender(&scenario, merchant);
        };
        
        ts::next_tx(&mut scenario, @0x2);
        {
            let payment = coin::mint_for_testing<SUI>(3000000000, ts::ctx(&mut scenario)); // 3 SUI
            let mut merchant = ts::take_from_address<Merchant>(&scenario, @0x1);
            let mut invoice = ts::take_from_address<Invoice>(&scenario, @0x1);
            
            payment_service::pay_invoice(
                &mut merchant,
                &mut invoice,
                payment,
                &clock,
                ts::ctx(&mut scenario)
            );
            
            // Verify merchant balance before withdrawal
            assert!(payment_service::get_merchant_balance(&merchant) == 2500000000, 0); // 2.5 SUI
            
            ts::return_to_address(@0x1, merchant);
            ts::return_to_address(@0x1, invoice);
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let mut merchant = ts::take_from_sender<Merchant>(&scenario);
            
            // Withdraw balance
            payment_service::withdraw_balance(&mut merchant, ts::ctx(&mut scenario));
            
            // Verify merchant balance is now zero
            assert!(payment_service::get_merchant_balance(&merchant) == 0, 0);
            
            ts::return_to_sender(&scenario, merchant);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_update_merchant() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, @0x1);
        {
            payment_service::create_merchant(
                MERCHANT_NAME,
                MERCHANT_DESCRIPTION,
                MERCHANT_LOGO_URL,
                MERCHANT_CALLBACK_URL,
                ts::ctx(&mut scenario)
            );
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let mut merchant = ts::take_from_sender<Merchant>(&scenario);
            payment_service::update_merchant(
                &mut merchant,
                b"Updated Merchant",
                b"Updated description",
                b"https://example.com/new_logo.png",
                b"https://example.com/new_callback",
                ts::ctx(&mut scenario)
            );
            ts::return_to_sender(&scenario, merchant);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }

    #[test]
    fun test_update_invoice() {
        let mut scenario = ts::begin(@0x1);
        let clock = clock::create_for_testing(ts::ctx(&mut scenario));
        
        ts::next_tx(&mut scenario, @0x1);
        {
            payment_service::create_merchant(
                MERCHANT_NAME,
                MERCHANT_DESCRIPTION,
                MERCHANT_LOGO_URL,
                MERCHANT_CALLBACK_URL,
                ts::ctx(&mut scenario)
            );
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let merchant = ts::take_from_sender<Merchant>(&scenario);
            payment_service::create_invoice(
                &merchant,
                INVOICE_DESCRIPTION,
                INVOICE_AMOUNT_USD,
                INVOICE_EXPIRES_AT,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_to_sender(&scenario, merchant);
        };
        
        ts::next_tx(&mut scenario, @0x1);
        {
            let merchant = ts::take_from_sender<Merchant>(&scenario);
            let mut invoice = ts::take_from_sender<Invoice>(&scenario);
            payment_service::update_invoice(
                &merchant,
                &mut invoice,
                b"Updated Invoice",
                150,
                2000000000000,
                &clock,
                ts::ctx(&mut scenario)
            );
            ts::return_to_sender(&scenario, merchant);
            ts::return_to_sender(&scenario, invoice);
        };
        
        clock::destroy_for_testing(clock);
        ts::end(scenario);
    }
}
