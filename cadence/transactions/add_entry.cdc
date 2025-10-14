import "FlowJukeBox"
import "FlowToken" 
import "FungibleToken"  

transaction(nftID: UInt64, value: String, duration: UFix64, amount: UFix64) {
    prepare(signer: auth(BorrowValue, FungibleToken.Withdraw) &Account) {
        // Borrow a FlowToken Vault with withdraw entitlement
        let vaultRef = signer.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Missing FlowToken vault in signer storage")

        // Withdraw FLOW payment
        let payment <- vaultRef.withdraw(amount: amount)

        // Deposit to the Jukebox contract and add entry
        FlowJukeBox.depositBacking(
            nftID: nftID,
            from: signer.address,
            value: value,
            duration: duration,
            payment: <- payment
        )
    }

    execute {
        log("✅ Entry added to Jukebox ".concat(nftID.toString()))
    }
}
