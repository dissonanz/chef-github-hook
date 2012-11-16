require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'rack/test'
require 'yajl'

describe ChefGithubHook do
  describe ChefGithubHook::RestAPI do
    include Rack::Test::Methods
    @hook_sample = {
      "before" => "5aef35982fb2d34e9d9d4502f6ede1072793222d",
      "repository" => {
        "url" => "http://github.com/defunkt/github",
        "name" => "github",
        "description" => "You're lookin' at it.",
        "watchers" => 5,
        "forks" => 2,
        "private" => 1,
        "owner" => {
          "email" => "chris@ozmm.org",
          "name" => "defunkt"
        }
      },
      "commits" => [
        {
          "id" => "41a212ee83ca127e3c8cf465891ab7216a705f59",
          "url" => "http://github.com/defunkt/github/commit/41a212ee83ca127e3c8cf465891ab7216a705f59",
          "author" => {
            "email" => "chris@ozmm.org",
            "name" => "Chris Wanstrath"
          },
          "message" => "okay i give in",
          "timestamp" => "2008-02-15T14:57:17-08:00",
          "added" => ["filepath.rb"]
        },
        {
          "id" => "de8251ff97ee194a289832576287d6f8ad74e3d0",
          "url" => "http://github.com/defunkt/github/commit/de8251ff97ee194a289832576287d6f8ad74e3d0",
          "author" => {
            "email" => "chris@ozmm.org",
            "name" => "Chris Wanstrath"
          },
          "message" => "update pricing a tad",
          "timestamp" => "2008-02-15T14:36:34-08:00"
        }
      ],
        "after" => "de8251ff97ee194a289832576287d6f8ad74e3d0",
        "ref" => "refs/heads/master"
    }

    #Setting up Sinatra application for testing
    def app
      ChefGithubHook::RestAPI
    end

    it "responds to posts on /" do
      ChefGithubHook.stub(:sync_to)
      post '/'
      last_response.status.should_not == 404
    end
  end
  describe 'chef_repo_cmd' do

    before :each do
      @command = double Mixlib::ShellOut
      [:cwd=,:run_command,:error!,:stdout,:stderr].each do |method|
        @command.stub(method)
      end
    end
    it 'should execute commands that are arguments' do
      argument = "knife cookbook upload *"
      Mixlib::ShellOut.should_receive(:new).with(argument).and_return(@command)
      ChefGithubHook.chef_repo_cmd(argument)
    end
    it 'should call Mixlib::ShellOut.cwd=' do
      ENV["CHEF_REPO_DIR"] = '/tmp'
      Mixlib::ShellOut.should_receive(:new).with('ls').and_return(@command)
      @command.should_receive(:cwd=).with('/tmp')
      @command.should_not_receive(:cwd)
      ChefGithubHook.chef_repo_cmd('ls')
    end
  end

  describe 'parse_knife_diff_output' do
    context 'no input' do
      let (:parser) { ChefGithubHook.parse_knife_diff_output("") }
      it 'should return a hash' do
        parser.class.should == Hash
      end
      it 'should return a hash with specified keys' do
        %w(cookbook role environment data_bag).each do |item|
          parser.should have_key "#{item}_delete".to_sym
        end
      end
    end
    context 'has input' do
      input = '''
D cookbooks/book1/recipes/default.rb
D cookbooks/book2
D roles/role1.json
D roles/role2.rb
D roles/role3
D environments/env1.json
D data_bags/bag1
D data_bags/bag2/item1.json
      '''
      let (:parser) { ChefGithubHook.parse_knife_diff_output(input)}
      it 'should not list filenames within cookbooks' do
        parser[:cookbook_delete].should == ['book2']
      end
      it 'should list deleted data bags' do
        parser[:data_bag_delete].should include 'bag1'
      end
      it 'should not list entire data bags when only items are deleted' do
        parser[:data_bag_delete].should_not include 'bag2'
      end
      it 'should include deleted data bag items' do
        parser[:data_bag_delete].should include 'bag2 item1'
      end
      it 'should include deleted roles when they have an extension' do
        parser[:role_delete].should include 'role1','role2'
        parser[:role_delete].should_not include 'role3'
      end
      it 'should include deleted environments' do
        parser[:environment_delete].should include 'env1'
      end
    end
  end
end
