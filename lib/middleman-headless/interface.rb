require 'active_support/core_ext/hash/indifferent_access'

module MiddlemanHeadless
  class Interface
    attr_reader :options

    def initialize(options, space_slug)
      @options = options
      @space_slug = space_slug
      @cache = {}

      @conn = Faraday.new(url: "#{@options.address}/delivery/#{@space_slug}") do |config|
        config.headers['Authorization'] = "Bearer #{@options.token}"
        config.response :logger if @options.log
        config.adapter Faraday.default_adapter
      end
    end

    def space
      @space ||= Space.new(get('').with_indifferent_access, self)
    end

    def entries(content_type)
      content_type = content_type[:slug] if content_type.is_a?(Hash)
      @cache[content_type.to_sym] ||= get(content_type).map do |item|
        Entry.new(item.with_indifferent_access, self)
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
      JSON.parse(@conn.get(path.to_s).body)
    end
  end

  class Item
    def initialize(data, interface)
      @data = data
      @interface = interface
    end

    def method_missing(key)
      @data[key]
    end
  end

  class Space < Item
    def content_types
      @data[:content_types].map do |item|
        Item.new(item, @interface)
      end
    end

    def languages
      @data[:languages].map do |item|
        Item.new(item, @interface)
      end
    end
  end

  class Entry
    def initialize(data, interface)
      @data = data
      @interface = interface
    end

    def id
      @data[:id]
    end

    def name
      @data[:name]
    end

    def version(key)
      Version.new(@data[:versions][key], @interface)
    end

    def field(key)
      version(I18n.locale).field(key)
    end

    def asset(key)
      Asset.new(field(key), @interface)
    end

    def reference(key, type=nil)
      type = key if type.nil?
      Reference.new(type, field(key), @interface)
    end

    def method_missing(key)
      field(key)
    end
  end

  class Version
    def initialize(data, interface)
      @data = data
      @interface = interface
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

  class Asset
    def initialize(id, interface)
      @id = id
      @interface = interface
    end

    def url
      address = @interface.options.address
      token = @interface.options.token
      "#{address}/file/view/#{@id}?token=#{token}"
    end
  end

  class Reference
    def initialize(type, id, interface)
      @type = type
      @id = id
      @interface = interface
    end

    def entry
      @interface.entry(@type, @id)
    end

    def method_missing(key)
      entry.send(key)
    end
  end
end
