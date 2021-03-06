# frozen_string_literal: true
RSpec.describe Pragma::Operation::Create do
  subject(:context) do
    operation_klass.call(
      current_user: current_user,
      params: params
    )
  end

  let(:params) do
    {
      author_id: 1,
      title: 'My Post'
    }
  end

  let(:contract_klass) do
    Class.new(Pragma::Contract::Base) do
      property :author_id
      property :title

      validation do
        required(:title).filled
      end
    end
  end

  let(:operation_klass) do
    Class.new(described_class) do
      def build_record
        OpenStruct.new
      end
    end.tap do |klass|
      klass.send(:contract, contract_klass)
      allow(klass).to receive(:name).and_return('API::V1::Post::Operation::Create')
    end
  end

  let(:current_user) { nil }

  it 'creates the record' do
    expect(context.resource.to_h).to eq(
      title: 'My Post',
      author_id: 1
    )
  end

  context 'when invalid parameters are supplied' do
    let(:params) do
      {
        author_id: 1,
        title: ''
      }
    end

    it 'responds with 422 Unprocessable Entity' do
      expect(context.status).to eq(:unprocessable_entity)
    end
  end

  context 'when a decorator is defined' do
    let(:decorator_klass) do
      Class.new(Pragma::Decorator::Base) do
        property :title
      end
    end

    before do
      operation_klass.send(:decorator, decorator_klass)
    end

    it 'decorates the updated resource' do
      expect(context.resource.to_hash).to eq(
        'title' => 'My Post'
      )
    end
  end

  context 'when a policy is defined' do
    let(:policy_klass) do
      Class.new(Pragma::Policy::Base) do
        def create?
          resource.author_id == user.id
        end
      end
    end

    before do
      operation_klass.send(:policy, policy_klass)
    end

    context 'when the user is authorized' do
      let(:current_user) { OpenStruct.new(id: 1) }

      it 'permits the creation' do
        expect(context.resource.to_h).to eq(title: 'My Post', author_id: 1)
      end
    end

    context 'when the user is not authorized' do
      let(:current_user) { OpenStruct.new(id: 2) }

      it 'does not permit the creation' do
        expect(context.status).to eq(:forbidden)
      end
    end
  end
end
