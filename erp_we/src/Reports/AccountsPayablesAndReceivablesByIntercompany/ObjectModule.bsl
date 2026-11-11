#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean -passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	ParametersForm = ThisForm.ParametersForm;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then
		
		CommandParameter = Parameters.CommandParameter;
		If TypeOf(CommandParameter) = Type("Array") Then
			If CommandParameter.Count() > 0 Then
				TheFirstControl = CommandParameter[0];
			Else
				TheFirstControl = Undefined;
			EndIf;
		Else
			TheFirstControl = CommandParameter;
		EndIf;
		
		If TypeOf(TheFirstControl) = Type("DocumentRef.ARAPSettlement") Then
			ThisForm.ParametersForm.Filter = New Structure("ARAPSettlement", CommandParameter);
			ThisForm.ParametersForm.PurposeUseKey = "ARAPSettlement";
			Parameters.PurposeUseKey = "ARAPSettlement";
		ElsIf TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_4")
			Or TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_5_11") Then
			ThisForm.ParametersForm.Filter = New Structure("ARAPReconciliation", TheFirstControl);
			ThisForm.ParametersForm.PurposeUseKey = "ARAPReconciliation";
			Parameters.PurposeUseKey = "ARAPReconciliation";
		EndIf;
		
	EndIf;
	
	If ParametersForm.Property("Filter")
	   And ParametersForm.Filter.Property("Document") Then
	   
		If TypeOf(ParametersForm.Filter.Document) = Type("DocumentRef.CustomerInvoiceIntercompany") Then
			Attributes = Documents.CustomerInvoiceIntercompany.DocumentAttributes(ParametersForm.Filter.Document);
			
		ElsIf TypeOf(ParametersForm.Filter.Document) = Type("DocumentRef.CommissionReportIntercompany") Then
			Attributes = Documents.CommissionReportIntercompany.DocumentAttributes(ParametersForm.Filter.Document);
		ElsIf TypeOf(ParametersForm.Filter.Document) = Type("DocumentRef.ConsumptionReportSubcontractingServicesDeliveredIntercompany") Then
			Attributes = Documents.ConsumptionReportSubcontractingServicesDeliveredIntercompany.DocumentAttributes(ParametersForm.Filter.Document);
		Else
			Attributes = Undefined;
			
		EndIf;
		
		If Attributes <> Undefined Then
			Array = New Array;
			Array.Add(Attributes.SenderOrganization);
			Array.Add(Attributes.CompanyRecipient);
			ParametersForm.Filter.Insert("Organization", Array);
		EndIf;
		
	ElsIf ParametersForm.Property("Filter")
		And ParametersForm.Filter.Property("ARAPSettlement") Then
		NettingLink = ParametersForm.Filter.ARAPSettlement[0];
		Attributes = Common.ObjectAttributesValues(NettingLink, "Date,OperationKind,Organization,CompanyCreditor,CounterpartyDebtor,Creditor");
		If Attributes <> Undefined Then
			If ValueIsFilled(Attributes.Organization) Then
				
				If Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfVendorAPIntercompany Then
					Parameters.VariantKey = "SalesPayments";
					ParametersForm.Filter.Insert("Seller", Attributes.Organization);
					If ValueIsFilled(Attributes.CompanyCreditor) Then
						ParametersForm.Filter.Insert("Customer", Attributes.CompanyCreditor);
					EndIf;
				EndIf;
				
				If Attributes.OperationKind = Enums.KindsOfARAPSettlements.SettlementOfCustomerARIntercompany Then
					Parameters.VariantKey = "ProcurementPayments";
					ParametersForm.Filter.Insert("Customer", Attributes.Organization);
					If ValueIsFilled(Attributes.CompanyCreditor) Then
						ParametersForm.Filter.Insert("Seller", Attributes.CompanyCreditor);
					EndIf;
				EndIf;
				
			EndIf;
			
			Period = New StandardPeriod;
			Period.Variant = StandardPeriodVariant.Custom;
			Period.StartDate = BegOfMonth(Attributes.Date);
			Period.EndDate = EndOfDay(Attributes.Date);
			ParametersForm.Filter.Insert("Period", Period);
		EndIf;
		ParametersForm.Filter.Delete("ARAPSettlement");
		
	ElsIf ParametersForm.Property("Filter")
		And ParametersForm.Filter.Property("ARAPReconciliation") Then
		Attributes = Undefined;
		If TypeOf(ParametersForm.Filter.ARAPReconciliation) = Type("DocumentRef.ARAPReconciliation2_4") Then
			Attributes = Documents.ARAPReconciliation2_4.DocumentAttributes(ParametersForm.Filter.ARAPReconciliation);
		ElsIf TypeOf(ParametersForm.Filter.ARAPReconciliation) = Type("DocumentRef.ARAPReconciliation2_5_11") Then
			Attributes = Documents.ARAPReconciliation2_5_11.DocumentAttributes(ParametersForm.Filter.ARAPReconciliation);
		EndIf;
		If Attributes <> Undefined Then
			If Attributes.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting 
				And Attributes.TotalTypesOfCalculations = 1 Then
				Parameters.VariantKey = "SalesPayments";
				ParametersForm.Filter.Insert("Seller", Attributes.Organization);
				ParametersForm.Filter.Insert("Customer", Attributes.Counterparty);
			Else
				Parameters.VariantKey = "ProcurementPayments";
				ParametersForm.Filter.Insert("Customer", Attributes.Organization);
				ParametersForm.Filter.Insert("Seller", Attributes.Counterparty);
			EndIf;
			Period = New StandardPeriod;
			Period.Variant = StandardPeriodVariant.Custom;
			Period.StartDate = Attributes.BeginOfPeriod;
			Period.EndDate = Attributes.EndOfPeriod;
			ParametersForm.Filter.Insert("Period", Period);
		EndIf;
		ParametersForm.Filter.Delete("ARAPReconciliation");
	
	EndIf;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	//A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#EndIf