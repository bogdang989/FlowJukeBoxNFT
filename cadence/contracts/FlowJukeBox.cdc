import "NonFungibleToken"
import "FungibleToken"
import "FlowToken"
import "ViewResolver"
import "MetadataViews"

// Scheduled transactions
import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"


// ///////////////TESTNET IMPORTS/////////////////////
// import NonFungibleToken from 0x631e88ae7f1d7c20
// import FungibleToken from 0x9a0766d93b6608b7
// import FlowToken from 0x7e60df042a9c0868
// import ViewResolver from 0x631e88ae7f1d7c20
// import MetadataViews from 0x631e88ae7f1d7c20

// // Scheduled transactions
// import FlowTransactionScheduler from 0x8c5303eaa26202d6
// import FlowTransactionSchedulerUtils from 0x8c5303eaa26202d6
/////////////////////////////////////////////////

access(all) contract FlowJukeBox: NonFungibleToken {

    //
    // ────────────────────────────────────────────────
    // Core Paths & Config
    // ────────────────────────────────────────────────
    //
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let AdminStoragePath: StoragePath
    access(all) let HandlerStoragePath: StoragePath
    access(all) let HandlerPublicPath: PublicPath
    access(all) let contractAddress: Address

    access(all) var payoutPercentage: UFix64
    access(all) let defaultTrack: {String: AnyStruct}
    access(all) var totalSupply: UInt64

    //
    // ────────────────────────────────────────────────
    // Events
    // ────────────────────────────────────────────────
    //
    access(all) event AutoPlayScheduled(
        nftId: UInt64,
        scheduledTxId: UInt64,
        executeAt: UFix64,
        nextTrack: String,
        duration: UFix64,
        fee: UFix64
    )

    //
    // ────────────────────────────────────────────────
    // NowPlaying Struct
    // ────────────────────────────────────────────────
    //
    access(all) struct NowPlaying {
        access(all) let value: String
        access(all) let displayName: String
        access(all) let duration: UFix64
        access(all) let startTime: UFix64
        access(all) let isDefault: Bool

        init(value: String, displayName: String, duration: UFix64, startTime: UFix64, isDefault: Bool) {
            self.value = value
            self.displayName = displayName
            self.duration = duration
            self.startTime = startTime
            self.isDefault = isDefault
        }
    }

    //
    // ────────────────────────────────────────────────
    // Queue Entry
    // ────────────────────────────────────────────────
    //
    access(all) struct QueueEntry {
        access(all) let value: String
        access(all) let displayName: String
        access(all) var totalBacking: UFix64
        access(all) var latestBacking: UFix64
        access(all) let duration: UFix64

        init(value: String, displayName: String, totalBacking: UFix64, latestBacking: UFix64, duration: UFix64) {
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

    //
    // ────────────────────────────────────────────────
    // NFT Resource
    // ────────────────────────────────────────────────
    //
    access(all) resource NFT: NonFungibleToken.NFT, ViewResolver.Resolver {
        access(all) let id: UInt64
        access(all) let sessionOwner: Address
        access(all) let queueIdentifier: String
        access(all) let queueDuration: UFix64
        access(all) let createdAt: UFix64
        access(all) var queueEntries: [QueueEntry]
        access(all) var totalDuration: UFix64
        access(all) var totalBacking: UFix64
        access(all) var nowPlaying: FlowJukeBox.NowPlaying?
        access(contract) var hasBeenPaidOut: Bool

        init(id: UInt64, sessionOwner: Address, queueIdentifier: String, queueDuration: UFix64) {
            self.id = id
            self.sessionOwner = sessionOwner
            self.queueIdentifier = queueIdentifier
            self.queueDuration = queueDuration
            self.createdAt = getCurrentBlock().timestamp
            self.queueEntries = []
            self.totalDuration = 0.0
            self.totalBacking = 0.0
            self.nowPlaying = nil
            self.hasBeenPaidOut = false
        }

        access(contract) fun markAsPaid() { self.hasBeenPaidOut = true }

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

        access(all) fun playNext(): {String: AnyStruct} {
            let now = getCurrentBlock().timestamp

            if self.queueEntries.length == 0 {
                let def = FlowJukeBox.NowPlaying(
                    value: FlowJukeBox.defaultTrack["value"] as! String,
                    displayName: FlowJukeBox.defaultTrack["displayName"] as! String,
                    duration: FlowJukeBox.defaultTrack["duration"] as! UFix64,
                    startTime: now,
                    isDefault: true
                )
                self.nowPlaying = def
                return {
                    "value": def.value,
                    "displayName": def.displayName,
                    "duration": def.duration,
                    "startTime": def.startTime,
                    "isDefault": def.isDefault
                }
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
            let np = FlowJukeBox.NowPlaying(
                value: next.value,
                displayName: next.displayName,
                duration: next.duration,
                startTime: now,
                isDefault: false
            )
            self.nowPlaying = np
            log("▶️ Now playing: ".concat(np.displayName))

            return {
                "value": np.value,
                "displayName": np.displayName,
                "duration": np.duration,
                "startTime": np.startTime,
                "isDefault": np.isDefault
            }
        }

        // required by NonFungibleToken.NFT
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
                default:
                    return nil
            }
        }
    }

    //
    // ────────────────────────────────────────────────
    // Collection Resource
    // ────────────────────────────────────────────────
    //
    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}
        init() { self.ownedNFTs <- {} }

        access(all) view fun getIDs(): [UInt64] { return self.ownedNFTs.keys }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            let m: {Type: Bool} = {}
            m[Type<@FlowJukeBox.NFT>()] = true
            return m
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@FlowJukeBox.NFT>()
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        access(all) fun borrowJukeboxNFT(_ id: UInt64): &FlowJukeBox.NFT? {
            let any = &self.ownedNFTs[id] as &{NonFungibleToken.NFT}?
            if any == nil { return nil }
            return any as! &FlowJukeBox.NFT
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

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- FlowJukeBox.createEmptyCollection(nftType: Type<@FlowJukeBox.NFT>())
        }

        access(contract) fun removeAndDestroy(id: UInt64) {
            let tok <- self.ownedNFTs.remove(key: id) ?? panic("NFT not found for burn")
            destroy tok
        }
    }

    // -------------------------
    // Public depositBacking (add FLOW and track to queue)
    // -------------------------
    access(all) fun depositBacking(
        nftID: UInt64,
        from: Address,
        value: String,
        displayName: String,
        duration: UFix64,
        payment: @{FungibleToken.Vault}
    ) {
        // Deposit incoming FLOW to the contract vault
        let receiver = self.account.capabilities.borrow<&{FungibleToken.Receiver}>(
            /public/flowTokenReceiver
        ) ?? panic("FlowToken receiver not found")

        let amount = payment.balance
        receiver.deposit(from: <- payment)

        // Borrow collection and target NFT
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

    //
    // ────────────────────────────────────────────────
    // Scheduled Transaction Handler
    // ────────────────────────────────────────────────
    //
    access(all) resource PlayHandler: FlowTransactionScheduler.TransactionHandler {
        access(FlowTransactionScheduler.Execute)
        fun executeTransaction(id: UInt64, data: AnyStruct?) {
            let nftId = data as! UInt64
            log("🎬 AutoPlay executing for NFT ".concat(nftId.toString()))
            FlowJukeBox.playNextOrPayout(nftID: nftId)
        }
    }

    access(all) fun createPlayHandler(): @PlayHandler { return <- create PlayHandler() }
    // -------------------------
    // Public Mint (Create a new Jukebox Session NFT)
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

        let col = FlowJukeBox.account.storage.borrow<&FlowJukeBox.Collection>(
            from: FlowJukeBox.CollectionStoragePath
        ) ?? panic("Contract collection not found")

        col.deposit(token: <- nft)
        log("✅ Public mint: FlowJukeBox #".concat(id.toString()))
    }
    //
    // ────────────────────────────────────────────────
    // Scheduler helper
    // ────────────────────────────────────────────────
    //
    access(all) fun scheduleNextPlay(nftId: UInt64, delay: UFix64, feeAmount: UFix64) {
        if !FlowJukeBox.account.storage.check<@{FlowTransactionSchedulerUtils.Manager}>(
            from: FlowTransactionSchedulerUtils.managerStoragePath
        ) {
            let mgr <- FlowTransactionSchedulerUtils.createManager()
            FlowJukeBox.account.storage.save(<- mgr, to: FlowTransactionSchedulerUtils.managerStoragePath)
            let cap = FlowJukeBox.account.capabilities.storage.issue<&{FlowTransactionSchedulerUtils.Manager}>(
                FlowTransactionSchedulerUtils.managerStoragePath
            )
            FlowJukeBox.account.capabilities.publish(cap, at: FlowTransactionSchedulerUtils.managerPublicPath)
        }

        if !FlowJukeBox.account.storage.check<@FlowJukeBox.PlayHandler>(
            from: FlowJukeBox.HandlerStoragePath
        ) {
            let h <- FlowJukeBox.createPlayHandler()
            FlowJukeBox.account.storage.save(<- h, to: FlowJukeBox.HandlerStoragePath)
        }

        let execHandlerCap = FlowJukeBox.account.capabilities.storage.issue<
            auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}
        >(FlowJukeBox.HandlerStoragePath)

        let now = getCurrentBlock().timestamp
        let executeAt = now + delay

        let vault = FlowJukeBox.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Flow vault missing for scheduler fees")
        let fees <- vault.withdraw(amount: feeAmount) as! @FlowToken.Vault

        let manager = FlowJukeBox.account.storage.borrow<
            auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}
        >(from: FlowTransactionSchedulerUtils.managerStoragePath)
            ?? panic("Manager not found")

        let scheduledId = manager.schedule(
            handlerCap: execHandlerCap,
            data: nftId,
            timestamp: executeAt,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <- fees
        )

        let col = FlowJukeBox.account.storage.borrow<&FlowJukeBox.Collection>(
            from: FlowJukeBox.CollectionStoragePath
        ) ?? panic("Collection not found")
        let nft = col.borrowJukeboxNFT(nftId) ?? panic("NFT not found")
        let np = nft.nowPlaying

        emit AutoPlayScheduled(
            nftId: nftId,
            scheduledTxId: scheduledId,
            executeAt: executeAt,
            nextTrack: np?.displayName ?? "unknown",
            duration: np?.duration ?? 0.0,
            fee: feeAmount
        )
    }

    //
    // ────────────────────────────────────────────────
    // Public logic (autoplay + payout)
    // ────────────────────────────────────────────────
    //
    access(all) fun playNextOrPayout(nftID: UInt64): {String: AnyStruct}? {
        let col = self.account.storage.borrow<&FlowJukeBox.Collection>(
            from: self.CollectionStoragePath
        ) ?? panic("Collection not found")

        let nftRef = col.borrowJukeboxNFT(nftID)
            ?? panic("NFT not found")

        let now = getCurrentBlock().timestamp
        let expiresAt = nftRef.createdAt + nftRef.queueDuration

        if now > expiresAt {
            self._payoutAndBurn(nftID: nftID)
            return nil
        }

        let info = nftRef.playNext()
        let duration = info["duration"] as! UFix64
        let fee: UFix64 = 0.01
        self.scheduleNextPlay(nftId: nftID, delay: duration, feeAmount: fee)
        return info
    }

    access(contract) fun _payoutAndBurn(nftID: UInt64) {
        let col = self.account.storage.borrow<&FlowJukeBox.Collection>(
            from: self.CollectionStoragePath
        ) ?? panic("Collection not found")
        let nftRef = col.borrowJukeboxNFT(nftID)
            ?? panic("NFT not found")

        let owner: Address = nftRef.sessionOwner
        let amountToPay: UFix64 = nftRef.totalBacking * self.payoutPercentage

        if !nftRef.hasBeenPaidOut && amountToPay > 0.0 {
            let vaultRef = self.account.storage.borrow<
                auth(FungibleToken.Withdraw) &FlowToken.Vault
            >(from: /storage/flowTokenVault)
                ?? panic("Flow vault not found")
            let vault <- vaultRef.withdraw(amount: amountToPay)
            let receiverCap = getAccount(owner)
                .capabilities
                .borrow<&{FungibleToken.Receiver}>(/public/flowTokenReceiver)
                ?? panic("Receiver cap not found")
            receiverCap.deposit(from: <- vault)
            nftRef.markAsPaid()
        }

        col.removeAndDestroy(id: nftID)
        log("💸 Paid ".concat(amountToPay.toString())
            .concat(" FLOW to ").concat(owner.toString())
            .concat(" and burned NFT #").concat(nftID.toString()))
    }

    //
    // ────────────────────────────────────────────────
    // Interface compliance (NFT contract)
    // ────────────────────────────────────────────────
    //
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
                    name: "Flow Jukebox Sessions",
                    description: "Each NFT represents a live jukebox session queue.",
                    externalURL: MetadataViews.ExternalURL("https://mvponflow.cc/"),
                    squareImage: media,
                    bannerImage: media,
                    socials: {}
                )
            default:
                return nil
        }
    }

    //
    // ────────────────────────────────────────────────
    // Init
    // ────────────────────────────────────────────────
    //
    init() {
        self.CollectionStoragePath = /storage/FlowJukeBoxCollection
        self.CollectionPublicPath  = /public/FlowJukeBoxCollection
        self.AdminStoragePath      = /storage/FlowJukeBoxAdmin
        self.HandlerStoragePath    = /storage/FlowJukeBoxPlayHandler
        self.HandlerPublicPath     = /public/FlowJukeBoxPlayHandler
        self.contractAddress       = self.account.address
        self.totalSupply = 0
        self.payoutPercentage = 0.80

        self.defaultTrack = {
            "value": "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
            "displayName": "Default Track",
            "duration": 180.0
        }

        let col <- create FlowJukeBox.Collection()
        self.account.storage.save(<- col, to: self.CollectionStoragePath)
        let cap = self.account.capabilities.storage.issue<&FlowJukeBox.Collection>(self.CollectionStoragePath)
        self.account.capabilities.publish(cap, at: self.CollectionPublicPath)

        log("✅ FlowJukeBox deployed successfully with automatic scheduling.")
    }
}
