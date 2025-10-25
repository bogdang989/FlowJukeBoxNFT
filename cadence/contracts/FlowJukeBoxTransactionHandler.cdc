import "FungibleToken"
import "FlowToken"
import "FlowTransactionScheduler"
import "FlowTransactionSchedulerUtils"
import "FlowJukeBox"

///////////////TESTNET IMPORTS/////////////////////
// import NonFungibleToken from 0x631e88ae7f1d7c20
// import FungibleToken from 0x9a0766d93b6608b7
// import FlowToken from 0x7e60df042a9c0868
// import ViewResolver from 0x631e88ae7f1d7c20
// import MetadataViews from 0x631e88ae7f1d7c20
// import FlowJukeBox from 0x34c91b1135c00528

// // Scheduled transactions
// import FlowTransactionScheduler from 0x8c5303eaa26202d6
// import FlowTransactionSchedulerUtils from 0x8c5303eaa26202d6

access(all) contract FlowJukeBoxTransactionHandler {
    // Reference to FlowJukeBox contract
    access(all) let jukeboxAddress: Address
    access(all) let jukeboxCollectionPath: PublicPath

    // Core Paths
    access(all) let HandlerStoragePath: StoragePath
    access(all) let HandlerPublicPath: PublicPath
    access(all) let ManagerStoragePath: StoragePath
    access(all) let ManagerPublicPath: PublicPath

    // Events
    access(all) event AutoPlayScheduled(
        nftId: UInt64,
        scheduledTxId: UInt64,
        executeAt: UFix64,
        nextTrack: String,
        duration: UFix64,
        fee: UFix64
    )

    // Transaction Handler Resource
    access(all) resource PlayHandler: FlowTransactionScheduler.TransactionHandler {
        access(FlowTransactionScheduler.Execute) var lastExecutionTime: UFix64?
        access(all) let contractAddress: Address

        access(FlowTransactionScheduler.Execute)
        fun executeTransaction(id: UInt64, data: AnyStruct?) {
            let nftId = data as! UInt64
            self.lastExecutionTime = getCurrentBlock().timestamp

            // Get reference to jukebox contract
            let account = getAccount(FlowJukeBoxTransactionHandler.jukeboxAddress)
            let capability = account.capabilities
                .borrow<&FlowJukeBox.Collection>(
                    FlowJukeBoxTransactionHandler.jukeboxCollectionPath
                ) ?? panic("Could not borrow jukebox collection")

            // Play next song and get duration
            let nft = capability.borrowJukeboxNFT(nftId)
                ?? panic("Could not borrow NFT")

            let songInfoOpt = nft.playNextOrPayout()
            if let songInfo = songInfoOpt {
                let duration = songInfo["duration"] as! UFix64

                FlowJukeBoxTransactionHandler.scheduleNextPlay(
                    nftId: nftId,
                    delay: duration,
                    feeAmount: 0.1
                )
            } else {
                log("ℹ️ Jukebox expired — payout handled, nothing to schedule.")
            }
        }

        init(contractAddress: Address) {
            self.lastExecutionTime = nil
            self.contractAddress = contractAddress
        }
    }

    access(all) fun createPlayHandler(): @PlayHandler {
        return <- create PlayHandler(contractAddress: self.jukeboxAddress)
    }

    // Scheduler Functions
    access(all) fun scheduleNextPlay(nftId: UInt64, delay: UFix64, feeAmount: UFix64) {
        self.ensureHandlerAndManager()

        let execHandlerCap = self.account.capabilities.storage.issue<
            auth(FlowTransactionScheduler.Execute) &{FlowTransactionScheduler.TransactionHandler}
        >(self.HandlerStoragePath)

        let now = getCurrentBlock().timestamp
        let executeAt = now + delay

        let vault = self.account.storage.borrow<auth(FungibleToken.Withdraw) &FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Flow vault missing for scheduler fees")
        let fees <- vault.withdraw(amount: feeAmount) as! @FlowToken.Vault

        let manager = self.account.storage.borrow<
            auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}
        >(from: self.ManagerStoragePath)
            ?? panic("Manager not found")

        let scheduledId = manager.schedule(
            handlerCap: execHandlerCap,
            data: nftId,
            timestamp: executeAt,
            priority: FlowTransactionScheduler.Priority.Medium,
            executionEffort: 1000,
            fees: <- fees
        )

        // Verify NFT exists
        let account = getAccount(self.jukeboxAddress)
        let capability = account.capabilities.borrow<&FlowJukeBox.Collection>(
            self.jukeboxCollectionPath
        ) ?? panic("Could not borrow jukebox collection")

        let _ = capability.borrowJukeboxNFT(nftId) ?? panic("NFT not found")

        emit AutoPlayScheduled(
            nftId: nftId,
            scheduledTxId: scheduledId,
            executeAt: executeAt,
            nextTrack: "Scheduled for playback",
            duration: 0.0,
            fee: feeAmount
        )
    }

    // Internal Functions
    access(contract) fun ensureHandlerAndManager() {
        if !self.account.storage.check<@{FlowTransactionSchedulerUtils.Manager}>(
            from: self.ManagerStoragePath
        ) {
            let mgr <- FlowTransactionSchedulerUtils.createManager()
            self.account.storage.save(<- mgr, to: self.ManagerStoragePath)
            let cap = self.account.capabilities.storage.issue<&{FlowTransactionSchedulerUtils.Manager}>(
                self.ManagerStoragePath
            )
            self.account.capabilities.publish(cap, at: self.ManagerPublicPath)
        }

        if !self.account.storage.check<@FlowJukeBoxTransactionHandler.PlayHandler>(
            from: self.HandlerStoragePath
        ) {
            let h <- self.createPlayHandler()
            self.account.storage.save(<- h, to: self.HandlerStoragePath)
        }
    }

    // ────────────────────────────────────────────────
    // Monitoring & Maintenance (FIXED)
    // ────────────────────────────────────────────────
    //
    // Use the manager's time index to fetch IDs scheduled before `before`,
    // cancel only those still `Scheduled`, and refund fees.
    //
    access(contract) fun cleanupOldTransactions(before: UFix64) {
        let manager = self.account.storage.borrow<
            auth(FlowTransactionSchedulerUtils.Owner) &{FlowTransactionSchedulerUtils.Manager}
        >(from: self.ManagerStoragePath)
            ?? panic("Manager not found")

        let treasury = self.account.storage.borrow<&FlowToken.Vault>(
            from: /storage/flowTokenVault
        ) ?? panic("Flow vault missing")

        // All tx IDs with scheduled timestamp <= `before`
        let oldIds = manager.getTransactionIDsByTimestamp(before)

        for id in oldIds {
            let status = manager.getTransactionStatus(id: id)
            if status == FlowTransactionScheduler.Status.Scheduled {
                let refund <- manager.cancel(id: id)
                treasury.deposit(from: <- refund)
                log("🧹 Canceled & refunded scheduled tx ".concat(id.toString()))
            }
        }
    }

    access(all) fun getSchedulerHealth(): {String: AnyStruct} {
        let manager = self.account.storage.borrow<
            &{FlowTransactionSchedulerUtils.Manager}
        >(from: self.ManagerStoragePath)
            ?? panic("Manager not found")

        let handler = self.account.storage.borrow<
            auth(FlowTransactionScheduler.Execute) &PlayHandler
        >(from: self.HandlerStoragePath)
            ?? panic("Handler not found")

        let now = getCurrentBlock().timestamp
        return {
            "activeTransactions": manager.getTransactionIDs().length,
            "lastExecutionTime": handler.lastExecutionTime,
            "scheduledTransactionIds": manager.getTransactionIDsByTimestamp(now)
        }
    }

    init() {
        // Initialize contract references
        self.jukeboxAddress = getAccount(FlowJukeBox.contractAddress).address
        self.jukeboxCollectionPath = FlowJukeBox.CollectionPublicPath

        // Initialize paths
        self.HandlerStoragePath = /storage/FlowJukeBoxPlayHandler
        self.HandlerPublicPath = /public/FlowJukeBoxPlayHandler
        self.ManagerStoragePath = /storage/FlowJukeBoxSchedulerManager
        self.ManagerPublicPath = /public/FlowJukeBoxSchedulerManager

        // Create initial resources
        let mgr <- FlowTransactionSchedulerUtils.createManager()
        self.account.storage.save(<- mgr, to: self.ManagerStoragePath)
        let cap = self.account.capabilities.storage.issue<&{FlowTransactionSchedulerUtils.Manager}>(
            self.ManagerStoragePath
        )
        self.account.capabilities.publish(cap, at: self.ManagerPublicPath)

        // Create and store handler resource
        let h <- create PlayHandler(contractAddress: self.jukeboxAddress)
        self.account.storage.save(<- h, to: self.HandlerStoragePath)
    }
}
