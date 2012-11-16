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

    let (:command) { double Mixlib::ShellOut }
  
    it 'should execute commands that are arguments' do
      argument = "knife cookbook upload *"
      Mixlib::ShellOut.should_receive(:new).with(argument).and_return(command)
      [:cwd,:run_command,:error!,:stdout,:stderr].each do |method|
        command.should_receive(method)
      end
      ChefGithubHook.chef_repo_cmd(argument)
    end
  end
end
