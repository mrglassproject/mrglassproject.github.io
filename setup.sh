#!/usr/bin/env bash
# =============================================================================
# Glass Project — Astro setup script
# Uruchom w Codespaces: bash setup.sh
# =============================================================================
set -euo pipefail

# ── Logowanie ────────────────────────────────────────────────────────────────
LOG_FILE="setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1
# Od tej chwili WSZYSTKO (stdout + stderr) trafia jednocześnie:
# - na terminal (widzisz na bieżąco)
# - do setup.log (zostaje po zakończeniu)

# ── Kolory terminala ──────────────────────────────────────────────────────────
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}✓${NC} $1"; }
info()  { echo -e "${BLUE}→${NC} $1"; }
warn()  { echo -e "${YELLOW}!${NC} $1"; }
error() { echo -e "${RED}✗ BŁĄD:${NC} $1"; }

# ── Handler błędów ────────────────────────────────────────────────────────────
on_error() {
  local exit_code=$?
  local line_number=$1
  echo ""
  error "Skrypt zatrzymał się z kodem błędu ${exit_code}"
  error "Linia: ${line_number}"
  error "Szczegóły w pliku: $(pwd)/${LOG_FILE}"
  echo ""
  echo "  Ostatnie 20 linii logu:"
  echo "  ─────────────────────────────────────"
  tail -20 "$LOG_FILE" | sed 's/^/  /'
  echo "  ─────────────────────────────────────"
  echo ""
  warn "Możesz uruchomić skrypt ponownie po naprawieniu problemu."
  warn "Plik ${LOG_FILE} zawiera pełną historię wykonania."
  exit "${exit_code}"
}

# Pułapka — wywołaj on_error przy każdym błędzie, przekaż numer linii
trap 'on_error ${LINENO}' ERR

# ── Znacznik czasu startu ─────────────────────────────────────────────────────
echo "======================================================="
echo "  Setup start: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "  Katalog:     $(pwd)"
echo "  Node:        $(node --version 2>/dev/null || echo 'nie znaleziono')"
echo "  npm:         $(npm --version 2>/dev/null || echo 'nie znaleziono')"
echo "======================================================="
echo ""

echo ""
echo "  Glass Project — Astro 4.x setup"
echo "  ================================"
echo ""

# =============================================================================
# 1. STRUKTURA FOLDERÓW
# =============================================================================
info "Tworzę strukturę folderów..."

mkdir -p .github/workflows
mkdir -p cloudflare-worker/src
mkdir -p cloudflare-worker/assets
mkdir -p public/admin
mkdir -p public/fonts
mkdir -p public/favicons
mkdir -p src/components/portfolio
mkdir -p src/components/workshop
mkdir -p src/components/forms
mkdir -p src/components/ui
mkdir -p src/components/seo
mkdir -p src/config
mkdir -p src/content/posts
mkdir -p src/content/projects
mkdir -p src/content/workshops
mkdir -p src/content/testimonials
mkdir -p src/content/vouchers
mkdir -p src/content/faq
mkdir -p src/data
mkdir -p src/layouts
mkdir -p src/pages/posts
mkdir -p src/styles
mkdir -p src/utils

log "Foldery gotowe"

# =============================================================================
# 2. WYKRYJ AKTUALNE WERSJE PACZEK
# =============================================================================
info "Sprawdzam aktualne wersje paczek npm..."

get_version() {
  npm info "$1" version 2>/dev/null || echo "0.0.0"
}

VER_ASTRO=$(get_version astro)
VER_ALPINE_INT=$(get_version @astrojs/alpinejs)
VER_SITEMAP=$(get_version @astrojs/sitemap)
VER_ALPINE=$(get_version alpinejs)
VER_TYPES_ALPINE=$(get_version @types/alpinejs)
VER_TAILWIND=$(get_version tailwindcss)
VER_TAILWIND_ASTRO=$(get_version @astrojs/tailwind)

echo "  astro:             $VER_ASTRO"
echo "  @astrojs/alpinejs: $VER_ALPINE_INT"
echo "  @astrojs/sitemap:  $VER_SITEMAP"
echo "  alpinejs:          $VER_ALPINE"
echo "  @types/alpinejs:   $VER_TYPES_ALPINE"
echo "  tailwindcss:       $VER_TAILWIND"
echo "  @astrojs/tailwind: $VER_TAILWIND_ASTRO"

# =============================================================================
# 3. PACKAGE.JSON
# =============================================================================
info "Tworzę package.json..."
cat > package.json << EOF
{
  "name": "mrglassproject-com",
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "astro dev",
    "build": "astro build",
    "preview": "astro preview",
    "astro": "astro"
  },
  "dependencies": {
    "astro": "^${VER_ASTRO}",
    "@astrojs/alpinejs": "^${VER_ALPINE_INT}",
    "@astrojs/sitemap": "^${VER_SITEMAP}",
    "@astrojs/tailwind": "^${VER_TAILWIND_ASTRO}",
    "alpinejs": "^${VER_ALPINE}",
    "tailwindcss": "^${VER_TAILWIND}"
  },
  "devDependencies": {
    "@types/alpinejs": "^${VER_TYPES_ALPINE}"
  }
}
EOF
log "package.json gotowy (astro $VER_ASTRO, tailwind $VER_TAILWIND)"

# =============================================================================
# 4. ASTRO CONFIG
# =============================================================================
info "Tworzę astro.config.mjs..."
cat > astro.config.mjs << 'EOF'
import { defineConfig } from 'astro/config';
import alpinejs  from '@astrojs/alpinejs';
import sitemap   from '@astrojs/sitemap';
import tailwind  from '@astrojs/tailwind';

export default defineConfig({
  site: 'https://mrglassproject.github.io',
  base: '/mrglassproject-com',
  integrations: [
    alpinejs(),
    sitemap(),
    tailwind({
      // Tailwind v4 — konfiguracja przez src/styles/global.css (@theme)
      // applyBaseStyles: false wyłącza domyślne style Astro
      // żeby nie kolidowały z naszym global.css
      applyBaseStyles: false,
    }),
  ],
  image: {
    domains: ['res.cloudinary.com'],
  },
  output: 'static',
});
EOF
log "astro.config.mjs gotowy (z Tailwind v4)"

