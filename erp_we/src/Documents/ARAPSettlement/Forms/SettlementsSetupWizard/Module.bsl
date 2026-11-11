
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	OperationKind = Parameters.OperationKind;
	
	OperationKinds = Enums.KindsOfARAPSettlements;
	UseTemplate = ValueIsFilled(OperationKind);
		
	If UseTemplate Then
		
		TypesOfCalculations_ = New Map;
		TypesOfCalculations_.Insert(OperationKinds.SettlementOfPrepaymentBetweenCompanyCounterparty,    0);
		TypesOfCalculations_.Insert(OperationKinds.SettlementOfCustomerPrepaymentBetweenCounterparties,       0);
		TypesOfCalculations_.Insert(OperationKinds.SettlementOfPrepaymentFromCustomerIntercompany,       0);
		TypesOfCalculations_.Insert(OperationKinds.CustomerPrepaymentOffsetBetweenTwoCompanies,  0);
		
		TypesOfCalculations_.Insert(OperationKinds.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty,     1);
		TypesOfCalculations_.Insert(OperationKinds.TransferOfCustomerReceivablesBetweenCounterparties,        1);
		TypesOfCalculations_.Insert(OperationKinds.SettlementOfCustomerARIntercompany,        1);
		TypesOfCalculations_.Insert(OperationKinds.AccountsReceivableOffsetBetweenTwoCompanies,   1);
		
		TypesOfCalculations_.Insert(OperationKinds.SettlementOfVendorBetweenCompanyCounterparty, 2);
		TypesOfCalculations_.Insert(OperationKinds.SettlementOfVendorPrepaymentBetweenCounterparties,    2);
		TypesOfCalculations_.Insert(OperationKinds.SettlementOfPrepaymenToVendortIntercompany,    2);
		TypesOfCalculations_.Insert(OperationKinds.PrepaymentToVendorOffsetBetweenTwoCompanies,2);
		
		TypesOfCalculations_.Insert(OperationKinds.TransferOfAccountsPayableBetweenCompanyAndCounterparty,  3);
		TypesOfCalculations_.Insert(OperationKinds.TransferOfAccountsPayablesBetweenCounterparties,     3);
		TypesOfCalculations_.Insert(OperationKinds.SettlementOfVendorAPIntercompany,     3);
		TypesOfCalculations_.Insert(OperationKinds.AccountsPayableOffsetBetweenTwoCompanies,3);
		
		TypesOfCalculations_.Insert(OperationKinds.Barter,                                       4);
		TypesOfCalculations_.Insert(OperationKinds.ARAPClearingBetweenCompanies,                     4);
		
		TypesOfCalculations_.Insert(OperationKinds.Arbitrary,                                 5);
		
		TypesOfCalculations_.Insert(OperationKinds.RecordOfPaymentThroughTheCommissionAgent,             6);
		TypesOfCalculations_.Insert(OperationKinds.RecordOfRefundThroughTheCommissionAgent,     6);
		
		TypesOfCalculations_.Insert(OperationKinds.PaymentByGiftCard,                 6);
		
		PaymentType_ = TypesOfCalculations_[OperationKind];
		
		ParticipationOptions = New Map;
		ParticipationOptions.Insert(OperationKinds.SettlementOfPrepaymentBetweenCompanyCounterparty,    0);
		ParticipationOptions.Insert(OperationKinds.SettlementOfCustomerPrepaymentBetweenCounterparties,       1);
		ParticipationOptions.Insert(OperationKinds.SettlementOfPrepaymentFromCustomerIntercompany,       2);
		ParticipationOptions.Insert(OperationKinds.CustomerPrepaymentOffsetBetweenTwoCompanies,  3);
		
		ParticipationOptions.Insert(OperationKinds.SettlementOfVendorBetweenCompanyCounterparty, 0);
		ParticipationOptions.Insert(OperationKinds.SettlementOfVendorPrepaymentBetweenCounterparties,    1);
		ParticipationOptions.Insert(OperationKinds.SettlementOfPrepaymenToVendortIntercompany,    2);
		ParticipationOptions.Insert(OperationKinds.PrepaymentToVendorOffsetBetweenTwoCompanies,3);
		
		ParticipationOptions.Insert(OperationKinds.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty,     0);
		ParticipationOptions.Insert(OperationKinds.TransferOfCustomerReceivablesBetweenCounterparties,        1);
		ParticipationOptions.Insert(OperationKinds.SettlementOfCustomerARIntercompany,        2);
		ParticipationOptions.Insert(OperationKinds.AccountsReceivableOffsetBetweenTwoCompanies,   3);
		
		ParticipationOptions.Insert(OperationKinds.TransferOfAccountsPayableBetweenCompanyAndCounterparty,  0);
		ParticipationOptions.Insert(OperationKinds.TransferOfAccountsPayablesBetweenCounterparties,     1);
		ParticipationOptions.Insert(OperationKinds.SettlementOfVendorAPIntercompany,     2);
		ParticipationOptions.Insert(OperationKinds.AccountsPayableOffsetBetweenTwoCompanies,3);
		
		ParticipationOptions.Insert(OperationKinds.RecordOfPaymentThroughTheCommissionAgent,             0);
		ParticipationOptions.Insert(OperationKinds.RecordOfRefundThroughTheCommissionAgent,     1);
		
		ParticipationOptions.Insert(OperationKinds.PaymentByGiftCard,                 2);
		
		ParticipationOptions.Insert(OperationKinds.Barter,                                       0);
		ParticipationOptions.Insert(OperationKinds.ARAPClearingBetweenCompanies,                     3);
		
		ParticipationOption = ParticipationOptions[OperationKind];
		
	EndIf;
	
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	UseSalesCommission = GetFunctionalOption("UseSalesCommission");
	UseGiftCards = GetFunctionalOption("UseGiftCards");
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	If Not UseSalesCommission
		 And Not (NewOnlineARAPAccounting And UseGiftCards)
		 And (PaymentType_ = 6) Then
		PaymentType_ = 0;
	EndIf;

	FormControl();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ClosingInProgress And Modified And Not SaveParameters Then
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		Cancel = True;
		
		Notification   = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Cài đặt sẽ không được thay đổi. Đóng biểu mẫu mà không lưu kết quả?';
						|ru = 'Настройка не будет изменена. Закрыть форму без сохранения результата?';
						|en = 'Setting will not be changed. Close the form without saving the result?'; fa = 'Setting will not be changed. Close the form without saving the result?';
						|it = 'La configurazione non verrà modificata. Chiudere il modello senza salvare il risultato?';
						|pl = 'Ustawienie nie będzie zmienione. Zamknąć formularz bez zapisywania rezultatu?';
						|tr = 'Ayar değiştirilmeyecek. Sonuç kaydedilmeden formu kapat?'");
		
		ShowQueryBox(Notification,QueryText, ButtonsList);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseTemplateOnChange(Item)
	
	FormControl();
	
