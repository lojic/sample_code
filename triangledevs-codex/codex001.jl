# c.f. codex001.rkt for comparison

# Dict of dictionary words
dict = Dict(w => true for w in eachline("dictionary.txt"))

# passwordstrength(username, password, lookupword) -> (Symbol, Union{String, Nothing})
# username : String
# password : String
# lookupword : String -> Bool
#
# Returns two values, a symbol indicating the strength of the
# password, and an optional error message which will be nothing if no
# error message.
function passwordstrength(username, password, lookupword)
  bits = entropybits(password)
  error_message = failedpassword(username, password, bits, lookupword)

  if isnothing(error_message)
    strength = if bits < 66
      :weak
    elseif bits < 99
      :fair
    elseif bits < 132
      :good
    else
      :strong
    end

    (strength, nothing)
  else
    (:fail, error_message)
  end
end

# charactersetsize(str) -> Int
# str : String
#
# Returns the character set size for a string.
#
# This function, while much longer, is more than 10x faster than
# repeated regexp-match calls.
function charactersetsize(str)::Int
  digits = lower = upper = sym = false

  for c in str
    if islowercase(c)
      lower = true
    elseif isuppercase(c)
      upper = true
    elseif isdigit(c)
      digits = true
    elseif !isspace(c)
      sym = true
    end

    digits && lower && upper && sym && break
  end

  (digits ? 10 : 0) + (lower ? 26 : 0) + (upper ? 26 : 0) + (sym ? 32 : 0)
end

# entropybits(str) -> Int
# str : String
#
# Returns the number of bits required to represent the specified
# string.
entropybits(str)::Int = ceil(length(str) * log(2, charactersetsize(str)))

# failedpassword(username, password, bits) -> Union{String, Nothing}
# username : String
# password : String
# bits : Int
# lookupword : String -> Bool
#
# Returns either an error string for a failed password, or #f for a
# valid password.
function failedpassword(username, password, bits, lookupword)
  user = lowercase(username)
  pswd = lowercase(password)

  # Helper functions --------------------------------------------------------------------------
  checkentropy()  = bits < 48 ? "Entropy bits ($bits) < 48" : nothing
  checkusername() = contains(pswd, user) ? "Contains username ($username)" : nothing

  function checkdictionary()
    dwords = [ word for word in subwords(pswd, 3) if lookupword(word) ]

    if isempty(dwords)
      nothing
    else
      "Contains dictionary words: $(join(sort(dwords), ", "))"
    end
  end
  # -------------------------------------------------------------------------------------------

  errors = [ message for message in [ checkentropy(), checkusername(), checkdictionary() ]
             if !isnothing(message) ]

  if isempty(errors)
    nothing
  else
    join(errors, "; ")
  end
end

# subwords(str, n) -> Array{String,1}
# str : String
# n : Int
#
# Returns a list of all subwords within str that are at least n
# characters long.
function subwords(str, n)
  # Removing non alpha characters greatly reduces the number of
  # subwords we need to check!
  str = replace(str, r"[^A-Za-z]+" => "")
  len = length(str)
  [ str[b:e] for b = 1:len-n+1 for e = b+n-1:len ]
end

# Benchmark
# lookup(w) = haskey(dict, w)
# passwordstrength("jsmith", "aKwirkdcICOYuHd03iDcje>ZzVAG}T", lookup)
# @time for _ = 1:100000
#   passwordstrength("jsmith", "aKwirkdcICOYuHd03iDcje>ZzVAG}T", lookup)
# end

using Test

@testset "passwordstrength" begin
  lookup(word) = haskey(dict, word)

  @test passwordstrength("jsmith", "Pswd1", lookup) == (:fail, "Entropy bits (30) < 48")

  @test passwordstrength("jsmith", "FgKMsFqEjsmithZ4UIMw7pkmT4e4", lookup) ==
    (:fail, "Contains username (jsmith); Contains dictionary words: mit, smit, smith")

  @test passwordstrength("jsmith", "abate", lookup) ==
    (:fail, "Entropy bits (24) < 48; Contains dictionary words: abate, ate, bat, bate")

  @test passwordstrength("jsmith", "a4df8az2wq", lookup)            == (:weak, nothing)
  @test passwordstrength("jsmith", "A4dF8aZ2wQ5", lookup)           == (:fair, nothing)
  @test passwordstrength("jsmith", "Ab@hY#iU*qw!fv\$z", lookup)     == (:good, nothing)
  @test passwordstrength("jsmith", "!1Qa@2Ws#3Ed\$4Rf%5Tg", lookup) == (:strong, nothing)
end

@testset "charactersetsize" begin
  @test charactersetsize("34") == 10
  @test charactersetsize("ab") == 26
  @test charactersetsize("AB") == 26
  @test charactersetsize("@#") == 32
  @test charactersetsize("3a") == 36
  @test charactersetsize("3Z") == 36
  @test charactersetsize("3@") == 42
  @test charactersetsize("Aa") == 52
  @test charactersetsize("A^") == 58
  @test charactersetsize("a^") == 58
  @test charactersetsize("Aa7") == 62
  @test charactersetsize("3a&") == 68
  @test charactersetsize("3A&") == 68
  @test charactersetsize("aA%") == 84
  @test charactersetsize("1aA!") == 94
end

@testset "dictionary" begin
  @test haskey(dict, "abate")
  @test !haskey(dict, "qwertyasdf")
end

@testset "entropybits" begin
  @test charactersetsize("Open-Sesame") == 84
  @test entropybits("Open-Sesame") == 71
end

@testset "failedpassword" begin
  lookup(w) = haskey(dict, w)

  pswd = "Pswd1"
  @test failedpassword("jsmith", pswd, entropybits(pswd), lookup) ==
    "Entropy bits (30) < 48"

  pswd = "FgKMsFqEjsmithZ4UIMw7pkmT4e4"
  @test failedpassword("jsmith", pswd, entropybits(pswd), lookup) ==
  "Contains username (jsmith); Contains dictionary words: mit, smit, smith"

  pswd = "abate"
  @test failedpassword("jsmith", pswd, entropybits(pswd), lookup) ==
  "Entropy bits (24) < 48; Contains dictionary words: abate, ate, bat, bate"
end

@testset "subwords" begin
  @test subwords("abc", 3) == [ "abc" ]
  @test subwords("abc", 2) == [ "ab","abc","bc" ]
  @test subwords("abcde", 3) == [ "abc","abcd","abcde","bcd","bcde","cde" ]
  @test subwords("abc", 4) == [ ]
end
