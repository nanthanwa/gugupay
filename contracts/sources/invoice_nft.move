module gugupay::invoice_nft {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};

    public struct InvoiceNFT has key, store {
        id: UID,
        name: String,
        symbol: String,
        token_id: u64,
        owner: address
    }

    public fun mint(
        to: address,
        token_id: u64,
        ctx: &mut TxContext
    ): InvoiceNFT {
        let nft = InvoiceNFT {
            id: object::new(ctx),
            name: string::utf8(b"GugupayI"),
            symbol: string::utf8(b"GUGUINVOICE"),
            token_id,
            owner: to
        };
        
        nft
    }

    public entry fun burn(nft: InvoiceNFT) {
        let InvoiceNFT { id, name: _, symbol: _, token_id: _, owner: _ } = nft;
        object::delete(id);
    }
} 