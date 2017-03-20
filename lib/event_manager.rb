require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  phone_number = phone_number.scan(/\d+/).join

  if phone_number.length < 10 || phone_number.length > 11 || phone_number.length == 11 && phone_number[0] != "1"
    phone_number = ""
  elsif phone_number.length == 11 && phone_number[0] == "1"
    phone_number[1..10]
  else
    phone_number
  end
end

def get_peak_hours(contents)
  hours = Hash.new(0)
  hours_sorted = []
  contents.each do |row|
    date_string = row[:regdate]
    date_hour = DateTime.strptime(date_string, "%m/%d/%Y %H:%M").hour
    hours[date_hour] += 1
  end
  hours_sorted = hours.sort_by { |hour, counter| counter }
  hours_sorted = hours_sorted[-3..-1]
  peak_hours = []
  hours_sorted.each do |ary|
    peak_hours << ary[0]
  end
  peak_hours
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, from_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts from_letter
  end
end

puts "EventManager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  puts "#{name}\t#{phone_number}"

  legislators = legislators_by_zipcode(zipcode)

  from_letter = erb_template.result(binding)

  save_thank_you_letters(id, from_letter)
end

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

peak_hours = get_peak_hours(contents)
puts "Peak hours are: #{peak_hours.join(', ')}"
