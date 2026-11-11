#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If Not Parameters.Property("OperationParametersList")
		Or Not Parameters.OperationParametersList.Property("DocumentRef") Then
		
		Return;
	EndIf;
	
	If Parameters.OperationParametersList.Property("Counterparty") Then
		LegalEntityIndividualOfCounterparty = Common.ObjectAttributeValue(Parameters.OperationParametersList.Counterparty, "LegalEntityIndividual");
		If LegalEntityIndividualOfCounterparty = PredefinedValue("Enum.LegalEntityIndividual.LegalEntityNonResident") Then
			Parameters.OperationParametersList.Counterparty = PredefinedValue("Catalog.Counterparties.EmptyRef");
		EndIf; 
	EndIf;
	
	StandardProcessing = False;
	SelectedForm = "Form";
	
	Parameters.Insert(
		"ConnectedReceiptPrintingEquipment",
		GeneratingFiscalChecksServer.ConnectedReceiptPrintingEquipment(Parameters.OperationParametersList));
	
	If Not DocumentCurrencyLocalAccountingCurrency(Parameters.OperationParametersList) Then
		SelectedForm = "ErrorOfCurrencyUsed";
	ElsIf Not ConnectedHardwareIsConfigured(Parameters.ConnectedReceiptPrintingEquipment) Then
		SelectedForm = "ErrorOfCREConnection";
	Else
		GeneratingFiscalChecksServer.ProcessingReceiptOfFormPreviewingReceipt(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function DocumentCurrencyLocalAccountingCurrency(BasicOperationParameters)
	
	DocumentCurrencyLocalAccountingCurrency = True;
	
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(BasicOperationParameters.DocumentRef.Organization);

		If TypeOf(BasicOperationParameters.DocumentRef) = Type("DocumentRef.ARAPSettlement") Then
			
			Query = New Query;
			Query.Text = "SELECT
						   |	""Dr"" AS Party,
			               |	AccountsReceivable.ARAPObject AS ARAPObject,
			               |	AccountsReceivable.ARAPObject.Currency AS Currency
			               |FROM
			               |	Document.ARAPSettlement.AccountsReceivable AS AccountsReceivable
			               |WHERE
			               |	AccountsReceivable.Ref = &DocumentRef
			               |	AND NOT AccountsReceivable.ARAPObject.ARAPObjectType IN (VALUE(Enum.ARAPObjectTypes.OrderDocument), VALUE(Enum.ARAPObjectTypes.Contract))
			               |	AND AccountsReceivable.ARAPObject.Currency <> &LocalAccountingCurrency
			               |
			               |UNION ALL
			               |
			               |SELECT
						   |	""Cr"" AS Party,
			               |	AccountsPayable.ARAPObject,
			               |	AccountsPayable.ARAPObject.Currency
			               |FROM
			               |	Document.ARAPSettlement.AccountsPayable AS AccountsPayable
			               |WHERE
			               |	AccountsPayable.Ref = &DocumentRef
			               |	AND NOT AccountsPayable.ARAPObject.ARAPObjectType IN (VALUE(Enum.ARAPObjectTypes.OrderDocument), VALUE(Enum.ARAPObjectTypes.Contract))
			               |	AND AccountsPayable.ARAPObject.Currency <> &LocalAccountingCurrency";
			
			Query.SetParameter("LocalAccountingCurrency", ComplCurrency);
			Query.SetParameter("DocumentRef", BasicOperationParameters.DocumentRef);
			Result = Query.Execute();
			If Not Result.IsEmpty() Then
				DocumentCurrencyLocalAccountingCurrency = False;
			EndIf;
			
		ElsIf ValueIsFilled(BasicOperationParameters.Currency)
			And ValueIsFilled(BasicOperationParameters.ARAPCurrency) Then

			If BasicOperationParameters.Currency <> ComplCurrency
				Or BasicOperationParameters.ARAPCurrency <> ComplCurrency Then

				DocumentCurrencyLocalAccountingCurrency = False;
			EndIf;

		ElsIf ValueIsFilled(BasicOperationParameters.Currency) Then

			If BasicOperationParameters.Currency <> ComplCurrency Then
				DocumentCurrencyLocalAccountingCurrency = False;
			EndIf;

		Else

			DocumentCurrencyLocalAccountingCurrency = False;

		EndIf;
	
	#EndIf
	
	Return DocumentCurrencyLocalAccountingCurrency;
	
EndFunction

Function ConnectedHardwareIsConfigured(ConnectedReceiptPrintingEquipment)
	
	Return ConnectedReceiptPrintingEquipment.Count() > 0;
	
EndFunction

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	If PrintManagement.TemplatePrintRequired(PrintFormsCollection, "PersonalDataProcessingConsent") Then
		PrintManagement.OutputSpreadsheetDocumentToCollection(
			PrintFormsCollection,
			"PersonalDataProcessingConsent",
			NStr("vi = 'Thống nhất xử lý dữ liệu cá nhân';
				|ru = 'Согласие на обработку персональных данных';
				|en = 'Consent to personal data processing'; fa = 'رضایت برای پردازش داده‌های شخصی';
				|it = 'Consenso sull''utilizzo dei dati personali';
				|pl = 'Zgoda na przetwarzanie danych osobowych';
				|tr = 'Kişisel bilgilerin i̇şlenmesi̇ne ilişkin rıza'"),
			FormPrintedFormOfConsentToProcessingOfPersonalData(ObjectsArray, PrintParameters, PrintParameters),
			,
			"DataProcessor.PreviewReceipt.PersonalDataProcessingConsent");
	EndIf;
	
EndProcedure

Function FormPrintedFormOfConsentToProcessingOfPersonalData(ObjectsArray, PrintObjects, PrintParameters)
	
	SetPrivilegedMode(True);
	
	Template = PrintManagement.PrintFormTemplate("DataProcessor.PreviewReceipt.PF_MXL_PersonalDataProcessingConsent");
	
	SpreadsheetDocument = New SpreadsheetDocument;
	SpreadsheetDocument.PrintParametersName = "PRINT_OPTIONS_PreviewReceipt_PersonalDataProcessingConsent";
	
	Area = Template.GetArea("Header");
	SpreadsheetDocument.Put(Area);
	
	Area = Template.GetArea("DescriptionOfConsent");
	SpreadsheetDocument.Put(Area);
	
	Area = Template.GetArea("PermanentPartOfPersonalData");
	SpreadsheetDocument.Put(Area);
	
	If PrintParameters.PersonalDataType = "TIN" Then
		Area = Template.GetArea("PersonalDataTIN");
		SpreadsheetDocument.Put(Area);
	Else
		Area = Template.GetArea("PersonalDataPassportData");
		SpreadsheetDocument.Put(Area);
	EndIf;
	
	Area = Template.GetArea("Footer");
	SpreadsheetDocument.Put(Area);
	
	SpreadsheetDocument.FitToPage = True;
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
	Return SpreadsheetDocument;
	
EndFunction

#EndRegion

#EndRegion

#EndIf