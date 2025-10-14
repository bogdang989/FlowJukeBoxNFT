import "FlowJukeBox"

access(all) fun main(owner: Address, id: UInt64): [{String: AnyStruct}] {
  let col = getAccount(owner)
    .capabilities
    .borrow<&FlowJukeBox.Collection>(FlowJukeBox.CollectionPublicPath)
    ?? panic("Public FlowJukeBox collection not found")

  let any = col.borrowNFT(id) ?? panic("Jukebox session not found")
  let nft = any as! &FlowJukeBox.NFT

  let out: [{String: AnyStruct}] = []
  var i = 0
  while i < nft.queueEntries.length {
    let e = nft.queueEntries[i]
    out.append({
      "value": e.value,
      "totalBacking": e.totalBacking,
      "latestBacking": e.latestBacking,
      "duration": e.duration
    })
    i = i + 1
  }
  return out
}
