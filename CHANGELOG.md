# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-04-29

First public release: Template 1 (ERC-20 + Custom Gas Token) is feature-complete,
fully tested, documented in Türkçe, and **live on Fuji testnet**.

### Live Deployment

- **Network:** Avalanche Fuji Testnet (chain ID 43113)
- **Contract:** `KozaGasToken` at [`0x06451DD4Fb8ebFC19870DacC9568f4364D2A2eB0`](https://testnet.snowtrace.io/address/0x06451DD4Fb8ebFC19870DacC9568f4364D2A2eB0)
- **Owner:** `0x39AEfbC8388da12907A21d9De888B288a9fa5794` (Bekir Erdem deployer EOA, will be migrated to multisig before mainnet)
- **Initial mint:** 100,000 KGAS to owner
- **Cap:** 1,000,000 KGAS

### Verification Status

Snowtrace source verification pending — Routescan free-tier API key blocked by rate-limit / policy. Contract bytecode is live and all read functions confirmed via `cast call` (name, symbol, cap, totalSupply, owner all match expected). To be retried with a personal Snowtrace API key in v0.1.1.

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
- **Avalanche 101 (1F)**: `docs/tr/01-avalanche-101.md` — Türkçe ekosistem girişi: Primary Network 3-chain mimari, Avalanche9000 / Etna upgrade etkileri, Sovereign L1 türleri (Subnet-EVM / HyperSDK / Custom VM), ICM-Teleporter-ICTT katmanları, geliştirici araçları (CLI, AvaCloud, Foundry), hibe programları (Retro9000 $40M, Codebase $250K, Multiverse), Türkiye topluluğu (Team1 TR, SCDEVTR, üniversite kulüpleri)
- **Güvenlik Checklist (1F)**: `docs/tr/04-guvenlik.md` — audit-grade pre-deploy checklist (22 madde), Solidity 0.8.34+ best practices (pragma pin, custom errors, unchecked discipline, ERC-7201 storage), 9 attack vector (reentrancy, integer overflow, oracle manipulation, flash loan, MEV, signature replay, access control, bridge trust, custom bridge yasağı), Foundry test discipline (3 katman, coverage %95+, fuzz run sayıları), 5 araçlı toolchain (Slither/Aderyn/Halmos/Echidna/Mythril), audit stratejisi (Tier 1-2-3), 2025 case studies (Bybit/Cetus/Balancer V2/Sonne/Nemo), AI-generated code uyarısı, operational security (multisig, key discipline, RPC, frontend)

### Added (Sprint 2 — Frontend)

Marketing & landing site for `koza.bekirerdem.dev`. Stack and structure
finalized in collaboration with Gemini 3.1 Pro on UI/UX side; Claude
contributed scaffolding, design tokens, type/lint hygiene, and final
type-error cleanup.

- **Scaffold**: Astro 5 + Tailwind v4 (`@tailwindcss/vite`) + GSAP + Lenis,
  TypeScript strict, Cloudflare Pages-friendly static build
- **Design system** (`src/styles/global.css`):
  - Color tokens: `bg-primary` `#0a0a0a`, `bg-pure`, `bg-card-dark/light`,
    brand `koza-red` / `red-hot` / `red-deep` / `orange`, `koza-blue` /
    `blue-deep`, neutrals + `true-white` / `true-black`
  - Typography: Cabinet Grotesk (Fontshare CDN) for display, Inter
    (`@fontsource/inter` 400-700) for sans
  - **Avax-style chamfer utilities**: `chamfer-tr`, `chamfer-br`, `chamfer-bl`,
    `chamfer-bl-br`, `chamfer-right` — 64px clip-path corner cuts
  - `split-line` / `split-mask` helpers for line-by-line text reveal
- **Layout** (`src/layouts/Layout.astro`): page shell with OG/Twitter meta,
  Cabinet Grotesk preconnect, Lenis smooth-scroll bootstrap (1.2s
  exp-out, smoothWheel)
- **Nav** (`src/components/Nav.astro`): fixed top nav with custom Koza
  wordmark SVG (crystal in red + path-based "Koza" + "-L1" suffix),
  center menu with external arrow indicators, light/dark theme toggle,
  hot-pill "GitHub'da İncele" CTA
- **Hero** (`src/components/Hero.astro`): full-viewport 4-column asymmetric
  grid (1-2-1 ratio) — left col stacks pitch card + Powered-by Avalanche
  gradient card, center spans 2 cols with abstract orbital network SVG
  (central pulsing red core + 3 orbiting nodes with `feGaussianBlur`
  glow), right col with docs + "Koza-L1'i Keşfet" CTA. GSAP timeline
  for entrance + continuous orbital rotation + central pulse
- **Stacking cards** (`src/components/StackingCards.astro`): 5 sticky
  cards with chamfer-tr top-right cut, offset top values (`10vh + index*6.5rem`)
  for visible peek tabs, multi-color rotation (red-deep, blue-deep,
  red-hot, orange, dark), 65/35 horizontal split (number + heading +
  body left, oversized monochrome SVG icon right)
- **Index page** (`src/pages/index.astro`): two-layer scroll trick — z-0
  pinned "WHY KOZA-L1" mega title (`sticky top-0 h-screen`,
  `pointer-events-none`) sits as permanent backdrop while z-10 stacking
  cards scroll over it via `mt-[100vh] pt-[20vh]`. Footer carries Koza
  wordmark + GitHub / Live Contract / Team1 TR / © attribution

### Fixed (Sprint 2 — Frontend)

- `astro check`: 0 errors / 0 warnings / 0 hints
- `astro.config.mjs`: bypass Vite Plugin structural type mismatch between
  Astro 5's pinned Vite and the user-installed Vite that
  `@tailwindcss/vite` resolves against (runtime fully compatible, JSDoc
  cast added)
- `Hero.astro`: removed unused `masterSVG` declaration
- `index.astro`: replaced `<div class="split-line">` inside `<h2>` with
  `<span class="split-line">` (semantic HTML — `<h2>` may not contain
  block-level `<div>`)
- `StackingCards.astro`: replaced arbitrary hex `bg-[#B8232C]` /
  `bg-[#0046C8]` with theme-token utilities `bg-koza-red-deep` /
  `bg-koza-blue-deep` (Tailwind LSP autocomplete now resolves; tokens
  centralized for theme consistency)

### Coming Soon (Phase 1 Sprints)
- v0.1.0 — ERC-20 + Custom Gas Token template ✅
- v0.1.1 — Snowtrace verify retry (Sprint 1G follow-up)
- v0.2.0 — ERC-721 Collection (allowlist + royalty)
- v0.3.0 — ICTT Cross-L1 Bridge
- v0.4.0 — Soulbound Credential (ERC-5114)
- v0.5.0 — Treasury Multisig + Timelock
- v0.6.0 — EN docs + landing site polish

---

[Unreleased]: https://github.com/Bekirerdem/koza-l1/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Bekirerdem/koza-l1/releases/tag/v0.1.0
