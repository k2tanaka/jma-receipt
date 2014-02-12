#!/usr/bin/ruby
# coding : utf-8
Encoding.default_external = "euc-jp" unless RUBY_VERSION == "1.8.7"

open(ARGV[1], 'w') do |outf|
  open(ARGV[0], 'r') do |inf|
    while rec = inf.gets
      rec.chomp!
      outf.puts sprintf("%05d%s\n", rec.size, rec)
    end
  end
end
