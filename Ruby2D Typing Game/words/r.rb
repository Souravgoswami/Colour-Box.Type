#!/usr/bin/env ruby

file = File.open("british", 'r').read.split
var = []

file.each do |word|
	var << word if word.match(/^[a-z]+$/)
end

w1 = File.open("1_letter_words", 'w')
w2 = File.open("2_letter_words", 'w')
w3 = File.open("3_letter_words", 'w')
w4 = File.open("4_letter_words", 'w')
w5 = File.open("5_letter_words", 'w')
w6 = File.open("6_letter_words", 'w')
w7 = File.open("7_letter_words", 'w')
w8 = File.open("8_letter_words", 'w')
w9 = File.open("9_letter_words", 'w')
w10 = File.open("10_letter_words", 'w')
welse = File.open("10+_letter_words", 'w')

var.each do |word|
	w1.puts word if word.length == 1
	w2.puts word if word.length == 2
	w3.puts word if word.length == 3
	w4.puts word if word.length == 4
        w5.puts word if word.length == 5
        w6.puts word if word.length == 6
        w7.puts word if word.length == 7
        w8.puts word if word.length == 8
        w9.puts word if word.length == 9
        w10.puts word if word.length == 10
	welse.puts word if word.length > 10
end
