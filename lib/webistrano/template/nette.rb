module Webistrano
	module Template
		module Nette

			CONFIG = Webistrano::Template::BasePHP::CONFIG.dup.merge({
				:remote_tmp_dir => 'temp',
				:app_path => "app",
				:web_path => "www",
				:app_config_file => "app/config/local.neon",
				:use_composer => true,
				:shared_children => "[\"temp\",\"log\"]",
				:shared_files => "[\"app/config/local.neon\"]",
        :nette_console => "www/index.php"
			}).freeze

			DESC = <<-'EOS'
				Template to use for Nette project deploy
			EOS

			# load all netiffy nette2 tasks
			task = ""
			nettify = ["deploy","nette","doctrine"]

      nettify.each{ |fileName|
        task = task + IO.read("lib/webistrano/template/nettify/" + fileName + ".rb");
      }

      nettify_tasks = <<-'EOS'

        set :nette_env_prod, 'production'

        set :local_cache_path, "/var/deploys/#{webistrano_project}/"
        set :local_cache, "#{local_cache_path}/#{webistrano_stage}"

        set :maintenance_basename, 'maintenance'

        # Nette application path
        set :app_path,              "app"

        # Nette web path
        set :web_path,              "web"

        # Nette log path
        set :log_path,              app_path + "/logs"

        # Nette cache path
        set :cache_path,            app_path + "/cache"

        # Nette config file path
        set :app_config_path,       app_path + "/config"

        # Nette config file (parameters.(ini|yml|etc...)
        set :app_config_file,       "parameters.yml"

        # Nette bin vendors
        set :nette_vendors,         "bin/vendors"

        # Nette build_bootstrap script
        set :build_bootstrap,       "bin/build_bootstrap"

        # Path to composer binary
        # If set to false, Nettify will download/install composer
        set :composer_bin,          'composer'

        # Options to pass to composer when installing/updating
        set :composer_options,      "--no-scripts --verbose --prefer-dist"

        # Whether to update vendors using the configured dependency manager (composer or bin/vendors)
        set :update_vendors,        false

        # run bin/vendors script in mode (upgrade, install (faster if shared /vendor folder) or reinstall)
        set :vendors_mode,          "reinstall"

        # Copy vendors from previous release
        set :copy_vendors,          true

        # Whether to run cache warmup
        set :cache_warmup,          true

        # Dirs that need to be writable by the HTTP Server (i.e. cache, log dirs)
        set :writable_dirs,         [log_path, cache_path]

        # Name used by the Web Server (i.e. www-data for Apache)
        set :webserver_user,        "www-data"

        # Model manager: (doctrine, propel)
        set :model_manager,         "doctrine"

        # If set to false, it will never ask for confirmations (migrations task for instance)
        # Use it carefully, really!
        set :interactive_mode,      false

        def load_database_config(data, env)
          #read_parameters(data)['parameters']
        end

        def read_parameters(data)
          #if '.ini' === File.extname(app_config_file) then
          #  File.readable?(data) ? IniFile::load(data) : IniFile.new(data)
          #else
          #  YAML::load(data)
          #end
        end

        def remote_file_exists?(full_path)
          'true' == capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
        end

        def remote_command_exists?(command)
          'true' == capture("if [ -x \"$(which #{command})\" ]; then echo 'true'; fi").strip
        end

        STDOUT.sync
        $error = false
        $pretty_errors_defined = false

        # Be less verbose by default
        #logger.level = Capistrano::Logger::IMPORTANT

        def nettify_pretty_print(msg)
            logger.info msg
        end

        def nettify_puts_ok
          logger.info 'ok'.green

          $error = false
        end

        ["nette:composer:install", "nette:composer:update"].each do |action|
          before action do
            if copy_vendors
              nette.composer.copy_vendors 
            end
          end
        end

        after "deploy:finalize_update" do
          if use_composer
            if update_vendors
              nette.composer.update
            else
              nette.composer.install
            end
          else
            if update_vendors
              #vendors_mode.chomp # To remove trailing whiteline
              #case vendors_mode
              #when "upgrade" then nette.vendors.upgrade
              #when "install" then nette.vendors.install
              #when "reinstall" then nette.vendors.reinstall
              #end
            end
          end

          #nette.bootstrap.build


          if use_composer
            #nette.composer.dump_autoload
          end

          if cache_warmup
            #nette.cache.warmup            # Warmup clean cache
          end

        end

        before "deploy:update_code" do
          msg = "--> Updating code base with #{deploy_via} strategy"
          logger.info msg
          #sudo "mkdir -p #{local_cache_path}"
          #sudo "chown -R #{user} #{local_cache_path}"
        end

        after "deploy:create_symlink" do
          logger.info "--> Successfully deployed!".green
        end

      EOS

      TASKS = Webistrano::Template::Base::TASKS + nettify_tasks + task

    end
  end
end