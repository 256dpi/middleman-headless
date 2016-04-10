require 'middleman-core'

require 'middleman-headless/interface'

module MiddlemanHeadless
  class Extension < ::Middleman::Extension
    option :address, 'http://0.0.0.0:3000', 'The Headless address'
    option :token, nil, 'The application token to be used'
    option :space, nil, 'The default space to be used'
    option :log, false, 'Enable logging to STDOUT'

    def initialize(app, options_hash={}, &block)
      super
      require 'faraday'

      @cache = {}

      # clear cache before any request
      app.before do
        extensions[:headless].clear
      end
    end

    def instance(space)
      space ||= options.space
      @cache[space.to_sym] ||= Interface.new(options, space)
    end

    def clear
      @cache = {}
    end

    helpers do
      def headless(space=nil)
        extensions[:headless].instance(space)
      end
    end
  end
end
