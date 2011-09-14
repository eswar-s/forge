require 'sprockets'
require 'zip/zip'

module Forge
  class Builder
    def initialize(project)
      @project = project
      @templates_path = File.join(@project.root, 'templates')
      @assets_path = File.join(@project.root, 'assets')

      init_sprockets
    end

    # Runs all the methods necessary to build a completed project
    def build
      copy_templates
      build_assets
    end

    # Use the rubyzip library to build a zip from the generated source
    def zip
      basename = File.basename(@project.root)

      Zip::ZipFile.open("#{basename}.zip", Zip::ZipFile::CREATE) do |zip|
        build_dir = Dir.open(@project.build_dir)
        build_dir.each do |filename|
          zip.add File.join(basename, filename), File.join(@project.build_dir, filename)
        end
      end
    end

    def copy_templates
      template_paths.each do |template_path|
        FileUtils.cp_r template_path, '.forge'
      end
    end

    def build_assets
      [['style.css'], ['js', 'theme.js']].each do |asset|
        destination = File.join(@project.build_dir, asset)

        asset = @sprockets.find_asset(asset.last)

        asset.write_to(destination) unless asset.nil?
      end
    end

    private

    def init_sprockets
      @sprockets = Sprockets::Environment.new

      ['javascripts', 'stylesheets'].each do |dir|
        @sprockets.append_path File.join(@assets_path, dir)
      end
    end

    def template_paths
      @template_paths ||= [
        ['default', '.'],
        ['custom', 'pages', '.'],
        ['custom', 'partials', '.']
      ].collect { |path| File.join(@templates_path, path) }
    end
  end
end