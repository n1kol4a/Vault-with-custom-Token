1. This is practice project. I have not yet done any security research/audit.
- I plan on adding:
- Security and other improvements 
2. This is a Time locked vault with custom token as currency.
3. Users can lock their funds for selected amount of time.
4. The proccess of using the vault is:
- User pays eth to mint custom token
- User deposites token into the vault
- User locks the funds into the vault
- User calls updateInterest function from Vault contract to update their balance and mint tokens
- User can withdraw the funds when enough time passed
- User can call burn function from VaultTokenMinter contract to claim back eth 
