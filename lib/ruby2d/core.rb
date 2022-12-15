# frozen_string_literal: true

# Ruby2D module and native extension loader
unless RUBY_ENGINE == 'mruby'
  require 'ruby2d/communicating_vessel_system'
  include Ruby2D::CommunicatingVesselSystem
  require 'ruby2d/planned'
  require 'ruby2d/cli/colorize'
  require 'ruby2d/exceptions'
  require 'ruby2d/draw/render/renderable'
  require 'ruby2d/draw/color'
  require 'ruby2d/compose/entity'
  require 'ruby2d/compose/cluster'
  require 'ruby2d/compose/arena'
  require 'ruby2d/draw/render/quad'
  require 'ruby2d/draw/render/line'
  require 'ruby2d/draw/render/circle'
  require 'ruby2d/draw/render/rectangle'
  require 'ruby2d/draw/render/square'
  require 'ruby2d/draw/render/triangle'
  require 'ruby2d/draw/pixel'
  require 'ruby2d/draw/pixmap'
  require 'ruby2d/draw/pixmap_atlas'
  require 'ruby2d/draw/render/image'
  require 'ruby2d/draw/render/sprite'
  require 'ruby2d/draw/tileset'
  require 'ruby2d/draw/font'
  require 'ruby2d/draw/render/text'
  require 'ruby2d/draw/render/canvas'
  require 'ruby2d/sound'
  require 'ruby2d/music'
  require 'ruby2d/draw/texture'
  require 'ruby2d/draw/vertices'
  require 'ruby2d/compose/widget'
  require 'ruby2d/compose/grid'
  require 'ruby2d/compose/fit_grid'
  require 'ruby2d/compose/button'
  require 'ruby2d/compose/note'
  require 'ruby2d/compose/note_support'
  require 'ruby2d/window'
  require 'ruby2d/dsl'
  require 'ruby2d/ruby2d' # load native extension
end
