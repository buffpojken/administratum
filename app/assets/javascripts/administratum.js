// Administratum runtime: islands, offcanvas panels, dropdowns, comboboxes,
// sortable lists, confirmations, flash messages and the light/dark toggle. Plain ES module, no dependencies.
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

const darkQuery = window.matchMedia("(prefers-color-scheme: dark)")

function storedTheme() {
  try {
    const value = localStorage.getItem(THEME_KEY)
    return value === "dark" || value === "light" ? value : null
  } catch (_error) {
    return null
  }
}

function applyTheme(theme) {
  const root = document.documentElement
  root.classList.remove("dark", "light")
  root.classList.add(theme)
}

function currentTheme() {
  return document.documentElement.classList.contains("dark") ? "dark" : "light"
}

function toggleTheme() {
  const next = currentTheme() === "dark" ? "light" : "dark"
  applyTheme(next)
  try {
    localStorage.setItem(THEME_KEY, next)
  } catch (_error) {
    // Storage unavailable (private mode); the choice lasts for this page only.
  }
}

// Follow the OS setting until the viewer picks a theme themselves.
darkQuery.addEventListener("change", (event) => {
  if (!storedTheme()) applyTheme(event.matches ? "dark" : "light")
})

// ------------------------------------------------------------------- flash --

function scheduleFlashDismissal(root = document) {
  root.querySelectorAll("[data-adm-flash]:not([data-adm-flash-scheduled])").forEach((el) => {
    el.dataset.admFlashScheduled = "true"
    setTimeout(() => el.remove(), 6000)
  })
}

// -------------------------------------------------------------- comboboxes --

// <select data-adm-combobox> becomes a type-to-filter input. The select stays
// in the form (visually hidden) and keeps submitting its param. With
// data-adm-combobox-url, options come from a JSON search endpoint instead:
// GET url?q=… returning [{ id, label, group }].

const COMBOBOX_SELECTOR = "select[data-adm-combobox]:not([multiple])"
const comboboxes = new WeakSet()
let comboboxCount = 0

// Case- and accent-insensitive matching: "Ange" finds "Ängel".
function fold(text) {
  return text.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
}

function enhanceComboboxes(root = document) {
  root.querySelectorAll(COMBOBOX_SELECTOR).forEach((select) => {
    if (comboboxes.has(select)) return
    // A Turbo snapshot restores the input without its listeners: rebuild it.
    const stale = select.previousElementSibling
    if (stale && stale.matches("[data-adm-combobox-wrapper]")) stale.remove()
    comboboxes.add(select)
    createCombobox(select)
  })
}

