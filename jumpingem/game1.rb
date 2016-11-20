#!/usr/bin/env ruby -w
require 'rubygems'
require 'gosu'
include Gosu

class Floor
  attr_accessor :x, :y, :width, :height, :color

  def initialize(window, x, y, width, height, color)
    @x = x
    @y = y
    @width = width
    @height = height
    @color = color
    @window = window
  end

  def draw
    #draw_quad(x1, y1, c1, x2, y2, c2, x3, y3, c3, x4, y4, c4, z = 0, mode = :default)
    # points are in clockwise order
    @window.draw_quad @x, @y, @color, @x + @width, @y, @color, @x + @width, @y + @height, @color, @x, @y + @height, @color
  end
end

class TextBox < Gosu::Image
  attr_accessor :x, :y, :width, :height, :color, :font
  def initialize(window, x, y, width, height, color, font)
    @x = x
    @y = y
    @width = width
    @height = height
    @color = color
    @window = window
    @font = font
  end
 
  
  def draw
    @window.draw_quad @x, @y, @color, @x + @width, @y, @color, @x + @width, @y + @height, @color, @x, @y + @height, @color
    #@message = Gosu::Image.from_text(@window, "Click here", @font)
    #@message.draw(10, 10, 0)
  end
  
  def inside?(mouse_x, mouse_y)
    mouse_x > x and mouse_x < x+width and mouse_y > y and mouse_y<y+height
  end
  
  
    
end



class TextField < Gosu::TextInput
  # Some constants that define our appearance.
  INACTIVE_COLOR  = 0xcc666666
  ACTIVE_COLOR    = 0xccff6666
  SELECTION_COLOR = 0xcc0000ff
  CARET_COLOR     = 0xffffffff
  PADDING = 5
  attr_reader :x, :y
  def initialize(window, font, x, y)
    # TextInput's constructor doesn't expect any arguments.
    super()
    @window, @font, @x, @y = window, font, x, y
    # Start with a self-explanatory text in each field.
    self.text = "Click to change text"
  end
  # Example filter method. You can truncate the text to employ a length limit (watch out
  # with Ruby 1.8 and UTF-8!), limit the text to certain characters etc.
  def filter text
    text.upcase
  end
  def draw
    # Depending on whether this is the currently selected input or not, change the
    # background's color.
    if @window.text_input == self then
      background_color = ACTIVE_COLOR
    else
      background_color = INACTIVE_COLOR
    end
    @window.draw_quad(x - PADDING,         y - PADDING,          background_color,
                      x + width + PADDING, y - PADDING,          background_color,
                      x - PADDING,         y + height + PADDING, background_color,
                      x + width + PADDING, y + height + PADDING, background_color, 0)
    # Calculate the position of the caret and the selection start.
    pos_x = x + @font.text_width(self.text[0...self.caret_pos])
    sel_x = x + @font.text_width(self.text[0...self.selection_start])
    # Draw the selection background, if any; if not, sel_x and pos_x will be
    # the same value, making this quad empty.
    @window.draw_quad(sel_x, y,          SELECTION_COLOR,
                      pos_x, y,          SELECTION_COLOR,
                      sel_x, y + height, SELECTION_COLOR,
                      pos_x, y + height, SELECTION_COLOR, 0)
    # Draw the caret; again, only if this is the currently selected field.
    if @window.text_input == self then
      @window.draw_line(pos_x, y,          CARET_COLOR,
                        pos_x, y + height, CARET_COLOR, 0)
    end
    # Finally, draw the text itself!
    @font.draw(self.text, x, y, 0)
  end
  # This text field grows with the text that's being entered.
  # (Usually one would use clip_to and scroll around on the text field.)
  def width
    @font.text_width(self.text)
  end
  def height
    @font.height
  end
  # Hit-test for selecting a text field with the mouse.
  def under_point?(mouse_x, mouse_y)
    mouse_x > x - PADDING and mouse_x < x + width + PADDING and
      mouse_y > y - PADDING and mouse_y < y + height + PADDING
  end
  
  def get_text()
    self.text
  end
  
  # Tries to move the caret to the position specifies by mouse_x
  def move_caret(mouse_x)
    # Test character by character
    1.upto(self.text.length) do |i|
      if mouse_x < x + @font.text_width(text[0...i]) then
        self.caret_pos = self.selection_start = i - 1;
        return
      end
    end
    # Default case: user must have clicked the right edge
    self.caret_pos = self.selection_start = self.text.length
  end
end


class Game < Window

  def initialize
    super(640, 480, false)
    self.caption = "Jump 'n Run"
    @standing, @walk1, @walk2, @jump = *Image.load_tiles(self, "sprites.png", 100, 160, false)
    @x, @y = 200, 0
    @vy = 0
    @move_xbol = false
    @move_xbol1 = false
    @dir = :left
    @cur_image = @standing
    @cursor = Gosu::Image.new(self, "media/Cursor.png", false)

    @floor = Floor.new(self, 0, 400, 640, 100, Color::BLUE)
    
    font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    @text_field = TextField.new(self, font, 20, 20)
    @button = TextBox.new(self, 400, 20, 220, 100, Color::WHITE, font)
    # Set up an array of three text fields.
    #@text_field = TextField.new(self, font, 400, 20)
  end

  def update
    move_x = 0
    if(@move_xbol)
    move_x -= 20
    @move_xbol = false
    elsif(@move_xbol1)
     move_x += 20
    @move_xbol1 = false
    end
    # Select image depending on action
    if (move_x == 0)
      @cur_image = @standing
    else
      @cur_image = (milliseconds / 175 % 2 == 0) ? @walk1 : @walk2
    end

    if (@vy < 0)
      @cur_image = @jump
    end

    # Directional walking, horizontal movement
    if move_x > 0 then
      @dir = :right
      move_x.times { @x += 1 }
    end
    if move_x < 0 then
      @dir = :left
      (-move_x).times { @x -= 1 }
    end

    # Acceleration/gravity
    # By adding 1 each frame, and (ideally) adding vy to y, the player's
    # jumping curve will be the parabole we want it to be.
    @vy += 1

    # Vertical movement
    if @vy > 0 && @y < 300 then
      @vy.times { @y += 1 }
    end
    if @vy < 0 then
      (-@vy).times {@y -= 1}
    end

  end
  
   input = TextInput.new
  def input.filter(text_in)
  text_in.downcase!
    if(text_in == "move")
    @vy = -20;
    elsif(text_in == "jump")
    end
  end

  def draw
    @floor.draw
    @text_field.draw
    @cursor.draw(mouse_x, mouse_y, 0)
    @button.draw

    if @dir == :left then
      offs_x = -25
      factor = 1.0
    else
      offs_x = 25
      factor = -1.0
    end
    @cur_image.draw(@x + offs_x, @y - 49, 0, factor, 1.0)
  end

  def button_down(id)
    if id == KbUp then
      @vy = -20
    elsif id == KbLeft then
    @move_xbol = true
    elsif id == KbRight then
    @move_xbol1 = true
    end
    if id == KbEscape then close end
     
    if id == Gosu::MsLeft then
      # Mouse click: Select text field based on mouse position.
      if(@text_field.under_point?(mouse_x, mouse_y))
      self.text_input = @text_field
      #@mytext = @text.field.get_text()
      self.text_input.move_caret(mouse_x) unless self.text_input.nil?
      
      end
      if(@button.inside?(mouse_x, mouse_y))
      @mytext = "hello"
      end
    end
    
    
  end
end

Game.new.show