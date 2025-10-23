import "FlowJukeBox"

transaction(nftID: UInt64) {
  prepare(signer: auth(BorrowValue) &Account) {
    // signer is not used; burn happens in the contract's storage
  }

  execute {
    FlowJukeBox.burnNFT(id: nftID)
  }
}
