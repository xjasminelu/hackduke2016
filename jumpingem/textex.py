
require 'gosu'

class TextField < Gosu::TextInput
  # Some constants that define our appearance.
  INACTIVE_COLOR  = 0xcc666666
  ACTIVE_COLOR    = 0xccff6666
  SELECTION_COLOR = 0xcc0000ff
  CARET_COLOR     = 0xffffffff
  PADDING = 5
  attr_reader :x, :y
  def initialize(window, font, x, y, width, height, color)
    # TextInput's constructor doesn't expect any arguments.
    super()
    @window, @font, @x, @y, @color, @width, @height = window, font, x, y, color, width, height
    # Start with a self-explanatory text in each field.
    self.text = "Robot code"
  end
  # Example filter method. You can truncate the text to employ a length limit (watch out
  # with Ruby 1.8 and UTF-8!), limit the text to certain characters etc.
  
  def draw
    @window.draw_quad(x - PADDING,         y - PADDING,        @color,
                      x + @width + PADDING, y - PADDING,          @color,
                      x - PADDING,         y + @height + PADDING, @olor,
                      x + @width + PADDING, y + @height + PADDING, @color, 0)
    # Calculate the position of the caret and the selection start.
    pos_x = x + @font.text_width(self.text[0...self.caret_pos])
    sel_x = x + @font.text_width(self.text[0...self.selection_start])
    # Draw the selection background, if any; if not, sel_x and pos_x will be
    # the same value, making this quad empty.
    @window.draw_quad(sel_x, y,          @color,
                      pos_x, y,          @color,
                      sel_x, y + height, @color,
                      pos_x, y + height, @color, 0)
    # Draw the caret; again, only if this is the currently selected field.
    if @window.text_input == self then
      @window.draw_line(pos_x, y,          Color::BLUE,
                        pos_x, y + height, Color::BLUE, 0)
    end
    # Finally, draw the text itself!
    @font.draw(self.text, x, y, 0)
  end
  # Hit-test for selecting a text field with the mouse.
  def under_point?(mouse_x, mouse_y)
    mouse_x > x - PADDING and mouse_x < x + width + PADDING and
      mouse_y > y - PADDING and mouse_y < y + height + PADDING
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
class TextInputWindow < Gosu::Window
  def initialize
    super(300, 200, false)
    self.caption = "Text Input Example"
    font = Gosu::Font.new(self, Gosu::default_font_name, 20)
    # Set up an array of three text fields.
    @text_field = TextField.new(self, font, 20, 20, 200, 200, Color::WHITE) 
    
   # @cursor = Gosu::Image.new(self, "media/Cursor.png", false)
  end
  def needs_cursor?
  true
  end
  def draw
    @text_fields.each { |tf| tf.draw }
    #@cursor.draw(mouse_x, mouse_y, 0)
  end
  def button_down(id)
    if id == Gosu::KbEscape then
      # Escape key will not be 'eaten' by text fields; use for deselecting.
      if self.text_input then
        self.text_input = nil
      else
        close
      end
    elsif id == Gosu::MsLeft then
      # Mouse click: Select text field based on mouse position.
      self.text_input = @text_fields.find { |tf| tf.under_point?(mouse_x, mouse_y) }
      # Advanced: Move caret to clicked position
      self.text_input.move_caret(mouse_x) unless self.text_input.nil?
    end
  end
end
TextInputWindow.new.show