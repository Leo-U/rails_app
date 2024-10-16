# frozen_string_literal: true

require_relative 'game'

class GameInterface
  def initialize
    @color_choices = %w[black white]
    @directory = './saved-games'
  end

  def start
    loop do
      display_menu
      process_choice(gets.chomp.to_i)
    end
  end

  private

  def display_menu
    puts 'Pick one:'
    puts ''
    puts '(1) Human vs. computer'
    puts '(2) Human vs. human'
    puts '(3) Load saved game'
  end

  def process_choice(choice)
    case choice
    when 1
      setup_and_start_computer_game
    when 2
      start_human_game
    when 3
      load_game
    end
  end

  def setup_and_start_computer_game
    color = get_color_choice
    game = setup_game(color, true)
    game.play_game
  end

  def start_human_game
    game = Game.new
    game.play_game
  end

  def get_color_choice
    puts 'Do you want to play as Black or White?'
    color = nil

    until @color_choices.include?(color)
      color = gets.chomp.downcase
      puts 'Invalid choice.' unless @color_choices.include?(color)
    end
    color
  end

  def setup_game(color, play_with_computer)
    game = Game.new
    game.play_with_computer = play_with_computer
    if color == 'black'
      game.print_color = 'black'
      game.computer_has_turn = game.computer_has_turn.reverse
    end
    game
  end

  def load_game
    if Dir.entries(@directory).length == 2
      system 'clear'
      puts "\e[38;5;196mNo games have been saved.\e[0m"
      puts ''
    else
      game = get_saved_game
      game&.play_from_saved
    end
  end

  def get_saved_game
    puts 'Pick a saved game:'
    Dir.entries(@directory).each do |filename|
      puts filename unless ['.', '..'].include? filename
    end
    filename = nil
    until Dir.entries(@directory).include?(filename)
      filename = gets.chomp.downcase
      return Game.load_game("#{@directory}/#{filename}") if Dir.entries(@directory).include?(filename)

      puts 'Invalid filename. Please re-type.'

    end
  end
end

system 'clear'
GameInterface.new.start
