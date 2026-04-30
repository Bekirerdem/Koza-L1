# Güvenlik Checklist — Audit-Grade Solidity 2026

> **Hedef:** `kozalak-L1` template'lerinin **production deploy öncesi** güvenlik standartlarını kanıtlamak.

> ⚠️ **Bu doküman bir audit yerine geçmez.** Production deployment öncesi profesyonel audit (Sherlock, Cantina, Trail of Bits) yapılmalıdır.

---

## 0. Tehdit Modeli

Bir smart contract şu üç saldırıyı bekler:

1. **Doğrudan ekonomik saldırı** — flash loan, oracle manipülasyonu, MEV, reentrancy
2. **Privilege escalation** — access control bug, role hijack, ownership transfer hile
3. **Supply chain saldırı** — kötü niyetli dependency, kompromise edilmiş RPC, multisig UI hack

`kozalak-L1` template'leri 1 ve 2'ye karşı sertleştirilmiştir. 3 (supply chain) **operatörün sorumluluğu** — multisig signer'lar, RPC provider'lar, frontend host'ları sıkı denetlenmeli.

---

## 1. Pre-Deploy Checklist (22 Madde)

```
[ ]  1. Solidity ≥ 0.8.34 (IR storage bug fix sonrası), pragma kesin pin
[ ]  2. forge test → tüm testler yeşil
[ ]  3. forge test --fuzz-runs 10000 → invariant'lar geçiyor
[ ]  4. forge coverage ≥ %95 (lines/statements/branches/functions)
[ ]  5. slither . → high/medium uyarı YOK, low'lar gerekçeli
[ ]  6. aderyn . → ek detector çalıştı, finding'ler triaged
[ ]  7. halmos → symbolic test'ler invariant kanıtladı
[ ]  8. Storage layout: ERC-7201 namespaced (proxy ise) veya immutable (değilse)
[ ]  9. Access control: tüm sensitive fn'lar role-protected, Ownable2Step + multisig owner
[ ] 10. Reentrancy: external call yapan tüm fn'larda CEI + nonReentrant
[ ] 11. Oracle: Chainlink + freshness (updatedAt), deviation check, fallback (eğer kullanılıyorsa)
[ ] 12. Custom errors, require string YOK (audit kalitesi)
[ ] 13. Constructor: _disableInitializers() (upgradeable ise)
[ ] 14. EIP-712: domain'de chainId, nonce + deadline + signer recovery
[ ] 15. Pause mechanism: critical fn'larda Pausable + multisig pauser (eğer pausable)
[ ] 16. Upgrade auth (UUPS): _authorizeUpgrade timelock + multisig
[ ] 17. Static dependency audit: foundry.toml deps hash'leri sabit, submodule pin'li
[ ] 18. Snowtrace verify: deploy sonrası source code public
[ ] 19. Defender monitoring + Tenderly alert kuruldu (suspicious tx, pause trigger)
[ ] 20. Deployment runbook: mainnet fork'unda dry-run yapıldı
[ ] 21. Audit (competition veya firma) raporu mevcut, finding'ler kapatıldı
[ ] 22. Bug bounty program (Immunefi) deploy günü canlı
```

---

## 2. Solidity 0.8.34+ Best Practices

### 2.1 Pragma Discipline

```solidity
// ✅ DOĞRU — kesin sürüm pin
pragma solidity 0.8.34;

// ❌ YANLIŞ — caret esnek, audit'te red flag
pragma solidity ^0.8.0;
```

`kozalak-L1` ekosisteminde tüm contract'lar ve test'ler aynı kesin pragma'ya sahip olmalı. `foundry.toml`'da `solc = "0.8.34"` ile uyumlu.

### 2.2 Custom Errors > require strings

```solidity
// ✅ DOĞRU
error Unauthorized(address caller);
function adminOnly() external {
    if (msg.sender != admin) revert Unauthorized(msg.sender);
}

// ❌ YANLIŞ
function adminOnly() external {
    require(msg.sender == admin, "Unauthorized");
}
```

**Neden:** ~50 gas tasarruf, ABI'da daha iyi parse, revert reason'da context taşır.

### 2.3 `unchecked` Sadece Kanıtlı Taşmaz Durumlar

```solidity
// ✅ DOĞRU — for counter, asla taşmaz
for (uint256 i = 0; i < n; ) {
    // ...
    unchecked { ++i; }
}

// ❌ YANLIŞ — kullanıcı input'unda unchecked tehlikeli
unchecked {
    uint256 result = userValue + 1; // Cetus $223M hack
}
```

### 2.4 Storage Layout (Proxy/Upgradeable İçin)

ERC-7201 namespaced storage zorunlu:

