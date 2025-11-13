import "FlowJukeBoxTransactionHandler"

// ///////////////TESTNET IMPORTS/////////////////////
// import FlowJukeBoxTransactionHandler from 0x6e0cf74ea4a8cf7d
// ///////////////////////////////////////////////

access(all) fun main(): {String: AnyStruct} {
    return FlowJukeBoxTransactionHandler.getSchedulerHealth()
}
