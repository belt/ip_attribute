$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
begin ; require 'active_record' ; rescue LoadError; require 'rubygems'; require 'active_record'; end

require 'ar_extensions'

