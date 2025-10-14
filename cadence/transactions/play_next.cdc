import "FlowJukeBox"

transaction(nftID: UInt64) {
    prepare(signer: auth(BorrowValue) &Account) {
        let collectionRef = signer.storage.borrow<&FlowJukeBox.Collection>(
            from: /storage/FlowJukeBoxCollection
        ) ?? panic("FlowJukeBox.Collection not found in signer storage")

        let nftRef = collectionRef.borrowJukeboxNFT(nftID)
            ?? panic("No FlowJukeBox NFT with that ID found")

        let result = nftRef.playNext()
        log(result)
    }

    execute {
        log("✅ playNext executed for NFT ".concat(nftID.toString()))
    }
}
