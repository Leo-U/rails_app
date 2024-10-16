# frozen_string_literal: true

module Display
  def init_escape_sequences
    @dark_bg = "\e[48;5;253m"
    @light_bg = "\e[48;5;231m"
    @black_fg = "\e[30m"
    @red_fg = "\e[38;5;196m"
    @reset = "\e[0m"
  end

  def init_pieces
    @blank = '   '
    @red = { kin: '♚', que: '♛', roo: '♜', bis: '♝', kni: '♞', paw: '♟︎' }.transform_values { |value| @red_fg + value }
    @black = @red.transform_values { |value| @black_fg + value[11..] }
  end

  def init_display
    init_escape_sequences
    init_pieces
  end

  def build_empty_board
    @board = Array.new(8) do |row_i|
      Array.new(8) do |el_i|
        (row_i.even? == el_i.even? ? @light_bg : @dark_bg) + @blank + @reset
      end
    end
  end

  def fill_board
    build_empty_board
    @state.each_with_index do |row, y|
      row.each_with_index do |square, x|
        if square
          piece = square.piece_name.downcase.to_sym
          @board[y][x][-6] = square.color == 'white' ? @red[piece] : @black[piece]
        end
      end
    end
  end

  def board_as_black
    @board.reverse.map(&:reverse)
  end

  def print_board(side, board = @board, rank = 9, i = -1, letters = ('  a'..'  h'))
    if side == 'black'
      (board = board_as_black
       rank = 0
       i = 1
       letters = letters.to_a.reverse)
    end
    print ' ', *letters, "\n"
    board.each do |row|
      print rank += i, ' '
      row.each { |square| print square }
      print ' ', rank, "\n"
    end
    print ' ', *letters, "\n"
  end

  def full_print_sequence(side)
    init_display
    fill_board
    print_board(side)
  end
end

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

class Piece
    attr_reader :origin, :piece_name, :color
    attr_accessor :unmoved, :destination
  
    def initialize(piece_name, color)
      @piece_name = piece_name
      @color = color
      @destination = []
      @origin = []
      @moved_two = false
      @unmoved = true
    end
  
    def set_origin(state)
      state.each do |row|
        @origin = state.index(row), row.index(self) if row.include? self
      end
    end
  
    def set_destination(y, x)
      @destination = [y, x]
    end
  
    def find_distances
      @distance_y = (@origin[0] - @destination[0]).abs
      @distance_x = (@origin[1] - @destination[1]).abs
    end
  
    def no_friendly_at_dest?(board)
      !board.piece_at?(@color, @destination[0], @destination[1], 'friendly')
    end
  
    def diagonal_clear?(board)
      board.diagonal_clear?(@origin, @destination)
    end
  
    def horizontal_clear?(board)
      board.horizontal_clear?(@origin, @destination)
    end
  
    def results_in_king_safety?(board)
      dest_y = @destination[0]
      dest_x = @destination[1]
      check_test_board = Board.new
      check_test_board.state = Marshal.load(Marshal.dump(board.state))
      check_test_board.state[@origin[0]][@origin[1]] = nil
      check_test_board.state[dest_y][dest_x] = dup
      check_test_board.king_is_safe?(@color)
    end
end

class Knight < Piece
    def legal_move?(board, check_king_safety = true)
      find_distances
      condition = [@distance_y, @distance_x].sort == [1, 2] && no_friendly_at_dest?(board)
      check_king_safety ? condition && results_in_king_safety?(board) : condition
    end
end

class Bishop < Piece
    def legal_move?(board, check_king_safety = true)
      find_distances
      condition = @distance_y == @distance_x && no_friendly_at_dest?(board) && diagonal_clear?(board)
      check_king_safety ? condition && results_in_king_safety?(board) : condition
    end
end

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

class King < Piece
  def empty_square_safe?(board)
    board.square_safe?(self, @destination[0], @destination[1])
  end

  def capture_safe?(board, y = @destination[0], x = @destination[1])
    if board.state[y][x] && board.state[y][x].color != color
      dummy_board = Board.new
      dummy_board.state = Marshal.load(Marshal.dump(board.state))
      dummy_board.state[y][x] = nil
      dummy_board.state[@origin[0]][@origin[1]] = nil
      empty_square_safe?(dummy_board)
    else
      true
    end
  end

  def legal_move?(board, check_king_safety = true)
    find_distances
    condition = no_friendly_at_dest?(board) && @distance_y.between?(0, 1) && @distance_x.between?(0, 1)
    check_king_safety ? condition && empty_square_safe?(board) && capture_safe?(board) : condition
  end
end

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
