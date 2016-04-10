require 'active_support/core_ext/hash/indifferent_access'

module MiddlemanHeadless
  class Entry
    def initialize(data)
      @data = data
    end

    def id
      @data[:id]
    end

    def name
      @data[:name]
    end

    def version(key)
      Version.new(@data[:versions][key])
    end

    def field(key)
      version(I18n.locale).field(key)
    end

    def method_missing(key)
      field(key)
    end
  end

  class Version
    def initialize(data)
      @data = data
    end

    def id
      @data[:id]
    end

    def field(key)
      @data[:fields][key]
    end

    def updated_at
      @data[:updated_at]
    end

    def published_at
      @data[:published_at]
    end

    def method_missing(key)
      field(key)
    end
  end

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
      get(content_type.is_a?(Hash) ? content_type[:slug] : content_type).map do |item|
        Entry.new(item)
      end
    end

    def method_missing(key)
      entries(key.to_s)
    end

    protected

    def get(path)
      JSON.parse(@conn.get(path).body).map do |item|
        item.with_indifferent_access
      end
    end
  end
end
