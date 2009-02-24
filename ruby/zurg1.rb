require 'pp'
TOYS = { :buzz => 5, :woody => 10, :rex => 20, :hamm => 25, :foo => 30, :bar => 35, :abc => 40 }

def combinations array, n
  result = []
  if n > 0
    (0 .. array.length - n).each do |i|
      combs = [[]] if (combs = combinations(array[i + 1 .. -1], n - 1)).empty?
      combs.collect {|comb| [array[i]] + comb}.each {|x| result << x}
    end
  end
  return result
end

def generate_states state
  forward = state[:position] == :forward
  args = forward ? [state[:source], 2] : [state[:destination], 1]
  combinations(*args).inject([]) do |states, movers|
    states << {
      :minutes => state[:minutes] - TOYS[movers.max {|a,b| TOYS[a] <=> TOYS[b] }],
      :source => forward ? state[:source] - movers : state[:source] + movers,
      :destination => forward ? state[:destination] + movers : state[:destination] - movers,
      :position => forward ? :backward : :forward,
      :history => state[:history] + [[ state[:position], movers ]] }
    states
  end
end

def play_game state
  if state[:source].empty?
    pp(state[:history]) unless state[:minutes] < 0
  else
    generate_states(state).each {|new_state| play_game new_state }
  end
end

play_game({
  :minutes => 60,
  :source => [ :buzz, :woody, :rex, :hamm, :foo, :bar ],
  :destination => [],
  :position => :forward,
  :history => [] })
