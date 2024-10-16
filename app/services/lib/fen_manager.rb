# frozen_string_literal: true

module FenManager
  def output_fen
    @state.map do |row|
      row.map do |piece|
        case piece
        when nil then 1
        when Rook then piece.color == 'white' ? 'R' : 'r'
        when Knight then piece.color == 'white' ? 'N' : 'n'
        when Bishop then piece.color == 'white' ? 'B' : 'b'
        when Queen then piece.color == 'white' ? 'Q' : 'q'
        when King then piece.color == 'white' ? 'K' : 'k'
        when Pawn then piece.color == 'white' ? 'P' : 'p'
        end
      end.join
    end.join('/').gsub(/1+/) { |ones| ones.length.to_s }
  end

  def push_position
    @positions << output_fen
  end

  def get_positions
    @positions
  end

  def count_repeated_positions
    fen_counts = Hash.new(0)
    @positions.each do |fen|
      fen_counts[fen] += 1
    end
    fen_counts.values.max
  end
end
