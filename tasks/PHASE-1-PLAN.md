# Phase 1 Implementation Plan — `kozalak-l1`

> **Durum:** Aktif (2026-04-29 başlangıç)
> **Hedef:** 5 audit-grade Avalanche/Solidity template + Türkçe deployment rehberi

---

## Stratejik Bağlam

`kozalak-l1`, Bekir'in seçtiği **Senaryo P** (Avalanche L1 Toolkit) projesi. Solo dev + güvenlik kritik + hibe-odaklı (Retro9000 + Codebase) + açık kaynak.

Bekir'in mevcut Avalanche tecrübesi:
- ChainBounty (hackathon): Foundry + ICM/Teleporter + Subnet-EVM L1 + Wagmi/Viem
- shavaxre (hackathon, Emin ortak): C-Chain + Hardhat + ethers v6

Phase 1 hedefi: Hackathon-grade'den **production audit-grade**'e geçiş.

---

## Sprint Akışı

| Sprint | İçerik | Çıktı | Status |
|---|---|---|---|
| **0 — Setup** | Repo iskeleti, Foundry config, dependencies, ilk CI, GitHub repo | `forge build` yeşil, CI yeşil, GitHub'da public | 🚧 Aktif |
| **1 — Template 1** | ERC-20 + Custom Gas Token + Subnet-EVM genesis | v0.1.0 tag | ⏳ |
| **2 — Template 2** | ERC-721 NFT (allowlist + ERC-2981 royalty + IPFS metadata) | v0.2.0 tag | ⏳ |
| **3 — Template 3** | ICTT Cross-L1 Bridge (audited inherit, fork tests) ⭐ | v0.3.0 tag | ⏳ |
| **4 — Template 4** | Soulbound Credential (ERC-5114, ARIA-uyumlu) | v0.4.0 tag | ⏳ |
| **5 — Template 5** | Treasury Multisig + Timelock + AccessManager | v0.5.0 tag | ⏳ |
| **6 — Polish** | EN docs çevirisi, landing site (mdbook/VitePress), README rework | Yayın hazır | ⏳ |
| **7 — Launch** | ARIA Hub demo + Hürsel/Team1 partnership + Builder Hub PR | İlk traction | ⏳ |

---

## Sprint 0 — Setup (Şu Anda)

### Yapıldı (2026-04-29)

- [x] Klasör iskeleti: `kozalak-l1/{src,test,script,docs/{tr,en},genesis,tasks,.github/workflows}`
- [x] `foundry.toml` — Solidity 0.8.34, optimizer 200, via_ir, fuzz 10000, invariant 1000
- [x] `remappings.txt` — OZ + ICM contracts + ICTT/Teleporter/Subnet-EVM/Utilities prefixes
- [x] `.gitignore` — Foundry + Node + secrets + IDE
- [x] `LICENSE` — MIT
- [x] `.env.example` — PRIVATE_KEY, RPC, Snowtrace, Teleporter messenger address
- [x] `README.md` — TR-first pitch + template listesi + quick start

### Yapılacak

- [ ] `git init` + ilk commit (boş seed dosyaları için)
- [ ] `forge install` ile lib submodule'leri:
  - `foundry-rs/forge-std`
  - `OpenZeppelin/openzeppelin-contracts` (v5.3+)
  - `ava-labs/icm-contracts` (Avalanche audited Teleporter + ICTT)
