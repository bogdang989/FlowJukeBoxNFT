import "FlowJukeBox"
import "FlowJukeBoxTransactionHandler"
import "FlowToken"
import "FungibleToken"

// Mints the Jukebox NFT and immediately starts autoplay by calling playNextOrPayout
// and schedules the next track via the TransactionHandler.
transaction(queueIdentifier: String, queueDuration: UFix64) {
    let payerVault: auth(FungibleToken.Withdraw) &FlowToken.Vault
    let recipient: Address

    prepare(signer: auth(Storage, BorrowValue) &Account) {
        // Ensure signer has a Flow vault
        if !signer.storage.check<@FlowToken.Vault>(from: /storage/flowTokenVault) {
            let vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            signer.storage.save<@FlowToken.Vault>(<- vault, to: /storage/flowTokenVault)
        }

        self.payerVault = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Missing FlowToken vault at /storage/flowTokenVault")

        self.recipient = signer.address
    }

    execute {
        // Mint a new Jukebox NFT
        let newId = FlowJukeBox.createJukeboxSession(
            sessionOwner: self.recipient,
            queueIdentifier: queueIdentifier,
            queueDuration: queueDuration,
            payerVault: self.payerVault
        )

        // Play first song and get info
        let songInfoOpt = FlowJukeBox.playNextOrPayout(nftID: newId)
        if let songInfo = songInfoOpt {
            let duration = songInfo["duration"] as! UFix64

            // Schedule next play
            FlowJukeBoxTransactionHandler.scheduleNextPlay(
                nftId: newId,
                delay: duration,
                feeAmount: 0.1
            )

            log("✅ Created and started FlowJukeBox #".concat(newId.toString()))
            log("⏱ Next play scheduled after ".concat(duration.toString()).concat(" seconds"))
        } else {
            log("⚠️ Session expired immediately or payout already handled.")
        }
    }
}
