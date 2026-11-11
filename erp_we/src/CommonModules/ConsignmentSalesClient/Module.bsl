////////////////////////////////////////////////////////////////////////////////////////
// The "Commission Trading Client" module contains procedures and functions for 
// processing user actions in the process of working with commission trading documents.
//
////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region EventHandlersForFormElements

// Procedure - the event handler "primeneniy the fields of Showcandidate".
//
// Parameters:
//  Object - FormDataCollection - the object in the form of which the handler is called.
//  VATPercentage - Number - the value of the VAT percentage to fill in.
//
Procedure VATRateOfRemunerationOnChange(Object, VATPercentage) Export
	
	VATPercentage = VATAccountingERPClientServer.ValueOfVATRate(Object.VATRateOfRemuneration);
	CalculateCommissionFeeVAT(Object, VATPercentage);
	
EndProcedure

// Procedure-handler of the event " when Changing "of the" sales Amount " field in the table.
//
// Parameters:
//  TableRow - FormDataCollectionItem - row in the table to complete the fields if you change the amount.
//  ThereIsVATSaleAmount - Boolean - True if the line table has a field of Compromisings.
//  NameOfSalesAmountColumn - String - name of the amount column.
//
Procedure SaleAmountWhenChanged(TableRow, ThereIsVATSaleAmount, NameOfSalesAmountColumn = "SalesAmount") Export
	
	TableRow.SellingPrice = ?(TableRow.NumberOfPackages <> 0, Round(TableRow[NameOfSalesAmountColumn] / TableRow.NumberOfPackages, 2, 1), 0);
	If ThereIsVATSaleAmount Then
		TableRow.AmountSalesVAT = AmountSalesVAT(TableRow[NameOfSalesAmountColumn], TableRow.VATRate);
	EndIf;
	
EndProcedure

// Procedure-handler of the event" when Changing "the" Packing " field of the table.
//
// Parameters:
//  Object - FormDataCollection - the object in the form of which the handler is called.
//  CurrentRow - FormDataCollectionItem - table row for filling in the fields when changing the packaging.
//  ToUseTermsOfSales - Boolean - True if agreements with the client are used.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure CommissionAgentSReportGoodsPackagingWhenChanged(Object, CurrentRow, ToUseTermsOfSales, CachedValues) Export

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	If CurrentRow.Count > 0 Then
		StructureOfActions.Insert("RecalculatePricePerPackage", CurrentRow.Count);
	ElsIf ToUseTermsOfSales And ValueIsFilled(Object.Terms) Then
		StructureOfActions.Insert(
		   "FillIn_TermsOfSales", 
		   BatchProcessingOfTablePartClientServer.GetStructureForFillingInSalesConditionsInTSLine(Object));
	ElsIf ValueIsFilled(CurrentRow.PriceKind) Then
		StructureOfActions.Insert(
		   "FillInSalePrice",
		   BatchProcessingOfTablePartClientServer.ParametersForFillingInPriceInTSLine(Object));
	EndIf;
	
	StructureOfActions.Insert("FillInVATRateByPriceType", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRateByPriceType(Object));
	
	StructureOfActions.Insert("RecalculateVATAmount", 
	   BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object));
	StructureOfActions.Insert("RecalculateAmount");
	StructureOfActions.Insert("RecalculateAmountWithVAT", New Structure("PriceIncludesVAT", Object.PriceIncludesVAT));
	StructureOfActions.Insert("RecalculateSalePricePerPackage");
	StructureOfActions.Insert("RecalculateSaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Partner");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

// Procedure-handler of the event " when Changing "of the" quantity of Packages " field in the table.
//
// Parameters:
//  Object - FormDataCollection - the object in the form of which the handler is called.
//  CurrentRow - FormDataCollectionItem - table row for filling in fields when changing the number of packages.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure CommissionAgentSReportGoodsNumberOfPackagesWhenChanged(Object, CurrentRow, CachedValues) Export
	
	If Object.ByPhysicalCountResults Then
		CurrentRow.NumberOfPackagesReal = CurrentRow.NumberOfPackagesAccounting - CurrentRow.NumberOfPackages;
	EndIf;
	
	StructureOfActions = New Structure;
	SelfServiceClientServer.AddCommissionAgentSReportToActionStructureWhenChangingNumberOfPackages(StructureOfActions, Object);
	
	AccountingForTraceableGoodsClientServerLocalization.AddDescriptionOfSettingsForRecalculatingDetailsOfTablePart(
		Object,
		StructureOfActions,
		"Partner");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

// Procedure-handler of the event " when Changing "of the" sales Price " field in the table.
//
// Parameters:
//  CurrentRow - FormDataCollectionItem - a table row for filling in fields when the sales price changes.
//  CachedValues - Structure - saved values of parameters used during processing.
//
Procedure CommissionAgentSReportProductsSalePriceWhenChanged(CurrentRow, CachedValues) Export

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateSaleAmount");
	StructureOfActions.Insert("RecalculateVATSalesAmount");
	StructureOfActions.Insert("ClearRewardAmount");

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

