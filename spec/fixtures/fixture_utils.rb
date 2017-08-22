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

  def self.non_existent_file_msg(path)
    "ERROR: #{path} does not exist!\n"
  end

  def self.invalid_file_msg(path)
    "ERROR: #{path} is not a valid log file! Log files must have the \".log\" extension.\n"
  end

  def self.valid_file_msg(path)
    "#{path} was successfully translated, with the result written to #{path}.trans!\n"
  end

  def self.unique_path(prefix)
    tmp_file = Tempfile.new(prefix)
    path = tmp_file.path
    tmp_file.close
    tmp_file.unlink
    path
  end

  # Interleaves the array "b" with array "a". Note that
  # if |b| > |a|, then the remaining elements of b are not included.
  def self.interleave(a, b)
    a.zip(b).reduce(:concat).compact
  end
end
