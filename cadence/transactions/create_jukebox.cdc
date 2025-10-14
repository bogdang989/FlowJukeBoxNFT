import "FlowJukeBox"
import "FlowToken"
import "FungibleToken"

// Mints a new Jukebox NFT (10 FLOW fee handled here)
transaction(queueIdentifier: String, queueDuration: UFix64) {

    prepare(signer: auth(BorrowValue, FungibleToken.Withdraw) &Account) {
        // Withdraw 10 FLOW from signer
        let vault = signer.storage.borrow<
            auth(FungibleToken.Withdraw) &FlowToken.Vault
        >(from: /storage/flowTokenVault)
            ?? panic("Missing FlowToken vault in signer storage")

        let payment <- vault.withdraw(amount: 10.0)

        // Deposit directly into contract’s FlowToken receiver
        let receiver = getAccount(FlowJukeBox.contractAddress)
            .capabilities
            .borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("FlowJukeBox receiver not found")

        receiver.deposit(from: <- payment)

        // Mint new NFT (no payment param)
        FlowJukeBox.createJukeboxSession(
            sessionOwner: signer.address,
            queueIdentifier: queueIdentifier,
            queueDuration: queueDuration
        )
    }

    execute {
        log("✅ Created FlowJukeBox session ".concat(queueIdentifier))
    }
}