#EndRegion

#Region ProceduresAndFunctionsForCheckingAbilityToPerformActions

// The procedure determines whether the Commission fee should be calculated.
//
// Parameters:
//  CallbackDescription - CallbackDescription - called after calculating the need to calculate the reward.
//  Form - ClientApplicationForm - the form in which the procedure is called.
//
Procedure YouNeedToCalculateReward(CallbackDescription, Form) Export
	
	CommissionFeeCalculationMethod = Form.Object.CommissionFeeCalculationMethod;
	CalculationMethodAmount = CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.ArbitraryAmount");
	MethodOfCalculationPercentage = CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.PercentageOfDifferenceBetweenSaleAmountAndConsignorAmount")
			Or CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.SaleShare");
	
	If (CalculationMethodAmount And Form.Object.CommissionAmount = 0) Or (MethodOfCalculationPercentage And Form.Object.RemunerationPercentage = 0)
		Or CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
			
		If TypeOf(CallbackDescription.AdditionalParameters) = Type("Structure") Then
			CallbackDescription.AdditionalParameters.Insert("ClearCommission", True);
		EndIf;
			
		YouNeedToClearCommissionFee(CallbackDescription, Form);
	Else
		ItIsNecessaryToCalculateCommission(CallbackDescription, Form);
	EndIf;
	
EndProcedure

// The procedure displays messages to the user if the filling was not completed.
//
// Parameters:
//	Object - FormDataStructure - The Cur object contains, among other things:
//	* Ref - DocumentRef.ConsignmentReportToVendor, DocumentRef.PurchaseInvoiceConsignmentStockLost - link to the document
//
Procedure CheckDocumentCompletionByBalances(Object) Export
	
	If Object.Goods.Count() = 0 Then
	   
		If TypeOf(Object.Ref) = Type("DocumentRef.ConsignmentReportToVendor") Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có dữ liệu bán hàng của người đặt ký gửi ""%1""';
					|ru = 'Нет данных о продажах товаров комитента ""%1""';
					|en = 'No data about ""%1"" consignor goods sales'; fa = 'No data about ""%1"" consignor goods sales';
					|it = 'Non ci sono dati sulle vendite di beni di capitale ""%1""';
					|pl = 'Brak danych o sprzedaży towarów komitenta ""%1""';
					|tr = 'Gönderici ""%1"" ürünleri için satış verisi yok'"),
				Object.Partner);
		ElsIf TypeOf(Object.Ref) = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không có dữ liệu ghi giảm của người đặt ký gửi ""%1""';
					|ru = 'Нет данных о списании товаров комитента ""%1""';
					|en = 'No data about ""%1"" consignor goods write-off'; fa = 'No data about ""%1"" consignor goods write-off';
					|it = 'Non ci sono dati sulla cancellazione di beni di capitale ""%1""';
					|pl = 'Brak danych o wyksięgowaniu towarów komitenta ""%1""';
					|tr = 'Gönderici ""%1"" ürünleri için gider yazma verisi yok'"),
				Object.Partner);
		Else
			Text = "";
		EndIf;
				
		If Not IsBlankString(Text) Then
			CommonClientServer.MessageToUser(
				Text,
				Object.Ref,
				, // Field
				// Refusal
			);
		EndIf;
	   
	EndIf;
	
EndProcedure

