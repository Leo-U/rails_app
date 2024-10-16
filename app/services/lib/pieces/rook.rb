# frozen_string_literal: true

require_relative 'piece'

class Rook < Piece
  def legal_move?(board, check_king_safety = true)
    find_distances
    condition =
      (@distance_y.zero? || @distance_x.zero?) &&
      no_friendly_at_dest?(board) &&
      horizontal_clear?(board)
    check_king_safety ? condition && results_in_king_safety?(board) : condition
  end
end
