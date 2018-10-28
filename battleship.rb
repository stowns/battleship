require 'byebug'
require './player1/ships'
require './player2/ships'

module Common
  COLUMNS = ['A',  'B',  'C',  'D',  'E',  'F',  'G',  'H',  'I', 'J']

  def in_bounds(col,row)
    # or's w/ inverse to return faster if one returns falsey
    !(!COLUMNS.index(col) || row < 0 || row > 10)
  end
end

class Board
  include Common
  
  attr_accessor :occupied_spaces, :ships
  
  def initialize(arr)    
    @occupied_spaces = Hash[COLUMNS.map { |column| [column,{}] }]
    @ships = {}

    arr.each_with_index do |ship, i|
      ship[:id] = i # use the index as the ship's id
      ship[:occupied_spaces] = [] # we'll store all of the occ_spaces for tracking damage
      @ships[i] = ship # store ship in hash for easier lookup later

      # current position vars
      col = ship[:position][0]
      col_i = COLUMNS.index(col)
      row = ship[:position][1..ship[:position].length].to_i
      length = ship[:length] - 1
      direction = ship[:direction]
    
      # add the initial position
      add_position(i, col, row)

      # add additional positions based on length of ship and direction
      case direction
      when :north
        calc_n_s_ship_pos(i, length, col, row, -1)
      when :south
        calc_n_s_ship_pos(i, length, col, row, 1)
      when :east
        calc_e_w_ship_pos(i, length, col_i, row, 1)
      when :west
        calc_e_w_ship_pos(i, length, col_i, row, -1)
      else
        raise "#{direction} is not a valid direction :("
      end
    end
  end

  def calc_n_s_ship_pos(ship_id, length, col, initial_row, inc_or_dec)
    (1..length).each do |i|
      add_position(ship_id, col, initial_row + (i*inc_or_dec))
    end
  end

  def calc_e_w_ship_pos(ship_id, length, col_i, row, inc_or_dec)
    (1..length).each do |i|
      add_position(ship_id, COLUMNS[col_i + (i*inc_or_dec)], row)
    end
  end

  def add_position(ship_id, col, row)
    if @occupied_spaces[col]&.[](row)
      raise "A ship already exists at #{col}#{row}"
    elsif !in_bounds(col, row)
      raise "This ship is sailing off the earth at #{col}#{row}"
    end

    @occupied_spaces[col][row] = ship_id
    @ships[ship_id][:occupied_spaces] << "#{col}#{row}"
  end
end

class Battleship
  include Common

  def initialize(playerA, playerB)
    @player_a_turn = true
    @player_a_board = Board.new(playerA)
    @player_b_board = Board.new(playerB)
    @current_board = @player_b_board
  end

  def fire!(pos)
    end_game = false
    col = pos[0]
    row = pos[1..pos.length].to_i
    if !in_bounds(col, row)
      puts "That position is out-of-bounds! Try again with something [A-J][1-10]"
      return
    end

    ship_id = @current_board.occupied_spaces[pos[0]]&.[](pos[1..pos.length].to_i)
    ship = @current_board.ships[ship_id]
    msg = ""
    if ship_id
      # we know a ship is on this space, may have already been hit though
      hit = ship[:occupied_spaces].index(pos)
      if hit
        reaction = ['Dang', 'No', 'Why me?', 'You have to be kidding me', 'Aw Snap', 'Well GD it', 'FU'].sample
        ship[:occupied_spaces].delete_at(hit)
        if ship[:occupied_spaces].length.eql?(0)
          msg = "#{reaction}! You sunk my #{ship[:type]}!"
          ship[:sunken] = true

          if @current_board.ships.all? { |k, v| v[:sunken] }
            end_game = true
          end
        else
          msg = "#{reaction}! It's a hit!"
        end
      else
        insult = ['dummy', 'moron', 'loser', 'jerk', 'jerkface'].sample
        msg = "You already hit a ship at #{pos} #{insult}!"
      end
    else
      msg = "Not a hit.."
    end
    
    puts msg
    if end_game
      abort("Game Over!")
    end

    next_turn
  end

  def next_turn
    @player_a_turn = !@player_a_turn
    @current_board = @player_a_turn ? @player_b_board : @player_a_board
    turn_message
  end

  def turn_message
    puts @player_a_turn ? "Player 1, it's your turn!" : "Player 2, it's your turn!"
  end

end

# init the game
battleship = Battleship.new(A, B)
battleship.turn_message

# listen for user input
stream = $stdin
stream.each do |line|
  battleship.fire!(line.chomp!.upcase)
end