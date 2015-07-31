module Webistrano
  module Template
    module Phing

      CONFIG = Webistrano::Template::PHP::CONFIG.dup.merge({
        :phing_bin => "bin/phing",
        :phing_build_config => "build.xml",
        :phing_build_task => 'build',
        :use_composer => true
      }).freeze

      DESC = <<-'EOS'
        Template for use with PHP projects
      EOS

      tasks = <<-'EOS'

      EOS
      recipe = [ "phing" ]
      recipe.each {|import|
        tasks = tasks + File.open("lib/webistrano/template/php/#{import}.rb", "rb").read
      }

      TASKS = Webistrano::Template::PHP::TASKS + tasks

    end
  end
end