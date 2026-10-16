# frozen_string_literal: true

namespace :administratum do
  desc "Create an admin user: EMAIL=you@example.com [PASSWORD=secret]"
  task create_user: :environment do
    email = ENV.fetch("EMAIL") { abort "Set EMAIL=you@example.com" }
    password = ENV["PASSWORD"].presence || SecureRandom.base58(16)
    user = Administratum::User.create!(email:, password:, password_confirmation: password)
    puts "Created #{user.email}"
    puts "Password: #{password}" if ENV["PASSWORD"].blank?
  end

  namespace :tailwind do
    desc "Write the import file that adds Administratum to your own Tailwind v4 build"
    task :sync do
      require "administratum/tailwind"
      path = Administratum::Tailwind.write(ENV.fetch("OUTPUT", "app/assets/tailwind/administratum.gen.css"))
      puts "Wrote #{path}"
    end
  end
end

# Keep the generated import file current wherever assets are built.
# Declaring the prerequisite (rather than looking the task up) works whichever
# order the rake files load in.
if File.exist?("app/assets/tailwind/administratum.gen.css")
  %w[assets:precompile vite:build].each { |name| task(name).enhance(["administratum:tailwind:sync"]) }
end
