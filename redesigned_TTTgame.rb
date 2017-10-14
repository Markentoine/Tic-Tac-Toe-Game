=begin
  This TicTacToe game is designed on 10 different objects :

    => Game
    => BoardGame
    => Engine
    => Player
    => VirtualBoard
    => BoardLine
    => Round
    => Move
    => Score
    => Stats

  The Game object take in charge :
      => Welcome the user and propose to read the rules
      => Display the BoardGame (scalable : 3*3, 5*5, 9*9)
      => Run the Engine
      => Stop the Engine
      => Say Goodbye to the user and propose to look at Stats

  The BoardGame is the physical display :
  It consists of
      => A box at the top to display some infos
      => A grid to display the players markers
      => An other box at the bottom to display some infos

  The Engine will take in charge the core of the game :
      => It defines the Players (number : 2 or 3)
          => Player will ask for a type(human or computer)
                                 a name
                                 a player_number

             Each Player has a MARKER.

             Each Player can :
                                => chose to view the rules and
                                   the commands of the game(if human)
                                => chose his Move at each Round.
                                => chose to end the game or play it again.

     => It sets a new VirtualBoard (same scale as the BoardGame)
                              => is made with Boardlines that have cells
                                => rows
                                => columns
                                => diagonals

                      The VirtualBoard is reponsible of the calculations
                      in the core game :
                                => set the markers after each move
                                => verify if there is a winner
                                => verify if the board is full
                                => give the informations to display by the BoardGame.
    => It records a Score :
                                => record wins
                                => record loses


   => It records Stats on the game  :
                                => record first moves
                                => calculate percentages : games wins/loses
                                => determine the best first moves

  => It runs Rounds until Player decide to end the game
                                => a Round has :
                                     a number
                                  it can
                                     => ask Player for a choice of Move
                                     => Send the Move to the VirtualBoard
                                     => Receive a message if there is a winner or
                                     if the board is full

  Dependencies :

    => Game          : BoardGame / Player / Engine
    => BoardGame     :
    => Engine        : Player / VirtualBoard / Score / Stats / Move
    => Player        :
    => VirtualBoard  : BoardLine
    => BoardLine     :
    => Move          :
    => Score         :
    => Stats         :

=end

require 'colorize'

$grid_size = 3

class Game
  attr_accessor :core_game

  def initialize
    clear_screen
    puts 'Welcome here!'
    puts 'Before we play, let me ask you few questions.'
    @core_game = Engine.new
    puts "Thank you for your patience."
    puts "And now...Let's play!"
    wait(1)
  end

  def play
    display_intro
    loop do
      clear_screen
      core_game.reset_engine
      start_game
      clear_screen
      display_result
      wait(0.5)
      clear_screen
      display_score
      break unless play_again?
    end
    clear_screen
    say_good_bye
  end

  private

  def play_again?
    puts "Do you to want to play again?"
    answer = nil
    loop do
      answer = gets.chomp
      break if ['y', 'n', 'yes', 'no'].include?(answer)
      puts 'Invalid choice'.red.blink
    end
    ['y', 'yes'].include?(answer)
  end

  def display_intro
    clear_screen
	  welcome
	  wait(2)
	  clear_screen
  end

  def display_score
    core_game.say_score
  end

  def start_game
    core_game.start
  end

  def display_result
    core_game.display_final
  end

  def say_good_bye
    core_game.display_good_bye
  end

  def prompt(message)
    puts "=>#{message}"
  end

  def wait(t)
    sleep(t)
  end

  def welcome
    core_game.display_welcome_board
  end

  def clear_screen
    system "clear" or system "cls"
  end
end

