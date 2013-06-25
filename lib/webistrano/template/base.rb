module Webistrano
  module Template
    module Base
      CONFIG = {
        :application => "%PROJECT NAME%",
        :deploy_to => "/home/www/%PROJECT NAME%/%DOMAIN NAME%/",
        :deploy_via => ":checkout",
        :repository => "git@dev.eastbiz.com:%PROJECT NAME%.git",
        :scm => ":git",
        :ssh_keys => "/home/webistrano/.ssh/id_rsa",
        :user => "%PROJECT NAME%",
        :use_sudo => "false",
        :branch => "master",
        :newrelic_appname => "%DOMAIN NAME%",
        :web_path => "www"
      }.freeze
      
      DESC = <<-'EOS'
        Base template that the other templates use to inherit from.
        Defines basic Capistrano configuration parameters.
        Overrides no default Capistrano tasks.
      EOS
      
      TASKS =  <<-'EOS'

        require 'new_relic/recipes'
        after "deploy:update", "newrelic:notice_deployment"

        before "newrelic:notice_deployment" do
          run <<-EOB
                echo -e " <IfModule mod_php5.c> \\n
                            php_value newrelic.appname "#{newrelic_appname}" \\n
                          </IfModule> " >> #{latest_release}/#{web_path}/.htaccess
              EOB
        end

        # allocate a pty by default as some systems have problems without
        default_run_options[:pty] = true
      
        # set Net::SSH ssh options through normal variables
        # at the moment only one SSH key is supported as arrays are not
        # parsed correctly by Webistrano::Deployer.type_cast (they end up as strings)
        [:ssh_port, :ssh_keys].each do |ssh_opt|
          if exists? ssh_opt
            logger.important("SSH options: setting #{ssh_opt} to: #{fetch(ssh_opt)}")
            ssh_options[ssh_opt.to_s.gsub(/ssh_/, '').to_sym] = fetch(ssh_opt)
          end
        end
      EOS
    end
  end
end