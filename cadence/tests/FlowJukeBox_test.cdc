import Test

access(all) let account = Test.createAccount()

access(all) fun testContract() {
    let err = Test.deployContract(
        name: "FlowJukeBox",
        path: "../contracts/FlowJukeBox.cdc",
        arguments: [],
    )

    Test.expect(err, Test.beNil())
}