
class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                  [[1, 5, 9], [7, 5, 3]]

  def initialize
    @squares = {}
    reset
  end

  # rubocop : disable Metrics/AbcSize
  # rubocop : disable Metrics/LineLength
  def draw
    puts "     |     |"
    puts "  #{@squares.fetch(1)}  |  #{@squares.fetch(2)}  |  #{@squares.fetch(3)}  "
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares.fetch(4)}  |  #{@squares.fetch(5)}  |  #{@squares.fetch(6)}  "
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares.fetch(7)}  |  #{@squares.fetch(8)}  |  #{@squares.fetch(9)}  "
    puts "     |     |"
  end
  # rubocop : enable Metrics/Abcsize
  # rubocop : enable Metrics/LineLength

  def []=(key, marker)
    @squares[key].marker = marker
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    markers = ->(*a) { @squares.values_at(*a).map(&:marker) }
    WINNING_LINES.each do |line|
      if markers.call(*line).uniq.size == 1 && markers.call(*line)[0] != ' '
        return markers.call(*line)[0]
      end
    end
    nil
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker = INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end
end

class Player
  attr_reader :marker

  def initialize(marker)
    @marker = marker
  end
end

class TTTGame
  HUMAN_MARKER = 'X'
  COMPUTER_MARKER = 'O'
  FIRST_TO_MOVE = :player

  attr_reader :board, :human, :computer

  def initialize
    @board = Board.new
    @human = Player.new(HUMAN_MARKER)
    @computer = Player.new(COMPUTER_MARKER)
    @current_player = FIRST_TO_MOVE
  end

  def play
    clear
    display_welcome_message
    loop do
      display_board
      loop do
        current_player_moves
        break if board.someone_won? || board.full?
        clear_screen_and_display_board
        change_current_player
      end
      display_result
      break unless play_again?
      reset
      display_play_again_message
    end
    display_goodbye_message
  end

  private

  def display_welcome_message
    puts "Welcome to TIC TAC TOE"
    puts ''
  end

  def display_goodbye_message
    puts "Thanks for playing and Goodbye!"
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def display_board
    puts "You're a #{human.marker}. Computer is a #{computer.marker}."
    puts ""
    board.draw
    puts ""
  end

  def joinor(arr, separation = ', ', ending = 'or')
    if arr.size > 1
      arr[0..-2].join(', ') + ", #{ending} #{arr[-1]}"
    else
      arr.join
    end
  end

  def human_moves
    puts "Chose a square : #{joinor(board.unmarked_keys)} :"
    square = nil
    loop do
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      puts "Sorry that's not a valid input"
    end
    board[square] = human.marker
  end

  def computer_moves
    board[board.unmarked_keys.sample] = computer.marker
  end

  def display_result
    clear_screen_and_display_board
    case board.winning_marker
    when human.marker then puts 'You won!'
    when computer.marker then puts 'Computer won!'
    else
      puts "It's a tie!"
    end
  end

  def clear
    system "clear"
  end

  def play_again?
    answer = nil
    loop do
      puts "Do you want to play again?"
      answer = gets.chomp.downcase
      break if ['y', 'n'].include?(answer)
      puts 'Invalid choice!'
    end
    answer == 'y'
  end

  def reset
    clear
    board.reset
    @current_player = FIRST_TO_MOVE
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def current_player_moves
    if @current_player == :player
      human_moves
    else
      computer_moves
    end
  end

  def change_current_player
    @current_player = @current_player == :player ? :machine : :player
  end
end

game = TTTGame.new
game.play
