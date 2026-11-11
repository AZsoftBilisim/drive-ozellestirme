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
	Settings.Events.BeforeLoadVariantAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		ThisForm.ParametersForm.Filter.Insert("Document", Parameters.CommandParameter);
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	FormSettingsComposer.Settings.AdditionalProperties.Insert("CurrentVariantKey", ThisForm.CurrentVariantKey);
	
	NewDCSettings = FormSettingsComposer.Settings;

EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	DocumentParameter = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "Document");
	
	If ValueIsFilled(DocumentParameter.Value) Then
		
		LimitPeriod = Undefined;
		BusinessOperation = Undefined;
		
		If TypeOf(DocumentParameter.Value) = Type("DocumentRef.PaymentRequest") Then
			
			DocumentAttributes = Common.ObjectAttributesValues(DocumentParameter.Value,
				"Date, PaymentDate, RequiredPaymentDate, Organization, Department, BusinessOperation");
			
			If ValueIsFilled(DocumentAttributes.PaymentDate) Then
				LimitPeriod = DocumentAttributes.PaymentDate;
			ElsIf ValueIsFilled(DocumentAttributes.RequiredPaymentDate) Then
				LimitPeriod = DocumentAttributes.RequiredPaymentDate;
			Else
				LimitPeriod = DocumentAttributes.Date;
			EndIf;
			
			BusinessOperation = DocumentAttributes.BusinessOperation;
			
		ElsIf TypeOf(DocumentParameter.Value) = Type("DocumentRef.ApplicationForBusinessTrip") Then
		
			DocumentAttributes = Common.ObjectAttributesValues(DocumentParameter.Value,
				"Date, RequiredPaymentDate, Organization, Department");
				
			If ValueIsFilled(DocumentAttributes.RequiredPaymentDate) Then
				LimitPeriod = DocumentAttributes.RequiredPaymentDate;
			Else
				LimitPeriod = DocumentAttributes.Date;
			EndIf;
			
			BusinessOperation = Enums.BusinessTransactions.IssueCashToAdvanceHolder;
		EndIf;
		
		PeriodParameter = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "Period");
		PeriodParameter.Value = New StandardPeriod(BegOfMonth(LimitPeriod), EndOfMonth(LimitPeriod));
		PeriodParameter.Use = True;
		
		ParameterBusinessOperation = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "BusinessOperation");
		ParameterBusinessOperation.Value = BusinessOperation;
		ParameterBusinessOperation.Use = True;
		
		CashFlowReportItems = CashFlowItemsOfDocument(DocumentParameter.Value);
		For Each GroupingCashFlowItem_ In SettingsComposer.Settings.Structure Do
			SetSettingsComposerSelection(
				GroupingCashFlowItem_.Filter, "CashFlowItem", CashFlowReportItems);
		EndDo;
		
		If GetFunctionalOption("UseCashFlowLimitsByCompanies") Then
			SetSettingsComposerSelection(
				SettingsComposer.Settings.Filter, "Organization", DocumentAttributes.Organization);
		EndIf;
		
		If GetFunctionalOption("UseCashFlowLimitsByBusinessUnit") Then
			SetSettingsComposerSelection(
				SettingsComposer.Settings.Filter, "Department", DocumentAttributes.Department);
		EndIf;
	Else
		
		ParameterBusinessOperation = DataCompositionClientServer.GetParameter(SettingsComposer.Settings, "BusinessOperation");
		ParameterBusinessOperation.Value = Enums.BusinessTransactions.EmptyRef();
		ParameterBusinessOperation.Use = True;
	EndIf;
	
	Parameter = SettingsComposer.Settings.DataParameters.FindParameterValue(New DataCompositionParameter("Currency"));
	If Parameter <> Undefined Then
		Parameter.Value = Constants.ManagementAccountingCurrency.Get();
		Parameter.Use = True;
	EndIf;
	
	DataCompositionServer.SetUpDynamicPeriod(DataCompositionSchema, SettingsComposer);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	DataCompositionServer.HideAuxiliaryReportParameters(DataCompositionSchema, SettingsComposer, ResultDocument, AuxiliaryReportParameters());
	
EndProcedure

#EndRegion

#Region Private

Procedure SetSettingsComposerSelection(Filter, FieldName, Value)
	
	FilterItems1 = CommonClientServer.FindFilterItemsAndGroups(Filter, FieldName);
	For Each FilterElement In FilterItems1 Do
		FilterElement.RightValue = Value;
		FilterElement.Use = True;
	EndDo;
	
EndProcedure

Function AuxiliaryReportParameters()
	AuxiliaryParameters = New Array;
	
	CurrentVariantKey = "";
	If SettingsComposer.Settings.AdditionalProperties.Property("CurrentVariantKey", CurrentVariantKey) Then
		If CurrentVariantKey = "CashFlowLimitsContext" Then
			AuxiliaryParameters.Add("Periodicity");
			AuxiliaryParameters.Add("Period");
		EndIf;
	EndIf;
	
	Return AuxiliaryParameters;
EndFunction

Function CashFlowItemsOfDocument(DocumentRef)
	
	CashFlowReportItems = New Array;
	
	QueryParts = New Array;
	
	If AccessRight("Read", Metadata.Documents.PaymentRequest) Then
		
		QueryParts.Add(
			"SELECT
			|	PaymentRequest.CashFlowItem AS CashFlowItem
			|FROM
			|	Document.PaymentRequest AS PaymentRequest
			|WHERE
			|	PaymentRequest.Ref = &DocumentRef
			|	AND PaymentRequest.BusinessOperation IN (
			|		VALUE(Enum.BusinessTransactions.CurrencyConversion),
			|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices)
			|	)
			|
			|UNION ALL
			|
			|SELECT
			|	PaymentRequestARAPDetails.CashFlowItem
			|FROM
			|	Document.PaymentRequest.ARAPDetails AS PaymentRequestARAPDetails
			|WHERE
			|	PaymentRequestARAPDetails.Ref = &DocumentRef
			|	AND PaymentRequestARAPDetails.Ref.BusinessOperation NOT IN (
			|		VALUE(Enum.BusinessTransactions.CurrencyConversion),
			|		VALUE(Enum.BusinessTransactions.TransferCashBetweenCompanyAndItsBranchOffices))
			|");
	EndIf;
	
	If AccessRight("Read", Metadata.Documents.ApplicationForBusinessTrip) Then
		
		QueryParts.Add("
			|SELECT
			|	FundsIssueToAdvanceHolder.CashFlowItem AS CashFlowItem
			|FROM
			|	Document.ApplicationForBusinessTrip.FundsIssueToAdvanceHolder AS FundsIssueToAdvanceHolder
			|WHERE
			|	FundsIssueToAdvanceHolder.Ref = &DocumentRef
			|");
	EndIf;
	
	If QueryParts.Count() Then
		
		Query = New Query;
		Query.Text = StrConcat(QueryParts, TMCommonUse.QuerySeparatorInJoin());
		Query.SetParameter("DocumentRef", DocumentRef);
		CashFlowReportItems = Query.Execute().Unload().UnloadColumn("CashFlowItem");
	EndIf;
	
	Return CashFlowReportItems;
	
EndFunction

#EndRegion

#EndIf