# =============================================================================
# 5. TSCONFIG
# =============================================================================
info "Tworzę tsconfig.json..."
cat > tsconfig.json << 'EOF'
{
  "extends": "astro/tsconfigs/strict",
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@components/*": ["src/components/*"],
      "@layouts/*":    ["src/layouts/*"],
      "@utils/*":      ["src/utils/*"],
      "@config/*":     ["src/config/*"],
      "@styles/*":     ["src/styles/*"]
    }
  }
}
EOF
log "tsconfig.json gotowy"

# =============================================================================
# 6. GITHUB ACTION
# =============================================================================
info "Tworzę GitHub Action..."
cat > .github/workflows/deploy.yml << 'EOF'
name: Deploy to GitHub Pages

on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

concurrency:
  group: pages
  cancel-in-progress: false

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install dependencies
        run: npm ci

      - name: Build Astro
        run: npm run build
        env:
          # Variables — wartości niechronione, widoczne w logach
          PUBLIC_CLOUDINARY_CLOUD_NAME: ${{ vars.PUBLIC_CLOUDINARY_CLOUD_NAME }}
          PUBLIC_FORMSPARK_FORM_ID:     ${{ vars.PUBLIC_FORMSPARK_FORM_ID }}
          # Secrets — zaszyfrowane, niewidoczne w logach
          PUBLIC_CLOUDINARY_API_KEY:    ${{ secrets.PUBLIC_CLOUDINARY_API_KEY }}

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: dist

  deploy:
    name: Deploy
    needs: build
    runs-on: ubuntu-latest
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    steps:
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
EOF
log "GitHub Action gotowy (z Secrets)"

# =============================================================================
# 6. SITE CONFIG
# =============================================================================
info "Tworzę src/config/site.ts..."
cat > src/config/site.ts << 'EOF'
export const SITE = {
  name: 'Glass Project',
  fullName: 'Pracownia Szkła Artystycznego Maciej Rafalski Glass Project',
  description: 'Pracownia szkła artystycznego w Warszawie. Projekty na zamówienie dla firm, hoteli i architektów.',
  url: 'https://mrglassproject.github.io/mrglassproject-com',
  finalUrl: 'https://mrglassproject.com',
  lang: 'pl',
  locale: 'pl_PL',
  themeColor: '#FF8C00',
  bgColor: '#0A0A0B',
  ogImage: 'https://res.cloudinary.com/mrglassproject/image/upload/f_auto,q_auto,w_1200,h_630,c_fill/og-default',
} as const;

export const CONTACT = {
  address: 'ul. Grójecka 79 lok. 7',
  city: '02-094 Warszawa',
  region: 'mazowieckie',
  country: 'PL',
  phone: '+48 500 603 151',
  phoneHref: 'tel:+48500603151',
  email: 'mrglassproject@gmail.com',
  emailHref: 'mailto:mrglassproject@gmail.com',
  nip: '8762371621',
  regon: '387628069',
  hours: 'Poniedziałek–Piątek 8:00–16:00',
  hoursSchema: 'Mo-Fr 08:00-16:00',
  lat: 52.2121751,
  lng: 20.9779826,
  mapsUrl: 'https://maps.app.goo.gl/vXUA1MQB47HWjrjP9',
  mapsEmbed: 'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d2444.7178278804267!2d20.977982600000004!3d52.212175099999996!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x471ecd7dea749169%3A0x37b3ffea814a8560!2sPracownia%20Szk%C5%82a%20Artystycznego%20Maciej%20Rafalski%20Glass%20Project!5e0!3m2!1spl!2spl!4v1770455090382!5m2!1spl!2spl',
} as const;

export const SOCIAL = {
  facebook:   'https://www.facebook.com/p/Mrglassproject-100063557379907/',
  instagram:  'https://www.instagram.com/maciejrafalski_glassproject/',
  tiktok:     'https://www.tiktok.com/@mr_glassproject',
  googleMaps: 'https://maps.app.goo.gl/vXUA1MQB47HWjrjP9',
} as const;

export const CLOUDINARY = {
  cloudName: 'mrglassproject',
  baseUrl: 'https://res.cloudinary.com',
} as const;

export const FORMSPARK = {
  formId: 'TWOJ_FORM_ID',
  url: 'https://submit-form.com',
} as const;

export const NAV = [
  { label: 'Start',         href: '/' },
  { label: 'Moja historia', href: '/about' },
  { label: 'Pracownia',     href: '/pracownia' },
  { label: 'Realizacje',    href: '/portfolio' },
  { label: 'Oferta',        href: '/services' },
  { label: 'FAQ',           href: '/faq' },
  { label: 'Kontakt',       href: '/contact' },
] as const;

export const NAV_CTA = {
  label: 'Warsztaty',
  href: '/workshop',
} as const;

export const FOOTER_NAV = [
  { label: 'Start',               href: '/' },
  { label: 'Oferta',              href: '/services' },
  { label: 'Warsztaty',           href: '/workshop' },
  { label: 'FAQ',                 href: '/faq' },
  { label: 'Kontakt',             href: '/contact' },
  { label: 'Regulamin',           href: '/terms' },
  { label: 'Polityka prywatności', href: '/privacy' },
] as const;
EOF
log "site.ts gotowy"

# =============================================================================
# 7. CLOUDINARY UTILS
# =============================================================================
info "Tworzę src/utils/cloudinary.ts..."
cat > src/utils/cloudinary.ts << 'EOF'
import { CLOUDINARY } from '../config/site';

interface TransformOptions {
  width?:       number;
  height?:      number;
  crop?:        'fill' | 'fit' | 'scale' | 'crop' | 'thumb' | 'pad';
  gravity?:     'auto' | 'face' | 'center' | 'north' | 'south';
  format?:      'auto' | 'webp' | 'avif' | 'jpg' | 'png';
  quality?:     'auto' | 'auto:best' | 'auto:good' | number;
  aspectRatio?: string;
}

export function cloudinaryUrl(publicId: string, opts: TransformOptions = {}): string {
  const {
    width, height, crop = 'fill', gravity = 'auto',
    format = 'auto', quality = 'auto', aspectRatio,
  } = opts;

  const t: string[] = [`f_${format}`, `q_${quality}`];
  if (width)       t.push(`w_${width}`);
  if (height)      t.push(`h_${height}`);
  if (aspectRatio) t.push(`ar_${aspectRatio}`);
  if (width || height || aspectRatio) {
    t.push(`c_${crop}`, `g_${gravity}`);
  }

  return `${CLOUDINARY.baseUrl}/${CLOUDINARY.cloudName}/image/upload/${t.join(',')}/${publicId}`;
}

export function cloudinarySrcset(
  publicId: string,
  widths: number[] = [400, 800, 1200, 1600],
  opts: Omit<TransformOptions, 'width'> = {},
): string {
  return widths.map(w => `${cloudinaryUrl(publicId, { ...opts, width: w })} ${w}w`).join(', ');
}

export const img = {
  hero:          (id: string) => cloudinaryUrl(id, { width: 1200, aspectRatio: '4:3',  crop: 'fill' }),
  section:       (id: string) => cloudinaryUrl(id, { width: 900,  aspectRatio: '4:3',  crop: 'fill' }),
  portfolioCard: (id: string) => cloudinaryUrl(id, { width: 800,  aspectRatio: '4:3',  crop: 'fill' }),
  portfolioFull: (id: string) => cloudinaryUrl(id, { width: 1600, format: 'auto' }),
  postCover:     (id: string) => cloudinaryUrl(id, { width: 1200, aspectRatio: '16:9', crop: 'fill' }),
  postThumb:     (id: string) => cloudinaryUrl(id, { width: 600,  aspectRatio: '16:9', crop: 'fill' }),
  og:            (id: string) => cloudinaryUrl(id, { width: 1200, height: 630,         crop: 'fill' }),
};
EOF
log "cloudinary.ts gotowy"

# =============================================================================
# 8. CONTENT CONFIG
# =============================================================================
info "Tworzę src/content/config.ts..."
cat > src/content/config.ts << 'EOF'
import { defineCollection, z } from 'astro:content';

const posts = defineCollection({
  type: 'content',
  schema: z.object({
    title:     z.string(),
    date:      z.date(),
    excerpt:   z.string(),
    cover:     z.string(),
    published: z.boolean().default(false),
  }),
});

const projects = defineCollection({
  type: 'content',
  schema: z.object({
    title:       z.string(),
    category:    z.enum(['dla-domu', 'dla-firm']),
    images:      z.array(z.string()),
    description: z.string().optional(),
    year:        z.number().optional(),
    dimensions:  z.string().optional(),
    order:       z.number().default(0),
    published:   z.boolean().default(true),
  }),
});

const workshops = defineCollection({
  type: 'content',
  schema: z.object({
    title:          z.string(),
    description:    z.string(),
    duration:       z.string(),
    maxPersons:     z.number(),
    price:          z.number(),
    pricePair:      z.number().optional(),
    pricePairLabel: z.string().optional(),
    level:          z.enum(['fusing', 'podstawowy', 'zaawansowany', 'indywidualny']),
    setmoreUrl:     z.string().url(),
    active:         z.boolean().default(true),
    order:          z.number().default(0),
  }),
});

const testimonials = defineCollection({
  type: 'data',
  schema: z.object({
    name:    z.string(),
    content: z.string(),
    rating:  z.number().min(1).max(5).default(5),
    date:    z.string(),
    source:  z.string().default('Google'),
  }),
});

const vouchers = defineCollection({
  type: 'content',
  schema: z.object({
    title:       z.string(),
    description: z.string(),
    price:       z.number(),
    buyUrl:      z.string().url().optional(),
    active:      z.boolean().default(true),
    order:       z.number().default(0),
  }),
});

const faq = defineCollection({
  type: 'data',
  schema: z.object({
    question: z.string(),
    answer:   z.string(),
    order:    z.number().default(0),
  }),
});

export const collections = { posts, projects, workshops, testimonials, vouchers, faq };
EOF
log "content/config.ts gotowy"

# =============================================================================
# 9. PRZYKŁADOWE DANE — CONTENT
# =============================================================================
info "Tworzę przykładowe dane kolekcji..."

cat > src/content/workshops/fusing.md << 'EOF'
---
title: "Warsztaty z Fusingu"
description: "W trakcie zajęć zaprojektujesz własną pracę, nauczysz się wycinać, szlifować, zdobić i grawerować szkło oraz wypalać je w piecu."
duration: "3 godziny"
maxPersons: 8
price: 390
pricePair: 650
pricePairLabel: "2 os. tylko 650 zł"
level: "fusing"
setmoreUrl: "https://setmore.com/TWOJ_LINK_FUSING"
active: true
order: 1
---
EOF

cat > src/content/workshops/podstawowy.md << 'EOF'
---
title: "Warsztaty ze szkła dmuchanego — poziom podstawowy"
description: "Pod okiem instruktorów stworzysz własny wazon, karafkę lub szklankę, samodzielnie odbijesz ją z piszczeli i umieścisz w odprężarce."
duration: "3 godziny"
maxPersons: 6
price: 450
pricePair: 850
pricePairLabel: "2 os. tylko 850 zł"
level: "podstawowy"
setmoreUrl: "https://setmore.com/TWOJ_LINK_PODSTAWOWY"
active: true
order: 2
---
EOF

cat > src/content/workshops/zaawansowany.md << 'EOF'
---
title: "Warsztaty ze szkła dmuchanego — poziom zaawansowany"
description: "Dzięki pracy na drumli stworzysz szklankę z uchem, kieliszek na nóżce lub inny przedmiot do 30 cm wysokości."
duration: "3 godziny"
maxPersons: 5
price: 600
pricePair: 1000
pricePairLabel: "2 os. tylko 1000 zł"
level: "zaawansowany"
setmoreUrl: "https://setmore.com/TWOJ_LINK_ZAAWANSOWANY"
active: true
order: 3
---
EOF

cat > src/content/workshops/indywidualny.md << 'EOF'
---
title: "Warsztaty ze szkła dmuchanego — indywidualne"
description: "Wydmuchasz i uformujesz własną pracę z bezbarwnego szkła, poznasz techniki zdobienia oraz sposób powstawania pęcherzy powietrza."
duration: "3 godziny"
maxPersons: 1
price: 2000
level: "indywidualny"
setmoreUrl: "https://setmore.com/TWOJ_LINK_INDYWIDUALNY"
active: true
order: 4
---
EOF

cat > src/content/testimonials/marta-nobo.json << 'EOF'
{
  "name": "Marta Nobo",
  "content": "Warsztaty dmuchania szkła prowadzone były w bardzo przyjemnej atmosferze, a jednocześnie na najwyższym, profesjonalnym poziomie. Polecam!",
  "rating": 5,
  "date": "2024-11-15",
  "source": "Google"
}
EOF

cat > src/content/faq/wspolpraca.json << 'EOF'
{
  "question": "Jak wygląda współpraca?",
  "answer": "Każdy projekt zaczyna się od rozmowy — krótkiej, bez zobowiązań. Opisz czego potrzebujesz: przeznaczenie obiektu, przybliżony wymiar, budżet. Po zebraniu informacji przesyłam indywidualną wycenę, zwykle w ciągu 2–3 dni roboczych.",
  "order": 1
}
EOF

cat > src/content/faq/cena.json << 'EOF'
{
  "question": "Ile kosztuje wykonanie obiektu na zamówienie?",
  "answer": "Nie mamy stałego cennika — każdy obiekt powstaje ręcznie. Proste formy użytkowe od kilkuset zł, obiekty dekoracyjne od 1000–2000 zł, instalacje i projekty architektoniczne — indywidualnie. Wycena jest bezpłatna.",
  "order": 2
}
EOF

cat > src/content/projects/wazon-1.md << 'EOF'
---
title: "Wazon dmuchany — forma organiczna"
category: "dla-domu"
images:
  - "glassproject/projects/wazon-1"
description: "Ręcznie formowany wazon z recyklowanego szkła."
year: 2024
order: 1
published: true
---
EOF

cat > src/content/projects/instalacja-hotel.md << 'EOF'
---
title: "Instalacja świetlna — lobby hotelowe"
category: "dla-firm"
images:
  - "glassproject/projects/instalacja-hotel-1"
  - "glassproject/projects/instalacja-hotel-2"
description: "Szklana instalacja do przestrzeni komercyjnej."
year: 2024
order: 1
published: true
---
EOF

cat > src/data/settings.json << 'EOF'
{
  "phone": "+48 500 603 151",
  "email": "mrglassproject@gmail.com",
  "address": "ul. Grójecka 79 lok. 7, 02-094 Warszawa",
  "hours": "Poniedziałek–Piątek 8:00–16:00",
  "social": {
    "facebook": "https://www.facebook.com/p/Mrglassproject-100063557379907/",
    "instagram": "https://www.instagram.com/maciejrafalski_glassproject/",
    "tiktok": "https://www.tiktok.com/@mr_glassproject",
    "googlemaps": "https://maps.app.goo.gl/vXUA1MQB47HWjrjP9"
  },
  "clients": [
    "OBI",
    "Wasalaa",
    "Le Collet",
    "AD 100",
    "MedEstelle Institute",
    "LUX MED"
  ]
}
EOF

log "Przykładowe dane gotowe"

# =============================================================================
# 10. GLOBAL CSS
# =============================================================================
info "Tworzę src/styles/global.css (Tailwind v4)..."
cat > src/styles/global.css << 'EOF'
/* ============================================
   Glass Project — Global Styles
   Tailwind CSS v4
   ============================================ */

@import "tailwindcss";

/* ── Tailwind v4: konfiguracja przez @theme ─────────────────────────────── */
@theme {
  /* Kolory marki */
  --color-glass-black:      #0A0A0B;
  --color-glass-anthracite: #161618;
  --color-glass-border:     #26262B;
  --color-glass-smoke:      #3E3E42;
  --color-glass-white:      #F4F4F5;
  --color-glass-muted:      #A1A1AA;

  /* Akcenty */
  --color-glass-accent-amber: #FF8C00;
  --color-glass-accent-glow:  #FFC24A;
  --color-glass-accent-fire:  #E25822;
  --color-glass-accent-cool:  #7FD1C7;

  /* Fonty */
  --font-sans:    'Inter', system-ui, sans-serif;
  --font-serif:   'Libre Baskerville', Georgia, serif;
  --font-heading: 'Libre Baskerville', Georgia, serif;
  --font-body:    'Inter', system-ui, sans-serif;
  --font-mono:    'JetBrains Mono', 'Fira Code', monospace;

  /* Breakpointy — standardowe Tailwind */
  --breakpoint-sm:  640px;
  --breakpoint-md:  768px;
  --breakpoint-lg:  1024px;
  --breakpoint-xl:  1280px;
  --breakpoint-2xl: 1536px;
}

/* ── Fonty Google ────────────────────────────────────────────────────────── */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Libre+Baskerville:wght@400;700&display=swap');

/* ── Reset i base ────────────────────────────────────────────────────────── */
@layer base {
  *, *::before, *::after {
    box-sizing: border-box;
  }

  html {
    scroll-behavior: smooth;
    -webkit-text-size-adjust: 100%;
  }

  body {
    background-color: var(--color-glass-black);
    color: var(--color-glass-white);
    font-family: var(--font-sans);
    font-size: 1rem;
    line-height: 1.7;
    -webkit-font-smoothing: antialiased;
    -moz-osx-font-smoothing: grayscale;
  }

  h1, h2, h3, h4, h5, h6 {
    font-family: var(--font-heading);
    font-weight: 500;
    line-height: 1.2;
  }

  :focus-visible {
    outline: 2px solid var(--color-glass-accent-amber);
    outline-offset: 2px;
  }

  /* Scrollbar — dark style */
  ::-webkit-scrollbar        { width: 6px; }
  ::-webkit-scrollbar-track  { background: var(--color-glass-black); }
  ::-webkit-scrollbar-thumb  { background: var(--color-glass-border); border-radius: 3px; }
  ::-webkit-scrollbar-thumb:hover { background: var(--color-glass-smoke); }
}

/* ── Komponenty ──────────────────────────────────────────────────────────── */
@layer components {

  /* Gradient tekstu — nagłówki */
  .text-gradient {
    background: linear-gradient(to right, #f3f4f6, #e5e7eb, #d1d5db);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  /* Gradient tekstu — akcent amber */
  .text-gradient-amber {
    background: linear-gradient(to right, #FF8C00, #FFC24A);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  /* Padding sekcji — spójny rytm pionowy */
  .section-py {
    padding-top: 5rem;
    padding-bottom: 5rem;
    @media (min-width: 1024px) {
      padding-top: 7rem;
      padding-bottom: 7rem;
    }
  }

  /* Wrapper zdjęcia — standard dla całego serwisu */
  .img-wrapper {
    padding: 4px;
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 1rem;
  }

  .img-wrapper img {
    width: 100%;
    display: block;
    border-radius: 0.75rem;
    border: 1px solid var(--color-glass-border);
  }

  /* Wrapper zdjęcia z bluram dekoracyjnym (sekcje narracyjne) */
  .img-wrapper-glow {
    position: relative;
    padding: 4px;
    border: 1px solid rgba(255, 255, 255, 0.2);
    border-radius: 1rem;
  }

  .img-wrapper-glow::before {
    content: '';
    position: absolute;
    inset: 0;
    border-radius: inherit;
    background: linear-gradient(to right, rgb(147 51 234 / 0.2), rgb(126 34 206 / 0.2));
    filter: blur(40px);
    z-index: -1;
  }

  .img-wrapper-glow img {
    width: 100%;
    display: block;
    border-radius: 0.75rem;
    border: 1px solid var(--color-glass-border);
  }

  /* Przycisk główny — amber CTA */
  .btn-primary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background-color: var(--color-glass-accent-amber);
    color: var(--color-glass-black);
    font-size: 0.875rem;
    font-weight: 600;
    border-radius: 9999px;
    border: none;
    cursor: pointer;
    text-decoration: none;
    transition: background-color 0.2s, box-shadow 0.2s;
  }

  .btn-primary:hover {
    background-color: var(--color-glass-accent-glow);
    box-shadow: 0 0 24px rgba(255, 140, 0, 0.2);
  }

  /* Przycisk drugorzędny — outline */
  .btn-secondary {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background-color: transparent;
    color: var(--color-glass-white);
    font-size: 0.875rem;
    font-weight: 600;
    border-radius: 9999px;
    border: 1px solid var(--color-glass-border);
    cursor: pointer;
    text-decoration: none;
    transition: border-color 0.2s, color 0.2s;
  }

  .btn-secondary:hover {
    border-color: rgba(255, 255, 255, 0.5);
    color: var(--color-glass-white);
  }

  /* Przycisk biały — dla ciemnych sekcji CTA */
  .btn-white {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background-color: var(--color-glass-white);
    color: var(--color-glass-black);
    font-size: 0.875rem;
    font-weight: 600;
    border-radius: 9999px;
    border: none;
    cursor: pointer;
    text-decoration: none;
    transition: background-color 0.2s;
  }

  .btn-white:hover {
    background-color: #e4e4e7;
  }

  /* Karta — surface z borderem */
  .card {
    background-color: var(--color-glass-anthracite);
    border: 1px solid var(--color-glass-border);
    border-radius: 1rem;
    padding: 1.5rem;
  }

  /* Karta z gradientem tła — opinie, FAQ */
  .card-warm {
    background: linear-gradient(
      to top,
      rgb(23 23 23),
      rgb(69 26 3 / 0.6)
    );
    border: 1px solid rgba(255, 255, 255, 0.1);
    border-radius: 1rem;
    padding: 1.5rem;
  }

  /* Divider */
  .divider {
    border: none;
    border-top: 1px solid var(--color-glass-border);
  }

  /* Formularz — input */
  .form-input {
    width: 100%;
    padding: 0.75rem;
    background-color: #171717;
    border: 1px solid var(--color-glass-border);
    border-radius: 0.5rem;
    color: var(--color-glass-white);
    font-size: 1rem;
    font-family: var(--font-sans);
    transition: border-color 0.2s;
    resize: vertical;
  }

  .form-input::placeholder {
    color: var(--color-glass-smoke);
  }

  .form-input:hover  { border-color: rgba(255, 255, 255, 0.3); }
  .form-input:focus  { outline: none; border-color: rgba(255, 255, 255, 0.5); }

  /* Badge — label kategorii */
  .badge {
    display: inline-block;
    padding: 0.25rem 0.75rem;
    font-size: 0.75rem;
    font-weight: 500;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    border-radius: 9999px;
    border: 1px solid var(--color-glass-border);
    color: var(--color-glass-muted);
  }

  .badge-amber {
    border-color: rgba(255, 140, 0, 0.3);
    color: var(--color-glass-accent-amber);
    background: rgba(255, 140, 0, 0.08);
  }
}

/* ── Utilities custom ────────────────────────────────────────────────────── */
@layer utilities {

  /* Tło sekcji — ciemniejszy gradient */
  .bg-section-dark {
    background: linear-gradient(
      to right,
      var(--color-glass-black),
      #0f0f10,
      var(--color-glass-black)
    );
  }

  /* Blur dekoracyjny — purple glow za zdjęciami */
  .glow-purple {
    position: relative;
  }

  .glow-purple::before {
    content: '';
    position: absolute;
    inset: 0;
    background: linear-gradient(to right, rgb(126 34 206 / 0.2), rgb(88 28 135 / 0.2));
    filter: blur(48px);
    border-radius: inherit;
    z-index: -1;
  }

  /* Blur dekoracyjny — amber glow */
  .glow-amber {
    position: relative;
  }

  .glow-amber::before {
    content: '';
    position: absolute;
    inset: 0;
    background: rgba(255, 140, 0, 0.15);
    filter: blur(48px);
    border-radius: inherit;
    z-index: -1;
  }

  /* Tekst accent amber */
  .text-amber { color: var(--color-glass-accent-amber); }
  .text-cool  { color: var(--color-glass-accent-cool); }
  .text-fire  { color: var(--color-glass-accent-fire); }
  .text-muted { color: var(--color-glass-muted); }
}
EOF
log "global.css gotowy (Tailwind v4)"

# =============================================================================
# 11. BASE HEAD COMPONENT
# =============================================================================
info "Tworzę src/components/BaseHead.astro..."
cat > src/components/BaseHead.astro << 'ASTROEOF'
---
import { SITE, CONTACT, CLOUDINARY } from '../config/site';
import { img } from '../utils/cloudinary';

interface Props {
  title?:       string;
  description?: string;
  ogImage?:     string;
  ogType?:      'website' | 'article';
  canonical?:   string;
  noindex?:     boolean;
  jsonLd?:      object | object[];
}

const {
  title,
  description = SITE.description,
  ogImage     = SITE.ogImage,
  ogType      = 'website',
  canonical,
  noindex     = false,
  jsonLd,
} = Astro.props;

const pageTitle  = title ? `${title} — ${SITE.name}` : `${SITE.name} — Pracownia Szkła Artystycznego`;
const pageUrl    = canonical ?? new URL(Astro.url.pathname, SITE.url).href;
const currentUrl = new URL(Astro.url.pathname, SITE.url).href;

/* ── JSON-LD: Organization + LocalBusiness (globalne) ─────────────────── */
const orgJsonLd = {
  '@context':   'https://schema.org',
  '@type':      ['Organization', 'LocalBusiness', 'ArtGallery'],
  '@id':        `${SITE.finalUrl}/#organization`,
  name:         SITE.fullName,
  alternateName:'Glass Project',
  url:          SITE.finalUrl,
  logo: {
    '@type': 'ImageObject',
    url:     `${SITE.url}/favicons/icon-512.png`,
    width:   512,
    height:  512,
  },
  image: {
    '@type': 'ImageObject',
    url:     img.og('glassproject/pracownia-placeholder'),
    width:   1200,
    height:  900,
  },
  description:  SITE.description,
  telephone:    CONTACT.phone,
  email:        CONTACT.email,
  address: {
    '@type':           'PostalAddress',
    streetAddress:     CONTACT.address,
    addressLocality:   'Warszawa',
    addressRegion:     CONTACT.region,
    postalCode:        '02-094',
    addressCountry:    CONTACT.country,
  },
  geo: {
    '@type':     'GeoCoordinates',
    latitude:    CONTACT.lat,
    longitude:   CONTACT.lng,
  },
  openingHours:  CONTACT.hoursSchema,
  hasMap:        CONTACT.mapsUrl,
  sameAs: [
    'https://www.facebook.com/p/Mrglassproject-100063557379907/',
    'https://www.instagram.com/maciejrafalski_glassproject/',
    'https://www.tiktok.com/@mr_glassproject',
  ],
  currenciesAccepted: 'PLN',
  paymentAccepted:    'Cash, Credit Card, Bank Transfer',
  areaServed: {
    '@type': 'City',
    name:    'Warszawa',
  },
  priceRange: '$$',
};

/* ── JSON-LD: WebSite (globalne) ───────────────────────────────────────── */
const websiteJsonLd = {
  '@context': 'https://schema.org',
  '@type':    'WebSite',
  '@id':      `${SITE.finalUrl}/#website`,
  url:        SITE.finalUrl,
  name:       SITE.name,
  description: SITE.description,
  inLanguage: 'pl-PL',
  publisher: {
    '@id': `${SITE.finalUrl}/#organization`,
  },
};

const allJsonLd = [
  orgJsonLd,
  websiteJsonLd,
  ...(jsonLd ? (Array.isArray(jsonLd) ? jsonLd : [jsonLd]) : []),
];
---

<!-- Charset & viewport — HTML5 standard -->
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="X-UA-Compatible" content="IE=edge">

<!-- Primary meta -->
<title>{pageTitle}</title>
<meta name="description" content={description}>
<meta name="generator" content={Astro.generator}>
<link rel="canonical" href={pageUrl}>
{noindex && <meta name="robots" content="noindex, nofollow">}

<!-- Open Graph -->
<meta property="og:type"        content={ogType}>
<meta property="og:url"         content={currentUrl}>
<meta property="og:title"       content={pageTitle}>
<meta property="og:description" content={description}>
<meta property="og:image"       content={ogImage}>
<meta property="og:image:width"  content="1200">
<meta property="og:image:height" content="630">
<meta property="og:image:alt"    content={pageTitle}>
<meta property="og:locale"       content={SITE.locale}>
<meta property="og:site_name"    content={SITE.name}>

<!-- Twitter / X Card -->
<meta name="twitter:card"        content="summary_large_image">
<meta name="twitter:title"       content={pageTitle}>
<meta name="twitter:description" content={description}>
<meta name="twitter:image"       content={ogImage}>

<!-- Favicona — pełny zestaw -->
<link rel="icon"             href="/favicons/favicon.ico" sizes="32x32">
<link rel="icon"             href="/favicons/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/favicons/apple-touch-icon.png">
<link rel="manifest"         href="/favicons/manifest.webmanifest">
<meta name="theme-color"     content="#FF8C00">
<meta name="msapplication-TileColor" content="#0A0A0B">

<!-- Preconnect — fonty -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="preconnect" href="https://res.cloudinary.com">

<!-- Global CSS -->
<link rel="stylesheet" href="/styles/global.css">

<!-- JSON-LD -->
{allJsonLd.map(schema => (
  <script type="application/ld+json" set:html={JSON.stringify(schema, null, 0)} />
))}
ASTROEOF
log "BaseHead.astro gotowy"

# =============================================================================
# 12. BASE LAYOUT
# =============================================================================
info "Tworzę src/layouts/BaseLayout.astro..."
cat > src/layouts/BaseLayout.astro << 'ASTROEOF'
---
import BaseHead from '../components/BaseHead.astro';
import Header   from '../components/Header.astro';
import Footer   from '../components/Footer.astro';
import GTranslate from '../components/GTranslate.astro';

interface Props {
  title?:       string;
  description?: string;
  ogImage?:     string;
  ogType?:      'website' | 'article';
  canonical?:   string;
  noindex?:     boolean;
  jsonLd?:      object | object[];
}

const props = Astro.props;
---

<!doctype html>
<html lang="pl">
  <head>
    <BaseHead {...props} />
  </head>
  <body class="antialiased">
    <Header />
    <main id="main-content">
      <slot />
    </main>
    <Footer />
    <GTranslate />
  </body>
</html>
ASTROEOF
log "BaseLayout.astro gotowy"

# =============================================================================
# 13. POST LAYOUT
# =============================================================================
info "Tworzę src/layouts/PostLayout.astro..."
cat > src/layouts/PostLayout.astro << 'ASTROEOF'
---
import BaseLayout from './BaseLayout.astro';
import { img }    from '../utils/cloudinary';

interface Props {
  title:       string;
  date:        Date;
  excerpt:     string;
  cover:       string;
}

const { title, date, excerpt, cover } = Astro.props;

const dateStr = date.toLocaleDateString('pl-PL', {
  year: 'numeric', month: 'long', day: 'numeric',
});

const jsonLd = {
  '@context':     'https://schema.org',
  '@type':        'BlogPosting',
  headline:       title,
  description:    excerpt,
  image:          img.postCover(cover),
  datePublished:  date.toISOString(),
  dateModified:   date.toISOString(),
  author: {
    '@type': 'Person',
    name:    'Maciej Rafalski',
    url:     'https://mrglassproject.com/about',
  },
  publisher: {
    '@type': 'Organization',
    name:    'Glass Project',
    logo: {
      '@type': 'ImageObject',
      url:     'https://mrglassproject.com/favicons/icon-512.png',
    },
  },
};
---

<BaseLayout
  title={title}
  description={excerpt}
  ogImage={img.og(cover)}
  ogType="article"
  jsonLd={jsonLd}
>
  <article class="section-py">
    <div class="container">
      <div style="max-width: 768px; margin: 0 auto;">
        <header style="margin-bottom: 2rem;">
          <time datetime={date.toISOString()} style="color: var(--color-text-muted); font-size: 0.875rem;">
            {dateStr}
          </time>
          <h1 style="margin-top: 0.5rem; font-size: clamp(1.75rem, 4vw, 3rem); font-weight: 500;" class="text-gradient">
            {title}
          </h1>
          <p style="color: var(--color-text-secondary); font-size: 1.125rem; margin-top: 1rem;">
            {excerpt}
          </p>
        </header>

        {cover && (
          <figure style="margin-bottom: 3rem;">
            <div class="img-wrapper">
              <img
                src={img.postCover(cover)}
                alt={title}
                width="1200"
                height="675"
                loading="eager"
                decoding="async"
              >
            </div>
          </figure>
        )}

        <div class="prose">
          <slot />
        </div>
      </div>
    </div>
  </article>
</BaseLayout>
ASTROEOF
log "PostLayout.astro gotowy"

# =============================================================================
# 14. HEADER COMPONENT
# =============================================================================
info "Tworzę src/components/Header.astro..."
cat > src/components/Header.astro << 'ASTROEOF'
---
import { NAV, NAV_CTA, SITE } from '../config/site';

const currentPath = Astro.url.pathname;
const isActive = (href: string) => {
  if (href === '/') return currentPath === '/' || currentPath === '/mrglassproject-com/';
  return currentPath.startsWith(href);
};
---

<header>
  <div
    x-data="{ open: false }"
    class="nav-wrapper"
  >
    <div class="container">
      <nav aria-label="Nawigacja główna">
        <!-- Logo -->
        <a href="/" class="nav-logo" aria-label={SITE.fullName}>
          <img
            src="/images/logo-glassproject-500x175px.webp"
            alt={`${SITE.name} — logo`}
            width="128"
            height="45"
            loading="eager"
            decoding="async"
          >
        </a>

        <!-- Desktop nav -->
        <ul class="nav-list" role="list">
          {NAV.map(({ label, href }) => (
            <li>
              <a
                href={href}
                class:list={['nav-link', { 'nav-link--active': isActive(href) }]}
                aria-current={isActive(href) ? 'page' : undefined}
              >
                {label}
              </a>
            </li>
          ))}
        </ul>

        <!-- CTA -->
        <a href={NAV_CTA.href} class="nav-cta" aria-label={`${NAV_CTA.label} — zarezerwuj miejsce`}>
          {NAV_CTA.label}
        </a>

        <!-- Mobile toggle -->
        <button
          class="nav-toggle"
          x-on:click="open = !open"
          x-bind:aria-expanded="open.toString()"
          aria-controls="mobile-menu"
          aria-label="Otwórz menu"
        >
          <svg width="24" height="24" fill="currentColor" aria-hidden="true" viewBox="0 0 20 20">
            <path d="M0 3h20v2H0V3zm0 6h20v2H0V9zm0 6h20v2H0v-2z"/>
          </svg>
        </button>
      </nav>
    </div>

    <!-- Mobile menu overlay -->
    <div
      id="mobile-menu"
      x-show="open"
      x-transition:enter="transition ease-out duration-200"
      x-transition:enter-start="opacity-0"
      x-transition:enter-end="opacity-100"
      x-transition:leave="transition ease-in duration-150"
      x-transition:leave-start="opacity-100"
      x-transition:leave-end="opacity-0"
      class="mobile-overlay"
      x-on:click="open = false"
      aria-hidden="true"
    ></div>

    <nav
      id="mobile-nav"
      x-show="open"
      x-transition:enter="transition ease-out duration-200"
      x-transition:enter-start="opacity-0 -translate-x-4"
      x-transition:enter-end="opacity-100 translate-x-0"
      x-transition:leave="transition ease-in duration-150"
      x-transition:leave-start="opacity-100 translate-x-0"
      x-transition:leave-end="opacity-0 -translate-x-4"
      class="mobile-nav"
      aria-label="Nawigacja mobilna"
    >
      <div class="mobile-nav__header">
        <a href="/" aria-label={SITE.fullName}>
          <img
            src="/images/logo-glassproject-500x175px.webp"
            alt={`${SITE.name} — logo`}
            width="128"
            height="45"
            loading="lazy"
            decoding="async"
          >
        </a>
        <button
          x-on:click="open = false"
          aria-label="Zamknij menu"
        >
          <svg width="24" height="24" fill="none" stroke="currentColor" aria-hidden="true" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <ul role="list" style="list-style: none; padding: 0; margin: 0;">
        {NAV.map(({ label, href }) => (
          <li>
            <a
              href={href}
              class:list={['mobile-nav__link', { 'mobile-nav__link--active': isActive(href) }]}
              aria-current={isActive(href) ? 'page' : undefined}
              x-on:click="open = false"
            >
              {label}
            </a>
          </li>
        ))}
      </ul>

      <div class="mobile-nav__footer">
        <a href={NAV_CTA.href} class="nav-cta" style="display: block; text-align: center;">
          {NAV_CTA.label}
        </a>
      </div>
    </nav>
  </div>
</header>

<style>
  .nav-wrapper {
    position: relative;
  }

  nav {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 2rem 0;
    gap: 1rem;
  }

  .nav-logo img {
    display: block;
    width: 8rem;
    height: auto;
  }

  .nav-list {
    display: none;
    list-style: none;
    padding: 0;
    margin: 0 auto 0 0;
    margin-left: auto;
    margin-right: 2rem;
    gap: 2rem;
  }

  @media (min-width: 1024px) {
    .nav-list { display: flex; align-items: center; }
    .nav-toggle { display: none; }
  }

  .nav-link {
    font-size: 0.875rem;
    font-weight: 500;
    color: var(--color-text-secondary);
    text-decoration: none;
    transition: color 0.2s;
  }
  .nav-link:hover,
  .nav-link--active {
    color: var(--color-text-primary);
  }

  .nav-cta {
    display: none;
    padding: 0.75rem 1.5rem;
    font-size: 0.875rem;
    font-weight: 600;
    color: #0A0A0B;
    background-color: var(--color-accent);
    border-radius: 9999px;
    text-decoration: none;
    transition: background-color 0.2s;
    white-space: nowrap;
  }
  .nav-cta:hover { background-color: var(--color-accent-hover); }

  @media (min-width: 1024px) {
    .nav-cta { display: inline-flex; align-items: center; }
  }

  .nav-toggle {
    display: flex;
    align-items: center;
    justify-content: center;
    background: none;
    border: none;
    cursor: pointer;
    color: var(--color-text-secondary);
    transition: color 0.2s;
  }
  .nav-toggle:hover { color: var(--color-text-primary); }

  @media (min-width: 1024px) {
    .nav-toggle { display: none; }
  }

  /* Mobile overlay */
  .mobile-overlay {
    position: fixed;
    inset: 0;
    background: rgba(10,10,11,0.8);
    z-index: 40;
  }

  /* Mobile nav panel */
  .mobile-nav {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    width: 83.333%;
    max-width: 24rem;
    z-index: 50;
    background-color: var(--color-bg-surface);
    border-right: 1px solid var(--color-border);
    display: flex;
    flex-direction: column;
    padding: 1.5rem;
    overflow-y: auto;
  }

  .mobile-nav__header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 3rem;
  }

  .mobile-nav__header button {
    background: none;
    border: none;
    cursor: pointer;
    color: var(--color-text-secondary);
    transition: color 0.2s;
  }
  .mobile-nav__header button:hover { color: var(--color-text-primary); }

  .mobile-nav__link {
    display: block;
    padding: 1rem;
    font-size: 0.875rem;
    font-weight: 600;
    color: var(--color-text-secondary);
    text-decoration: none;
    border-radius: 0.5rem;
    transition: color 0.2s, background-color 0.2s;
    margin-bottom: 0.25rem;
  }
  .mobile-nav__link:hover,
  .mobile-nav__link--active {
    color: var(--color-text-primary);
    background-color: var(--color-bg);
  }

  .mobile-nav__footer {
    margin-top: auto;
    padding-top: 1.5rem;
  }
</style>
ASTROEOF
log "Header.astro gotowy"

# =============================================================================
# 15. FOOTER COMPONENT
# =============================================================================
info "Tworzę src/components/Footer.astro..."
cat > src/components/Footer.astro << 'ASTROEOF'
---
import { SITE, CONTACT, SOCIAL, FOOTER_NAV } from '../config/site';

const year = new Date().getFullYear();
---

<footer>
  <div class="container">

    <!-- Top: logo + opis + social -->
    <div class="footer__top">
      <div class="footer__brand">
        <a href="/" aria-label={SITE.fullName}>
          <img
            src="/images/logo-glassproject-500x175px.webp"
            alt={`${SITE.name} — logo`}
            width="128"
            height="45"
            loading="lazy"
            decoding="async"
          >
        </a>
        <p class="footer__tagline">
          Pracownia szkła artystycznego w Warszawie.<br>
          Projekty na zamówienie dla firm, hoteli i architektów.
        </p>
      </div>

      <!-- Dane kontaktowe -->
      <address class="footer__contact">
        <p>{CONTACT.address}</p>
        <p>{CONTACT.city}</p>
        <p>
          <a href={CONTACT.phoneHref}>{CONTACT.phone}</a>
        </p>
        <p>
          <a href={CONTACT.emailHref}>{CONTACT.email}</a>
        </p>
        <p>{CONTACT.hours}</p>
      </address>
    </div>

    <hr class="footer__divider">

    <!-- Bottom: nawigacja + social + copyright -->
    <div class="footer__bottom">
      <!-- Nav -->
      <nav aria-label="Nawigacja w stopce">
        <ul role="list" class="footer__nav">
          {FOOTER_NAV.map(({ label, href }) => (
            <li>
              <a href={href} class="footer__nav-link">{label}</a>
            </li>
          ))}
        </ul>
      </nav>

      <!-- Social -->
      <div class="footer__social">
        {SOCIAL.facebook && (
          <a href={SOCIAL.facebook} target="_blank" rel="noopener noreferrer" class="footer__social-link" aria-label="Facebook">
            <svg width="20" height="20" fill="currentColor" aria-hidden="true" viewBox="0 0 24 24">
              <path d="M18 2h-3a5 5 0 0 0-5 5v3H7v4h3v8h4v-8h3l1-4h-4V7a1 1 0 0 1 1-1h3z"/>
            </svg>
          </a>
        )}
        {SOCIAL.instagram && (
          <a href={SOCIAL.instagram} target="_blank" rel="noopener noreferrer" class="footer__social-link" aria-label="Instagram">
            <svg width="20" height="20" fill="currentColor" aria-hidden="true" viewBox="0 0 24 24">
              <path fill-rule="evenodd" d="M3 8a5 5 0 0 1 5-5h8a5 5 0 0 1 5 5v8a5 5 0 0 1-5 5H8a5 5 0 0 1-5-5V8Zm5-3a3 3 0 0 0-3 3v8a3 3 0 0 0 3 3h8a3 3 0 0 0 3-3V8a3 3 0 0 0-3-3H8Zm7.597 2.214a1 1 0 0 1 1-1h.01a1 1 0 1 1 0 2h-.01a1 1 0 0 1-1-1ZM12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6Zm-5 3a5 5 0 1 1 10 0 5 5 0 0 1-10 0Z" clip-rule="evenodd"/>
            </svg>
          </a>
        )}
        {SOCIAL.tiktok && (
          <a href={SOCIAL.tiktok} target="_blank" rel="noopener noreferrer" class="footer__social-link" aria-label="TikTok">
            <svg width="20" height="20" fill="currentColor" aria-hidden="true" viewBox="0 0 24 24">
              <path d="M12.4381 2.01667C13.5298 2 14.6131 2.00833 15.6964 2C15.7631 3.27498 16.2214 4.57497 17.1548 5.47496C18.0881 6.39995 19.4047 6.82494 20.688 6.9666V10.3249C19.488 10.2832 18.2797 10.0332 17.1881 9.51656C16.7131 9.29991 16.2714 9.02491 15.8381 8.74157C15.8298 11.1749 15.8464 13.6082 15.8214 16.0332C15.7548 17.1998 15.3714 18.3581 14.6964 19.3164C13.6048 20.9164 11.7131 21.9581 9.7715 21.9914C8.57986 22.0581 7.38819 21.7331 6.37154 21.1331C4.68823 20.1414 3.50492 18.3248 3.32992 16.3748C3.31325 15.9582 3.30492 15.5415 3.32158 15.1332C3.47158 13.5499 4.25491 12.0332 5.47156 10.9999C6.85488 9.7999 8.78817 9.22491 10.5965 9.56656C10.6131 10.7999 10.5631 12.0332 10.5631 13.2665C9.73816 12.9999 8.77151 13.0749 8.04652 13.5749C7.52153 13.9165 7.12154 14.4415 6.91319 15.0332C6.7382 15.4582 6.7882 15.9248 6.79654 16.3748C6.99654 17.7415 8.31318 18.8914 9.71316 18.7665C10.6465 18.7581 11.5381 18.2165 12.0215 17.4248C12.1798 17.1498 12.3548 16.8665 12.3631 16.5415C12.4465 15.0498 12.4131 13.5665 12.4215 12.0749C12.4298 8.71657 12.4131 5.36661 12.4381 2.01667Z"/>
            </svg>
          </a>
        )}
        {SOCIAL.googleMaps && (
          <a href={SOCIAL.googleMaps} target="_blank" rel="noopener noreferrer" class="footer__social-link" aria-label="Znajdź nas na mapie">
            <svg width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 0 1-2.827 0l-4.244-4.243a8 8 0 1 1 11.314 0z"/>
              <path stroke-linecap="round" stroke-linejoin="round" d="M15 11a3 3 0 1 1-6 0 3 3 0 0 1 6 0z"/>
            </svg>
          </a>
        )}
      </div>
    </div>

    <!-- Dane firmowe + copyright -->
    <div class="footer__legal">
      <p class="footer__legal-company">
        {SITE.fullName} · NIP: {CONTACT.nip} · REGON: {CONTACT.regon}
      </p>
      <p class="footer__copyright">
        Wszelkie prawa zastrzeżone © {year} Maciej Rafalski
      </p>
    </div>

  </div>
</footer>

<style>
  footer {
    padding: 5rem 0 2rem;
    border-top: 1px solid var(--color-border);
  }

  .footer__top {
    display: grid;
    grid-template-columns: 1fr;
    gap: 2.5rem;
    margin-bottom: 3rem;
  }
  @media (min-width: 768px) {
    .footer__top { grid-template-columns: 1fr 1fr; }
  }

  .footer__brand img { margin-bottom: 1rem; }

  .footer__tagline {
    font-size: 0.875rem;
    color: var(--color-text-secondary);
    line-height: 1.6;
    margin: 0;
  }

  .footer__contact {
    font-style: normal;
    font-size: 0.875rem;
    color: var(--color-text-secondary);
    line-height: 1.8;
  }
  .footer__contact a {
    color: var(--color-text-secondary);
    text-decoration: none;
    transition: color 0.2s;
  }
  .footer__contact a:hover { color: var(--color-text-primary); }

  .footer__divider {
    border: none;
    border-top: 1px solid var(--color-border);
    margin: 0 0 2rem;
  }

  .footer__bottom {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: 1.5rem;
    margin-bottom: 2rem;
  }

  .footer__nav {
    display: flex;
    flex-wrap: wrap;
    gap: 0.25rem 1rem;
    list-style: none;
    padding: 0;
    margin: 0;
  }

  .footer__nav-link {
    font-size: 0.875rem;
    font-weight: 300;
    color: var(--color-text-secondary);
    text-decoration: none;
    transition: color 0.2s;
  }
  .footer__nav-link:hover { color: var(--color-text-primary); }

  .footer__social {
    display: flex;
    align-items: center;
    gap: 0.75rem;
  }

  .footer__social-link {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 2.5rem;
    height: 2.5rem;
    border-radius: 9999px;
    border: 1px solid var(--color-border);
    color: var(--color-text-secondary);
    text-decoration: none;
    transition: border-color 0.2s, color 0.2s;
  }
  .footer__social-link:hover {
    border-color: rgba(255,255,255,0.5);
    color: var(--color-text-primary);
  }

  .footer__legal {
    padding-top: 2rem;
    border-top: 1px solid var(--color-border);
    text-align: center;
  }

  .footer__legal-company,
  .footer__copyright {
    font-size: 0.75rem;
    color: var(--color-text-muted);
    margin: 0.25rem 0;
  }
</style>
ASTROEOF
log "Footer.astro gotowy"

# =============================================================================
# 16. GTRANSLATE COMPONENT
# =============================================================================
info "Tworzę src/components/GTranslate.astro..."
cat > src/components/GTranslate.astro << 'ASTROEOF'
---
// GTranslate widget — tłumaczenia
// Dokumentacja: https://gtranslate.io/
---
<script>
  window.gtranslateSettings = {
    default_language:  "pl",
    detect_browser_language: false,
    languages:         ["pl","en","de","fr","uk","ru"],
    wrapper_selector:  ".gtranslate_wrapper",
    switcher_horizontal_position: "right",
    switcher_vertical_position:   "bottom",
    float_switcher_open_direction:"top",
    alt_flags:         { en: "usa" },
  };
</script>
<div class="gtranslate_wrapper"></div>
<script src="https://cdn.gtranslate.net/widgets/latest/float.js" defer></script>
ASTROEOF
log "GTranslate.astro gotowy"

# =============================================================================
# 17. CLOUDINARY IMAGE COMPONENT
# =============================================================================
info "Tworzę src/components/ui/CloudinaryImage.astro..."
cat > src/components/ui/CloudinaryImage.astro << 'ASTROEOF'
---
import { cloudinaryUrl, cloudinarySrcset } from '../../utils/cloudinary';

interface Props {
  publicId:    string;
  alt:         string;
  width?:      number;
  height?:     number;
  aspectRatio?: string;
  crop?:       'fill' | 'fit' | 'scale' | 'crop' | 'thumb';
  sizes?:      string;
  loading?:    'lazy' | 'eager';
  decoding?:   'async' | 'sync' | 'auto';
  class?:      string;
  widths?:     number[];
}

const {
  publicId,
  alt,
  width,
  height,
  aspectRatio,
  crop      = 'fill',
  sizes     = '(max-width: 768px) 100vw, (max-width: 1024px) 50vw, 800px',
  loading   = 'lazy',
  decoding  = 'async',
  class:    className,
  widths    = [400, 800, 1200],
} = Astro.props;

const src    = cloudinaryUrl(publicId, { width: width ?? 800, height, aspectRatio, crop });
const srcset = cloudinarySrcset(publicId, widths, { height, aspectRatio, crop });
---

<img
  src={src}
  srcset={srcset}
  sizes={sizes}
  alt={alt}
  width={width}
  height={height}
  loading={loading}
  decoding={decoding}
  class={className}
>
ASTROEOF
log "CloudinaryImage.astro gotowy"

# =============================================================================
# 18. CONTACT FORM COMPONENT
# =============================================================================
info "Tworzę src/components/forms/ContactForm.astro..."
cat > src/components/forms/ContactForm.astro << 'ASTROEOF'
---
import { FORMSPARK, CONTACT, SITE } from '../../config/site';

const siteKey = import.meta.env.PUBLIC_TURNSTILE_SITE_KEY ?? '';
const formUrl = `${FORMSPARK.url}/${FORMSPARK.formId}`;
---

<!-- Turnstile script — ładuj tylko na stronach z formularzem -->
<script
  src="https://challenges.cloudflare.com/turnstile/v0/api.js"
  async
  defer
></script>

<div
  x-data="{
    name:    '',
    email:   '',
    company: '',
    message: '',
    status:  'idle',
    turnstileToken: '',
    async submit() {
      if (!this.turnstileToken) {
        this.status = 'no-token';
        return;
      }
      this.status = 'sending';
      try {
        const res = await fetch(formAction, {
          method:  'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept':       'application/json',
          },
          body: JSON.stringify({
            name:                    this.name,
            email:                   this.email,
            company:                 this.company,
            message:                 this.message,
            'cf-turnstile-response': this.turnstileToken,
          }),
        });
        this.status = res.ok ? 'success' : 'error';
      } catch {
        this.status = 'error';
      }
    }
  }"
  x-init="
    formAction = $el.dataset.action;
    // Turnstile callback — wywoływany gdy widget zatwierdzi użytkownika
    window.onTurnstileSuccess = (token) => { turnstileToken = token; };
    window.onTurnstileExpire  = ()      => { turnstileToken = ''; };
  "
  data-action={formUrl}
>
  <!-- Sukces -->
  <div x-show="status === 'success'" role="alert" style="padding: 2rem; text-align: center;">
    <p style="color: var(--color-text-primary); font-size: 1.125rem; font-weight: 500;">
      Wiadomość wysłana!
    </p>
    <p style="color: var(--color-text-secondary); margin-top: 0.5rem;">
      Odpowiemy w ciągu 24 godzin w dni robocze.
    </p>
  </div>

  <!-- Formularz -->
  <form
    x-show="status !== 'success'"
    x-on:submit.prevent="submit()"
    novalidate
  >
    <div class="form-group">
      <label for="contact-name" class="form-label">Imię *</label>
      <input
        id="contact-name"
        type="text"
        name="name"
        x-model="name"
        required
        autocomplete="given-name"
        class="form-input"
        placeholder="Twoje imię"
      >
    </div>

    <div class="form-group">
      <label for="contact-email" class="form-label">E-mail *</label>
      <input
        id="contact-email"
        type="email"
        name="email"
        x-model="email"
        required
        autocomplete="email"
        class="form-input"
        placeholder="twoj@email.pl"
      >
    </div>

    <div class="form-group">
      <label for="contact-company" class="form-label">
        Firma / instytucja
        <span style="color: var(--color-text-muted); font-size: 0.75rem;">(opcjonalnie)</span>
      </label>
      <input
        id="contact-company"
        type="text"
        name="company"
        x-model="company"
        autocomplete="organization"
        class="form-input"
        placeholder="Nazwa firmy"
      >
    </div>

    <div class="form-group">
      <label for="contact-message" class="form-label">Wiadomość *</label>
      <textarea
        id="contact-message"
        name="message"
        x-model="message"
        required
        rows="8"
        class="form-input"
        placeholder="Opisz swój projekt lub zadaj pytanie..."
      ></textarea>
    </div>

    <!-- Cloudflare Turnstile widget -->
    <div
      class="cf-turnstile"
      data-sitekey={siteKey}
      data-callback="onTurnstileSuccess"
      data-expired-callback="onTurnstileExpire"
      data-theme="dark"
      style="margin-bottom: 1rem;"
    ></div>

    <!-- Komunikaty błędów -->
    <p
      x-show="status === 'no-token'"
      role="alert"
      style="color: #f87171; font-size: 0.875rem; margin-bottom: 1rem;"
    >
      Potwierdź że nie jesteś robotem.
    </p>
    <p
      x-show="status === 'error'"
      role="alert"
      style="color: #f87171; font-size: 0.875rem; margin-bottom: 1rem;"
    >
      Coś poszło nie tak. Spróbuj ponownie lub napisz bezpośrednio na
      <a href={CONTACT.emailHref} style="color: var(--color-accent);">{CONTACT.email}</a>.
    </p>

    <button
      type="submit"
      class="btn-primary"
      x-bind:disabled="status === 'sending'"
    >
      <span x-show="status !== 'sending'">Wyślij wiadomość</span>
      <span x-show="status === 'sending'" aria-live="polite">Wysyłanie...</span>
    </button>
  </form>
</div>

<style>
  .form-group { margin-bottom: 1rem; }

  .form-label {
    display: block;
    font-size: 0.875rem;
    color: var(--color-text-secondary);
    margin-bottom: 0.375rem;
  }

  .form-input {
    width: 100%;
    padding: 0.75rem;
    background-color: #171717;
    border: 1px solid var(--color-border);
    border-radius: 0.5rem;
    color: var(--color-text-primary);
    font-size: 1rem;
    font-family: var(--font-sans);
    transition: border-color 0.2s;
    resize: vertical;
  }
  .form-input::placeholder { color: var(--color-text-muted); }
  .form-input:hover  { border-color: rgba(255,255,255,0.3); }
  .form-input:focus  { outline: none; border-color: rgba(255,255,255,0.5); }

  .btn-primary {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.75rem 1.5rem;
    background-color: var(--color-text-primary);
    color: var(--color-bg);
    font-size: 0.875rem;
    font-weight: 600;
    border: none;
    border-radius: 9999px;
    cursor: pointer;
    transition: background-color 0.2s;
  }
  .btn-primary:hover    { background-color: #e4e4e7; }
  .btn-primary:disabled { opacity: 0.6; cursor: not-allowed; }

  /* Turnstile — dopasowanie do ciemnego motywu */
  .cf-turnstile {
    border-radius: 0.5rem;
    overflow: hidden;
  }
</style>
ASTROEOF
log "ContactForm.astro gotowy (z Turnstile)"

# =============================================================================
# 19. ADMIN CMS
# =============================================================================
info "Tworzę public/admin/..."

cat > public/admin/index.html << 'EOF'
<!DOCTYPE html>
<html lang="pl">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Glass Project — CMS</title>
  <script src="https://unpkg.com/sveltia-cms/dist/sveltia-cms.js"></script>
</head>
<body></body>
</html>
EOF

cat > public/admin/config.yml << 'EOF'
backend:
  name: github
  repo: mrglassproject/mrglassproject-com
  branch: main
  base_url: https://sveltia-cms-auth.pages.dev

media_library:
  name: cloudinary
  config:
    cloud_name: mrglassproject
    api_key: TWOJ_API_KEY
    default_transformations:
      - - fetch_format: auto
          quality: auto

media_folder: public/uploads
public_folder: /uploads
locale: pl

collections:

  - name: posts
    label: Posty
    label_singular: Post
    folder: src/content/posts
    create: true
    slug: "{{slug}}"
    fields:
      - { name: title,     label: Tytuł,        widget: string }
      - { name: date,      label: Data,          widget: datetime, format: "YYYY-MM-DD" }
      - { name: excerpt,   label: Zajawka,       widget: text }
      - { name: cover,     label: Zdjęcie cover, widget: image, media_library: { name: cloudinary } }
      - { name: published, label: Opublikowany,  widget: boolean, default: false }
      - { name: body,      label: Treść,         widget: markdown }

  - name: projects
    label: Realizacje
    label_singular: Realizacja
    folder: src/content/projects
    create: true
    slug: "{{slug}}"
    fields:
      - { name: title,       label: Tytuł,        widget: string }
      - name: category
        label: Kategoria
        widget: select
        options:
          - { label: "Dla domu", value: dla-domu }
          - { label: "Dla firm", value: dla-firm }
      - name: images
        label: Zdjęcia
        widget: list
        field: { name: image, label: Zdjęcie, widget: image, media_library: { name: cloudinary } }
      - { name: description, label: Opis,         widget: text,    required: false }
      - { name: year,        label: Rok,           widget: number,  required: false }
      - { name: dimensions,  label: Wymiary,       widget: string,  required: false }
      - { name: order,       label: Kolejność,     widget: number,  default: 0 }
      - { name: published,   label: Opublikowana,  widget: boolean, default: true }
      - { name: body,        label: Opis rozszerzony, widget: markdown, required: false }

  - name: workshops
    label: Warsztaty
    label_singular: Warsztat
    folder: src/content/workshops
    create: true
    slug: "{{slug}}"
    fields:
      - { name: title,          label: Tytuł,           widget: string }
      - { name: description,    label: Opis,             widget: text }
      - { name: duration,       label: Czas trwania,     widget: string }
      - { name: maxPersons,     label: Maks. osób,       widget: number }
      - { name: price,          label: Cena (zł),        widget: number }
      - { name: pricePair,      label: Cena dla 2 osób,  widget: number,  required: false }
      - { name: pricePairLabel, label: Etykieta pary,    widget: string,  required: false }
      - name: level
        label: Poziom
        widget: select
        options:
          - { label: Fusing,       value: fusing }
          - { label: Podstawowy,   value: podstawowy }
          - { label: Zaawansowany, value: zaawansowany }
          - { label: Indywidualny, value: indywidualny }
      - { name: setmoreUrl, label: Link Setmore, widget: string }
      - { name: active,     label: Aktywny,      widget: boolean, default: true }
      - { name: order,      label: Kolejność,    widget: number,  default: 0 }
      - { name: body,       label: Opis rozszerzony, widget: markdown, required: false }

  - name: testimonials
    label: Opinie
    label_singular: Opinia
    folder: src/content/testimonials
    create: true
    extension: json
    format: json
    slug: "{{slug}}"
    fields:
      - { name: name,    label: Imię i nazwisko, widget: string }
      - { name: content, label: Treść opinii,    widget: text }
      - { name: rating,  label: Ocena (1-5),     widget: number, min: 1, max: 5, default: 5 }
      - { name: date,    label: Data,            widget: string }
      - { name: source,  label: Źródło,          widget: string, default: Google }

  - name: vouchers
    label: Vouchery
    label_singular: Voucher
    folder: src/content/vouchers
    create: true
    slug: "{{slug}}"
    fields:
      - { name: title,       label: Tytuł,         widget: string }
      - { name: description, label: Opis,           widget: text }
      - { name: price,       label: Cena (zł),      widget: number }
      - { name: buyUrl,      label: Link do zakupu, widget: string, required: false }
      - { name: active,      label: Aktywny,        widget: boolean, default: true }
      - { name: order,       label: Kolejność,      widget: number,  default: 0 }
      - { name: body,        label: Opis rozszerzony, widget: markdown, required: false }

  - name: faq
    label: FAQ
    label_singular: Pytanie
    folder: src/content/faq
    create: true
    extension: json
    format: json
    slug: "{{slug}}"
    fields:
      - { name: question, label: Pytanie,    widget: string }
      - { name: answer,   label: Odpowiedź, widget: text }
      - { name: order,    label: Kolejność, widget: number, default: 0 }

  - name: settings
    label: Ustawienia
    files:
      - name: site
        label: Dane strony i social media
        file: src/data/settings.json
        fields:
          - { name: phone,   label: Telefon, widget: string }
          - { name: email,   label: Email,   widget: string }
          - { name: address, label: Adres,   widget: string }
          - { name: hours,   label: Godziny, widget: string }
          - name: social
            label: Social media
            widget: object
            fields:
              - { name: facebook,   label: Facebook URL,    widget: string, required: false }
              - { name: instagram,  label: Instagram URL,   widget: string, required: false }
              - { name: tiktok,     label: TikTok URL,      widget: string, required: false }
              - { name: googlemaps, label: Google Maps URL, widget: string, required: false }
          - name: clients
            label: Klienci (lista nazw)
            widget: list
            field: { name: name, label: Nazwa firmy, widget: string }
EOF

log "Admin CMS gotowy"

# =============================================================================
# 20. ROBOTS.TXT
# =============================================================================
cat > public/robots.txt << 'EOF'
User-agent: *
Allow: /
Disallow: /admin/

Sitemap: https://mrglassproject.com/sitemap-index.xml
EOF
log "robots.txt gotowy"

# =============================================================================
# 21. MANIFEST WEBMANIFEST
# =============================================================================
mkdir -p public/favicons
cat > public/favicons/manifest.webmanifest << 'EOF'
{
  "name": "Glass Project — Pracownia Szkła Artystycznego",
  "short_name": "Glass Project",
  "description": "Pracownia szkła artystycznego w Warszawie",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#0A0A0B",
  "theme_color": "#FF8C00",
  "lang": "pl",
  "icons": [
    { "src": "/favicons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "/favicons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "/favicons/favicon.svg",  "sizes": "any",     "type": "image/svg+xml", "purpose": "any maskable" }
  ]
}
EOF
log "manifest.webmanifest gotowy"

# =============================================================================
# 22. LLMS.TXT + LLMS-FULL.TXT
# =============================================================================
info "Tworzę src/pages/llms.txt.ts..."
cat > src/pages/llms.txt.ts << 'ASTROEOF'
import type { APIRoute } from 'astro';
import { SITE, CONTACT, SOCIAL } from '../config/site';
import { getCollection } from 'astro:content';

export const GET: APIRoute = async () => {
  const workshops  = await getCollection('workshops',  e => e.data.active);
  const faqEntries = await getCollection('faq');
  const sortedFaq  = faqEntries.sort((a, b) => a.data.order - b.data.order);
  const sortedWS   = workshops.sort((a, b) => a.data.order - b.data.order);

  const content = `# ${SITE.fullName}

> Pracownia szkła artystycznego w Warszawie. Maciej Rafalski — hutnik szkła z ponad 20-letnim doświadczeniem. Realizujemy projekty na zamówienie dla firm, hoteli, architektów i osób prywatnych. Techniki: hutnictwo szkła (szkło dmuchane), fusing.

## Informacje ogólne

- Lokalizacja: ${CONTACT.address}, ${CONTACT.city}
- Telefon: ${CONTACT.phone}
- Email: ${CONTACT.email}
- Godziny pracy: ${CONTACT.hours}
- Strona WWW: ${SITE.finalUrl}

## Warsztaty

${sortedWS.map(w => `### ${w.data.title}\n- Cena: ${w.data.price} zł\n- Rezerwacja: ${w.data.setmoreUrl}`).join('\n\n')}

## FAQ

${sortedFaq.map(f => `### ${f.data.question}\n${f.data.answer}`).join('\n\n')}

## Mapa strony

- [Strona główna](${SITE.finalUrl}/)
- [Historia Macieja Rafalskiego](${SITE.finalUrl}/about)
- [Pracownia](${SITE.finalUrl}/pracownia)
- [Realizacje / Portfolio](${SITE.finalUrl}/portfolio)
- [Oferta](${SITE.finalUrl}/services)
- [Warsztaty](${SITE.finalUrl}/workshop)
- [FAQ](${SITE.finalUrl}/faq)
- [Kontakt](${SITE.finalUrl}/contact)
- [Pełna treść dla LLM](${SITE.finalUrl}/llms-full.txt)
`;

  return new Response(content, {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'public, max-age=86400',
    },
  });
};
ASTROEOF
log "llms.txt.ts gotowy"

info "Tworzę src/pages/llms-full.txt.ts..."
cat > src/pages/llms-full.txt.ts << 'ASTROEOF'
import type { APIRoute } from 'astro';
import { SITE, CONTACT } from '../config/site';
import { getCollection } from 'astro:content';

export const GET: APIRoute = async () => {
  const workshops  = await getCollection('workshops',  e => e.data.active);
  const faqEntries = await getCollection('faq');
  const projects   = await getCollection('projects',   e => e.data.published);
  const posts      = await getCollection('posts',      e => e.data.published);

  const sortedWS    = workshops.sort((a, b) => a.data.order - b.data.order);
  const sortedFaq   = faqEntries.sort((a, b) => a.data.order - b.data.order);
  const sortedPosts = posts.sort((a, b) => b.data.date.valueOf() - a.data.date.valueOf());
  const projFirm    = projects.filter(p => p.data.category === 'dla-firm');
  const projDom     = projects.filter(p => p.data.category === 'dla-domu');

  const content = `# ${SITE.fullName} — pełna treść

Wygenerowano: ${new Date().toISOString()}

## O pracowni

Pracownia Szkła Artystycznego Maciej Rafalski Glass Project, Warszawa, Ochota.
Maciej Rafalski — hutnik szkła z ponad 20-letnim doświadczeniem.
Techniki: hutnictwo szkła (dmuchanie), fusing.
Materiały: szkło recyklingowe.

## Realizacje dla firm (${projFirm.length})

${projFirm.map(p => `- ${p.data.title}${p.data.year ? ` (${p.data.year})` : ''}${p.data.description ? `: ${p.data.description}` : ''}`).join('\n') || '- brak danych'}

## Realizacje dla domu (${projDom.length})

${projDom.map(p => `- ${p.data.title}${p.data.year ? ` (${p.data.year})` : ''}${p.data.description ? `: ${p.data.description}` : ''}`).join('\n') || '- brak danych'}

## Warsztaty

${sortedWS.map(w => `### ${w.data.title}\n${w.data.description}\n- Cena: ${w.data.price} zł${w.data.pricePair ? `, para: ${w.data.pricePair} zł` : ''}\n- Osób: ${w.data.maxPersons}, czas: ${w.data.duration}`).join('\n\n')}

## FAQ

${sortedFaq.map(f => `### ${f.data.question}\n${f.data.answer}`).join('\n\n')}

## Posty

${sortedPosts.map(p => `### [${p.data.title}](${SITE.finalUrl}/posts/${p.slug})\n\n${p.data.excerpt}`).join('\n\n') || 'Brak postów.'}

## Kontakt

${CONTACT.address}, ${CONTACT.city} · ${CONTACT.phone} · ${CONTACT.email}
NIP: ${CONTACT.nip} · REGON: ${CONTACT.regon}
`;

  return new Response(content, {
    headers: {
      'Content-Type': 'text/plain; charset=utf-8',
      'Cache-Control': 'public, max-age=86400',
    },
  });
};
ASTROEOF
log "llms-full.txt.ts gotowy"

# =============================================================================
# 23. PLACEHOLDER STRONY INDEX
# =============================================================================
info "Tworzę src/pages/index.astro (placeholder)..."
cat > src/pages/index.astro << 'ASTROEOF'
---
import BaseLayout from '../layouts/BaseLayout.astro';

const jsonLd = {
  '@context': 'https://schema.org',
  '@type':    'WebPage',
  '@id':      'https://mrglassproject.com/#webpage',
  name:       'Glass Project — Pracownia Szkła Artystycznego',
  url:        'https://mrglassproject.com',
  isPartOf: { '@id': 'https://mrglassproject.com/#website' },
};
---

<BaseLayout jsonLd={jsonLd}>
  <section style="min-height: 60vh; display: flex; align-items: center; justify-content: center;">
    <div style="text-align: center;">
      <h1 class="text-gradient" style="font-size: clamp(2rem, 6vw, 4rem); font-weight: 500; margin-bottom: 1rem;">
        Glass Project
      </h1>
      <p style="color: var(--color-text-secondary); font-size: 1.125rem;">
        Strona w budowie — zawartość wkrótce.
      </p>
    </div>
  </section>
</BaseLayout>
ASTROEOF
log "index.astro gotowy"

# =============================================================================
# 23. PLACEHOLDER POZOSTAŁE STRONY
# =============================================================================
info "Tworzę placeholder strony..."

pages=("about" "pracownia" "contact" "workshop" "services" "portfolio" "faq" "vouchers" "privacy" "terms")
titles=("Moja historia" "Pracownia" "Kontakt" "Warsztaty" "Oferta" "Portfolio" "FAQ" "Vouchery" "Polityka prywatności" "Regulamin")

for i in "${!pages[@]}"; do
  page="${pages[$i]}"
  title="${titles[$i]}"
  cat > "src/pages/${page}.astro" << ASTROEOF
---
import BaseLayout from '../layouts/BaseLayout.astro';
---

<BaseLayout title="${title}">
  <section class="section-py">
    <div class="container">
      <h1 class="text-gradient" style="font-size: clamp(2rem, 5vw, 3.5rem); font-weight: 500; margin-bottom: 2rem;">
        ${title}
      </h1>
      <p style="color: var(--color-text-secondary);">Treść strony wkrótce.</p>
    </div>
  </section>
</BaseLayout>
ASTROEOF
done

# Strona postów
cat > src/pages/posts/index.astro << 'ASTROEOF'
---
import BaseLayout  from '../../layouts/BaseLayout.astro';
import { getCollection } from 'astro:content';

const posts = (await getCollection('posts', ({ data }) => data.published))
  .sort((a, b) => b.data.date.valueOf() - a.data.date.valueOf());
---

<BaseLayout title="Blog">
  <section class="section-py">
    <div class="container">
      <h1 class="text-gradient" style="font-size: clamp(2rem, 5vw, 3.5rem); font-weight: 500; margin-bottom: 3rem;">
        Posty
      </h1>
      {posts.length === 0 && (
        <p style="color: var(--color-text-secondary);">Brak postów.</p>
      )}
      <ul role="list" style="list-style: none; padding: 0; display: grid; gap: 2rem;">
        {posts.map(post => (
          <li>
            <a href={`/posts/${post.slug}`} style="text-decoration: none; color: inherit;">
              <h2 style="font-size: 1.5rem; font-weight: 500;" class="text-gradient">
                {post.data.title}
              </h2>
              <p style="color: var(--color-text-secondary); margin-top: 0.5rem;">
                {post.data.excerpt}
              </p>
            </a>
          </li>
        ))}
      </ul>
    </div>
  </section>
</BaseLayout>
ASTROEOF

cat > src/pages/posts/\[slug\].astro << 'ASTROEOF'
---
import PostLayout from '../../layouts/PostLayout.astro';
import { getCollection, getEntry } from 'astro:content';

export async function getStaticPaths() {
  const posts = await getCollection('posts', ({ data }) => data.published);
  return posts.map(post => ({ params: { slug: post.slug } }));
}

const { slug } = Astro.params;
const post = await getEntry('posts', slug!);
if (!post) return Astro.redirect('/404');

const { Content } = await post.render();
---

<PostLayout
  title={post.data.title}
  date={post.data.date}
  excerpt={post.data.excerpt}
  cover={post.data.cover}
>
  <Content />
</PostLayout>
ASTROEOF

log "Placeholder strony gotowe"

# =============================================================================
# 24. DEPENDABOT
# =============================================================================
info "Tworzę .github/dependabot.yml..."
cat > .github/dependabot.yml << 'EOF'
version: 2

updates:

  - package-ecosystem: npm
    directory: /
    schedule:
      interval: weekly
      day: monday
      time: "08:00"
      timezone: Europe/Warsaw
    open-pull-requests-limit: 5
    labels:
      - dependencies
      - npm
    groups:
      astro:
        patterns:
          - "astro"
          - "@astrojs/*"
      alpinejs:
        patterns:
          - "alpinejs"
          - "@types/alpinejs"
    ignore:
      - dependency-name: "astro"
        update-types: ["version-update:semver-major"]
      - dependency-name: "@astrojs/*"
        update-types: ["version-update:semver-major"]
    commit-message:
      prefix: "chore(deps)"
      include: scope

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: monthly
      day: monday
      time: "08:00"
      timezone: Europe/Warsaw
    labels:
      - dependencies
      - github-actions
    commit-message:
      prefix: "chore(actions)"
EOF
log "dependabot.yml gotowy"

# =============================================================================
# 28. CLOUDFLARE WORKER — VOUCHERS
# =============================================================================
info "Tworzę cloudflare-worker/..."

cat > cloudflare-worker/package.json << 'EOF'
{
  "name": "glassproject-voucher-worker",
  "version": "1.0.0",
  "type": "module",
  "private": true,
  "scripts": {
    "dev":    "wrangler dev",
    "deploy": "wrangler deploy",
    "tail":   "wrangler tail"
  },
  "dependencies": {
    "resend":            "^3.0.0",
    "satori":            "^0.10.0",
    "@resvg/resvg-wasm": "^2.6.0"
  },
  "devDependencies": {
    "wrangler":                  "^3.0.0",
    "@cloudflare/workers-types": "^4.0.0",
    "typescript":                "^5.0.0"
  }
}
EOF

cat > cloudflare-worker/wrangler.toml << 'EOF'
name               = "glassproject-voucher-worker"
main               = "src/index.ts"
compatibility_date = "2024-01-01"
compatibility_flags = ["nodejs_compat"]

[vars]
SITE_URL = "https://mrglassproject.com"

# Sekrety — dodaj przez CLI:
# wrangler secret put STRIPE_WEBHOOK_SECRET
# wrangler secret put RESEND_API_KEY
# wrangler secret put STRIPE_SECRET_KEY

[[rules]]
type        = "CompiledWasm"
globs       = ["**/*.wasm"]
fallthrough = true
EOF

cat > cloudflare-worker/src/assets.ts << 'TSEOF'
// Zasoby statyczne — uzupełnij przed deployem
// Patrz: VOUCHERS.md sekcja 1.1 i 1.2

import inter400 from '../assets/inter-400.woff2';
import inter700 from '../assets/inter-700.woff2';

export const FONTS: import('satori').SatoriOptions['fonts'] = [
  { name: 'Inter', data: inter400, weight: 400, style: 'normal' },
  { name: 'Inter', data: inter700, weight: 700, style: 'normal' },
];

// Wygeneruj przez: base64 -i logo-glassproject-200x70.png | tr -d '\n'
export const LOGO_BASE64 = 'data:image/png;base64,WKLEJ_TUTAJ_BASE64_LOGO';

// Opcjonalna tekstura tła (może być pusty string)
export const TEXTURE_BASE64 = '';
TSEOF

# Placeholder dla fontów
touch cloudflare-worker/assets/.gitkeep
cat > cloudflare-worker/assets/README.md << 'EOF'
# Fonty dla generatora voucherów

Umieść tu pliki:
- inter-400.woff2 (Inter Regular)
- inter-700.woff2 (Inter Bold)

Instrukcja pobierania w VOUCHERS.md sekcja 1.2
EOF

# Plik VOUCHERS.md w głównym katalogu
cat > VOUCHERS.md << 'EOF'
Patrz: VOUCHERS.md — wygenerowany osobno.
Pełna instrukcja systemu voucherów.
EOF

log "cloudflare-worker/ gotowy"

# =============================================================================
# 29. GITIGNORE — aktualizacja o Worker
# =============================================================================
cat > .gitignore << 'EOF'
# Build
dist/
.astro/

# Dependencies
node_modules/
cloudflare-worker/node_modules/

# Env — NIE wgrywaj do repo
.env
.env.*
!.env.example

# Logi setupu
setup.log

# Cloudflare Worker — pliki tymczasowe
cloudflare-worker/.wrangler/

# Fonty Worker — duże pliki binarne, wgraj ręcznie
cloudflare-worker/assets/*.woff2
cloudflare-worker/assets/*.ttf
!cloudflare-worker/assets/.gitkeep
!cloudflare-worker/assets/README.md

# OS
.DS_Store
Thumbs.db

# Editor
.vscode/settings.json
.idea/
EOF
log ".gitignore gotowy"

# =============================================================================
# 25. ENV EXAMPLE
# =============================================================================
cat > .env.example << 'EOF'
# Cloudinary
PUBLIC_CLOUDINARY_CLOUD_NAME=mrglassproject
PUBLIC_CLOUDINARY_API_KEY=twoj_api_key

# Formspark
PUBLIC_FORMSPARK_FORM_ID=twoj_form_id
EOF

# .env lokalny — NIE trafia do repo
cat > .env << 'EOF'
# Skopiuj z .env.example i uzupełnij wartościami
PUBLIC_CLOUDINARY_CLOUD_NAME=mrglassproject
PUBLIC_CLOUDINARY_API_KEY=
PUBLIC_FORMSPARK_FORM_ID=
EOF

log ".env.example i .env gotowe"

# =============================================================================
# 26. README
# =============================================================================
cat > README.md << 'EOF'
# Glass Project — mrglassproject.com

Strona pracowni szkła artystycznego. Zbudowana na Astro 4.x.

## Stack
- **Astro 4.x** — static site generator
- **Alpine.js** — interaktywność (mobile menu, galeria, modal)
- **Sveltia CMS** — panel administracyjny (`/admin`)
- **Cloudinary** — hosting i transformacje zdjęć
- **Formspark** — formularz kontaktowy
- **GitHub Pages** — hosting

## Szybki start

```bash
npm install
npm run dev
```

## Deploy
Push na branch `main` → GitHub Action buduje i deployuje automatycznie.

## CMS
Panel dostępny pod `/admin`. Wymaga zalogowania przez GitHub OAuth.

## Konfiguracja
Uzupełnij w `src/config/site.ts`:
- `FORMSPARK.formId`

Uzupełnij w `public/admin/config.yml`:
- Cloudinary `api_key`

## Struktura kolekcji
- `src/content/posts/` — posty blogowe (`.md`)
- `src/content/projects/` — realizacje portfolio (`.md`)
- `src/content/workshops/` — warsztaty (`.md`)
- `src/content/testimonials/` — opinie klientów (`.json`)
- `src/content/vouchers/` — vouchery (`.md`)
- `src/content/faq/` — FAQ (`.json`)
- `src/data/settings.json` — dane kontaktowe i social media
EOF
log "README.md gotowy"

# =============================================================================
# 27. INSTALACJA ZALEŻNOŚCI
# =============================================================================
echo ""
info "Instaluję zależności npm..."
npm install
log "npm install gotowy"

# =============================================================================
# PODSUMOWANIE
# =============================================================================
echo ""
echo "  ================================"
echo -e "  ${GREEN}Projekt gotowy!${NC}"
echo "  ================================"
echo "  Zakończono: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "  Pełny log:  $(pwd)/setup.log"
echo "  ================================"
echo ""
echo "  Następne kroki:"
echo "  1. Uzupełnij FORMSPARK formId w src/config/site.ts"
echo "  2. Uzupełnij Cloudinary api_key w public/admin/config.yml"
echo "  3. Wgraj faviconę do public/favicons/"
echo "     (favicon.ico, favicon.svg, apple-touch-icon.png, icon-192.png, icon-512.png)"
echo "  4. Wgraj logo do public/images/"
echo "  5. W GitHub: Settings → Pages → Source: GitHub Actions"
echo "  6. Uruchom: npm run dev"
echo ""
warn "  Pamiętaj: zmień repo w public/admin/config.yml na:"
warn "  repo: mrglassproject/mrglassproject-com"
echo ""
