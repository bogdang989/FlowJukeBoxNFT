# 🎵 Flow Jukebox — Music Powered by Smart Contracts

**Built on Flow blockchain**

Deployed on **Testnet**: 
- A.9c3f2ba02c56c5c3.FlowJukeBox
- A.9c3f2ba02c56c5c3.FlowJukeBoxTransactionHandler


**Live:** [https://flow-juke-box-ui.vercel.app/](https://flow-juke-box-ui.vercel.app/)

**Promo video:** [https://www.youtube.com/watch?v=EaJTwLqPro8](https://www.youtube.com/watch?v=EaJTwLqPro8)

---

## 🎯 Short Summary
**Flow Jukebox** transforms music experiences into interactive on-chain events.  
Anyone can start a jukebox session, play music on a shared screen, and let the crowd vote, boost, or add songs — all using Flow tokens.  
It’s a decentralized, token-powered social music queue built entirely on the Flow blockchain.

---

## 🚀 The Idea

Imagine owning a bar, organizing a house party, or running a virtual event. No need for a DJ or specialized hardware, you just open Flow Jukebox on the screen and the party can get started.  
People connect their Flow wallets, browse songs, and use tokens to:

- 💡 **Add songs** to the queue  
- 🔼 **Boost favorites** to the top  
- 👀 **Watch in real time** as the queue reorders on-chain  

Every interaction — adding, boosting, and playback scheduling — is processed instantly through Flow smart contracts.

---

## ⚙️ How It Works

### 🎶 Start a Jukebox
The host launches a jukebox session by paying a Flow fee.  
This deploys a **Jukebox NFT** representing that session.

### 💰 Queue Songs with Flow Tokens
Users interact via the web app to add or boost songs, sending Flow payments to the jukebox contract.  
Each action triggers an on-chain update — the queue dynamically reorders by total backing amount.

### ⏱️ Autoplay & Payouts
The jukebox runs on a timer powered by **Flow Forte Scheduled Transactions**.  
When a session ends, the contract automatically distributes payouts to the jukebox owner and burns the session NFT.

---

## 💎 Built With

- **Smart Contracts:** Written in Cadence, deployed on Flow Testnet  
- **Scheduled Automation:** Powered by Flow Forte Transaction Scheduler  
- **Frontend:** React + Vite, integrated with FCL (Flow Client Library)  
- **Wallet Integration:** Full Flow wallet support for adding or boosting songs  

---

## 🌐 Why It’s Different

Flow Jukebox blends entertainment, ownership, and real-time blockchain utility:

- No centralized playlist manager — the community controls the queue.  
- Every action is transparent and verifiable on-chain.  
- Venues and event hosts can monetize engagement instantly.  

It’s a perfect example of Flow’s vision: **fun, fast, and frictionless consumer dApps** that feel magical — not technical.

---

## 🗺️ Roadmap

### **Phase 1 — Proof of Concept (✅ Completed)**

- 💿 **Functional Prototype:** Built and deployed the first working Flow Jukebox dApp on Flow Testnet.  
- 🔗 **Smart Contracts in Cadence:** Implemented NFT-based jukebox sessions with automatic payouts, burn logic, and time-based expiry via Flow Forte Scheduled Transactions.  
- 🖥️ **Frontend:** Created a React + FCL interface for starting jukeboxes, adding songs, and boosting them with Flow tokens.  
- ▶️ **YouTube Integration:** Integrated YouTube playback for all added songs, allowing the jukebox to stream real videos in sync with on-chain actions.  
  The core `FlowJukeBox` contract is platform agnostic — YouTube is used to demonstrate capability and prove the concept.  
- ⚙️ **End-to-End Validation:** Demonstrated instant on-chain queue reordering, payouts, and session finalization — proving the concept’s viability and user appeal.

---

### **Phase 2 — Mainnet Launch (🚧 In Progress)**

- 🌐 **Mainnet Deployment:** Migrate smart contracts to Flow Mainnet and validate all wallet, schedule, and payout flows in production.  
- 🔐 **Audit & Optimization:** Conduct contract security reviews, optimize gas efficiency, and streamline transaction UX.  
- 💳 **Payment Layer:** Finalize Flow token logic for adding/boosting songs using real on-chain payments.  
- 📊 **Analytics Dashboard:** Implement session metrics, user leaderboards, and transaction summaries for hosts.  
- 🪙 **Monetization:** Finalize business model details for host earnings and reward structures to power real jukebox sessions at events or within communities.

---

### **Phase 3 — Adoption & Expansion (🔜 Upcoming)**

- 🎧 **Online Events:** Host live, shared jukebox sessions (e.g., Flow Fridays, Hackathon closing party) where users join, boost, and listen together.  
- 💬 **Community Features:** Add reactions, live chat, and global leaderboards to make jukebox sessions social and interactive.  
- 🏟️ **IRL Integrations:** Deploy Flow Jukebox to real-world venues — cafés, bars, and community meetups — using QR-code access.  
- 💰 **Fiat-to-Flow Gateway:** Enable seamless entry for non-crypto users through automatic fiat conversion into Flow tokens.  
- 📱 **Mobile Experience:** Launch mobile-optimized version for quick participation and song boosting.  
- 🤝 **Partnership Ecosystem:** Collaborate with Flow projects, music collectives, and venues to make Flow Jukebox the go-to interactive music layer — both online and offline.


## How it works

Jukebox sessions:
- Creating a jukebox - Each jukebox session is an NFT that can be minted by anyone, after paying the minting fee. The NFT lives in the contract wallet.
- Adding songs - Anyone can add songs to a jukebox session, by providing the song info and arbitrary amount of $FLOW token to rank it higher in the queue. More $FLOW backing a song, the earlier the song comes into the queue
- Payout - Each jukebox has limited lifetime. After the jukebox lifetime expires, percentage of accumulated fees for adding songs to the jukebox is paid out to the wallet that created the jukebox session.
- scheduleNextPlay - Contract method, when called checks if session lifetime expired. If true, handles payout and terminates the session, else picks the next song from the queue and plays it. 
- NFT metadata - NFT stores the queue, as well as info on what is now playing and when it started playing.
  
Fully automated jukebox -  using the power of Forte and Scheduled transactions:
1. Jukebox owner creates the jukebox, which mints the NFT and starts autoplay, which runs the first `scheduleNextPlay` transaction.
1. `scheduleNextPlay` transaction plays the next song from the queue. It also reads the song duration and schedules the next `scheduleNextPlay` for once the current song ends.
1. This is repeated for every song from the queue until flow jukebox session is expired. If session expired, `scheduleNextPlay` does not play more songs, but handles payout and destroys the NFT, thus terminating the chain of scheduled transactions.

## Dev Commands (PowerShell)

### Setup
Set variables:  

TESTNET:
```
$SIGNER = "FlowJukeBoxDev3"
$CONTRACTADDR = "0x9c3f2ba02c56c5c3"
$FLOWNETWORK = "testnet"
```

EMULATOR:
```
$SIGNER = "emulator-account"
$CONTRACTADDR = "0xf8d6e0586b0a20c7"
$FLOWNETWORK = "emulator"
```
List accounts:
`flow accounts list`

Add a deployment:
`flow config add deployment`

Update contract:
```
flow project deploy --network $FLOWNETWORK --update
```

### Contract commands

Create a jukebox with songs and start
```
flow transactions send .\cadence\transactions\create_jukebox.cdc ABACAC 7200.0 --signer $SIGNER -n $FLOWNETWORK
flow transactions send .\cadence\transactions\start_autoplay.cdc 1 -n $FLOWNETWORK --signer $SIGNER
flow transactions send .\cadence\transactions\add_entry.cdc 1 "https://www.youtube.com/watch?v=tiSjxSc2hac" "Eva Cassidy - Songbird" 230.0 30.0 --signer $SIGNER -n $FLOWNETWORK
flow transactions send .\cadence\transactions\add_entry.cdc 1 "https://www.youtube.com/watch?v=QHfxMGEb9iE" "Eva Cassidy - You Take My Breath Away
" 269.0 20.0 --signer $SIGNER -n $FLOWNETWORK
flow transactions send .\cadence\transactions\add_entry.cdc 1 "https://www.youtube.com/watch?v=9-hKDYQ6F54" "Eva Cassidy - Wade in the water" 245.0 10.0 --signer $SIGNER -n $FLOWNETWORK
flow transactions send .\cadence\transactions\add_entry.cdc 1 "https://www.youtube.com/watch?v=ccmXWBluxIc" "Eva Cassidy - Ain't no sunshine" 206.0 5.0 --signer $SIGNER -n $FLOWNETWORK
flow transactions send .\cadence\transactions\add_entry.cdc 1 "https://www.youtube.com/watch?v=9UVjjcOUJLE" "Eva Cassidy - Fields of gold" 286.0 5.0 --signer $SIGNER -n $FLOWNETWORK
flow scripts execute .\cadence\scripts\get_jukebox_info.cdc 1 -n $FLOWNETWORK
flow scripts execute .\cadence\scripts\get_queue.cdc $CONTRACTADDR 1 -n $FLOWNETWORK
flow scripts execute .\cadence\scripts\list_jukeboxes.cdc -n $FLOWNETWORK
flow scripts execute .\cadence\scripts\get_users_jukeboxes.cdc $CONTRACTADDR -n $FLOWNETWORK
```

Create a jukebox:
```
flow transactions send .\cadence\transactions\create_jukebox.cdc ABACAC 7200.0 --signer $SIGNER -n $FLOWNETWORK
```

Start the next song and run autoplay to play next or end queue with payout:
```
flow transactions send .\cadence\transactions\start_autoplay.cdc 1 -n $FLOWNETWORK --signer $SIGNER
```

Create and immediately start autoplay
```
flow transactions send .\cadence\transactions\mint_and_start_autoplay.cdc ABACAC 7200.0 --signer $SIGNER -n $FLOWNETWORK
```

Add a song:
```
flow transactions send .\cadence\transactions\add_entry.cdc 1 "https://www.youtube.com/watch?v=9UVjjcOUJLE" "Eva Cassidy - Fields of gold" 286.0 5.0 --signer $SIGNER -n $FLOWNETWORK
```

```
flow transactions send .\cadence\transactions\extend_jukebox.cdc 1 7200.0 --signer $SIGNER -n $FLOWNETWORK
```

Get single jukebox details:
```
flow scripts execute .\cadence\scripts\get_jukebox_info.cdc 1 -n $FLOWNETWORK
```

See the queue for a specific jukebox:
```
flow scripts execute .\cadence\scripts\get_queue.cdc $CONTRACTADDR 1 -n $FLOWNETWORK
```

Play next (Admin):
```
flow transactions send .\cadence\transactions\play_next.cdc 1 -n $FLOWNETWORK --signer $SIGNER
```

List all jukeboxes:
```
flow scripts execute .\cadence\scripts\list_jukeboxes.cdc -n $FLOWNETWORK
```

List users jukeboxes:
```
flow scripts execute .\cadence\scripts\get_users_jukeboxes.cdc $CONTRACTADDR -n $FLOWNETWORK
```

Payout:
```
flow transactions send .\cadence\transactions\payout.cdc 1 -n $FLOWNETWORK --signer $SIGNER
```
