// Copyright 2019 The Beam Team
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#pragma once

#include "utility/io/address.h"
#include "utility/common.h"
#include "wallet/common.h"

namespace beam
{
    struct BitcoindSettings
    {
        std::string m_userName;
        std::string m_pass;
        io::Address m_address;
    };

    class IBitcoinSettings
    {
    public:
        using Ptr = std::shared_ptr<IBitcoinSettings>;
        
        virtual ~IBitcoinSettings() {};

        virtual const BitcoindSettings& GetConnectionOptions() const = 0;
        virtual Amount GetFeeRate() const = 0;
        virtual uint16_t GetTxMinConfirmations() const = 0;
        virtual uint32_t GetLockTimeInBlocks() const = 0;
        virtual wallet::SwapSecondSideChainType GetChainType() const = 0;
    };

    class BitcoinSettings : public IBitcoinSettings
    {
    public:
        BitcoinSettings() = default;

        const BitcoindSettings& GetConnectionOptions() const override;
        Amount GetFeeRate() const override;
        uint16_t GetTxMinConfirmations() const override;
        uint32_t GetLockTimeInBlocks() const override;
        wallet::SwapSecondSideChainType GetChainType() const override;

        void SetConnectionOptions(const BitcoindSettings& connectionSettings);
        void SetFeeRate(Amount feeRate);
        void SetTxMinConfirmations(uint16_t txMinConfirmations);
        void SetLockTimeInBlocks(uint32_t lockTimeInBlocks);
        void SetChainType(wallet::SwapSecondSideChainType chainType);

    private:
        BitcoindSettings m_connectionSettings;
        Amount m_feeRate = 0;
        uint16_t m_txMinConfirmations = 6;
        wallet::SwapSecondSideChainType m_chainType = wallet::SwapSecondSideChainType::Mainnet;
        uint32_t m_lockTimeInBlocks = 2 * 24 * 6;
    };
}