# frozen_string_literal: true

module ComputerPlayer
  def legal_moves(color)
    legal_moves = []
    @board.state.each do |row|
      row.each do |piece|
        next unless piece && piece.color == color

        @board.state.each_with_index do |row, y|
          row.each_index do |x|
            piece.set_destination(y, x)
            legal_moves << [piece.origin, piece.destination] if piece.legal_move?(@board)
            piece.destination = []
          end
        end
      end
    end
    legal_moves
  end

  def sample_legal_moves(color)
    legal_moves(color).sample
  end
end
