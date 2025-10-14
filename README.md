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

Create a jukebox:
`flow transactions send .\cadence\transactions\create_jukebox.cdc ABACAC --signer $SIGNER -n $FLOWNETWORK`

Add a song:
`flow transactions send .\cadence\transactions\add_entry.cdc 1 "SongABCD" 1.0 30.0 --signer $SIGNER -n $FLOWNETWORK`

See the queue:
`flow scripts execute .\cadence\scripts\get_queue.cdc $CONTRACTADDR 1 -n $FLOWNETWORK`

Play next:
`flow transactions send .\cadence\transactions\play_next.cdc 1 -n $FLOWNETWORK --signer $SIGNER`