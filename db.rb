begin
  require_relative '.env.rb'
rescue LoadError
end

require 'sequel/core'

# Delete BIBLIOTHECA_DATABASE_URL from the environment, so it isn't accidently
# passed to subprocesses.  BIBLIOTHECA_DATABASE_URL may contain passwords.
DB = Sequel.connect(ENV.delete('BIBLIOTHECA_DATABASE_URL') || ENV.delete('DATABASE_URL'))
