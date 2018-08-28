#!/usr/bin/env ruby
require 'ruby2d'
require 'rbconfig'

l1, l2, l3 = File.open('words/1_letter_words').read.split, File.open('words/2_letter_words').read.split, File.open('words/3_letter_words').read.split
l4, l5, l6 = File.open('words/4_letter_words').read.split, File.open('words/5_letter_words').read.split, File.open('words/6_letter_words').read.split
l7, l8, l9 = File.open('words/7_letter_words').read.split, File.open('words/8_letter_words').read.split, File.open('words/9_letter_words').read.split
l10, lelse = File.open('words/10_letter_words').read.split, File.open('words/10+_letter_words').read.split
$r = { l1: l1, l2: l2, l3: l3, l4: l4, l5: l5, l6: l6, l7: l7, l8: l8, l9: l9, l10: l10, lelse: lelse }
Sound.new('sounds/electric_sweep.mp3').play

class Word
	def initialize(hash) ; @hash = hash end
	def self.word_level(leng=1)
		list = $r[:l1].sample if leng == 1
		list = $r[:l2].sample	if leng == 2
		list = $r[:l3].sample if leng == 3
		list = $r[:l4].sample if leng == 4
		list = $r[:l5].sample if leng == 5
		list = $r[:l6].sample if leng == 6
		list = $r[:l7].sample if leng == 7
		list = $r[:l8].sample if leng == 8
		list = $r[:l9].sample if leng == 9
		list = $r[:l10].sample if leng == 10
		list = $r[:lelse].sample if leng > 10
		Text.new x: rand(30..$width - 460), y: rand(-80..0), text: list, font: 'fonts/arima.otf', size: 32
	end
	def draw(speed=1, i=1) ; @hash.values.each { |object| object.y += speed ; object.x += Math.sin(i)} end
	def wordlist(hash={}) ; @hash.keys.each { |key| hash.merge! "#{key}": @hash[key].text } ; hash end
	def current_pos(word)[@hash[word].x, @hash[word].y] end
	def delete(word) ; @hash[word].opacity = 0 ;  @hash.delete(word) end
	def resolution(word) [@hash[word].width, @hash[word].height] end
	def colourize(word, colour)
		@hash[word].color = colour
		@hash[word].z = 5
	end
	def drag(x=-100, y=-100)
		@hash.keys.each do |key|
			if @hash[key].contains?(x, y) then @hash[key].color = 'black' else @hash[key].color = 'white' end
		end
	end
end

class Particles
	def initialize(hash) ; @hash = hash end
	def self.square ; Square.new x: rand(0..$width - 250) ,y: rand(0..$height - 250), size: rand(20..50), color: 'random', z: 0 end
	def draw(down=false, right=false, left=false)
		@hash.values.each do |n| if down then n.y += 1 ; else n.y -= 1 end
			n.x += 1 if right and n.x <= $width - 200
			n.x -= 1 if left and n.x <= 50
			n.opacity -=  rand(0.005..0.01)
		end
	end

	def fade(x, y) @hash.values.each do |n|
			if n.contains?(x, y)
				Sound.new('sounds/plop.mp3').play if n.opacity >= 0.1
				n.opacity = 0
			end
		end
	end
	def alpha(obj)
		obj.opacity = rand(0.2..0.5) if obj.opacity <= 0.1
	end

	def change
		@hash.values.each do |n|
			n.y=  rand(0..$height - 250) if n.y <= 0 or n.y >= $height
			n.x = rand(0..$width - 250)
			alpha(n)
		end
	end
end

class MagicParticles < Particles
	def initialize(hash) ; @hash = hash end
	def self.square(fizz=false, stars=false)
		sz, colour = rand(10..15), []
		unless fizz then magical_colours = %w(yellow white green lime silver orange)
			until colour.length == 4 do colour << magical_colours.delete(magical_colours.sample) end
		else  colour = 'white'
		end
		if stars then colour = '#ffc106' ; sz = rand(3..7) end
		Square.new x: rand(0..$width - 250) ,y: rand(0..$height - 250), size: sz, color: colour, z: -1
	end

	def pos(posx, posy, above=false)
		object = @hash.values.sample
		unless above then z = 1 else z = 2 end
		object.x, object.y, object.z = posx, posy, z
		alpha(object)
	end
end

