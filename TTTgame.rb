=begin
The program is based on four classes
so
=> Board that takes charge of the display; it is scalable (3x3 => 9x9)
=> VirtualBoard takes charge of the calculations in lines
=> Player deals with the players of the game
=> Score
=> Stats
=> Engine

dependencies between objects in this program
=end
require 'pry'

require 'colorize'

class BoardGame
	attr_reader :grid_size, :height_grid, :width, :heigth_box
	attr_accessor :color, :marks

	ANGLE = '+'
	BORDER = '|'

	def initialize(size, width, height_grid, heigth_box)
      @grid_size = set_grid_size
      @width = width.odd? ? (width + 1) : width
      @height_grid = height_grid
      @heigth_box = heigth_box
      @color = set_color
      @marks = []
	end

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
	  min_line = line((width - 2) / grid_size)
    inside_border = ((BORDER + min_line) * grid_size + BORDER)
    inside_border = inside_border.send(color)
    inside_line = (ANGLE + line(width - 2, '-') + ANGLE).send(color)
    part_grid = lambda { (height_grid / (grid_size * 2)).times do 
     puts inside_border
    end }
    grid_size.times do |n|
      part_grid.call
      marks.empty? ? (puts inside_border) : (puts marked_line(marks[n]))
      part_grid.call
      puts inside_line
    end
  end

  def message_line(mark)
    "#{' ' * ((width - (grid_size * 2)) / (grid_size * 2))}#{mark}#{' ' * ((width - (grid_size * 2)) / (grid_size * 2))}"
  end

  def marked_line(marks)
    result = []
    marks.each do |mark|
      result << '| '.send(color)
      mark = if mark == 'X' 
               mark.bold.green
             elsif mark == 'O'
               mark.bold.red
             elsif mark == 'V'
             	 mark.bold.cyan
             else 
             	 mark
             end
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

end

class VirtualBoard
	attr_accessor :rows, :columns, :diagonals

	def initialize(size)
    @rows = []
	  @columns = []
	  @diagonals = []
    @rows_coord = (0..size - 1).to_a.product((0..size - 1).to_a)
	  @columns_coord = @rows_coord.map(&:reverse)
    size.times do |n|
      @rows << BoardLine.new(size, n + 1)
      @columns << BoardLine.new(size, n + 1)
    end
    2.times do |n|
    	@diagonals << BoardLine.new(size, n + 1)
    end
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
    if  move == 1
      self.diagonals[0].insert_mark(0, mark)
    elsif move == 9
    	self.diagonals[0].insert_mark(2, mark)
    elsif move == 5
    	self.diagonals[0].insert_mark(1, mark)
    	self.diagonals[1].insert_mark(1, mark)
    elsif move == 3
    	self.diagonals[1].insert_mark(0, mark)
    elsif move == 7
    	self.diagonals[1].insert_mark(2, mark)
    end
	end

	def fill_board(move, mark)
    self.fill_rows(move, mark)
    self.fill_columns(move, mark)
    self.fill_diagonals(move, mark)
	end

	def one_line_complete?(mark)
    all_lines = [rows, columns, diagonals].map { |lines| lines.any? { |line| line.complete?(mark) } }
    all_lines.any? { |e| e == true }
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

  def initialize(size, number)
    @size = size
    @number = number
    @cells = Array.new(size, ' ')
  end

  def complete?(mark)
    self.cells.each_cons(2).all? { |pair| [pair.first, pair.last] == [mark, mark] }
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

class Player
  attr_reader :name, :type, :mark, :player_number
  attr_accessor :score, :stats

  MARKS = ['X', 'O', 'V']

  @@computers_names = []
  @@numb_of_players = 0

  def initialize(mark, player_number)
  	 @mark = mark
  	 @player_number = player_number
     @type = define_type_player
     @name = set_name
     @score = Score.new
     @stats = Stats.new
  end

  def self.set_numb_of_players
    puts "Is there two or three players in this game? (2/3)"
    answer = nil
    loop do
      answer = gets.chomp.to_i
      break if [2, 3].include?(answer)
      puts 'Invalid choice'.red.blink
    end
    @@numb_of_players = answer
  end

  def self.say_numb_of_players
    @@numb_of_players
  end

  def define_type_player
  	type = nil
    puts "Tell me if : "
    loop do
      puts "Player #{player_number} is : (h)uman or (c)omputer ?"
      type = gets.chomp
      if type.start_with?('h') || type.start_with?('c')
      	break
      else
      	puts 'Invalid choice'.red.blink
      end
    end
    type.start_with?('h') ? :human : :computer
  end

  def set_name
  	answer = ''
    if type == :computer
    	loop do
        answer = ['Hal 9000', 'The Maniac', 'IA', 'Robert', 'Marcel'].sample
        break unless @@computers_names.include?(answer)
      end
      @@computers_names << answer
    elsif @type == :human
      loop do 
        puts "What is the name of the player #{self.player_number} ?"
        answer = gets.chomp.capitalize
        break if answer != ''
        puts 'Please, type a correct name.'.red.blink
      end
    end
    answer
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
end

