#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	// Skip the processing to ensure that the shape of the object is received when passing the "AutoTest" parameter.
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	NotCheckedAttributeArray.Add("BankAccount");
	
	If Not ValueIsFilled(BankAccount) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Tài khoản ngân hàng để trích"".';
						|ru = 'Поле ""Банковский счет для зачисления"" не заполнено';
						|en = 'The ""Bank account for payouts"" field is not filled in'; fa = 'The ""Bank account for payouts"" field is not filled in';
						|it = 'Поле ""Банковский счет для зачисления"" не заполнено';
						|pl = 'The ""Bank account for payouts"" field is not filled in';
						|tr = '""Tahakkuk için banka hesabı"" alanı doldurulmadı'");
		Common.MessageToUser(ErrorText, , "Object.BankAccount", , Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray.Add("Partner");
	
	If Not ValueIsFilled(Partner) Then
		
		ErrorText = NStr("vi = 'Chưa điền trường ""Ngân hàng thanh toán"".';
						|ru = 'Поле ""Эквайер"" не заполнено';
						|en = '""Acquirer"" is required'; fa = '""Acquirer"" is required';
						|it = 'Поле ""Эквайер"" не заполнено';
						|pl = '""Acquirer"" is required';
						|tr = '""Alıcı banka"" alanı doldurulmadı'");
		Common.MessageToUser(ErrorText, , "Object.Partner", , Cancel);
		
	EndIf;
	
	If Not KeepRecordsOfCommissionInARAPAccounting Then
		NotCheckedAttributeArray.Add("CommissionARAPObject");
	EndIf;

	If AdditionalProperties.Property("ExcludeVerificationOfFillingInARAPObjectOfFee")
		And AdditionalProperties.ExcludeVerificationOfFillingInARAPObjectOfFee Then
		NotCheckedAttributeArray.Add("CommissionARAPObject");
	EndIf;

	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	If PaymentInOnlineStore And Not ValueIsFilled(OnlineStoreAddress) Then
		ErrorText = NStr("vi = 'Trong trường hợp đặt dấu hộp kiểm ""Thanh toán trong cửa hàng trực tuyến"", cần điền trường ""Địa chỉ cửa hàng trực tuyến""';
						|ru = 'В случае установки флага ""Оплата в интернет-магазине"" поле ""Адрес интернет-магазина"" должно быть заполнено';
						|en = 'If the ""Payment in online store"" checkbox is selected, the ""Online store address"" field is required'; fa = 'If the ""Payment in online store"" checkbox is selected, the ""Online store address"" field is required';
						|it = 'If the ""Payment in online store"" checkbox is selected, the ""Online store address"" field is required';
						|pl = 'If the ""Payment in online store"" checkbox is selected, the ""Online store address"" field is required';
						|tr = '""İnternet mağazasında ödeme"" seçeneği işaretlendiğinde, ""İnternet mağazasının adresi"" alanı doldurulmalıdır.'");
		Common.MessageToUser(ErrorText, , "Object.OnlineStoreAddress", , Cancel);
	EndIf;
	
	If ValueIsFilled(OnlineStoreAddress) 
		And TMCommonUseClientServer.CheckSiteAddress(OnlineStoreAddress) Then
			ErrorText = NStr("vi = 'Sai định dạng cửa hàng trực tuyến';
							|ru = 'Неверный формат адреса интернет-магазина';
							|en = 'Incorrect format of online store address'; fa = 'Incorrect format of online store address';
							|it = 'Incorrect format of online store address';
							|pl = 'Incorrect format of online store address';
							|tr = 'Yanlış internet mağazası adresi formatı'");
			Common.MessageToUser(ErrorText, , "Object.OnlineStoreAddress", "Object", Cancel);
	EndIf;
	
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TypesDetailsBoolean = New TypeDescription("Boolean");
	FiscalReceiptsAreGeneratedByPaymentSystem = TypesDetailsBoolean.AdjustValue(FiscalReceiptsAreGeneratedByPaymentSystem);

	POSTerminalsAreUsed = (MakingPaymentMethod = Enums.MakingPaymentMethods.POSTerminal);

	If Not FixedFeeRate Then
		CommissionRate = 0;
	EndIf;
	
	If CommissionPostingMethod = Enums.MethodsOfAcquiringCommissionRecording.InReport Then
		FeeIsChargedOnRefund = False;
	EndIf;
	
	If Not (MakingPaymentMethod = PredefinedValue("Enum.MakingPaymentMethods.InternetAcquiring")
		Or MakingPaymentMethod = PredefinedValue("Enum.MakingPaymentMethods.InstantPayments")) Then
		PaymentInOnlineStore = False;
		OnlineStoreAddress = "";
	EndIf;
	
	If KeepRecordsOfCommissionInARAPAccounting Then
		ExpensesBusinessUnit = Catalogs.BusinessStructure.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		ExpenseItem = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
		DimensionOfExpenses = Undefined;
	Else
		CommissionARAPObject = Catalogs.ARAPObjects.EmptyRef();
	EndIf;
	
EndProcedure

#EndRegion

#EndIf