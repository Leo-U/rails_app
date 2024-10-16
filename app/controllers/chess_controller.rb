require_dependency "./services/lib/game"

class ChessController < ApplicationController
  def show
    @game = Game.new
    @game.board.setup_board # Initialize the pieces on the board
  end

  def move
    @game = Game.new
    @game.board.setup_board

    # Get user move from params (e.g., 'e2e4')
    move = params[:move]

    # Call a method from the Game class to process the move
    @game.handle_input(move) # Assuming handle_input handles a move like 'e2e4'

    render :show
  end
end
