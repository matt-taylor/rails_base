
RSpec.describe RailsBase::Admin::ActionCache do
  let(:instance) { described_class.instance }

  xdescribe '.initialize' do
    subject(:init) { instance }

    context 'with namespace' do
      before { allow(RailsBase.config.redis).to receive(:admin_action_namespace).and_return(namespace) }
      let(:namespace) { 'dooder' }

      it { expect(init.redis.namespace).to eq(namespace) }
    end

    it 'sets redis' do
      expect(init.redis).to be_a(Redis::Namespace)
    end
  end

  xdescribe '#add_action' do
    subject(:add_action) { instance.add_action(params) }

    let(:params) { { user: user, msg: msg, occured: occured } }
    let(:user) { User.first }
    let(:msg) { "This is a Message" }
    let(:occured) { Time.now }

    context 'with multiple actions' do
    end

    it 'adds action to users cache' do

    end

    it 'sets ttl' do
    end
  end
end
