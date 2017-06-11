# Change the values below (e.g. BIRTH_YEAR, etc) and then run the script

require_relative 'retirement_planner.rb'

################################################
# UPDATE THESE VALUES
################################################
BIRTH_YEAR = 1985
RUN_SIMULATION_UNTIL_AGE = 85
STARTING_CAPITAL = 300000
STARTING_YEARLY_EXPENSES = 40000
STARTING_YEARLY_INCOME = 50000
INVESTMENT_RETURN_RATE = 0.06
INFLATION_RATE = 0.03
EVENTS = {
  # Buy house
  40 => ["capital-400000"],

  # Retire.  Assume our expenses will go down but we'll also be
  # invested in safer, lower-yield securities.
  65 => [
    "income=0",
    "return_rate=0.04",
    "expenses*0.8",
  ],
}
################################################

def run_simulation
  tracker = RetirementPlanner.new(
    BIRTH_YEAR,
    STARTING_CAPITAL,
    STARTING_YEARLY_EXPENSES,
    STARTING_YEARLY_INCOME,
    INVESTMENT_RETURN_RATE,
    INFLATION_RATE,
    EVENTS,
  )
  tracker.simulate_until_age(RUN_SIMULATION_UNTIL_AGE) do
    ran_out_str = tracker.is_ran_out_of_money_year ? 
      "!!!!!! RAN OUT OF MONEY !!!!!" : 
      ""

    events = tracker.get_year_events
    puts "  " + events.join(',') if events != nil
    
    puts [
      tracker.get_year,
      tracker.get_age,
      "       ",
      int_to_comma_dollar_string(tracker.get_total_capital),
      "       ",
      "income=" + int_to_comma_dollar_string(tracker.get_income),
      "expenses=" + int_to_comma_dollar_string(tracker.get_expenses),
      "returns=" + int_to_comma_dollar_string(tracker.get_returns),
      ran_out_str,
    ].join(" ")
  end
  if tracker.get_ran_out_of_money_age == nil
    puts "Didn't run out of money: " + 
      int_to_comma_dollar_string(tracker.get_total_capital)
  else
    puts "Ran out of money at " + tracker.get_ran_out_of_money_age.to_s + ": " +
      int_to_comma_dollar_string(tracker.get_total_capital)
  end
end

run_simulation()
