# TODO: Change these to require eventually!
require_relative 'POParser'
require_relative 'POEntry'

# This class represents the reverse-lookup table for a single POT file.
# It is an array of POEntries. It will have one method, reverse_translate,
# that takes in a message and tries to translate it using its entries.
# 
# TODO: Have it also account for the pluralization formula later on, making
# sure that msgstr[0] is what corresponds to msgid.
class POTable
  # TODO: Remove after some testing!
  TEST_STR_1 = "[Şħǿẇş şŧȧŧŭş ȧƞḓ ḓḗŧȧīŀş ǿƒ ĵǿƀş, ẇħḗŧħḗř ƈǿḿƥŀḗŧḗ ǿř īƞ-ƥřǿɠřḗşş. ǲ衋ſςſ ııϐϑ]"
  TEST_STR_2 = "[Ṽȧŀīḓȧŧīǿƞ Ḗřřǿř: Ƥŀḗȧşḗ ǿƞŀẏ ŭşḗ ŧħḗ first ǿƥŧīǿƞ. Īŧ ḓǿḗş ŧħḗ şȧḿḗ\n"\
  "ȧş the second one, ẇħīƈħ īş ǿƞŀẏ şŭƥƥǿřŧḗḓ ƒǿř ŀḗɠȧƈẏ ƥŭřƥǿşḗş. ϵςϱϖΐǈϖǅϑϖ ẛςǲ衋衋ǲ 靐ϕ]"
  TEST_STR_3 = "[ĴǾƁ ŦȦŘƓḖŦ: Ƞǿḓḗş ḿȧŧƈħīƞɠ ȧ ƤŭƥƥḗŧḒƁ ɋŭḗřẏ (ŭşīƞɠ ŧħḗ Ƥŭƥƥḗŧ Ɋŭḗřẏ "\
  "Ŀȧƞɠŭȧɠḗ). Ẇḗ řḗƈǿḿḿḗƞḓ ẇřȧƥƥīƞɠ ŧħḗ ɋŭḗřẏ īƞ şīƞɠŀḗ ɋŭǿŧḗş ȧƞḓ, īƞşīḓḗ ŧħḗ "\
  "ɋŭḗřẏ, ŭşīƞɠ ḓǿŭƀŀḗ ɋŭǿŧḗş. Ḗɠ. Ȧŀŀ ƞǿḓḗş ƈǿƞŧȧīƞīƞɠ ḗẋȧḿƥŀḗ īƞ ƈḗřŧƞȧḿḗ: "\
  "--ɋŭḗřẏ 'ƞǿḓḗş {ƈḗřŧƞȧḿḗ ~ \"ḗẋȧḿƥŀḗ\\.ƈǿḿ\"}' Ḗɠ. Ȧŀŀ ƞǿḓḗş ƈǿƞŧȧīƞīƞɠ ŧħḗ "\
  "Ƞŧƥ ƈŀȧşş: --ɋŭḗřẏ 'řḗşǿŭřƈḗş { ŧẏƥḗ = \"Ƈŀȧşş\" ȧƞḓ ŧīŧŀḗ = \"Ƞŧƥ\"}' "\
  "Řḗṽīḗẇ ŧħḗşḗ ḓǿƈş ƒǿř ȧḓḓīŧīǿƞȧŀ ħḗŀƥ ẇīŧħ ƤɊĿ: "\
  "ħŧŧƥş://ḓǿƈş.ƥŭƥƥḗŧ.ƈǿḿ/ƥḗ/ŀȧŧḗşŧ/ǿřƈħḗşŧřȧŧǿř_ĵǿƀ_řŭƞ.ħŧḿŀ#ḗƞƒǿřƈḗ-ƈħȧƞɠḗ-"\
  "ƀȧşḗḓ-ǿƞ-ȧ-ƥɋŀ-ƞǿḓḗş-ɋŭḗřẏ 衋ϕǅ ẛſΰıϱǲ鶱 ϐϰ靐ıϱ ΐıſϱǲϵϰ鶱 ϕ ΐϕ衋ǲǋǅϰϖ ϵ衋靐ẛϰ "\
  "靐ıϐΰ靐ı ΐǈſ ϰẛςςıϖ ẛ靐ıϰϵ ϑǅǈϐϑϐϐǲǋſ ǅẛ ſϐıǅǋ鶱ς靐ſ ϵ靐靐ǲǈ衋]"
  TEST_STR_4 = "[Şħǿẇş ȧ ƥřḗṽīḗẇ ǿƒ ŧħḗ `ƥŭƥƥḗŧ ĵǿƀ řŭƞ` ƈǿḿḿȧƞḓ ẇīŧħ ŧħḗ şȧḿḗ ȧřɠŭḿḗƞŧş, "\
  "īƞƈŀŭḓḗş ƞǿḓḗş ǿř ȧƥƥŀīƈȧŧīǿƞ īƞşŧȧƞƈḗş īƞ ŧħḗ ĵǿƀ ȧƞḓ ƞǿḓḗ řŭƞ ǿřḓḗř. "\
  "ħŧŧƥş://ḓǿƈş.ƥŭƥƥḗŧ.ƈǿḿ/ƥḗ/ŀȧŧḗşŧ/ǿřƈħḗşŧřȧŧǿř_ĵǿƀ_ƥŀȧƞ.ħŧḿŀ ǈ靐鶱ϑǈ ϖ ϖſǲϑϵϐǈ"\
  " 靐ϕ ΐϰΰ ϐǲǲϑ鶱ǈ衋 ϱϱǅ ςϵ]"
  TEST_STR_5 = "[Ƞǿǿƥ:         foobar ſ靐ςıǅ]"
  TEST_STR_6 = "[Řḗɋŭḗşŧ ŧǿ 'blah' ƒȧīŀḗḓ: Exception: Error \n accessing files for \n me ı靐ǋſ鶱ϐϐ ςǅ]"
  TEST_STR_7 = "[Ƞǿǿƥ:         [Řḗɋŭḗşŧ ŧǿ 'blah' ƒȧīŀḗḓ: Exception: Error \n accessing files for \n me ı靐ǋſ鶱ϐϐ ςǅ] ſ靐ςıǅ]"

  # TODO: Remove this after testing!
  attr_reader :entries 

  def initialize(pot_file)
    @entries = POParser::parse(pot_file).map { |e| POEntry.new(e) }
  end

  def reverse_translate(msg)
    entries.inject(msg) { |new_msg, entry| entry.reverse_translate(new_msg) }
  end
end