EndProcedure

&AtClient
Procedure TypeOfCalculationsWhenChanging(Item)
	
	FormControl();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Apply(Command)
	
	If UseTemplate Then
		
		If PaymentType_ = 0 Then // Transfer of the client
			If ParticipationOption = 0 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.SettlementOfPrepaymentBetweenCompanyCounterparty");
			ElsIf ParticipationOption = 1 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.SettlementOfCustomerPrepaymentBetweenCounterparties");
			ElsIf ParticipationOption = 2 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.SettlementOfPrepaymentFromCustomerIntercompany");
			Else
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.CustomerPrepaymentOffsetBetweenTwoCompanies");
			EndIf;
			
		ElsIf PaymentType_ = 1 Then // Transfer of the client's debt
			If ParticipationOption = 0 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCompanyAndCounterparty");
			ElsIf ParticipationOption = 1 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.TransferOfCustomerReceivablesBetweenCounterparties");
			ElsIf ParticipationOption = 2 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany");
			Else
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.AccountsReceivableOffsetBetweenTwoCompanies");
			EndIf;
			
		ElsIf PaymentType_ = 2 Then //TransferOfAdvancePaymentToSupplier
			If ParticipationOption = 0 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.SettlementOfVendorBetweenCompanyCounterparty");
			ElsIf ParticipationOption = 1 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.SettlementOfVendorPrepaymentBetweenCounterparties");
			ElsIf ParticipationOption = 2 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.SettlementOfPrepaymenToVendortIntercompany");
			Else
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.PrepaymentToVendorOffsetBetweenTwoCompanies");
			EndIf;
			
		ElsIf PaymentType_ = 3 Then //Transfer of debt to the supplier
			If ParticipationOption = 0 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.TransferOfAccountsPayableBetweenCompanyAndCounterparty");
			ElsIf ParticipationOption = 1 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.TransferOfAccountsPayablesBetweenCounterparties");
			ElsIf ParticipationOption = 2 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany");
			Else
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.AccountsPayableOffsetBetweenTwoCompanies");
			EndIf;
			
		ElsIf PaymentType_ = 4 Then //Barter
			If ParticipationOption = 0 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.Barter");
			Else
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.ARAPClearingBetweenCompanies");
			EndIf;
		ElsIf PaymentType_ = 6 Then //OtherItems
			If ParticipationOption = 0 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.RecordOfPaymentThroughTheCommissionAgent");
			ElsIf ParticipationOption = 1 Then
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.RecordOfRefundThroughTheCommissionAgent");
			Else
				OperationKind = PredefinedValue(
					"Enum.KindsOfARAPSettlements.PaymentByGiftCard");
			EndIf;
		Else //Arbitrary
			OperationKind = PredefinedValue(
				"Enum.KindsOfARAPSettlements.Arbitrary");
		EndIf;
		
	Else
		
		OperationKind = PredefinedValue("Enum.KindsOfARAPSettlements.Arbitrary");
		
	EndIf;
	
	SaveParameters = True;
	
	Close(OperationKind);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FormControl()
	
	Items.TemplateParameters.Enabled    = UseTemplate;
	Items.DecorationNote.Enabled  = UseTemplate;
	
	ThisIsBarter = (PaymentType_ = 4);
	ItSArbitrary = (PaymentType_ = 5);
	TheseAreOtherOperations = (PaymentType_ = 6);
	
	Items.WithinCounterparty.Visible = Not ItSArbitrary And Not TheseAreOtherOperations;
	Items.BetweenCounterparties.Visible = Not ThisIsBarter And Not ItSArbitrary And Not TheseAreOtherOperations;
	Items.BetweenCompanies.Visible = Not ThisIsBarter And Not ItSArbitrary And UseMultipleCompanies
		And Not TheseAreOtherOperations;
	Items.BetweenOrganizationsWithoutCounterparty.Visible = Not ItSArbitrary And Not TheseAreOtherOperations And NewOnlineARAPAccounting;
	Items.BetweenCommissionAgentAndClient.Visible = UseSalesCommission And TheseAreOtherOperations;
	Items.BetweenCommissionAgentAndClient.Visible = UseSalesCommission And TheseAreOtherOperations;
	Items.BetweenClientAndCommissionAgent.Visible = UseSalesCommission And TheseAreOtherOperations;
	Items.PaymentByRetailGiftCertificate.Visible = NewOnlineARAPAccounting And UseGiftCards And TheseAreOtherOperations;
	Items.Other.Visible = UseSalesCommission
		 Or (NewOnlineARAPAccounting And UseGiftCards); 
	
	Items.DecorationCustom.Visible = ItSArbitrary;
	
	Items.GroupParticipationOption.Title = ?(TheseAreOtherOperations, NStr("vi = 'Dạng giao dịch';
																			|ru = 'Вид операции';
																			|en = 'Transaction type'; fa = 'نوع تراکنش';
																			|it = 'Tipo di operazione';
																			|pl = 'Typ operacji';
																			|tr = 'İşlem türü'"), NStr("vi = 'Các bên khấu trừ';
																											|ru = 'Стороны зачета';
																											|en = 'Offset parties'; fa = 'طرفین تهاتر';
																											|it = 'Tra le parti';
																											|pl = 'Pomiędzy stronami';
																											|tr = 'Mahsup tarafları'"));
	
	If PaymentType_ = 0 Then // Transfer of the client
		If ParticipationOption = 0 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản ứng trước của doanh nghiệp-khách hàng sang đối tượng hạch toán khác.';
												|ru = 'Перенос аванса организации-клиента на другой объект расчетов.';
												|en = 'Customer prepayment offset to another AR/AP object.'; fa = 'Customer prepayment offset to another AR/AP object.';
												|it = 'Перенос аванса организации-клиента на другой объект расчетов.';
												|pl = 'Customer prepayment offset to another AR/AP object.';
												|tr = 'Müşteri iş yeri ön ödemesinin başka alacak/borç muhasebesi nesnesine aktarılması.'");
		ElsIf ParticipationOption = 1 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản ứng trước từ khách hàng sang đối tác khác.';
												|ru = 'Перенос аванса от клиента на другого контрагента.';
												|en = 'Customer prepayment offset to another counterparty.'; fa = 'Customer prepayment offset to another counterparty.';
												|it = 'Trasferimento pagamento anticipato dal cliente ad un altro contragente.';
												|pl = 'Przeniesienie zaliczki od klienta na innego kontrahenta.';
												|tr = 'Diğer cari hesaba istemci avansının transferi.'");
		ElsIf ParticipationOption = 2 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản ứng trước của khách hàng giữa hai doanh nghiệp.';
												|ru = 'Перенос аванса клиента между двумя организациями.';
												|en = 'Customer prepayment offset between two companies.'; fa = 'Customer prepayment offset between two companies.';
												|it = 'Trasferimento del pagamento anticipato del cliente tra due organizzazioni.';
												|pl = 'Przeniesienie zaliczki klienta między dwoma firmami.';
												|tr = 'İki iş yeri arasında istemci avansının transferi.'");
		ElsIf ParticipationOption = 3 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản ứng trước của doanh nghiệp-khách hàng sang đối tượng hạch toán khác.';
												|ru = 'Перенос аванса организации-клиента на другой объект расчетов.';
												|en = 'Customer prepayment offset to another AR/AP object.'; fa = 'Customer prepayment offset to another AR/AP object.';
												|it = 'Перенос аванса организации-клиента на другой объект расчетов.';
												|pl = 'Customer prepayment offset to another AR/AP object.';
												|tr = 'Müşteri iş yeri ön ödemesinin başka alacak/borç muhasebesi nesnesine aktarılması.'");
		EndIf;
		
	ElsIf PaymentType_ = 1 Then // Transfer of the client's debt
		If ParticipationOption = 0 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản nợ của doanh nghiệp-khách hàng sang đối tượng hạch toán khác.';
												|ru = 'Перенос долга организации-клиента на другой объект расчетов.';
												|en = 'AR offset to another AR/AP object.'; fa = 'AR offset to another AR/AP object.';
												|it = 'Перенос долга организации-клиента на другой объект расчетов.';
												|pl = 'AR offset to another AR/AP object.';
												|tr = 'Müşteri iş yeri borcunun başka alacak/borç muhasebesi nesnesine aktarılması.'");
		ElsIf ParticipationOption = 1 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển công nợ khách hàng cho đối tác khác.';
												|ru = 'Перенос долга клиента на другого контрагента.';
												|en = 'Accounts receivable offset to another counterparty.'; fa = 'Accounts receivable offset to another counterparty.';
												|it = 'Trasferimento del debito del cliente ad un altro contragente.';
												|pl = 'Przeniesienie długu klienta na innego kontrahenta.';
												|tr = 'Diğer cari hesaba istemci borcunun transferi.'");
		ElsIf ParticipationOption = 2 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển công nợ của khách hàng giữa hai doanh nghiệp.';
												|ru = 'Перенос долга клиента между двумя организациями.';
												|en = 'Accounts receivable offset between two companies.'; fa = 'Accounts receivable offset between two companies.';
												|it = 'Trasferimento del debito del cliente tra due organizzazioni.';
												|pl = 'Przeniesienie długu klienta między dwoma firmami.';
												|tr = 'İki iş yeri arasında istemci borcunun transferi.'");
		ElsIf ParticipationOption = 3 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản nợ của doanh nghiệp-khách hàng sang đối tượng hạch toán khác.';
												|ru = 'Перенос долга организации-клиента на другой объект расчетов.';
												|en = 'AR offset to another AR/AP object.'; fa = 'AR offset to another AR/AP object.';
												|it = 'Перенос долга организации-клиента на другой объект расчетов.';
												|pl = 'AR offset to another AR/AP object.';
												|tr = 'Müşteri iş yeri borcunun başka alacak/borç muhasebesi nesnesine aktarılması.'");
		EndIf;
		
	ElsIf PaymentType_ = 2 Then //TransferOfAdvancePaymentToSupplier
		If ParticipationOption = 0 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản ứng trước cho nhà cung cấp sang đối tượng hạch toán khác.';
												|ru = 'Перенос аванса поставщику на другой объект расчетов.';
												|en = 'Prepayment to vendor offset to another AR/AP object.'; fa = 'Prepayment to vendor offset to another AR/AP object.';
												|it = 'Trasferimento del pagamento anticipato al fornitore ad un altro oggetto dei calcoli.';
												|pl = 'Przeniesienie zaliczki dla dostawcy na inny obiekt obliczeń.';
												|tr = 'Diğer alacak/borç nesnesine sağlayıcıya avans transferi.'");
		ElsIf ParticipationOption = 1 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản ứng trước cho nhà cung cấp sang đối tác khác.';
												|ru = 'Перенос аванса поставщику на другого контрагента.';
												|en = 'Prepayment to vendor offset to another counterparty.'; fa = 'Prepayment to vendor offset to another counterparty.';
												|it = 'Trasferimento pagamento anticipato al fornitore ad un altro contragente.';
												|pl = 'Przeniesienie zaliczki dostawcy na innego kontrahenta.';
												|tr = 'Diğer cari hesaba sağlayıcıya avans transferi.'");
		ElsIf ParticipationOption = 2 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản ứng trước cho nhà cung cấp giữa các doanh nghiệp.';
												|ru = 'Перенос аванса поставщику между организациями.';
												|en = 'Prepayment to vendor offset between two companies.'; fa = 'Prepayment to vendor offset between two companies.';
												|it = 'Trasferimento pagamento anticipato al fornitore tra organizzazioni.';
												|pl = 'Przeniesienie zaliczki do dostawcy między firmami.';
												|tr = 'İki iş yeri arasında sağlayıcıya avans transferi.'");
		ElsIf ParticipationOption = 3 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển khoản ứng trước cho nhà cung cấp sang đối tượng hạch toán khác.';
												|ru = 'Перенос аванса поставщику на другой объект расчетов.';
												|en = 'Prepayment to vendor offset to another AR/AP object.'; fa = 'Prepayment to vendor offset to another AR/AP object.';
												|it = 'Trasferimento del pagamento anticipato al fornitore ad un altro oggetto dei calcoli.';
												|pl = 'Przeniesienie zaliczki dla dostawcy na inny obiekt obliczeń.';
												|tr = 'Diğer alacak/borç nesnesine sağlayıcıya avans transferi.'");
		EndIf;
		
	ElsIf PaymentType_ = 3 Then //Transfer of debt to the supplier
		If ParticipationOption = 0 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển công nợ cho nhà cung cấp sang đối tượng hạch toán khác.';
												|ru = 'Перенос долга поставщику на другой объект расчетов.';
												|en = 'AP offset to another AR/AP object.'; fa = 'AP offset to another AR/AP object.';
												|it = 'Trasferimento del debito al fornitore ad un altro oggetto dei calcoli.';
												|pl = 'Przeniesienie długu dla dostawcy na inny obiekt obliczeń.';
												|tr = 'Diğer alacak/borç nesnesine sağlayıcıya borç transferi.'");
		ElsIf ParticipationOption = 1 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển công nợ cho nhà cung cấp cho đối tác khác.';
												|ru = 'Перенос долга поставщику на другого контрагента.';
												|en = 'Accounts payable offset to another counterparty.'; fa = 'Accounts payable offset to another counterparty.';
												|it = 'Trasferimento del debito al fornitore ad un altro contragente.';
												|pl = 'Przeniesienie długu do dostawcy na innego kontrahenta.';
												|tr = 'Diğer cari hesaba sağlayıcıya borç transferi.'");
		ElsIf ParticipationOption = 2 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển công nợ cho nhà cung cấp giữa các doanh nghiệp.';
												|ru = 'Перенос долга поставщику между организациями.';
												|en = 'Accounts payable offset between two companies.'; fa = 'Accounts payable offset between two companies.';
												|it = 'Trasferimento del debito al fornitore tra organizzazioni.';
												|pl = 'Przeniesienie długu do dostawcy między firmami.';
												|tr = 'İki iş yeri arasında sağlayıcıya borç transferi.'");
		ElsIf ParticipationOption = 3 Then
			Items.DecorationNote.Title = NStr("vi = 'Chuyển công nợ cho nhà cung cấp sang đối tượng hạch toán khác.';
												|ru = 'Перенос долга поставщику на другой объект расчетов.';
												|en = 'AP offset to another AR/AP object.'; fa = 'AP offset to another AR/AP object.';
												|it = 'Trasferimento del debito al fornitore ad un altro oggetto dei calcoli.';
												|pl = 'Przeniesienie długu dla dostawcy na inny obiekt obliczeń.';
												|tr = 'Diğer alacak/borç nesnesine sağlayıcıya borç transferi.'");
		EndIf;
		
	ElsIf PaymentType_ = 4 Then //Barter
		If ParticipationOption = 3 Then
			Items.DecorationNote.Title = NStr("vi = 'Hạch toán công nợ phải thu, công nợ phải trả của doanh nghiệp với doanh nghiệp khác.';
												|ru = 'Взаимозачет дебиторской и кредиторской задолженности организации перед другой организацией.';
												|en = 'Offset of AR/AP of one company to another company.'; fa = 'Offset of AR/AP of one company to another company.';
												|it = 'Взаимозачет дебиторской и кредиторской задолженности организации перед другой организацией.';
												|pl = 'Offset of AR/AP of one company to another company.';
												|tr = 'Bir iş yerinin başka bir iş yerine olan alacak ve borç hesaplarının mahsup edilmesi.'");
		Else
			ParticipationOption = 0;
			Items.DecorationNote.Title = NStr("vi = 'Khấu trừ các tài khoản phải trả của doanh nghiệp cho đối tác với tư cách là nhà cung cấp và các khoản phải thu của đối tác với tư cách là khách hàng của doanh nghiệp.';
												|ru = 'Взаимозачет кредиторской задолженности организации перед контрагентом как поставщиком и дебиторской задолженности контрагента как клиента перед организацией.';
												|en = 'Offset company accounts payable to the counterparty as a vendor and counterparty receivable as a customer to the company.'; fa = 'Offset company accounts payable to the counterparty as a vendor and counterparty receivable as a customer to the company.';
												|it = 'Compensazione dei debiti della società verso il contraente-fornitore e dei crediti del contraente come cliente della società.';
												|pl = 'Kompensata zobowiązań firmy przed kontrahentem jako dostawcą i należności kontrahenta jako klienta przed firmą.';
												|tr = 'İş yeri tedarikçi olarak cari hesaba olan borçlarının ve istemci olarak cari hesabın iş yerine olan alacaklarının uzlaşması.'");
		EndIf;
		
	ElsIf PaymentType_ = 5 Then //Arbitrary
		Items.DecorationNote.Title = NStr("vi = 'Tùy chỉnh khấu trừ tùy ý.';
											|ru = 'Произвольные настройки взаимозачета.';
											|en = 'Arbitrary settlement settings.'; fa = 'Arbitrary settlement settings.';
											|it = 'Произвольные настройки взаимозачета.';
											|pl = 'Arbitrary settlement settings.';
											|tr = 'İsteğe bağlı mahsup ayarları.'");
		
	ElsIf PaymentType_ = 6 Then //OtherItems
		If ParticipationOption > 2 Then
			ParticipationOption = 0;
		EndIf;
		Items.DecorationNote.Title = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = "Close" Then
		ClosingInProgress = True;
		Close();
	EndIf;
	
EndProcedure

#EndRegion
