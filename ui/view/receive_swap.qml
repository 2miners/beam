import QtQuick 2.11
import QtQuick.Controls 1.2
import QtQuick.Controls 2.4
import QtQuick.Controls.Styles 1.2
import QtGraphicalEffects 1.0
import QtQuick.Layouts 1.3
import Beam.Wallet 1.0
import "controls"

ColumnLayout {
    id: thisView
    property var defaultFocusItem: receiveAmountInput.amountInput

    ReceiveSwapViewModel {
        id: viewModel
        onNewAddressFailed: {
            thisView.enabled = true
            Qt.createComponent("receive_addrfail.qml")
                .createObject(sendView)
                .open();
        }
    }

    function isValid () {
        if (!viewModel.commentValid) return false
        if (viewModel.receiveCurrency == viewModel.sentCurrency) return false
        return receiveAmountInput.isValid && sentAmountInput.isValid
    }

    function canSend () {
        if (!isValid()) return false;
        if (viewModel.amountToReceive <= 0 || viewModel.amountSent <= 0) return false;
        return true;
    }

    function saveAddress() {
        if (viewModel.commentValid) viewModel.saveAddress()
    }

    Grid {
        Layout.fillWidth: true
        columnSpacing:    70
        columns:          2

        ColumnLayout {
            width: parent.width / 2 - parent.columnSpacing / 2

            //
            // My Address
            //
            SFText {
                font.pixelSize: 14
                font.styleName: "Bold"; font.weight: Font.Bold
                color: Style.content_main
                //% "My address (auto-generated)"
                text: qsTrId("wallet-receive-my-addr-label")
            }

            SFTextInput {
                id:               myAddressID
                Layout.fillWidth: true
                font.pixelSize:   14
                color:            Style.content_disabled
                readOnly:         true
                activeFocusOnTab: false
                text:             viewModel.receiverAddress
            }

            //
            // Amount
            //
            AmountInput {
                Layout.topMargin: 25
                title:            qsTrId("receive-amount-swap-label") //% "Receive amount"
                id:               receiveAmountInput
                hasFee:           true
                currency:         viewModel.receiveCurrency
                amount:           viewModel.amountToReceive
                multi:            true
                currColor:        viewModel.receiveCurrency == viewModel.sentCurrency ? Style.validator_error : Style.content_main
            }

            Binding {
                target:   viewModel
                property: "amountToReceive"
                value:    receiveAmountInput.amount
            }

            Binding {
                target:   viewModel
                property: "receiveCurrency"
                value:    receiveAmountInput.currency
            }

            Binding {
                target:   viewModel
                property: "receiveFee"
                value:    receiveAmountInput.fee
            }

            //
            // Comment
            //
            SFText {
                Layout.topMargin: 40
                font.pixelSize:   14
                font.styleName:   "Bold"; font.weight: Font.Bold
                color:            Style.content_main
                text:             qsTrId("general-comment") //% "Comment"
            }

            SFTextInput {
                id:               addressComment
                font.pixelSize:   14
                Layout.fillWidth: true
                font.italic :     !viewModel.commentValid
                backgroundColor:  viewModel.commentValid ? Style.content_main : Style.validator_error
                color:            viewModel.commentValid ? Style.content_main : Style.validator_error
                focus:            true
                text:             viewModel.addressComment
                maximumLength:    BeamGlobals.maxCommentLength()
            }

            Binding {
                target:   viewModel
                property: "addressComment"
                value:    addressComment.text
            }

            Item {
                Layout.fillWidth: true
                SFText {
                    //% "Address with same comment already exist"
                    text:           qsTrId("general-addr-comment-error")
                    color:          Style.validator_error
                    font.pixelSize: 12
                    font.italic:    true
                    visible:        !viewModel.commentValid
                }
            }
        }

        ColumnLayout {
            width: parent.width / 2 - parent.columnSpacing / 2

            //
            // Sent amount
            //
            AmountInput {
                Layout.topMargin: 84
                title:            qsTrId("sent-amount-label") //% "Sent amount"
                id:               sentAmountInput
                color:            Style.accent_outgoing
                hasFee:           true
                currency:         viewModel.sentCurrency
                amount:           viewModel.amountSent
                multi:            true
                currColor:        viewModel.receiveCurrency == viewModel.sentCurrency ? Style.validator_error : Style.content_main
            }

            Binding {
                target:   viewModel
                property: "amountSent"
                value:    sentAmountInput.amount
            }

            Binding {
                target:   viewModel
                property: "sentCurrency"
                value:    sentAmountInput.currency
            }

            Binding {
                target:   viewModel
                property: "sentFee"
                value:    sentAmountInput.fee
            }

            //
            // Expires
            //
            RowLayout {
                id:      expiresCtrl
                spacing: 10
                property alias title: expiresTitle.text

                SFText {
                    id:               expiresTitle
                    Layout.topMargin: 26
                    font.pixelSize:   14
                    color:            Style.content_main
                    text:             qsTrId("wallet-receive-offer-expires-label")
                }

                CustomComboBox {
                    id:                  expiresCombo
                    Layout.topMargin:    26
                    Layout.minimumWidth: 75
                    height:              20
                    currentIndex:        viewModel.offerExpires

                    model: [
                        //% "12 hours"
                        qsTrId("wallet-receive-expires-12"),
                        //% "6 hours"
                        qsTrId("wallet-receive-expires-6")
                    ]
                }

                Binding {
                    target:   viewModel
                    property: "offerExpires"
                    value:    expiresCombo.currentIndex
                }
            }
        }
    }

    SFText {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 40
        font.pixelSize:   14
        font.styleName:   "Bold"
        font.weight:      Font.Bold
        color:            Style.content_main
        //% Your transaction token:
        text: qsTrId("wallet-receive-your-token")
    }

    SFTextArea {
        Layout.alignment:    Qt.AlignHCenter
        width:               570
        focus:               true
        activeFocusOnTab:    true
        font.pixelSize:      14
        wrapMode:            TextInput.Wrap
        color:               isValid() ? (canSend() ? Style.content_secondary : Qt.darker(Style.content_secondary)) : Style.validator_error
        text:                viewModel.transactionToken
        horizontalAlignment: TextEdit.AlignHCenter
        readOnly:            true
    }

    SFText {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 5
        font.pixelSize:   14
        color:            Style.content_main
        //% Send this token to the sender over an external secure channel
        text: qsTrId("wallet-swap-propogate-addr-message")
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 30
        spacing:          25

        CustomButton {
            //% "Close"
            text: qsTrId("general-close")
            palette.buttonText: Style.content_main
            icon.source: "qrc:/assets/icon-cancel-white.svg"
            onClicked: {
                walletView.pop();
            }
        }

        CustomButton {
            //% "Copy transaction address"
            text: qsTrId("wallet-receive-copy-address")
            palette.buttonText: Style.content_opposite
            icon.color: Style.content_opposite
            palette.button: Style.active
            icon.source: "qrc:/assets/icon-copy.svg"
            onClicked: {
                BeamGlobals.copyToClipboard(viewModel.transactionToken);
                viewModel.startListen();
            }
            enabled: thisView.canSend()
        }
    }

    Row {
        Layout.fillHeight: true
    }
}