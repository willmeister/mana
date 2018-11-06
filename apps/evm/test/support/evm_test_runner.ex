defmodule EvmTestRunner do
  import ExthCrypto.Math, only: [hex_to_bin: 1, hex_to_int: 1]

  alias EVM.Mock.{MockAccountRepo, MockBlockHeaderInfo}

  def run(json) do
    exec_env = get_exec_env(json)
    gas = hex_to_int(json["exec"]["gas"])
    EVM.VM.run(gas, exec_env)
  end

  defp get_exec_env(json) do
    %EVM.ExecEnv{
      account_repo: account_repo(json),
      address: hex_to_bin(json["exec"]["address"]),
      block_header_info: block_header_info(json),
      data: hex_to_bin(json["exec"]["data"]),
      gas_price: hex_to_bin(json["exec"]["gasPrice"]),
      machine_code: hex_to_bin(json["exec"]["code"]),
      originator: hex_to_bin(json["exec"]["origin"]),
      sender: hex_to_bin(json["exec"]["caller"]),
      value_in_wei: hex_to_bin(json["exec"]["value"])
    }
  end

  defp block_header_info(json) do
    genisis_block_header = %Block.Header{
      number: 0,
      mix_hash: 0
    }

    first_block_header = %Block.Header{
      number: 1,
      mix_hash: 0xC89EFDAA54C0F20C7ADF612882DF0950F5A951637E0307CDCB4C672F298B8BC6
    }

    second_block_header = %Block.Header{
      number: 2,
      mix_hash: 0xAD7C5BEF027816A800DA1736444FB58A807EF4C9603B7848673F7E3A68EB14A5
    }

    parent_block_header = %Block.Header{
      number: hex_to_int(json["env"]["currentNumber"]) - 1,
      mix_hash: 0x6CA54DA2C4784EA43FD88B3402DE07AE4BCED597CBB19F323B7595857A6720AE
    }

    last_block_header = %Block.Header{
      number: hex_to_int(json["env"]["currentNumber"]),
      timestamp: hex_to_int(json["env"]["currentTimestamp"]),
      beneficiary: hex_to_bin(json["env"]["currentCoinbase"]),
      mix_hash: 0,
      parent_hash: hex_to_int(json["env"]["currentNumber"]) - 1,
      gas_limit: hex_to_int(json["env"]["currentGasLimit"]),
      difficulty: hex_to_int(json["env"]["currentDifficulty"])
    }

    block_map = %{
      genisis_block_header.mix_hash => genisis_block_header,
      first_block_header.mix_hash => first_block_header,
      second_block_header.mix_hash => second_block_header,
      parent_block_header.mix_hash => parent_block_header,
      last_block_header.mix_hash => last_block_header
    }

    MockBlockHeaderInfo.new(
      last_block_header,
      block_map
    )
  end

  defp account_repo(json) do
    account_map = %{
      hex_to_bin(json["exec"]["caller"]) => %{
        balance: 0,
        code: <<>>,
        nonce: 0,
        storage: %{}
      }
    }

    account_map =
      Enum.reduce(json["pre"], account_map, fn {address, account}, address_map ->
        storage =
          account["storage"]
          |> Enum.into(%{}, fn {key, value} ->
            {hex_to_int(key), hex_to_int(value)}
          end)

        Map.merge(address_map, %{
          hex_to_bin(address) => %{
            balance: hex_to_int(account["balance"]),
            code: hex_to_bin(account["code"]),
            nonce: hex_to_int(account["nonce"]),
            storage: storage
          }
        })
      end)

    contract_result = %{
      gas: 0,
      sub_state: %EVM.SubState{},
      output: <<>>
    }

    MockAccountRepo.new(
      account_map,
      contract_result
    )
  end
end
