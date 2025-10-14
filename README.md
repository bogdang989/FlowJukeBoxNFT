Create flow jukebox

Set variables for later
TESTNET:
`$SIGNER = "flowjukebox1"`
`$CONTRACTADDR = "0x"`
`$FLOWNETWORK = "testnet"`

EMULATOR:
`$SIGNER = "emulator-account"`
`$CONTRACTADDR = "0xf8d6e0586b0a20c7"`
`$FLOWNETWORK = "emulator"`

Update contract:
`flow project deploy --network $FLOWNETWORK --update `

List accounts:
`flow accounts list`

Add a deployment:
`flow config add deployment`

Create a jukebox (ADMIN):
`flow transactions send .\cadence\transactions\create_jukebox.cdc ABACAC --signer $SIGNER -n $FLOWNETWORK`