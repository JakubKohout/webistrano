module Webistrano
  module Template
    module Base
      CONFIG = {
        :application => "Project name",
        :deploy_to => "/home/www/Project/domain/",
        :deploy_via => ":checkout",
        :repository => "git@dev.eastbiz.com:project.git",
        :scm => ":git",
        :ssh_keys => "/home/webistrano/.ssh/id_rsa",
        :user => "Project",
        :use_sudo => "false"
      }.freeze
      
      DESC = <<-'EOS'
        Base template that the other templates use to inherit from.
        Defines basic Capistrano configuration parameters.
        Overrides no default Capistrano tasks.
      EOS
      
      TASKS =  <<-'EOS'
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