////////////////////////////////////////////////////////////////////////////////
// Subsystem "Commercial offers", implementation in UT.
// General module.Commercial offers and documents for the server call.
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

Function PaymentTermsByText(SourceOfPaymentTerms) Export
	
	ConditionData = New Structure;
	ConditionData.Insert("PaymentMethod", Enums.PaymentForms.EmptyRef());
	ConditionData.Insert("PaymentSteps", New ValueTable);
	
	If TypeOf(SourceOfPaymentTerms) = Type("CatalogRef.TermsOfSale") Then
		
		GetPaymentTermsDataUnderAgreement(SourceOfPaymentTerms, ConditionData);
		
	ElsIf TypeOf(SourceOfPaymentTerms) = Type("CatalogRef.PaymentSchedules") Then
		
		GetPaymentTermsDataForPaymentSchedule(SourceOfPaymentTerms, ConditionData);
		
	EndIf;
	
	RowsArray = New Array;
	If ValueIsFilled(ConditionData.PaymentMethod) Then
		RowsArray.Add(StrTemplate(NStr("vi = 'Hình thức thanh toán: %1.';
										|ru = 'Форма оплаты: %1.';
										|en = 'Payment method: %1.'; fa = 'Payment method: %1.';
										|it = 'Modalità di pagamento: %1.';
										|pl = 'Forma płatności: %1.';
										|tr = 'Ödeme formu: %1.'"), String(ConditionData.PaymentMethod)));
		RowsArray.Add(Chars.LF);
	EndIf;
	
	If ConditionData.PaymentSteps.Count() > 0 Then
		RowsArray.Add(NStr("vi = 'Các kỳ thanh toán:';
							|ru = 'Этапы оплаты:';
							|en = 'Payment milestones:'; fa = 'Payment milestones:';
							|it = 'Fasi di pagamento:';
							|pl = 'Etapy płatności:';
							|tr = 'Ödeme aşamaları:'"));
	EndIf;
	
	For Each PaymentStage In ConditionData.PaymentSteps Do
		RowsArray.Add(Chars.LF);
		RowsArray.Add(StrTemplate(NStr("vi = '%1, hoãn (ngày) - %2, tỷ lệ phần trăm thanh toán -%3 %%';
										|ru = '%1, отсрочка (дн.) - %2, процент платежа - %3 %%';
										|en = '%1, delay (days) - %2, payment percentage - %3 %%'; fa = '%1, delay (days) - %2, payment percentage - %3 %%';
										|it = '%1, proroga (giorni) - %2, percentuale del pagamento - %3 %%';
										|pl = '%1, odroczenie (dn.) - %2, odsetki płatności - %3%%';
										|tr = '%1, erteleme (gün.) - %2, ödeme faizi - %3 %%'"),
		                               PaymentStage.PaymentOption,
		                               PaymentStage.Move,
		                               PaymentStage.PaymentPercentage));
		RowsArray.Add(".");
	EndDo;
		
	Return StrConcat(RowsArray);
	
EndFunction

Function PresentationOfProductsForPrinting(Products, Characteristic) Export
	
	SetPrivilegedMode(True);
	
	PresentationOfProductsForPrinting = "";
	PresentationOfCharacteristicForPrinting = "";
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	Products.SKU AS SKU,
	|	Products.Code AS Code,
	|	Products.DescriptionFull AS DescriptionFull
	|FROM
	|	Catalog.Products AS Products
	|WHERE
	|	Products.Ref = &Products
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////1
	|SELECT
	|	ItemsCharacteristics.DescriptionFull AS DescriptionFull
	|FROM
	|	Catalog.ItemsCharacteristics AS ItemsCharacteristics
	|WHERE
	|	ItemsCharacteristics.Ref = &Characteristic";
	
	Query.SetParameter("Products",   Products);
	Query.SetParameter("Characteristic", Characteristic);

	
	Result = Query.ExecuteBatch(); // Array of QueryResultSelection
	
	ColumnOfCodes = PrintFormGeneration.AdditionalColumnOfDocumentPrintForms().ColumnName;
	OutputCodes = Not IsBlankString(ColumnOfCodes);
	
	SelectionOfProducts = Result[0].Select();
	If SelectionOfProducts.Next() Then
		
		If OutputCodes And Not IsBlankString(SelectionOfProducts[ColumnOfCodes]) Then
			PresentationOfProductsForPrinting = SelectionOfProducts[ColumnOfCodes] + ", " + SelectionOfProducts.DescriptionFull;
		Else
			PresentationOfProductsForPrinting = SelectionOfProducts.DescriptionFull;			
		EndIf;
	
	EndIf;
	
	SampleCharacteristics = Result[1].Select();
	If SampleCharacteristics.Next() Then
	
		PresentationOfCharacteristicForPrinting = SampleCharacteristics.DescriptionFull;
	
	EndIf;
	
	AdditionalParametersProductPresentation = ProductsClientServer.AdditionalParametersPresentationOfProductsForPrinting();
	AdditionalParametersProductPresentation.DefaultLanguageCode = Common.DefaultLanguageCode();
	
	Return ProductsClientServer.PresentationOfProductsForPrinting(PresentationOfProductsForPrinting, 
				PresentationOfCharacteristicForPrinting,
				,
				,
				AdditionalParametersProductPresentation);
	
EndFunction

#EndRegion

#Region Private

Procedure GetPaymentTermsDataUnderAgreement(Terms, ConditionData)
	
	UsePaymentSchedules = GetFunctionalOption("UsePaymentSchedules");
	
	Query = New Query;
	Query.SetParameter("Terms", Terms);
	
	If UsePaymentSchedules Then
		
		Query.Text = "SELECT ALLOWED
		|	TermsOfSale.PaymentSchedule AS Ref
		|INTO RequiredPaymentSchedule
		|FROM
		|	Catalog.TermsOfSale AS TermsOfSale
		|WHERE
		|	TermsOfSale.Ref = &Terms
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////1
		|SELECT ALLOWED
		|	PaymentSchedules.PaymentMethod AS PaymentMethod
		|FROM
		|	Catalog.PaymentSchedules AS PaymentSchedules
		|WHERE
		|	PaymentSchedules.Ref IN
		|			(SELECT
		|				RequiredPaymentSchedule.Ref
		|			FROM
		|				RequiredPaymentSchedule AS RequiredPaymentSchedule)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////2
		|SELECT ALLOWED
		|	PaymentSchedulesStages.PaymentOption  AS PaymentOption,
		|	PaymentSchedulesStages.Move          AS Move,
		|	PaymentSchedulesStages.PaymentPercentage AS PaymentPercentage
		|FROM
		|	Catalog.PaymentSchedules.Stages AS PaymentSchedulesStages
		|WHERE
		|	PaymentSchedulesStages.Ref IN
		|			(SELECT
		|				RequiredPaymentSchedule.Ref
		|			FROM
		|				RequiredPaymentSchedule AS RequiredPaymentSchedule)";
		
		Result = Query.ExecuteBatch();
		
		HeaderSelection       = Result[1].Select();
		PaymentStagesTable = Result[2].Unload();
		
	Else
		
		Query.Text = "
		|SELECT ALLOWED
		|	TermsOfSale.PaymentMethod AS PaymentMethod
		|FROM
		|	Catalog.TermsOfSale AS TermsOfSale
		|WHERE
		|	TermsOfSale.Ref = &Terms
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////1
		|SELECT ALLOWED
		|	TermsOfSalePaymentScheduleSteps.PaymentOption AS PaymentOption,
		|	TermsOfSalePaymentScheduleSteps.Move AS Move,
		|	TermsOfSalePaymentScheduleSteps.PaymentPercentage AS PaymentPercentage
		|FROM
		|	Catalog.TermsOfSale.PaymentScheduleSteps AS TermsOfSalePaymentScheduleSteps
		|WHERE
		|	TermsOfSalePaymentScheduleSteps.Ref = &Terms";
		
		Result = Query.ExecuteBatch();
		
		HeaderSelection       = Result[0].Select();
		PaymentStagesTable = Result[1].Unload();
		
	EndIf;
	
	If HeaderSelection.Next() Then
		
		ConditionData.PaymentMethod = HeaderSelection.PaymentMethod;
		
	EndIf;
	
	ConditionData.PaymentSteps = PaymentStagesTable;
	
EndProcedure

Procedure GetPaymentTermsDataForPaymentSchedule(Schedule, ConditionData)
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	PaymentSchedules.PaymentMethod AS PaymentMethod
	|FROM
	|	Catalog.PaymentSchedules AS PaymentSchedules
	|WHERE
	|	PaymentSchedules.Ref = &Schedule
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PaymentSchedulesStages.PaymentOption  AS PaymentOption,
	|	PaymentSchedulesStages.Move          AS Move,
	|	PaymentSchedulesStages.PaymentPercentage AS PaymentPercentage
	|FROM
	|	Catalog.PaymentSchedules.Stages AS PaymentSchedulesStages
	|WHERE
	|	PaymentSchedulesStages.Ref = &Schedule
	|
	|ORDER BY
	|	PaymentSchedulesStages.LineNumber";
	
	Query.SetParameter("Schedule", Schedule);
	
	Result = Query.ExecuteBatch();
		
	HeaderSelection       = Result[0].Select();
	PaymentStagesTable = Result[1].Unload();
	
	If HeaderSelection.Next() Then
		
		ConditionData.PaymentMethod = HeaderSelection.PaymentMethod;
		
	EndIf;
	
	ConditionData.PaymentSteps = PaymentStagesTable;
	
EndProcedure

#EndRegion