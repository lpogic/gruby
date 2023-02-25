module Kernel
    alias original_require require
    alias original_load load
  
    def require(name)
      if name == 'ruby2d/ruby2d'
        original_require name
      elsif name.start_with?('ruby2d')
        original_require "./lib/#{name}"
      else
        original_require name
      end
    end
  
    def load(name)
      if name.start_with?('ruby2d')
        original_load "./lib/#{name}"
      else
        original_load name
      end
    end
  end
  
  module Ruby2D
    def self.gem_dir
      '.'
    end
  
    def self.assets(path = nil)
      if path
         "#{gem_dir}/assets/#{path}"
      else 
        "#{gem_dir}/assets"
      end
    end
  
    def self.test_media
      "#{gem_dir}/assets/test_media"
    end
  end
  
  require 'ruby2d/core'
  include Ruby2D
  extend DSL
  
  set background: 'gray', resizable: true, title: ARGV[0] || 'Ruby2D'#, diagnostics: true
  on :key_down do |e|
    close confirm_required: true if e.key == 'escape'
  end
  window.enable_tab_callback
  # Pot.debug = true