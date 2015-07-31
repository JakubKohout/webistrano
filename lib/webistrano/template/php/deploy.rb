after "deploy:create_symlink" , "deploy:share_childs"

namespace :deploy do

  desc "Symlinks static directories and static files that need to remain between deployments"
  task :share_childs, :roles => :app, :except => { :no_release => true } do
    if shared_children
      logger.info "--> Creating symlinks for shared directories"

      shared_children.each do |link|
        run "#{try_sudo} mkdir -p #{shared_path}/#{link}"
        run "#{try_sudo} sh -c 'if [ -d #{release_path}/#{link} ] ; then rm -rf #{release_path}/#{link}; fi'"
        run "#{try_sudo} ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end

      logger.info "OK"
    end

    if shared_files
      logger.info "--> Creating symlinks for shared files"

      shared_files.each do |link|
        link_dir = File.dirname("#{shared_path}/#{link}")
        run "#{try_sudo} mkdir -p #{link_dir}"
        run "#{try_sudo} touch #{shared_path}/#{link}"
        run "#{try_sudo} ln -nfs #{shared_path}/#{link} #{release_path}/#{link}"
      end

      logger.info "OK"
    end
  end




end
