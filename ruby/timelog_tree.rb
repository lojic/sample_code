#!/Users/badkins/.rvm/rubies/ruby-2.1.2/bin/ruby
PREFIX_LEN = '  '

def each_description file
  file.each_line {|line| yield line.split(' ')[3..-1] if line[0,1] == 'i' }
end

def update_categories cat, tags
  return if tags.empty?
  cat[tags[0]] = {} if cat[tags[0]].nil?
  update_categories(cat[tags[0]], tags[1..-1])
end

def print_categories cat, depth, prefix=''
  return if cat.empty?
  cat.keys.sort.each do |k|
    puts prefix + k
    print_categories(cat[k], depth-1, prefix+PREFIX_LEN) if depth > 1
  end
end

def process_file file, cat
  each_description(file) do |tags|
    update_categories(cat, tags)
  end
  cat
end

print_categories(process_file(STDIN, {}), ARGV.length == 1 ? ARGV[0].to_i : 99)