class Engine
  attr_accessor :board, :players, :virtual_board, :score, :stats, :move
  attr_reader :n_in_a_row

  def initialize
    @board = BoardGame.new(45, 15, 2)
    @players = construct_players
    @virtual_board = VirtualBoard.new(players.size)
    @score = Score.new(players.size)
    @stats = Stats.new
    @n_in_a_row = define_nb_of_similar_mark_to_win #define rule of the game
  end

  def start
    loop do
      players.each do |player|
        break unless Move.possible?
        update_choices(player)
        set_best_choices_for_computer(player) if player.type == :computer
        @move = Move.new(player.type)
        virtual_board.fill_board(move.result, player.mark)
        clear_screen
        update_boardgame_chose(player)
        wait(1) if player.type == :computer
        stats.count_rounds if player == players[-1]
        #stats.record_moves(move)
        wait(1)
        break if virtual_board.one_line_complete?(player.mark, @n_in_a_row)
        wait(1)
        clear_screen
      end
      break if a_winner? || !Move.possible?
    end
    update_score
  end

  def reset_engine
    self.virtual_board = VirtualBoard.new(players.size)
    Move.reset
    stats.reset_rounds
  end

  def define_nb_of_similar_mark_to_win # rules for each type of game
    if $grid_size == 3
      3
    elsif $grid_size == 5 && players.size == 3
      3
    elsif $grid_size == 5
      4
    elsif $grid_size == 9 && players.size == 3
      4
    else
      5
    end
  end

  def update_score
    winner = find_winner if a_winner?
    score.update_score(winner.player_number) if winner
  end

  def update_choices(player)
    if $grid_size == 3
      update_boardgame_choices_left
    else
      board.set_marks(*virtual_board.display_rows)
      board.display("#{player.name}, make a choice...", 'First you think, then you move!')
    end
  end

  def display_final
    if a_winner?
      winner = find_winner
      board.set_marks(*board.define_inside_message("WIN WIN WIN"))
      board.display("#{winner.name}, You", ':)')
      wait(2)
    elsif !Move.possible?
      board.set_marks(*board.define_inside_message('TIE TIE TIE'))
      board.display("IT'S A", ':|')
      wait(1)
    end
  end

  def say_score
    if players.size == 2
      board.set_marks(*board.define_inside_message("PL1 #{score.state[0]}-#{score.state[1]} PL2"))
      board.display("SCORE", "#{score.state[0]} - #{score.state[1]}")
    else
      board.set_marks(*board.define_inside_message("1P#{score.state[0]} 2P#{score.state[1]} 3P#{score.state[2]}"))
      board.display("SCORE", "#{score.state[0]} - #{score.state[1]} - #{score.state[2]}")
    end
  end

  def display_good_bye
    board.set_marks(*board.define_inside_message("BYE BYE BYE"))
    board.display("GOOD", 'HAVE A NICE DAY')
  end

  def set_best_choices_for_computer(computer)
    other_players = players - [computer]
    Move.fill_computer_choices(virtual_board.find_best_choice_for_computer(computer, other_players, n_in_a_row))
  end

  def a_winner?
    players.any? { |player|  virtual_board.one_line_complete?(player.mark, @n_in_a_row)}
  end

  def find_winner
    players.find { |player| virtual_board.one_line_complete?(player.mark, @n_in_a_row) }
  end

  def wait(t)
    sleep(t)
  end

  def clear_screen
    system "clear" or system "cls"
  end

  def joinor(arr)
    if arr.size > 2
      arr[0, arr.size - 2].join(', ') + ", #{arr[-2]} or #{arr[-1]}"
    elsif arr.size == 2
      "#{arr[0]} or #{arr[-1]}"
    else
      arr[0]
    end
  end

  def update_boardgame_choices_left
    board.set_marks(*virtual_board.display_rows)
    board.display("Choices : #{joinor(Move.left_choices)}", 'First you think, then you move')
  end

  def update_boardgame_chose(player)
    board.set_marks(*virtual_board.display_rows)
    board.display("#{player.name} chose : #{@move.result}", "ROUND # #{stats.rounds} ")
  end

  def show_commands
    board.set_marks(['7','8','9'], ['4', '5', '6'], ['1', '2', '3'])
    board.display('COMMANDS', '=>TYPE THE RIGHT NUMBER<=')
  end

  def display_welcome_board
    board.set_marks(*board.define_inside_message('TIC TAC TOE'))
    human_players = @players.select { |player| player.type == :human }
    if human_players.empty?
      board.display('WELCOME', 'OK, COMPUTERS!')
    elsif human_players.size == 3
      board.display('WELCOME', 'TO ALL OF YOU GUYS')
    elsif human_players.size == 2
      board.display('WELCOME', "#{human_players[0].name} and #{human_players[1].name}")
    elsif human_players.size == 1
      board.display('WELCOME', "#{human_players[0].name}!")
    end
  end

  private

  def construct_players
    players = []
    Player.set_numb_of_players
    (Player.say_numb_of_players).times do |n|
      players << Player.new(Player::MARKERS[n], (n + 1))
    end
    if players.any? { |player| player.type == :human } && $grid_size == 3
      if players.find { |player| player.type == :human }.want_view_commands?
        show_commands
        wait(3)
      end
    end
    players
  end
