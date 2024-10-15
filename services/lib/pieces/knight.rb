# frozen_string_literal: true

require_relative 'piece'

class Knight < Piece
  def legal_move?(board, check_king_safety = true)
    find_distances
    condition = [@distance_y, @distance_x].sort == [1, 2] && no_friendly_at_dest?(board)
    check_king_safety ? condition && results_in_king_safety?(board) : condition
  end
end
