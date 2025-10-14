import "NonFungibleToken"
import "FungibleToken"
import "FlowToken"
import "ViewResolver"
import "MetadataViews"

access(all) contract FlowJukeBox: NonFungibleToken {

    // -------------------------
    // Standard Paths & Metadata
    // -------------------------
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    access(all) let contractAddress: Address

    // Payout % (tunable later)
    access(all) var payoutPercentage: UFix64

    // -------------------------
    // Queue Entry
    // -------------------------
    access(all) struct QueueEntry {
        access(all) let value: String
        access(all) let displayName: String
        access(all) var totalBacking: UFix64
        access(all) var latestBacking: UFix64
        access(all) let duration: UFix64

        init(
            value: String,
            displayName: String,
            totalBacking: UFix64,
            latestBacking: UFix64,
            duration: UFix64
        ) {
            self.value = value
            self.displayName = displayName
            self.totalBacking = totalBacking
            self.latestBacking = latestBacking
            self.duration = duration
        }

        access(contract) fun updateBacking(extraBacking: UFix64, newTimestamp: UFix64) {
            self.totalBacking = self.totalBacking + extraBacking
            self.latestBacking = newTimestamp
        }
    }

    // -------------------------
    // NFT Resource
    // -------------------------
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        access(all) let id: UInt64
        access(all) let sessionOwner: Address
        access(all) let queueIdentifier: String
        access(all) let queueDuration: UFix64

        access(all) var queueEntries: [QueueEntry]
        access(all) var totalDuration: UFix64
        access(all) var totalBacking: UFix64
        access(all) var nowPlaying: String
        access(contract) var hasBeenPaidOut: Bool

        init(
            id: UInt64,
            sessionOwner: Address,
            queueIdentifier: String,
            queueDuration: UFix64
        ) {
            self.id = id
            self.sessionOwner = sessionOwner
            self.queueIdentifier = queueIdentifier
            self.queueDuration = queueDuration
            self.queueEntries = []
            self.totalDuration = 0.0
            self.totalBacking = 0.0
            self.nowPlaying = ""
            self.hasBeenPaidOut = false
        }

        access(contract) fun markAsPaid() {
            self.hasBeenPaidOut = true
        }

        // Internal entry logic
        access(contract) fun _addEntryInternal(
            value: String,
            displayName: String,
            backing: UFix64,
            duration: UFix64,
            timestamp: UFix64
        ) {
            var found = false
            var i = 0
            while i < self.queueEntries.length {
                if self.queueEntries[i].value == value {
                    self.queueEntries[i].updateBacking(extraBacking: backing, newTimestamp: timestamp)
                    found = true
                    break
                }
                i = i + 1
            }

            if !found {
                let newEntry = QueueEntry(
                    value: value,
                    displayName: displayName,
                    totalBacking: backing,
                    latestBacking: timestamp,
                    duration: duration
                )
                self.queueEntries.append(newEntry)
            }

            self.totalBacking = self.totalBacking + backing
            self.totalDuration = self.totalDuration + duration
        }

        // Play next entry
        access(all) fun playNext(): {String: AnyStruct} {
            if self.queueEntries.length == 0 {
                panic("Queue empty.")
            }

            var topIndex = 0
            var i = 1
            while i < self.queueEntries.length {
                let cur = self.queueEntries[i]
                let top = self.queueEntries[topIndex]
                if cur.totalBacking > top.totalBacking ||
                   (cur.totalBacking == top.totalBacking && cur.latestBacking < top.latestBacking) {
                    topIndex = i
                }
                i = i + 1
            }

            let next = self.queueEntries.remove(at: topIndex)
            self.nowPlaying = next.displayName
            return { "value": next.value, "displayName": next.displayName, "duration": next.duration }
        }

        // Metadata Views
        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FlowJukeBox.createEmptyCollection(nftType: Type<@FlowJukeBox.NFT>())
        }

        access(all) view fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<MetadataViews.NFTCollectionData>(),
                Type<MetadataViews.NFTCollectionDisplay>()
            ]
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    let desc = "Flow Jukebox ".concat(self.queueIdentifier)
                    return MetadataViews.Display(
                        name: "🎵 Jukebox Session",
                        description: desc,
                        thumbnail: MetadataViews.HTTPFile(url: "https://mvponflow.cc/favicon.png")
                    )
                case Type<MetadataViews.NFTCollectionData>():
                    return FlowJukeBox.resolveContractView(
                        resourceType: Type<@FlowJukeBox.NFT>(),
                        viewType: Type<MetadataViews.NFTCollectionData>()
                    )
                case Type<MetadataViews.NFTCollectionDisplay>():
                    return FlowJukeBox.resolveContractView(
                        resourceType: Type<@FlowJukeBox.NFT>(),
                        viewType: Type<MetadataViews.NFTCollectionDisplay>()
                    )
            }
            return nil
        }
    }

    // -------------------------
    // Collection
    // -------------------------
    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        init() { self.ownedNFTs <- {} }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FlowJukeBox.createEmptyCollection(nftType: Type<@FlowJukeBox.NFT>())
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let m: {Type: Bool} = {}
            m[Type<@FlowJukeBox.NFT>()] = true
            return m
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@FlowJukeBox.NFT>()
        }

        access(NonFungibleToken.Withdraw)
        fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let t <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Missing NFT ID ".concat(withdrawID.toString()))
            return <- t
        }

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let c <- token as! @FlowJukeBox.NFT
            let old <- self.ownedNFTs[c.id] <- c
            destroy old
        }

        access(all) view fun getIDs(): [UInt64] { return self.ownedNFTs.keys }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        access(all) fun borrowJukeboxNFT(_ id: UInt64): &FlowJukeBox.NFT? {
            let any = self.borrowNFT(id)
            if any == nil { return nil }
            return any as! &FlowJukeBox.NFT
        }
    }

    // -------------------------
    // Public Mint
    // -------------------------
    access(all) fun createJukeboxSession(
        sessionOwner: Address,
        queueIdentifier: String,
        queueDuration: UFix64
    ) {
        let id = FlowJukeBox.totalSupply + 1
        FlowJukeBox.totalSupply = id

        let nft <- create FlowJukeBox.NFT(
            id: id,
            sessionOwner: sessionOwner,
            queueIdentifier: queueIdentifier,
            queueDuration: queueDuration
        )

        let col = self.account.storage.borrow<&FlowJukeBox.Collection>(
            from: self.CollectionStoragePath
        ) ?? panic("Contract collection not found")

        col.deposit(token: <- nft)
        log("✅ Public mint: FlowJukeBox #".concat(id.toString()))
    }

    // -------------------------
    // Public depositBacking
    // -------------------------
    access(all) fun depositBacking(
        nftID: UInt64,
        from: Address,
        value: String,
        displayName: String,
        duration: UFix64,
        payment: @{FungibleToken.Vault}
    ) {
        let receiver = self.account.capabilities.borrow<&{FungibleToken.Receiver}>(
            /public/flowTokenReceiver
        ) ?? panic("FlowToken receiver not found")

        let amount = payment.balance
        receiver.deposit(from: <- payment)

        let collectionRef = self.account.storage.borrow<&FlowJukeBox.Collection>(
            from: self.CollectionStoragePath
        ) ?? panic("FlowJukeBox.Collection not found")

        let nftRef = collectionRef.borrowJukeboxNFT(nftID)
            ?? panic("NFT not found")

        let now = getCurrentBlock().timestamp
        nftRef._addEntryInternal(
            value: value,
            displayName: displayName,
            backing: amount,
            duration: duration,
            timestamp: now
        )

        log("💰 ".concat(amount.toString()).concat(" FLOW added to #").concat(nftID.toString()))
    }

    // -------------------------
    // Payout Function
    // -------------------------
    access(all) fun payout(nftID: UInt64) {
        let col = self.account.storage.borrow<&FlowJukeBox.Collection>(
            from: self.CollectionStoragePath
        ) ?? panic("FlowJukeBox.Collection not found")

        let nftRef = col.borrowJukeboxNFT(nftID)
            ?? panic("NFT not found")

        if nftRef.hasBeenPaidOut {
            panic("This NFT has already been paid out")
        }

        let amountToPay = nftRef.totalBacking * self.payoutPercentage

        let vaultRef = self.account.storage.borrow<
            auth(FungibleToken.Withdraw) &FlowToken.Vault
        >(from: /storage/flowTokenVault)
            ?? panic("FlowToken vault not found in contract storage")

        let vault <- vaultRef.withdraw(amount: amountToPay)

        let receiverCap = getAccount(nftRef.sessionOwner)
            .capabilities
            .borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
            ?? panic("Receiver capability not found")

        receiverCap.deposit(from: <- vault)

        nftRef.markAsPaid()

        log("💸 Paid out ".concat(amountToPay.toString()).concat(" FLOW to ").concat(nftRef.sessionOwner.toString()))
    }

    // -------------------------
    // Views & Init
    // -------------------------
    access(all) var totalSupply: UInt64

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create FlowJukeBox.Collection()
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return [Type<MetadataViews.NFTCollectionData>(), Type<MetadataViews.NFTCollectionDisplay>()]
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        switch viewType {
            case Type<MetadataViews.NFTCollectionData>():
                return MetadataViews.NFTCollectionData(
                    storagePath: self.CollectionStoragePath,
                    publicPath: self.CollectionPublicPath,
                    publicCollection: Type<&FlowJukeBox.Collection>(),
                    publicLinkedType: Type<&FlowJukeBox.Collection>(),
                    createEmptyCollectionFunction: (fun(): @{NonFungibleToken.Collection} {
                        return <- FlowJukeBox.createEmptyCollection(nftType: Type<@FlowJukeBox.NFT>())
                    })
                )
            case Type<MetadataViews.NFTCollectionDisplay>():
                let media = MetadataViews.Media(
                    file: MetadataViews.HTTPFile(url: "https://mvponflow.cc/favicon.png"),
                    mediaType: "image/png"
                )
                return MetadataViews.NFTCollectionDisplay(
                    name: "Flow JukeBox Sessions",
                    description: "Each NFT represents a live jukebox session queue.",
                    externalURL: MetadataViews.ExternalURL("https://mvponflow.cc/"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {}
                )
        }
        return nil
    }

    init() {
        self.CollectionStoragePath = /storage/FlowJukeBoxCollection
        self.CollectionPublicPath  = /public/FlowJukeBoxCollection
        self.AdminStoragePath      = /storage/FlowJukeBoxAdmin
        self.contractAddress       = self.account.address
        self.totalSupply = 0
        self.payoutPercentage = 0.80

        let col <- create FlowJukeBox.Collection()
        self.account.storage.save(<- col, to: self.CollectionStoragePath)

        let colCap = self.account.capabilities.storage.issue<&FlowJukeBox.Collection>(self.CollectionStoragePath)
        self.account.capabilities.publish(colCap, at: self.CollectionPublicPath)

        log("✅ FlowJukeBox deployed successfully.")
    }
}
