ENV["RAILS_ENV"] = "test"
require 'rubygems'
require 'active_support'
require 'active_support/test_case'
require 'test/unit'
require 'action_controller'
require 'test_help'

$: << File.join(File.dirname(__FILE__), '../lib')
require File.join(File.dirname(__FILE__), "../init")

