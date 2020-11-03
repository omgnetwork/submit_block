# Copyright 2019-2020 OmiseGO Pte Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

defmodule SubmitBlock do
  alias SubmitBlock.Transaction
  alias SubmitBlock.PrivateKey
  alias SubmitBlock.Transaction.Signature

  def opts() do
    [:private_key, :url]
  end

  def enterprise() do
    0
  end

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
