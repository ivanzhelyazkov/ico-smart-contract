
# Jarvis Token Crowdsale Smart Contracts

## Token details:
| Name     | Jarvis Reward Token |
|----------|---------------------|
| Symbol   | JRT                 |
| Decimals | 2                   |
| Amount   | 420,000,000         |
| Price    | 0.10 USD            |

Jarvis Reward Token is ERC-20 compliant.
ETH/USD rate is determined by an oracle.

## Crowdsale Details:
Crowdsale will be in 4 stages, one week each:
* Pre-ICO stage - 30% token bonus
* ICO stage 2 - 20% token bonus
* ICO stage 3 - 10% token bonus
* ICO stage 4 - 0% token bonus

Each stage will have a hard cap of 40,000,000 tokens.

Tokens will be distributed at the end of the ICO.

Unsold tokens will be burnt.

## Token distribution details:

| Allocation                  |      Tokens |
|:----------------------------|------------:|
| Team and Advisors           |  60,000,000 |
| DAO Pool                    |  30,000,000 |
| Partnership Pool            |  50,000,000 |
| Bounty and Airdrop Campaign |  20,000,000 |
| ICO Crowdsale               | 260,000,000 |
| Total                       | 420,000,000 |

## Developer instructions:

0. Install node.js and npm
https://nodejs.org/en/

1. Install truffle and npm dependencies -
```
npm install
npm install -g truffle
```

2. Install ganache - private blockchain simulator
https://github.com/trufflesuite/ganache

3. Run ganache.

4. Deploy smart contracts:
```
truffle migrate --network ganache
```

5. Run tests for Whitelist, Privileged, Crowdsale and Jarvis Reward Token:
```
truffle test --network ganache
```
