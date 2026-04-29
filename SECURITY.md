# Security Policy — koza-l1

## ⚠️ Audit Durumu

**Bu kod henüz profesyonel audit'ten geçmemiştir.** Phase 1 sonunda Sherlock veya Cantina contest planlanıyor. O zamana kadar:

- ⛔ Mainnet deploy ÖNERİLMEZ
- ✅ Fuji testnet ve eğitim amaçlı kullanım uygundur
- ✅ Tüm template'ler audited bağımlılıklar (OpenZeppelin, ava-labs/icm-contracts) miras alır

## Güvenlik Açığı Bildirimi

`koza-l1` kodunda bir güvenlik açığı tespit ederseniz lütfen **public issue açmayın**. Aşağıdaki kanallardan birini kullanın:

### Tercih Edilen: Email

📧 **l3ekirerdem@gmail.com**

Konu satırına `[koza-l1 SECURITY]` yazınız.

İçerik:
- Etkilenen dosya / fonksiyon
- Adım adım reproduce
- Etki tahmininiz (low/medium/high/critical)
- Önerdiğiniz fix (varsa)

### Yanıt Süresi

- İlk yanıt: 72 saat içinde
- Triage: 1 hafta içinde
- Fix + disclosure: severity'e göre 7-90 gün

## Bug Bounty

Phase 1 launch sonrası **Immunefi**'da bug bounty programı aktif olacak. Detaylar yakında.

## Dahil Edilmiş Güvenlik Önlemleri

- Solidity ≥ 0.8.34 (IR storage bug fix sonrası)
- OpenZeppelin Contracts v5.3+ (Ownable2Step, AccessManager, ERC-7201 namespaced storage)
- Custom errors (audit kalitesi)
- Foundry fuzz/invariant testing (10000+ runs)
- Slither + Aderyn + Halmos CI
- ICM/Teleporter/ICTT için ava-labs audited kontratları miras alınır (custom bridge yazılmaz)

## Disclosure Policy

Coordinated disclosure tercih edilir. Reporter'lar uygun süre vermeden public açıklama yapmamalıdır. Karşılığında:
- Public credit (isteğe bağlı)
- Hall of Fame listing (yakında)
- Bug bounty (Immunefi açıldıktan sonra)
