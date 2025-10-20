import "FlowToken"
import "FlowJukeBox"
import "FlowJukeBoxTransactionHandler"

// This transaction starts the autoplay cycle for a jukebox NFT by:
// 1. Playing the first song
// 2. Scheduling the next play after the song duration
transaction(nftID: UInt64) {
    let jukeboxAddr: Address

    prepare(acct: auth(Storage, BorrowValue) &Account) {
        // Ensure we have a Flow vault for scheduling fees
        if !acct.storage.check<@FlowToken.Vault>(from: /storage/flowTokenVault) {
            let vault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            acct.storage.save<@FlowToken.Vault>(<- vault, to: /storage/flowTokenVault)
        }

        // Store jukebox contract address
        self.jukeboxAddr = getAccount(FlowJukeBox.contractAddress).address
    }

    execute {
        // First play the next song and get its duration
        let songInfo = FlowJukeBox.playNextOrPayout(nftID: nftID) 
            ?? panic("Session has ended or NFT does not exist")

        let duration = songInfo["duration"] as! UFix64
        
        // Schedule the next play after current song ends
        FlowJukeBoxTransactionHandler.scheduleNextPlay(
            nftId: nftID,
            delay: duration,
            feeAmount: 0.1 // Minimal fee for scheduling
        )
     }
}