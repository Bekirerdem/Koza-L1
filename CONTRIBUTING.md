# Katkıda Bulun — kozalak-l1

`kozalak-l1`'e katkıda bulunmak istediğin için teşekkürler! 🏔️

Bu proje, Türk Solidity geliştiricilerinin Avalanche ekosistemine production-grade kod ile katkı yapması için açık kaynak bir tooling. Hem Türkçe hem İngilizce katkı kabul edilir.

---

## 🎯 Nasıl Katkı Yapabilirsin?

### Code

- Yeni template önerileri (issue aç, tartış)
- Mevcut template'lerde bug fix
- Test coverage iyileştirmeleri
- Gas optimizasyonları (⚠️ güvenlik kalitesinden taviz vermeden)

### Docs

- Türkçe dokümantasyon iyileştirme
- İngilizce çeviri (Phase 1 Sprint 6+)
- Yeni rehberler (bizim ihtiyaçtan eklemediğimiz konularda)
- Örnek deployment senaryoları

### Topluluk

- Issue triage
- PR review
- Soru cevaplama (Discussions)

---

## 🛠️ Geliştirme Akışı

### 1. Fork + Clone

```bash
gh repo fork Bekirerdem/Kozalak-L1 --clone
cd kozalak-l1
forge install
forge build
forge test -vvv
```

### 2. Branch

```bash
git checkout -b feat/your-feature-name
# veya
git checkout -b fix/issue-description
# veya
git checkout -b docs/section-update
```

### 3. Geliştir + Test

Her PR aşağıdaki kontrolleri geçmelidir:

```bash
forge fmt --check       # Formatting
forge build             # Build temiz
forge test --fuzz-runs 10000 -vvv   # Tüm testler geçiyor
forge coverage          # Coverage ≥ %95 (yeni kod için)
slither .               # No high/medium
```

CI bunları otomatik koşturacak ama lokalde de çalıştır.

### 4. Commit

[Conventional Commits](https://www.conventionalcommits.org/) formatı:

```
feat: add ERC-721 royalty support
fix: prevent reentrancy in TokenRemote.receive
docs(tr): translate erc20-gas guide
test: add invariant for treasury timelock
chore: update foundry version
```

Türkçe commit mesajları da kabul edilir, ama `type:` İngilizce kalsın.

### 5. PR Aç

- Net başlık
- Açıklamada: ne yaptın, neden, nasıl test ettin
- Eğer issue'yi kapatıyorsa: `Fixes #123`
- Screenshot/video ekle (UI/CLI değişiklikleri için)

---

## 📐 Solidity Stil Rehberi

### Genel

- **Solidity:** 0.8.34 (kesin pin, daha düşük sürüm yasak)
- **Naming:** `mixedCase` fonksiyonlar, `PascalCase` kontratlar/struct/enum, `UPPER_SNAKE` constants
- **NatSpec:** Public/external fonksiyonlar için zorunlu (`/// @notice`, `/// @param`, `/// @return`)
- **Custom errors:** `require` string yerine zorunlu (`error InsufficientBalance(uint256 available, uint256 required);`)
- **Reentrancy:** External call yapan tüm fonksiyonlarda CEI pattern + `nonReentrant`
- **Access control:** Tüm sensitive fonksiyonlar `Ownable2Step` veya `AccessManager` ile korunmalı
- **OpenZeppelin:** Custom logic yazma, mümkünse OZ inherit

### Yasaklanan

- `unchecked { }` blokları gerekçesiz
- `require("string")` (custom error kullan)
- `tx.origin` (asla)
- `block.timestamp` ile zaman karşılaştırması (manipülasyon riski; kabul edilebilir tolerans varsa OK)
- Inline assembly (sadece dokümante edilmiş, gerekçeli durumlarda)
- `selfdestruct` (Cancun sonrası tehlikeli)

### Test

- Foundry kullanılır (Hardhat değil)
- Her kontrat için unit + invariant + fuzz test
- Test isimleri açıklayıcı: `test_RevertWhen_NotOwner_TransferFails()`

---

## 📚 Dokümantasyon Stil Rehberi

### Türkçe

- **Hedef kitle:** Hackathon-grade Türk geliştiricisi (production'a geçiyor)
- **Ton:** Net, dürüst, "ezbere kabul ettir"meyen — neden böyle yapıldığını açıklar
- **Yapı:** Her doc'ta (1) bu ne işe yarar, (2) hangi Avalanche feature'ını kullanır, (3) nelere dikkat, (4) adım adım örnek, (5) ortak hatalar
- **Kod örnekleri:** Test edilmiş, çalışan
- **Markdown:** GitHub-flavored, KaTeX matematik için

### İngilizce

- Türkçe orijinal sürümün doğrudan çevirisi
- Yerel argo / espri çevirilmez, anlamı aktarılır

---

## 🚦 PR Review Kriterleri

Bir PR aşağıdakileri içermelidir:
- [ ] Tüm CI yeşil
- [ ] Coverage ≥ %95 (yeni kod için)
- [ ] Slither high/medium = 0
- [ ] Aderyn temiz
- [ ] NatSpec eksiksiz
- [ ] CHANGELOG.md güncellendi (kullanıcıyı etkileyen değişiklikler için)
- [ ] Yeni feature için: dokümantasyon
- [ ] Yeni contract için: hem TR hem EN doc

---

## 🤝 Davranış Kuralları

- Saygılı ol
- Dürüst eleştir, savunmacı olma
- Yardım ettikçe öğreniriz
- Türkçe ve İngilizce konuşanları eşit karşılarız

---

## 📞 Sorular

- **Discussions:** Genel sorular, fikir tartışması
- **Issues:** Bug raporu, feature request
- **Email:** Kritik güvenlik için (`SECURITY.md`)

---

## 🙏 Teşekkürler

Her katkı (kod, doc, issue, PR review) önemli. İlk commit'inden itibaren burada anılırsın.

— Bekir Erdem & kozalak-l1 katkıcıları
