import "FlowJukeBox"

access(all) fun main(): [{String: AnyStruct}] {
    // Borrow the contract’s public collection
    let collection = getAccount(FlowJukeBox.contractAddress)
        .capabilities
        .borrow<&FlowJukeBox.Collection>(FlowJukeBox.CollectionPublicPath)
        ?? panic("Public FlowJukeBox.Collection not found")

    let ids = collection.getIDs()
    let result: [{String: AnyStruct}] = []

    var i = 0
    while i < ids.length {
        let id = ids[i]
        let nft = collection.borrowJukeboxNFT(id)
            ?? panic("NFT reference missing")

        result.append({
            "id": id,
            "queueIdentifier": nft.queueIdentifier,
            "sessionOwner": nft.sessionOwner,
            "queueDuration": nft.queueDuration,
            "totalBacking": nft.totalBacking,
            "totalDuration": nft.totalDuration,
            "nowPlaying": nft.nowPlaying
        })
        i = i + 1
    }

    return result
}
