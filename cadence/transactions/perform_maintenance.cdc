import "FlowJukeBoxTransactionHandler"

// ///////////////TESTNET IMPORTS/////////////////////
// import FlowJukeBoxTransactionHandler from 0x6e0cf74ea4a8cf7d
// ///////////////////////////////////////////////

transaction() {
    prepare(signer: auth(Storage) &Account) {
        // No preparation needed - maintenance is a public function
    }

    execute {
        FlowJukeBoxTransactionHandler.performMaintenance()
        log("🧹 Maintenance completed successfully")
    }
}
