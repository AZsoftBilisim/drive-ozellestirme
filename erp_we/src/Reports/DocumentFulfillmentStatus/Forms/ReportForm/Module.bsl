
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("CommandParameter") Then
		If TypeOf(Parameters.CommandParameter) = Type("CatalogRef.CounterpartyContracts") Then
			IncomingDocuments.Add(Common.ObjectAttributeValue(Parameters.CommandParameter, "ContractSchedule"));
		Else
			IncomingDocuments.LoadValues(Parameters.CommandParameter);
		EndIf;
	ElsIf ValueIsFilled(Parameters.IncomingDocuments) Then
		IncomingDocuments = Parameters.IncomingDocuments;
	Else
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		GenerateReport();
	Else
		Raise NStr("vi = 'Báo cáo không dành cho mở trực tác.';
					|ru = 'Отчет не предназначен для интерактивного открытия.';
					|en = 'The report is not designed for interactive opening.'; fa = 'The report is not designed for interactive opening.';
					|it = 'Il report non è destinato all''apertura interattiva.';
					|pl = 'Raport nie jest przeznaczony do otwarcia interaktywnego.';
					|tr = 'Rapor, etkileşimli açılmaya yönelik değildir.'");
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForReportTableElements

// Parameters:
// 	Item - FormField
// 	Area - SpreadsheetDocumentRange - Contains:
// 		* Details - Structure:
// 			** OrderDocument - DocumentRef
// 			** Action - String
// 	StandardProcessing - Boolean
//
&AtClient
Procedure ReportTableSelection(Item, Area, StandardProcessing)
	
	If Not ValueIsFilled(Area.Details) Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ParametersStructure = Area.Details;
	
	If ParametersStructure.Action = "OpenSoftwareState" Then
		
		FormParameters = ProvisionInDocumentsClient.OrderSecurityStateFormParameters("ORDERDOCUMENT");
		FormParameters.OrderDocument = ParametersStructure.OrderDocument;
		FormParameters.ReadOnly = True;
		OpenForm("DataProcessor.OrderSupplyForecast.Form",
			FormParameters,
			ThisObject,
			UUID);
		
	ElsIf ParametersStructure.Action = "OpenValue" Then
		ShowValue(,ParametersStructure.OrderDocument);
	ElsIf ParametersStructure.Action = "ShowDocumentsOfTransferOfRawMaterialsToProcessor2_5" Then
		
		ReportSettings = ReportSettingsDecodingStateOfOrderFulfillmentForProcessors(ParametersStructure, "TransferOfGoodsToBailee");
		
		FormParameters = New Structure;
		FormParameters.Insert("DetailsMode", True);
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("UserSettings", ReportSettings);
		FormParameters.Insert("VariantKey", "TransferOfGoodsToBailee");
	
		OpenForm("Report.ExplanationOfTollingOrderStatus.ObjectForm", FormParameters);
	
	ElsIf ParametersStructure.Action = "ShowDocumentsReceivedFromProcessor2_5" Then
		
		ReportSettings = ReportSettingsDecodingStateOfOrderFulfillmentForProcessors(ParametersStructure, "ReceiptOfGoodsFromCustodian");
		
		FormParameters = New Structure;
		FormParameters.Insert("DetailsMode", True);
		FormParameters.Insert("GenerateOnOpen", True);
		FormParameters.Insert("UserSettings", ReportSettings);
		FormParameters.Insert("VariantKey", "ReceiptOfGoodsFromCustodian");
	
		OpenForm("Report.ExplanationOfTollingOrderStatus.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Generate(Command)
	ClearMessages();
	GenerateReport();
EndProcedure 

#EndRegion

#Region Private

&AtServer
Procedure GenerateReport()
	
	ReportTable.Clear();
	Reports.DocumentFulfillmentStatus.GenerateDocumentExecutionStateReport(IncomingDocuments, ReportTable);
	
EndProcedure

&AtServerNoContext
Function ReportSettingsDecodingStateOfOrderFulfillmentForProcessors(Val ParametersStructure, Val ReportVariant)

	ReportObject = Reports.ExplanationOfTollingOrderStatus.Create();
	
	UserSettings = ReportObject.SettingsComposer.UserSettings;
	
	ReportObject.SettingsComposer.Settings.DataParameters.SetParameterValue("ReportVariant", ReportVariant);
	
	ParametersToBeSpecified = New Map;
	ParametersToBeSpecified.Insert("Document", ParametersStructure.Document);
	ParametersToBeSpecified.Insert("Products", ParametersStructure.Products);
	ParametersToBeSpecified.Insert("Characteristic", ParametersStructure.Characteristic);
	
	DataCompositionClientServer.SetCollectionOfParameters(UserSettings, ParametersToBeSpecified);
			
	Return UserSettings;

EndFunction

#EndRegion
