namespace :nette do
  namespace :doctrine do
    namespace :cache do
      desc "Clears all metadata cache for a entity manager"
      task :clear_metadata, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> Clearing Doctrine metadata cache"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:cache:clear-metadata '"
        capifony_puts_ok
      end

      desc "Clears all query cache for a entity manager"
      task :clear_query, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> Clearing Doctrine query cache"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:cache:clear-query '"
        capifony_puts_ok
      end

      desc "Clears result cache for a entity manager"
      task :clear_result, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> Clearing Doctrine result cache"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:cache:clear-result '"
        capifony_puts_ok
      end
    end

    namespace :database do
      [:create, :drop].each do |action|
        desc "#{action.to_s.capitalize}s the configured databases"
        task action, :roles => :app, :except => { :no_release => true } do
          case action.to_s
          when "create"
            capifony_pretty_print "--> Creating databases"
          when "drop"
            capifony_pretty_print "--> Dropping databases"
          end

          run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:database:#{action.to_s} '", :once => true
          capifony_puts_ok
        end
      end
    end

    namespace :schema do
      desc "Processes the schema and either create it directly on EntityManager Storage Connection or generate the SQL output"
      task :create, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> Creating schema"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:schema:create '", :once => true
        capifony_puts_ok
      end

      desc "Drops the complete database schema of EntityManager Storage Connection or generate the corresponding SQL output"
      task :drop, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> Droping schema"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:schema:drop '", :once => true
        capifony_puts_ok
      end

      desc "Updates database schema of EntityManager Storage Connection"
      task :update, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> Updating schema"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:schema:update --force '", :once => true
        capifony_puts_ok
      end
    end

    namespace :fixtures do
      desc "Load data fixtures"
      task :load, :roles => :app, :except => { :no_release => true } do
        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:fixtures:load '", :once => true
      end
    end

    namespace :migrations do
      desc "Executes a migration to a specified version or the latest available version"
      task :migrate, :roles => :app, :only => { :primary => true }, :except => { :no_release => true } do
        currentVersion = nil
        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} --no-ansi migrations:status '", :once => true do |ch, stream, out|
          if stream == :out and out =~ /Current Version:.+\(([\w]+)\)/
            currentVersion = Regexp.last_match(1)
          end
          if stream == :out and out =~ /Current Version:\s*0\s*$/
            currentVersion = 0
          end
        end

        if currentVersion == nil
          raise "Could not find current database migration version"
        end
        logger.info "    Current database version: #{currentVersion}"

        on_rollback {
          if !interactive_mode || Capistrano::CLI.ui.agree("Do you really want to migrate #{nette_env_prod}'s database back to version #{currentVersion}? (y/N)")
            run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} migrations:migrate #{currentVersion}  --no-interaction'", :once => true
          end
        }

        if !interactive_mode || Capistrano::CLI.ui.agree("Do you really want to migrate #{nette_env_prod}'s database? (y/N)")
          run "#{try_sudo} sh -c ' cd #{latest_release} && #{php_bin} #{nette_console} migrations:migrate  --no-interaction'", :once => true
        end
      end

      desc "Views the status of a set of migrations"
      task :status, :roles => :app, :except => { :no_release => true } do
        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} migrations:status '", :once => true
      end
    end

    namespace :mongodb do
      [:create, :update, :drop].each do |action|
        namespace :schema do
          desc "Allows you to #{action.to_s} databases, collections and indexes for your documents"
          task action, :roles => :app, :except => { :no_release => true } do
            capifony_pretty_print "--> Executing MongoDB schema #{action.to_s}"

            run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:mongodb:schema:#{action.to_s} '", :once => true
            capifony_puts_ok
          end
        end

        if action != :update
          namespace :indexes do
            desc "Allows you to #{action.to_s} indexes *only* for your documents"
            task action, :roles => :app do
              capifony_pretty_print "--> Executing MongoDB indexes #{action.to_s}"

              run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} orm:mongodb:schema:#{action.to_s} --index '", :once => true
              capifony_puts_ok
            end
          end
        end
      end
    end

    namespace :init do
      desc "Mounts ACL tables in the database"
      task :acl, :roles => :app, :except => { :no_release => true } do
        capifony_pretty_print "--> Mounting Doctrine ACL tables"

        run "#{try_sudo} sh -c 'cd #{latest_release} && #{php_bin} #{nette_console} init:acl '", :once => true
        capifony_puts_ok
      end
    end
  end
end