def interactive_btn(btn, txt, btnclr=$colours.rotate[0], txtclr='white') ; btn.color, txt.color = btnclr, txtclr end
def main
	$info = File.open("data/info", 'a+')
	$info.puts "Game started #{Time.new.strftime 'on %D, at %T'}"
	started = false
	$colours = []
	available_colours, colours = %w(#3ce3b5 fuchsia orange blue green red #E58AE8 #EB65BB), []
	until colours.length == 4 do colours << available_colours.delete(available_colours.sample) end
	colours.permutation { |colour| $colours << colour }
	$width, $height = 1600, 900
		cheers = ['Awesome', 'Great Job', 'Nice!', 'Sweet', 'Amazing!', "It's Amazing!.."]
	level_details = [	"  Beginners' Level", "The Novices' Level", " The Practice Level", "    Mediocres' Level",
					" The Advance Level", "  The Adepts' Level", "The Legends' Level"]
	level, l, t = 4, '', Proc.new { |format| Time.new.strftime(format) }
	$highestscore, $highestwpm = 0, 0
	swivel, oldlevel, levelup_criteria = rand(10..15), level, rand(60..75)
	i = j = startparticles = word_typed = no_missed = inittime = score = previous_score = 0
	clear_value = chng_bg_value = level_plus_value = level_minus_value = false
	time, pressed_key, possible_word = t.call('%s'), '', ''
	chances, inittime = 9, time.to_f
	words, s, word_len, speed = {}, Word, 0, 1

	set title: "Colour::Box.Type", width: $width, height: $height, resizable: true
	bg = Quad.new x2: $width, x3: $width, y3: $height, y4: $height, color: $colours[0]
	menu = Rectangle.new width: 250, height: $height, x: $width - 250, color: $colours.sample, z: 2
	level_label = Text.new x: $width - 240, y: 170, text: 1, font: 'fonts/arima.otf', size: 22, z: 2
	score_label = Text.new x: $width - 240, y: 200, text: "Score: 0, Highest: 0", font: 'fonts/arima.otf', size: 22, z: 2
	newgame = Rectangle.new x: $width - 240, y: 20, width: 230, height: 40, color: '#3ce3b4', z: 2
	clear_t = Text.new x: newgame.x + 50, y: newgame.y - 3, text: 'New Game', font: 'fonts/arima.otf', size: 30, z: 2
	obj = Word.new(words)

	name_box = Rectangle.new x: $width - 240, y: 730, width: 230, height: 40, z: 2
	name_label = Text.new x: 1, y: 710, font: 'fonts/euler.otf', size: 20, text: 'Your Name: ', z: 2
	name_label.x = $width - name_label.width - 120

	nameline = Line.new x1: name_label.x, y1: name_box.y + 5, x2: name_label.x, y2: name_box.y + 35, z: 3, color: 'red'

	username = Text.new x: 1, y: 740, font: 'fonts/euler.otf', size: 18, text: '', color: 'green', z: 2
	username.x = $width - username.width - 230
	nameline.x1 = nameline.x2 = username.width

	level_plus = Rectangle.new x: $width - 240, y: 70, width: 110, height: 40, color: '#3ce3b4', z: 2
	level_plus_t = Text.new x: level_plus.x + 10, y: level_plus.y - 3, text: 'Level +', font: 'fonts/arima.otf', size: 30, z: 2

	level_minus = Rectangle.new x: $width - 120, y: 70, width: 110, height: 40, color: '#3ce3b4', z: 2
	level_minus_t = Text.new x: level_minus.x + 10, y: level_minus.y - 3, text: 'Level -', font: 'fonts/arima.otf', size: 30, z: 2

	chng_bg = Rectangle.new x: $width - 240, y: 120, width: 230, height: 40, color: '#3ce3b4', z: 2
	chng_bg_t = Text.new x: chng_bg.x + 40, y: chng_bg.y - 3, text: 'Background', font: 'fonts/arima.otf', size: 30, z: 2

	word_box = Rectangle.new x: $width - 240, y: 240, width: 230, height: 40, z: 2
	word = Text.new y:245, font: 'fonts/euler.otf', size: 30, text: 'Type!', z: 2
	word.x = $width - word.width - 160

	time_box = Rectangle.new x: $width - 240, y: 340, width: 230, height: 40, color: 'black', z: 2
	tm = Text.new y: 346, font: 'fonts/euler.otf', size: 30, text: "Played: 0 sec.", color: 'blue', z: 2
	tm.x = $width - tm.width - 40

	total_typed_box = Rectangle.new x: $width - 240, y: 390, width: 230, height: 40, color: 'black', z: 2
	total_typed = Text.new y: 390 + 6, font: 'fonts/euler.otf', size: 30, text: "Typed: 0", color: 'purple', z: 2
	total_typed.x = $width - total_typed.width - 115

	total_missed_box = Rectangle.new x: $width - 240, y: 440, width: 230, height: 40, color: 'black', z: 2
	total_missed = Text.new y: 440 + 6, font: 'fonts/euler.otf', size: 30, text: "Missed: 0", color: '#FF7163', z: 2
	total_missed.x = $width - total_missed.width - 95

	chances_box = Rectangle.new x: $width - 240, y: 490, width: 230, height: 40, color: 'black', z: 2
	chances_label = Text.new y: 490 + 6, font: 'fonts/euler.otf', size: 30, text: "Lives: #{chances}", color: 'green', z: 2
	chances_label.x = $width - chances_label.width - 125

	level_details_box = Rectangle.new x: $width - 240, y: 540, width: 230, height: 40, color: 'black', z: 2
	level_details_text = Text.new y: 540 + 6, font: 'fonts/DancingScript-Bold.ttf', size: 20, text: level_details[2], color: 'teal', z: 2
	level_details_text.x = $width - level_details_text.width - 50

	inittext = Text.new y: 340 + 6, font: 'fonts/DancingScript-Bold.ttf', size: 120, text: "Press Enter to Start", color: 'white', z: 2
	inittext.x = $width - inittext.width - 500

	wpm_box = Rectangle.new x: $width - 240, y: 290, width: 230, height: 40, color: 'black', z: 2
	wpm_label = Text.new y: 297 + 4, font: 'fonts/euler.otf', size: 20, text: "No Data", z: 2, color: 'yellow'
	wpm_label.x = $width - wpm_label.width - 140

	stats_box = Rectangle.new x: $width - 230, y: $height - 75, width: 100, height: 30, color: 'blue', z: 2
	stats_label = Text.new y: $height - 79, font: 'fonts/arima.otf', size: 25, text: "Stats", z: 2, color: 'white'
	stats_label.x = $width - stats_box.width - 110

	reset_box = Rectangle.new x: $width - 120, y: $height - 75, width: 100, height: 30, color: 'blue', z: 2
	reset_label = Text.new y: $height - 79, font: 'fonts/arima.otf', size: 25, text: "Reset", z: 2, color: 'white'
	reset_label.x = $width - reset_box.width - 0

	about_box = Rectangle.new x: $width - 230, y: $height - 35, width: 100, height: 30, color: 'blue', z: 2
	about_label = Text.new x: about_box.x, y: $height - 39, font: 'fonts/arima.otf', size: 25, text: "About", z: 2, color: 'white'
	about_label.x = $width - about_box.width - 110

	exit_box = Rectangle.new x: $width - 120, y: $height - 35, width: 100, height: 30, color: 'blue', z: 2
	exit_label = Text.new x: exit_box.x, y: $height - 40, font: 'fonts/arima.otf', size: 25, text: "Exit", z: 2
	exit_label.x = $width - exit_box.width + 10

	cheer = Text.new x: 1, y: 297 + 2, font: 'fonts/euler.otf', size: 25, text: "Test Your Typing Speed", z: 2
	cheer.x = $width/2 - cheer.width

	wordwrap_x1 = Line.new width: 2, color: 'yellow', z: 2
	wordwrap_x2 = Line.new width: 2, color: 'yellow', z: 2
	wordwrap_y1 = Line.new width: 2, color: 'yellow', z: 2
	wordwrap_y2 = Line.new width: 2, color: 'yellow', z: 2

	wordwrap_x1.opacity = wordwrap_x2.opacity = wordwrap_y1.opacity = wordwrap_y2.opacity = 0

	Line.new x1: $width - 250, y1: 0, x2: $width - 250, y2: $height, z: 3
	Line.new x1: $width, y1: 170, x2: $width - 250, y2: 170, z: 3, width: 2
	Line.new x1: $width, y1: 0, x2: $width - 250, y2: 0, z: 3, width: 4
	Line.new x1: $width - 10, y1: 240, x2: $width - 240, y2: 240, z: 3, width: 2, color: 'random'
	Line.new x1: $width - 10, y1: 280, x2: $width - 240, y2: 280, z: 3, width: 2, color: 'random'
	Line.new x1: $width - 10, y1: 240, x2: $width - 10, y2: 280, z: 3, width: 2, color: 'random'
	Line.new x1: $width - 240, y1: 240, x2: $width - 240, y2: 280, z: 3, width: 2, color: 'random'
	Line.new x1: $width - 240, y1: 600, x2: $width - 240, y2: 700, z: 3
	Line.new x1: $width - 10, y1: 600, x2: $width - 10, y2: 700, z: 3
	Line.new x1: $width - 240, y1: 600, x2: $width - 10, y2: 600, z: 3
	Line.new x1: $width - 240, y1: 700, x2: $width - 10, y2: 700, z: 3

	Text.new x: $width - 160, y: 670, z: 3, font: 'fonts/arima.otf', text: 'Status', size: 22

	pressed = [Sound.new('sounds/k1.mp3'), Sound.new('sounds/k2.mp3'), Sound.new('sounds/k3.mp3')]
	missed = [Sound.new('sounds/bleep.mp3'), Sound.new('sounds/beep.mp3')]
	correct = Sound.new('sounds/robot_blip.mp3')
	buttonpressed = Sound.new('sounds/button.wav')
	levelup = Sound.new('sounds/levelup.mp3')
	exit_sound = Sound.new('sounds/exit.mp3')
	plop = Sound.new('sounds/plop.mp3')

	img = Image.new path: 'images/star.png', width: 50, height: 50, z: 2
	img2 = Image.new path: 'images/star1.png', width: 50, height: 50, z: 2
	img3 = Image.new path: 'images/starblob.png', width: 50, height: 50, z: 2
	happy = Image.new path: 'images/emptyface.png', x: $width - 160, y: 610, width: 60, height: 54, z: 2
	stareye = Image.new path: 'images/starryeyes.png', x: $width - 160, y: 610, width: 60, height: 54, z: 2
	stareye.opacity = 0
	happycurve = Image.new path: 'images/happycurve.png', x: $width - 160, y: 618, width: 60, height: 54, z: 2
	sadcurve = Image.new path: 'images/sadcurve.png', x: $width - 160, y: 618, width: 60, height: 54, z: 2
	sadcurve.opacity = 0

	img.opacity, img2.opacity, img3.opacity = 0, 0, 0

	h0, h1, h2, h3, h4, h5, h6, h7, h8, h9, h10, h11, h12, h13, sq = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, Particles

	for i in 1..rand(10..15) do
		h0.merge! "#{i}": sq.square ; h1.merge! "#{i}": sq.square ; h2.merge! "#{i}": sq.square ; h3.merge! "#{i}": sq.square
	end
	obj0, obj1, obj2, obj3 = Particles.new(h0), Particles.new(h1), Particles.new(h2), Particles.new(h3)

	sq = MagicParticles
	for i in 1..10
		h4.merge! "#{i}": sq.square ; h5.merge! "#{i}": sq.square ; h6.merge! "#{i}": sq.square
		h7.merge! "#{i}": sq.square(true) ; h8.merge! "#{i}": sq.square(true) ; h9.merge! "#{i}": sq.square(true)
		h10.merge! "#{i}": sq.square(true, true) ; h11.merge! "#{i}": sq.square(true, true) ; h12.merge! "#{i}": sq.square(true, true)
		h13.merge! "#{i}": sq.square(true, true)
	end
	obj4, obj5, obj6 = sq.new(h4), sq.new(h5), sq.new(h6)
	obj7, obj8, obj9 = sq.new(h7), sq.new(h8), sq.new(h9)
	obj10, obj11, obj12, obj13 = sq.new(h10), sq.new(h11), sq.new(h12), sq.new(h13)

	on :key_down do |k|
		if (k.key == 'return' or k.key == 'keypad enter' and !username.text.empty?) and !started
			started, inittime, word_typed = true, t.call('%s').to_f, 0
			cheer.x = $width/2 - 150
			inittext.opacity, inittext.x, inittext.y = 1, $width/2 - 260, $height/2 - inittext.height
			inittext.text, cheer.text = 'Begin!', 'Superb!'
			no_missed, score, chances, pressed_key = 0, 0, 9, ''
			buttonpressed.play
			obj.wordlist.keys.each { |key| obj.delete(key) }
			$info.puts("\tNew Game at #{Time.new.strftime('%T')}")
			$info.puts "\tPlayer: #{username.text}"
		elsif !started
			username.text += k.key if k.key.length == 1 and username.width < name_box.width - 15
			username.text += ' ' if k.key == 'space'
			username.text = '' if k.key == 'delete' or k.key == 'escape'
			username.text = username.text[0...username.text.length - 1] if k.key == 'backspace'
			nameline.x1, nameline.x2 = username.width + username.x + 2, username.width + username.x + 2
			name_label.text = 'Edit Name: '
		else
			if k.key == 'backspace' then word_box.color = 'blue' ; word.color = 'white' end
			pressed_key += k.key.match(/^[a-z.A-Z]+$/).to_s if k.key.length == 1 and pressed_key.length <= 12
			pressed_key = pressed_key[0...pressed_key.length - 1] if k.key == 'backspace'
			pressed_key = '' if k.key == 'escape' or k.key == 'delete'
		end
		pressed[0].play unless k.key == 'space' and k.key == 'return'
		pressed[1].play if k.key == 'space'
		pressed[2].play if k.key == 'return'
		word_list = obj.wordlist
		word_list.keys.each do |key|
			obj.colourize(key, 'white')
			if word_list[key] == pressed_key
				score += pressed_key.length
				word_typed += 1
				$highestscore = score if score > $highestscore
				word_len, pressed_key, word_box.color = word_list[key].length, '', 'yellow'
				x, y = obj.current_pos(key)[0] + 20, obj.current_pos(key)[1]+20
				img.opacity = img2.opacity = img3.opacity = 1
				img.x = img2.x = img3.x = x - 20
				img.y = img2.y = img3.y = y - 20
				obj.delete(key)
				correct.play
				stareye.opacity = 1
				if score >= previous_score + levelup_criteria
					if !(level >= 11 or level == 1 or level == 2 or level == 3)
						level += 1
						chances += 3
						oldlevel, previous_score = level, score
						levelup.play
						cheer.x, cheer.y = $width/2 - 180, $height - 200
						cheer.text, cheer.opacity = cheers.sample, 1
						inittext.y, inittext.x = $height/2 - 100, $width/2 - 400
						inittext.text, inittext.opacity = "Level Up: #{level}", 1
					elsif level == 11
						previous_score = score
						chances += 6
						cheer.x, cheer.y = $width/2 - 300, $height - 200
						inittext.x, inittext.y = $width/2 - 300, $height/2 - 100
						cheer.text, cheer.opacity = "The Last Infinite Level! You Rocked!", 1
						inittext.text, inittext.opacity = "Great Job!", 1
					elsif level == 1 or level == 2 or level == 3
						cheer.x, cheer.y = $width/2 - 250, $height - 200
						cheer.text, cheer.opacity = "The Practice Level Never Ends ;)", 1
						previous_score = score
						chances += 1
					end
					chances_label.text = "Lives: #{chances}"
					levelup_criteria += 45
				end
				rand(10..15).times do
					obj7.pos(rand(0..$width - 265), rand($height - 100..$height))
					obj8.pos(rand(0..$width - 265), rand($height - 200..$height - 100))
					obj9.pos(rand(0..$width - 265), rand($height - 300..$height - 200))
					obj10.pos(rand(x - 30..x + 30), rand(y - 30..y + 30))
					obj11.pos(rand(x - 30..x + 30), rand(y - 30..y + 30))
					obj12.pos(rand(x - 30..x + 30), rand(y - 30..y + 30))
					obj13.pos(rand(x - 30..x + 30), rand(y - 30..y + 30))
				end
			end
		end
	end

	on :mouse_move do |e|
		obj.drag(e.x, e.y)
		obj0.fade(e.x, e.y) ; obj1.fade(e.x, e.y) ; obj2.fade(e.x, e.y) ; obj3.fade(e.x, e.y)
		obj4.pos(e.x, e.y, true) ; obj5.pos(e.x, e.y, true) ; obj6.pos(e.x, e.y, true)

		if e.x >= newgame.x  and e.x <= newgame.width + newgame.x and e.y >= newgame.y and e.y <= newgame.height + newgame.y then interactive_btn(newgame, clear_t, 'blue', 'white')
		else interactive_btn(newgame, clear_t, '#3ce3b4')  end

		if e.x >= chng_bg.x  and e.x <= chng_bg.width + chng_bg.x and e.y >= chng_bg.y and e.y <= chng_bg.height + chng_bg.y then interactive_btn(chng_bg, chng_bg_t, 'blue', 'white')
		else interactive_btn(chng_bg, chng_bg_t, '#3ce3b4') end

		if e.x >= level_plus.x  and e.x <= level_plus.width + level_plus.x and e.y >= level_plus.y and e.y <= level_plus.height + level_plus.y then interactive_btn(level_plus, level_plus_t, 'blue', 'white')
		else interactive_btn(level_plus, level_plus_t, '#3ce3b4') end

		if e.x >= level_minus.x  and e.x <= level_minus.width + level_minus.x and e.y >= level_minus.y and e.y <= level_minus.height + level_minus.y then interactive_btn(level_minus, level_minus_t, 'blue', 'white')
		else interactive_btn(level_minus, level_minus_t, '#3ce3b4') end

		if e.x >= word_box.x and e.x <= word_box.width + word_box.x and e.y >= word_box.y and e.y <= word_box.height + word_box.y then interactive_btn(word_box, word, 'yellow', 'white')
		else interactive_btn(word_box, word, 'white', 'red') end

		if e.x >= name_box.x and e.x <= name_box.width + name_box.x and e.y >= name_box.y and e.y <= name_box.height + name_box.y
			interactive_btn(name_box, nameline, 'black', 'green')
			interactive_btn(name_box, username, 'black', 'green')
		elsif !started
			interactive_btn(name_box, nameline, 'white', 'green')
			interactive_btn(name_box, username, 'white', 'green')
		end

		if e.x >= stats_box.x and e.x <= stats_box.width + stats_box.x and e.y >= stats_box.y and e.y <= stats_box.height + stats_box.y then interactive_btn(stats_box, stats_label, 'fuchsia', 'white')
		else interactive_btn(stats_box, stats_label, 'blue') end

		if e.x >= reset_box.x and e.x <= reset_box.width + reset_box.x and e.y >= reset_box.y and e.y <= reset_box.height + reset_box.y then interactive_btn(reset_box, reset_label, 'fuchsia', 'white')
		else interactive_btn(reset_box, reset_label, 'blue') end

		if e.x >= exit_box.x and e.x <= exit_box.width + exit_box.x and e.y >= exit_box.y and e.y <= exit_box.height + exit_box.y then interactive_btn(exit_box, exit_label, 'red', 'white')
		else interactive_btn(exit_box, exit_label, 'blue') end

		if e.x >= about_box.x and e.x <= about_box.width + about_box.x and e.y >= about_box.y and e.y <= about_box.height + about_box.y then interactive_btn(about_box, about_label, 'red', 'white')
		else interactive_btn(about_box, about_label, 'blue') end

		if e.x >= wpm_box.x  and e.x <= wpm_box.width + wpm_box.x and e.y >= wpm_box.y and e.y <= wpm_box.height + wpm_box.y then interactive_btn(wpm_box, wpm_label, 'yellow', 'white')
		else interactive_btn(wpm_box, wpm_label, 'black', 'yellow')  end

		if e.x >= time_box.x  and e.x <= time_box.width + time_box.x and e.y >= time_box.y and e.y <= time_box.height + time_box.y then interactive_btn(time_box, tm, 'blue', 'white')
		else interactive_btn(time_box, tm, 'black', 'blue')  end

		if e.x >= total_typed_box.x  and e.x <= total_typed_box.width + total_typed_box.x and e.y >= total_typed_box.y and e.y <= total_typed_box.height + total_typed_box.y then interactive_btn(total_typed_box, total_typed, 'purple', 'white')
		else interactive_btn(total_typed_box, total_typed, 'black', 'purple')  end

		if e.x >= total_missed_box.x  and e.x <= total_missed_box.width + total_missed_box.x and e.y >= total_missed_box.y and e.y <= total_missed_box.height + total_missed_box.y then interactive_btn(total_missed_box, total_missed, '#FF7163', 'white')
		else interactive_btn(total_missed_box, total_missed, 'black', '#FF7163')  end

		if e.x >= chances_box.x  and e.x <= chances_box.width + chances_box.x and e.y >= chances_box.y and e.y <= chances_box.height + chances_box.y then interactive_btn(chances_box, chances_label, 'green', 'white')
		else interactive_btn(chances_box, chances_label, 'black', 'green')  end

		if e.x >= level_details_box.x  and e.x <= level_details_box.width + level_details_box.x and e.y >= level_details_box.y and e.y <= level_details_box.height + level_details_box.y then interactive_btn(level_details_box, level_details_text, 'teal', 'white')
		else interactive_btn(level_details_box, level_details_text, 'black', 'teal')  end
	end

	on :mouse_down do |e|
		obj4.pos(e.x, e.y) ; obj5.pos(e.x, e.y) ; obj6.pos(e.x, e.y)
		obj0.fade(e.x, e.y) ; obj1.fade(e.x, e.y) ; obj2.fade(e.x, e.y) ; obj3.fade(e.x, e.y)
		if (e.x >= newgame.x  and e.x <= newgame.width + newgame.x and e.y >= newgame.y and e.y <= newgame.height + newgame.y) and !username.text.empty?
			interactive_btn(newgame, clear_t, $colours.rotate[0], 'white')
			started = true
			inittext.text, inittext.opacity, inittext.y = 'Lets Begin!', 1, inittext.y = $height/2 - inittext.height
			inittext.x = $width - inittext.width - 680
			inittime = t.call('%s').to_f
			clear_value, no_missed, score, pressed_key, cheer.text = true, 0, 0, '', "Good Luck!"
			chances, word_typed = 9, 0
			buttonpressed.play
			$info.puts("\tNew Game at #{Time.new.strftime('%T')}")
			$info.puts "\tPlayer: #{username.text}"
			obj.wordlist.keys.each { |key| obj.delete(key) }
			10.times {
				obj7.pos(rand(0..$width - 265), rand($height - 100..$height))
				obj8.pos(rand(0..$width - 265), rand($height - 200..$height))
				obj9.pos(rand(0..$width - 265), rand($height - 300..$height - 100)) }
		elsif e.x >= chng_bg.x  and e.x <= chng_bg.width + chng_bg.x and e.y >= chng_bg.y and e.y <= chng_bg.height + chng_bg.y
			available_colours, colours, $colours = %w(#3ce3b5 fuchsia orange blue green red yellow #E58AE8 #EB65BB), [], []
			until colours.length == 4 do colours << available_colours.delete(available_colours.sample) end
			colours.permutation { |colour| $colours << colour }
			chng_bg_value = true
			buttonpressed.play
		elsif e.x >= level_plus.x  and e.x <= level_plus.width + level_plus.x and e.y >= level_plus.y and e.y <= level_plus.height + level_plus.y
			interactive_btn(level_plus, level_plus_t)
			level += 1 if level < 11
			oldlevel, level_plus_value = level, true
			buttonpressed.play
		elsif e.x >= level_minus.x  and e.x <= level_minus.width + level_minus.x and e.y >= level_minus.y and e.y <= level_minus.height + level_minus.y
			interactive_btn(level_minus, level_minus_t)
			level -= 1 if level > 1
			oldlevel, level_minus_value = level, true
			buttonpressed.play
		elsif e.x >= level_details_box.x  and e.x <= level_details_box.width + level_details_box.x and e.y >= level_details_box.y and e.y <= level_details_box.height + level_details_box.y
			interactive_btn(level_details_box, level_details_text)
		 	level += 1 if level <= 11
			level = 1 if level > 11
		elsif e.x >= stats_box.x and e.x <= stats_box.width + stats_box.x and e.y >= stats_box.y and e.y <= stats_box.height + stats_box.y
			interactive_btn(stats_box, stats_label)
			system('xdg-open', 'data/info')
			plop.play
		elsif e.x >= reset_box.x and e.x <= reset_box.width + reset_box.x and e.y >= reset_box.y and e.y <= reset_box.height + reset_box.y
			interactive_btn(reset_box, reset_label)
			plop.play
		elsif e.x >= exit_box.x and e.x <= exit_box.width + exit_box.x and e.y >= exit_box.y and e.y <= exit_box.height + exit_box.x
			interactive_btn(exit_box, exit_label)
			exit_sound.play
		elsif e.x >= about_box.x and e.x <= about_box.width + about_box.x and e.y >= about_box.y and e.y <= about_box.height + exit_box.x
			interactive_btn(about_box, about_label)
			exit_sound.play
			system('xdg-open', 'data/about.png') if RbConfig::CONFIG['host_os'] == "linux-gnu"
			system('open', 'data/about.png') if RbConfig::CONFIG['host_os'] == "darwin"
		else
			$colours.rotate!
		end
	end

	on :mouse_up do |e|
		if e.x >= newgame.x  and e.x <= newgame.width + newgame.x and e.y >= newgame.y and e.y <= newgame.height + newgame.y
			interactive_btn(newgame, clear_t, 'blue', 'white') ; clear_value = false
		elsif e.x >= chng_bg.x  and e.x <= chng_bg.width + chng_bg.x and e.y >= chng_bg.y and e.y <= chng_bg.height + chng_bg.y
			interactive_btn(chng_bg, chng_bg_t, 'blue', 'white') ; chng_bg_value = false
		elsif e.x >= level_plus.x  and e.x <= level_plus.width + level_plus.x and e.y >= level_plus.y and e.y <= level_plus.height + level_plus.y
			interactive_btn(level_plus, level_plus_t, 'blue', 'white') ; level_plus_value = false
		elsif e.x >= level_minus.x  and e.x <= level_minus.width + level_minus.x and e.y >= level_minus.y and e.y <= level_minus.height + level_minus.y
			interactive_btn(level_minus, level_minus_t, 'blue', 'white') ; level_minus_value = false
		elsif e.x >= exit_box.x and e.x <= exit_box.width + exit_box.x and e.y >= exit_box.y and e.y <= exit_box.height + exit_box.x
			interactive_btn(exit_box, exit_label, $colours.rotate[0], 'white') ; close
		elsif e.x >= reset_box.x and e.x <= reset_box.width + reset_box.x and e.y >= reset_box.y and e.y <= reset_box.height + reset_box.y
			interactive_btn(reset_box, reset_label, $colours.rotate[0], 'white')
			plop.play
			$info.truncate(0)
			exit 0
		end
	end

	on :mouse_scroll do |e|
		$colours.rotate!(-1) if e.delta_y == -1
		$colours.rotate!(1) if e.delta_y == 1
		menu.color = $colours[0]
	end

	update do
		i += 1
		img2.opacity -= 0.05 unless img2.opacity <= 0
		img.opacity -= 0.07 unless img.opacity <= 0
		img3.opacity -= 0.09 unless img3.opacity <= 0
		happycurve.opacity -= 0.05 if chances < 5 and happycurve.opacity >= 0
		sadcurve.opacity += 0.05 if chances < 5 and sadcurve.opacity <= 1
		happycurve.opacity += 0.05 if chances >= 5 and happycurve.opacity <= 1
		sadcurve.opacity -= 0.05 if chances >= 5 and sadcurve.opacity >= 0
		stareye.opacity -= 0.015 if stareye.opacity >= 0

		newgame.opacity -= 0.07 if newgame.opacity >= 0 and clear_value
		chng_bg.opacity -= 0.07 if chng_bg.opacity >= 0 and chng_bg_value
		level_plus.opacity -= 0.07 if level_plus.opacity >= 0 and level_plus_value
		level_minus.opacity -= 0.07 if level_minus.opacity >= 0 and level_minus_value
		wordwrap_x1.opacity -= 0.2 if wordwrap_x1.opacity >= 0
		wordwrap_x2.opacity -= 0.2 if wordwrap_x2.opacity >= 0
		wordwrap_y1.opacity -= 0.2 if wordwrap_x1.opacity >= 0
		wordwrap_y2.opacity -= 0.2 if wordwrap_x2.opacity >= 0

		bg.color = $colours[0]

		word.text = pressed_key
		wpm = (60 * word_typed)/(time.to_f-inittime).to_i unless score <= 0
		if wpm then $highestwpm = wpm.to_i if wpm > $highestwpm end

		level_label.text, score_label.text = "Level: #{level}", "Score: #{score}, Highest: #{$highestscore}"
		wpm_label.text = "WPM: #{wpm.to_i}, Highest: #{$highestwpm}"
		chances_label.text = "Lives: #{chances}"
		total_typed.text = "Typed: #{word_typed}"
		total_missed.text = "Missed: #{no_missed}"

		level_details_text.text = level_details[0] if level == 1
 		level_details_text.text = level_details[1] if level == 2
		level_details_text.text = level_details[2] if level == 3
		level_details_text.text = level_details[3] if level == 4 or level == 5
		level_details_text.text = level_details[4] if level == 6 or level == 7
		level_details_text.text = level_details[5] if level == 8 or level == 9
		level_details_text.text = level_details[6] if level == 10 or level == 11

		obj.draw(speed, i/swivel)
		obj0.draw(true, false, true)
		obj1.draw ; obj2.draw(true) ; obj3.draw(false, true)
		obj4.draw ; obj5.draw(true, true) ; obj6.draw(true, false, true)
		obj7.draw ; obj8.draw ; obj9.draw
		obj10.draw ; obj11.draw(true) ; obj12.draw(false, false, true)
		obj13.draw(false, true)

		if !started and !(j >= $width - 250)
				startparticles += 1
				j += 13
				obj7.pos(j, (Math.tan(startparticles) * 200) + 400)
				obj8.pos(j, Math.tan(startparticles) * 200 + 400)
				obj9.pos(j, Math.tan(startparticles) * 200 + 400)
				obj10.pos(j, Math.sin(startparticles) * 200 + 400)
				obj11.pos(j, Math.sin(startparticles) * 200 + 400)
				obj12.pos(j, Math.sin(startparticles) * 200 + 400)
		elsif !started
			username.color = 'green'
			name_box.opacity += 0.01 if name_box.opacity <= 1
			obj7.pos(rand(0..$width - 260), rand($height - 100..$height))
			obj8.pos(rand(0..$width - 260), rand($height - 200..$height - 100))
			obj9.pos(rand(0..$width - 260), rand($height - 300..$height - 200))
			if t.call('%s')[-1].to_i % 2 == 0 then nameline.opacity += 0.1 if nameline.opacity <= 1 else nameline.opacity -=0.1 if nameline.opacity >= 0 end
		else
			name_box.opacity -= 0.02 if name_box.opacity >= 0
			username.color = 'white'
			name_label.text = 'User: '
			nameline.opacity = 0
			word_length = rand(1..2) if level == 1
			word_length = rand(1..3) if level == 2
			word_length = rand(1..4) if level == 3
			word_length = rand(1..6) if level == 4 or level == 5
			word_length = rand(2..6) if level == 6 or level == 7
			word_length = rand(3..7) if level == 8 or level == 9
			word_length = rand(2..10) if level == 10
			word_length = rand(2..12) if level == 11

			speed += 0.0001
			inittext.opacity -= 0.01 unless inittext.opacity <= 0
			cheer.opacity -= 0.01 unless cheer.opacity <= 0
			inittext.y += 1 unless inittext.y <= 0
			cheer.y -= 1 unless cheer.y <= 0

			if time.next == t.call('%s')
				obj.drag if time.to_i % 2 == 0
				tm.text = ("Played: #{t.call('%s').to_i - inittime.to_i} sec.")
				possible_word = s.word_level(word_length)		# get a random Text object
				words.values.each { |val|
					while val.text.start_with?(possible_word.text) or possible_word.text.start_with?(val.text)
						possible_word.remove
						possible_word = s.word_level(word_length)
					end
				}
				words.merge! "w#{i}": possible_word
				if level < 4
					if (t.call('%s').to_i - inittime) >= 60
						possible_word = s.word_level(word_length)
						words.values.each { |val|
							while val.text.start_with?(possible_word.text) or possible_word.text.start_with?(val.text)
								possible_word.remove
								possible_word = s.word_level(word_length)
							end
						}
						words.merge! "w#{i + 1}": possible_word
					end

					if (t.call('%s').to_i - inittime) >= 150
						possible_word = s.word_level(word_length)
						words.values.each { |val|
							while val.text.start_with?(possible_word.text) or possible_word.text.start_with?(val.text)
								possible_word.remove
								possible_word = s.word_level(word_length)
							end
						}
						words.merge! "w#{i + 2}": possible_word
					end
				end
				word.color, word_box.color = 'red', 'white'
				obj0.change ; obj1.change
				obj2.change if time.to_i % 2 == 0 ; obj3.change if time.to_i % 3 == 0
			end
			word_list = obj.wordlist
			obj.wordlist.each do |key, val|
				unless word_list[key].start_with?(pressed_key) and !pressed_key.empty?
					obj.colourize(key, ['white', 'red'].sample) if obj.current_pos(key)[1] >= $height - 80 end
				if word_list[key].start_with?(pressed_key) and !pressed_key.empty?
					wordwrap_x1.opacity = wordwrap_x2.opacity = wordwrap_y1.opacity = wordwrap_y2.opacity = 1

					wordwrap_x1.x1, wordwrap_x1.x2 = obj.current_pos(key)[0] - 5, obj.current_pos(key)[0] + obj.resolution(key)[0] + 5
					wordwrap_x1.y1, wordwrap_x1.y2 = obj.current_pos(key)[1] + 5, obj.current_pos(key)[1] + 5

					wordwrap_x2.x1, wordwrap_x2.x2  = obj.current_pos(key)[0] - 5, obj.resolution(key)[0] + obj.current_pos(key)[0] + 5
					wordwrap_x2.y1, wordwrap_x2.y2 = obj.current_pos(key)[1] + obj.resolution(key)[1] - 5, obj.current_pos(key)[1] + obj.resolution(key)[1] - 5

					wordwrap_y1.x1, wordwrap_y1.x2 = obj.current_pos(key)[0] - 5, obj.current_pos(key)[0] - 5
					wordwrap_y1.y1, wordwrap_y1.y2 = obj.current_pos(key)[1] + 4, obj.current_pos(key)[1] + obj.resolution(key)[1] - 4

					wordwrap_y2.x1, wordwrap_y2.x2 = obj.current_pos(key)[0] + obj.resolution(key)[0] + 5, obj.current_pos(key)[0] + obj.resolution(key)[0] + 5
					wordwrap_y2.y1, wordwrap_y2.y2 = obj.current_pos(key)[1] + 4, obj.current_pos(key)[1] + obj.resolution(key)[1] - 4

					obj.colourize(key, '#FFC106')
				end
				if obj and obj.current_pos(key)[1] >= $height
					pressed_key = '' if  obj.wordlist[key].start_with?(pressed_key) and !(pressed_key.empty?)
					score -= 1 unless score <= 0
					missed.sample.play
					obj.delete(key)
					no_missed += 1
					chances -= 1
					cheer.x, cheer.y, cheer.opacity = $width/2 - 200, $height - 200, 1

					cheer.text = "#{chances} chances left."
					if chances <= 0
						inittext.x, inittext.y, inittext.opacity = $width/2 - 350, $height/2 - 100, 1
						inittext.text = "Game Over"
						cheer.x, cheer.y, cheer.opacity = $width/2 - 250, $height - 200, 1
						startparticles, j, cheer.text, started = 0, 0, "Score: #{score}, WPM: #{wpm.to_i} at Level: #{level}", false
					end
	 			end
			end
			time = t.call('%s')
		end
	end
end
main
show
$info.puts("\tHighest Score: #{$highestscore}")
$info.puts("\tHighest WPM: #{$highestwpm}")
$info.puts("Game Exited #{Time.new.strftime('on %D, at %T')}\n\n")
