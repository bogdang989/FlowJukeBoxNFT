import "FlowJukeBox"
import "FlowToken"
import "FungibleToken"

transaction(
    nftID: UInt64,
    value: String,
    displayName: String,
    duration: UFix64,
    amount: UFix64
) {
    prepare(signer: auth(BorrowValue, FungibleToken.Withdraw) &Account) {
        let vaultRef = signer.storage.borrow<
            auth(FungibleToken.Withdraw) &FlowToken.Vault
        >(from: /storage/flowTokenVault)
            ?? panic("Missing FlowToken vault")

        let payment <- vaultRef.withdraw(amount: amount)

        FlowJukeBox.depositBacking(
            nftID: nftID,
            from: signer.address,
            value: value,
            displayName: displayName,
            duration: duration,
            payment: <- payment
        )
    }

    execute {
        log("✅ Added entry ".concat(displayName))
    }
}
