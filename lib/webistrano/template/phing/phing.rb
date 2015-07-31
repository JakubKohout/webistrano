before "deploy:update" , "phing:build"

namespace :phing do

  desc "Build application via phing"
  task :build, :roles => :app do
    run "#{try_sudo} #{phing_bin} #{phing_build_task} -f #{phing_build_config}"
    logger.info "OK"
  end

end
