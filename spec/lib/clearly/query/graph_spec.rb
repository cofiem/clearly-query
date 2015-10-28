require 'spec_helper'

describe Clearly::Query::Graph do
  include_context 'shared_setup'

  context 'creates the expected branch when' do
    it 'maps customer associations' do
      association_graph = {join: customer_def.model, on: nil, associations: customer_def.associations}
      graph = Clearly::Query::Graph.new(association_graph, :associations)
      result = graph.branches

      expect(result.size).to eq(1)
      expect(result[0].size).to eq(6)

      expect(result[0][0][:join]).to eq(Customer)
      expect(result[0][1][:join]).to eq(Order)
      expect(result[0][2][:join]).to eq(Arel::Table.new(:orders_products))
      expect(result[0][3][:join]).to eq(Product)
      expect(result[0][4][:join]).to eq(Arel::Table.new(:parts_products))
      expect(result[0][5][:join]).to eq(Part)
    end

    it 'maps order associations' do
      association_graph = {join: order_def.model, on: nil, associations: order_def.associations}
      graph = Clearly::Query::Graph.new(association_graph, :associations)
      result = graph.branches

      expect(result.size).to eq(2)

      expect(result[0].size).to eq(2)
      expect(result[1].size).to eq(5)

      expect(result[0][0][:join]).to eq(Order)
      expect(result[0][1][:join]).to eq(Customer)

      expect(result[1][0][:join]).to eq(Order)
      expect(result[1][1][:join]).to eq(Arel::Table.new(:orders_products))
      expect(result[1][2][:join]).to eq(Product)
      expect(result[1][3][:join]).to eq(Arel::Table.new(:parts_products))
      expect(result[1][4][:join]).to eq(Part)
    end

    it 'maps part associations' do
      association_graph = {join: part_def.model, on: nil, associations: part_def.associations}
      graph = Clearly::Query::Graph.new(association_graph, :associations)
      result = graph.branches

      expect(result.size).to eq(1)
      expect(result[0].size).to eq(6)

      expect(result[0][5][:join]).to eq(Customer)
      expect(result[0][4][:join]).to eq(Order)
      expect(result[0][3][:join]).to eq(Arel::Table.new(:orders_products))
      expect(result[0][2][:join]).to eq(Product)
      expect(result[0][1][:join]).to eq(Arel::Table.new(:parts_products))
      expect(result[0][0][:join]).to eq(Part)
    end

    it 'maps product associations' do
      association_graph = {join: product_def.model, on: nil, associations: product_def.associations}
      graph = Clearly::Query::Graph.new(association_graph, :associations)
      result = graph.branches

      expect(result.size).to eq(2)

      expect(result[0].size).to eq(4)
      expect(result[1].size).to eq(3)

      expect(result[0][0][:join]).to eq(Product)
      expect(result[0][1][:join]).to eq(Arel::Table.new(:orders_products))
      expect(result[0][2][:join]).to eq(Order)
      expect(result[0][3][:join]).to eq(Customer)

      expect(result[1][0][:join]).to eq(Product)
      expect(result[1][1][:join]).to eq(Arel::Table.new(:parts_products))
      expect(result[1][2][:join]).to eq(Part)
    end

  end

end
