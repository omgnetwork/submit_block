defmodule SubmitBlock.BitHelper do
  @moduledoc """
  Helpers for common operations on the blockchain.
  Extracted from: https://github.com/exthereum/blockchain
  """

  use Bitwise

  @type keccak_hash :: binary()

  @doc """
  Returns the keccak sha256 of a given input.

  ## Examples

      iex> SubmitBlock.BitHelper.kec("hello world")
      <<71, 23, 50, 133, 168, 215, 52, 30, 94, 151, 47, 198, 119, 40, 99,
             132, 248, 2, 248, 239, 66, 165, 236, 95, 3, 187, 250, 37, 76, 176,
             31, 173>>

      iex> SubmitBlock.BitHelper.kec(<<0x01, 0x02, 0x03>>)
      <<241, 136, 94, 218, 84, 183, 160, 83, 49, 140, 212, 30, 32, 147, 34,
             13, 171, 21, 214, 83, 129, 177, 21, 122, 54, 51, 168, 59, 253, 92,
             146, 57>>
  """
  @spec kec(binary()) :: keccak_hash
  def kec(data) do
    {:ok, hash} = ExKeccak.hash_256(data)

    hash
  end

  @doc """
  Similar to `:binary.encode_unsigned/1`, except we encode `0` as
  `<<>>`, the empty string. This is because the specification says that
  we cannot have any leading zeros, and so having <<0>> by itself is
  leading with a zero and prohibited.

  ## Examples

      iex> SubmitBlock.BitHelper.encode_unsigned(0)
      <<>>

      iex> SubmitBlock.BitHelper.encode_unsigned(5)
      <<5>>

      iex> SubmitBlock.BitHelper.encode_unsigned(5_000_000)
      <<76, 75, 64>>
  """
  @spec encode_unsigned(non_neg_integer()) :: binary()
  def encode_unsigned(0), do: <<>>
  def encode_unsigned(n), do: :binary.encode_unsigned(n)
end
