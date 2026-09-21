# CormeX Easy

Catálogo web/PWA para encontrar prestadores de serviços por categoria e localização e entrar em contato diretamente pelo WhatsApp.

## Estado desta entrega

- Flutter Web responsivo para celular, tablet e desktop.
- Navegação pública sem login.
- Home, busca, categorias, favoritos, perfil do prestador e compartilhamento.
- Fluxo em etapas para anunciar um serviço.
- Conta, gestão do anúncio, planos, assinatura e analytics preparados para API.
- Área administrativa, manutenção e páginas de erro CormeX.
- Ambientes `qa` e `production` via `--dart-define`.
- Dados demonstrativos estritamente isolados no ambiente QA.
- Deploy automático no GitHub Pages.

## Executar

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=APP_ENV=qa \
  --dart-define=USE_QA_DATA=true \
  --dart-define=PARSE_SERVER_URL=https://parseapi.back4app.com \
  --dart-define=PARSE_APPLICATION_ID=seu_app_id \
  --dart-define=PARSE_CLIENT_KEY=sua_client_key
```

Produção:

```bash
flutter build web --release \
  --base-href=/cormex_easy/ \
  --dart-define=APP_ENV=production \
  --dart-define=USE_QA_DATA=false \
  --dart-define=PARSE_SERVER_URL=https://parseapi.back4app.com \
  --dart-define=PARSE_APPLICATION_ID=seu_app_id \
  --dart-define=PARSE_CLIENT_KEY=sua_client_key
```

Nenhum segredo deve ser enviado por `dart-define`: o Flutter Web é público. Tokens privados, chaves administrativas e credenciais do Mercado Pago pertencem exclusivamente ao backend.

## GitHub Pages

O workflow `.github/workflows/deploy-pages.yml` publica a branch `main`. Enquanto a API real não estiver disponível, a configuração padrão publica a demonstração QA. Para produção, crie estas *Repository Variables*:

| Variável | Valor de produção |
|---|---|
| `APP_ENV` | `production` |
| `USE_QA_DATA` | `false` |
| `PARSE_SERVER_URL` | `https://parseapi.back4app.com` |
| `PARSE_APPLICATION_ID` | Application ID do BancoEasy |
| `PARSE_CLIENT_KEY` | Client Key do BancoEasy |

Em **Settings → Pages**, selecione **GitHub Actions** como origem.

## Contratos esperados

| Recurso | Endpoint sugerido |
|---|---|
| Bootstrap/Home | `GET /v1/home` |
| Categorias | `GET /v1/categories` |
| Prestadores | `GET /v1/providers` |
| Perfil público | `GET /v1/providers/{slug}` |
| Favoritos autenticados | `GET/POST/DELETE /v1/favorites` |
| Conta | `GET/PATCH /v1/auth/me` |
| Anúncio | `POST/PATCH /v1/provider-profile` |
| Planos elegíveis | `GET /v1/plans/eligible` |
| Assinatura | `POST /v1/subscriptions` |
| Analytics | `GET /v1/provider-profile/analytics` |
| Denúncia | `POST /v1/reports` |
| Admin | `/v1/admin/*` |

O backend será a fonte de verdade para permissões, ranking/rotação Pro, preços, assinatura, feature flags, manutenção e autorização administrativa.

## Estrutura

```text
lib/
  core/        configuração, DI, HTTP, rotas, tema e widgets
  features/
    catalog/   descoberta, busca, favoritos e prestadores
    advertise/ anúncio, planos e gestão
    account/   login e conta
    admin/     painel administrativo
    system/    erros e manutenção
```

© 2026 Genesys System. Todos os direitos reservados.
