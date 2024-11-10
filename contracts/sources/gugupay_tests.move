#[test_only]
module gugupay::gugupay_tests {
    use sui::test_scenario::{Self as ts, Scenario};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::test_utils;
    use std::string;
    use gugupay::gugupay::{Self, AdminCap, GugupayState, MerchantNFT, InvoiceNFT};

    // Test addresses
    const ADMIN: address = @0xAD;
    const MERCHANT: address = @0xABC;
    const CUSTOMER: address = @0xCBA;

    // Test values
    const MERCHANT_NAME: vector<u8> = b"Test Merchant";
    const MERCHANT_DESC: vector<u8> = b"Test Description";
    const MERCHANT_LOGO: vector<u8> = b"test_logo.png";
    const INVOICE_DESC: vector<u8> = b"Test Invoice";
    const INVOICE_AMOUNT: u64 = 1000;

    fun setup_test(): Scenario {
        let mut scenario_val = ts::begin(ADMIN);
        let ctx = ts::ctx(&mut scenario_val);
        
        // Initialize the contract
        gugupay::init_for_testing(ctx);
        
        scenario_val
    }

    #[test]
    fun test_create_merchant() {
        let mut scenario = setup_test();
        
        // Create merchant as MERCHANT address
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let ctx = ts::ctx(&mut scenario);

            gugupay::create_merchant(
                &mut state,
                MERCHANT_NAME,
                MERCHANT_DESC,
                MERCHANT_LOGO,
                ctx
            );

            ts::return_shared(state);
        };

        // Verify merchant NFT was created
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let merchant_nft = ts::take_from_sender<MerchantNFT>(&scenario);
            assert!(gugupay::merchant_id(&merchant_nft) == 1, 0);
            assert!(gugupay::merchant_owner(&merchant_nft) == MERCHANT, 1);
            ts::return_to_sender(&scenario, merchant_nft);
        };

        ts::end(scenario);
    }

    #[test]
    fun test_create_invoice() {
        let mut scenario = setup_test();
        
        // First create a merchant
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let merchant_nft = ts::take_from_sender<MerchantNFT>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx = ts::ctx(&mut scenario);

            gugupay::create_invoice(
                &mut state,
                &merchant_nft,
                INVOICE_DESC,
                INVOICE_AMOUNT,
                &clock,
                ctx
            );

            clock::destroy_for_testing(clock);
            ts::return_shared(state);
            ts::return_to_sender(&scenario, merchant_nft);
        };

        // Verify invoice NFT was created
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let invoice_nft = ts::take_from_sender<InvoiceNFT>(&scenario);
            assert!(gugupay::invoice_id(&invoice_nft) == 1, 0);
            assert!(gugupay::invoice_owner(&invoice_nft) == MERCHANT, 1);
            ts::return_to_sender(&scenario, invoice_nft);
        };

        ts::end(scenario);
    }

    #[test]
    fun test_pay_invoice() {
        let mut scenario = setup_test();
        
        // Setup merchant and invoice
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let ctx = ts::ctx(&mut scenario);

            gugupay::create_merchant(
                &mut state,
                MERCHANT_NAME,
                MERCHANT_DESC,
                MERCHANT_LOGO,
                ctx
            );

            ts::return_shared(state);
        };

        ts::next_tx(&mut scenario, MERCHANT);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let merchant_nft = ts::take_from_sender<MerchantNFT>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx = ts::ctx(&mut scenario);

            gugupay::create_invoice(
                &mut state,
                &merchant_nft,
                INVOICE_DESC,
                INVOICE_AMOUNT,
                &clock,
                ctx
            );

            clock::destroy_for_testing(clock);
            ts::return_shared(state);
            ts::return_to_sender(&scenario, merchant_nft);
        };

        // Customer pays invoice
        ts::next_tx(&mut scenario, CUSTOMER);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let merchant_nft = ts::take_from_address<MerchantNFT>(&scenario, MERCHANT);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx = ts::ctx(&mut scenario);

            // Create payment coin
            let payment = coin::mint_for_testing<SUI>(INVOICE_AMOUNT, ctx);

            gugupay::pay_invoice(
                &mut state,
                1, // invoice_id
                &mut merchant_nft,
                payment,
                &clock,
                ctx
            );

            clock::destroy_for_testing(clock);
            ts::return_shared(state);
            ts::return_to_address(MERCHANT, merchant_nft);
        };

        // Verify merchant NFT balance updated
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let merchant_nft = ts::take_from_sender<MerchantNFT>(&scenario);
            assert!(gugupay::merchant_balance(&merchant_nft) == INVOICE_AMOUNT, 0);
            ts::return_to_sender(&scenario, merchant_nft);
        };

        ts::end(scenario);
    }

    #[test]
    fun test_withdraw_sui() {
        let mut scenario = setup_test();
        
        // Setup merchant, invoice, and payment
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let ctx = ts::ctx(&mut scenario);

            gugupay::create_merchant(
                &mut state,
                MERCHANT_NAME,
                MERCHANT_DESC,
                MERCHANT_LOGO,
                ctx
            );

            ts::return_shared(state);
        };

        // Create and pay invoice
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let merchant_nft = ts::take_from_sender<MerchantNFT>(&scenario);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx = ts::ctx(&mut scenario);

            gugupay::create_invoice(
                &mut state,
                &merchant_nft,
                INVOICE_DESC,
                INVOICE_AMOUNT,
                &clock,
                ctx
            );

            // Create treasury coin
            let treasury = coin::mint_for_testing<SUI>(INVOICE_AMOUNT * 2, ctx);

            gugupay::pay_invoice(
                &mut state,
                1, // invoice_id
                &mut merchant_nft,
                treasury,
                &clock,
                ctx
            );

            clock::destroy_for_testing(clock);
            ts::return_shared(state);
            ts::return_to_sender(&scenario, merchant_nft);
        };

        // Merchant withdraws balance
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let merchant_nft = ts::take_from_sender<MerchantNFT>(&scenario);
            let treasury = ts::take_from_sender<Coin<SUI>>(&scenario);
            let ctx = ts::ctx(&mut scenario);

            gugupay::withdraw_sui(
                &mut merchant_nft,
                &mut treasury,
                ctx
            );

            assert!(gugupay::merchant_balance(&merchant_nft) == 0, 0);
            
            ts::return_to_sender(&scenario, merchant_nft);
            ts::return_to_sender(&scenario, treasury);
        };

        ts::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = 0)]
    fun test_unauthorized_invoice_creation() {
        let mut scenario = setup_test();
        
        // Create merchant
        ts::next_tx(&mut scenario, MERCHANT);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let ctx = ts::ctx(&mut scenario);

            gugupay::create_merchant(
                &mut state,
                MERCHANT_NAME,
                MERCHANT_DESC,
                MERCHANT_LOGO,
                ctx
            );

            ts::return_shared(state);
        };

        // Try to create invoice as unauthorized user
        ts::next_tx(&mut scenario, CUSTOMER);
        {
            let mut state = ts::take_shared<GugupayState>(&scenario);
            let merchant_nft = ts::take_from_address<MerchantNFT>(&scenario, MERCHANT);
            let clock = clock::create_for_testing(ts::ctx(&mut scenario));
            let ctx = ts::ctx(&mut scenario);

            // This should fail
            gugupay::create_invoice(
                &mut state,
                &merchant_nft,
                INVOICE_DESC,
                INVOICE_AMOUNT,
                &clock,
                ctx
            );

            clock::destroy_for_testing(clock);
            ts::return_shared(state);
            ts::return_to_address(MERCHANT, merchant_nft);
        };

        ts::end(scenario);
    }
} 