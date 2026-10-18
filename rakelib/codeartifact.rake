# frozen_string_literal: true

# Publishing to the private gem repository on AWS CodeArtifact.
# Lives in rakelib/ (not lib/tasks/) so it isn't packaged into the gem or loaded by host apps.
module CodeArtifact
  DOMAIN = "greyseal"
  OWNER  = "791515923336"
  REGION = "eu-north-1"
  REPO   = "gems"
  URL    = "https://#{DOMAIN}-#{OWNER}.d.codeartifact.#{REGION}.amazonaws.com/ruby/#{REPO}".freeze
  # Root can't get CodeArtifact tokens, so default to an IAM user's profile. Set CODEARTIFACT_PROFILE to override.
  PROFILE = ENV.fetch("CODEARTIFACT_PROFILE", "buffpojken-cli")

  def self.token
    token = `aws codeartifact get-authorization-token --domain #{DOMAIN} --domain-owner #{OWNER} \
             --region #{REGION} --profile #{PROFILE} --query authorizationToken --output text`.strip
    abort "Could not get a CodeArtifact token. Are your AWS credentials set up?" unless $?.success? && !token.empty?
    token
  end
end

namespace :codeartifact do
  desc "Build, tag and push the current version to CodeArtifact (#{CodeArtifact::URL})"
  task :release do
    ENV["GEM_HOST_API_KEY"] = "Bearer #{CodeArtifact.token}"
    Rake::Task["release"].invoke

    # gem push exits 0 even when the server rejects the upload, so check that the version actually landed.
    require_relative "../lib/administratum/version"
    published = `aws codeartifact describe-package-version --domain #{CodeArtifact::DOMAIN} \
                 --domain-owner #{CodeArtifact::OWNER} --region #{CodeArtifact::REGION} --profile #{CodeArtifact::PROFILE} \
                 --repository #{CodeArtifact::REPO} --format ruby --package administratum \
                 --package-version #{Administratum::VERSION} --query packageVersion.status --output text 2>&1`.strip
    abort "Push failed: #{Administratum::VERSION} is not in CodeArtifact (#{published})" unless published == "Published"
    puts "administratum #{Administratum::VERSION} is published on CodeArtifact."
  end

  desc "List published versions on CodeArtifact"
  task :versions do
    sh "aws codeartifact list-package-versions --domain #{CodeArtifact::DOMAIN} --domain-owner #{CodeArtifact::OWNER} " \
       "--region #{CodeArtifact::REGION} --profile #{CodeArtifact::PROFILE} --repository #{CodeArtifact::REPO} --format ruby --package administratum " \
       "--query 'versions[].[version,status]' --output text"
  end
end
