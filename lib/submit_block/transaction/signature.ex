defmodule SubmitBlock.Transaction.Signature do
  @moduledoc """
  Defines helper functions for signing and getting the signature
  of a transaction, as defined in Appendix F of the Yellow Paper.

  For any of the following functions, if chain_id is specified,
  it's assumed that we're post-fork and we should follow the
  specification EIP-155 from:

  https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
  Extracted from: https://github.com/exthereum/blockchain
  """

  require Integer

  alias SubmitBlock.Transaction
  alias SubmitBlock.Transaction.Hash

  @type private_key :: <<_::256>>

  @doc """
  Takes a given transaction and returns a version signed
  with the given private key. This is defined in Eq.(216) and
  Eq.(217) of the Yellow Paper.

  ## Examples

      iex> SubmitBlock.Transaction.Signature.sign_transaction(%SubmitBlock.Transaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 5, init: <<1>>}, <<1::256>>)
      %SubmitBlock.Transaction{data: <<>>, gas_limit: 7, gas_price: 6, init: <<1>>, nonce: 5, r: 97037709922803580267279977200525583527127616719646548867384185721164615918250, s: 31446571475787755537574189222065166628755695553801403547291726929250860527755, to: "", v: 27, value: 5}

      iex> SubmitBlock.Transaction.Signature.sign_transaction(%SubmitBlock.Transaction{nonce: 5, gas_price: 6, gas_limit: 7, to: <<>>, value: 5, init: <<1>>}, <<1::256>>, 1)
      %SubmitBlock.Transaction{data: <<>>, gas_limit: 7, gas_price: 6, init: <<1>>, nonce: 5, r: 25739987953128435966549144317523422635562973654702886626580606913510283002553, s: 41423569377768420285000144846773344478964141018753766296386430811329935846420, to: "", v: 38, value: 5}
  """
  @spec sign_transaction(Transaction.t(), private_key, integer() | nil) :: Transaction.t()
  def sign_transaction(trx, private_key, chain_id \\ nil) do
    {v, r, s} =
      trx
      |> Hash.transaction_hash(chain_id)
      |> Hash.sign_hash(private_key, chain_id)

    %{trx | v: v, r: r, s: s}
  end
end
