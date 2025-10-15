## Create flow jukebox

### Set variables for later

TESTNET:
```
$SIGNER = "FlowJukeboxDev1"
$CONTRACTADDR = "0x0x2636c731d469aa64"
$FLOWNETWORK = "testnet"
```

EMULATOR:
```
$SIGNER = "emulator-account"
$CONTRACTADDR = "0xf8d6e0586b0a20c7"
$FLOWNETWORK = "emulator"
```

### Commands
List accounts:
`flow accounts list`

Add a deployment:
`flow config add deployment`

Update contract:
`flow project deploy --network $FLOWNETWORK --update `


Create a jukebox:
`flow transactions send .\cadence\transactions\create_jukebox.cdc ABACAC 7200.0 --signer $SIGNER -n $FLOWNETWORK `

Start the a song and run autoplay to play next or end queue with payout:
`flow transactions send .\cadence\transactions\play_next_or_payout.cdc 1 -n $FLOWNETWORK --signer $SIGNER`

Add a song:
`flow transactions send .\cadence\transactions\add_entry.cdc 1 "youtube.com/blabla" "SongABCD" 10.0 30.0 --signer $SIGNER -n $FLOWNETWORK`

Get single jukebox details:
`flow scripts execute .\cadence\scripts\get_jukebox_info.cdc 1 -n $FLOWNETWORK`

See the queue:
`flow scripts execute .\cadence\scripts\get_queue.cdc $CONTRACTADDR 1 -n $FLOWNETWORK`

Play next (Admin):
`flow transactions send .\cadence\transactions\play_next.cdc 1 -n $FLOWNETWORK --signer $SIGNER`

List all jukeboxes:
`flow scripts execute .\cadence\scripts\list_jukeboxes.cdc -n $FLOWNETWORK`

List users jukeboxes:
`flow scripts execute .\cadence\scripts\get_users_jukeboxes.cdc $CONTRACTADDR -n $FLOWNETWORK`

Payout:
`flow transactions send .\cadence\transactions\payout.cdc 1 -n $FLOWNETWORK --signer $SIGNER`

