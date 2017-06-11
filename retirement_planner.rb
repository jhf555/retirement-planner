# Provides a tool for approximating when you can retire based on your age,
# income, investments, etc.  This is meant as one tool and nothing more, use
# the calculations it provides at your own risk.  This tool should not be used
# as a substitute for other financial planning methods.
#
# This script might be missing some things, e.g. tax consideration, property values,
# etc

require 'date'

# Formatting helper
def int_to_comma_dollar_string(num)
  is_negative = (num < 0)
  num *= -1 if is_negative

  ret = []
  num = num.to_i.to_s.reverse
  for i in 0..(num.length-1)
    ret << ',' if i > 0 && i % 3 == 0
    ret << num[i].chr
  end
  ret = "$" + ret.reverse.join('')
  ret = "-" + ret if is_negative
  return ret
end

class RetirementPlanner
  def initialize(
      birth_year,
      starting_yearly_capital, 
      starting_yearly_expenses, 
      starting_income,
      starting_yearly_return_rate,
      starting_yearly_inflation_rate,
      events)

    @birth_year = birth_year
    @year = Date.today.year
    @total_capital = starting_yearly_capital.to_f
    @expenses = starting_yearly_expenses.to_f
    @return_rate = starting_yearly_return_rate
    @inflation_rate = starting_yearly_inflation_rate
    @income = starting_income.to_f
    @returns = (@total_capital * @return_rate).to_i
    @events = events

    @ran_out_of_money_age = nil
  end

  def simulate_until_age(age)
    while true do
      break if self.get_age >= age
      yield
      self.tick_year
    end
  end

  def simulate_num_years(num_years)
    for i in 0..num_years do
      yield
      self.tick_year
    end
  end
  
  def tick_year
    @year += 1

    # Increase both expenses and income for inflation
    @expenses += (@expenses * @inflation_rate).to_i

    @income += (@income * @inflation_rate).to_i

    self.process_events

    prev_total_capital = @total_capital

    @total_capital -= @expenses
    @total_capital += @income
    @returns = (@total_capital * @return_rate).to_i
    @total_capital += @returns

    if @ran_out_of_money_age == nil
      if prev_total_capital > 0 and @total_capital < 0
        @ran_out_of_money_age = self.get_age
      end
    end
  end

  def process_events
    cur_events = self.get_year_events
    return if cur_events == nil
    cur_events.each_with_index do |evt, idx|
      self.process_event(evt)
    end
  end

  def get_year_events
    return @events[self.get_age]
  end

  def process_event(evt)
    op = nil
    ["=", "-", "+", "*", "/"].each do |cur_op|
      if evt.split(cur_op).length == 2
        op = cur_op
        break
      end
    end
    raise "Invalid event #{evt}" if op == nil

    parts = evt.split(op)
    field = parts[0]
    val = parts[1].to_f

    starting_val = nil
    if field == "capital"
      starting_val = @total_capital
    elsif field == "income"
      starting_val = @income
    elsif field == "expenses"
      starting_val = @expenses
    elsif field == "return_rate"
      starting_val = @return_rate
    elsif field == "inflation"
      starting_val = @inflation_rate
    else
      raise "Unhandled field for event #{evt}"
    end

    new_val = nil
    if op == "="
      new_val = val
    elsif op == "+"
      new_val = starting_val + val
    elsif op == "-"
      new_val = starting_val - val
    elsif op == "*"
      new_val = starting_val * val
    elsif op == "/"
      new_val = starting_val / val
    end

    if field == "capital"
      @total_capital = new_val
    elsif field == "income"
      @income = new_val
    elsif field == "expenses"
      @expenses = new_val
    elsif field == "return_rate"
      @return_rate = new_val
    elsif field == "inflation"
      @inflation_rate = new_val
    else
      raise "Unhandled field for event #{evt}"
    end
  end

  def get_year
    return @year
  end

  def get_age
    return @year - @birth_year
  end

  def get_total_capital
    return @total_capital
  end

  def get_expenses
    return @expenses
  end

  def get_income
    return @income
  end

  def get_returns
    return @returns
  end

  def get_ran_out_of_money_age
    return @ran_out_of_money_age
  end

  def is_ran_out_of_money_year
    return self.get_ran_out_of_money_age == self.get_age
  end

  def get_event_summary
    ret = []
    @events.keys.sort.each do |age|
      ret << "#{age}:" + @events[age].join(',')
    end
    return ret.join(' ')
  end
end
