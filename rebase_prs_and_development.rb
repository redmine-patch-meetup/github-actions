#!/usr/bin/env ruby

require 'json'

require 'faraday'

CONNECTION = Faraday.new(url: 'https://api.github.com/repos/redmine-patch-meetup/redmine-dev-mirror') do |conn|
  conn.response :raise_error
  conn.adapter Faraday.default_adapter
end

TOKEN = File.read('.token')

def rebase_local_development_branch
  system 'git checkout develop'
  system 'git rebase master'
end

def get_repo_resource(resource)
  response = CONNECTION.get resource
  JSON.parse response.body
end

def post_repo_resource(resource, body)
  response = CONNECTION.post resource,
                             body.to_json,
                             "Content-Type" => "application/json",
                             "Authorization" => "token #{TOKEN}"
  JSON.parse response.body
end

REBASE_NEEDED_LABEL = 'manual rebase needed'

def has_rebase_needed_label?(pr)
  pr['labels'].any? { |label| label['name'] == REBASE_NEEDED_LABEL }
end

def add_rebase_needed_label(pr)
  post_repo_resource("issues/#{pr['number']}/labels", { 'labels': [REBASE_NEEDED_LABEL] })
end

def rebase_onto_new_development_branch(pr)
  branch = pr['head']['ref']
  base_sha = pr['base']['sha']
  system "git checkout #{branch}"
  system "git rebase #{base_sha} --onto develop && git push -f"
end

def push_new_development_branch
  system 'git checkout develop'
  system 'git push -f origin develop'
end

def main
  Dir.chdir('redmine-dev-mirror')

  rebase_local_development_branch

  get_repo_resource('pulls').each do |pr|
    if has_rebase_needed_label?(pr)
      puts "Skip rebase of \"#{pr['title']}\" - Rebase needed"
      next
    end

    rebase_successful = rebase_onto_new_development_branch pr
    next if rebase_successful

    puts "Rebase of \"#{pr['title']}\" failed - Adding label"
    add_rebase_needed_label(pr)
  end

  push_new_development_branch
end

main if __FILE__ == $0
