#!/usr/bin/ruby


require 'csv'
require './round_half_even'
require 'xmlsimple'


FILE_TRANS = "TRANS.csv"
FILE_RATES = "RATES.xml"
FILE_OUTPUT = "OUTPUT.txt"

def get_rates
  # create a conversion hash of each currency to USD
  xml_hash = XmlSimple.xml_in(FILE_RATES)
  xml_array = xml_hash["rate"]

  # build the Hash  with empty rates
  rates_to_usd = Hash.new
  xml_array.each do |i|
    rates_to_usd[i["from"].to_s.tr('^A-Za-z', '')] = 0
    rates_to_usd[i["to"].to_s.tr('^A-Za-z', '')] = 0
  end

  # search for conversions to USD
  to_usd = xml_hash["rate"].select{|k| k["to"] == ["USD"]}

  # create a new array to build to
  # rates_to_usd[currency] = conversion_to_usd
  currency = to_usd.find{|k| k["to"] == ["USD"]}["from"].to_s.tr('^A-Za-z', '')
  conversion = to_usd.find{|k| k["to"] == ["USD"]}["conversion"].to_s.tr('^0-9.', '').to_f
  rates_to_usd[currency] = conversion

  # add the USD to USD conversion
  rates_to_usd["USD"] = 1

  # search for empty rates
  rates_to_usd.select{|key, hash| hash == 0 }.each do |key,value|
    rate_array = xml_hash["rate"].select{|k| k["from"] == [key]}
    rate_array.each do |i|
      from = i["from"].to_s.tr('^A-Za-z', '')
      to   = i["to"].to_s.tr('^A-Za-z', '') 
      conversion = i["conversion"].to_s.tr('^0-9.', '').to_f
      # find "to" conversion to USD
      if rates_to_usd[to] > 0 && !rates_to_usd[to].nil? 
        rates_to_usd[from] = conversion * rates_to_usd[to]
      end  
    end
  end
  
  return rates_to_usd
end

def get_total(file_name, item)
  rates_hash = get_rates
  total_amount = 0.0
  
  CSV.foreach(File.path(file_name), :headers => true, :header_converters => :symbol, :converters => :all) do |row|
    row[2] = row[2].split
    currency = row[2][1]
    amount = row[2][0].to_f
    
    if row[1] == item
      total_amount = total_amount + amount * rates_hash[currency]
      total_amount = total_amount.round_half_even
    end
  end
  File.open(FILE_OUTPUT, 'w') { |file| file.write(total_amount) }
  return total_amount.round_half_even
end

puts "Enter an item: "
item = gets.chomp
puts data = get_total(FILE_TRANS, item)
