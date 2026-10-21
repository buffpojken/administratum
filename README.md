# Administratum

A Rails admin engine where every adminable resource is one file in `app/admin`.
You get a Tailwind v4 CRUD UI with Devise login out of the box. When the defaults
stop fitting, you can replace any part of it: a field, a partial, a whole page, or
a JS island running Vue, React or anything else.

- One class per resource, and that class is a real controller.
- Index, show, new, edit and delete, with filters (Ransack) and pagination (Pagy).
- A field DSL with built-in types, plus your own types backed by a partial.
- Template overrides by file location: `app/views/admin/<resource>/edit.html.erb`.
- Nested resources, shallow or not.
- Custom member and collection actions, and buttons that trigger them.
- Framework-agnostic JS islands, mounted with props from ERB.
- Styling through design tokens. Use the bundled CSS, or build it with your own Tailwind v4.

Requires Rails 8, with Propshaft or Sprockets. With Sprockets, add `//= link administratum.css` and
`//= link administratum.js` to `app/assets/config/manifest.js`.

## Install

```ruby
gem "administratum", "~> 0.2"
```

### Switching from CodeArtifact or a git source

- Replace the `source "https://greyseal-…codeartifact…" do` block (or the `git:` line) with the line above,
  then run `bundle update administratum`.
- Drop the CodeArtifact token from the Kamal `builder.secrets`, `.kamal/secrets` and the
  `RUN --mount=type=secret` in the Dockerfile.
- Unset `bundle config local.administratum` if you set it (add `--global` if it was set there).
- To work against a local checkout, temporarily use `gem "administratum", path: "../administratum"`. Don't commit it.

### Setting up an app

```sh
bin/rails g administratum:install          # initializer, migration, app/admin, mount at /administratum
bin/rails db:migrate
bin/rails administratum:create_user EMAIL=you@example.com
bin/rails g administratum:resource Post    # app/admin/post_admin.rb
```

### Alongside ActiveAdmin

ActiveAdmin also uses `app/admin`, and removes it from Zeitwerk. Administratum skips that directory
with a warning in the log, so nothing breaks. Its resources then need a directory of their own, and
**this initializer should ship in the same deploy as the Gemfile change**:

```ruby
# config/initializers/administratum.rb
Administratum.configure do |config|
  config.resource_paths = ["app/admin_next"]
  config.view_prefix = "admin_next"        # templates in app/views/admin_next/<resource>/
end
```

Mount the engine away from ActiveAdmin's path with `bin/rails g administratum:install --path=/admin_next`.
Once ActiveAdmin is gone, move everything back to `app/admin` and drop both settings.

## Resources

```ruby
# app/admin/post_admin.rb
class PostAdmin < Administratum::Resource
  model Post                       # inferred from the class name when omitted
  title :title                     # display name of a record (default: title/name)
  label "Article", plural: "Articles"

  filters :title, :published, :category_id   # default: the title attribute
  filter :language, as: :select, collection: %w[en sv]

  index sort: "created_at desc", per_page: 50, csv: true do
    column :title
    column :category                # belongs_to: links to the record
    column :published               # booleans render as badges
    column(:comments, sortable: false) { |post| post.comments.size }   # runs in the view
    column(:preview, csv: false) { |post| link_to "Preview", post }    # left out of the CSV
  end

  form do
    field :title, hint: "Shown in listings"
    field :body, as: :textarea, rows: 8
    field :published
    field :category_id              # inferred :belongs_to select
    field :tag_ids                  # inferred :has_many_ids multi-select
    field :status, as: :select, collection: -> { Post::STATUSES }
  end

  show do                           # default: id, form fields, timestamps
    attribute :title
    attribute(:words) { |post| post.body.to_s.split.size }
    attribute :published_at, if: ->(post) { post.published? }   # row hidden otherwise
  end

  permit :title, :body, :published, :category_id, tag_ids: []   # default: the form fields
  scope { |posts| posts.includes(:category) }                    # every query starts here
  scope :published                                               # index tab, calls Post.published
  actions except: :destroy                                       # :index :show :new :edit :destroy
  menu label: "Articles", priority: 10                           # `menu false` hides it
end
```

