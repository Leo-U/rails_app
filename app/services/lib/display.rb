# frozen_string_literal: true

module Display
  def init_escape_sequences
    @dark_bg = "\e[48;5;253m"
    @light_bg = "\e[48;5;231m"
    @black_fg = "\e[30m"
    @red_fg = "\e[38;5;196m"
    @reset = "\e[0m"
  end

  def init_pieces
    @blank = '   '
    @red = { kin: '♚', que: '♛', roo: '♜', bis: '♝', kni: '♞', paw: '♟︎' }.transform_values { |value| @red_fg + value }
    @black = @red.transform_values { |value| @black_fg + value[11..] }
  end

  def init_display
    init_escape_sequences
    init_pieces
  end

  def build_empty_board
    @board = Array.new(8) do |row_i|
      Array.new(8) do |el_i|
        (row_i.even? == el_i.even? ? @light_bg : @dark_bg) + @blank + @reset
      end
    end
  end

  def fill_board
    build_empty_board
    @state.each_with_index do |row, y|
      row.each_with_index do |square, x|
        if square
          piece = square.piece_name.downcase.to_sym
          @board[y][x][-6] = square.color == 'white' ? @red[piece] : @black[piece]
        end
      end
    end
  end

  def board_as_black
    @board.reverse.map(&:reverse)
  end

  def print_board(side, board = @board, rank = 9, i = -1, letters = ('  a'..'  h'))
    if side == 'black'
      (board = board_as_black
       rank = 0
       i = 1
       letters = letters.to_a.reverse)
    end
    print ' ', *letters, "\n"
    board.each do |row|
      print rank += i, ' '
      row.each { |square| print square }
      print ' ', rank, "\n"
    end
    print ' ', *letters, "\n"
  end

  def full_print_sequence(side)
    init_display
    fill_board
    print_board(side)
  end
end
