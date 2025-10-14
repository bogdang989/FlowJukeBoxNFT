import "FlowJukeBox"

access(all) fun main(): [{String: AnyStruct}] {
    let col = getAccount(FlowJukeBox.contractAddress)
        .capabilities
        .borrow<&FlowJukeBox.Collection>(FlowJukeBox.CollectionPublicPath)
        ?? panic("Public collection not found")

    let ids = col.getIDs()
    var out: [{String: AnyStruct}] = []

    var i = 0
    while i < ids.length {
        let id = ids[i]
        let nft = col.borrowJukeboxNFT(id)!
        out.append({
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
    return out
}
