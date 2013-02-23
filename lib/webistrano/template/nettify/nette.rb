namespace :nette do
  desc "Runs custom nette command"
  task :default, :roles => :app, :except => { :no_release => true } do
    prompt_with_default(:task_arguments, "cache:clear")

    stream "cd #{latest_release} && #{php_bin} #{nette_console} #{task_arguments} --env=#{nette_env_prod}"
  end

  namespace :logs do
    [:tail, :tail_dev].each do |action|
      lines = ENV['lines'].nil? ? '50' : ENV['lines']
      log   = action.to_s == 'tail' ? 'prod.log' : 'dev.log'
      desc "Tail #{log}"
      task action, :roles => :app, :except => { :no_release => true } do
        run "#{try_sudo} tail -n #{lines} -f #{shared_path}/#{log_path}/#{log}" do |channel, stream, data|
          trap("INT") { puts 'Interupted'; exit 0; }
          puts
          puts "#{channel[:host]}: #{data}"
          break if stream == :err
        end
      end
    end
  end

  namespace :bootstrap do
    desc "Runs the bin/build_bootstrap script"
    task :build, :roles => :app, :except => { :no_release => true } do
      nettify_pretty_print "--> Building bootstrap file"

      if !remote_file_exists?("#{latest_release}/#{build_bootstrap}") && true == use_composer then
        set :build_bootstrap, "vendor/sensio/distribution-bundle/Sensio/Bundle/DistributionBundle/Resources/bin/build_bootstrap.php"
        run "#{try_sudo} sh -c 'cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} #{app_path} || echo '#{build_bootstrap} not found, skipped''"
      else
        run "#{try_sudo} sh -c 'cd #{latest_release} && test -f #{build_bootstrap} && #{php_bin} #{build_bootstrap} || echo '#{build_bootstrap} not found, skipped''"
      end

      nettify_puts_ok
    end
  end

  namespace :composer do
    desc "Gets composer and installs it"
    task :get, :roles => :app, :except => { :no_release => true } do
      if remote_file_exists?("#{previous_release}/composer.phar")
        nettify_pretty_print "--> Copying Composer from previous release"
        run "#{try_sudo} sh -c 'cp #{previous_release}/composer.phar #{latest_release}/'"
        nettify_puts_ok
      end

      if !remote_file_exists?("#{latest_release}/composer.phar")
        nettify_pretty_print "--> Downloading Composer"

        run "#{try_sudo} sh -c 'cd #{latest_release} && curl -s http://getcomposer.org/installer | #{php_bin}'"
      else
        nettify_pretty_print "--> Updating Composer"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} composer.phar self-update'"
      end
      nettify_puts_ok
    end

    desc "Updates composer"
    task :self_update, :roles => :app, :except => { :no_release => true } do
      nettify_pretty_print "--> Updating Composer"
      run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} self-update'"
      nettify_puts_ok
    end

    desc "Runs composer to install vendors from composer.lock file"
    task :install, :roles => :app, :except => { :no_release => true } do
      if composer_bin
        nette.composer.self_update
      else
        nette.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      nettify_pretty_print "--> Installing Composer dependencies"
      run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} install #{composer_options}'"
      nettify_puts_ok
    end

    desc "Runs composer to update vendors, and composer.lock file"
    task :update, :roles => :app, :except => { :no_release => true } do
      if composer_bin
        nette.composer.self_update
      else
        nette.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      nettify_pretty_print "--> Updating Composer dependencies"
      run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} update #{composer_options}'"
      nettify_puts_ok
    end

    desc "Dumps an optimized autoloader"
    task :dump_autoload, :roles => :app, :except => { :no_release => true } do
      if composer_bin
        nette.composer.self_update
      else
        nette.composer.get
        set :composer_bin, "#{php_bin} composer.phar"
      end

      nettify_pretty_print "--> Dumping an optimized autoloader"
      run "#{try_sudo} sh -c 'cd #{latest_release} && #{composer_bin} dump-autoload --optimize'"
      nettify_puts_ok
    end

    task :copy_vendors, :except => { :no_release => true } do
      nettify_pretty_print "--> Copying vendors from previous release"

      run "vendorDir=#{current_path}/vendor; if [ -d $vendorDir ] || [ -h $vendorDir ]; then cp -a $vendorDir #{latest_release}/vendor; fi;"
      nettify_puts_ok
    end
  end

  namespace :cache do
    [:clear, :warmup].each do |action|
      desc "Cache #{action.to_s}"
      task action, :roles => :app, :except => { :no_release => true } do
        case action
        when :clear
          nettify_pretty_print "--> Clearing cache"
        when :warmup
          nettify_pretty_print "--> Warming up cache"
        end

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} cache:#{action.to_s} --env=#{nette_env_prod}'"
        run "#{try_sudo} chmod -R g+w #{latest_release}/#{cache_path}"
        nettify_puts_ok
      end
    end
  end

  namespace :project do
    desc "Clears all non production environment controllers"
    task :clear_controllers do
      nettify_pretty_print "--> Clear controllers"

      command = "#{try_sudo} sh -c 'cd #{latest_release} && rm -f"
      controllers_to_clear.each do |link|
        command += " #{web_path}/" + link
      end
      run command + "'"

      nettify_puts_ok
    end
  end
end
