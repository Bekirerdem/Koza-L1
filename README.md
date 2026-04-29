<h1 align="center">koza-l1</h1>
<p align="center">
  <strong>Türk geliştiriciler için Avalanche L1 builder toolkit</strong>
</p>
<p align="center">
  Audit-grade Solidity templates · Subnet-EVM · ICTT cross-L1 bridge · Türkçe dokümantasyon
</p>

<p align="center">
  <a href="#-ne-bu">Ne Bu</a> ·
  <a href="#-template-listesi">Template Listesi</a> ·
  <a href="#-hizli-baslangic">Hızlı Başlangıç</a> ·
  <a href="#-guvenlik">Güvenlik</a> ·
  <a href="#-katki">Katkı</a>
</p>

---

## 🎯 Ne Bu

`koza-l1`, Avalanche9000 (Etna) sonrası **Sovereign L1** mimarisi üstüne kurulmuş, Türk geliştiricilere yönelik **audit-grade Solidity template'leri** ve **Türkçe deployment rehberi** sunan açık kaynak bir toolkit.

**Niye var?**
- Avalanche9000 ile L1 kurulumu radikal şekilde ucuzladı (%99 maliyet düşüşü) — ama Türk geliştiriciler için **Türkçe production-grade kaynak yok**
- ICTT (Inter-Chain Token Transfer), Teleporter, Subnet-EVM gibi yeni primitiveler için anadilde rehber bulunmuyor
- Hackathon kalitesinden production-grade'e geçiş için "hazır şablon" eksik

**Kim için?**
- Solo Türk Solidity geliştiricileri
- ARIA Hub, Patika, Kodluyoruz mezunları
- Avalanche'da kendi L1'ini kurmak isteyen küçük ekipler / öğrenci kulüpleri
- Avalanche Foundation grant başvurusu hazırlayanlar

---

## 📦 Template Listesi (Phase 1)

| # | Template | Durum | Açıklama |
|---|---|---|---|
| 1 | **ERC-20 + Custom Gas Token** | 🚧 Geliştiriliyor | Subnet-EVM'in native gas token'i için ERC-20 |
| 2 | **ERC-721 NFT Collection** | ⏳ Planlanıyor | Allowlist (Merkle), royalty (ERC-2981), IPFS |
| 3 | **ICTT Cross-L1 Bridge** | ⏳ Planlanıyor | Avalanche audited ICTT inherit, lock/burn |
| 4 | **Soulbound Credential** | ⏳ Planlanıyor | ERC-5114, eğitim sertifikası, ARIA-uyumlu |
| 5 | **Treasury Multisig + Timelock** | ⏳ Planlanıyor | Safe-uyumlu, AccessManager, role-based |

---

## 🚀 Hızlı Başlangıç

> ⚠️ Phase 1 aktif geliştirmede. Stable release henüz yok.

### Gereksinimler

- [Foundry](https://book.getfoundry.sh/getting-started/installation) (1.5+)
- [Avalanche CLI](https://docs.avax.network/tooling/avalanche-cli) (custom L1 deploy için, opsiyonel)
- Node.js 18+ (frontend için, Phase 3)
- Fuji testnet AVAX → [faucet.avax.network](https://faucet.avax.network/)

### Kurulum

```bash
git clone https://github.com/Bekirerdem/koza-l1.git
cd koza-l1
forge install
forge build
forge test -vvv
```

### Bir Template Deploy Et (Örnek: ERC-20 Custom Gas)

```bash
cp .env.example .env   # PRIVATE_KEY ve diğer değerleri doldur
forge script script/deploy/DeployERC20Gas.s.sol \
    --rpc-url fuji \
    --broadcast \
    --verify
```

---

## 📚 Dokümantasyon

Türkçe ve İngilizce dokümantasyon `/docs/` altında:

- [`docs/tr/00-baslangic.md`](./docs/tr/00-baslangic.md) — Sıfırdan kuruluma rehber
- [`docs/tr/01-avalanche-101.md`](./docs/tr/01-avalanche-101.md) — Avalanche9000, ICM, ICTT, Subnet-EVM özeti
- [`docs/tr/02-l1-deploy.md`](./docs/tr/02-l1-deploy.md) — Kendi L1'ini deploy et
- [`docs/tr/03-templateler/`](./docs/tr/03-templateler/) — Her template için adım adım rehber
- [`docs/tr/04-guvenlik.md`](./docs/tr/04-guvenlik.md) — Audit-grade güvenlik checklist

---

## 🛡️ Güvenlik

Tüm template'ler aşağıdaki güvenlik standartlarına uyar:

- ✅ Solidity ≥ 0.8.34 (IR storage bug fix sonrası)
- ✅ OpenZeppelin Contracts v5.3+ (Ownable2Step, AccessManager, ERC-7201 namespaced storage)
- ✅ Custom errors (gas + audit kalitesi)
- ✅ Foundry fuzz/invariant test (≥ 10000 runs)
- ✅ Slither + Aderyn + Halmos static/symbolic analiz
- ✅ Bug bounty (Phase 1 sonu Immunefi'da canlı)

Güvenlik açığı bildirimi: [`SECURITY.md`](./SECURITY.md) okuyun.

> ⚠️ **Bu kod henüz audit edilmemiştir.** Production deployment öncesi Sherlock veya Cantina contest yapılması planlanıyor (Phase 1 sonu).

---

## 🤝 Katkı

Katkıda bulunmak ister misin? [`CONTRIBUTING.md`](./CONTRIBUTING.md) okuyup başlayabilirsin. Türkçe ve İngilizce katkı kabul edilir.

---

## 📄 Lisans

[MIT](./LICENSE) — Bekir Erdem © 2026

---

## 🙏 Teşekkürler

- [Avalanche Foundation](https://www.avax.network/) — ekosistem ve ICM/ICTT audited contract'lar
- [OpenZeppelin](https://www.openzeppelin.com/) — ekosistem güvenlik standartları
- [Cyfrin Updraft](https://updraft.cyfrin.io/) — Avalanche L1 development materyalleri
- [Team1 Türkiye](https://team1.blog/) — Türkiye'de Avalanche topluluğu

---

<p align="center">
  <em>Türkiye'de Avalanche L1 ekosistemi inşaa ediliyor. 🏔️</em>
</p>
