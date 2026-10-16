# Administratum design system

Read this before changing any view, helper or stylesheet in the gem.

## Rules

- **Colours come only from tokens.** Never write a raw colour or a stock palette utility (`bg-blue-600`) in a view, helper or component. Use `bg-adm-primary`, `text-adm-muted`, `border-adm-border`, and so on.
- **Markup uses `adm-*` component classes.** They're defined in `app/assets/tailwind/administratum/components.css` with `@apply` on the tokens. Add a new component class when a pattern repeats; one-off layout tweaks can use plain utilities.
- **Class names must appear literally** in `app/views`, `app/helpers` or `app/assets/javascripts`, so Tailwind's `@source` finds them. Never interpolate class names.
- **Rebuild after changes.** Run `bin/build-css` after touching views, helpers or CSS, and commit `app/assets/builds/administratum.css`.
- **No inline styles or inline event handlers.** Behaviour lives in `administratum.js` and is attached through `data-adm-*` attributes.

## Tokens (`theme.css`)

| Token | Role |
|---|---|
| `--color-adm-bg` | Page background |
| `--color-adm-surface` | Cards, bars, panels |
| `--color-adm-surface-muted` | Table headers, card footers, hover rows |
| `--color-adm-border` | All borders and dividers |
| `--color-adm-text` | Primary text |
| `--color-adm-muted` | Secondary text, labels in tables |
| `--color-adm-primary` / `--color-adm-primary-fg` | Primary buttons, active nav, links |
| `--color-adm-danger` / `--color-adm-danger-fg` | Destructive actions, errors, alert flash |
| `--color-adm-success` | Positive badges |
| `--color-adm-warning` | Reserved for warnings |
| `--color-adm-ring` | Focus rings |
| `--color-adm-overlay` | Offcanvas backdrop |
| `--radius-adm` | Corner radius for cards, inputs and buttons |
| `--font-adm`, `--font-adm-mono` | Body and code fonts |

Dark values are set under `:root.dark`, and under `prefers-color-scheme: dark` unless `:root.light` is set, which covers pages with JS disabled.

An inline script always puts `.dark` or `.light` on `<html>` before first paint: the stored choice from `localStorage["administratum-theme"]` if there is one, otherwise the OS preference. Until the viewer picks a theme, it follows OS changes. Host styles can therefore rely on `.dark`, for example through Tailwind's class-based `dark` variant, which `theme.css` defines.

Overrides, in order of precedence:
1. `config.theme` / `config.dark_theme`, rendered as an inline `<style>`.
2. The host app's `@theme`, in `:host` stylesheet mode.
3. The defaults above.

## Components (`components.css`)

| Area | Classes |
|---|---|
| Layout | `adm-container`, `adm-main`, `adm-page-body`, `adm-grid` |
| Chrome | `adm-topbar`, `adm-brand`, `adm-nav`, `adm-nav-link`, `adm-nav-link-active`, `adm-dropdown`, `adm-dropdown-menu`, `adm-dropdown-item` |
| Page header | `adm-page-header`, `adm-page-title`, `adm-page-actions`, `adm-breadcrumb`, `adm-breadcrumb-item` |
| Cards | `adm-card`, `adm-card-header`, `adm-card-title`, `adm-card-body`, `adm-card-footer`, `adm-tile` |
| Buttons | `adm-btn` plus one of `adm-btn-primary`, `-secondary`, `-danger`, `-ghost`; sizes `adm-btn-sm`, `adm-btn-block`; `adm-btn-group`, `adm-icon-btn`, `adm-link` |
| Tables | `adm-table-wrap`, `adm-table`, `adm-table-actions`, `adm-table-footer`, `adm-empty`, `adm-pagy` |
| Show page | `adm-attributes`, `adm-attribute` |
| Forms | `adm-form`, `adm-field`, `adm-field-horizontal`, `adm-field-control`, `adm-label`, `adm-input`, `adm-checkbox`, `adm-check`, `adm-hint`, `adm-error`, `adm-form-footer`, `adm-alert` |
| Feedback | `adm-badge`, `adm-badge-success`, `adm-flash`, `adm-flash-notice`, `adm-flash-alert` |
| Panels | `adm-offcanvas`, `adm-offcanvas-panel`, `adm-offcanvas-header`, `adm-offcanvas-body` |
| Auth | `adm-auth`, `adm-auth-panel`, `adm-auth-title` |

## Behaviour hooks (`administratum.js`)

| Attribute | Effect |
|---|---|
| `data-adm-offcanvas-open="name"` | Opens `[data-adm-offcanvas="name"]` |
| `data-adm-offcanvas-close` | Closes the open panel; Escape does too |
| `data-adm-dropdown`, `-toggle`, `-menu` | Dropdowns |
| `data-adm-confirm="…"` (on a form) | Asks for confirmation before submitting |
| `data-adm-toggle="id"` | Toggles `adm-open` on the element with that id |
| `data-adm-theme-toggle` | Switches between light and dark |
| `data-adm-flash`, `data-adm-dismiss` | Flash messages auto-dismiss after 6s, or close on click |
| `data-administratum-island="name"` | Island mount point; rendered by the `island` helper |