- [ ] İlk `forge build` (boş src/, sadece dependencies derleniyor mu?)
- [ ] `SECURITY.md`, `CONTRIBUTING.md`, `CHANGELOG.md` (seed)
- [ ] `.github/workflows/ci.yml` — forge build/test/fmt + slither + aderyn
- [ ] GitHub repo oluştur (`gh repo create Bekirerdem/Kozalak-L1 --public --source=. --description "..."`)
  - **Önkoşul:** `gh auth login -h github.com` (Bekir terminal'den interactive)
- [ ] İlk push to main
- [ ] Branch protection: main protected, PR-only, CI required
- [ ] Repo settings: topics (avalanche, solidity, foundry, l1, web3, türkiye), description, social preview

### Sprint 0 Acceptance

- `forge build` yeşil
- `forge test` yeşil (boş test ama compile geçiyor)
- CI yeşil (foundry-rs/foundry-toolchain action)
- GitHub'da public repo, ilk commit
- Slither install + temiz çıktı

---

## Tech Stack (Locked)

| Bileşen | Sürüm | Not |
|---|---|---|
| Solidity | `0.8.34` (kesin pin) | IR storage bug fix sonrası |
| Foundry | `nightly` (CI'da hash pin) | forge 1.5.1 yerelde mevcut |
| OpenZeppelin Contracts | `v5.3+` (git submodule) | Ownable2Step, AccessManager, ERC-7201 |
| Avalanche ICM | `ava-labs/icm-contracts` (submodule) | Audited Teleporter + ICTT |
| Slither | `0.10.x` | CI ve pre-commit |
| Aderyn (Cyfrin) | latest | CI |
| Halmos | latest | Symbolic test, CI nightly |
| Echidna | latest | Invariant fuzzing, CI nightly |

---

## Template Spec'leri (Detay)

### Template 1 — ERC-20 + Custom Gas Token

**Dosyalar:**
- `src/templates/erc20-gas/KozaGasToken.sol`
- `script/deploy/DeployERC20Gas.s.sol`
- `genesis/erc20-gas-token.json` — Subnet-EVM genesis with custom gas token
- `test/templates/ERC20Gas.t.sol` (unit + invariant)
- `docs/tr/03-templateler/erc20-gas.md`

**Solidity Spec:**
- OZ `ERC20`, `ERC20Capped`, `ERC20Permit` (EIP-2612), `Ownable2Step`
- Custom errors (no require strings)
- Pre-mint allocation (constructor argümanı)
- Optional cap
- Solidity 0.8.34, custom errors, no unchecked

**Test Spec:**
- Unit: mint, transfer, approve, permit, ownership transfer
- Invariant: totalSupply ≤ cap, Sum(balances) == totalSupply
- Fuzz: transfer arbitrary amounts, approve overflow guards

**Acceptance:**
- Slither high/medium = 0
- Aderyn temiz
- forge coverage ≥ %95
- Fuji testnet'te deploy + Snowtrace verify
- Türkçe doc tamamlanmış

### Template 2 — ERC-721 NFT Collection

**Dosyalar:**
- `src/templates/erc721-collection/KozaCollection.sol`
- `script/deploy/DeployCollection.s.sol`
- `test/templates/ERC721Collection.t.sol`
- `docs/tr/03-templateler/erc721-collection.md`

**Solidity Spec:**
- OZ `ERC721`, `ERC721Enumerable`, `ERC2981`, `Pausable`, `Ownable2Step`
- Merkle proof allowlist (mint with `bytes32[] proof`)
- IPFS metadata (`tokenURI` baseURI override)
- Royalty default %5
- Max supply cap

**Test Spec:**
- Unit: mint, allowlist mint, royalty calc, pause/unpause, burn
- Invariant: totalSupply ≤ maxSupply, balanceOf consistency

### Template 3 — ICTT Cross-L1 Bridge ⭐

**Dosyalar:**
- `src/templates/ictt-bridge/KozaTokenHome.sol` (kaynak L1, mint/burn veya lock/release)
- `src/templates/ictt-bridge/KozaTokenRemote.sol` (hedef L1, ERC-20 representation)
- `script/deploy/DeployTokenHome.s.sol`
- `script/deploy/DeployTokenRemote.s.sol`
- `test/templates/ICTT.t.sol` (fork test, Fuji + custom L1)
- `docs/tr/03-templateler/ictt-bridge.md`

**Solidity Spec:**
- `ava-labs/icm-contracts/contracts/ictt/TokenHome` ve `TokenRemote` inherit
- Token Home Modes:
  - `ERC20TokenHome` — kaynak L1'de ERC-20'yi lock
  - `NativeTokenHome` — kaynak L1'de native AVAX'ı lock
- Token Remote Modes:
  - `ERC20TokenRemote` — hedef L1'de mint/burn
  - `NativeTokenRemote` — hedef L1'de native gas token mint/burn
- `sendAndCall` örneği (token transfer + uzak L1'de fonksiyon çağrı)

**Güvenlik Notu:**
- **Custom logic minimum.** Ava-labs'in audited contract'ını miras al, sadece access control ekle
- Teleporter messenger adresi kontrol et (deterministic deploy: `0x253b2784c75e510dD0fF1da844684a1aC0aa5fcf`)

**Test Spec:**
- Fork test: Fuji + custom L1 testnet (Avalanche CLI ile yerel kurulu L1)
- Mesaj gönderme/alma, fee modeli, multi-hop scenarios

### Template 4 — Soulbound Credential (ERC-5114)

**Dosyalar:**
- `src/templates/soulbound-credential/KozaCredential.sol`
- `script/deploy/DeployCredential.s.sol`
- `test/templates/Soulbound.t.sol`
- `docs/tr/03-templateler/soulbound-credential.md`

**Solidity Spec:**
- ERC-721 base + non-transferable override
- ERC-5114 interface compliance
- Issuer-only mint (`AccessManager` veya `AccessControl`)
- Optional revoke (issuer)
- Metadata JSON: issuer, recipient, course, date, signature

**Use Case Hedef:** ARIA Hub mezunlarına on-chain sertifika.

### Template 5 — Treasury Multisig + Timelock

**Dosyalar:**
- `src/templates/treasury-multisig/KozaTreasury.sol`
- `script/deploy/DeployTreasury.s.sol`
- `test/templates/Treasury.t.sol`
- `docs/tr/03-templateler/treasury-multisig.md`

**Solidity Spec:**
- OZ `TimelockController` + `AccessControl` veya `AccessManager`
- Safe (Gnosis Safe) ile uyumlu interface
- Proposer/Executor/Canceller roles
- Min delay configurable (default 48h)

---

## CI/CD Pipeline

### `.github/workflows/ci.yml`

Her PR/push'ta:

1. `actions/checkout@v4` (with submodules)
2. `foundry-rs/foundry-toolchain@v1` (nightly)
3. `forge build`
4. `forge fmt --check`
5. `forge test --fuzz-runs 10000 -vvv`
6. `forge coverage` (rapor + Codecov)
7. Slither (`crytic/slither-action@v0.4.0`, fail-on-medium)
8. Aderyn (`cyfrin/aderyn-action`)

### Branch Protection

- `main` korumalı
- 1 review zorunlu (kendi review'unuz)
- CI yeşil zorunlu
- No direct push

---

## Dokümantasyon Strüktürü

```
docs/
├── tr/                              # Türkçe (ana)
│   ├── 00-baslangic.md
│   ├── 01-avalanche-101.md          # Avalanche9000, ICM, ICTT, Subnet-EVM
│   ├── 02-l1-deploy.md              # Kendi L1'inizi nasıl deploy edersiniz
│   ├── 03-templateler/
│   │   ├── erc20-gas.md
│   │   ├── erc721-collection.md
│   │   ├── ictt-bridge.md
│   │   ├── soulbound-credential.md
│   │   └── treasury-multisig.md
│   ├── 04-guvenlik.md               # Audit-grade checklist
│   └── 05-katki-sagla.md            # Türkçe katkı rehberi
└── en/                              # İngilizce (Sprint 6'da çeviri)
    └── (mirror of /tr/)
```

---

## Phase 1 Acceptance Criteria

- [ ] 5 template main branch'te tag'li (v0.1.0, …, v0.5.0)
- [ ] Tüm template'ler Fuji testnet'te deploy + Snowtrace verify
- [ ] Forge coverage ≥ %95 / template
- [ ] Slither high/medium = 0
- [ ] Türkçe docs eksiksiz, EN mirror tamam
- [ ] Landing site canlı (GitHub Pages mdbook veya VitePress)
- [ ] ARIA Hub Mersin'de min. 1 atölye
- [ ] Team1 TR / Hürsel partnership görüşmesi tamam
- [ ] Avalanche Builder Hub'da listing PR açıldı
- [ ] Min. 50 GitHub star (organic)
- [ ] SECURITY.md disclosure policy + Immunefi rezervasyonu

---

## Sprint 0 Sonrası Karar Noktaları

- Foundry submodule install (paketler) → forge build yeşil → ilk commit + push
- GitHub repo oluştur (gh CLI auth gerekiyor — Bekir ya da Claude)
- CI iskeleti deploy
- Sprint 1 başlat (ERC-20 Custom Gas)

---

## Notlar

- **Hürsel/Team1 timing:** Phase 1 sonu (Sprint 7). Şu aşamada konuşma yok, ürün önce.
- **Hibe başvurusu:** Phase 1 sonu Retro9000 (production traction + topluluk leaderboard).
- **Audit:** Phase 1 sonu Sherlock contest ($30K) öncesi tüm template'ler Slither + Aderyn + Halmos temiz.
- **Avalanche CLI Windows kurulumu:** Sprint 3 öncesi WSL2 üstüne kurulum.