```solidity
/// @custom:storage-location erc7201:koza.contracts.MyToken
struct MyTokenStorage {
    uint256 totalSupply;
    mapping(address => uint256) balances;
}

bytes32 private constant MY_TOKEN_STORAGE_LOCATION =
    0x...; // keccak256(abi.encode(uint256(keccak256("koza.contracts.MyToken")) - 1)) & ~bytes32(uint256(0xff))

function _getStorage() private pure returns (MyTokenStorage storage $) {
    assembly { $.slot := MY_TOKEN_STORAGE_LOCATION }
}
```

OpenZeppelin v5 tüm upgradeable contract'larını bu pattern'e taşıdı.

---

## 3. Bilinen Attack Vektörleri

### 3.1 Reentrancy (Klasik + Read-Only + Cross-Function)

```solidity
// ❌ KIRIK — DAO hack pattern
function withdraw() external {
    uint256 balance = balances[msg.sender];
    (bool ok,) = msg.sender.call{value: balance}("");  // ← reentrancy point
    require(ok);
    balances[msg.sender] = 0;  // çok geç
}

// ✅ CEI (Checks-Effects-Interactions) + nonReentrant
function withdraw() external nonReentrant {
    uint256 balance = balances[msg.sender];
    balances[msg.sender] = 0;  // ← Effects ÖNCE
    (bool ok,) = msg.sender.call{value: balance}("");  // Interactions SONRA
    require(ok);
}
```

OZ `ReentrancyGuard` veya transient storage tabanlı varyantı kullan. **Read-only reentrancy** için view fonksiyonları da koru.

### 3.2 Integer Overflow (0.8+ Default Safe, Ama)

Solidity 0.8+ default safe ama `unchecked` ihlal edebilir:

- **Cetus Protocol** — Mayıs 2025, **$223M kayıp**. `checked_shlw` fonksiyonu yanlış sınırla yazılmıştı, küçük deposit ile büyük credit kaydedildi.
- **Ders:** Custom math fonksiyonlarını ASLA test'siz deploy etme. Halmos symbolic + Echidna fuzzing tam bunun için var.

### 3.3 Oracle Manipulation

```solidity
// ❌ KIRIK — Spot DEX fiyatı kullanma
function liquidate(address user) external {
    uint256 price = getUniswapV2Price(token); // tek-blok manipüle edilebilir
    // ...
}

// ✅ Chainlink + freshness + deviation
function liquidate(address user) external {
    (, int256 price,, uint256 updatedAt,) = chainlinkFeed.latestRoundData();
    require(price > 0, "Invalid price");
    require(block.timestamp - updatedAt < 1 hours, "Stale price");
    
    int256 twapPrice = uniswapV3TWAP();  // secondary check
    require(_deviation(price, twapPrice) < 5%, "Suspicious deviation");
    // ...
}
```

### 3.4 Flash Loan Attack

Tek tx'te ekonomik invariant ihlali:

- **Cream Finance** — flash loan ile yetersiz liquidity'yi sömürdü
- **Beanstalk** — flash governance attack ($182M)
- **Euler** — donation attack pattern ($197M)

**Önlem:** Tek tx'e bağımlı **hiçbir kritik karar verme**. Multi-block, oracle TWAP, time-locked operations.

### 3.5 MEV / Sandwich / JIT

```solidity
// ❌ Slippage-protected değil
swap(tokenIn, tokenOut, amount);

// ✅ User-defined slippage
swap(tokenIn, tokenOut, amount, minAmountOut, deadline);
```

Hassas operasyonlar için **commit-reveal** veya batch auction (CoW Protocol pattern). Veya **MEV-Share / Flashbots Protect** private mempool.

### 3.6 Signature Replay

EIP-712 + nonce + deadline + chainId şart:

```solidity
struct Permit {
    address owner;
    address spender;
    uint256 value;
    uint256 nonce;     // ← her imza için artar
    uint256 deadline;  // ← timestamp
}

bytes32 DOMAIN_SEPARATOR = keccak256(
    abi.encode(
        keccak256("EIP712Domain(...)"),
        keccak256(bytes(name)),
        keccak256(bytes("1")),
        block.chainid,    // ← cross-chain replay koruması
        address(this)
    )
);
```

`kozalak-L1` `KozaGasToken`'ın `ERC20Permit` (EIP-2612) implementasyonu bu pattern'e uyar — `nonces[owner]` her permit'te artar.

### 3.7 Access Control Bug (En Yaygın 2025 Kayıp Kategorisi)

**2025 toplam kayıp $1.42B+. Access control %67 oranıyla #1 sebep.**

