require 'spec_helper'
require 'compendium'
require 'compendium/count_query'

class SingleCounter
  def count
    1792
  end
end

class MultipleCounter
  def order(*)
    @order = true
    self
  end

  def reverse_order
    @reverse = true
    self
  end

  def count
    results = { 1 => 340, 2 => 204, 3 => 983 }

    if @order
      results = results.sort_by{ |r| r[1] }
      results.reverse! if @reverse
      results = Hash[results]
    end

    results
  end
end

describe Compendium::CountQuery do
  subject { described_class.new(:counted_query, { count: true }, -> * { @counter }) }

  it 'should have a default order' do
    subject.options[:order].should == 'COUNT(*)'
    subject.options[:reverse].should == true
  end

  describe "#run" do
    it "should call count on the proc result" do
      @counter = SingleCounter.new
      @counter.should_receive(:count).and_return(1234)
      subject.run(nil, self)
    end

    it "should return the count" do
      @counter = SingleCounter.new
      subject.run(nil, self).should == [1792]
    end

    context 'when given a hash' do
      before { @counter = MultipleCounter.new }

      it "should return a hash" do
        subject.run(nil, self).should == { 3 => 983, 1 => 340, 2 => 204 }
      end

      it 'should be ordered in descending order' do
        subject.run(nil, self).keys.should == [3, 1, 2]
      end

      it 'should use the given options' do
        subject.options[:reverse] = false
        subject.run(nil, self).keys.should == [2, 1, 3]
      end
    end

    it "should raise an error if the proc does not respond to count" do
      @counter = Class.new
      expect { subject.run(nil, self) }.to raise_error Compendium::InvalidCommand
    end
  end
end