function createCombobox(select) {
  const id = `adm-combobox-${++comboboxCount}`
  const data = select.dataset
  const url = data.admComboboxUrl
  const minLength = Number(data.admComboboxMin || (url ? 2 : 0))
  const texts = {
    empty: data.admComboboxEmpty || "No matches",
    loading: data.admComboboxLoading || "Searching…",
    short: (data.admComboboxShort || "Type at least %{count} characters").replace("%{count}", minLength),
    error: data.admComboboxError || "Search failed"
  }

  const wrapper = document.createElement("div")
  wrapper.className = "adm-combobox"
  wrapper.dataset.admComboboxWrapper = ""
  const input = document.createElement("input")
  input.type = "text"
  input.className = "adm-input adm-combobox-input"
  input.autocomplete = "off"
  input.spellcheck = false
  input.disabled = select.disabled
  input.setAttribute("role", "combobox")
  input.setAttribute("aria-autocomplete", "list")
  input.setAttribute("aria-expanded", "false")
  input.setAttribute("aria-controls", `${id}-listbox`)
  const describedBy = select.getAttribute("aria-describedby")
  if (describedBy) input.setAttribute("aria-describedby", describedBy)
  const blank = select.querySelector('option[value=""]')
  if (blank && blank.textContent.trim()) input.placeholder = blank.textContent.trim()
  const listbox = document.createElement("div")
  listbox.id = `${id}-listbox`
  listbox.className = "adm-combobox-listbox"
  listbox.setAttribute("role", "listbox")
  listbox.hidden = true
  wrapper.append(input, listbox)
  select.before(wrapper)

  select.classList.add("adm-sr-only")
  select.tabIndex = -1
  select.setAttribute("aria-hidden", "true")
  const label = select.id && document.querySelector(`label[for="${CSS.escape(select.id)}"]`)
  if (label) {
    label.id ||= `${id}-label`
    input.setAttribute("aria-labelledby", label.id)
    label.addEventListener("click", (event) => {
      event.preventDefault()
      input.focus()
    })
  }

  let results = []
  let active = -1
  let typed = false
  let timer = null
  let controller = null

  const displayText = () => {
    const option = select.selectedOptions[0]
    return option && option.value !== "" ? option.textContent.trim() : ""
  }

  const localOptions = () => Array.from(select.options)
    .filter((option) => option.value !== "" && !option.disabled)
    .map((option) => ({
      value: option.value,
      label: option.textContent.trim(),
      group: option.parentElement instanceof HTMLOptGroupElement ? option.parentElement.label : ""
    }))

  // Every typed word must appear in the option's label or its group's label.
  const filterLocal = (query) => {
    const terms = fold(query).split(/\s+/).filter(Boolean)
    return localOptions().filter((option) => {
      const haystack = fold(`${option.group} ${option.label}`)
      return terms.every((term) => haystack.includes(term))
    })
  }

  function setActive(index) {
    listbox.querySelector(".adm-combobox-option-active")?.classList.remove("adm-combobox-option-active")
    active = index
    const option = index >= 0 ? document.getElementById(`${id}-option-${index}`) : null
    if (!option) {
      input.removeAttribute("aria-activedescendant")
      return
    }
    option.classList.add("adm-combobox-option-active")
    input.setAttribute("aria-activedescendant", option.id)
    option.scrollIntoView({ block: "nearest" })
  }

  function render(message) {
    listbox.replaceChildren()
    if (message) {
      const note = document.createElement("div")
      note.className = "adm-combobox-empty"
      note.textContent = message
      listbox.append(note)
    }
    let group = ""
    let container = listbox
    results.forEach((item, index) => {
      if (item.group !== group) {
        group = item.group
        container = listbox
        if (group) {
          container = document.createElement("div")
          container.setAttribute("role", "group")
          container.setAttribute("aria-labelledby", `${id}-group-${index}`)
          const heading = document.createElement("div")
          heading.id = `${id}-group-${index}`
          heading.className = "adm-combobox-group"
          heading.setAttribute("role", "presentation")
          heading.textContent = group
          container.append(heading)
          listbox.append(container)
        }
      }
      const option = document.createElement("div")
      option.id = `${id}-option-${index}`
      option.className = "adm-combobox-option"
      option.setAttribute("role", "option")
      option.setAttribute("aria-selected", String(item.value === select.value))
      option.dataset.index = index
      option.textContent = item.label
      container.append(option)
    })
    const selected = results.findIndex((item) => item.value === select.value)
    setActive(results.length ? Math.max(selected, 0) : -1)
  }

  function show() {
    listbox.hidden = false
    input.setAttribute("aria-expanded", "true")
  }

  function hide() {
    clearTimeout(timer)
    controller?.abort()
    listbox.hidden = true
    input.setAttribute("aria-expanded", "false")
    setActive(-1)
  }

  async function search(query) {
    controller?.abort()
    controller = new AbortController()
    const target = new URL(url, window.location.href)
    target.searchParams.set("q", query)
    try {
      const response = await fetch(target, { headers: { Accept: "application/json" }, credentials: "same-origin", signal: controller.signal })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)
      const items = await response.json()
      results = items.map((item) => ({ value: String(item.id), label: String(item.label ?? item.id), group: item.group ? String(item.group) : "" }))
      render(results.length ? null : texts.empty)
    } catch (error) {
      if (error.name === "AbortError") return
      console.error("[administratum] combobox search failed", error)
      results = []
      render(texts.error)
    }
  }

  // Until the viewer types, the input shows the current choice and the list shows everything.
  function update() {
    const query = typed ? input.value.trim() : ""
    show()
    if (!url) {
      results = query ? filterLocal(query) : localOptions()
      render(results.length ? null : texts.empty)
    } else if (query.length < minLength) {
      results = []
      render(texts.short)
    } else {
      clearTimeout(timer)
      results = []
      render(texts.loading)
      timer = setTimeout(() => search(query), 250)
    }
  }

  function choose(value, text) {
    let option = Array.from(select.options).find((candidate) => candidate.value === value)
    if (!option) {
      option = new Option(text, value)
      select.add(option)
    }
    if (select.value !== value) {
      select.value = value
      select.dispatchEvent(new Event("input", { bubbles: true }))
      select.dispatchEvent(new Event("change", { bubbles: true }))
    }
    input.setCustomValidity("")
    revert()
  }

  function revert() {
    typed = false
    input.value = displayText()
  }

  function move(delta) {
    if (!results.length) return
    setActive(Math.min(Math.max(active + delta, 0), results.length - 1))
  }

  revert()

  input.addEventListener("input", () => {
    typed = true
    input.setCustomValidity("")
    update()
  })
  input.addEventListener("click", () => {
    if (listbox.hidden) update()
  })
  input.addEventListener("keydown", (event) => {
    const open = !listbox.hidden
    switch (event.key) {
      case "ArrowDown":
      case "ArrowUp":
        event.preventDefault()
        if (!open) update()
        else if (!event.altKey) move(event.key === "ArrowDown" ? 1 : -1)
        break
      case "Enter":
        if (!open) return
        event.preventDefault()
        if (results[active]) choose(results[active].value, results[active].label)
        hide()
        break
      // Escape closes the list (or undoes typing) before it closes a panel.
      case "Escape":
        if (!open && !typed) return
        event.preventDefault()
        hide()
        revert()
        break
    }
  })
  // Clearing the text and leaving picks the blank option, when there is one.
  input.addEventListener("blur", () => {
    hide()
    if (typed && input.value.trim() === "" && blank) choose("", "")
    else revert()
  })
  listbox.addEventListener("mousedown", (event) => event.preventDefault())
  listbox.addEventListener("click", (event) => {
    const option = event.target instanceof Element ? event.target.closest('[role="option"]') : null
    if (!option) return
    const item = results[Number(option.dataset.index)]
    choose(item.value, item.label)
    hide()
  })
  // Label clicks and panel autofocus land on the hidden select: pass focus on.
  select.addEventListener("focus", () => input.focus())
  select.addEventListener("change", () => {
    if (document.activeElement !== input) revert()
  })
  // The browser can't point at a hidden select, so report on the input.
  select.addEventListener("invalid", (event) => {
    event.preventDefault()
    input.setCustomValidity(select.validationMessage)
    input.reportValidity()
  })
}

