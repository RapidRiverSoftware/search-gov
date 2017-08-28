require 'spec_helper'

describe I14yDrawer do
  fixtures :i14y_drawers, :affiliates, :i14y_memberships
  it { should validate_presence_of :handle }
  it { should validate_uniqueness_of :handle }
  it { should validate_length_of(:handle).is_at_least(3).is_at_most(33) }
  it { should have_many(:i14y_memberships).dependent(:destroy) }
  it { should have_many(:affiliates).through :i14y_memberships }
  ["UPPERCASE", "weird'chars", "spacey name", "hyphens-are-special-in-i14y",
   "periods.are.bad", "hiding\nnaughti.ness"].each do |value|
    it { should_not allow_value(value).for(:handle) }
  end
  %w{datagov123 some_aff 123}.each do |value|
    it { should allow_value(value).for(:handle) }
  end

  context 'creating a drawer' do
    before do
      SecureRandom.stub(:hex).with(16).and_return "0123456789abcdef"
    end

    it 'creates collection in i14y and assigns token' do
      response = Hashie::Mash.new('status' => 200, "developer_message" => "OK", "user_message" => "blah blah")
      I14yCollections.should_receive(:create).with("settoken", "0123456789abcdef").and_return response
      i14y_drawer = Affiliate.first.i14y_drawers.create!(handle: "settoken")
      i14y_drawer.token.should eq("0123456789abcdef")
    end

    context 'create call to i14y Collection API fails' do
      before do
        I14yCollections.should_receive(:create).and_raise StandardError
      end

      it 'should not create the I14yDrawer' do
        Affiliate.first.i14y_drawers.create(handle: "settoken")
        I14yDrawer.exists?(handle: 'settoken').should be false
      end
    end
  end

  context 'deleting a drawer' do
    it 'deletes collection in i14y' do
      response = Hashie::Mash.new('status' => 200, "developer_message" => "OK", "user_message" => "blah blah")
      I14yCollections.should_receive(:delete).with("one").and_return response
      i14y_drawers(:one).destroy
    end

    context 'delete call to i14y Collection API fails' do
      before do
        I14yCollections.should_receive(:delete).and_raise StandardError
      end

      it 'should not delete the I14yDrawer' do
        i14y_drawers(:one).destroy
        I14yDrawer.exists?(handle: 'one').should be true
      end
    end
  end

  describe "#label" do
    it "should return the handle" do
      i14y_drawers(:one).label.should == i14y_drawers(:one).handle
    end
  end

  describe "stats" do
    let(:collection)  { Hashie::Mash.new('created_at' => '2015-06-12T16:59:50.687+00:00', 'updated_at' => '2015-06-12T16:59:50.687+00:00', 'token' => '6bffe2fe778ba131f28c93377e0630a8', 'id' => 'one', 'document_total' => 1, 'last_document_sent' => "2015-06-12T16:59:50+00:00")}

    before do
      response = Hashie::Mash.new('status' => 200, "developer_message" => "OK", "collection" => collection)
      I14yCollections.should_receive(:get).with("one").and_return response
    end

    it 'gets the collection from I14y endpoint and returns the collection info' do
      i14y_drawers(:one).stats.should == collection
    end
  end

  describe '#i14y_connection' do
    let(:drawer) { I14yDrawer.new(handle: 'handle', token: 'foobarbaz') }
    let(:i14y_connection) { double(Faraday::Connection) }

    it 'establishes a connection based on the drawer handle & token' do
      expect(I14y).to receive(:establish_connection!).with(user: 'handle', password: 'foobarbaz')
      drawer.i14y_connection
    end

    it 'memoizes the connection' do
      expect(I14y).to receive(:establish_connection!).once.
        with(user: 'handle', password: 'foobarbaz').
        and_return(i14y_connection)
      2.times { drawer.i14y_connection }
    end
  end
end
