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

    def initialize(app, options_hash={}, &block)
      super
      require 'oauth2'

      app.before do
        extensions[:headless].clear
      end
    end

    def instance
      slug = options.space.to_sym
      @cache[slug] ||= Interface.new(options, slug, self)
    end

    def clear
      @cache = {}
    end

    helpers do
      def headless
        extensions[:headless].instance
      end
    end
  end
end
