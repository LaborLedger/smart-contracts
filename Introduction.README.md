#### Units & tokens
Smart Contracts support the following units and tokens:

##### Time Units
Working hours, measured in 5-minutes units to avoid floating-point operations.  
_Time Units_ may be "accepted" and "pending" (explained below).  
_Time Units_ may be "used" only by automatic "conversion" them into _Labor Units_. 

##### Labor Units
Working hours weighted with a member "weight", i.e. _Time Units_ multiplied by the "weight".   
To avoid floating-point operations, weights are integers -  
instead of the weight of 1.5 for the "Senior" role and 1.0 for the "Standard" role, the weight of 3 is assigned for the "Senior" and 2 to the "Standard" roles.       
_Labor Units_ considered "accepted" (rather than "pending") as soon as _Time Units_ are accepted.   
"Accepted" _Labor Units_ may be "spent" for (i.e. exchanged into) _Project Tokens_ and/or ETH/DAI coins,  
should _Tokens-for-Labor_ and/or _Tokens-for-DAI_ smart contract(s) is (are) active.  
We may later want to introduce "staking" of _Labor Units_ and rewards/penalties for acting in _Project Arbiter(s)_ and other roles.   

Note: _Labor Units_ do not "represent" the voting rights.

##### _Project Tokens_
ERC-777 (advanced ERC-20) tokens, representing 'de jure' rights (participation) in the project.

#### Roles
Smart Contracts support the following roles (which are not yet fully supported by the rest of the App):
1. _Member_ - may submit hours  
2. _Project Lead_ - may set the member status, the member weight (once only), maximum working hours, may adjust (decrease) "pending" _Time Units_ of a member  
3. _Project Arbiter(s)_ - may alter (decrease or cancel) the _Project Lead_'s adjustments of _Time Units_, update (already set) member weight 
4. _Inviter(s)_ - may invite new members 
5. _Admin_ - may migrate to new versions of smart contracts 
6. _Default Operator_ - may submit transactions on behalf of any other user (with any role) unless the user once explicitly revokes the allowance 
7. _Operator(s)_ - any user may assign an operator(s) able to submit transactions on the user behalf 
8. _Quorum_ - may mint and distribute _Project Tokens_, create token sales/exchange contracts, assign/denounce the _Project Lead_, the _Inviter(s)_, the _Project Arbiter(s)_ 
9. _Treasurer(s)_ - may send transactions (pay coins) from the _Treasury Wallet_ 

On the smart contracts deployment:
- the _Project Lead_, the _Project Arbiter_, the _Inviter(s)_ and the _Quorum_ is the same Ethereum account - the one provided by the signing-in user 
- the _Admin_ (via the _Admin Proxy_ smart contract, to be exact) is a "manually" created and maintained Ethereum account, one for all projects 
- no _Operator(s)_ registered 
- the _Default Operator_ is the Ethereum account controlled by the BE (this allows sending transactions for members w/o knowing their private keys) 

#### Smart Contracts

#### Labor-Ledger
It registers members, their _Time Units_ and _Labor Units_, does "aging", accounts "adjustments" ...

#### Token
ERC 777 tokens with the _Collaboration_ set as the "minter" (who may issue and distribute tokens).   
May implement limitations (like authorized token holders) for token transfers between accounts.

#### Collaboration
"Glue" making all contracts act as a whole.

#### Treasury Wallet
Multisig wallet keeping coins (DAI/ETH) of the project

_Note: the above mentioned contracts use "proxy-implementation" design pattern._   
_So, technically, there are two smart contracts (the proxy and the implementation) for each of them._

#### Tokens-for-Labor
A "token crowdsale" smart contract that allows members to "buy" _Project Tokens_ for _Labor Units_.

#### Labor-for-Coins
A smart contract that allows members to "sell" their Labor Units for DAI/ETH.  
One may think of it as a "salary payment" contract.

#### Tokens-for-Coins
A "token crowdsale" smart contract that allows _Investors_ buy _Project Tokens_ for DAI/ETH (or Pollen Tokens).

#### Admin-Proxy
The smart contract implementing the _Admin_ role.
 
#### Optional contracts
Not yet implemented: 
- _Quorum_ - [optional] a multisig and "voting" smart contract, currently the _Project Lead_'s EOA rather than a smart contract
- _Arbiter_ - [optional] a multisig smart contract, currently a member EOA rather than a smart contract
- _Member_ - [optional] a proxy/identity for a member, currently a member EOA rather than a smart contract

#### "Pending" vs. "accepted" labor, adjustments 

