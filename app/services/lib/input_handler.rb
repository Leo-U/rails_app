# frozen_string_literal: true

module InputHandler
  def draw_offered?
    @input == 'offer draw'
  end

  def agreement_valid?
    @draw_response == 'accept' && @draw_offered
  end

  def claim_draw?
    @input == 'claim draw'
  end

  def long_c?
    @input == 'o-o-o'
  end

  def short_c?
    @input == 'o-o'
  end

  def resign?
    @input == 'resign'
  end

  def algebraic?(index_1, index_2)
    @input[index_1].between?('a', 'h') && @input[index_2].between?('1', '8')
  end

  def pawn_push?
    @input.length == 2 && algebraic?(-2, -1)
  end

  def non_pawn?
    @input.length == 3 && @letters.key?(@input[0]) && algebraic?(-2, -1)
  end

  def unambiguous?
    @input.length == 4 && algebraic?(0, 1) && algebraic?(-2, -1)
  end

  def save_game?
    @input == 'save game' || @input == 'save'
  end

  def help?
    @input == 'h' || @input == 'help'
  end

  def input_valid?
    non_pawn? ||
      pawn_push? ||
      short_c? ||
      long_c? ||
      draw_offered? ||
      agreement_valid? ||
      claim_draw? ||
      resign? ||
      unambiguous? ||
      save_game? ||
      help?
  end

  def save_sequence
    return unless save_game?

    puts 'Please enter filename.'
    filename = gets.chomp
    save_game(filename)
    recursive_sequence
  end

  def retrieve_dest
    @dest_y = 8 - @input[-1].to_i
    @dest_x = ('a'..'h').to_a.index @input[-2]
  end

  def retrieve_unambiguous_origin
    @origin_y = 8 - @input[1].to_i
    @origin_x = ('a'..'h').to_a.index @input[0]
  end

  def retrieve_origin_from_piece
    @origin_y = @board.legal_pieces[0].origin[0]
    @origin_x = @board.legal_pieces[0].origin[1]
  end

  def lookup_piece
    @letters[@input[0]]
  end
end
