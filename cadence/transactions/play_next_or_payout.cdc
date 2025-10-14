import "FlowJukeBox"

transaction(nftID: UInt64) {
    prepare(signer: auth(BorrowValue) &Account) {
        // You don't need to borrow the NFT here anymore
        // playNextOrPayout is a CONTRACT function, not a resource method
    }

    execute {
        let result = FlowJukeBox.playNextOrPayout(nftID: nftID)

        if result == nil {
            log("⏰ Expired: payout + burn executed for NFT #".concat(nftID.toString()))
        } else {
            let data = result!
            log("▶️ Now playing ".concat(data["displayName"] as! String))
        }
    }
}
