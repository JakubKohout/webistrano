module Webistrano
  module Template
    module Wordpress
      
      CONFIG = Webistrano::Template::Rails::CONFIG.dup.merge({
        :app_symlinks => ["wp-content/uploads"]
        :app_file_symlinks => ["wp-config.php", "sitemap.xml", "sitemap.xml.qz"]
        :document_root => "www"
      }).freeze
      
      DESC = <<-'EOS'
        Wordpress project
      EOS
      
      TASKS = Webistrano::Template::Base::TASKS + <<-'EOS'
        namespace :wordpress do
  
          task :setup, :except => { :no_release => true } do
            if app_symlinks
              app_symlinks.each { |link| run "#{try_sudo} mkdir -p #{shared_path}/#{link}" }
            end
            if app_file_symlinks
              app_file_symlinks.each { |link| run "#{try_sudo} touch #{shared_path}/#{link} && chmod 777 #{shared_path}/#{link}" }
            end
          end

          desc <<-DESC
            Touches up the released code. This is called by update_code \
            after the basic deploy finishes. 
            
            Any directories deployed from the SCM are first removed and then replaced with \
            symlinks to the same directories within the shared location.
          DESC
          task :finalize_update, :except => { :no_release => true } do    
            run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
            
            if app_symlinks
              # Remove the contents of the shared directories if they were deployed from SCM
              app_symlinks.each { |link| run "#{try_sudo} rm -rf #{latest_release}/#{document_root}/#{link}" }
              # Add symlinks the directoris in the shared location
              app_symlinks.each { |link| run "#{try_sudo} ln -nfs #{shared_path}/#{link} #{latest_release}/#{document_root}/#{link}" }
            end
            
            if app_file_symlinks
              # Remove the contents of the shared directories if they were deployed from SCM
              app_file_symlinks.each { |link| run "#{try_sudo} rm -rf #{latest_release}/#{document_root}/#{link}" }
              # Add symlinks the directoris in the shared location
              app_file_symlinks.each { |link| run "#{try_sudo} ln -s #{shared_path}/#{link} #{latest_release}/#{document_root}/#{link}" }
            end
          end  
        end
      EOS
      
    end
  end
end