A resource class is a controller (`Administratum::Resource < ActionController::Base`
by default). Everything you'd do in a controller works: `before_action`, `rescue_from`,
`helper`, overriding `resource_params` or `scoped_collection`, and so on. In views, the
current record is `@resource`, the index records are `@resources`, and the parent of a
nested resource is `@parent`.

For a namespaced model (`model ActsAsTaggableOn::Tag`), Rails derives the route key and form
params from the full name: `/acts_as_taggable_on_tags` and `params[:acts_as_taggable_on_tag]`.
Set `route :tags` for a shorter URL. The param key stays the same, so `permit` and
`resource_params` work as usual.

Resource files are loaded to draw routes, so the DSL never touches the database at
class load. Types and defaults are resolved when a request is made.

### Field types

| Type | Notes |
|---|---|
| `string` | Default for string columns |
| `textarea` | `rows:` |
| `number` | `step:`, `min:`, `max:` |
| `boolean` | |
| `select` | `collection:` takes an array, a relation, or a lambda (optionally receiving the record); `include_blank:` |
| `multi_select` | Permitted as an array |
| `belongs_to` | Inferred for `*_id` belongs_to columns |
| `has_many_ids` | Inferred for `*_ids`; permitted as an array |
| `date` | Text input for ISO dates (YYYY-MM-DD), whatever the browser locale |
| `datetime` | Text input for YYYY-MM-DD HH:MM, parsed in the app time zone |
| `email` | |
| `password` | |
| `hidden` | |
| `json` | Pretty-printed textarea |
| `island` | Rendered by a JS island (see below): `island: "name", props: ->(record) { {...} }` |

Every field also takes these options:

| Option | Effect |
|---|---|
| `label:` | Overrides the label. Defaults to the attribute's human name, with `tag_ids` shown as "Tags". |
| `hint:` | Help text shown under the input and linked to it with `aria-describedby`. |
| `placeholder:` | Placeholder text. On selects it becomes the blank option's text. |
| `required:` | Shows or hides the required marker. Defaults to whether the model validates presence. |
| `input_html: {}` | Extra HTML attributes on the input. |

Custom field partials get the same wiring by building their attributes with `input_options(field, form:, class: "adm-input")`.

Register your own type with a partial:

```ruby
# config/initializers/administratum.rb
config.field_types.register :color, partial: "admin/fields/color"           # param: :scalar (default)
config.field_types.register :tag_list, partial: "admin/fields/tags", param: :array
```

```erb
<%# app/views/admin/fields/_color.html.erb — locals: form, field, resource, value %>
<%= form.color_field field.name, class: "adm-input" %>
```

The label, hint and errors wrapper is added for you. To restyle a built-in type,
shadow its partial at `app/views/administratum/fields/_<type>.html.erb`.

### Index scopes

Named scopes become tabs above the index table, each with a record count:

```ruby
class PostAdmin < Administratum::Resource
  scope :all                                               # Post.all
  scope :published                                         # Post.published
  scope(:recent, label: "This week") { |posts| posts.where(created_at: 1.week.ago..) }
  scope :archived, count: false                            # skip the count query
end
```

- The first tab is active unless one says `default: true`. The URL carries `?scope=published`.
- Counts and results respect the current filters. Switching tabs keeps filters and sorting, and goes back to page 1.
- The CSV export follows the active tab.
- Labels default to `administratum.scopes.<name>` in your locale, then to the humanized name.
- `scope` with only a block (no name) still sets the base query for every request, not a tab.
- In a custom `index.html.erb`, render the tabs with `<%= index_scope_tabs %>`.

### Template overrides

Templates are looked up in `app/views/admin/<route_key>/` first, then in the engine.
To replace a page, add a file:

| File | Replaces |
|---|---|
| `index.html.erb` | The index page |
| `show.html.erb` | The show page |
| `new.html.erb` / `edit.html.erb` | The whole page |
| `_form.html.erb` | Only the form, on both new and edit |
| `_table.html.erb` / `_attributes.html.erb` | The index table / the show attribute list |
| `<custom_action>.html.erb` | A custom action's page |

You can also point `form template: "admin/posts/editor"` at a partial elsewhere.
To keep these templates somewhere other than `app/views/admin` (for example while an
older admin still lives there), set `config.view_prefix = "admin_next"`.

