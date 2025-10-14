import "FlowJukeBox"

/// Pays out 80% (or current payoutPercentage) of accumulated FLOW to the NFT owner.
transaction(nftID: UInt64) {
    prepare(signer: auth(BorrowValue) &Account) {
        FlowJukeBox.payout(nftID: nftID)
    }

    execute {
        log("✅ Payout executed for Jukebox #".concat(nftID.toString()))
    }
}