// --------------------------------------------------------------- sortables --

// [data-adm-sortable] holds [data-adm-sortable-item] children, each with the
// controls from reorder_controls. Without JS those are position number fields;
// with it, drag handles and move up/down buttons that renumber the fields.

const sortables = new WeakSet()
let drag = null
let liveRegion = null

function sortableItems(list) {
  return Array.from(list.children).filter((child) => child.matches("[data-adm-sortable-item]"))
}

function enhanceSortables(root = document) {
  root.querySelectorAll("[data-adm-sortable]").forEach((list) => {
    if (sortables.has(list)) return
    sortables.add(list)
    list.querySelectorAll("[data-adm-sortable-handle], [data-adm-sortable-up], [data-adm-sortable-down]").forEach((el) => { el.hidden = false })
    list.querySelectorAll("[data-adm-sortable-fallback]").forEach((el) => { el.hidden = true })
    refreshSortable(list)
  })
}

function refreshSortable(list) {
  const items = sortableItems(list)
  items.forEach((item, index) => {
    const position = item.querySelector("[data-adm-sortable-position]")
    if (position) position.value = index + 1
    const up = item.querySelector("[data-adm-sortable-up]")
    if (up) up.disabled = index === 0
    const down = item.querySelector("[data-adm-sortable-down]")
    if (down) down.disabled = index === items.length - 1
  })
}

