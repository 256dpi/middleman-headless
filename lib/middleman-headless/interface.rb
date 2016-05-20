require 'active_support/core_ext/hash/indifferent_access'

module MiddlemanHeadless
  class Interface
    def initialize(options, space)
      @cache = {}
      @conn = Faraday.new(url: "#{options.address}/delivery/#{space}") do |config|
        config.headers['Authorization'] = "Bearer #{options.token}"
        config.response :logger if options.log
        config.adapter Faraday.default_adapter
      end
    end

    def space
      @space ||= Space.new(get('').with_indifferent_access)
    end

    def entries(content_type)
      content_type = content_type[:slug] if content_type.is_a?(Hash)
      @cache[content_type.to_sym] ||= get(content_type).map do |item|
        Entry.new(item.with_indifferent_access)
      end
    end

    def entry(content_type, id)
      entries(content_type).find do |item|
        item.id == id
      end
    end

    def method_missing(key)
      entries(key.to_s)
    end

    protected

    def get(path)
      JSON.parse(@conn.get(path).body)
    end
  end

  class Item
    def initialize(data)
      @data = data
    end

    def method_missing(key)
      @data[key]
    end
  end

  class Space < Item
    def content_types
      @data[:content_types].map{|item| Item.new(item) }
    end

    def languages
      @data[:languages].map{|item| Item.new(item) }
    end
  end

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
end