```solidity
// ❌ KIRIK — initializer çağrılmamış
contract Upgradeable {
    address owner;
    function initialize(address _owner) external {
        owner = _owner;  // herkes çağırabilir, ilk çağıran owner olur
    }
}

// ✅ initializer modifier + _disableInitializers
contract Upgradeable is Initializable {
    constructor() {
        _disableInitializers();  // implementation contract'ta init'i kapat
    }
    function initialize(address _owner) external initializer {
        owner = _owner;
    }
}
```

**Diğer access control hataları:**
- `external` yerine `public` (gas atılır + child contract erişebilir)
- `onlyOwner` yerine `onlyAdmin` modifier'ı kullanmadığını unutmak
- Multisig owner ama signer'ın bir tanesi compromise (3-of-5 minimum, daha iyi 5-of-9)

### 3.8 Bridge / Cross-Chain Trust Assumptions

ICM/ICTT'de Avalanche **kendi validator'larına** güvenir — ekstra trust assumption yok. Ama **kaynak L1'in validator ekonomisi zayıfsa** bridge mesajları o ekonomi kadar zayıf.

**Kural:** Değer transfer edilen her L1'in validator stake ekonomisi denetlenmeli. PoA tek-validator L1'e değer aktarmak = tek-nokta-failure.

### 3.9 Custom Bridge Yazma — YASAK

```solidity
// ❌ ÇOK TEHLİKELİ — Solo dev custom bridge
contract MyBridge {
    function relay(bytes calldata msg) external { ... }
}

// ✅ kozalak-L1 yaklaşımı: ava-labs/icm-contracts inherit
import {TokenHome} from "icm-contracts/teleporter/registry/TokenHome.sol";
contract MyTokenHome is TokenHome { ... }
```

**Cross-chain bug'ları en pahalı bug'lardır** — Wormhole $325M, Ronin $625M, Nomad $190M. Audited code'a güven, kendi yazma.

---

## 4. Foundry Test Discipline

### 4.1 Üç Katman: Unit, Fuzz, Invariant

```solidity
// Unit — net davranış
function test_RevertWhen_NotOwner() public {
    vm.expectRevert();
    vm.prank(alice);
    contract.adminOnly();
}

// Fuzz — rastgele input
function testFuzz_TransferAmount(uint256 amount) public {
    amount = bound(amount, 1, balance);
    contract.transfer(alice, amount);
    assertEq(contract.balanceOf(alice), amount);
}

// Invariant — stateful fuzzing
function invariant_TotalSupplyConstant() public view {
    uint256 sum;
    for (uint i = 0; i < actors.length; i++) sum += contract.balanceOf(actors[i]);
    assertEq(sum, contract.totalSupply());
}
```

### 4.2 Coverage Hedefleri

- Lines: **%95+** zorunlu, **%100** ideal
- Branches: **%100** (her if/else dalı test edilmeli)
- Functions: **%100** (her external/public fn'in en az bir test'i)

`forge coverage --report summary` ile kontrol.

### 4.3 Fuzz Run Sayısı

- Local geliştirme: 1000 runs (hızlı)
- Pre-commit: 10,000 runs
- CI: 50,000 runs (`FOUNDRY_PROFILE=ci`)
- Production öncesi: 1,000,000+ runs (uzun)

`kozalak-L1` foundry.toml'da default 10K, CI profile'da 50K.

---

## 5. Toolchain (Statik Analiz)

| Araç | Ne Yakalar | Kullanım |
|---|---|---|
| **Slither** | 93 detector — reentrancy, uninit storage, shadowing, gas | `slither .` her commit |
| **Aderyn (Cyfrin)** | Rust-based, Slither'ın yakalamadığını yakalar | `aderyn .` CI'da |
| **Halmos (a16z)** | Symbolic execution — invariant prove | `halmos test/` symbolic prove |
| **Echidna** | Property-based fuzzing, derin invariant | nightly CI |
| **Mythril** | Bytecode-level symbolic | overnight CI |

`kozalak-L1` CI pipeline'ı:
1. `forge build`
2. `forge fmt --check`
3. `forge test --fuzz-runs 10000`
4. `forge coverage`
5. `slither .` (fail-on-medium)
6. `aderyn .` (rapor)

Pre-commit hook ile lokal'de aynı kontroller.

---

## 6. Audit Stratejisi (Solo Dev İçin)

### 6.1 Tier 1 — Profesyonel Firma ($40K-$200K+)

Trail of Bits, OpenZeppelin, ConsenSys Diligence, Cyfrin. Solo dev MVP için **aşırı**.

### 6.2 Tier 2 — Audit Competition (Önerilen)

| Platform | Prize Pool | Süre |
|---|---|---|
| **Code4rena** | $20K-$200K | 5-14 gün |
| **Sherlock** | $30K-$150K | 7-21 gün |
| **Cantina** | $10K-$100K | 7-30 gün |
| **CodeHawks** | $5K-$50K | 7-21 gün |

