# Select a subset of species e.g. dog, cat, snake
# Take the 'count' most populous sub-species
# Sort the final result by original position of species and population
#
# Originally motivated by this comp.lang.lisp thread:
# http://groups.google.com/group/comp.lang.lisp/browse_frm/thread/296ea591d79ae7f5?hl=en#

PETS = [
  [:dog, [[:blab, 12], [:glab, 17], [:cbret, 82], [:dober, 42], [:gshep, 25]]],
  [:cat, [[:pers, 22], [:siam, 7], [:tibet, 52], [:russ, 92], [:meow, 35]]],
  [:snake, [[:garter, 10], [:cobra, 37], [:python, 77], [:adder, 24], [:rattle, 40]]],
  [:cow, [[:jersey, 200], [:heiffer, 300], [:moo, 400]]]
]

def digest_tag_population tag_population, pick_tags, count
  tag_population.select {|e| pick_tags.include?(e[0]) }.
    inject([]) {|memo,obj| obj[1].each {|e| memo << [obj[0], e[0], e[1]] }; memo }.
    sort {|a,b| b[2] <=> a[2] }[0,count].
    sort_by {|e| [ tag_population.map{|p| p[0]}.rindex(e[0]), e[2] * -1] }
end

digest_tag_population(PETS, [:dog, :cat, :snake], 5)
