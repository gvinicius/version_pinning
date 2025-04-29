# frozen_string_literal: true

require_relative '../lib/version_pinning'

RSpec.describe VersionPinning do
  let(:dummy_class) { Class.new { extend VersionPinning } }

  it 'has a version number' do
    expect(VersionPinning::VERSION).not_to be nil
  end

  it 'does something useful' do
    expect(false).to eq(false)
  end

  it 'lists local gems' do
    expect(dummy_class.list_gems).to include('rubocop')
    expect(dummy_class.list_gems).not_to include('sidekiq')
  end
end
