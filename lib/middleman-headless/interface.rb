require 'active_support/core_ext/hash/indifferent_access'

module MiddlemanHeadless
  class Interface
    def initialize(options, space)
      @space = space

      @conn = Faraday.new(url: "#{options.address}/delivery/#{space}") do |config|
        config.headers['Authorization'] = "Bearer #{options.token}"
        config.response :logger if options.log
        config.adapter Faraday.default_adapter
      end
    end

    def space
      get('')
    end

    def entries(content_type)
      get(content_type.is_a?(Hash) ? content_type[:slug] : content_type)
    end

    protected

    def get(path)
      JSON.parse(@conn.get(path).body).map do |item|
        item.with_indifferent_access
      end
    end
  end
end