// Checks whether the Bank details required for conversion from currency to currency are filled in
//
// Parameters:
// 	CallbackDescription - CallbackDescription - 
// 	Object - DocumentObject - object that checks are performed on
// 	OldCurrency - CatalogRef.Currencies - The previous currency of the document.
// NameOfSalesAmountColumn - String - name of the column that contains the sales amount.
//
// Returns:
//	Boolean - False if the required data is not filled in.
//
Function CheckWhetherCurrencyConversionIsNecessaryCommissionReports(CallbackDescription, Object, OldCurrency, NameOfSalesAmountColumn = "SalesAmount") Export
	
	If ValueIsFilled(Object.Currency)
	   And ValueIsFilled(OldCurrency)
	   And OldCurrency <> Object.Currency
	   And (Object.Goods.Total("Price") <> 0
	    Or Object.Goods.Total(NameOfSalesAmountColumn) <> 0) Then
	
		MessageText = NStr("vi = 'Tính lại số tiền trong chứng từ theo nguyên tệ ""%Currency%""?';
							|ru = 'Пересчитать суммы в документе в валюту ""%Currency%""?';
							|en = 'Convert amounts in the document in %Currency%?'; fa = 'Convert amounts in the document in %Currency%?';
							|it = 'Ricalcolare gli importi del documento in valuta ""%Currency%""?';
							|pl = 'Przeliczyć kwoty w dokumencie na walutę ""%Currency%""?';
							|tr = 'Belgedeki tutarlar ""%Currency%"" para birimine göre yeniden hesaplansın mı?'");
		MessageText = StrReplace(MessageText, "%Currency%", Object.Currency);
		
		Buttons = New ValueList;
		Buttons.Add(True, NStr("vi = 'Có';
								|ru = 'Да';
								|en = 'Yes'; fa = 'بله';
								|it = 'Sì';
								|pl = 'Tak';
								|tr = 'Evet'"));
		Buttons.Add(False, NStr("vi = 'Không';
								|ru = 'Нет';
								|en = 'No'; fa = 'خیر';
								|it = 'Non ci sono';
								|pl = 'Nie';
								|tr = 'Hayır'"));
		
		ShowQueryBox(
			CallbackDescription,
			MessageText,
			Buttons,
			,
			True);
		
	Else
		
		RunCallback(CallbackDescription, False);
		
	EndIf;

EndFunction

#EndRegion

#Region ProceduresForNotifyingUserOfCompletedActions

// The procedure shows a notification to the user about the end
// of the Commission calculation.
//
// Parameters:
//  CommissionFeeCalculationMethod - EnumRef.CommissionFeeCalculationMethods - way of calculation.
//
Procedure NotifyAboutEndOfCalculationOfRemuneration(CommissionFeeCalculationMethod) Export
	
	If CommissionFeeCalculationMethod = PredefinedValue("Enum.CommissionFeeCalculationMethods.NotCalculating") Then
		ShowUserNotification(
		NStr("vi = 'Phần thưởng được xóa.';
			|ru = 'Вознаграждение очищено.';
			|en = 'Commission is cleared.'; fa = 'Commission is cleared.';
			|it = 'La ricompensa è stata cancellata.';
			|pl = 'Nagroda została wyczyszczona.';
			|tr = 'Ücret temizlendi.'"),
		,
		NStr("vi = 'Hoa hồng trong chứng từ bị xóa.';
			|ru = 'Комиссионное вознаграждение в документе очищено.';
			|en = 'Commission is cleared in the document.'; fa = 'Commission is cleared in the document.';
			|it = 'La Commissione nel documento è stata cancellata.';
			|pl = 'Prowizja w dokumencie jest rozliczana.';
			|tr = 'Belgedeki komisyon temizlendi.'"),
		PictureLib.Information32);
		
	ElsIf Not ValueIsFilled(CommissionFeeCalculationMethod) Then
		ShowUserNotification(
		NStr("vi = 'Phương pháp tính toán chưa điền.';
			|ru = 'Способ расчета не заполнен.';
			|en = 'Calculation method is not specified.'; fa = 'Calculation method is not specified.';
			|it = 'Il metodo di calcolo non è completo.';
			|pl = 'Metoda obliczania nie jest wypełniona.';
			|tr = 'Hesaplama yöntemi doldurulmadı.'"),
		,
		NStr("vi = 'Trước khi tính toán hoa hồng, Phương pháp tính toán, trong chứng từ, phải được hoàn thành.';
			|ru = 'Перед расчетом комиссионного вознаграждения, Способ расчета, в документе, необходимо заполнить.';
			|en = 'Before commission calculation, fill in Calculation method in the document.'; fa = 'Before commission calculation, fill in Calculation method in the document.';
			|it = 'Prima di calcolare la Commissione, il metodo di calcolo, nel documento, deve essere compilato.';
			|pl = 'Przed obliczeniem prowizji należy wypełnić metodę obliczania w dokumencie.';
			|tr = 'Komisyonu hesaplamadan önce, belgedeki hesaplama yöntemi doldurulmalıdır.'"),
		PictureLib.Information32);
		
	Else
		ShowUserNotification(
		NStr("vi = 'Phần thưởng được tính toán.';
			|ru = 'Вознаграждение рассчитано.';
			|en = 'Commission is calculated.'; fa = 'Commission is calculated.';
			|it = 'La ricompensa è calcolata.';
			|pl = 'Nagroda jest obliczana.';
			|tr = 'Ücret hesaplandı.'"),
		,
		NStr("vi = 'Hoa hồng trong chứng từ được tính toán.';
			|ru = 'Комиссионное вознаграждение в документе рассчитано.';
			|en = 'Commission is calculated in the document.'; fa = 'Commission is calculated in the document.';
			|it = 'La Commissione nel documento è stata calcolata.';
			|pl = 'Prowizja w dokumencie jest obliczana.';
			|tr = 'Belgedeki komisyon hesaplandı.'"),
		PictureLib.Information32);
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

// The procedure calculates the VAT amount of the Commission fee.
//
// Parameters:
//  Object - FormDataCollection, FormDataCollectionItem - the object or string of the object to calculate for.
//  VATPercentage - Number - value of the VAT percentage.
//
Procedure CalculateCommissionFeeVAT(Object, VATPercentage) Export
	
	Object.AmountVATRemuneration = Round(Object.CommissionAmount * VATPercentage / (100 + VATPercentage), 2, RoundMode.Round15as20);
	
EndProcedure

// The procedure fills in the "payment date" field in the document.
//
// Parameters:
// 	CallbackDescription - CallbackDescription - 
//	PaymentDate - Date - 
//	WriteParameters - Structure - Document recording parameters.
//
Procedure FillInPaymentDate(CallbackDescription, PaymentDate, WriteParameters) Export
	
	If WriteParameters.WriteMode = DocumentWriteMode.Posting
	 And Not ValueIsFilled(PaymentDate) Then
		ShowInputDate(CallbackDescription, PaymentDate, NStr("vi = 'Hãy nhập ngày thanh toán';
															|ru = 'Введите дату платежа';
															|en = 'Enter the payment date'; fa = 'Enter the payment date';
															|it = 'Inserisci la data di pagamento';
															|pl = 'Wprowadź datę płatności';
															|tr = 'Ödeme tarihini gir'"), DateFractions.Date);
	Else
		RunCallback(CallbackDescription, PaymentDate);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure ItIsNecessaryToCalculateCommission(CallbackDescription, Form)
	
	If Form.Object.Goods.Count() > 0 Then
		
		If ValueIsFilled(Form.Object.CommissionFeeCalculationMethod) Then
			If TypeOf(CallbackDescription.AdditionalParameters) = Type("Structure") Then
				CallbackDescription.AdditionalParameters.Insert("RestoreAttributes", True);
			EndIf;
			Buttons = New ValueList;
			Buttons.Add(True, NStr("vi = 'Có';
									|ru = 'Да';
									|en = 'Yes'; fa = 'بله';
									|it = 'Sì';
									|pl = 'Tak';
									|tr = 'Evet'"));
			Buttons.Add(False, NStr("vi = 'Không';
									|ru = 'Нет';
									|en = 'No'; fa = 'خیر';
									|it = 'Non ci sono';
									|pl = 'Nie';
									|tr = 'Hayır'"));
			ShowQueryBox(CallbackDescription, NStr("vi = 'Tính hoa hồng?';
													|ru = 'Рассчитать комиссионное вознаграждение?';
													|en = 'Calculate the commission?'; fa = 'Calculate the commission?';
													|it = 'Calcolare la Commissione?';
													|pl = 'Obliczyć wynagrodzenie komisowe?';
													|tr = 'Komisyonu hesapla?'"), Buttons,, True);
		Else 
			RunCallback(CallbackDescription, True);
		EndIf;
		
	Else
		
		RunCallback(CallbackDescription, False);
		
	EndIf;
	
EndProcedure

Procedure YouNeedToClearCommissionFee(CallbackDescription, Form)
	
	If Form.Object.Goods.Total("CommissionAmount") <> 0 Then
		
		If TypeOf(CallbackDescription.AdditionalParameters) = Type("Structure") Then
			CallbackDescription.AdditionalParameters.Insert("RestoreAttributes", True);
		EndIf;
		Buttons = New ValueList;
		Buttons.Add(True, NStr("vi = 'Có';
								|ru = 'Да';
								|en = 'Yes'; fa = 'بله';
								|it = 'Sì';
								|pl = 'Tak';
								|tr = 'Evet'"));
		Buttons.Add(False, NStr("vi = 'Không';
								|ru = 'Нет';
								|en = 'No'; fa = 'خیر';
								|it = 'Non ci sono';
								|pl = 'Nie';
								|tr = 'Hayır'"));
		ShowQueryBox(CallbackDescription, NStr("vi = 'Sẽ xóa hoa hồng ký gửi, tiếp tục?';
												|ru = 'Комиссионное вознаграждение будет очищено, продолжить?';
												|en = 'Commission will be cleared. Continue?'; fa = 'Commission will be cleared. Continue?';
												|it = 'La Commissione sarà cancellata, procedere?';
												|pl = 'Wynagrodzenie komisowe będzie oczyszczone, czy kontynuować?';
												|tr = 'Komisyon temizlenecek, devam edilsin mi?'"), Buttons,, True);
	Else
		RunCallback(CallbackDescription, False);
	EndIf;
	
EndProcedure

Function AmountSalesVAT(SalesAmount, VATRate)
	
	AmountSalesVAT = PriceManagementSystemClientServer.CalculateVATAmount(SalesAmount, VATRate);
	Return Round(AmountSalesVAT, 2, RoundMode.Round15as20);
	
EndFunction

#EndRegion
