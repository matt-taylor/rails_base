RSpec.describe LinkDecisionHelper do

  let(:instance) { described_class.new(**params) }
  let(:params) do
    {
      title: title,
      url: url,
      type: type,
      default_type: default_type,
      config: config
    }.compact
  end

  let(:title) { 'Title for header' }
  let(:url) { '/path/url/for/header' }
  let(:type) { described_class::NAVBAR_LOGGED_IN }
  let(:default_type) { nil }
  let(:config) { nil }
  let(:type_array) { Rails.application.config.public_send("#{type}") }

  describe '.clear_type!' do
  end

  describe '.initialize' do
    subject(:init) { instance }
    context 'when using default' do
      let(:default_type) { described_class::NAVBAR_LOGGED_IN }

      context 'when default is not an allowed type' do
        let(:default_type) { "#{type}_not_allowed_type" }

        it 'raises error' do
          expect { init }.to raise_error(described_class::NotOnAllowListError)
        end
      end

      it 'sets url' do
        expect(init.url).to eq(described_class::DEFAULT_URL)
      end

      it 'sets title' do
        expect(init.title).to eq(described_class::DEFAULT_TITLE)
      end
    end

    context 'when config passed in' do
      let(:config) { Rails.application.config }

      it 'sets url' do
        expect(init.url).to eq(url)
      end

      it 'sets title' do
        expect(init.title).to eq(title)
      end
    end

    context 'when not an allowed type' do
      let(:type) { "#{described_class::NAVBAR_LOGGED_IN}_not_allowed_type" }

      it 'raises error' do
        expect { init }.to raise_error(described_class::NotOnAllowListError)
      end
    end
  end

  describe '#assign!' do
    subject(:assign) { instance.assign! }
    before { described_class.clear_type!(type: type) }

    it 'present in config' do
      assign

      expect(type_array).to eq([instance])
    end
  end

  describe '#url' do
    subject { instance.url }

    context 'when is a proc' do
      let(:url) { -> { 'this_is_a_valid_call' } }

      it { is_expected.to eq('this_is_a_valid_call') }
    end

    it { is_expected.to eq(url) }
  end

  describe '#title' do
    subject { instance.title }

    context 'when is a proc' do
      let(:title) { -> { 'this_is_a_valid_call' } }

      it { is_expected.to eq('this_is_a_valid_call') }
    end

    it { is_expected.to eq(title) }
  end

  describe 'e2e' do
    before do
      # app/config/initializers/link_decision_helper.rb
      # clear all types you are about to assign
      # Removes default and sets config to an array
      described_class.clear_type!(type: type)
      # whatever is defined first is set to active and first in line
      described_class.new(**params).assign!
      described_class.new(**params.merge(default_type: type)).assign!
    end

    it 'sets two headers' do
      expect(type_array).to all(be_a(described_class))
    end
  end
end
