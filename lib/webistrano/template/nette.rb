module Webistrano
	module Template
		module Nette

			CONFIG = Webistrano::Template::BasePHP::CONFIG.dup.merge({
				:php_bin => '/usr/bin/php',
				:remote_tmp_dir => '/tmp',
				:app_path => "app",
				:web_path => "web",
				:app_config_file => "parameters.yml",
				:use_composer => true,
				:shared_children => "[\"temp\",\"log\"]",
				:shared_files => "[\"app/config/local.neon\"]"
			}).freeze

			DESC = <<-'EOS'
				Template to use for Nette project deploy
			EOS

			# load all netiffy nette2 tasks
			task = ""
			nettify = [ "netiffy", "nettify/nette", "nettify/database", "nettify/deploy", "nettify/doctrine", "nettify/propel", "nettify/web" ]
			netiffy.each {|import|
				task = task + File.open("lib/webistrano/template/netiffy/#{import}.rb", "rb").read
			}

			nettify_tasks = <<-'EOS'

				set :maintenance_basename, 'maintenance'

				# nette application path
				set :app_path,              "app"

				# nette web path
				set :web_path,              "web"

				# nette console bin
				set :nette_console,       web + "/index.php"

				# nette log path
				set :log_path,              app_path + "/logs"

				# nette cache path
				set :cache_path,            app_path + "/cache"

				# nette config file path
				set :app_config_path,       app_path + "/config"

				# nette config file (parameters.(ini|yml|etc...)
				set :app_config_file,       "parameters.yml"

				# nette bin vendors
				set :nette_vendors,       "bin/vendors"

				# nette build_bootstrap script
				set :build_bootstrap,       "bin/build_bootstrap"

				# Whether to use composer to install vendors.
				# If set to false, it will use the bin/vendors script
				set :use_composer,          true

				# Path to composer binary
				# If set to false, nettify will download/install composer
				set :composer_bin,          false

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

				# Files that need to remain the same between deploys
				set :shared_files,          false

				# Dirs that need to remain the same between deploys (shared dirs)
				set :shared_children,       [log_path]

				# Asset folders (that need to be timestamped)
				set :asset_children,        [web_path + "/css", web_path + "/images", web_path + "/js"]

				# Dirs that need to be writable by the HTTP Server (i.e. cache, log dirs)
				set :writable_dirs,         [log_path, cache_path]

				# Name used by the Web Server (i.e. www-data for Apache)
				set :webserver_user,        "www-data"

				# Method used to set permissions (:chmod, :acl, or :chown)
				set :permission_method,     :acl

				# Execute set permissions
				set :use_set_permissions,   true

				# Model manager: (doctrine, propel)
				set :model_manager,         "doctrine"

				# If set to false, it will never ask for confirmations (migrations task for instance)
				# Use it carefully, really!
				set :interactive_mode,      false

				def load_database_config(data, env)
					nettify_fail;
					#read_parameters(data)['parameters']
				end

				def read_parameters(data)
					if '.ini' === File.extname(app_config_file) then
						File.readable?(data) ? IniFile::load(data) : IniFile.new(data)
					else
						YAML::load(data)
					end
				end

				def guess_nette_version
					capture("cd #{latest_release} && #{php_bin} #{nette_console} --version |cut -d \" \" -f 3")
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

				def nettify_fail
					logger.info 'Fail'.red;

					$error = true;
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
							vendors_mode.chomp # To remove trailing whiteline
							case vendors_mode
							when "upgrade" then nette.vendors.upgrade
							when "install" then nette.vendors.install
							when "reinstall" then nette.vendors.reinstall
							end
						end
					end

					nette.bootstrap.build

					if use_set_permissions
						nette.deploy.set_permissions
					end

					if use_composer
						nette.composer.dump_autoload
					end

					if cache_warmup
						nette.cache.warmup            # Warmup clean cache
					end

					if clear_controllers
						# If clear_controllers is an array set controllers_to_clear,
						# else use the default value 'app_*.php'
						if clear_controllers.is_a? Array
							set(:controllers_to_clear) { clear_controllers }
						end
						nette.project.clear_controllers
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