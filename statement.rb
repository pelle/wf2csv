require 'pdf_parser'

class Statement
  attr_accessor :statement_end_date, :account_number, :ending_balance, :starting_balance, :total_deposits, :total_withdrawals, :deposits, :withdrawals,:content
  
  MONTHS="(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)"
  DAY="[0123]\\d"
  DATE="(#{MONTHS}\s+#{DAY})"
  AMOUNT="((- )?(\\d{1,3},)?\\d{1,3}\\.\\d{2}) "
  
#  AMOUNT="\s{5}((- )?[0123456789,]+\.[0123456789]{2})"
  
  def initialize(file_name)
    @content=PdfParser.new(file_name).content
    File.open("#{file_name}.txt",'w') {|f| f<<@content }
    @year="20"+statement_end_date.split(/\//).last
    File.open("#{file_name}.csv",'w') do |f|
      all.each do |x|
        f.puts x.join(",")
      end
    end
    unless audit?
      puts "AUDIT file #{file_name}" 
      [:statement_end_date, :account_number, :starting_balance,:ending_balance, :calculated_ending_balance,  :total_deposits, :calculated_total_deposits, :total_withdrawals, :calculated_total_withdrawals].each do |field|
        puts "#{field.to_s}=#{self.send(field)}"
      end
      puts "#{calculated_ending_balance-ending_balance} missing"
    end
  end
  
  def statement_end_date
    @statement_end_date||=find_value(/Statement End Date:\s*(\d\d\/\d\d\/\d\d)/)[0]
  end

  def starting_balance
    @starting_balance||=to_number(find_value(/#{DATE} BEGINNING BALANCE\s*#{AMOUNT}/)[2])
  end

  def ending_balance
    @ending_balance||=to_number( find_value(/#{DATE} ENDING BALANCE\s*#{AMOUNT}/)[2])
  end

  def account_number
    @account_number||=find_value(/Account Number:\s*(\d+-?\d+)/)[0]
  end
  
  def total_deposits
    @total_deposits||=to_number(find_value(/TOTAL DEPOSITS\/CREDITS\s*#{AMOUNT}/)[0])
  end
  
  def total_withdrawals
    @total_withdrawals||=to_number(find_value(/TOTAL WITHDRAWALS\/DEBITS\s*#{AMOUNT}/)[0])
  end
  
  
  def calculated_total_deposits
    calculate_balance(deposits)
  end
  
  def calculated_total_withdrawals
    calculate_balance(withdrawals)
  end
  
  def turnover
    calculated_total_deposits+calculated_total_withdrawals
  end
  
  def calculated_ending_balance
     truncate(starting_balance+turnover)
  end
  
  def audit?
    calculated_ending_balance===ending_balance
  end

  def calculate_balance(txns)
    balance=txns.inject(0) do |balance,txn|
      balance+=txn[2]
      balance
    end
    truncate(balance)
  end
  
  def deposits
    @deposits||=transactions(deposits_section)
  end
  
  def withdrawals
    @withdrawals||=transactions(withdrawals_section)+checks
  end
  
  def checks
    if has_checks?
      transactions(checks_section).collect{|x|[x[0],x[1],-x[2]]}
    else
      []
    end
  end
  
  def all
    (deposits+withdrawals)
  end
  
  def transactions(text)
    text.scan(/#{DATE} (.*?) #{AMOUNT}/).collect do |x|
      [ format_date(x[0]), 
        x[2] ? x[2].strip.gsub(/,/,' ').gsub(/\s+/,' ') : 'In branch check',to_number(x[3])]
    end
  end
  
  def deposits_section
    @content[deposits_start,withdrawals_start-deposits_start]
  end

  def withdrawals_section
    if has_checks?
      @content[withdrawals_start,checks_start-withdrawals_start]
    else
      @content[withdrawals_start,daily_balance_summary_start-withdrawals_start]
    end
  end

  def checks_section
    @content[checks_start,daily_balance_summary_start-checks_start]
  end
  
  def has_checks?
    checks_start!=nil
  end
  
  def deposits_start
    @content.index "DEPOSITS AND CREDITS"
  end

  def withdrawals_start
    @content.index "WITHDRAWALS AND DEBITS"
  end

  def checks_start
    @content.index "CHECKS PAID"
  end
  
  def daily_balance_summary_start
    @content.index "DAILY BALANCE SUMMARY"
  end
  
  def to_number(amount)
    truncate(amount.gsub(/[ ,]/,'').to_f)
  end
  
  def truncate(number)
    ((((number*100).round).to_f)/100).to_f
  end
  
  def format_date(d)
    (d.split + [@year]).join('-')
  end
  
  def to_hash
    attributes={}
    [:statement_end_date, :account_number, :ending_balance, :starting_balance, :total_deposits, :total_withdrawals, :deposits, :withdrawals].each do |name|
      attributes[name]=self.send(name)
    end
    attributes
  end
#  protected
  
  def search(regex)
    @content.scan(regex)
  end
  
  def find_value(regex)
    search(regex).first
  end
end