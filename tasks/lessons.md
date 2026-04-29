# Lessons Learned — koza-L1

Sprint sırasında karşılaşılan ve gelecekte tekrar etmemek istediğimiz pattern'ler ve düzeltmeler.

## 2026-04-29

### Foundry `vm.setEnv` test'ler arasında ortak state oluşturuyor

**Problem:** Deploy script env-driven yazıldığında, `forge test` çalıştırırken her test kendi `vm.setEnv` çağrılarıyla env değiştiriyor; ama bu değişiklikler **sonraki test'lere taşıyor**. `setUp()` her test öncesi çalışsa da `vm.setEnv` davranışı deterministic değil — Foundry test execution order garanti vermiyor (alfabetik mı, paralel mi belli değil).

**Belirti:**
```
[FAIL: assertion failed: Custom Token != Koza Gas Token]
test_DefaultDeploy_ProducesValidToken
```
Beklenen `"Koza Gas Token"` ama önceki test'in `vm.setEnv("ERC20_NAME", "Custom Token")` çağrısı hâlâ aktif.

**Çözüm:** Script'lere **iki ayrı entry point** ekle:
- `run()` → env'den oku (production: `forge script ... --broadcast`)
- `deploy(...explicit params...)` → public, parametrik (test-friendly)

Test'ler `deploy(...)` direkt çağırır, env'e dokunmaz. Env-driven `run()` integration test ile (gerçek `forge script`) doğrulanır.

**Pattern:**
```solidity
function run() external returns (Token, address) {
    string memory name = vm.envOr("TOKEN_NAME", DEFAULT_NAME);
    // ...
    return deploy(name, ...);
}

function deploy(string memory name, ...) public returns (Token, address) {
    // shared logic
}
```

**Genel kural:** Deploy script'lerini ENV'den izole et. Test edilebilirlik için **parametre alan public fn** her zaman olsun.

### Solidity sürüm pin uyumsuzluğu (foundry.toml ↔ pragma)

**Problem:** `foundry.toml`'da `solc = "0.8.34"` ama dosyalarda `pragma solidity 0.8.35` (linter veya editor auto-fix değiştirmiş olabilir). `forge build` "No solc version exists" hatası verir.

**Çözüm:** İkisini de tutarlı tut. Memory'de Solidity sürüm referansları (memory bank) tek doğruluk noktası.

### CI: Slither ve Aderyn boş `src/` ile çalışmaz

**Problem:** İlk push'ta `src/` boştu. Slither `out/build-info` directory bulamadı, Aderyn `cargo install` upstream `svm-rs-builds` bug'ı yedi.

**Çözüm:**
- Slither/Aderyn job'larına `has_contracts` guard ekle (boş src'de skip)
- Aderyn için `cargo install` yerine **resmi pre-built binary installer** kullan (`Cyfrin/aderyn` releases)

### `bracket_spacing = true` Solidity ekosistem default'una aykırı

**Problem:** `import { ERC20 } from "..."` (boşluklu) Foundry fmt default ama OpenZeppelin/ava-labs ekosistemi boşluksuz yazar (`import {ERC20}`).

**Çözüm:** `foundry.toml` → `[fmt] bracket_spacing = false`

### Constructor'da redundant zero-checks gas waste + audit-grade kalitesini düşürür

**Problem:** Custom `ZeroAddress` ve `ZeroAmount` revert'leri `Ownable(0)` ve `ERC20Capped(0)` parent kontratlarının kendi error'larını fırlatmasından **sonra** çalışmaya çalışıyor → asla ulaşılmıyor.

**Çözüm:** Constructor body'de redundant check yapma. Parent error'larına güven (`OwnableInvalidOwner`, `ERC20InvalidCap`). Custom logic gerektiren check'leri (örn. `initialMint > cap`) bırak.

**Audit-grade prensibi:** "Minimum custom logic" — OZ/ava-labs'in audited primitive'lerine güven, kendi katmanını ince tut.
