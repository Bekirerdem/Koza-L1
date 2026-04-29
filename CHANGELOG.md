# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Project initialized (Phase 1 Sprint 0, 2026-04-29)
- Foundry config (Solidity 0.8.34, optimizer 200, via_ir, fuzz 10000, invariant 1000)
- Remappings: OpenZeppelin Contracts v5.3+, ava-labs/icm-contracts (Teleporter + ICTT)
- Initial documentation structure (`docs/tr/`, `docs/en/`)
- MIT License
- README seed with Phase 1 template roadmap
- SECURITY.md disclosure policy
- CONTRIBUTING.md (Türkçe + English)
- `.env.example` with Teleporter messenger address
- GitHub Actions CI workflows (build/test/slither/aderyn + release)
- README v2: branding (`koza-L1`), badges (CI, License, Solidity, Foundry, Avalanche, OZ), ASCII architecture diagram, value proposition, Phase 1/2/3 roadmap, "Why Avalanche?" section

### Fixed
- CI: Slither and Aderyn jobs now skip when `src/` has no Solidity files (Sprint 0 → Sprint 1 transition)
- CI: Aderyn switched from `cargo install` (upstream svm-rs-builds bug) to pre-built binary installer
- CI: `actions/checkout` upgraded to v5 (Node 24 compat)
- README: clarified ecosystem positioning (production-grade Türkçe toolkit pozisyonu, "anadilde rehber yok" abartısı düzeltildi)
- `chore(fmt)`: `bracket_spacing=false` to match Solidity ecosystem default

### Added (Sprint 1)
- **Template 1**: `src/templates/erc20-gas/KozaGasToken.sol` — ERC-20 + Capped + Permit + Ownable2Step (audit-grade boilerplate)
- **Tests 1B**: `test/templates/ERC20Gas.t.sol` — 26 unit + fuzz tests covering constructor, mint, burn, ERC-20 standard, ERC-2612 permit (valid/expired/replay), Ownable2Step (transfer, accept, cancel)
- **Invariants 1B**: `test/templates/ERC20Gas.invariants.t.sol` — handler-based stateful fuzzing with 3 invariants (totalSupply ≤ cap, sum(balances) == totalSupply, owner immutable)
- **Coverage**: 100% lines / statements / branches / functions on KozaGasToken.sol
- **Deploy script 1C**: `script/deploy/DeployERC20Gas.s.sol` with two entry points: `run()` (env-driven for `forge script`) and `deploy(...)` (parametric, test-friendly)
- **Smoke tests 1C**: `test/templates/DeployERC20Gas.t.sol` — 3 cases: defaults, custom params, no initial mint
- `tasks/lessons.md` capturing Foundry env state pitfall, solc/pragma pinning, CI guard pattern, OZ-first audit-grade principle
- **Genesis 1D**: `genesis/erc20-gas-token.json` — Avalanche9000 Subnet-EVM genesis with custom native gas token, ICM (Warp) enabled, `contractNativeMinter` and `contractDeployerAllowList` precompile placeholders
- **Genesis 1D docs**: `genesis/README.md` — chainID guidance, allocation hex helpers, multisig admin requirements, mainnet checklist, Avalanche CLI deployment commands
- **Türkçe rehber 1E**: `docs/tr/03-templateler/erc20-gas.md` (295 lines) — kapsamlı deployment guide: ne işe yarar (Senario A/B), Avalanche/Solidity özellikleri, güvenlik uyarıları (multisig owner, immutable cap, permit replay), adım-adım Fuji deploy, ortak hatalar + çözümleri, Foundry test komutları, ICTT bridge'e geçiş öngörüsü

### Coming Soon (Phase 1 Sprints)
- v0.1.0 — ERC-20 + Custom Gas Token template
- v0.2.0 — ERC-721 Collection (allowlist + royalty)
- v0.3.0 — ICTT Cross-L1 Bridge
- v0.4.0 — Soulbound Credential (ERC-5114)
- v0.5.0 — Treasury Multisig + Timelock
- v0.6.0 — EN docs + landing site

---

[Unreleased]: https://github.com/Bekirerdem/koza-l1/compare/HEAD