end

class Player
  attr_reader :name, :type, :mark, :player_number
  attr_accessor :score, :stats

  MARKERS = ['X', 'O', '*']

  @@computers_names = []
  @@numb_of_players = 0

  def initialize(mark, player_number)
  	 @mark = mark
  	 @player_number = player_number
     @type = define_type_player
     @name = set_name
  end

  def self.set_numb_of_players
    puts "How many players you want in this game? 2 or 3 ?"
    answer = nil
    loop do
      answer = gets.chomp.to_i
      break if [2, 3].include?(answer)
      puts 'Invalid choice. Enter 2 or 3'.red.blink
    end
    @@numb_of_players = answer
  end

  def self.say_numb_of_players
    @@numb_of_players
  end

  def want_view_commands?
  	answer = nil
  	puts 'Do you want to view the commands? (y)es or (n)o?'
    loop do
    	answer = gets.chomp
      break if ['y', 'yes', 'n', 'no'].include?(answer)
    puts 'Not a valid choice'.red.blink
    end
    ['y', 'yes'].include?(answer)
  end

  private

  def define_type_player
  	type = nil
    puts "Tell me if : "
    loop do
      puts "Player #{player_number} is : (h)uman or (c)omputer ?"
      type = gets.chomp.downcase
      if type.start_with?('h') || type.start_with?('c')
      	break
      else
      	puts 'INVALID CHOICE'.red.blink
      end
    end
    type.start_with?('h') ? :human : :computer
  end

  def set_name
  	answer = ''
    if type == :computer
    	loop do
        answer = ['Hal 9000', 'The Maniac', 'IA', 'Robert', 'Marcel Proust'].sample
        break unless @@computers_names.include?(answer)
      end
      @@computers_names << answer
    elsif @type == :human
      loop do
        puts "What is the name of the player #{self.player_number} ?"
        answer = gets.chomp.capitalize
        break if answer != '' || answer == ' '
        puts 'Please, enter a correct name.'.red.blink
      end
    end
    answer
  end
end

class BoardGame
	attr_reader :height_grid, :width, :heigth_box
	attr_accessor :color, :marks

	ANGLE = '+'
	BORDER = '|'

	def initialize(width, height_grid, heigth_box)
      $grid_size = set_grid_size.freeze
      Move.reset
      @width = width.odd? ? (width + 1) : width
      @height_grid = height_grid
      @heigth_box = heigth_box
      @color = set_color
      @marks = []
	end

	def define_inside_message(message)
		chars = []
		words = message.split(' ')
		fill_chars = ->(n) { words.each { |w| chars << Array.new(n, '*') + w.chars + Array.new(n, '*') } }
    if $grid_size == 3
      fill_chars.call(0)
    elsif $grid_size == 5
    	chars << Array.new($grid_size, '*')
      fill_chars.call(1)
      chars << Array.new($grid_size, '*')
    elsif $grid_size == 9
    	3.times { chars << Array.new($grid_size, '*')}
    	fill_chars.call(3)
    	3.times { chars << Array.new($grid_size, '*')}
    end
    chars
  end

	def set_marks(*marks)
    self.marks = []
    marks.each { |mark| self.marks << mark }
	end

	def display(message1, message2)
    full_box(message1)
    grid
    full_box(message2, :false, :true)
	end

	def full_box(message = line(width - 2), up = :true, bottom = :true)
    puts (ANGLE + line(width - 2, '-') + ANGLE).send(color) if up == :true
    (heigth_box / 2).times do
	    puts (BORDER + line(width - 2) + BORDER).send(color)
	  end
	  puts (BORDER + "#{message.center(width - 2).bold}" + BORDER).send(color)
	  (heigth_box / 2).times do
	    puts (BORDER + line(width - 2) + BORDER).send(color)
	  end
	  puts (ANGLE + line(width - 2, '-') + ANGLE).send(color) if bottom == :true
	end

	def grid
	  min_line = line((width - 2) / $grid_size)
    inside_border = ((BORDER + min_line) * $grid_size + BORDER)
    inside_border = inside_border.send(color)
    inside_line = (ANGLE + line(width - 2, '-') + ANGLE).send(color)
    part_grid = lambda { (height_grid / ($grid_size * 2)).times do
      puts inside_border
    end }
    $grid_size.times do |n|
      part_grid.call
      marks.empty? ? (puts inside_border) : (puts marked_line(marks[n]))
      part_grid.call
      puts inside_line
    end
  end

  def message_line(mark)
    if mark.to_s.length == 2
      "#{' ' * ((width - ($grid_size * 2)) / ($grid_size * 2) - 1)}#{mark}#{' ' * ((width - ($grid_size * 2)) / ($grid_size * 2))}"
    else
      "#{' ' * ((width - ($grid_size * 2)) / ($grid_size * 2))}#{mark}#{' ' * ((width - ($grid_size * 2)) / ($grid_size * 2))}"
    end
  end

  def set_mark_color(mark)
    case mark
    when 'X' then mark.bold.green
    when 'O' then mark.bold.red
    when '*' then mark.bold.light_magenta
    when 'W' then mark.red.blink
    when 'I' then mark.red.blink
    when 'N' then mark.red.blink
    when 'A' then mark.bold.blue
    else
      mark
    end
  end

  def marked_line(marks)
    result = []
    marks.each do |mark|
      result << '| '.send(color)
      mark = set_mark_color(mark)
      result << message_line(mark)
    end
    result << '|'.send(color)
    result.join
  end

  def line(length, type = ' ')
    type * length
  end

  def clear
    system "clear"
  end

  private

  def set_grid_size
    puts 'Do you want to play  a 3x3, 5x5 or 9x9 game?'
    puts 'Please, enter your choice : 3, 5, 9'
    answer = nil
    loop do
      answer = gets.chomp.to_i
      break if [3, 5, 9].include?(answer)
      puts 'Invalid choice'.red.blink
    end
    answer
	end

	def set_color
    loop do
      puts 'What is your favorite color between :'
      puts '(b)lue, (m)agenta and (g)reen ?'
      answer = gets.chomp.downcase
      self.color = if answer.start_with?('b')
      	             'blue'
                   elsif answer.start_with?('m')
      	             'magenta'
      	           elsif answer.start_with?('g')
      	           	 'green'
      	           end
      break if ['blue', 'magenta', 'green'].include?(color)
      puts 'Invalid choice'.red.blink
    end
    color
	end
