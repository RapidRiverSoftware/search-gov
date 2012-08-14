require 'spec_helper'

describe "Boosted sites rake tasks" do
  before(:all) do
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake.application.rake_require('tasks/boosted_content')
    Rake::Task.define_task(:environment)
  end

  describe "usasearch:boosted_content" do
    describe "usasearch:boosted_content:prune" do
      let(:task_name) { 'usasearch:boosted_content:prune' }
      before { @rake[task_name].reenable }

      it "should have 'environment' as a prereq" do
        @rake[task_name].prerequisites.should include("environment")
      end

      it "should delete auto-generated boosted_content more than a week old" do
        BoostedContent.should_receive(:delete_all).with(["created_at < ? and auto_generated = true", 7.days.ago.beginning_of_day.to_s(:db)])
        @rake[task_name].invoke
      end
    end
  end
end