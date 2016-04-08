require 'middleman-core'

Middleman::Extensions.register :headless do
  require 'middleman-headless/extension'
  Headless
end
