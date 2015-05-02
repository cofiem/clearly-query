require 'spec_helper'

describe ClearlyQuery::Composer do
  include_context 'shared_setup'

  it 'can be instantiated' do
    ClearlyQuery::Composer.new(all_defs)
  end
end
