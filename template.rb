# generate(:scaffold, "person name:string")
# route "root to: 'people#index'"
# rails_command("db:migrate")

include_spina_cms = yes?("Include Spina CMS? (Y/n)")
action_mailer_host = ask("Action::Mailer host (with protocol)? (leave blank to set it later)")
dev_db_host = ask("Dev DB host? (leave blank to use localhost)") || "localhost"
dev_db_port = ask("Dev DB port? (leave blank to use 5432)") || "5432"
dev_db_user = ask("Dev DB user? (leave blank to use the underscored app name)") || ''
dev_db_pass = ask("Dev DB password? (leave blank to use no password)") || ''

gem "nokogiri"
gem "pg"
gem "bcrypt"
gem "image_processing", "~> 1.2"
gem "phlex", "~> 2.0.0.rc1"
gem "phlex-rails", "~> 2.0.0.rc1"

gem "spina", "~> 2.18" if include_spina_cms

gem_group :development, :test do
  gem "dotenv-rails"
  gem "ruby-lsp"

  gem "rubocop", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
end

gem_group :development do
  gem "overmind"
end

gem_group :test do
  gem "database_cleaner"
  gem "phlex-testing-nokogiri"
  gem "rspec"
  gem "rspec-rails"
  gem "rspec-activemodel-mocks"
end

run "yarn add -D daisyui@latest"
run "yarn add -D @tailwindcss/aspect-ratio"
run "yarn add -D @tailwindcss/container-queries"
run "yarn add -D @tailwindcss/forms"
run "yarn add -D @tailwindcss/typography"
run "yarn add -D postcss"

environment "config.action_mailer.default_url_options = {host: '#{action_mailer_host}'}", env: "production" unless action_mailer_host.to_s.strip.empty?

file "config/tailwind.config.js", <<-CODE
/** @type {import('tailwindcss').Config} */

const plugin = require('tailwindcss/plugin')

module.exports = {
  content: [
    "./app/**/*.{html,js,rb,erb}",
  ],
  theme: {
    extend: {
      textShadow: {
        sm: '0 1px 2px var(--tw-shadow-color)',
        DEFAULT: '0 2px 4px var(--tw-shadow-color)',
        lg: '0 8px 16px var(--tw-shadow-color)',
      },
    },
    fontFamily: {
      sans: ['Karla', 'sans-serif'],
      serif: ['Times New Roman', 'serif'],
    },
  },
  plugins: [
    plugin(function ({ matchUtilities, theme }) {
      matchUtilities(
        {
          'text-shadow': (value) => ({
            textShadow: value,
          }),
        },
        { values: theme('textShadow') }
      )
    }),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/container-queries'),
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('daisyui'),
  ]
}
CODE

remove_file 'config/database.yml'
file 'config/database.yml', <<-CODE
  default: &default
    adapter: postgresql
    encoding: unicode
    # For details on connection pooling, see Rails configuration guide
    # http://guides.rubyonrails.org/configuring.html#database-pooling
    pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

  development:
    <<: *default
    database: <%= Rails.application.class.module_parent_name.underscore %>_development

    # The specified database role being used to connect to postgres.
    # To create additional roles in postgres see `$ createuser --help`.
    # When left blank, postgres will use the default role. This is
    # the same name as the operating system user that initialized the database.
    username: <%= '#{dev_db_user}'.present? ? '#{dev_db_user}' : Rails.application.class.module_parent_name.underscore %>

    # The password associated with the postgres role (username).
    #{dev_db_pass.to_s.strip.empty? ? '# ' : ''}password: #{dev_db_pass}

    # Connect on a TCP socket. Omitted by default since the client uses a
    # domain socket that doesn't need configuration. Windows does not have
    # domain sockets, so uncomment these lines.
    host: #{dev_db_host}

    # The TCP port the server listens on. Defaults to 5432.
    # If your server runs on a different port number, change accordingly.
    port: #{dev_db_port}

    # Schema search path. The server defaults to $user,public
    #schema_search_path: myapp,sharedapp,public

    # Minimum log levels, in increasing order:
    #   debug5, debug4, debug3, debug2, debug1,
    #   log, notice, warning, error, fatal, and panic
    # Defaults to warning.
    #min_messages: notice

  # Warning: The database defined as "test" will be erased and
  # re-generated from your development database when you run "rake".
  # Do not set this db to the same as development or production.
  test:
    <<: *default
    database: <%= Rails.application.class.module_parent_name.underscore %>_test

  # As with config/secrets.yml, you never want to store sensitive information,
  # like your database password, in your source code. If your source code is
  # ever seen by anyone, they now have access to your database.
  #
  # Instead, provide the password as a unix environment variable when you boot
  # the app. Read http://guides.rubyonrails.org/configuring.html#configuring-a-database
  # for a full rundown on how to provide these environment variables in a
  # production deployment.
  #
  # On Heroku and other platform providers, you may have a full connection URL
  # available as an environment variable. For example:
  #
  #   DATABASE_URL="postgres://myuser:mypass@localhost/somedatabase"
  #
  # You can use this database configuration with:
  #
  #   production:
  #     url: <%= ENV['DATABASE_URL'] %>
  #
  production:
    <<: *default
    database: <%= Rails.application.class.module_parent_name.underscore %>_production
    username: <%= Rails.application.class.module_parent_name.underscore %>
    password: <%= ENV["\#{ Rails.application.class.module_parent_name.underscore.upcase }_DATABASE_PASSWORD"] %>
CODE

run 'mkdir -p app/assets/javascripts'
file 'app/assets/config/manifest.js', <<-CODE
//= link_tree ../images
//= link_directory ../javascripts .js
//= link_directory ../stylesheets .css
CODE

after_bundle do
  say "Installing Phlex"
  generate "phlex:install"
  say "Installing Rspec"
  generate "rspec:install"
  if include_spina_cms
    say "Installing Spina"
    generate "spina:install"
  end

  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end