The _Labor-Ledger_ smart contract implements the "multi-stage" (or "aging") time submission as follows.
1. A member may submit hours (i.e. _Time Units_) for a week ended no later than 4 weeks ago  
(e.g., for weeks #14 ...#17 should a member submit hours on the week #18)
2. the _Time Units_ get converted into _Labor Units_ no sooner than in three weeks after the submission week.  
(e.g. on the week #21 should a member submit the week #17 on the week #18)  
During these three weeks the member's _Time Units_ (and future _Labor Units_) are "pending".  
After that, with adjustments mentioned below, they are "accepted".  
(N.B.: a member rights, i.e. voting, are based on the _Project Tokens_.  
Only the "accepted" _Labor Units_ may be exchange into the _Project Tokens_.  
Therefore "pending" _Time Units_ do not directly influence the voting rights.)  
3. During two weeks following the submission week, the _Project Lead_ may make an adjustment - decrease the _Time Units_ submitted by a member.
4. During the 3rd week following the submission week, (any of) the _Project Arbiter(s)_ may decrease or cancel the _Project Lead_'s adjustments.
5. The adjustments noted above alter (decrease) _Time Units_ (and hence - the _Labor Units_) of members.

The _Project Arbiter_ acts as a moderator.  
A teammate (or a few teammates collectively, via a multisig smart contract) may act in the _Project Arbiter_ role.  
```
Example:
A member submits 160 hours for a week.
The _Project Lead_ believes it is too much and submits the adjustment for minus 80 hours (thus striking out 50% of the member hours).
The member does not agree with the adjustment and opens a dispute applying to the _Project Arbiter_.
The _Project Arbiter_ considers the issue and lowers the adjustment to minus 40 hours.
So the member will finally have 120 hours accepted for the week.
```

Note, the _Project Arbiter_ can only alter (or entirely cancel) adjustments already created by the _Project Lead_.  
The _Project Arbiter_ can't create new adjustments.  
The _Project Lead_ can't alter created adjustments (even if the _Project Arbiter_ altered them).

#### Labor Units, Project Tokens, coins exchange

Consider the example below as the base scenario (use case).
```
1. The _Quorum_ (which is a separate smart contract or the _Project Lead_ account) calls the _Collaboration_ smart contract to mine 1M _Project Tokens_ distributing tokens as follows.
- 0.2M to the addresses of the management (or the address of the _Project Lead_)
- 0.8M tokens shall remain with the _Collaboration_ smart contract.
The _Collaboration_ smart contract deploys a new instance (the "proxy") of the _Token_ smart contract and calls it.
The latest issues 0.2M to the address (addresses) of the management (the _Project Lead_) and 0.8M to the address of the _Collaboration_ contract.

2. The _Quorum_ calls the _Collaboration_ contract to deploy a new _Tokens-for-Labor_ contract. The "tokens for Labor Unit" rate is one of the important parameters for the contract.
The _Collaboration_ contract creates a new instance (the "proxy") of the _Tokens-for-Labor_ contract and sends 0.4M tokens from the _Collaboration_ contract address to the _Tokens-for-Labor_ contract address.

3. A member calls the _Tokens-for-Labor_ contract to exchange her _Labor Units_ into _Project Tokens_ (note, the member "pays" with the "accepted" rather than "pending" _Labor Units_).
The _Tokens-for-Labor_ contract calls the _Collaboration_ contract to get transaction approval and, if approved (there are "free" _Project Tokens_ in the _Tokens-for-Labor_ address and enough _Labor Units_ the mamber holds), sends the _Project Tokens_ to the member.
The _Collaboration_ contract calls the _Labor-Ledger_ contract to to check available _Labor Units_ and register the "settled" (or "used") _Labor Units_ of the member.

4. The _Quorum_ calls the _Collaboration_ contract to deploy a new _Tokens-for-Coins_ contract. The "tokens for 1 DAI" rate is one of the important parameters.
The _Collaboration_ contract creates a new instance (the "proxy") of the _Tokens-for-Coins_ contract and sends 0.4M tokens from the _Collaboration_ contract address to the _Tokens-for-Coins_ contract address.

5. An investor sends DAI to the _Tokens-for-Coins_ contract to exchange DAI into tokens.
The _Tokens-for-Coins_ contract calls the _Collaboration_ contract to get transaction approval and, if approved, transfers _Project Tokens_ to the investor and DAI to the treasury wallet.

6. The _Quorum_ calls the _Collaboration_ contract to deploy a new _Labor-for-Coins_ contract. The "DAI for Labor Unit" rate is one of parameters.
The _Collaboration_ contract creates a new instance (the "proxy") of the _Labor-for-Coins_ contract. The project treasurers send DAI to the _Labor-for-Coins_ contract address.

7. A member calls the _Labor-for-Coins_ contract to exchange her ("accepted") _Labor Units_ into DAI.
The _Labor-for-Coins_ smart contract calls the _Collaboration_ smart contract to get transaction approval and, if approved, sends DAI to the member.
The _Collaboration_ contract calls the _Labor-Ledger_ contract to check available _Labor Units_ and register the "settled" _Labor Units_ of the member.
```
