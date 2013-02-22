module Webistrano
  module Template
    module Wordpress
      
      CONFIG = Webistrano::Template::Rails::CONFIG.dup.merge({
        :shared_children => "[\"wp-content/uploads\"]",
        :shared_files => "[\"wp-config.php\", \"sitemap.xml\", \"sitemap.xml.qz\"]",
      }).freeze
      
      DESC = <<-'EOS'
        Wordpress project
      EOS
      
      TASKS = Webistrano::Template::Base::TASKS + <<-'EOS'
        namespace :deploy  do
  


          desc <<-DESC
            Touches up the released code. This is called by update_code \
            after the basic deploy finishes. 
            
            Any directories deployed from the SCM are first removed and then replaced with \
            symlinks to the same directories within the shared location.
          DESC
          task :finalize_update, :except => { :no_release => true } do    
            run "chmod -R g+w #{latest_release}" if fetch(:group_writable, true)
            

            if shared_children
              print "--> Creating symlinks for shared directories"

              shared_children.each do |link|
                run "#{try_sudo} sh -c 'if [ -d #{latest_release}/#{link} ] ; then rm -rf #{latest_release}/#{link}; fi'"
                run "#{try_sudo} ln -nfs #{shared_path}/#{link} #{latest_release}/#{link}"
              end

              #capifony_puts_ok
            end

            if shared_files
              print "--> Creating symlinks for shared files"

              shared_files.each do |link|
                link_dir = File.dirname("#{shared_path}/#{link}")
                run "#{try_sudo} sh -c 'if [ #{latest_release}/#{link} ] ; then rm -f #{latest_release}/#{link}; fi'"
                run "#{try_sudo} ln -nfs #{shared_path}/#{link} #{latest_release}/#{link}"
              end

              #capifony_puts_ok
            end
          end  
        end


        namespace :wordpress do
          task :setup, :except => { :no_release => true } do
            if shared_children
              print "--> Creating symlinks for shared directories"

              shared_children.each do |link|
                run "#{try_sudo} mkdir -p #{shared_path}/#{link}"
              end

              #capifony_puts_ok
            end

            if shared_files
              print "--> Creating symlinks for shared files"

              shared_files.each do |link|
                link_dir = File.dirname("#{shared_path}/#{link}")
                run "#{try_sudo} mkdir -p #{shared_path}/#{link_dir}"
                run "#{try_sudo} touch #{shared_path}/#{link}"
              end

              #capifony_puts_ok
            end  
          end

        end


      EOS
      
    end
  end
end