// Administratum runtime: islands, offcanvas panels, dropdowns, confirmations,
// flash messages and the light/dark toggle. Plain ES module, no dependencies.
// Behaviour is attached with event delegation, so it survives Turbo page swaps.

function install() {
const ISLAND_SELECTOR = "[data-administratum-island]"
const THEME_KEY = "administratum-theme"

// ---------------------------------------------------------------- islands --

const islands = new Map()
const mounted = new Map()

function readProps(el) {
  const script = el.querySelector(':scope > script[type="application/json"]')
  if (!script) return {}
  try {
    return JSON.parse(script.textContent || "{}")
  } catch (error) {
    console.error(`[administratum] invalid props for island "${el.dataset.administratumIsland}"`, error)
    return {}
  }
}

function mountIslands(root = document) {
  root.querySelectorAll(ISLAND_SELECTOR).forEach((el) => {
    if (mounted.has(el)) return
    const mount = islands.get(el.dataset.administratumIsland)
    if (!mount) return

    const props = readProps(el)
    const teardown = mount(el, props)
    mounted.set(el, typeof teardown === "function" ? teardown : null)
    el.dataset.administratumMounted = "true"
  })
}

function unmountIslands() {
  mounted.forEach((teardown, el) => {
    try {
      if (teardown) teardown()
    } catch (error) {
      console.error("[administratum] island teardown failed", error)
    }
    delete el.dataset.administratumMounted
  })
  mounted.clear()
}

// register("chapter-editor", (el, props) => { ...; return () => cleanup() })
function register(name, mount) {
  islands.set(name, mount)
  if (document.readyState !== "loading") mountIslands()
}

// --------------------------------------------------------------- offcanvas --

let lastTrigger = null

function openPanel(name, trigger) {
  const panel = document.querySelector(`[data-adm-offcanvas="${CSS.escape(name)}"]`)
  if (!panel) return
  lastTrigger = trigger || null
  panel.hidden = false
  document.documentElement.classList.add("adm-scroll-lock")
  requestAnimationFrame(() => {
    panel.classList.add("adm-offcanvas-open")
    const focusable = panel.querySelector("input:not([type=hidden]), select, textarea, button:not([data-adm-offcanvas-close])")
    if (focusable) focusable.focus()
  })
}

function closePanels() {
  document.querySelectorAll(".adm-offcanvas-open").forEach((panel) => {
    panel.classList.remove("adm-offcanvas-open")
    panel.hidden = true
  })
  document.documentElement.classList.remove("adm-scroll-lock")
  if (lastTrigger) lastTrigger.focus()
  lastTrigger = null
}

// --------------------------------------------------------------- dropdowns --

function closeDropdowns(except) {
  document.querySelectorAll("[data-adm-dropdown]").forEach((dropdown) => {
    if (dropdown === except) return
    const menu = dropdown.querySelector("[data-adm-dropdown-menu]")
    const toggle = dropdown.querySelector("[data-adm-dropdown-toggle]")
    if (menu) menu.hidden = true
    if (toggle) toggle.setAttribute("aria-expanded", "false")
  })
}

// ------------------------------------------------------------------- theme --

function currentTheme() {
  const root = document.documentElement
  if (root.classList.contains("dark")) return "dark"
  if (root.classList.contains("light")) return "light"
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
}

function toggleTheme() {
  const next = currentTheme() === "dark" ? "light" : "dark"
  const root = document.documentElement
  root.classList.remove("dark", "light")
  root.classList.add(next)
  try {
    localStorage.setItem(THEME_KEY, next)
  } catch (_error) {
    // Storage unavailable (private mode); the choice lasts for this page only.
  }
}

// ------------------------------------------------------------------- flash --

function scheduleFlashDismissal(root = document) {
  root.querySelectorAll("[data-adm-flash]:not([data-adm-flash-scheduled])").forEach((el) => {
    el.dataset.admFlashScheduled = "true"
    setTimeout(() => el.remove(), 6000)
  })
}

// ------------------------------------------------------------------ events --

document.addEventListener("click", (event) => {
  const target = event.target instanceof Element ? event.target : null
  if (!target) return

  const opener = target.closest("[data-adm-offcanvas-open]")
  if (opener) {
    event.preventDefault()
    openPanel(opener.dataset.admOffcanvasOpen, opener)
    return
  }

  if (target.closest("[data-adm-offcanvas-close]")) {
    event.preventDefault()
    closePanels()
    return
  }

  const dropdownToggle = target.closest("[data-adm-dropdown-toggle]")
  if (dropdownToggle) {
    const dropdown = dropdownToggle.closest("[data-adm-dropdown]")
    const menu = dropdown.querySelector("[data-adm-dropdown-menu]")
    const willOpen = menu.hidden
    closeDropdowns(dropdown)
    menu.hidden = !willOpen
    dropdownToggle.setAttribute("aria-expanded", String(willOpen))
    return
  }
  if (!target.closest("[data-adm-dropdown]")) closeDropdowns()

  const toggle = target.closest("[data-adm-toggle]")
  if (toggle) {
    const el = document.getElementById(toggle.dataset.admToggle)
    if (el) {
      const open = el.classList.toggle("adm-open")
      toggle.setAttribute("aria-expanded", String(open))
    }
    return
  }

  if (target.closest("[data-adm-theme-toggle]")) {
    toggleTheme()
    return
  }

  const dismiss = target.closest("[data-adm-dismiss]")
  if (dismiss) dismiss.parentElement.remove()
})

document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape") return
  closePanels()
  closeDropdowns()
})

// Forms with data-adm-confirm ask before submitting (button_to delete etc.).
document.addEventListener("submit", (event) => {
  const form = event.target
  if (!(form instanceof HTMLFormElement)) return
  const message = form.dataset.admConfirm
  if (message && !window.confirm(message)) {
    event.preventDefault()
    event.stopImmediatePropagation()
  }
}, true)

function boot() {
  mountIslands()
  scheduleFlashDismissal()
}

document.addEventListener("DOMContentLoaded", boot)
document.addEventListener("turbo:load", boot)
document.addEventListener("turbo:before-render", () => {
  closePanels()
  unmountIslands()
})
if (document.readyState !== "loading") boot()

// ------------------------------------------------------------------ public --

const Administratum = window.Administratum || {}
Administratum.loaded = true
const queued = (Administratum.islands && Administratum.islands.queue) || []

Administratum.islands = {
  register,
  mount: mountIslands,
  unmount: unmountIslands
}
Administratum.csrfToken = () => document.querySelector('meta[name="csrf-token"]')?.content
Administratum.openPanel = openPanel
Administratum.closePanels = closePanels

window.Administratum = Administratum

// Islands registered before this script ran:
// (window.Administratum ||= { islands: { queue: [] } }).islands.queue.push([name, fn])
queued.forEach(([name, mount]) => register(name, mount))

return Administratum
}

// Loading this file twice (e.g. a host bundle that also imports it) would bind
// every listener twice and replace the island registry, so only install once.
const Administratum = window.Administratum && window.Administratum.loaded ? window.Administratum : install()

export default Administratum
