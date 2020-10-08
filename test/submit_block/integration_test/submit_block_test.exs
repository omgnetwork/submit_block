defmodule SubmitBlockTest do
  use ExUnit.Case
  doctest SubmitBlock

  alias SubmitBlock.Geth

  @moduletag :integration

  setup_all do
    {:ok, _briefly} = Application.ensure_all_started(:briefly)
    port = 8545
    {:ok, {_geth_pid, _container_id}} = Geth.start(port)
    contracts = parse_contracts()
    %{port: port, contracts: contracts}
  end

  test "that we're actually able to submit a block to plasma contracts", %{
    port: port,
    contracts: contracts
  } do
    System.put_env("PK", private_key())
    nonce = 1
    gas_price = 1000
    plasma_framework = from_hex(contracts["CONTRACT_ADDRESS_PLASMA_FRAMEWORK"])

    assert SubmitBlock.submit_block(
             "block_root",
             nonce,
             gas_price,
             plasma_framework,
             url: "http://localhost:#{port}",
             private_key_module: System,
             private_key_function: :get_env,
             private_key_args: ["PK"]
           ) ==
             {:ok,
              <<131, 240, 72, 252, 140, 51, 1, 176, 75, 116, 221, 74, 63, 27, 57, 2, 5, 110, 128,
                4, 129, 124, 204, 89, 245, 135, 186, 240, 41, 50, 149, 133>>}

    Process.sleep(5000)
    # bytes of "block_root"
    assert get_external_data(
             contracts["CONTRACT_ADDRESS_PLASMA_FRAMEWORK"],
             "blocks(uint256)",
             [1000],
             url: "http://localhost:#{port}"
           ) ==
             <<98, 108, 111, 99, 107, 95, 114, 111, 111, 116, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
               0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
  end

  defp from_hex("0x" <> encoded), do: Base.decode16!(encoded, case: :lower)
  def to_hex(non_hex)

  def to_hex(raw) when is_binary(raw), do: "0x" <> Base.encode16(raw, case: :lower)
  def to_hex(int) when is_integer(int), do: "0x" <> Integer.to_string(int, 16)

  defp private_key() do
    "0x7f30f140fd4724519e5017c0895f158d68bbbe4a81c0c10dbb25a0006e348807"
  end

  defp parse_contracts() do
    local_umbrella_path = Path.join([File.cwd!(), "../../", "localchain_contract_addresses.env"])

    contract_addreses_path =
      case File.exists?(local_umbrella_path) do
        true ->
          local_umbrella_path

        _ ->
          # CI/CD
          Path.join([File.cwd!(), "localchain_contract_addresses.env"])
      end

    contract_addreses_path
    |> File.read!()
    |> String.split("\n", trim: true)
    |> List.flatten()
    |> Enum.reduce(%{}, fn line, acc ->
      [key, value] = String.split(line, "=")
      Map.put(acc, key, value)
    end)
  end

  defp get_external_data(address, signature, params, opts) do
    data = signature |> ABI.encode(params) |> to_hex()

    {:ok, data} = Ethereumex.HttpClient.eth_call(%{to: address, data: data}, "latest", opts)

    decode_function(data, signature)
  end

  defp blocks() do
    %ABI.FunctionSelector{
      function: "blocks",
      input_names: ["block_hash", "block_timestamp"],
      inputs_indexed: nil,
      method_id: <<242, 91, 63, 153>>,
      # returns: [bytes: 32, uint: 256],
      type: :function,
      # types: [uint: 256]
      types: [bytes: 32, uint: 256]
    }
  end

  defp decode_function(enriched_data, signature) do
    "0x" <> data = enriched_data
    {:ok, sig} = ExKeccak.hash_256(signature)
    <<method_id::binary-size(4), _::binary>> = sig
    method_id |> to_hex() |> Kernel.<>(data) |> from_hex() |> decode_function()
  end

  defp decode_function(enriched_data) do
    function_specs = [blocks()]

    {function_spec, data} = ABI.find_and_decode(function_specs, enriched_data)
    decode_function_call_result(function_spec, data)
  end

  defp decode_function_call_result(function_spec, [values]) when is_tuple(values) do
    function_spec.input_names
    |> Enum.zip(Tuple.to_list(values))
    |> Enum.into(%{})
  end

  defp decode_function_call_result(function_spec, values) do
    function_spec.input_names
    |> Enum.zip(values)
    |> Enum.into(%{})
  end
end
