import "FlowJukeBox"
/// Adds or increases a backing for a value (song / URL) in a given jukebox NFT
transaction(
    nftID: UInt64,
    value: String,
    backing: UFix64,
    duration: UFix64
) {
    prepare(signer: auth(BorrowValue) &Account) {
        let collectionRef = signer.storage.borrow<&FlowJukeBox.Collection>(
            from: /storage/FlowJukeBoxCollection
        ) ?? panic("FlowJukeBox.Collection not found in signer storage")

        let nftRef = collectionRef.borrowJukeboxNFT(nftID)
            ?? panic("No FlowJukeBox NFT with that ID found")

        let timestamp = getCurrentBlock().timestamp

        nftRef.addEntry(
            value: value,
            backing: backing,
            duration: duration,
            timestamp: timestamp
        )
    }

    execute {
        log("✅ Entry added/updated for FlowJukeBox NFT ".concat(nftID.toString()))
    }
}
