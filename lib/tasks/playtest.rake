namespace :playtest do
  desc "Print a Markdown report of all started games, replayed through the rules engine"
  task report: :environment do
    puts PlaytestReport.new.to_markdown
  end
end
