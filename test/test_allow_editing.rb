# ~*~ encoding: utf-8 ~*~
require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

context "Precious::Views::Editing" do
  include Rack::Test::Methods

  setup do
    @path = cloned_testpath('examples/revert.git')
    Precious::App.set(:gollum_path, @path)
    @wiki = Gollum::Wiki.new(@path)
  end

  teardown do
    FileUtils.rm_rf(@path)
  end

  test 'creating pages is blocked' do
    Precious::App.set(:wiki_options, {allow_editing: false})

    post '/gollum/create',
      content: 'abc',
      format: 'markdown',
      message: 'def',
      page: 'D'

    assert last_response.body.include? 'Forbidden. This wiki is set to no-edit mode.'

    refute last_response.ok?

    assert_nil @wiki.page('D')
  end

  test ".redirects.gollum file should not be accessible" do
    Precious::App.set(:wiki_options, { allow_editing: true, allow_uploads: true })
    get '/.redirects.gollum'
    assert_match /Accessing this resource is not allowed/, last_response.body
  end

  test ".redirects.gollum file should not be editable" do
    Precious::App.set(:wiki_options, { allow_editing: true, allow_uploads: true })
    get '/gollum/edit/.redirects.gollum'
    assert_match /Changing this resource is not allowed/, last_response.body
  end

  test "frontend links for editing are not blocked" do
    Precious::App.set(:wiki_options, { allow_editing: true, allow_uploads: true })
    get '/A'

    assert_match /Delete this Page/, last_response.body, "'Delete this Page' link is blocked in page template"
    assert_match /New/,              last_response.body, "'New' button is blocked in page template"
    assert_match /Upload\b/,         last_response.body, "'Upload' link is blocked in page template"
    assert_match /Rename/,           last_response.body, "'Rename' link is blocked in page template"
    assert_match /Edit/,             last_response.body, "'Edit' link is blocked in page template"

    get '/gollum/overview'

    assert_match /New/, last_response.body, "'New' link is blocked in pages template"

    get '/gollum/history/A'

    refute_match /Edit/, last_response.body, "'Edit' link is not blocked in history template"

    get '/gollum/compare/A/fc66539528eb96f21b2bbdbf557788fe8a1196ac..b26b791cb7917c4f37dd9cb4d1e0efb24ac4d26f'

    refute_match /Edit Page/,             last_response.body, "'Edit Page' link is not blocked in compare template"
    assert_match /Revert Changes/,        last_response.body, "'Revert Changes' link is blocked in compare template"
  end

  test "frontend links for editing blocked" do
    Precious::App.set(:wiki_options, { allow_editing: false })
    get '/A'

    refute_match /Delete this Page/, last_response.body, "'Delete this Page' link not blocked in page template"
    refute_match /New/,              last_response.body, "'New' button not blocked in page template"
    refute_match /Upload\b/,         last_response.body, "'Upload' link not blocked in page template"
    refute_match /Rename/,           last_response.body, "'Rename' link not blocked in page template"
    refute_match /Edit/,             last_response.body, "'Edit' link not blocked in page template"

    get '/gollum/overview'

    refute_match /New/, last_response.body, "'New' link not blocked in pages template"

    get '/gollum/history/A'

    refute_match /Edit/, last_response.body, "'Edit' link not blocked in history template"

    get '/gollum/compare/A/fc66539528eb96f21b2bbdbf557788fe8a1196ac..b26b791cb7917c4f37dd9cb4d1e0efb24ac4d26f'

    refute_match /Edit Page/,             last_response.body, "'Edit Page' link not blocked in compare template"
    refute_match /Revert Changes/,        last_response.body, "'Revert Changes' link not blocked in compare template"
  end

  def app
    Precious::App
  end
end
