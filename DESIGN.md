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
| `--color-adm-warning` | Warning alerts and badges |
| `--color-adm-ring` | Focus rings |
| `--color-adm-overlay` | Offcanvas backdrop |
| `--radius-adm` | Corner radius for cards, inputs and buttons |
| `--font-adm`, `--font-adm-mono` | Body and code fonts |

Status colours (danger, success, warning) are used as text on their own 10% tint (`bg-adm-warning/10`), so each keeps at least 4.5:1 contrast against that tint and against the surface, in light and dark. Keep tints at 10% and check contrast when overriding these tokens.

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
| Forms | `adm-form`, `adm-field`, `adm-field-horizontal`, `adm-field-control`, `adm-label`, `adm-input`, `adm-checkbox`, `adm-check`, `adm-hint`, `adm-error`, `adm-form-footer` |
| Feedback | `adm-alert` (see below), `adm-badge` (see below), `adm-flash`, `adm-flash-notice`, `adm-flash-alert` |
| Searchable select | `adm-combobox`, `adm-combobox-input`, `adm-combobox-listbox`, `adm-combobox-group`, `adm-combobox-option`, `adm-combobox-option-active`, `adm-combobox-empty` (built by `administratum.js`) |
| Reordering | `adm-sortable-controls`, `adm-sortable-handle`, `adm-sortable-position`, `adm-sortable-dragging` (rendered by `reorder_controls`) |
| Panels | `adm-offcanvas`, `adm-offcanvas-panel`, `adm-offcanvas-header`, `adm-offcanvas-body` |
| Auth | `adm-auth`, `adm-auth-panel`, `adm-auth-title` |

### Alerts and badges

Pick the level by what the reader has to do, not by how it looks:

| Level | Alert | Badge | Use for |
|---|---|---|---|
| Danger | `adm-alert` or `adm-alert adm-alert-danger` | `adm-badge adm-badge-danger` | Errors and problems that block an action ("Can't publish yet", form errors, "2 problems") |
| Warning | `adm-alert adm-alert-warning` | `adm-badge adm-badge-warning` | Things worth checking that don't block anything |
| Info | `adm-alert adm-alert-info` | `adm-badge` | Neutral context. Info is deliberately neutral, not primary: primary means "you can act on this" |
| Success | — | `adm-badge adm-badge-success` | Done, covered, ready |

Plain `adm-alert` is danger, as it always was. Give an alert an `adm-alert-title` (coloured by level) and put the detail in text or a list:

```html
<div class="adm-alert adm-alert-warning" role="status">
  <p class="adm-alert-title">Worth checking</p>
  <ul><li>Step 3 has no description.</li></ul>
</div>
```

Use `role="alert"` only for errors that appear after an action. Badges never carry meaning by colour alone: the text says "Missing", not just red.

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
| `data-adm-combobox` (on a `<select>`) | Type-to-filter searchable select; `-url`, `-min` and the text attributes from `adm_combobox_data` |
| `data-adm-sortable`, `-item`, `-handle`, `-up`, `-down`, `-position`, `-fallback` | Reorderable lists; rendered by `reorder_controls` |

Content inserted after page load (other than Turbo frames, which are handled) needs `Administratum.enhance(element)` for comboboxes and sortable lists.
