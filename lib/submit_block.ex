defmodule SubmitBlock do
  alias SubmitBlock.Transaction
  alias SubmitBlock.PrivateKey
  alias SubmitBlock.Transaction.Signature

  def submit_block(block_root, nonce, gas_price, contract, opts) do
    private_key = Keyword.fetch!(opts, :private_key)
    url = Keyword.fetch!(opts, :url)
    to = contract
    signature = "submitBlock(bytes32)"
    args = [block_root]
    abi_encoded_data = ABI.encode(signature, args)
    opts = [nonce: nonce, gasPrice: gas_price, value: 0, gas: 100_000]
    [nonce: nonce, gasPrice: gas_price, value: value, gas: gas_limit] = opts
    private_key = PrivateKey.get(private_key)

    transaction_data =
      %Transaction{
        data: abi_encoded_data,
        gas_limit: gas_limit,
        gas_price: gas_price,
        init: <<>>,
        nonce: nonce,
        to: to,
        value: value
      }
      |> Signature.sign_transaction(private_key)
      |> Transaction.serialize(true)
      |> ExRLP.encode()
      |> Base.encode16(case: :lower)

    eth_send_raw_transaction("0x" <> transaction_data, url)
  end

  defp eth_send_raw_transaction(transaction_data, url) do
    case Ethereumex.HttpClient.eth_send_raw_transaction(transaction_data, url: url) do
      {:ok, receipt_enc} -> {:ok, from_hex(receipt_enc)}
      other -> other
    end
  end

  defp from_hex("0x" <> encoded), do: Base.decode16!(encoded, case: :lower)
end
