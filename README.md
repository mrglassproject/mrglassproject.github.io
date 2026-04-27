# Glass Project — mrglassproject.com

Strona pracowni szkła artystycznego. Zbudowana na Astro 6.x.

## Stack
- **Astro 6.x** — static site generator
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
