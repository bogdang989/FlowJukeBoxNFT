import "FlowJukeBox"
import "FlowToken"
import "FungibleToken"

// Mints a new Jukebox NFT (10 FLOW fee handled here)
transaction(queueIdentifier: String, queueDuration: UFix64) {

    // Authorized reference so we can withdraw FLOW
    let payerVault: auth(FungibleToken.Withdraw) &FlowToken.Vault
    // Capture recipient (the signer) during prepare
    let recipient: Address

    prepare(signer: auth(BorrowValue) &Account) {
        self.payerVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Missing FlowToken vault at /storage/flowTokenVault")

        self.recipient = signer.address
    }

    execute {
        FlowJukeBox.createJukeboxSession(
            sessionOwner: self.recipient,
            queueIdentifier: queueIdentifier,
            queueDuration: queueDuration,
            payerVault: self.payerVault
        )
        log("✅ Created FlowJukeBox session ".concat(queueIdentifier))
    }
}
