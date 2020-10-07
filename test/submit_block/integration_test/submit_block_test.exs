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

    IO.inspect(
      SubmitBlock.submit_block(
        "block_root",
        0,
        1000,
        contracts["CONTRACT_ADDRESS_PLASMA_FRAMEWORK"],
        url: "http://localhost:#{port}",
        private_key_module: System,
        private_key_function: :get_env,
        private_key_args: ["PK"]
      )
    )
IO.inspect "here"
  end

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
end
