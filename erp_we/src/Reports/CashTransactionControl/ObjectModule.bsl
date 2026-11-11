#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(UserSettingsModified);
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion


#Region Private

Procedure SetRequiredSettings(UserSettingsModified)
	
	// String literals
	DataCompositionClientServer.SetParameter(SettingsComposer, "CheckoutLine",                           NStr("vi = 'Quỹ tiền mặt';
																												|ru = 'Касса';
																												|en = 'Cash account'; fa = 'صندوق';
																												|it = 'Cassa';
																												|pl = 'Cash account';
																												|tr = 'Kasa hesabı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineBank",                            NStr("vi = 'Ngân hàng';
																											|ru = 'Банк';
																											|en = 'Bank'; fa = 'بانک';
																											|it = 'Banca';
																											|pl = 'Bank';
																											|tr = 'Banka'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineBankCashier",                       NStr("vi = 'Ngân hàng hoặc tiền mặt';
																											|ru = 'Банк или касса';
																											|en = 'Bank or cash account'; fa = 'Bank or cash account';
																											|it = 'Banca oppure conto di cassa';
																											|pl = 'Bank lub kasa';
																											|tr = 'Banka veya kasa'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "PaymentCardLine",                  NStr("vi = 'Thẻ thanh toán';
																										|ru = 'Платежная карта';
																										|en = 'Payment card'; fa = 'کارت پرداخت';
																										|it = 'Carta di pagamento';
																										|pl = 'Karta płatnicza';
																										|tr = 'Ödeme kartı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "ReportCardLine",                     NStr("vi = 'Người nhận tạm ứng';
																											|ru = 'Подотчетник';
																											|en = 'Advance holder'; fa = 'تنخواه‌دار';
																											|it = 'Titolare di anticipo';
																											|pl = 'Advance holder';
																											|tr = 'Avans sahibi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "WarehouseLine",                           NStr("vi = 'Kho bãi';
																												|ru = 'Склад';
																												|en = 'Warehouse'; fa = 'Warehouse';
																												|it = 'Magazzino';
																												|pl = 'Warehouse';
																												|tr = 'Ambar'"));
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineCash",                        NStr("vi = 'Tiền mặt';
																										|ru = 'Наличные';
																										|en = 'Cash'; fa = 'صندوق';
																										|it = 'Contanti';
																										|pl = 'Cash';
																										|tr = 'Nakit'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "NonCashLine",                     NStr("vi = 'Chuyển khoản';
																										|ru = 'Безналичные';
																										|en = 'Bank account'; fa = 'حساب بانکی';
																										|it = 'Cashless';
																										|pl = 'Bank account';
																										|tr = 'Elektronik'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineCashHeldByAccountablePersons",         NStr("vi = 'Tiền mặt tại chỗ người nhận tạm ứng';
																												|ru = 'Наличные у подотчетных лиц';
																												|en = 'Cash of advance holders'; fa = 'وجه نقد تنخواه‌داران';
																												|it = 'Contanti presso i titolari d''anticipo';
																												|pl = 'Gotówka u osób odpowiedzialnych';
																												|tr = 'Sorumlu kişilerde nakit'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "LineAdvancesIssued",                  NStr("vi = 'Tạm ứng';
																											|ru = 'Выданные авансы';
																											|en = 'Prepayments to vendor'; fa = 'پیش‌پرداخت‌ها به تأمین‌کننده';
																											|it = 'I pagamenti anticipati effettuati';
																											|pl = 'Wydane zaliczki';
																											|tr = 'Verilen avanslar'"));
	
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextCashConversion",      NStr("vi = 'Đổi tiền mặt';
																											|ru = 'Конвертация наличной валюты';
																											|en = 'Conversion of currency in cash'; fa = 'تبدیل ارز نقدی';
																											|it = 'Conversione della valuta disponibile';
																											|pl = 'Przewalutowanie waluty w gotówce';
																											|tr = 'Nakit para birimi dönüştürücüsü'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextElectronicConversion",   NStr("vi = 'Thu tiền đã chuyển đổi ngoại tệ sang tài khoản';
																											|ru = 'Поступление сконвертированной безналичной валюты на счет';
																											|en = 'Receipt of converted electronic currency to account'; fa = 'دریافت ارز الکترونیکی تبدیل‌شده به حساب';
																											|it = 'Versamento della valuta convertita non in contanti sul conto';
																											|pl = 'Wpływ skonwertowanej waluty bezgotówkowej na konto';
																											|tr = 'Hesaba dönüştürülen gayri nakdi para biriminin girişi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextAcquiringInpayment",     NStr("vi = 'Thu từ ngân hàng theo hệ thống thẻ thanh toán';
																											|ru = 'Поступление от банка по эквайрингу';
																											|en = 'POS-related inflow from bank'; fa = 'ورود وجه از بانک مرتبط با POS';
																											|it = 'Versamento dalla banca in base all''acquiring';
																											|pl = 'Wpływ z banku z acquiringu';
																											|tr = 'Bankadan PoS ile ilgili giriş'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextAcquiringPayment",          NStr("vi = 'Nhận thanh toán từ khách hàng bằng thẻ thanh toán';
																												|ru = 'Оплата от клиента платежной картой';
																												|en = 'Payment from customer by payment card'; fa = 'دریافت از مشتری با کارت پرداخت';
																												|it = 'Pagamento dal cliente con la carta di pagamento';
																												|pl = 'Płatność od klienta kartą płatniczą';
																												|tr = 'Müşteri ödeme kartından ödeme'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextAcquiringReturn",         NStr("vi = 'Trả lại tiền theo thẻ thanh toán';
																												|ru = 'Возврат оплаты по платежной карте';
																												|en = 'Return payment by payment card'; fa = 'مرجوعی پرداخت با کارت پرداخت';
																												|it = 'Restituzione del pagamento effettuato con la carta di pagamento';
																												|pl = 'Zwrot płatności w wypadku płatności kartą płatniczą';
																												|tr = 'Ödeme kartı kapsamında ödeme iadesi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextIssueExpenseAdvance",           NStr("vi = 'Thanh toán tạm ứng';
																													|ru = 'Выдача аванса';
																													|en = 'Advance payment issue'; fa = 'Advance payment issue';
																													|it = 'Rilascio del pagamento anticipato';
																													|pl = 'Emisja zaliczki';
																													|tr = 'Avans verilmesi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextPlacingToAnotherAccount",   NStr("vi = 'Tính khi chuyển tiền sang tài khoản khác';
																												|ru = 'Зачисление при перечислении на другой счет';
																												|en = 'Bank receipt in case of transfer to other account'; fa = 'دریافت بانکی در صورت انتقال به حساب دیگر';
																												|it = 'Accredito al momento di versamento su un altro conto';
																												|pl = 'Zasilenie rachunku w wypadku przelewu na inny rachunek';
																												|tr = 'Başka bir hesaba aktarırken tahakkuk'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextTransferBetweenCashAccounts",  NStr("vi = 'Chuyển tiền giữa các quỹ tiền mặt của doanh nghiệp';
																													|ru = 'Перемещение ДС между кассами организации';
																													|en = 'Cash transfer between company cash accounts'; fa = 'انتقال وجه نقد بین صندوق‌های شرکت';
																													|it = 'Trasferimento del denaro tra le casse dell''azienda';
																													|pl = 'Przepływ środków pieniężnych pomiędzy kasami firmami';
																													|tr = 'İş yeri kasaları arasında nakit transferi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextTransferFromTheCashAccountToTheBank",  NStr("vi = 'Chuyển tiền từ quỹ vào ngân hàng';
																															|ru = 'Передача наличных из кассы в банк';
																															|en = 'Cash transfer from cash account to the bank'; fa = 'Cash transfer from cash account to the bank';
																															|it = 'Trasferimento dei contanti disponibile dalla cassa alla banca';
																															|pl = 'Przesyłanie gotówki z kasy do banku';
																															|tr = 'Kasadan bankaya nakit transferi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextTransferFromTheBankToTheCashAccount", NStr("vi = 'Rút tiền mặt từ ngân hàng vào quỹ tiền mặt';
																															|ru = 'Получение наличных из банка в кассу';
																															|en = 'Cash receipt from bank to cash account'; fa = 'دریافت وجه نقد از بانک به صندوق';
																															|it = 'Ricevimento dei contanti dalla banca al conto di cassa';
																															|pl = 'Inkasowanie środków pieniężnych z banku do kasy';
																															|tr = 'Bankadan kasaya nakit alımı'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextTransferFromCashRegister",    NStr("vi = 'Rút tiền từ quầy thu ngân';
																													|ru = 'Выемка ДС из кассы ККМ';
																													|en = 'Take cash out of cash register'; fa = 'برداشت وجه نقد از صندوق فروش';
																													|it = 'Prelievo del denaro dal registratore di cassa';
																													|pl = 'Wyjęcie środków pieniężnych z kasy';
																													|tr = 'Yazar kasa hesabından nakit para çekimi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TransactionTextTransferToCashRegister",     NStr("vi = 'Nhập tiền vào quầy thu ngân';
																												|ru = 'Внесение ДС в кассу ККМ';
																												|en = 'Deposit cash into cash register'; fa = 'واریز وجه نقد به صندوق فروش';
																												|it = 'Versamento del denaro nella cassa fiscale';
																												|pl = 'Wprowadzenie środków pieniężnych do kasy';
																												|tr = 'Yazar kasa hesabından nakit para girişi'"));
	DataCompositionClientServer.SetParameter(SettingsComposer, "TextOfOperationCreditingToIndividual",NStr("vi = 'Chuyển tiền cho cá nhân';
																											|ru = 'Перечисление физическим лицам';
																											|en = 'Transfer to persons'; fa = 'انتقال به اشخاص';
																											|it = 'Ricalcolo alle persone fisiche';
																											|pl = 'Przelew osobom fizycznym';
																											|tr = 'Gerçek kişilere transfer'"));
	
EndProcedure

Function AuxiliaryReportParameters()
	
	AuxiliaryParameters = New Array;
	
	AuxiliaryParameters.Add("DetailedDisplayOfSendersRecipients");
	AuxiliaryParameters.Add("DateAndTimeOfOperation_");
	
	DataCompositionServer.AddAuxiliaryReportParametersForFunctionalOptions(AuxiliaryParameters);
	
	Return AuxiliaryParameters;

EndFunction

#EndRegion

#EndIf