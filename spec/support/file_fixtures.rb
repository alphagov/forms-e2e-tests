module FileFixtures
  def file_fixture_path
    File.expand_path("spec/fixtures/files")
  end

  # Copied from https://github.com/rails/rails/blob/90a1eaa1b30ba1f2d524e197460e549c03cf5698/activesupport/lib/active_support/testing/file_fixtures.rb#L26
  def file_fixture(fixture_name)
    path = Pathname.new(File.join(file_fixture_path, fixture_name))

    if path.exist?
      path
    else
      msg = "the directory '%s' does not contain a file name '%s'"
      raise ArgumentError, msg % [file_fixture_path, fixture_name]
    end
  end
end

RSpec.configure do |config|
  config.include FileFixtures
end
