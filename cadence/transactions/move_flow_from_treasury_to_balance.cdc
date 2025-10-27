import "FungibleToken"
import "FlowToken"

// Moves FLOW from the contract's /storage/FlowJukeBoxTreasury vault
// into the normal /storage/flowTokenVault.
// You can set `amount` to any positive value, or pass a large number
// (e.g., 999999.0) to move everything available.

transaction(amount: UFix64) {
    prepare(signer: auth(Storage, BorrowValue) &Account) {
        // Borrow the Jukebox Treasury vault
        let fromVault = signer.storage.borrow<
            auth(FungibleToken.Withdraw) &FlowToken.Vault
        >(from: /storage/FlowJukeBoxTreasury)
            ?? panic("❌ Missing /storage/FlowJukeBoxTreasury vault")

        // Borrow the normal FlowToken vault
        let toVault = signer.storage.borrow<&FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("❌ Missing /storage/flowTokenVault")

        // If amount exceeds balance, send entire vault
        let moveAmount = amount
        if moveAmount > fromVault.balance {
            log("⚠️ Requested amount exceeds balance, moving entire vault")
        }

        // Withdraw and deposit
        let withdrawn <- fromVault.withdraw(
            amount: moveAmount > fromVault.balance ? fromVault.balance : moveAmount
        )
        toVault.deposit(from: <- withdrawn)
    }

    execute {
        log("✅ Moved Flow from /storage/FlowJukeBoxTreasury to /storage/flowTokenVault")
    }
}
