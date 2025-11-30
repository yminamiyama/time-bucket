# No-op asset tasks for API-only deployment (Render build calls assets:precompile/clean)
namespace :assets do
  task :precompile do
    puts "Skipping assets:precompile (API-only app)"
  end

  task :clean do
    puts "Skipping assets:clean (API-only app)"
  end
end
