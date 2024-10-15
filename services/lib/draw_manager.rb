# frozen_string_literal: true

module DrawManager
  def pieces_for_draw_check
    pieces = []
    @state.each do |row|
      row.each do |piece|
        pieces << piece if piece
      end
    end
    pieces
  end

  def only_two_kings?
    pieces_for_draw_check.length == 2
  end

  def lone_bishop_or_knight?
    pieces_for_draw_check.length == 3 && pieces_for_draw_check.any? do |piece|
      piece.piece_name.downcase =~ /^(kni|bis)$/
    end
  end

  def bishops
    pieces_for_draw_check.filter { |piece| piece.piece_name.downcase == 'bis' }
  end

  def same_color_bishops?
    bishops.all? { |bishop| bishop.origin.sum.even? } ||
      bishops.all? { |bishop| bishop.origin.sum.odd? }
  end

  def only_same_color_bishops?
    pieces_for_draw_check.length == 4 && bishops.length == 2 && same_color_bishops?
  end

  def insufficient_material?
    only_two_kings? ||
      lone_bishop_or_knight? ||
      only_same_color_bishops?
  end

  def count_pawns_by_row
    fen_split = output_fen.split '/'
    pawn_count_array = []
    fen_split.each do |row|
      pawn_count_array << row.count('p') + row.count('P')
    end
    pawn_count_array
  end

  def count_pieces
    i = 0
    @state.each do |row|
      row.each do |piece|
        i += 1 if piece
      end
    end
    i
  end

  def pawn_and_piece_counts
    array = count_pawns_by_row
    array << count_pieces
    array
  end
end
