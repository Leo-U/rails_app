# frozen_string_literal: true

require_relative 'piece'

class Pawn < Piece
  attr_reader :moved_two

  def at_starting_square?
    @origin[0] == (@color == 'white' ? 6 : 1)
  end

  def set_direction(c = @color == 'white')
    @one_step = c ? -1 : 1
    @two_step = c ? -2 : 2
  end

  def set_moved_two
    @moved_two = true
  end

  def unset_moved
    @moved_two = false
  end

  def square_attackable?
    find_distances
    dir = @color == 'black' ? 1 : -1
    @destination[0] == @origin[0] + dir && @distance_x == 1
  end

  def en_passant_possible?(board)
    board.piece_at?(@color, @origin[0], @destination[1], 'opponent') &&
      board.state[@origin[0]][@destination[1]].instance_of?(Pawn) &&
      board.state[@origin[0]][@destination[1]].moved_two
  end

  def enemy_at_attackable?(board)
    square_attackable? &&
      (board.piece_at?(@color, @destination[0], @destination[1], 'opponent') || en_passant_possible?(board))
  end

  def x_in_bounds?(_board)
    @destination[1] == @origin[1]
  end

  def one_or_two_steps?(board)
    @destination[0] == @origin[0] + @one_step ||
      (at_starting_square? && @destination[0] == @origin[0] + @two_step && horizontal_clear?(board))
  end

  def no_opponent_in_front?(board)
    !board.piece_at?(@color, @destination[0], @destination[1], 'opponent')
  end

  def legal_move?(board, check_king_safety = true)
    set_direction
    condition = (no_opponent_in_front?(board) &&
    no_friendly_at_dest?(board) &&
    one_or_two_steps?(board) &&
    x_in_bounds?(board) || enemy_at_attackable?(board))
    check_king_safety ? condition && results_in_king_safety?(board) : condition
  end

  def prompt_loop(board, computer_has_turn, print_color, piece_name = nil)
    until board.pieces.reject { |el| el == 'King' }.include?(piece_name)
      system 'clear'
      board.full_print_sequence(print_color)
      puts 'Enter name of new piece for pawn promotion.'
      piece_name = computer_has_turn ? 'Queen' : Input.instance.get_input.capitalize
    end
    piece_name
  end

  def promote(board, computer_has_turn, print_color)
    return unless (@origin[0]).zero? || @origin[0] == 7

    color = (@origin[0]).zero? ? 'white' : 'black'
    piece_name = prompt_loop(board, computer_has_turn, print_color)
    new_piece = board.create_piece(piece_name, color)
    board.add_piece(new_piece, @origin[0], @origin[1])
  end
end
