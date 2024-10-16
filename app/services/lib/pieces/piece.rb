# frozen_string_literal: true

class Piece
  attr_reader :origin, :piece_name, :color
  attr_accessor :unmoved, :destination

  def initialize(piece_name, color)
    @piece_name = piece_name
    @color = color
    @destination = []
    @origin = []
    @moved_two = false
    @unmoved = true
  end

  def set_origin(state)
    state.each do |row|
      @origin = state.index(row), row.index(self) if row.include? self
    end
  end

  def set_destination(y, x)
    @destination = [y, x]
  end

  def find_distances
    @distance_y = (@origin[0] - @destination[0]).abs
    @distance_x = (@origin[1] - @destination[1]).abs
  end

  def no_friendly_at_dest?(board)
    !board.piece_at?(@color, @destination[0], @destination[1], 'friendly')
  end

  def diagonal_clear?(board)
    board.diagonal_clear?(@origin, @destination)
  end

  def horizontal_clear?(board)
    board.horizontal_clear?(@origin, @destination)
  end

  def results_in_king_safety?(board)
    dest_y = @destination[0]
    dest_x = @destination[1]
    check_test_board = Board.new
    check_test_board.state = Marshal.load(Marshal.dump(board.state))
    check_test_board.state[@origin[0]][@origin[1]] = nil
    check_test_board.state[dest_y][dest_x] = dup
    check_test_board.king_is_safe?(@color)
  end
end
