require 'middleman-core'

require 'middleman-headless/interface'

module MiddlemanHeadless
  class Extension < ::Middleman::Extension
    option :address, 'http://0.0.0.0:3000', 'The Headless address'
    option :token, nil, 'The application token to be used'

    def initialize(app, options_hash={}, &block)
      super
      require 'faraday'
    end

    helpers do
      def headless(space)
        Interface.new(extensions[:headless].options, space)
      end
    end
  end
end
