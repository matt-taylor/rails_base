RSpec.describe RailsBase::AdminUpdateAttribute do
  subject(:call) { described_class.call(params) }

  let(:id) { user.id }
  let(:klass_string) { nil }
  let(:user) { User.first }
  let(:value) { 'value' }
  let(:attribute) { User::SAFE_AUTOMAGIC_UPGRADE_COLS.first }
  let(:input_params) { { id: id, attribute: attribute, value: value} }
  let(:params) {
    {
      params: input_params,
      klass_string: klass_string,
    }
  }

  describe '#validate!' do
    context 'fails without params' do
      let(:params) { super().except(:params) }

      it { expect { call }.to raise_error(/Expected params to be a Hash/) }
    end

    context 'fails without last_name' do
      let(:id) { nil }

      it { expect { call }.to raise_error(/Expected params to have a id/) }
    end
  end

  describe '#call' do
    context 'when klass string given' do
      let(:klass_string) { 'User' }

      it { expect(call.success?).to be true }

      context 'when invalid string' do
        let(:klass_string) { 'UserNotAvail' }

        it { expect(call.failure?).to be true }
        it { expect(call.message).to include("Failed to find model") }
      end

      context 'when model does not have safe upgrade constant' do
        let(:klass_string) { 'AdminAction' }

        it { expect(call.failure?).to be true }
        it { expect(call.message).to include("#{klass_string}::SAFE_AUTOMAGIC_UPGRADE_COLS array does not exist") }
      end
    end

    context 'when invalid id' do
      let(:id) { 34525 }

      it { expect(call.failure?).to be true }
      it { expect(call.message).to include("Failed to find id") }
    end

    context 'when value is true' do
      let(:value) { 'true' }
      let!(:og_value) { user.public_send(attribute) }

      it { expect(call.success?).to be true }
      it { expect(call.original_attribute).to eq og_value }
      it { expect(call.attribute).to eq true }
    end

    context 'when value is false' do
      let(:value) { 'false' }
      let!(:og_value) { user.public_send(attribute) }

      it { expect(call.success?).to be true }
      it { expect(call.original_attribute).to eq og_value }
      it { expect(call.attribute).to eq false }
    end

    context 'when unsafe variable update' do
      let(:attribute) { 'not_in_list' }

      it { expect(call.failure?).to be true }
      it { expect(call.message).to include("#{attribute} is not part of allowed updatable columns") }
    end

    context 'when fail param pased' do
      let(:input_params) { super().merge(_fail_: 'present') }

      it { expect(call.failure?).to be true }
      it { expect(call.message).to include("Failed to update [#{attribute}] with #{value}") }
    end

    context 'when update fails' do
      let(:value) { "#{"d" * 255 }@gmail.com" }
      let(:attribute) { 'email' }

      it { expect(call.failure?).to be true }
      it { expect(call.message).to include("Failed to update") }
    end
  end
end
