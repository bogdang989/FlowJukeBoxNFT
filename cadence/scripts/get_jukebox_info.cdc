import "FlowJukeBox"

access(all) fun main(nftID: UInt64): {String: AnyStruct} {
    let col = getAccount(FlowJukeBox.contractAddress)
        .capabilities
        .borrow<&FlowJukeBox.Collection>(FlowJukeBox.CollectionPublicPath)
        ?? panic("Public collection not found")

    let nft = col.borrowJukeboxNFT(nftID)
        ?? panic("NFT not found")

    var entries: [{String: AnyStruct}] = []
    var i = 0
    while i < nft.queueEntries.length {
        let e = nft.queueEntries[i]
        entries.append({
            "value": e.value,
            "displayName": e.displayName,
            "duration": e.duration,
            "totalBacking": e.totalBacking,
            "latestBacking": e.latestBacking
        })
        i = i + 1
    }

    return {
        "id": nft.id,
        "queueIdentifier": nft.queueIdentifier,
        "sessionOwner": nft.sessionOwner,
        "queueDuration": nft.queueDuration,
        "totalBacking": nft.totalBacking,
        "totalDuration": nft.totalDuration,
        "nowPlaying": nft.nowPlaying,
        "entries": entries
    }
}
