# frozen_string_literal: true

require_relative 'piece'

class Bishop < Piece
  def legal_move?(board, check_king_safety = true)
    find_distances
    condition = @distance_y == @distance_x && no_friendly_at_dest?(board) && diagonal_clear?(board)
    check_king_safety ? condition && results_in_king_safety?(board) : condition
  end
end
