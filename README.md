# reverse-translation 

A CLI tool for translating foreign log files back to English.

## Setup

Running the tool requires ruby version 2.0 or greater. First, clone the repo:
```
git clone git@github.com:ekinanp/reverse-translation.git
```

Then go into the repo's root directory
```
cd reverse-translation
```

To run the tool, type the following command in the repo's root directory:
```
./bin/reverse_translate <log-file>
```
where \<log-file\> is the path to the log file that needs to be translated. Be sure that the file ends with the ".log" extension. The tool will write the translated log file to the path \<log-file\>.trans, i.e., the translated log file's path is the provided path appended with the ".trans" extension.

NOTE: One key assumption in the tool is that the parameters are not translated, so it is highly unlikely that a parameter itself will be a part of the message in a foreign log file. For example, assume we have a log entry of the form "{0} errored on Node {1}!" whose translation is "Node {1} errored with {0}!", where {0} and {1} are the message's parameters. Then if the log message is of the form "Puppet errored on Node B errored on Node C", the tool will translate this to "Node B errored with Puppet errored on Node C", while another valid translation is "Node C errored with Puppet errored on Node B", i.e. the translation becomes ambiguous. So as counter-intuitive as it might be, please avoid running the CLI tool with English log files, as this risk becomes highly likely then!

## PO files

The tool relies on PO files, which are files containing the translations from English to the foreign language (and vice versa), to translate the log files. The resources/\<language\> directory contains all the PO files that the script will search for; for example, all the japanese PO files are in the resources/ja directory. It obtains these PO files from GitHub repos; right now these are only Puppet-specific repos, but they may include other third party repos in the future, such as Postgres. If you need to update the PO files before running the tool, type the command:
```
./scripts/get_po_files.sh
```
which will go to all the listed repos in the script and obtain the language specific PO files (right now, it is all the Japanese PO files). To add a new puppet repo, open the script in a text editor, and include the repo's name as part of the PUPPET_REPOS variable in the script. To add a third party repo, open the script again in a text editor, and include the repo's full git URL in the THIRD_PARTY_REPOS variable. 

## Limitations

The tool currently brute forces through all the translations in every provided PO file, i.e. the files that are currently in the resources/ja directory. For log files containing > 1000 messages, this could take a small amount of time to translate. Improving the performance is one of the next steps in the tool's development.

The tool assumes that all log-messages have some sort of a separator differentiating one message from the next, i.e. that a single log message is of the form \<PREFIX\>\<MESSAGE\> where PREFIX contains extraneous info. such as the timestamp, the date, the logging level, etc., while MESSAGE is the actual, to-be-translated message. Thus for ".log" files where a prefix does not exist, such as for the installer logs, this tool will not work. In the future, one possible approach would be having the user of the script provide their own (optional) separator expression.

If any entry in a PO file's message is of the form "\<p1\>\<p2\> ...", where p1 and p2 are parameters in the message, then this will be skipped over in the translation. The reason is due to catastrophic backtracking, as the existing code uses regexes of the form (.\*) to describe arbitrary parameters (the regex is short for "match any character"). When there are adjacent parameters, the regex becomes (.\*)(.\*) which can take an exponential (long) amount of time to match longer strings. A more real-world reason is that it is difficult to differentiate what part of a message belongs to \<p1\> and what part belongs to \<p2\>. I.e., for messages where two parameters are adjacent to one another, the tool skips them in translation.

For messages with a prefix of the form \<DATE\> \<TIMESTAMP\> \<LEVEL\> \<THREAD\> \<CALLER\> [\<some foreign string\>], the [\<some foreign string\>] is included as a part of the message's prefix, so it will not be translated. One of the tool's assumptions is that many LOG messages will not begin this way; if this becomes an issue, then the tool can be modified to translate that part.
