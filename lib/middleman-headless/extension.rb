require 'middleman-core'

require 'middleman-headless/interface'

module MiddlemanHeadless
  class Extension < ::Middleman::Extension
    option :address, 'https://0.0.0.0:4000', 'The Headless address'
    option :app_key, nil, 'The applications key used for authentication'
    option :app_secret, nil, 'The applications secret used for authentication"'
    option :verify, true, 'Certificates are verified by default'
    option :space, nil, 'The space to be used'
    option :preview, false, 'Enable preview mode'
    option :cache, false, 'Enable caching. You need to restart the middleman to get updated content.'

    expose_to_config :headless
    expose_to_template :headless

    def initialize(app, options_hash={}, &block)
      super
      require 'oauth2'

      app.before do
        extensions[:headless].clear unless app.build?
      end
    end

    def headless
      @interface ||= Interface.new(options)
    end

    def clear
      @interface = nil unless options.cache
    end
  end
end
