# Bridge - Backend

CLO Bridge backend is an observer system (events and transactions) to trigger two actions:

- Minting new tokens from CLO to BNB, ETH, TRX or EOS
- Burning tokens in BNB, ETH, TRX or EOS and sending back CLO.

## Components

### Mint daemon

Listen to all events of the smart-contract bridge on CLO to mint new BEP-2, ERC-20 or EOSIO tokens and send to the respective address.

### Burn daemon

Listen to all events/transactions from BNB, ETH, TRX, and EOS, burn tokens and send back CLO on Callisto Network chain. 