Helpers available in templates:

```erb
<%= page_header title: "Write #{@resource.title}" do %>
  <%= buttons_for(:show) %>                         <%# built-in plus custom buttons for a page %>
<% end %>

<%= administratum_form do |form| %>                 <%# form_with with the right URL and method %>
  <%= render_fields form, except: [:body] %>        <%# DSL fields %>
  <%= render_field form, :body %>                   <%# a single DSL field %>
  <%= render_field form, :notes, as: :textarea %>   <%# an ad-hoc field %>
  <%= adm_date_field form, :ends_on %>              <%# ISO date input; also adm_datetime_field %>
  <%= form.submit class: "adm-btn adm-btn-primary" %>
<% end %>
```

Path helpers:
- `collection_path`, `new_resource_path`, `resource_path(record)`, `edit_resource_path(record)`
- `resource_form_path(record)`, `action_path(:write, record)`, `parent_path`
- `paths_for(OtherAdmin).index`, for paths to another resource

Layout helpers: `card(title:) { }`, `island`, `record_title`, `format_value`.

### Nested resources

```ruby
class CommentAdmin < Administratum::Resource
  parent :post, shallow: true   # association defaults to post.comments
end
```

- Collection routes (index, new, create) nest under the parent: `/posts/1/comments`.
- Shallow member routes stand alone: `/comments/5/edit`. Without `shallow:`, they also nest.
- Queries go through the parent's association, so a child of another parent returns 404.
- Breadcrumbs include the parent.
- Nested resources are left out of the menu. Link to them with a button (below).

One level of nesting is supported.

### Custom actions and buttons

```ruby
class PostAdmin < Administratum::Resource
  member_action :write                         # GET, renders admin/posts/write.html.erb
  member_action :save_body, method: :patch
  member_action :publish, method: :post
  collection_action :export
  collection_action :import, method: :post

  button :write, on: %i[show row], style: :primary
  button :publish, on: :show, confirm: "Publish?", if: ->(post) { !post.published? }
  button :comments, on: :show, to: ->(post) { post_comments_path(post) }   # plain link
  button :import, on: :index, upload: ".json"                              # file upload panel
  button :add_tag, on: :show, panel: "admin/posts/add_tag"                 # your partial in a side panel

  def save_body
    @resource.update!(body: params.require(:body))
    render json: { body: @resource.body }
  end

  def publish
    @resource.update!(published: true)
    redirect_to resource_path, notice: "Published"
  end

  def export = send_data(Post.export_json, filename: "posts.json")

  def import
    Post.import_json(params.require(:file).read)
    redirect_to collection_path
  end
end
```

Button options:
- `on:` takes `:index`, `:show`, `:new`, `:edit` or `:row` (one button per index row).
- `style:` takes `:primary`, `:secondary`, `:danger` or `:ghost`.
- `if:` and `to:` lambdas run in the view and receive the record when they take an argument.

Non-GET buttons render as small forms, so no rails-ujs is needed.

A panel partial receives `resource:` and `button:`.

## Pages

A page is a screen that isn't CRUD on one model, like a report, a tool or a status page. It
lives in `app/admin` like a resource, gets a menu entry and a route, and is a controller:

```ruby
# app/admin/reports_page.rb
class ReportsPage < Administratum::Page
  label "Reports"                          # default: from the class name
  menu priority: 5                         # or `menu false`
  page_action :refresh, method: :post      # POST /administratum/reports/refresh
  page_action :weekly                      # GET  /administratum/reports/weekly
  button :refresh, confirm: "Refresh?", style: :primary   # buttons go in the page header
  button :weekly

  def index
    @stats = Stats.compute
  end

  def refresh
    Stats.refresh!
    redirect_to page_path, notice: "Refreshed"
  end
end
```

```erb
<%# app/views/admin/reports/_content.html.erb: the default index renders the header, then this %>
<%= card title: "Posts" do %><%= @stats[:posts] %><% end %>
```

- Templates live in `app/views/admin/<route_key>/`. The route key comes from the class name
  (`ReportsPage` is `reports`), or set it with `route :stats`.
