# Deployment Rehberi — `kozalak.bekirerdem.dev`

Bu rehber `kozalak-l1` landing site'ının Cloudflare Pages üzerinde nasıl
yayına alınacağını adım adım açıklar.

> **Stack:** Astro 5 (static build) → Cloudflare Pages → CNAME `kozalak.bekirerdem.dev`
> **Deploy yöntemi:** GitHub Actions (`.github/workflows/frontend-deploy.yml`)
> **Tetikleyici:** `frontend/**` altında değişiklik içeren `main` push'ları + manuel `workflow_dispatch`

---

## 1. Cloudflare Pages Projesi Oluştur

İlk seferlik kurulum (sonradan workflow her şeyi otomatik yapar):

1. [dash.cloudflare.com](https://dash.cloudflare.com) → **Workers & Pages** → **Create**
2. **Pages** sekmesi → **Upload assets** (Git bağlama yapma — GitHub Actions kullanacağız)
3. Project name: **`kozalak-l1`** (workflow `--project-name=kozalak-l1` ile push eder, isim eşleşmeli)
4. İlk upload için boş bir `index.html` yükle veya komut satırından oluştur:

```bash
# Yerel ön kurulum (opsiyonel — workflow ilk run'da da kuracak)
cd frontend
npm ci
npm run build
npx wrangler pages project create kozalak-l1 --production-branch=main
npx wrangler pages deploy dist --project-name=kozalak-l1 --branch=main
```

> Bu adımda Cloudflare CLI `kozalak-l1.pages.dev` adresine ilk versiyonu push eder.

---

## 2. GitHub Secrets Ayarla

`Bekirerdem/Kozalak-L1` reposunda → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**:

| Secret İsmi | Nereden Alınır |
|---|---|
| `CLOUDFLARE_API_TOKEN` | dash.cloudflare.com → My Profile → API Tokens → **Create Token** → "Edit Cloudflare Workers" template (veya custom: `Account > Cloudflare Pages > Edit`) |
| `CLOUDFLARE_ACCOUNT_ID` | dash.cloudflare.com → sağ alt panel veya URL'deki `accounts/<id>` |

> **Token kapsamı:** Sadece ilgili account üzerinde `Cloudflare Pages: Edit` yetkisi yeter. Daha geniş yetki vermeye gerek yok.

---

## 3. Custom Domain Bağla

`kozalak.bekirerdem.dev` alt-domainini Pages'e yönlendir:

### 3a. Cloudflare Pages tarafı

1. Pages projesi → **Custom domains** → **Set up a custom domain**
2. Domain: **`kozalak.bekirerdem.dev`** → **Continue**
3. Cloudflare otomatik DNS önerisi sunar:
   - `bekirerdem.dev` zaten Cloudflare'da yönetiliyorsa → **Activate domain** tek tıklama
   - Başka registrar/DNS provider ise → aşağıdaki manuel adıma geç

### 3b. Manuel DNS (eğer `bekirerdem.dev` Cloudflare dışındaysa)

DNS provider'ında bir CNAME kaydı ekle:

```
Type:  CNAME
Name:  koza
Value: kozalak-l1.pages.dev
TTL:   Auto (veya 300)
Proxy: -
```

Yayılma 5-30 dakika sürer. Sonra Cloudflare Pages dashboard'unda
domain "Active" olarak görünür.

### 3c. SSL/TLS

Cloudflare otomatik Let's Encrypt sertifikası sağlar (ücretsiz, otomatik
yenileme). Custom domain "Active" olduktan sonra HTTPS hemen aktif olur.

---

## 4. Deploy Workflow Akışı

`.github/workflows/frontend-deploy.yml` aşağıdaki durumlarda tetiklenir:

- `main`'e push + `frontend/**` veya workflow dosyası değişti
- Manuel: GitHub UI → Actions sekmesi → "Frontend Deploy" → **Run workflow**

Adımlar:

1. `actions/checkout@v5`
2. Node 22 + npm cache (`frontend/package-lock.json` üzerinden)
3. `npm ci` → bağımlılıkları kilit dosyasından kur
4. `npx astro check` → tip + accessibility kontrolü (hata varsa deploy iptal)
5. `npm run build` → `frontend/dist/` static output
6. `cloudflare/wrangler-action@v3` → `wrangler pages deploy dist --project-name=kozalak-l1 --branch=main`

> Build başarısız olursa deploy çalışmaz. Astro check 0 error tutmalı.

---

## 5. Yerel Test

Push'tan önce production build'i yerelde doğrulamak için:

```bash
cd frontend
npm run build
npm run preview
# → http://localhost:4321 üzerinde dist/ servis edilir
```

`astro check` ayrıca yerelde de çalıştırılabilir:

```bash
cd frontend
npx astro check
```

Beklenen çıktı: **0 errors, 0 warnings, 0 hints**.

---

## 6. Rollback

Cloudflare Pages her deploy'u otomatik versiyonlar.

1. dash.cloudflare.com → Pages → `kozalak-l1` → **Deployments** sekmesi
2. Eski bir deploy seç → **...** → **Rollback to this deployment**

İstenirse production branch'i değiştirip eski commit'e dönülebilir.

---

## 7. Sorun Giderme

| Belirti | Çözüm |
|---|---|
| `Error: Authentication error [code: 10000]` | `CLOUDFLARE_API_TOKEN` yetkisi `Pages: Edit` içermiyor — token'ı yeniden oluştur |
| `Project not found` | `--project-name=kozalak-l1` ile dashboard'daki proje adı eşleşmiyor — adı düzelt |
| `kozalak.bekirerdem.dev` SSL pending | DNS yayılması bekleniyor (15-30 dk). `dig kozalak.bekirerdem.dev CNAME` ile doğrula |
| `astro check` CI'da hata | Yerelde `npx astro check` çalıştır, çıktıyı düzelt |
| Deploy başarılı ama site eski içerik | Cloudflare cache → Pages projesi → **Caching** → **Purge cache** |

---

## 8. İleride Değişebilecekler

- **Önizleme deploy'ları:** Pull Request açıldığında preview URL üretmek istenirse `--branch=${{ github.head_ref }}` ile branch deploy aktive edilebilir
- **Custom build env:** Astro `import.meta.env.PUBLIC_*` değişkenleri için workflow'a `env:` bloğu eklenmeli
- **Çoklu domain:** `www.kozalak.bekirerdem.dev` veya `kozalak-l1.com` gibi ek domain'ler Pages dashboard'undan eklenebilir
- **Edge functions:** Astro adapter `@astrojs/cloudflare`'e geçilirse SSR de mümkün — şu an ihtiyaç yok, full static yeterli
