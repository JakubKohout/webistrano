namespace :composer do

  desc "Runs composer to install vendors from composer.lock file"
  task :install, :roles => :app, :except => { :no_release => true } do
    logger.info "--> Creating symlinks for shared files" "--> Installing Composer dependencies"
    run "#{try_sudo} bash --login  -c 'cd #{latest_release} && #{composer_bin} install #{composer_options}'"
    logger.info "OK"
  end

end