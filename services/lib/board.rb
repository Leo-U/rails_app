# frozen_string_literal: true

require_relative 'display'
require_relative 'fen_manager'
require_relative 'draw_manager'
require_relative 'pieces/piece'
require_relative 'pieces/knight'
require_relative 'pieces/bishop'
require_relative 'pieces/rook'
require_relative 'pieces/queen'
require_relative 'pieces/king'
require_relative 'pieces/pawn'

class Board
  include Display
  include FenManager
  include DrawManager

  attr_reader :pieces, :board, :white_has_castled, :black_has_castled
  attr_accessor :legal_pieces, :state

  def initialize
    @state =  8.times.map { 8.times.map { nil } }
    @pieces = %w[Rook Knight Bishop Queen King Bishop Knight Rook]
    @legal_pieces = []
    @positions = []
    @white_has_castled = false
    @black_has_castled = false
  end

  def add_piece(piece, y, x)
    @state[y][x] = piece
    @state[y][x].set_origin(@state)
  end

  def create_piece(name, color)
    label = color == 'black' ? name.downcase : name
    Object.const_get(name).new(label.slice(0, 3), color)
  end

  def add_home_rank(rank, color)
    @state[rank].each_index do |i|
      add_piece(create_piece(@pieces[i], color), rank, i)
    end
  end

  def add_pawn_rank(rank, color)
    @state[rank].each_index do |i|
      add_piece(create_piece('Pawn', color), rank, i)
    end
  end

  def setup_board
    add_home_rank(0, 'black')
    add_pawn_rank(1, 'black')
    add_pawn_rank(6, 'white')
    add_home_rank(7, 'white')
  end

  def reset_piece_state(piece)
    piece.set_origin(@state)
    piece.unmoved = false
    @state.each do |row|
      row.each do |el|
        el.unset_moved if el.instance_of?(Pawn)
      end
    end
  end

  def set_piece_state(piece, dest_y, dest_x)
    piece.set_destination(dest_y, dest_x)
    piece.set_origin(@state)
  end

  def set_nil(piece, origin_y, origin_x, dest_x)
    @state[origin_y][dest_x] = nil if piece.instance_of?(Pawn) && piece.en_passant_possible?(self)
    @state[origin_y][origin_x] = nil
  end

  def move_piece_if_legal(piece, origin_y, origin_x, dest_y, dest_x)
    return unless piece.legal_move?(self)

    @state[dest_y][dest_x] = piece
    set_nil(piece, origin_y, origin_x, dest_x)
  end

  def make_move(origin_y, origin_x, dest_y, dest_x, computer_has_turn, print_color)
    piece = @state[origin_y][origin_x]
    set_piece_state(piece, dest_y, dest_x)
    move_piece_if_legal(piece, origin_y, origin_x, dest_y, dest_x)
    reset_piece_state(piece)
    piece.set_moved_two if piece.instance_of?(Pawn) && (origin_y - dest_y).abs == 2
    piece.promote(self, computer_has_turn, print_color) if piece.instance_of?(Pawn)
  end

  def piece_at?(color, dest_y, dest_x, side)
    dest_piece = @state[dest_y][dest_x]
    !dest_piece.nil? && (side == 'friendly' ? color == dest_piece.color : color != dest_piece.color)
  end

  def direction_clear?(origin, destination, y_inc, x_inc, y = origin[0], x = origin[1])
    path = []
    loop do
      y += y_inc
      x += x_inc
      break if destination == [y, x] || !y.between?(0, 7) || !x.between?(0, 7)

      path << @state[y][x].nil?
    end
    path.all?
  end

  def diagonal_clear?(origin, destination)
    inc_y = destination[0] > origin[0] ? 1 : -1
    inc_x = destination[1] > origin[1] ? 1 : -1
    direction_clear?(origin, destination, inc_y, inc_x)
  end

  def horizontal_clear?(origin, destination)
    if destination[0] != origin[0]
      inc_x = 0
      inc_y = destination[0] > origin[0] ? 1 : -1
    else
      inc_y = 0
      inc_x = destination[1] > origin[1] ? 1 : -1
    end
    direction_clear?(origin, destination, inc_y, inc_x)
  end

  def square_safe?(king, dest_y, dest_x)
    opponent_pieces = @state.flatten.select { |el| el.is_a?(Piece) && el.color != king.color }
    opponent_pieces.each do |piece|
      piece.set_origin(@state)
      piece.set_destination(dest_y, dest_x)
    end
    @state[king.origin[0]][king.origin[1]] = nil
    boolean = opponent_pieces.none? do |piece|
      piece.instance_of?(Pawn) ? piece.square_attackable? : piece.legal_move?(self, check_king_safety = false)
    end
    @state[king.origin[0]][king.origin[1]] = king
    boolean
  end

  def find_king(color)
    @state.each do |row|
      row.each do |piece|
        return piece if piece.instance_of?(King) && piece.color == color
      end
    end
  end

  def king_is_safe?(color)
    king = find_king(color)
    dest_y = king.origin[0]
    dest_x = king.origin[1]
    square_safe?(king, dest_y, dest_x)
  end

  def each_square_safe?(king, dir, y = king.origin[0], x = king.origin[1])
    coords = [[y, x], [y, x + dir], [y, x + dir * 2]]
    booleans = []
    coords.each do |sub_arr|
      booleans << square_safe?(king, sub_arr[0], sub_arr[1])
    end
    booleans.all?
  end

  def castle(king, rook, dir, y = king.origin[0], king_x = king.origin[1], rook_x = rook.origin[1])
    king_dest_x = king_x + dir * 2
    rook_dest_x = king_x + dir
    if horizontal_clear?([y, king_x], [y, rook_x]) && each_square_safe?(king, dir) && king.unmoved && rook.unmoved
      @state[y][king_x], @state[y][rook_x] = nil, nil
      add_piece(king, y, king_dest_x)
      add_piece(rook, y, rook_dest_x)
      king.color == 'white' ? @white_has_castled = true : @black_has_castled = true
      king.unmoved, rook.unmoved = false, false
    else
      false
    end
  end

  def find_legal_pieces(turn_color, piece_name, dest_y, dest_x)
    @state.each do |row|
      row.each do |piece|
        next unless !piece.nil? && piece.color == turn_color && piece.piece_name.downcase == piece_name

        piece.set_destination(dest_y, dest_x)
        @legal_pieces << piece if piece.legal_move?(self)
        piece.destination = []
      end
    end
  end

  def find_pawn_origin(turn_color, dest_y, dest_x)
    @state.each do |row|
      piece = row[dest_x]
      next unless !piece.nil? && piece.color == turn_color && piece.instance_of?(Pawn)

      piece.set_destination(dest_y, dest_x)
      @legal_pieces << piece if piece.legal_move?(self)
      piece.destination = []
    end
  end

  def check_if_legal(turn_color, origin_y, origin_x, dest_y, dest_x)
    piece = @state[origin_y][origin_x]
    return unless !piece.nil? && piece.color == turn_color

    piece.set_destination(dest_y, dest_x)
    @legal_pieces << piece if piece.legal_move?(self)
  end

  def print_for_rspec
    @state.each do |row|
      row.each do |piece|
        if piece.nil?
          print '--- '
        else
          print "#{piece.piece_name} "
        end
      end
      puts
    end
  end

  def player_mated?(color)
    @state.each do |row|
      row.each do |piece|
        next unless piece && piece.color == color

        @state.each_with_index do |row, y|
          row.each_index do |x|
            piece.set_destination(y, x)
            return false if piece.legal_move?(self)

            piece.destination = []
          end
        end
      end
    end
    true
  end

  def player_checkmated?(color)
    king = find_king(color)
    !square_safe?(king, king.origin[0], king.origin[1]) && player_mated?(color)
  end

  def player_stalemated?(color)
    king = find_king(color)
    square_safe?(king, king.origin[0], king.origin[1]) && player_mated?(color)
  end
end
