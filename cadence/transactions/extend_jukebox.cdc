import "FungibleToken"
import "FlowToken"
import "FlowJukeBox"

/// Extends a jukebox NFT’s active duration by a given number of seconds
/// (must be multiple of 3600 — e.g., 10800.0 = 3 hours)
transaction(nftID: UInt64, additionalDuration: UFix64) {
    let payerVault: auth(FungibleToken.Withdraw) &FlowToken.Vault
    let signerAddr: Address

    prepare(signer: auth(Storage, BorrowValue) &Account) {
        self.signerAddr = signer.address

        // Borrow signer’s FlowToken vault for payment
        self.payerVault = signer.storage.borrow<
            auth(FungibleToken.Withdraw) &FlowToken.Vault
        >(from: /storage/flowTokenVault)
            ?? panic("Missing FlowToken vault at /storage/flowTokenVault")

        // Borrow FlowJukeBox collection and NFT
        let collectionRef = signer.storage.borrow<&FlowJukeBox.Collection>(
            from: /storage/FlowJukeBoxCollection
        ) ?? panic("FlowJukeBox.Collection not found in signer storage")

        let nftRef = collectionRef.borrowJukeboxNFT(nftID)
            ?? panic("No FlowJukeBox NFT with that ID found")

        // Extend lifetime (charges same as minting per hour)
        FlowJukeBox.extendJukeboxWithRef(
            nftRef: nftRef,
            additionalDuration: additionalDuration,
            extender: self.signerAddr,
            payerVault: self.payerVault
        )

        log("✅ Extended jukebox NFT ".concat(nftID.toString())
            .concat(" by ").concat(additionalDuration.toString()).concat(" seconds"))
    }

    execute {
        log("🎵 Lifetime extension completed.")
    }
}