- Replace the whole page with `index.html.erb`. A GET `page_action` without a method renders `<name>.html.erb`.
- In templates and the class: `page_path`, `action_path(:refresh)`, and `page_class`.
- From elsewhere: `administratum.reports_page_path` and `administratum.refresh_reports_page_path`.
- Pages have the same sign-in, layout, `before_action` and `helper` support as resources.
- Pagy is included, so `@pagy, @rows = pagy(scope)` and `<%== pagy_nav(@pagy) %>` work on pages too.

## JS islands

An island is a mount point with JSON props. What runs inside it is up to you:

```erb
<%= island :post_writer, props: { body: @resource.body, saveUrl: action_path(:save_body) } %>
```

```js
// your admin JS, loaded through config.head
import { createApp } from "vue"
import PostWriter from "./PostWriter.vue"

window.Administratum.islands.register("post-writer", (el, props) => {
  const app = createApp(PostWriter, props)   // props.csrfToken is always present
  app.mount(el)
  return () => app.unmount()                  // teardown, called before Turbo swaps the page
})
```

- Islands mount on `DOMContentLoaded` and `turbo:load`, and never twice.
- If your script can run before Administratum's, queue registrations: `(window.Administratum ||= { islands: { queue: [] } }).islands.queue.push([name, fn])`.
- `Administratum.csrfToken()` is also available.

Load your own JS and CSS with any asset pipeline:

```ruby
config.head = ->(view) { view.javascript_importmap_tags("admin") }   # importmap
config.head = ->(view) { view.vite_javascript_tag("admin") }         # vite_ruby
config.head_partial = "admin/head"                                    # or a partial
```

## Styling

All colours are CSS variables (`--color-adm-*`), so theming never needs a rebuild:

```ruby
config.theme = { primary: "#7c3aed", bg: "#fafafa" }
config.dark_theme = { primary: "#a78bfa" }
```

The available tokens are listed in [DESIGN.md](DESIGN.md).

**Host Tailwind v4.** If your app already builds Tailwind v4, compile Administratum into
your own build so tokens live in your `@theme`:

```sh
bin/rails administratum:tailwind:sync   # writes app/assets/tailwind/administratum.gen.css (gitignore it)
```

```css
@import "tailwindcss";
@import "./administratum.gen.css";
@theme { --color-adm-primary: var(--color-brand); }
```

```ruby
config.stylesheet = :host   # stop loading the bundled stylesheet
```

Once the generated file exists, the sync task runs before `assets:precompile` and `vite:build`.

## Configuration

See the generated `config/initializers/administratum.rb` for every option. The main ones:
- `app_name`, `logo`, `dashboard`
- `parent_controller`, `helpers`, `per_page`
- `mailer_sender`, `manage_users`
- `head`, `head_partial`, `theme`, `stylesheet`, `field_types`

## Authentication

- **Accounts.** Admins are `Administratum::User` records (table `administratum_users`) on a separate Devise scope, `:administratum_user`. They never collide with your app's own users.
- **Sign-out.** Signing out of the admin leaves the app's session alone.
- **Password reset.** Built in. The reset form doesn't reveal whether an email exists.
- **Current admin.** Available in views as `current_admin`.

## Development

```sh
bundle install
bin/rails test
bundle exec rubocop
bin/build-css          # rebuild app/assets/builds/administratum.css after changing views or CSS
```

The dummy app in `test/dummy` exercises each extension point:
- custom field type, write page with an island, and export/import (posts)
- shallow nesting (comments) and non-shallow nesting (attachments)
- custom index template (categories) and custom form partial (tags)

## Releasing

Releases go to [rubygems.org](https://rubygems.org/gems/administratum).

1. Bump `Administratum::VERSION` in `lib/administratum/version.rb`, run `bundle install` to update
   `Gemfile.lock`, and commit and push to `main`.
2. In GitHub, run the **Release** workflow (Actions → Release → Run workflow).

The workflow builds the gem, tags `vX.Y.Z`, pushes the tag and pushes the gem. It uses rubygems.org
trusted publishing, so no API key is stored anywhere.

To release from your own machine instead, run `bundle exec rake release` with a clean working tree.
It asks for your rubygems.org login and an MFA code.

Host apps pick up the new version with `bundle update administratum`.