end

class Move
	attr_reader :type, :result

  @@choices = (1..($grid_size ** 2)).to_a
  @@computer_choices = []

  def initialize(type)
  	@type = type
  	@result = type == :human ? choose_human : choose_computer
  end

  def self.send_left_choices
    @@choices
  end

  def self.reset
    @@choices = (1..$grid_size ** 2).to_a
  end

  def self.possible?
    !@@choices.empty?
  end

  def self.left_choices
    @@choices
  end

  def self.fill_computer_choices(best_choices)
    @@computer_choices = best_choices
  end

  def choose_human
    choice = nil
    loop do
      choice = gets.chomp.to_i
      break if @@choices.include?(choice)
      puts 'Invalid choice'.red
    end
    @@choices -= [choice]
    choice
  end

  def choose_computer
    choice = @@computer_choices.sample
    @@choices -= [choice]
    choice
  end
end

class VirtualBoard
	attr_accessor :rows, :columns, :diagonals
	attr_reader :size, :nb_players

	def initialize(nb_players)
    @nb_players = nb_players
		@size = $grid_size
    @rows = []
	  @columns = []
	  @diagonals = []
    @rows_coord = (0..size - 1).to_a.product((0..size - 1).to_a)
	  @columns_coord = @rows_coord.map(&:reverse)
    if $grid_size == 5 || $grid_size == 9
      size.times do |n|
        @rows << BoardLine.new(n + 1, :numbers)
        @columns << BoardLine.new(n + 1)
      end
    else
      size.times do |n|
        @rows << BoardLine.new(n + 1)
        @columns << BoardLine.new(n + 1)
      end
    end
    2.times do |n|
    	@diagonals << BoardLine.new(n + 1)
    end
    if $grid_size == 5 && nb_players == 2
      4.times do |n|
        @diagonals << BoardLine.new(n + 3, :normal, 4)
      end
    elsif $grid_size == 5 && nb_players == 3
      4.times do |n|
         @diagonals << BoardLine.new(n + 3, :normal, 4)
       end
      4.times do |n|
        @diagonals << BoardLine.new(n + 7, :normal, 3)
      end
    end
	end

  def find_best_choice_for_computer(computer, other_players, n_in_a_row)
    if opportunity?(computer, n_in_a_row)
      puts "#{computer.name} offensive"
      return find_offensive_move(computer, n_in_a_row)
    elsif threat?(other_players, n_in_a_row)
      puts "#{computer.name} defensive"
      return find_defensive_move(other_players, n_in_a_row)
    elsif $grid_size == 3 && (rows[1].cells[1].to_i != 0 || rows[1].cells[1] == ' ')
      return [5]
    else
      puts "#{computer.name} other"
      Move.send_left_choices
    end
  end

  def find_offensive_move(player, n_in_a_row)
    result = []
    which_lines = [rows, columns, diagonals].map { |lines| lines.any? { |line| line.nearly_complete?(player.mark, n_in_a_row)}}
                                            .find_index { |lines| lines == true }
    if which_lines == 0
      idx = rows.find_index { |row| row.nearly_complete?(player.mark, n_in_a_row) }
      idx2 = rows[idx].cells.find_index { |cell| cell != player.mark && ( cell == ' ' || cell.to_i != 0) }
      if $grid_size == 3
        result = [(idx2 + 1) + ($grid_size * idx)]
      else
        idx2 = rows[idx].cells.each_with_index.map do |e, idx|
          if e == ' ' || e.class == Fixnum
           idx
          else
           e
          end
        end.each_cons(n_in_a_row).select { |cons| cons.count(player.mark) == (n_in_a_row - 1) && cons.count { |x| x.class == Fixnum} == 1 }[0].find { |r| r != player.mark }
        result = [(idx2 + 1) + ($grid_size * idx)]
      end
    elsif which_lines == 1
      idx = columns.find_index { |column| column.nearly_complete?(player.mark, n_in_a_row) }
      idx2 = columns[idx].cells.find_index { |cell| cell != player.mark && ( cell == ' ' || cell.to_i != 0) }
      if $grid_size == 3
        result = [(idx + 1) + (idx2 * $grid_size)]
      else
        idx2 = columns[idx].cells.each_with_index.map { |e, idx| e == ' ' ? idx : e }.each_cons(n_in_a_row).select { |cons| cons.count(player.mark) == (n_in_a_row - 1) && cons.count { |x| x.class == Fixnum} == 1 }[0].find { |r| r != player.mark }
        result = [(idx + 1) + (idx2 * $grid_size)]
      end
    elsif which_lines == 2
      idx = diagonals.find_index { |diagonal| diagonal.nearly_complete?(player.mark, n_in_a_row) }
      idx2 = diagonals[idx].cells.find_index { |cell| cell != player.mark && ( cell == ' ' || cell.to_i != 0) }
      if $grid_size == 3
        if idx == 0
          result = [((idx + 1) + (($grid_size + 1) * idx2))]
        elsif idx == 1
          result = [((idx + 2 ) + (($grid_size - 1) * idx2))]
        end
      else
        idx2 = diagonals[idx].cells.each_with_index.map { |e, idx| e == ' ' ? idx : e }.each_cons(n_in_a_row).select { |cons| cons.count(player.mark) == (n_in_a_row - 1) && cons.count { |x| x.class == Fixnum} == 1 }[0].find { |r| r != player.mark }
        if idx == 0
          result = [((idx + 1) + (($grid_size + 1) * idx2))]
        elsif idx == 1
          result = [((idx + ($grid_size - 1)) + (($grid_size - 1) * idx2))]
        end
        if idx == 2 && $grid_size == 5
          result = [idx + (6 * idx2)]
        elsif idx == 3 && $grid_size == 5
          result = [(idx * 2) + (6 * idx2)]
        elsif idx == 4 && $grid_size == 5
          result = [idx + (4 * idx2)]
        elsif idx == 5 && $grid_size == 5
          result = [(idx * 2) + (4 * idx2)]
        end
      end
    end
    result.flatten
  end

  def find_defensive_move(other_players, n_in_a_row)
    result = []
    other_players.each do |player|
      which_lines = [rows, columns, diagonals].map { |lines| lines.any? { |line| line.nearly_complete?(player.mark, n_in_a_row)}}
                                              .find_index { |lines| lines == true }
      if which_lines == 0
        idx = rows.find_index { |row| row.nearly_complete?(player.mark, n_in_a_row) }
        idx2 = rows[idx].cells.find_index { |cell| cell != player.mark && ( cell == ' ' || cell.to_i != 0) }
        if $grid_size == 3
          result = [(idx2 + 1) + ($grid_size * idx)]
        else
          idx2 = rows[idx].cells.each_with_index.map do |e, idx|
            if e == ' ' || e.class == Fixnum
              idx
            else
              e
            end
          end.each_cons(n_in_a_row).select { |cons| cons.count(player.mark) == (n_in_a_row - 1) && cons.count { |x| x.class == Fixnum} == 1 }[0].find { |r| r != player.mark }
          result = [(idx2 + 1) + ($grid_size * idx)]
        end
      elsif which_lines == 1
        idx = columns.find_index { |column| column.nearly_complete?(player.mark, n_in_a_row) }
        if $grid_size == 3
          idx2 = columns[idx].cells.find_index { |cell| cell != player.mark && ( cell == ' ' || cell.to_i != 0) }
          result = [(idx + 1) + (idx2 * $grid_size)]
        else
          idx2 = columns[idx].cells.each_with_index.map { |e, idx| e == ' ' ? idx : e }.each_cons(n_in_a_row).select { |cons| cons.count(player.mark) == (n_in_a_row - 1) && cons.count { |x| x.class == Fixnum} == 1 }[0].find { |r| r != player.mark }
          result = [(idx + 1) + (idx2 * $grid_size)]
        end
      elsif which_lines == 2
        idx = diagonals.find_index { |diagonal| diagonal.nearly_complete?(player.mark, n_in_a_row) }
        idx2 = diagonals[idx].cells.find_index { |cell| cell != player.mark && ( cell == ' ' || cell.to_i != 0) }
        if $grid_size == 3
          if idx == 0
            result = [((idx + 1) + (($grid_size + 1) * idx2))]
          elsif idx == 1
            result = [((idx + 2 ) + (($grid_size - 1) * idx2))]
          end
        else
          idx2 = diagonals[idx].cells.each_with_index.map { |e, idx| e == ' ' ? idx : e }.each_cons(n_in_a_row).select { |cons| cons.count(player.mark) == (n_in_a_row - 1) && cons.count { |x| x.class == Fixnum} == 1  }[0].find { |r| r != player.mark }
          if idx == 0
            result = [((idx + 1) + (($grid_size + 1) * idx2))]
          elsif idx == 1
            result = [((idx + ($grid_size - 1) ) + (($grid_size - 1) * idx2))]
          end
          if idx == 2 && $grid_size == 5
            result = [idx + (6 * idx2)]
          elsif idx == 3 && $grid_size == 5
            result = [(idx * 2) + (6 * idx2)]
          elsif idx == 4 && $grid_size == 5
            result = [idx + (4 * idx2)]
          elsif idx == 5 && $grid_size == 5
            result = [(idx * 2) + (4 * idx2)]
          end
          if idx == 6 && $grid_size == 5
            result = [(idx - 3) + (4 * idx2)]
          elsif idx == 7 && $grid_size == 5
            result = [(idx - 4) + (6 * idx2)]
          elsif idx == 8 && $grid_size == 5
            result = [(idx + 3) + (6 * idx2)]
          elsif idx == 9 && $grid_size == 5
            result = [(idx + 6) + (4 * idx2)]
          end
        end
      end
    end
    result.flatten
  end

  def opportunity?(player, n_in_a_row)
    [rows, columns, diagonals].any? { |lines| lines.any? { |line| line.nearly_complete?(player.mark, n_in_a_row)} }
  end

  def threat?(other_players, n_in_a_row)
    other_players.any? { |player| opportunity?(player, n_in_a_row) }
  end

	def full_board?
	  [rows, columns, diagonals].map { |lines| lines.any?(&:uncomplete?) }.include?(true)
	end

	def fill_rows(move, mark)
    row, cell = @rows_coord[move - 1]
    self.rows[row].insert_mark(cell, mark)
	end

	def fill_columns(move, mark)
    col, cell = @columns_coord[move - 1]
    self.columns[col].insert_mark(cell, mark)
	end

	def fill_diagonals(move, mark)
		moves_in_diagonal1 = (1..(size * size)).step(size + 1).to_a
		moves_in_diagonal2 = (size..((size * size) - (size - 1))).step(size - 1).to_a
		if moves_in_diagonal1.include?(move)
			self.diagonals[0].insert_mark(moves_in_diagonal1.index(move), mark)
    end
		if moves_in_diagonal2.include?(move)
			self.diagonals[1].insert_mark(moves_in_diagonal2.index(move), mark)
		end
    if $grid_size == 5
      fill_sub_diagonals_grid_5(move, mark)
    elsif $grid_size == 9

    end
	end

  def fill_sub_diagonals_grid_5(move, mark)
    moves_in_diagonal3 = [2, 8, 14, 20]
    moves_in_diagonal4 = [6, 12, 18, 24]
    moves_in_diagonal5 = [4, 8, 12, 16]
    moves_in_diagonal6 = [10, 14, 18, 22]
    moves_in_diagonal7 = [3, 7, 11]
    moves_in_diagonal8 = [3, 9, 15]
    moves_in_diagonal9 = [11, 17, 23]
    moves_in_diagonal10 = [15, 19, 23]
    if moves_in_diagonal3.include?(move)
      self.diagonals[2].insert_mark(moves_in_diagonal3.index(move), mark)
    end
    if moves_in_diagonal4.include?(move)
      self.diagonals[3].insert_mark(moves_in_diagonal4.index(move), mark)
    end
    if moves_in_diagonal5.include?(move)
      self.diagonals[4].insert_mark(moves_in_diagonal5.index(move), mark)
    end
    if moves_in_diagonal6.include?(move)
      self.diagonals[5].insert_mark(moves_in_diagonal6.index(move), mark)
    end
    if nb_players == 3
      if moves_in_diagonal7.include?(move)
        self.diagonals[6].insert_mark(moves_in_diagonal7.index(move), mark)
      end
      if moves_in_diagonal8.include?(move)
        self.diagonals[7].insert_mark(moves_in_diagonal8.index(move), mark)
      end
      if moves_in_diagonal9.include?(move)
        self.diagonals[8].insert_mark(moves_in_diagonal9.index(move), mark)
      end
      if moves_in_diagonal10.include?(move)
        self.diagonals[9].insert_mark(moves_in_diagonal10.index(move), mark)
      end
    end
  end

	def fill_board(move, mark)
    self.fill_rows(move, mark)
    self.fill_columns(move, mark)
    self.fill_diagonals(move, mark)
	end

	def one_line_complete?(mark, n_in_a_row)
    all_lines = [rows, columns, diagonals].any? { |lines| lines.any? { |line| line.complete?(mark, n_in_a_row) } }
	end

	def display_rows
    to_display = []
    self.rows.reverse.each { |row| to_display << row.cells }
    to_display
	end
