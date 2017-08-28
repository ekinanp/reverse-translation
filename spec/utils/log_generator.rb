# This class is used to generate random log files for testing. It takes in a PO file containing the
# required strings.
#
# TODO:
#   (1) Add recursive translations (i.e. make a translated string a parameter of
#   another translated string). Probably the most necessary addition.
#
#   (2) Right now, msgid entries dominate. Maybe increase the variety so that more
#   msgid_plural entries are generated? This is not as strictly necessary, but would
#   capture real world behavior.
#
#   (3) Could probably randomly generate the prefix too. But this is not that necessary.
class LogGenerator
  # Sample prefix for the log message
  PREFIX = "2017-07-25 17:20:48,042 INFO  [p.r.m.authentication] "

  # Types of parameters that may be found in different log files
  FILENAMES = ["fileOne.c", "file-two.clj", "file_three.rb", "file-four.hs"]
  IDENTIFIERS = ["'admin'", "'temp'", "'user'", "'_hidden_'"]
  QUOTED_PARAMS = [
    "\"Error: Cannot find specified file\"", 
    "\"/etc/puppetlabs/puppet/ssl/certs/ca.pem\"", 
    "pglogical supervisor", 
    "\"/var/log/puppetlabs/postgresql\""
  ]
  EXCEPTION_MSGS = [
    "java.sql.SQLException: HikariDataSource HikariDataSource (orchestrator) has been closed.\n"\
      "\tat com.zaxxer.hikari.HikariDataSource.getConnection(HikariDataSource.java:79)\n"\
      "\tat sun.reflect.NativeMethodAccessorImpl.invoke0(Native Method)\n"\
      "\tat sun.reflect.NativeMethodAccessorImpl.invoke(NativeMethodAccessorImpl.java:62)\n"\
      "\tat sun.reflect.DelegatingMethodAccessorImpl.invoke(DelegatingMethodAccessorImpl.java:43)\n"\
      "\tat java.lang.reflect.Method.invoke(Method.java:498)\n"\
      "\tat clojure.lang.Reflector.invokeMatchingMethod(Reflector.java:93)\n"\
      "\tat clojure.lang.Reflector.invokeNoArgInstanceMember(Reflector.java:313)\n"\
      "\tat puppetlabs.jdbc_util.pool$wrap_with_delayed_init$reify__35232.getConnection(pool.clj:159)\n"\
      "\tat clojure.java.jdbc$get_connection.invokeStatic(jdbc.clj:307)\n"\
      "\tat clojure.java.jdbc$get_connection.invoke(jdbc.clj:197)\n"\
      "\tat clojure.java.jdbc$db_transaction_STAR_.invokeStatic(jdbc.clj:653)\n"\
      "\tat clojure.java.jdbc$db_transaction_STAR_.invoke(jdbc.clj:598)\n"\
      "\tat clojure.java.jdbc$db_transaction_STAR_.invokeStatic(jdbc.clj:611)\n"\
      "\tat clojure.java.jdbc$db_transaction_STAR_.invoke(jdbc.clj:598)\n"\
      "\tat puppetlabs.orchestrator.job$purge_old_jobs.invokeStatic(job.clj:296)\n"\
      "\tat puppetlabs.orchestrator.job$purge_old_jobs.invoke(job.clj:290)\n"\
      "\tat puppetlabs.orchestrator.service$reify__37522$service_fnk__6257__auto___positional$reify__37539$fn__37544.invoke(service.clj:138)\n"\
      "\tat puppetlabs.trapperkeeper.services.scheduler.scheduler_core$wrap_with_error_logging$fn__21777.invoke(scheduler_core.clj:16)\n"\
      "\tat clojure.lang.AFn.run(AFn.java:22)\n"\
      "\tat java.util.concurrent.Executors$RunnableAdapter.call(Executors.java:511)\n"\
      "\tat java.util.concurrent.FutureTask.runAndReset(FutureTask.java:308)\n"\
      "\tat java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.access$301(ScheduledThreadPoolExecutor.java:180)\n"\
      "\tat java.util.concurrent.ScheduledThreadPoolExecutor$ScheduledFutureTask.run(ScheduledThreadPoolExecutor.java:294)\n"\
      "\tat java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)\n"\
      "\tat java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)\n"\
      "\tat java.lang.Thread.run(Thread.java:748)",

      "HikariDataSource HikariDataSource (orchestrator) has been closed.\n"\
        "\tat slingshot.support$stack_trace.invoke(support.clj:201)\n"\
        "\tat puppetlabs.orchestrator.job$clean_db.invokeStatic(job.clj:313)\n"\
        "\tat puppetlabs.orchestrator.job$clean_db.invoke(job.clj:302)\n"\
        "\tat puppetlabs.orchestrator.service$init_service$post_migration_fn__37507.invoke(service.clj:60)\n"\
        "\tat puppetlabs.jdbc_util.pool$wrap_with_delayed_init$fn__35210$fn__35211$fn__35217.invoke(pool.clj:143)\n"\
        "\tat puppetlabs.jdbc_util.pool$wrap_with_delayed_init$fn__35210$fn__35211.invoke(pool.clj:141)\n"\
        "\tat puppetlabs.jdbc_util.pool$wrap_with_delayed_init$fn__35210.invoke(pool.clj:124)\n"\
        "\tat clojure.core$binding_conveyor_fn$fn__4676.invoke(core.clj:1938)\n"\
        "\tat clojure.lang.AFn.call(AFn.java:18)\n"\
        "\tat java.util.concurrent.FutureTask.run(FutureTask.java:266)\n"\
        "\tat java.util.concurrent.ThreadPoolExecutor.runWorker(ThreadPoolExecutor.java:1142)\n"\
        "\tat java.util.concurrent.ThreadPoolExecutor$Worker.run(ThreadPoolExecutor.java:617)\n"\
        "\tat java.lang.Thread.run(Thread.java:748)"\
  ]
  MISC = [
    "INSERT INTO subjects ( login, display_name, email, is_remote, password, id, is_group, is_superuser, is_revoked ) VALUES ( $1, $2, $3, $4, $5, $6, $7, $8, $9 ) RETURNING *", 
    "2017-07-25"
  ] 

  # Final list of parameters
  PARAMS = [FILENAMES, IDENTIFIERS, QUOTED_PARAMS, EXCEPTION_MSGS, MISC]

  attr_reader :po_entries

  def initialize(po_files)
    @po_entries = po_files.map { |f| POParser.parse(f) }.map do |(param_re, entries)|
      entries[1..-1].map { |e| [param_re, e] }
    end.reduce(:concat).select do |param_re, (_, msgstr_part)| 
      !msgstr_part.any? { |_, msg| POParam.adjacent_params?(msg, param_re) }
    end
  end

  # Returns a random parameter
  def random_param
    PARAMS.sample.sample
  end

  # Returns a two element array [english_msg, non_english_msg] where "english_msg" contains the 
  # English version of the generated message while "non_english_msg" contains the non-English 
  # version.
  #
  # Note that if there is a "msgid_plural" entry, that one will always be selected since
  # the translator automatically translates all msgstr entries to "msgid_plural"
  def random_msg
    param_re, entry = @po_entries.sample
    english_key = entry[0].keys.sort[entry[0].keys.size - 1]
    non_english_key = entry[1].keys.sample

    english_msg_raw = entry[0][english_key]
    non_english_msg_raw = entry[1][non_english_key]

    params = POParam.extract_params(english_msg_raw, param_re).uniq
    param_vals = params.map { |p| [p, random_param] }.to_h

    [english_msg_raw, non_english_msg_raw].map { |msg| POParam.substitute_params(msg, param_re, param_vals) }
  end

  # Generates a random log file. Takes two parameters:
  #   (1) The log file name
  #   (2) The number of entries to generate (default to 100)
  #
  # This method will create two files: <path>_english.log and <path>_non_english.log
  # storing the english and non-english versions of the log file, respectively. It will
  # return the paths of both the english and non-english files.
  def generate (path, num_entries = 100)
    english_file = File.open(path + "_english.log", "w")
    non_english_file = File.open(path + "_non_english.log", "w")
    num_entries.times.collect { random_msg }. each do |english, non_english|
      english_file.puts(PREFIX + english)
      non_english_file.puts(PREFIX + non_english)
    end
    english_file.close
    non_english_file.close
    [english_file.path, non_english_file.path]
  end
end
