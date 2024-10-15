# frozen_string_literal: true

require_relative 'piece'

class King < Piece
  def empty_square_safe?(board)
    board.square_safe?(self, @destination[0], @destination[1])
  end

  def capture_safe?(board, y = @destination[0], x = @destination[1])
    if board.state[y][x] && board.state[y][x].color != color
      dummy_board = Board.new
      dummy_board.state = Marshal.load(Marshal.dump(board.state))
      dummy_board.state[y][x] = nil
      dummy_board.state[@origin[0]][@origin[1]] = nil
      empty_square_safe?(dummy_board)
    else
      true
    end
  end

  def legal_move?(board, check_king_safety = true)
    find_distances
    condition = no_friendly_at_dest?(board) && @distance_y.between?(0, 1) && @distance_x.between?(0, 1)
    check_king_safety ? condition && empty_square_safe?(board) && capture_safe?(board) : condition
  end
end