end

class BoardLine
	attr_accessor :cells
	attr_reader :number

  def initialize(number, type = :normal, size = $grid_size)
    @size = size
    @number = number
    if type == :normal
      @cells = Array.new(@size, ' ')
    else
      @cells = add_command_numbers_to_grid[number - 1]
    end
  end

  def add_command_numbers_to_grid
    arr_numbers = ->(size) { (0..((size ** 2) - 1))
                             .step(size)
                             .map { |n| (1..(size **2)).to_a.slice(n, size) } }
    if $grid_size == 5
      arr_numbers.call(5)
    elsif $grid_size == 9
      arr_numbers.call(9)
    end
  end

  def nearly_complete?(mark, n_in_a_row)
    self.cells.each_cons(n_in_a_row).any? { |cons| cons.count(mark) == (n_in_a_row - 1) && (cons.include?(' ') || cons.one? { |e| e.class == Fixnum }) }
  end

  def complete?(mark, n_in_a_row)
    self.cells.each_cons(n_in_a_row).any? { |cons| cons == (mark * n_in_a_row).chars }
  end

  def uncomplete?
    self.cells.any? { |cell| cell == ' ' }
  end

  def insert_mark(place, mark)
    self.cells[place] = mark
  end

  def free_cells?
    cells.any? { |cell| cell == '' }
  end

  def reset_cells
    cells.map! { |cell| cell = ''}
  end
end

class Score
	attr_accessor :state
  attr_reader :nb_players

	def initialize(number_of_players)
    @nb_players = number_of_players
    @state = Array.new(nb_players, 0)
	end

  def update_score(player_number)
    self.state[player_number - 1] += 1
  end
end

class Stats
	attr_accessor :first_moves, :rounds

  def initialize
    @rounds = 1
    @winnings = 0
    @losing = 0
    @first_moves = []
    @moves = []
  end

  def record_win
    @winnings += 1
  end

  def record_lose
    @losing += 1
  end

  def count_rounds
    @rounds += 1
  end

  def record_moves(move)
    @moves << move
  end

  def reset_rounds
    self.rounds = 1
  end
end


Game.new.play
