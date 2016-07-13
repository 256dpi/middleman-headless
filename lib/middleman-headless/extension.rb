require 'middleman-core'

require 'middleman-headless/interface'

module MiddlemanHeadless
  class Extension < ::Middleman::Extension
    option :address, 'http://0.0.0.0:4000', 'The Headless address'
    option :token, nil, "The access key's token that should be used"
    option :space, nil, 'The default space to be used'
    option :preview, false, 'Enable preview mode'
    option :log, false, 'Enable logging to STDOUT'

    def initialize(app, options_hash={}, &block)
      super
      require 'faraday'

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
