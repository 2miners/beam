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


#include "shared_tx_builder.h"

using namespace ECC;

namespace beam::wallet
{
    SharedTxBuilder::SharedTxBuilder(BaseTransaction& tx, SubTxID subTxID, Amount amount, Amount fee)
        : BaseTxBuilder(tx, subTxID, { amount }, fee)
    {
        InitMinHeight();
    }

    Transaction::Ptr SharedTxBuilder::CreateTransaction()
    {
        LoadPeerOffset();
        return BaseTxBuilder::CreateTransaction();
    }

    Height SharedTxBuilder::GetMaxHeight() const
    {
        return m_MaxHeight;
    }

    bool SharedTxBuilder::GetSharedParameters()
    {
        return m_Tx.GetParameter(TxParameterID::SharedBlindingFactor, m_SharedBlindingFactor, SubTxIndex::BEAM_LOCK_TX)
            && m_Tx.GetParameter(TxParameterID::PeerPublicSharedBlindingFactor, m_PeerPublicSharedBlindingFactor, SubTxIndex::BEAM_LOCK_TX);
    }

    void SharedTxBuilder::InitTx(bool isTxOwner)
    {
        if (isTxOwner)
        {
            // select shared UTXO as input and create output utxo
            InitInput();
            InitOutput();

            if (!FinalizeOutputs())
            {
                // TODO: transaction is too big :(
            }
        }
        else
        {
            // init offset
//            InitOffset();
        }

        GenerateOffset();
    }

    void SharedTxBuilder::InitInput()
    {
        // load shared utxo as input
        Point::Native commitment(Zero);
        Amount amount = m_Tx.GetMandatoryParameter<Amount>(TxParameterID::Amount);
        Tag::AddValue(commitment, nullptr, amount);
        commitment += Context::get().G * m_SharedBlindingFactor;
        commitment += m_PeerPublicSharedBlindingFactor;

        auto& input = m_Inputs.emplace_back(std::make_unique<Input>());
        input->m_Commitment = commitment;
        m_Tx.SetParameter(TxParameterID::Inputs, m_Inputs, false, m_SubTxID);

       // m_Offset += m_SharedBlindingFactor;
    }

    void SharedTxBuilder::InitOutput()
    {
        beam::Coin outputCoin;

        if (!m_Tx.GetParameter(TxParameterID::SharedCoinID, outputCoin.m_ID, m_SubTxID))
        {
            outputCoin = m_Tx.GetWalletDB()->generateSharedCoin(GetAmount());
            m_Tx.SetParameter(TxParameterID::SharedCoinID, outputCoin.m_ID, m_SubTxID);
        }

		Height minHeight = 0;
		m_Tx.GetParameter(TxParameterID::MinHeight, minHeight, m_SubTxID);

        // add output
        Scalar::Native blindingFactor;
        Output::Ptr output = std::make_unique<Output>();
        output->Create(minHeight, blindingFactor, *m_Tx.GetWalletDB()->get_ChildKdf(outputCoin.m_ID.m_SubIdx), outputCoin.m_ID, *m_Tx.GetWalletDB()->get_MasterKdf());

      //  blindingFactor = -blindingFactor;
      //  m_Offset += blindingFactor;

        m_Outputs.push_back(std::move(output));
        m_OutputCoins.push_back(outputCoin.m_ID);
    }

    //void SharedTxBuilder::InitOffset()
    //{
    //    //m_Offset += m_SharedBlindingFactor;
    //    //m_Tx.SetParameter(TxParameterID::Offset, m_Offset, false, m_SubTxID);
    //}

    void SharedTxBuilder::InitMinHeight()
    {
        Height minHeight = 0;
        if (!m_Tx.GetParameter(TxParameterID::MinHeight, minHeight, m_SubTxID))
        {
            // Get MinHeight from main TX
            minHeight = m_Tx.GetMandatoryParameter<Height>(TxParameterID::MinHeight);

            if (SubTxIndex::BEAM_REFUND_TX == m_SubTxID)
            {
                minHeight += kBeamLockTimeInBlocks;
            }
            m_Tx.SetParameter(TxParameterID::MinHeight, minHeight, m_SubTxID);
        }
    }

    void SharedTxBuilder::LoadPeerOffset()
    {
        m_Tx.GetParameter(TxParameterID::PeerOffset, m_PeerOffset, m_SubTxID);
    }
}