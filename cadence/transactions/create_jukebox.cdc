import "FlowJukeBox"

/// Mints a new Flow Jukebox session NFT.
/// Must be run by the contract owner (who holds the Admin resource).
transaction(
    queueIdentifier: String
) {
    prepare(
        signer: auth(
            BorrowValue,
            SaveValue
        ) &Account
    ) {
        // ✅ Explicitly specify type argument for borrow
        let admin = signer.storage.borrow<&FlowJukeBox.Admin>(
            from: StoragePath(identifier: "FlowJukeBoxAdmin")!
        ) ?? panic("FlowJukeBox.Admin not found in signer storage (must be contract owner)")

        // Mint a new jukebox NFT
        let newSession <- admin.mintJukeboxSession(
            sessionOwner: signer.address,
            queueIdentifier: queueIdentifier
        )

        // ✅ Explicit type argument again for Collection borrow
        let collection = signer.storage.borrow<&FlowJukeBox.Collection>(
            from: StoragePath(identifier: "FlowJukeBoxCollection")!
        ) ?? panic("Signer has no FlowJukeBox.Collection in storage. Run setup_collection first.")

        collection.deposit(token: <- newSession)

        log("✅ Minted new FlowJukeBox session NFT with queue ID ".concat(queueIdentifier))
    }
}
