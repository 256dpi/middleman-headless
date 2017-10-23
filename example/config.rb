activate :headless,
  address: 'http://0.0.0.0:4000',
  app_key: 'key',
  app_secret: 'secret',
  space: 'example',
  download_assets: true

configure :development do
  activate :livereload
end
