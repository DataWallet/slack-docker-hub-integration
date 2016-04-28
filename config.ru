require 'bundler/setup'

require 'sinatra/base'
require 'rest-client'
require 'json'

class SlackDockerApp < Sinatra::Base
  get "/*" do
    params[:splat].first
  end

  post "/*" do
    docker = JSON.parse(request.body.read)

    repo = "<#{docker['repository']['repo_url']}|#{docker['repository']['repo_name']}>"
    tag = docker['push_data']['tag'] ? docker['push_data']['tag'] : "latest"
    pusher = docker['push_data']['pusher']
    images = docker['push_data']['images']

    RestClient.post(docker['callback_url'], {
        state: "success"
    }.to_json, :content_type => :json) { |response, request, result, &block|
        slack = {
            attachments: [{
                pretext: "Image build complete",
                fallback: response.code == 200 ? "🚀" : "☹️",
                color: response.code == 200 ? "good" : "danger",
                author_name: pusher,
                text: "\n[#{repo}:#{tag}]",
                fields: images.map! {|image| {
                    value: "- #{image}"
                }}
            }],
            username: "docker-hub",
            thumb_url: "https://pbs.twimg.com/profile_images/378800000124779041/fbbb494a7eef5f9278c6967b6072ca3e_200x200.png"
        }

        RestClient.post("https://hooks.slack.com/#{params[:splat].first}", payload: slack.to_json)
    }
  end
end

run SlackDockerApp
