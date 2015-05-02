require 'spec_helper'

describe ClearlyQuery::Parser do
  it 'can be instantiated' do
    ClearlyQuery::Parser.new({})
  end

  it 'cleans the hash' do
    dirty = { 'hello' => ['testing', 'testing'], 'again' => { 'something' => :small_one}}
    clean = {hello: [:testing, :testing], again: {something: :small_one}}

    parser = ClearlyQuery::Parser.new(dirty)
    expect(parser.cleaned).to eq(clean)
  end
end
