module FixtureUtils
  @@msgid_ctr = 0
  MSGID_GEN = lambda do
    entry_name = (@@msgid_ctr >= 1) ? "msgid_plural" : "msgid"
    @@msgid_ctr = @@msgid_ctr + 1
    entry_name
  end

  @@msgstr_ctr = 0
  @@is_array = false
  MSGSTR_GEN = lambda do
    return "msgstr" if !@@is_array
    entry_name = "msgstr[#{@@msgstr_ctr}]"
    @@msgstr_ctr = @@msgstr_ctr + 1
    entry_name
  end

  def self.set_is_array(val)
    @@is_array = val
  end

  def self.reset
    @@msgid_ctr, @@msgstr_ctr, @@is_array = [0, 0, false]
  end
end
