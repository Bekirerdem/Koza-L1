# ERC-20 + Custom Gas Token — Deployment Rehberi

> **Template 1** · `src/templates/erc20-gas/KozaGasToken.sol`

---

## 🎯 Bu Template Ne İşe Yarar?

`KozaGasToken`, Avalanche üzerinde **production-grade** bir ERC-20 token deploy etmek için hazır şablon. İki ana kullanım senaryosu var:

### Senaryo A — Avalanche L1'inin native gas token'ı

Kendi Sovereign L1'inizi kuruyorsunuz, kullanıcılar tx ücretini AVAX yerine **kendi token'ınızla (KGAS, vs.)** ödüyor. Bu durumda native token L1 genesis'inde tanımlanır (`genesis/erc20-gas-token.json`), ERC-20 contract'ı **C-Chain'de** deploy edilir ve ICTT bridge ile L1 native'e dönüştürülür _(Sprint 3'te detaylı)_.

### Senaryo B — Standalone ERC-20 (C-Chain'de)

Sadece basit bir ERC-20 token istiyorsunuz, custom L1 yok. Kontrat C-Chain'e (Fuji / Mainnet) deploy edilir, kullanıcılar AVAX ile gas öder.

Her iki senaryo da aynı kontrat dosyasını kullanır — fark deployment lokasyonu ve ICTT bridge entegrasyonu.

---

## 🛡️ Hangi Avalanche / Solidity Özelliklerini Kullanır?

| Özellik | Açıklama |
|---|---|
| **Solidity 0.8.34** | IR storage bug fix sonrası stable — `pragma` kesin pin |
| **OpenZeppelin v5.3+** | `ERC20Capped`, `ERC20Permit`, `Ownable2Step` (audited) |
| **EIP-2612 Permit** | Gasless approve — kullanıcı imzalar, dApp on-chain submit eder |
| **EIP-712** | Tipli imzalı veri (Permit signature için) |
| **ERC20Capped** | Total supply için hard cap, sınırsız enflasyon imkansız |
| **Ownable2Step** | İki aşamalı ownership transfer — yanlış adres riski sıfır |
| **Custom errors** | `require(string)` yerine — gas + audit kalitesi |
| **`_update` override** | OZ v5 multiple-inheritance (ERC20 + ERC20Capped) çakışmasını çözer |

---

## ⚠️ Neye Dikkat? (Güvenlik)

### 1. `initialOwner` ASLA EOA olmamalı

Production'da owner adresi **Safe (Gnosis Safe) multisig** olmalı. EOA private key kaybolursa:
- Mint authority kaybedilir
- Token cap'ine kadar mint edilmiş hiçbir sıkıştırma yok

```solidity
// ❌ YANLIŞ (production)
new KozaGasToken(name, symbol, cap, initMint, msg.sender); // EOA

// ✅ DOĞRU
new KozaGasToken(name, symbol, cap, initMint, address(safeMultisig));
```

### 2. `cap` değiştirilemez

Constructor'da set edilen `cap` immutable. Sonradan artırılamaz/azaltılamaz. Yanlış değer → token'ın yeniden deploy'u gerekir.

**Tavsiye:** Test sırasında `cap = 1_000_000 ether`, mainnet'te tokenomics'inize göre belirleyin. Bir kez sabitlenir.

### 3. `initialMint` cap'i aşamaz

Constructor'da `initialMint > cap` olursa `InitialMintExceedsCap` revert. Test edin:

```solidity
// Cap = 1M, initial = 100K → OK
new KozaGasToken(..., 1_000_000 ether, 100_000 ether, owner);

// Cap = 1M, initial = 2M → revert
new KozaGasToken(..., 1_000_000 ether, 2_000_000 ether, owner); // reverts
```

### 4. Permit replay koruması nonce'a bağlı

EIP-2612 Permit imzaları **tek kullanımlık**. İmza tekrar gönderilirse nonce mismatch ile revert. Bunu test ettik (`test_RevertWhen_PermitReplayed`).

Yine de dikkat: **deadline yakın ise** kullanıcı imzaladıktan sonra MEV bot işlemden önce permit submit edebilir. Buna izin verirsiniz çünkü zaten kullanıcı izin vermiş, ama UX dizaynında front-end'de uyarı verin.

### 5. Pausable yok

Bu template **pausable değil** — kasıtlı tasarım kararı. Adoption'ı kolaylaştırır (kullanıcı her zaman transfer/burn edebilir). Eğer pause gerekiyorsa Phase 2'de `KozaGasTokenPausable` varyantı eklenir.

---

## 🚀 Adım Adım Deploy

### Önkoşullar

- Foundry kurulu (`forge --version` 1.5+)
- `koza-L1` repo'su clone edilmiş
- Fuji testnet AVAX (deploy için ~0.05 AVAX yeterli)
- Cüzdan: Core Wallet veya MetaMask (Fuji'ye eklenmiş)

### 1. Repo'yu hazırla

```bash
git clone https://github.com/Bekirerdem/koza-l1.git
cd koza-l1
forge install
forge build
forge test  # 32/32 yeşil olmalı
```

### 2. `.env` dosyanı doldur

```bash
cp .env.example .env
```

`.env` içine yaz:

```bash
# Testnet için cüzdan private key (ASLA mainnet PK koyma!)
PRIVATE_KEY=0xabc...

# Opsiyonel: özel deploy parametreleri (yoksa default'lar kullanılır)
ERC20_NAME="Koza Gas Token"
ERC20_SYMBOL="KGAS"
ERC20_CAP=1000000000000000000000000        # 1M token (1e18 decimal)
ERC20_INITIAL_MINT=100000000000000000000000 # 100K initial mint

# Owner adresin (multisig veya cüzdanın)
ERC20_OWNER=0xYourSafeMultisigOrEOA

# Snowtrace verify için (Routescan ücretsiz tier)
SNOWTRACE_API_KEY=verifyContract
```

> 🛡️ `.env` dosyası `.gitignore`'da, **asla commit etme**.

### 3. Fuji testnet'e deploy

```bash
forge script script/deploy/DeployERC20Gas.s.sol \
    --rpc-url fuji \
    --broadcast \
    --verify
```

Beklenen çıktı:

```
=== Deploying KozaGasToken ===
  Broadcaster:     0xYourAddress
  Owner:           0xYourSafeMultisig
  Name:            Koza Gas Token
  Symbol:          KGAS
  Cap (wei):       1000000000000000000000000
  Initial mint:    100000000000000000000000

=== Deployed ===
  Address:         0xDeployedContractAddress
  Total supply:    100000000000000000000000
  Cap:             1000000000000000000000000
  Owner balance:   100000000000000000000000

##### avalancheFujiTestnet
✅ [Success] Hash: 0xabc...
Contract Address: 0xDeployedContractAddress
Block: 12345678
Paid: 0.00xx AVAX
```

### 4. Snowtrace'te kontrol et

```
https://testnet.snowtrace.io/address/0xDeployedContractAddress
```

Beklenen:
- ✅ Contract source verified (yeşil tik)
- ✅ Read functions: `name()`, `symbol()`, `cap()`, `totalSupply()`, `owner()`
- ✅ Write functions: `mint`, `burn`, `transfer`, `approve`, `permit`, `transferOwnership`, `acceptOwnership`

### 5. İlk transfer'i yap (smoke test)

Snowtrace üstünden veya `cast` CLI ile:

```bash
# Owner'dan başka bir adrese 100 KGAS gönder
cast send 0xDeployedContractAddress \
    "transfer(address,uint256)" \
    0xRecipient \
    100000000000000000000 \
    --rpc-url fuji \
    --private-key $PRIVATE_KEY
```

---

## 🐛 Ortak Hatalar ve Çözümleri

### `Error: insufficient funds for gas * price + value`

Cüzdanında yetersiz AVAX. Faucet'ten al: https://faucet.avax.network

### `Error: nonce too low`

Önceki deploy'un nonce'u tutmuş. Cüzdanında "Reset account" yap (MetaMask: Settings → Advanced → Reset Account) veya `--legacy` flag dene.

### `Error: transaction underpriced`

`feeConfig.minBaseFee` altında bid verdin. `--gas-price` flag'iyle artır:

```bash
forge script ... --gas-price 25000000000  # 25 gwei
```

### `Error: code size limit exceeded`

Contract 24KB üzerinde. Bizim KozaGasToken **4KB** olduğu için bu olmamalı. Eğer kendiniz extension eklediyseniz: `optimizer_runs` artırın (`foundry.toml`).

### `Snowtrace verification failed`

Çok yaygın sebep: `SNOWTRACE_API_KEY` eksik veya yanlış. Routescan ücretsiz tier için `verifyContract` literal string kabul ediyor. `.env`'de:

```bash
SNOWTRACE_API_KEY=verifyContract
```

Hala fail ediyorsa, manual verify:

```bash
forge verify-contract \
    --rpc-url fuji \
    --watch \
    --constructor-args $(cast abi-encode "constructor(string,string,uint256,uint256,address)" \
        "Koza Gas Token" "KGAS" 1000000000000000000000000 100000000000000000000000 0xOwner) \
    0xDeployedContractAddress \
    src/templates/erc20-gas/KozaGasToken.sol:KozaGasToken
```

### `Permit signature replay attack` revert

Aynı (owner, spender, value, nonce) ile permit() iki kez çağrıldı. Nonce arttığı için ikinci çağrı revert.

### `OwnableInvalidOwner(0x0)` deploy sırasında

`ERC20_OWNER` env'i sıfır adres veya boş. `.env` dosyanı kontrol et.

---

## 🧪 Foundry Test'leri Çalıştır

```bash
# Sadece bu template'in test'leri
forge test --match-contract ERC20Gas -vv

# Detaylı çıktı + traces
forge test --match-contract ERC20GasTest -vvvv

# Sadece fuzz testleri (yüksek run count)
forge test --match-test testFuzz --fuzz-runs 50000

# Invariant test'leri
forge test --match-contract ERC20GasInvariantTest

# Coverage raporu
forge coverage --report summary
```

Beklenen:
- 26 unit + fuzz test (`ERC20GasTest`)
- 3 invariant test (`ERC20GasInvariantTest`)
- 3 deploy script test (`DeployERC20GasTest`)
- = **32 test, hepsi yeşil**
- Coverage: %100 lines / statements / branches / functions

---

## 🌉 Sonraki Adım: ICTT Bridge ile L1'e Köprüleme

Bu template'i custom L1'inize taşımak için:

1. C-Chain'de KozaGasToken deploy et (yukarıdaki adımlar)
2. Custom Sovereign L1'inizi kurun (`genesis/erc20-gas-token.json` ile, bkz. `genesis/README.md`)
3. ICTT (Inter-Chain Token Transfer) ile token'ı L1'e bridge'le

ICTT entegrasyonu **Sprint 3 — Template 3** kapsamında.

---

## 📚 İlgili Dokümanlar

- [Avalanche 101 (Türkçe)](../01-avalanche-101.md) — Avalanche9000, ICM, ICTT, Subnet-EVM özeti
- [Kendi L1'ini Deploy Et](../02-l1-deploy.md) — Avalanche CLI ile Sovereign L1 oluşturma
- [Güvenlik Checklist](../04-guvenlik.md) — Audit-grade pre-deploy checklist
- [`SECURITY.md`](../../../SECURITY.md) — Vulnerability disclosure policy

---

## 🤝 Sorun mu var?

- GitHub Issues: https://github.com/Bekirerdem/koza-l1/issues
- Discussions: https://github.com/Bekirerdem/koza-l1/discussions
- Security: l3ekirerdem@gmail.com (`[koza-l1 SECURITY]` subject)
