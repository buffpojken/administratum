# frozen_string_literal: true

module Administratum
  module ApplicationHelper
    include Pagy::Frontend
    include Administratum::LayoutHelper
    include Administratum::FormHelper
    include Administratum::ResourceHelper
    include Administratum::IslandHelper
    include Administratum::ReorderHelper
  end
end