class Move
	attr_reader :type, :result

	@@choices = (1..9).to_a

  def initialize(type)
  	@type = type
  	@result = type == :human ? choose_human : choose_computer
  end

  def self.reset
    @@choices = (1..9).to_a
  end

  def self.possible?
    !@@choices.empty?
  end

  def self.left_choices
    @@choices
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
    choice = @@choices.sample
    @@choices -= [choice]
    choice
  end
end

class Score
	attr_accessor :score
	def initialize
    @score = 0
	end
  
  def update_score
    self.score += 1
  end
end

class Stats
	attr_reader :rounds
	attr_accessor :first_moves

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

  def reset_rounds
    @rounds = 0
  end

  def record_moves(move)
    @moves << move
  end
end

class Engine
  attr_reader :board, :virtual_board, :players 

  def initialize
    puts "Please, let me ask you few questions!"
    @players = []
    Player.set_numb_of_players
    (Player.say_numb_of_players).times do |n|
      @players << Player.new(Player::MARKS[n], (n + 1))
    end
    @board = BoardGame.new(9, 45, 15, 2)
    @virtual_board = VirtualBoard.new(board.grid_size)
  end

  def prompt(message)
    puts "=>#{message}"
  end

  def welcome
    board.set_marks(['T','I','C', ' ', ' '], ['T', 'A', 'C'], ['T', 'O', 'E'], ['T','I','C', ' ', ' '], ['T','I','C', ' ', ' '])
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

  def good_bye
    board.set_marks(['B','Y','E'], ['B', 'Y', 'E'], ['B', 'Y', 'E'])
    board.display('GOOD', "THAT'S ALL FOLKS!!!")
  end

  def show_commands
    board.set_marks(['7','8','9'], ['4', '5', '6'], ['1', '2', '3'])
    board.display('COMMANDS', '=>TYPE THE RIGHT NUMBER<=')
  end

  def clear_screen
    system "clear" or system "cls"
  end

  def display_intro
  	if @players.any? { |player| player.type == :human }
	    if @players.find { |player| player.type == :human }.want_view_commands?
	    	show_commands
	    	wait(3)
	    end
	  end
    clear_screen
	  welcome
	  wait(2)
	  clear_screen
  end

  def display_final
    if a_winner?
      winner = find_winner
      board.set_marks(['W', 'I', 'N'], ['W', 'I', 'N'], ['W', 'I', 'N'])
      board.display("#{winner.name}, you", ':)')
      wait(2)
    elsif !Move.possible?
    	board.set_marks(['T', 'I', 'E'], ['T', 'I', 'E'], ['T', 'I', 'E'])
      board.display("IT'S A", ':|')
      wait(1)
    end
  end

  def a_winner?
  	players.any? { |player|  virtual_board.one_line_complete?(player.mark)} 
  end

  def find_winner
    players.find { |player| virtual_board.one_line_complete?(player.mark) }
  end

  def wait(t)
    sleep(t)
  end

  def turns(*players)
    players.each do |player|
	  	break if !Move.possible?
	    board.set_marks(*virtual_board.display_rows)
      board.display("Choices : #{Move.left_choices.join(',')}", 'First you think, then you move')
      move = Move.new(player.type)
      virtual_board.fill_board(move.result, player.mark)
      wait(1) if player.type == :computer
      clear_screen
      board.set_marks(*virtual_board.display_rows)
      board.display("#{player.name} CHOSE : #{move.result}", "ROUND # #{player.stats.rounds}")
      player.stats.count_rounds
      player.stats.record_moves(move)
      break if virtual_board.one_line_complete?(player.mark)
      wait(2)
      clear_screen
    end
  end

  def play
	  display_intro
	  loop do
	  	turns(*players)
	    break if a_winner? || !Move.possible?
    end
    display_final
    wait(2)
    clear_screen
    good_bye
  end
end

game = Engine.new
game.play