// A plain-JS island: a textarea that saves through a JSON member action.
window.Administratum.islands.register("post-writer", (el, props) => {
  el.innerHTML = '<textarea class="adm-input" rows="10"></textarea><button type="button" class="adm-btn adm-btn-primary">Save</button>'
  const textarea = el.querySelector("textarea")
  textarea.value = props.body || ""
  el.querySelector("button").addEventListener("click", () => {
    fetch(props.saveUrl, {
      method: "PATCH",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": props.csrfToken },
      body: JSON.stringify({ body: textarea.value })
    })
  })
  return () => { el.innerHTML = "" }
})
