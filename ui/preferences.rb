require 'Qt4'
require 'singleton'
require 'fileutils'

module AirVideo
  class Settings < Hash

    include Singleton

    def initialize
      super
      @config_dir = ENV["HOME"] + "/.config/airvideo-server"
      @config_file = ENV["HOME"] + "/.config/airvideo-server/server.properties"
      self['path.ffmpeg'] = '/opt/airvideo-server/bin/ffmpeg'
      self['path.mp4creator'] = '/usr/bin/mp4creator'
      self['path.faac'] = '/usr/bin/faac'
      self['password'] = ''
      self['subtitles.encoding'] = 'windows-1250'
      self['subtitles.font'] = 'Verdana'
      self['folders'] = "Videos:#{ENV['HOME']}/Videos"
      self.load
    end

    def save
      FileUtils.mkdir_p @config_dir unless File.directory?(@config_dir)
      puts 'saving settings'
      File.open @config_file, 'w' do |f|
        each do |k,v|
          f.puts "#{k.strip.chomp} = #{v.strip.chomp}"
        end
      end
    end
    
    def load
      return unless File.exist?(@config_file)
      puts 'loading setings file'
      File.read(@config_file).each_line do |l|
        k,v = l.split("=")
        self[k.strip.chomp] = v.strip.chomp
      end
    end

    def add_folder name,path
      self['folders'] += ",#{name}:#{path}"
    end

    def folder_list
      l = []
      self['folders'].split(",").each do |i|
        l << i.split(":").last
      end
      l
    end

    def each_folder(&block)
      self['folders'].split(",").each do |i|
        yield i.split(":")
      end
    end

  end

  class PreferencesDialog < Qt::Dialog

    def initialize(parent=nil)
      puts 'new prefs'
      super(parent)
      require 'preferences_dialog_ui'
      @ui = Ui::PreferencesDialog.new
      @ui.setup_ui(self)
      @ui.addDirButton.icon = Qt::Icon.fromTheme('add')
      @ui.addDirButton.connect SIGNAL :clicked do
        add_clicked
      end
      @ui.deleteDirButton.icon = Qt::Icon.fromTheme('remove')
      @ui.deleteDirButton.connect SIGNAL :clicked do
        remove_clicked
      end
      #@ui.buttonBox.connect SIGNAL :accepted do
      #  save
      #end
      Settings.instance.each_folder do |n,d|
        add_folder n,d
      end
    end

    def reject
      puts 'reject'
      hide
    end

    def accept
      puts 'accept'
      Settings.instance.save
      hide
    end

    def closeEvent(evt)
      evt.ignore
      hide
    end

    def add_clicked
      dir = Qt::FileDialog.getExistingDirectory self, "Select directory", ENV["HOME"], Qt::FileDialog::ShowDirsOnly
      if not Settings.instance.folder_list.include?(dir) and dir
        dirname = dir.split("/").last
        add_folder dirname, dir
        Settings.instance.add_folder dirname, dir
      end
    end

    def add_folder name, dir
      label = Qt::Label.new("<b>#{name}</b><p style='color: grey;font-size: 12px;'>#{dir}</p>")
      item = Qt::ListWidgetItem.new() 
      item.setSizeHint(Qt::Size.new(0,55))
      item.icon = Qt::Icon.fromTheme 'video-x-generic'
      @ui.listWidget.addItem(item)
      @ui.listWidget.setItemWidget(item, label)
    end

    def remove_clicked
      @ui.listWidget.takeItem @ui.listWidget.currentRow
    end
  end
end
