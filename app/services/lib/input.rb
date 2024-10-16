# frozen_string_literal: true

require 'singleton'

class Input
  include Singleton
  def get_input
    @value = gets.chomp.downcase
  end
end
