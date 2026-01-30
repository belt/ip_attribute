# frozen_string_literal: true

RSpec.shared_context "single column AR" do
  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.define do
      create_table :test_users, force: true do |t|
        t.decimal :login_ip, precision: 39, scale: 0
        t.decimal :last_ip, precision: 39, scale: 0
        t.string :name
      end
    end

    Object.send(:remove_const, :TestUser) if defined?(TestUser)
    eval <<~RUBY, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
      class TestUser < ActiveRecord::Base
        include IpAttribute::ActiveRecordIntegration
      end
    RUBY
  end

  after(:all) { Object.send(:remove_const, :TestUser) if defined?(TestUser) }
  let(:user) { TestUser.new(name: "test") }
end

RSpec.shared_context "single column + family AR" do
  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.define do
      create_table :family_users, force: true do |t|
        t.decimal :login_ip, precision: 39, scale: 0
        t.integer :login_ip_family, limit: 2
        t.string :name
      end
    end

    Object.send(:remove_const, :FamilyUser) if defined?(FamilyUser)
    eval <<~RUBY, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
      class FamilyUser < ActiveRecord::Base
        include IpAttribute::ActiveRecordIntegration
      end
    RUBY
  end

  after(:all) { Object.send(:remove_const, :FamilyUser) if defined?(FamilyUser) }
  let(:user) { FamilyUser.new(name: "test") }
end

RSpec.shared_context "dual column AR" do
  before(:all) do
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.define do
      create_table :dual_sessions, force: true do |t|
        t.bigint :client_ipv4
        t.decimal :client_ipv6, precision: 39, scale: 0
        t.string :name
      end
    end

    Object.send(:remove_const, :DualSession) if defined?(DualSession)
    eval <<~RUBY, binding, __FILE__, __LINE__ + 1 # rubocop:disable Security/Eval
      class DualSession < ActiveRecord::Base
        include IpAttribute::ActiveRecordIntegration
      end
    RUBY
  end

  after(:all) { Object.send(:remove_const, :DualSession) if defined?(DualSession) }
  let(:session) { DualSession.new(name: "test") }
end
