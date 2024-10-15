# frozen_string_literal: true

require_relative 'piece'

class Queen < Piece
  def queen_path_clear?(board)
    @destination[0] == @origin[0] || @destination[1] == @origin[1] ? horizontal_clear?(board) : diagonal_clear?(board)
  end

  def legal_move?(board, check_king_safety = true)
    find_distances
    condition =
      no_friendly_at_dest?(board) &&
      queen_path_clear?(board) &&
      (@distance_y == @distance_x || (@distance_y.zero? || @distance_x.zero?))
    check_king_safety ? condition && results_in_king_safety?(board) : condition
  end
end
