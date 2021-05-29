# frozen_string_literal: true

RSpec.describe Sidekiq::Web::Custom do
  it "has a version number" do
    expect(Sidekiq::Web::Custom::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
