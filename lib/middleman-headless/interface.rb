require 'mime/types'
require 'active_support/core_ext/hash/indifferent_access'

module MiddlemanHeadless
  class Interface
    attr_reader :options, :build

    def initialize(options, build)
      @options = options
      @build = build

      @entries_cache = {}
      @asset_cache = {}

      @client = OAuth2::Client.new(
        @options.app_key,
        @options.app_secret,
        site: @options.address,
        token_url: '/auth/token',
        auth_scheme: :basic_auth,
        ssl: {
          verify: @options.verify
        }
      )

      @access_token = @client.client_credentials.get_token scope: ''
    end

    def space
      @space ||= Space.new(get("space/#{@options.space}").with_indifferent_access, self)
    end

    def entries(content_type)
      content_type = content_type[:slug] if content_type.is_a?(Hash)
      path = "entries/#{@options.space}/#{content_type}"
      @entries_cache[content_type.to_sym] ||= get(path).map do |item|
        Entry.new(item.with_indifferent_access, self)
      end
    end

    def entry(content_type, id)
      entries(content_type).find do |item|
        item.id == id
      end
    end

    def asset(id)
      return nil if id.blank?
      path = "asset/#{@options.space}/#{id}"
      @asset_cache[id.to_sym] ||= Asset.new(get(path).with_indifferent_access, self)
    end

    def token
      @access_token.token
    end

    def method_missing(key)
      entries(key.to_s)
    end

    protected

    def get(path)
      path = "/content/#{path.to_s}"
      path = "#{path}?preview=enabled" if @options.preview
      JSON.parse(@access_token.get(path).body)
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
      return nil if @data[:versions][key].nil?
      Version.new(@data[:versions][key], @interface)
    end

    def field(key)
      v = version(I18n.locale)
      return nil if v.nil?
      v.field(key)
    end

    def asset(key)
      @interface.asset(field(key))
    end

    def assets(key)
      assets = field(key)
      return [] if assets.nil?

      assets.map do |value|
        @interface.asset(value)
      end
    end

    def reference(key, type=nil)
      type = key if type.nil?
      ref = field(key)
      return nil if ref.nil?

      Reference.new(type, ref, @interface)
    end

    def references(key, type=nil)
      type = key if type.nil?
      refs = field(key)
      return [] if refs.nil?

      refs.map do |value|
        Reference.new(type, value, @interface)
      end
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
    def initialize(data, interface)
      @data = data
      @interface = interface
    end

    def key
      @data[:key]
    end

    def name
      @data[:name]
    end

    def content_type
      @data[:content_type]
    end

    def extension
      MIME::Types[content_type].first.preferred_extension
    end

    def url(options={})
      opts = options.length > 0 ? "?#{options.to_query}" : ''
      addr = "#{@interface.options.address}/content/file/#{key}#{opts}"

      if @interface.options[:download_assets] && @interface.build
        data = { addr: addr, ext: extension, name: name.parameterize }
        "hldl://#{Base64.urlsafe_encode64(JSON.generate(data))}/"
      else
        addr
      end
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

    def method_missing(*args)
      e = entry
      return nil if e.nil?
      entry.send(*args)
    end
  end
end
