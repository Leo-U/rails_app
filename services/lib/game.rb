# frozen_string_literal: true

require_relative 'input_handler'
require_relative 'computer_player'
require_relative 'board'
require_relative 'input'

class Game
  include InputHandler
  include ComputerPlayer

  attr_reader :board
  attr_accessor :play_with_computer, :computer_has_turn, :print_color

  def initialize
    @board = Board.new
    @turn_color = %w[white black]
    @game_status = 'ongoing'
    @input = ''
    @fifty_move_increment = 0
    @letters = { 'n' => 'kni', 'b' => 'bis', 'r' => 'roo', 'q' => 'que', 'k' => 'kin' }
    @play_with_computer = false
    @computer_has_turn = [false, true]
    @print_color = 'white'
  end

  def get_input_until_valid
    loop do
      puts "#{@turn_color[0].capitalize}, enter move or 'help'."
      @input = Input.instance.get_input
      break if input_valid?

      puts 'Invalid input. Try again.'
    end
  end

  def continue_sequence
    system 'clear'
    @board.full_print_sequence(@print_color)
    @turn_color.reverse!
    recursive_sequence
  end

  def set_game_status
    @game_status =
      if @board.player_stalemated?(@turn_color[0])
        'stalemate'
      elsif @board.player_checkmated?(@turn_color[0])
        'mate'
      elsif @board.insufficient_material?
        'insufficient material'
      elsif @input == 'resign'
        'resignation'
      elsif agreement_valid?
        'draw by agreement'
      elsif @board.count_repeated_positions == 3
        'threefold'
      elsif @fifty_move_increment == 50
        'fifty'
      end
  end

  def puts_ending
    case @game_status
    when 'mate'
      puts "Checkmate. #{@turn_color[1].capitalize} wins."
    when 'stalemate'
      puts 'Stalemate. Teehee!'
    when 'insufficient material'
      puts 'Draw by insufficient material.'
    when 'resignation'
      puts "#{@turn_color[1].capitalize} resigns. #{@turn_color[0].capitalize} wins!"
    when 'draw by agreement'
      puts 'Draw by agreement.'
    when 'threefold'
      puts 'Draw by threefold repetition.'
    when 'fifty'
      puts 'Draw by fifty-move rule.'
    end
  end

  def end_condition?
    ['mate', 'stalemate', 'insufficient material', 'resignation', 'draw by agreement', 'threefold',
     'fifty'].include?(@game_status)
  end

  def get_draw_response
    if @computer_has_turn[1] && @play_with_computer
      puts 'Computer takes pity on you and accepts the draw.'
      sleep(2.5)
      @draw_response = 'accept'
    else
      loop do
        @draw_response = gets.chomp.downcase
        break if @draw_response == 'accept' || @draw_response == 'decline'

        puts "'Please enter 'accept' or 'decline'."
      end
    end
  end

  def handle_draw_agreement
    return unless draw_offered?

    @draw_offered = true
    unless @computer_has_turn[1] && @play_with_computer
      puts "#{@turn_color[0].capitalize} offers draw. #{@turn_color[1].capitalize}, please accept or decline."
    end
    get_draw_response
    unless agreement_valid?
      @draw_offered = false
      @turn_color.reverse!
    end
    continue_sequence
  end

  def set_computer_move
    random_move = sample_legal_moves(@turn_color[0])
    sleep 0.5
    @origin_y = random_move[0][0]
    @origin_x = random_move[0][1]
    @dest_y = random_move[1][0]
    @dest_x = random_move[1][1]
  end

  def make_computer_move
    pre_castle_state = [@board.white_has_castled, @board.black_has_castled]
    castle_as_computer(1)
    castle_as_computer(-1)
    post_castle_state = [@board.white_has_castled, @board.black_has_castled]
    return unless pre_castle_state == post_castle_state

    @board.make_move(@origin_y, @origin_x, @dest_y, @dest_x, @computer_has_turn[0],
                     @print_color)
  end

  def print_instructions
    puts ''
    File.open('lib/instructions.txt', 'r') do |file|
      file.each_line do |line|
        puts line
      end
    end
    puts ''
  end

  def handle_help
    return unless @input == 'help'.downcase

    print_instructions
    get_input_until_valid
  end

  def handle_input
    get_input_until_valid
    handle_draw_agreement
    handle_help
    retrieve_dest
    branch
  end

  def recursive_sequence
    set_game_status
    if end_condition?
      puts_ending
      return
    end
    if @computer_has_turn[0]
      set_computer_move
    else
      handle_input
      save_sequence
    end
    return if end_condition?

    make_computer_move if @computer_has_turn[0]
    before_move_state = @board.pawn_and_piece_counts
    unless @input == 'resign' || @computer_has_turn[0]
      @board.make_move(@origin_y, @origin_x, @dest_y, @dest_x, false,
                       @print_color)
    end
    after_move_state = @board.pawn_and_piece_counts
    @fifty_move_increment += before_move_state != after_move_state ? -@fifty_move_increment : 0.5
    @board.push_position
    @computer_has_turn.reverse! if @play_with_computer
    continue_sequence
  end

  def abort
    puts 'Illegal move.'
    recursive_sequence
  end

  def get_origin_from_piece_letter
    @board.find_legal_pieces(@turn_color[0], lookup_piece, @dest_y, @dest_x)
    legal_count = @board.legal_pieces.length
    if legal_count.zero?
      abort
    elsif legal_count > 1
      puts "More than one such piece can move there. State origin square and destination square, e.g. 'a1a4'."
      recursive_sequence
    else
      retrieve_origin_from_piece
      @board.legal_pieces = []
    end
  end

  def get_origin_for_pawn_push
    @board.find_pawn_origin(@turn_color[0], @dest_y, @dest_x)
    legal_count = @board.legal_pieces.length
    if legal_count.zero?
      abort
    else
      retrieve_origin_from_piece
      @board.legal_pieces = []
    end
  end

  def check_legality
    retrieve_unambiguous_origin
    @board.check_if_legal(@turn_color[0], @origin_y, @origin_x, @dest_y, @dest_x)
    legal_count = @board.legal_pieces.length
    if legal_count.zero?
      abort
    else
      @board.legal_pieces = []
    end
  end

  def try_castle(dir)
    has_castled = @turn_color[0] == 'white' ? @board.white_has_castled : @board.black_has_castled
    abort if has_castled || @board.find_king(@turn_color[0]).unmoved == false
    king = @board.find_king(@turn_color[0])
    rook = if dir == 1
             @turn_color[0] == 'white' ? @board.state[7][7] : @board.state[0][7]
           else
             @turn_color[0] == 'white' ? @board.state[7][0] : @board.state[0][0]
           end
    abort if rook.nil? || @board.castle(king, rook, dir) == false
  end

  def castle_as_computer(dir)
    return if @board.find_king(@turn_color[0]).unmoved == false

    king = @board.find_king(@turn_color[0])
    rook = if dir == 1
             @turn_color[0] == 'white' ? @board.state[7][7] : @board.state[0][7]
           else
             @turn_color[0] == 'white' ? @board.state[7][0] : @board.state[0][0]
           end
    @board.castle(king, rook, dir) unless rook.nil?
  end

  def branch
    if pawn_push?
      get_origin_for_pawn_push
    elsif unambiguous?
      check_legality
    elsif non_pawn?
      get_origin_from_piece_letter
    elsif short_c?
      try_castle(1)
      @computer_has_turn.reverse! if @play_with_computer
      continue_sequence
    elsif long_c?
      try_castle(-1)
      @computer_has_turn.reverse! if @play_with_computer
      continue_sequence
    end
  end

  def save_game(filename)
    File.open("./saved-games/#{filename}", 'w') do |file|
      file.puts Marshal.dump(self)
    end
  end

  def self.load_game(filename)
    File.open(filename, 'r') do |file|
      Marshal.load(file)
    end
  end

  def play_game
    @board.setup_board
    system 'clear'
    @board.full_print_sequence(@print_color)
    @board.push_position
    recursive_sequence
  end

  def play_from_saved
    system 'clear'
    @board.full_print_sequence(@print_color)
    @board.push_position
    recursive_sequence
  end

  def play_saved_game(filename)
    game = load_game(filename)
    game.play_game
  end
end
