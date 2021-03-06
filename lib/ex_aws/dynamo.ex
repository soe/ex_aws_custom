defmodule ExAws.Dynamo do
  alias __MODULE__
  alias Dynamo.Conversions
  alias ExAws.Config

  ## Tables
  ######################

  def list_tables do
    request(:list_tables)
  end

  def create_table(name, primary_key, key_definitions, read_capacity, write_capacity) do
    key_schema = [%{
      AttributeName: primary_key,
      KeyType: "HASH"
    }]
    create_table(name, key_schema, key_definitions, read_capacity, write_capacity, [], [])
  end

  def create_table(name, key_schema, key_definitions, read_capacity, write_capacity, global_indexes, local_indexes) do
    data = %{
      TableName: name,
      AttributeDefinitions: key_definitions |> Conversions.dynamize_attrs,
      KeySchema: key_schema,
      ProvisionedThroughput: %{
        ReadCapacityUnits: read_capacity,
        WriteCapacityUnits: write_capacity
      }
    }
    if length(global_indexes) > 0 do
      data = Map.put(data, :GlobalSecondaryIndexes, global_indexes)
    end

    if length(local_indexes) > 0 do
      data = Map.put(data, :LocalSecondaryIndexes, local_indexes)
    end

    request(:create_table, data)
  end

  def delete_table(table) do
    request(:delete_table, %{TableName: table})
  end

  ## Records
  ######################

  def scan(name, opts \\ %{}) do
    data = %{
      TableName: name
    } |> Map.merge(opts)
    request(:scan, data)
  end

  def put_item(name, record) do
    data = %{
      TableName: name,
      Item: Dynamo.Conversions.dynamize(record)
    }
    request(:put_item, data)
  end

  def get_item(name, primary_key) do
    data = %{
      TableName: name,
      Key: primary_key
    }
    request(:get_item, data)
  end

  def delete_item(name, primary_key) do
    data = %{
      TableName: name,
      Key: primary_key
    }
    request(:delete_item, data)
  end

  # These function should be used for everything.
  def request(action) do
    request(action, %{})
  end

  def request(action, data) do
    ExAws.Request.request(:ddb, ExAws.Config.erlcloud_config, Dynamo.Actions.get(action), Config.namespace(data, :dynamo))
  end

end
