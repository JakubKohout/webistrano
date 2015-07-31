module Webistrano
  module Template
    module PHP

      CONFIG = Webistrano::Template::BasePHP::CONFIG.dup.merge({
        :shared_children => [],
        :shared_files => [],
        :deploy_to => '/path/to/deployment_base',
        :use_composer => true
      }).freeze

      DESC = <<-'EOS'
        Template for use with PHP projects
      EOS

      tasks = <<-'EOS'
        # Composer bin file
        set :composer_bin,          'composer'

        # Options to pass to composer when installing/updating
        set :composer_options,      "--no-scripts --verbose --prefer-dist"

        after "deploy:finalize_update" do
          if use_composer
              composer.install
          end
        end
      EOS
      recipe = [ "deploy", "composer" ]
      recipe.each {|import|
        tasks = tasks + File.open("lib/webistrano/template/php/#{import}.rb", "rb").read
      }

      TASKS = Webistrano::Template::Base::TASKS + tasks

    end
  end
end