**Avantaj:** Çok daha ucuz, çok daha fazla göz görür.
**Dezavantaj:** Garantisiz — bug bulunmasa da ödüyorsunuz.

`kozalak-L1` Phase 1 sonu: **Sherlock $30K-$50K contest** hedefi.

### 6.3 Tier 3 — Bug Bounty (Sürekli)

- **Immunefi** — sektörün lideri, %10 TVL'e kadar critical bounty
- **Hats Finance** — alternatif, daha küçük protokoller
- **Cantina** — competition + bounty kombo

Mainnet deploy günü Immunefi programı **canlı olmalı**.

### 6.4 Formal Verification (Opsiyonel)

- **Certora** — paralı, kurumsal
- **Halmos (ücretsiz)** — Foundry-native, başlangıç için pragmatik
- **K Framework** — akademik

---

## 7. 2025 Case Studies (Çıkarılacak Dersler)

| Hack | Tarih | Kayıp | Vector |
|---|---|---|---|
| **Bybit** | Şubat 2025 | $1.4B | Multisig UI compromise (supply chain) |
| **Cetus Protocol** | Mayıs 2025 | $223M | Math overflow (custom check_shlw bug) |
| **Balancer V2** | Kasım 2025 | $120M | Rounding direction mismatch |
| **Sonne Finance** | Mayıs 2024 | $20M | Compound V2 fork race condition (5+ kez tekrarladı) |
| **Nemo Protocol** | 2025 | $2.4M | Cross-chain message validation |

**Genel patern:** 2025 toplam kayıp $1.42B+. **Yeni vektör değil — eski hataların tekrarı.**

`kozalak-L1` ekosistemi olarak: **OZ + ava-labs audited primitive'ler dışında custom logic minimum**. Bu kural ihlal edildiğinde audit-grade etiketi düşer.

---

## 8. AI-Generated Code Uyarısı

Anthropic'in 2025 araştırmasında: AI agent'lar smart contract'larda **toplam $4.6M exploit** üretebildi.

**Kural:** AI üretilmiş kontrat kodu **ASLA direkt deploy edilmez**. Her AI-generated fonksiyon için:
1. Slither + Aderyn + Halmos zorunlu
2. Fuzz/invariant test (10K+ runs)
3. Audit competition öncesi peer review

`kozalak-L1` template'leri Claude AI ile yazıldı. Bu yüzden:
- Tüm pattern'ler OpenZeppelin/ava-labs audited primitives'e dayanır
- %100 test coverage zorunlu
- Sherlock contest Phase 1 sonu hedeflenmiştir

---

## 9. Operational Security

### 9.1 Multisig (Production'da Zorunlu)

- **Minimum:** 3-of-5
- **Önerilen:** 5-of-9 (büyük TVL)
- **Platform:** Safe (eski Gnosis Safe)
- Signer'lar **farklı coğrafyada** ve **farklı cihazlarda** olmalı (Bybit hack lesson)

### 9.2 Private Key Discipline

- Mainnet PK **asla** `.env` dosyasında saklanmaz — `cast wallet` (encrypted keystore) veya hardware wallet (Ledger/Trezor) kullan
- Testnet PK için bile farklı bir cüzdan kullan, mainnet karışmasın

### 9.3 RPC Provider Discipline

- Mainnet'te birden fazla RPC (failover) kullan
- Sensitive ops için **kendi node**'unu çalıştır (RPC compromise riski sıfırlanır)

### 9.4 Frontend Discipline

- Frontend host (Vercel, Netlify) compromise olabilir → Bybit pattern
- IPFS hosting (Fleek, Pinata) önerilir — immutable
- Wallet connect WAF'ları + dom verification (`web3-onboard` veya benzer)

---

## 10. Sıradaki Adım

Yukarıdaki checklist'i kendi projenizde uygulayın. Sorularınız için:

- GitHub Issues: https://github.com/Bekirerdem/Kozalak-L1/issues
- Discussions: https://github.com/Bekirerdem/Kozalak-L1/discussions
- Security disclosure: l3ekirerdem@gmail.com (`[kozalak-l1 SECURITY]`)

---

## 📚 Referanslar

- [OWASP Smart Contract Top 10 (2026)](https://scs.owasp.org/sctop10/)
- [OpenZeppelin Security Considerations](https://docs.openzeppelin.com/contracts/5.x/api/security)
- [Cyfrin Audit Reports](https://github.com/Cyfrin/audit-reports)
- [Rekt News (hack post-mortems)](https://rekt.news)
- [Solidity Security Considerations](https://docs.soliditylang.org/en/latest/security-considerations.html)
- [a16z Smart Contract Security Checklist](https://a16zcrypto.com/posts/article/smart-contract-security-checklist-web3-development/)
