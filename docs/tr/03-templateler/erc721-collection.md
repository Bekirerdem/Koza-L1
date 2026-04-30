# Template 2 — ERC-721 NFT Koleksiyonu

> **Audit-grade NFT koleksiyon kontratı** — ERC-721 + ERC-2981 royalty + Merkle
> allowlist + faz kontrolü + per-wallet limit. OpenZeppelin v5.3+ pattern'leri,
> 100% test coverage, 4 invariant doğrulaması.

## Ne işe yarar?

`KozaCollection.sol` üç farklı senaryoyu tek kontratla destekler:

### Senaryo A — Sanat Koleksiyonu (Türk Akademi Sanat)
- **Kim için:** Patika.dev mezunları, üniversite kulüpleri, dijital sanatçılar
- **Akış:** Allowlist faz (whitelist sahipleri) → Public faz (herkes)
- **Royalty:** Marketplace satışlarında %5-10 sanatçıya/koleksiyon hazinesine
- **Avantaj:** Audit-grade kod, kendi marketplace'iniz olmasa bile OpenSea / Joepegs / Salvor'da satılabilir

### Senaryo B — Topluluk / DAO Üyelik Token'ı
- **Kim için:** Bursa Koza DAO, Team1 TR chapter, üniversite kulüpleri
- **Akış:** Allowlist (mevcut üyeler) → Public (yeni alımlar)
- **Royalty:** %0 (üyelik token'ı, ikincil piyasa öncelikli değil)
- **Avantaj:** Multisig owner ile güvenli üyelik yönetimi

### Senaryo C — Utility NFT (oyun item, biletler, sertifika)
- **Kim için:** Web3 oyun stüdyoları, etkinlik organizatörleri
- **Akış:** Sadece Public faz, batch mint
- **Royalty:** %2.5-5 (geri-dönüş ekosistemi)
- **Avantaj:** Reveal mekaniği için `setBaseURI` kullanılabilir (önce gizli URI, sonra reveal)

> **Önerilmediği durumlar:** Tek-kullanımlık (soulbound) sertifika için Template 4
> ERC-5114; cross-chain bridge için Template 3 ICTT kullanın.

---

## Avalanche / Solidity Özellikleri

### Solidity 0.8.34+
- Custom errors (`require` string yerine, ~%50 daha az gas)
- Named mapping syntax (`mapping(address account => uint256 minted)`)
- Strict pragma: 0.8.35+ ile build edilirse compiler optimization farkları olur

### OpenZeppelin v5.3+
- `ERC721`: minimum baz, gas-friendly (Enumerable yok — listeleme indexer'a bırakılır)
- `ERC2981`: standartlaşmış royalty bilgisi (`royaltyInfo(tokenId, salePrice)`)
- `Ownable2Step`: yanlış adrese ownership transferi engellenir (kabul beklenir)
- `MerkleProof.verifyCalldata`: gas-optimal proof doğrulama

### Avalanche Spesifik
- Custom L1 (Subnet-EVM) üzerinde **native gas token kontratı = mint price birimi**
- ICM (Warp) açıksa ileride başka L1'lere bridge eklenebilir (Template 3)
- Block time 2s — mint UX'i C-Chain'den (~2s) hızlı, Ethereum L1'den (~12s) çok hızlı

---

## ⚠️ Güvenlik Uyarıları

### KRITIK
1. **Owner production'da ASLA EOA olmasın** — Gnosis Safe (4-of-7 önerilen) kullan
2. **Royalty receiver da multisig olmalı** — gelir kaybı riski
3. **`setBaseURI` after reveal cancel etme:** Mint sırasında `ipfs://placeholder/`
   kullanıyorsan, `setBaseURI` ile gerçek metadata'ya dönüş **tek yön** olmalı
   (immutable kontrat değil ama topluluk güveni için dokümante et)
4. **Strict `msg.value` eşleşmesi:** Frontend tam ücreti hesaplamalı; aksi halde
   user tx'i revert olur ve gas kaybeder. UX testi zorunlu.

### ÖNEMLİ
5. **Per-wallet limit sybil koruması değil:** `MAX_PER_WALLET = 10` sadece bot'u
   yavaşlatır. Gerçek koruma için frontend captcha + IP rate-limit gerekir
6. **Allowlist Merkle root değiştirilebilir:** `setMerkleRoot` ile owner istediği
   zaman yeni liste yükleyebilir. Topluluk şeffaflığı için Discord/Twitter
   duyurusu zorunlu
7. **Royalty marketplace seçimine bağlı:** OpenSea Operator Filter ile zorlanır,
   Blur royalty saymayabilir. Kullanıcılarınıza dokümante edin

### BİLGİ AMAÇLI
8. `ERC721._safeMint` reentrancy yapamaz — token alıcısı kontratsa
   `onERC721Received` çağrısı yapılır, ama mint'ten ÖNCE state güncellenir (CEI)
9. `withdraw` reentrancy guard içermez çünkü withdraw kendi state'ini
   güncellemez (balance native zaten 0'a düşer); ama target adres `call` ile
   çağrılır, kötü niyetli bir target çoklu withdraw deneyemez

---

## 📋 Adım-Adım Fuji Deploy

### 1. Allowlist için Merkle Root Üret

JavaScript helper (Node.js):

```js
// scripts/build-merkle.mjs
import { keccak256 } from "viem";
import { encodePacked } from "viem";

const allowlist = [
  "0x39AEfbC8388da12907A21d9De888B288a9fa5794",
  "0x...", // diğer adresler
];

// Yaprak hash'leri
const leaves = allowlist.map(addr =>
  keccak256(encodePacked(["address"], [addr]))
);

// 2-yapraklı sıralı hash (commutative — OZ MerkleProof.verifyCalldata uyumlu)
function commutativeHash(a, b) {
  const [lo, hi] = a < b ? [a, b] : [b, a];
  return keccak256(`0x${lo.slice(2)}${hi.slice(2)}`);
}

// Tek seviyeli ağaç örneği (production'da tam tree gerekir):
// Üretim için `merkletreejs` veya OZ'in `@openzeppelin/merkle-tree` paketini kullanın
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

const tree = StandardMerkleTree.of(
  allowlist.map(addr => [addr]),
  ["address"]
);

console.log("Root:", tree.root);

// Belirli bir adres için proof:
for (const [i, v] of tree.entries()) {
  if (v[0] === "0x39AEfbC8388da12907A21d9De888B288a9fa5794") {
    console.log("Proof:", tree.getProof(i));
    break;
  }
}
```

> ⚠️ **Önemli farklılık:** OpenZeppelin'in Standard Merkle Tree'si yaprakları
> `keccak256(keccak256(abi.encode(...)))` ile **çift hash** yapar (second
> preimage attack koruması). Bu kontrat ise basitlik için **tek hash**
> (`keccak256(abi.encodePacked(address))`) kullanır. Standart OZ tree ile
> uyumlu kalmak için kontratta da çift hash'e geçmek mümkün — bu template'in
> v0.3+ sürümlerinde değerlendirilebilir.

### 2. .env Hazırla

```bash
# Zorunlu
PRIVATE_KEY=0x...                                    # Fuji testnet wallet
DEPLOYER_ADDRESS=0x39AEfbC8388da12907A21d9De888B288a9fa5794

# Opsiyonel (defaults var)
NFT_NAME="Koza Genesis"
NFT_SYMBOL="KOZA"
NFT_BASE_URI="ipfs://QmYourCID/"        # SONU `/` İLE BİTİRİN
NFT_MAX_SUPPLY=5000
NFT_MINT_PRICE=50000000000000000        # 0.05 AVAX in wei
NFT_ROYALTY_BPS=500                     # %5
NFT_OWNER=0xMULTISIG_ADDRESS            # production: Safe
NFT_ROYALTY_RECEIVER=0xMULTISIG_ADDRESS

# Verify için
SNOWTRACE_API_KEY=rs_xxxxxxxxxxxxxxxxxxxxxxxx
```

### 3. Deploy + Verify

```bash
forge script script/deploy/DeployERC721Collection.s.sol \
  --rpc-url fuji \
  --broadcast \
  --verify
```

Beklenen output:
```
=== Deploying KozaCollection ===
  Owner: 0x...
  Name: Koza Genesis
  Max supply: 5000
  ...
=== Deployed ===
  Address: 0xCONTRACT_ADDRESS
  Phase: 0  (Closed)
```

### 4. Allowlist + Phase Yönetimi

```bash
# Merkle root yükle
cast send 0xCONTRACT_ADDRESS \
  "setMerkleRoot(bytes32)" 0xMERKLE_ROOT_FROM_STEP_1 \
  --rpc-url fuji --private-key $PRIVATE_KEY

# Allowlist faza geç
cast send 0xCONTRACT_ADDRESS \
  "setPhase(uint8)" 1 \
  --rpc-url fuji --private-key $PRIVATE_KEY

# (24-48 saat allowlist sonrası)
# Public faza geç
cast send 0xCONTRACT_ADDRESS "setPhase(uint8)" 2 \
  --rpc-url fuji --private-key $PRIVATE_KEY

# Mint ücretlerini topla
cast send 0xCONTRACT_ADDRESS \
  "withdraw(address)" 0xTREASURY_ADDRESS \
  --rpc-url fuji --private-key $PRIVATE_KEY
```

### 5. Allowlist Mint (kullanıcı tarafı)

```bash
cast send 0xCONTRACT_ADDRESS \
  "allowlistMint(uint256,bytes32[])" 2 "[0xPROOF1,0xPROOF2]" \
  --value 0.1ether \
  --rpc-url fuji --private-key $USER_PRIVATE_KEY
```

### 6. Public Mint

```bash
cast send 0xCONTRACT_ADDRESS \
  "publicMint(uint256)" 3 \
  --value 0.15ether \
  --rpc-url fuji --private-key $USER_PRIVATE_KEY
```

---

## 🧪 Foundry Test Komutları

```bash
# Sadece bu template'in unit/fuzz testleri
forge test --match-path "test/templates/ERC721*" -vv

# Sadece invariant testleri (1000 run × 100k call)
forge test --match-contract ERC721CollectionInvariantTest -vv

# Coverage
forge coverage --match-path "test/templates/ERC721*" --report summary

# Beklenen: 100% lines/statements/branches/funcs on KozaCollection.sol
```

---

## 🔧 Ortak Hatalar + Çözümleri

### `WrongPhase(0, 2)` revert (publicMint)
Faz Closed (0). Önce `setPhase(2)` ile Public yap.

### `IncorrectPayment(sent, required)` revert
`msg.value` tam olarak `mintPrice * quantity` olmalı. Frontend net hesap göstermeli.

### `InvalidProof()` revert (allowlistMint)
- Adres allowlist'te değil
- Proof yanlış sıra ile verildi (OZ commutative hash kabul eder, sıra önemsiz)
- Merkle root güncel değil (`merkleRoot()` view fonksiyonu ile kontrol et)

### `ExceedsPerWalletLimit(10, X, 10)` revert
Cüzdan zaten 10 mint yaptı (allowlist + public toplam). Başka adres kullanılmalı.

### `MaxSupplyReached(5000, 5001)` revert
Tüm token'lar tükendi. Yeni mint yok.

### `tokenURI(1)` boş string dönüyor
`baseURI` boş veya sonu `/` ile bitmiyor. `setBaseURI("ipfs://CID/")` çağır.

### Marketplace royalty saymıyor
- OpenSea: Operator Filter Registry üzerinden royalty zorlama (OZ
  `DefaultOperatorFilterer` modülü gerekir, bu template'e default eklenmedi)
- Joepegs: ERC-2981 destekler, bizim kontrat OK
- Blur: royalty zorlama yok, kullanıcı seçimi

---

## 🎨 IPFS Metadata Yönetimi

Her token için JSON metadata `baseURI + tokenId` adresinde olmalı:

```json
{
  "name": "Koza Genesis #1",
  "description": "Türk Avalanche topluluğunun genesis koleksiyonu.",
  "image": "ipfs://QmImageCID/1.png",
  "attributes": [
    {"trait_type": "Phase", "value": "Allowlist"},
    {"trait_type": "Edition", "value": "Genesis"}
  ]
}
```

**Yükleme yolları:**
- **Pinata** (önerilen): pinata.cloud üzerinden klasör yükle, CID al
- **NFT.Storage**: ücretsiz, IPFS pinning otomatik
- **kendi gateway'iniz**: HTTPS de kabul edilir (`https://meta.koza.dev/`)

> ⚠️ **Reveal mekaniği:** Mint sırasında placeholder URI kullan
> (`ipfs://QmHidden/`), sonra `setBaseURI("ipfs://QmRevealed/")` çağır.
> Topluluğa duyurulması zorunlu (rug-pull gibi görünmemesi için).

---

## 📊 Gas Maliyetleri (Fuji ortalamaları)

| İşlem | Gas | Maliyet @25 gwei |
|-------|-----|------------------|
| Deploy | ~2,500,000 | ~0.0625 AVAX |
| `publicMint(1)` | ~85,000 | ~0.0021 AVAX |
| `publicMint(5)` | ~280,000 | ~0.007 AVAX |
| `allowlistMint(1, [proof])` | ~110,000 | ~0.0028 AVAX |
| `transferFrom` | ~50,000 | ~0.00125 AVAX |
| `setPhase` | ~30,000 | ~0.00075 AVAX |
| `withdraw` | ~35,000 | ~0.00088 AVAX |

> Custom L1 üzerinde gas fiyatı ekosistem tarafından belirlenir, mainnet'te
> %99 daha düşük olabilir.

---

## 🔗 Sonraki Adımlar

- **Template 3 (ICTT Bridge):** Bu koleksiyonu farklı L1'lere köprüleyin
- **Template 5 (Treasury Multisig):** `withdraw` hedefi olarak güvenli bir
  Safe + Timelock kurun
- **Template 4 (Soulbound):** Üyelik tokenları için transfer-edilemez varyant

---

> Bu doküman Türkçe ana dilde yazılmıştır. Sorular için
> [github.com/Bekirerdem/Koza-L1/discussions](https://github.com/Bekirerdem/Koza-L1/discussions)
