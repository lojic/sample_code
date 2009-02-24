#  09/10/07
#  Buzz, Woody, Rex, and Hamm have to escape from Zurg. They merely
#  have to cross one last bridge before they are free. However, the
#  bridge is fragile and can hold at most two of them at the same time.
#  Moreover, to cross the bridge a flashlight is needed to avoid traps
#  and broken parts. The problem is that our friends have only one
#  flashlight with one battery that lasts for only 60 minutes. The toys
#  need different times to cross the bridge (in either direction):
#
#  Buzz:   5 minutes
#  Woody: 10 minutes
#  Rex:   20 minutes
#  Hamm:  25 minutes
#
#  Since there can be only two toys on the bridge at the same time,
#  they cannot cross the bridge all at once. Since they need the
#  flashlight to cross the bridge, whenever two have crossed the bridge,
#  somebody has to go back and bring the flashlight to those toys on
#  the other side that still have to cross the bridge.
#
#  The problem now is: In which order can the four toys cross the
#  bridge in time (that is, in 60 minutes) to be saved from Zurg?

require 'pp'
TOYS = { :buzz => 5, :woody => 10, :rex => 20, :hamm => 25 }

def combinations array, n
  result = []
  if n > 0
    (0 .. array.length - n).each do |i|
      combs = [[]] if (combs = combinations(array[i + 1 .. -1], n - 1)).empty?
      combs.collect {|comb| [array[i]] + comb}.each {|x| result << x}
    end
  end
  result
end

def execute_move state, forward, movers
  { :minutes => state[:minutes] - TOYS[movers.max {|a,b| TOYS[a] <=> TOYS[b] }], 
    :source => forward ? state[:source] - movers : state[:source] + movers, 
    :destination => forward ? state[:destination] + movers : state[:destination] - movers,
    :position => forward ? :backward : :forward,
    :history => state[:history] + [[ state[:position], movers ]] }
end

def each_state state
  combinations(*(
    forward = state[:position] == :forward) ? 
    [state[:source], 2] : 
    [state[:destination], 1]).each {|movers| yield execute_move(state, forward, movers) }
end

def play_game state, &b
  if state[:source].empty? 
    yield(state[:history]) unless state[:minutes] < 0
  else
    each_state(state) {|new_state| play_game new_state, &b } 
  end
end

play_game({ 
  :minutes => 60, 
  :source => [ :buzz, :woody, :rex, :hamm ],
  :destination => [], 
  :position => :forward, 
  :history => [] }) {|history| pp history }
