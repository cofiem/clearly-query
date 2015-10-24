require 'spec_helper'

describe ClearlyQuery::Cleaner do
  include_context 'shared_setup'

  it 'can be instantiated' do
    ClearlyQuery::Cleaner.new
  end

  context 'produces the expected result when cleaning a hash that' do
    it 'has simple values' do
      dirty = {'hello' => ['testing', 'testing'], 'again' => {'something' => :small_one}}
      clean = {hello: ['testing', 'testing'], again: {something: :small_one}}

      expect(cleaner.do(dirty)).to eq(clean)
    end

    it 'has complex values' do
      current_time = Time.zone.now
      dirty = {current_time => [Range.new(2, 5), 123456], 'again' => {'something' => :small_one}}
      clean = {
          current_time.to_s.underscore.to_sym => [2..5, 123456],
          again: {something: :small_one}
      }

      expect(cleaner.do(dirty)).to eq(clean)
    end

    it 'has nested arrays and hashes' do
      dirty = {
          what_is_this: [{test: Range.new(2, 5)}, [['more-more-more'], 123456]],
          'again' => {'something' => :small_one}
      }
      clean = {
          what_is_this: [{test: 2..5}, [['more-more-more'], 123456]],
          again: {something: :small_one}
      }

      expect(cleaner.do(dirty)).to eq(clean)
    end
  end
end
