import "FlowJukeBox"

/// Removes (burns) a FlowJukeBox NFT from the contract's own collection.
/// Must be signed by the account that owns the contract (i.e. FlowJukeBox.account).

transaction(nftID: UInt64) {

    prepare(signer: auth(BorrowValue) &Account) {
        // The contract's collection is stored at FlowJukeBox.CollectionStoragePath.
        let collectionRef = signer.storage.borrow<&FlowJukeBox.Collection>(
            from: FlowJukeBox.CollectionStoragePath
        ) ?? panic("❌ FlowJukeBox.Collection not found in signer storage")

        log("🔥 Burning FlowJukeBox NFT #".concat(nftID.toString()))

        // Directly call the internal destroy helper.
        collectionRef.removeAndDestroy(id: nftID)

        log("✅ Successfully removed and destroyed NFT #".concat(nftID.toString()))
    }

    execute {
        log("Transaction complete — NFT burned and removed from collection.")
    }
}
