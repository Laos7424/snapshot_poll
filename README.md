# snapshot_poll

A permissionless on-chain polling primitive for DAOs and communities to gauge sentiment before committing to formal governance.

## What it does

- Any address can create a yes/no/abstain poll with a hard on-chain deadline
- One vote per address — no token gate, no delegation setup required
- Results are readable on-chain in real time by any contract or caller
- Polls can be closed early by the creator
- Abstain is a first-class outcome, enabling quorum math that distinguishes "didn't vote" from "voted no confidence"

## Why it matters

Most governance tools conflate sentiment polling with binding execution. That forces communities to stand up full proposal infrastructure — token thresholds, timelocks, delegation — just to ask a question.

`snapshot_poll` is a coordination primitive. It sits upstream of formal governance: lightweight enough to run before a proposal is drafted, composable enough to feed into downstream contracts that need a signal.

This is not a replacement for on-chain governance. It is the missing layer before it.

## Example use cases

- **Early-stage DAO sentiment** — gauge community opinion before spending on a formal proposal
- **Pre-governance signaling** — establish rough consensus before opening a binding vote
- **Lightweight coordination** — any group, any question, no infrastructure required

## Core functions

| Function | Description |
|---|---|
| `CreatePoll` | Create a poll with a question and Unix deadline |
| `Vote` | Cast a yes / no / abstain vote (one per address) |
| `GetResults` | Read vote counts for any poll |
| `ClosePoll` | Manually close a poll (creator only) |
| `ListActivePolls` | List all open polls with their deadlines |

## Positioning

`snapshot_poll` is part of a broader governance stack being built as composable Gno primitives:

- **Identity** — `address_book`: who is participating
- **Signaling** — `snapshot_poll`: what do they want (this realm)
- **Proposals** — `proposal_bounty`: what gets funded and executed
- **Execution** — downstream multisig and timelock primitives

Each layer is independently deployable and queryable. Build with one, or compose all of them.

## License

MIT