function announceMove(list, item) {
  if (!liveRegion || !liveRegion.isConnected) {
    liveRegion = document.createElement("div")
    liveRegion.className = "adm-sr-only"
    liveRegion.setAttribute("aria-live", "polite")
    document.body.append(liveRegion)
  }
  const items = sortableItems(list)
  const template = item.querySelector("[data-adm-sortable-moved]")?.dataset.admSortableMoved || "Moved to position %{position} of %{count}"
  liveRegion.textContent = template.replace("%{position}", items.indexOf(item) + 1).replace("%{count}", items.length)
}

function sortableItemFor(control) {
  const item = control.closest("[data-adm-sortable-item]")
  return item && sortables.has(item.parentElement) ? item : null
}

// Moves an item one step and keeps focus on the control that moved it, or on
// its opposite button once it reaches the end of the list.
function moveSortable(item, delta, control) {
  const list = item.parentElement
  const items = sortableItems(list)
  const target = items[items.indexOf(item) + delta]
  if (!target) return
  if (delta < 0) target.before(item)
  else target.after(item)
  refreshSortable(list)
  const fallback = item.querySelector(delta < 0 ? "[data-adm-sortable-down]" : "[data-adm-sortable-up]")
  ;(control.disabled ? fallback : control)?.focus()
  announceMove(list, item)
}

document.addEventListener("keydown", (event) => {
  if (event.key !== "ArrowUp" && event.key !== "ArrowDown") return
  const handle = event.target instanceof Element ? event.target.closest("[data-adm-sortable-handle]") : null
  const item = handle && sortableItemFor(handle)
  if (!item) return
  event.preventDefault()
  moveSortable(item, event.key === "ArrowUp" ? -1 : 1, handle)
})

document.addEventListener("pointerdown", (event) => {
  if (event.button !== 0) return
  const handle = event.target instanceof Element ? event.target.closest("[data-adm-sortable-handle]") : null
  const item = handle && sortableItemFor(handle)
  if (!item) return
  event.preventDefault()
  handle.setPointerCapture(event.pointerId)
  item.classList.add("adm-sortable-dragging")
  drag = { item, list: item.parentElement }
})

// The dragged item goes just before the first other item whose midpoint is
// below the pointer, or last when there is none.
document.addEventListener("pointermove", (event) => {
  if (!drag) return
  const { item, list } = drag
  const items = sortableItems(list)
  const others = items.filter((other) => other !== item)
  const next = others.find((other) => {
    const rect = other.getBoundingClientRect()
    return event.clientY < rect.top + rect.height / 2
  })
  const current = items[items.indexOf(item) + 1]
  if (next === current) return
  if (next) next.before(item)
  else others.at(-1)?.after(item)
  refreshSortable(list)
})

function endDrag() {
  if (!drag) return
  drag.item.classList.remove("adm-sortable-dragging")
  announceMove(drag.list, drag.item)
  drag = null
}
document.addEventListener("pointerup", endDrag)
document.addEventListener("pointercancel", endDrag)

function enhance(root = document) {
  enhanceComboboxes(root)
  enhanceSortables(root)
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

  const mover = target.closest("[data-adm-sortable-up], [data-adm-sortable-down]")
  const moved = mover && sortableItemFor(mover)
  if (moved) {
    moveSortable(moved, mover.matches("[data-adm-sortable-up]") ? -1 : 1, mover)
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

// A control that handled Escape itself (an open combobox) prevents the default.
document.addEventListener("keydown", (event) => {
  if (event.key !== "Escape" || event.defaultPrevented) return
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
  enhance()
  scheduleFlashDismissal()
}

document.addEventListener("DOMContentLoaded", boot)
document.addEventListener("turbo:load", boot)
document.addEventListener("turbo:frame-load", (event) => enhance(event.target))
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
// Enhances comboboxes and sortable lists in HTML inserted after page load.
Administratum.enhance = enhance

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
