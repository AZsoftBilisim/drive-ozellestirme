#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	ReportParameters = GetReportParameters(ReportSettings);
	TempTablesManager = New TempTablesManager;
	
	If CalculationOfCostCached.BatchAccountingVersion22(ReportParameters.ReportPeriod) Then
	
		RuleRequestResult = GetCurrentRules(ReportParameters.ReportPeriod, ReportParameters.Organization);
	
		SetReportPeriod(ReportSettings, ReportParameters);
	
		If RuleRequestResult.IsEmpty() Then
			CreateEmptyTableForDCS(TempTablesManager);
		Else	
			CreateTemporaryTableForDCS(TempTablesManager, RuleRequestResult, ReportParameters.ReportPeriod);
		EndIf;
	
	Else
		CreateEmptyTableForDCS(TempTablesManager);
	EndIf;
	
	// Let's compose and output the query result into a tabular document
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData,,, TempTablesManager);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion
	
#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - Structure of See ReportsClientServer.DefaultReportSettings.
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean -passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If MonthEndTransactionsServer.ThisFormIsOpenedFromMonthClosingForm(ThisForm) Then
		
		ThisForm.PurposeUseKey = "ContextClosingOfMonth";
		ParametersForm = ThisForm.ParametersForm;
		
		ParametersForm.PurposeUseKey = ThisForm.PurposeUseKey;
		
		ReportPeriod = EndOfMonth(Parameters.RegistrationPeriod);
		ParametersForm.Filter.Clear();
		ParametersForm.Filter.Insert("ReportPeriod", ReportPeriod);
		If Not Parameters.AllCompanies Then
			ParametersForm.Filter.Insert("Organization", Parameters.CompanyArray);
		EndIf;
		
	ElsIf Parameters.Property("CommandParameter") And Parameters.CommandParameter.Count() <> 0 Then
		
		ReserveCalculationDocument = Parameters.CommandParameter[0];
		PaymentAttributes = Common.ObjectAttributesValues(ReserveCalculationDocument, "Date,Organization");
		ReportPeriod = EndOfMonth(PaymentAttributes.Date);
		ParametersForm = ThisForm.ParametersForm;
		ParametersForm.Filter.Clear();
		ParametersForm.Filter.Insert("ReportPeriod", ReportPeriod);
		ParametersForm.Filter.Insert("Organization", PaymentAttributes.Organization);
		
	EndIf;
	
EndProcedure

Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		ConfigureReportDataParameter(Context.ReportSettings, NewDCSettings, NewDCUserSettings);
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
	EndIf;
	
EndProcedure

// Configure the report data parameter.
// 
// Parameters:
//  ReportSettings						- DataCompositionSettings					- the report settings.
//	NewDCSettings					- DataCompositionSettings					- report variant settings that will be loaded
//																						into the settings Builder after it is initialized.
//										- Undefined 								- the option settings do not need to be downloaded (already downloaded earlier).
//	NewDCUserSettings	- DataCompositionUserSettings - custom settings that will be loaded into
//																						the settings Builder after it is initialized.
//										- Undefined 								- user settings do not need to be downloaded (already downloaded earlier).
//
Procedure ConfigureReportDataParameter(ReportSettings, NewDCSettings, NewDCUserSettings)
	
	ReportDataParameter = DataCompositionSchema.Parameters.Find("ReportData");

	ChoiceList = New ValueList;
	
	If CalculationOfCostCached.CompanyManagementAccounting() Then
		ChoiceList.Add(1, NStr("vi = 'Theo tiền tệ kế toán quản trị';
								|ru = 'В валюте упр. учета';
								|en = 'In management accounting currency'; fa = 'به ارز حسابداری مدیریت';
								|it = 'In valuta della contabilità gestionale';
								|pl = 'W walucie ewidencji zarządczej';
								|tr = 'Yönetim muhasebesi para birimi cinsinden'"));
	EndIf;
		
	ChoiceList.Add(2, NStr("vi = 'Theo tiền tệ kế toán tài chính';
							|ru = 'В валюте регл. учета';
							|en = 'In local accounting currency'; fa = 'به ارز حسابداری محلی';
							|it = 'In valuta della contabilità regolamentata';
							|pl = 'W walucie ewidencji reglamentowanej';
							|tr = 'Yerel muhasebe para birimi cinsinden'"));
		
	ReportDataParameter.SetAvailableValues(ChoiceList);
	
	If NewDCSettings = Undefined
		Or NewDCUserSettings = Undefined Then
		Return;
	EndIf;
	
	ValueOfReportDataParameter = NewDCSettings.DataParameters.FindParameterValue(New DataCompositionParameter("ReportData"));
	ConfiguringReportData = NewDCUserSettings.Items.Find(ValueOfReportDataParameter.UserSettingID);
	
	If Not ConfiguringReportData = Undefined
		And ChoiceList.FindByValue(ConfiguringReportData.Value) = Undefined Then
		ConfiguringReportData.Value = ChoiceList[0].Value;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function GetReportParameters(ReportSettings)
	
	ParametersStructure = New Structure("ReportPeriod,Organization");
	
	DataParameters = ReportSettings.DataParameters;
	PeriodParameter = DataParameters.FindParameterValue(New DataCompositionParameter("ReportPeriod"));
	ParameterOrganization = DataParameters.FindParameterValue(New DataCompositionParameter("Organization"));
	
	If Not ValueIsFilled(PeriodParameter.Value) Then
		ParametersStructure.ReportPeriod = EndOfMonth(CurrentSessionDate());
	Else
		ParametersStructure.ReportPeriod = EndOfMonth(PeriodParameter.Value);
	EndIf;
	
	If Not ParameterOrganization.Use Or Not ValueIsFilled(ParameterOrganization.Value) Then
		ParametersStructure.Organization = PredefinedValue("Catalog.Companies.EmptyRef");
	Else
		ParametersStructure.Organization = ParameterOrganization.Value;
	EndIf;
	
	Return ParametersStructure;
	
EndFunction

Function GetCurrentRules(ReportPeriod, Organization)
	
	RequestRules = New Query;
	RequestRules.Text = QueryTextRules_();
	RequestRules.SetParameter("ReportPeriod", ReportPeriod);
	
	If TypeOf(Organization) = Type("CatalogRef.Companies") Then
		CompaniesList = New Array;
		If ValueIsFilled(Organization) Then
			CompaniesList.Add(Organization);
		EndIf;
	Else
		CompaniesList = Organization;
	EndIf;
	
	RequestRules.SetParameter("CompaniesList", CompaniesList);
	RequestRules.SetParameter("AllCompanies", CompaniesList.Count() = 0);
	
	Return RequestRules.Execute();
	
EndFunction

Procedure SetReportPeriod(ReportSettings, ReportParameters)
	
	DataParameters = ReportSettings.DataParameters;
		
	ReserveCalculationDocument = GetDocumentForCalculatingReserves(ReportParameters);	
	
	If ValueIsFilled(ReserveCalculationDocument) Then
		DataParameters.SetParameterValue("BeginOfPeriod", New Boundary(ReserveCalculationDocument.PointInTime(), BoundaryType.Including));
		DataParameters.SetParameterValue("EndOfPeriod", New Boundary(ReserveCalculationDocument.PointInTime(), BoundaryType.Including));
	Else
		DataParameters.SetParameterValue("BeginOfPeriod", New Boundary(ReportParameters.ReportPeriod, BoundaryType.Excluding));
		DataParameters.SetParameterValue("EndOfPeriod", New Boundary(ReportParameters.ReportPeriod, BoundaryType.Including));
	EndIf;
	
EndProcedure

Function GetDocumentForCalculatingReserves(ReportParameters)
	
	ReserveCalculationDocument = PredefinedValue("Document.CalculationOfInventoryImpairmentProvision.EmptyRef");
	Query = New Query(
	"SELECT TOP 1
	|	CalculationOfInventoryImpairmentProvision.Ref AS Ref
	|FROM
	|	Document.CalculationOfInventoryImpairmentProvision AS CalculationOfInventoryImpairmentProvision
	|WHERE
	|	CalculationOfInventoryImpairmentProvision.Posted
	|	AND CalculationOfInventoryImpairmentProvision.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (CalculationOfInventoryImpairmentProvision.Organization = &Organization
	|		OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|");
	
	Query.SetParameter("BeginOfPeriod", BegOfMonth(ReportParameters.ReportPeriod));
	Query.SetParameter("EndOfPeriod", EndOfMonth(ReportParameters.ReportPeriod));
	Query.SetParameter("Organization", ReportParameters.Organization);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		ReserveCalculationDocument = Selection.Ref;
	EndIf;
	
	Return ReserveCalculationDocument;
		
EndFunction

Procedure CreateEmptyTableForDCS(TempTablesManager)
	
	QueryingEmptyTemporaryTable = New Query;
	QueryingEmptyTemporaryTable.Text = QueryTextOfEmptySummaryTable();
	QueryingEmptyTemporaryTable.TempTablesManager = TempTablesManager;
	QueryingEmptyTemporaryTable.Execute();
		
EndProcedure

Procedure CreateTemporaryTableForDCS(TempTablesManager, RuleRequestResult, ReportPeriod)
	
	RuleSelection = RuleRequestResult.Select();
	
	NumberOfTemporaryTables = 
		Catalogs.RulesForCalculationOfInventoryImpairmentProvision.CreateTemporaryTablesOfBalancesByRules(
			RuleSelection, 
			New Boundary(ReportPeriod, BoundaryType.Including), 
			TempTablesManager);
	
	PutParameters = New Structure;
	PutParameters.Insert("TempTableName", "TableOfBalancesByRule");
	PutParameters.Insert("TemporaryTableNumber", NumberOfTemporaryTables);
	Catalogs.RulesForCalculationOfInventoryImpairmentProvision.MergeTemporaryBalanceTablesIntoSummaryTable(TempTablesManager, PutParameters);
		
EndProcedure

Function QueryTextRules_()
		
	QueryText = 
	"SELECT
	|	RulesForCalculationOfInventoryImpairmentProvision.Ref AS Rule,
	|	RulesForCalculationOfInventoryImpairmentProvision.LocalAccounting AS LocalAccounting,
	|	RulesForCalculationOfInventoryImpairmentProvision.ManagementAccounting AS ManagementAccounting
	|FROM
	|	Catalog.RulesForCalculationOfInventoryImpairmentProvision AS RulesForCalculationOfInventoryImpairmentProvision
	|WHERE
	|	NOT RulesForCalculationOfInventoryImpairmentProvision.DeletionMark
	|	AND CASE
	|		WHEN RulesForCalculationOfInventoryImpairmentProvision.ValidOnDate = DATETIME(1, 1, 1)
	|			THEN TRUE
	|		ELSE RulesForCalculationOfInventoryImpairmentProvision.ValidOnDate <= ENDOFPERIOD(&ReportPeriod, MONTH)
	|	END
	|	AND CASE
	|		WHEN RulesForCalculationOfInventoryImpairmentProvision.ValidToDate = DATETIME(1, 1, 1)
	|			THEN TRUE
	|		ELSE RulesForCalculationOfInventoryImpairmentProvision.ValidToDate >= BEGINOFPERIOD(&ReportPeriod, MONTH)
	|	END
	|	AND CASE
	|		WHEN &AllCompanies
	|			THEN TRUE
	|		ELSE RulesForCalculationOfInventoryImpairmentProvision.Owner IN (&CompaniesList)
	|	END";
	
	Return QueryText;
	
EndFunction

Function QueryTextOfEmptySummaryTable()
	
	QueryText = 
	"SELECT
	|	VALUE(Catalog.InventoryLocationAttributeKeys.EmptyRef) AS ItemsLocationAttributes,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AS AccountingSection,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|	VALUE(Catalog.Companies.EmptyRef) AS Organization,
	|	UNDEFINED AS Lot,
	|	VALUE(Catalog.KeysForLotVendorAttributes.EmptyRef) AS LotVendorAttributes,
	|	UNDEFINED AS FinancialAccountingDimension,
	|	VALUE(Enum.VATTaxationTypes.EmptyRef) AS VATActivityType,
	|	VALUE(Catalog.DimensionKeysOfAccountingByPartners.EmptyRef) AS AccountingDimensionByPartners,
	|	VALUE(Catalog.RulesForCalculationOfInventoryImpairmentProvision.EmptyRef) AS Rule,
	|	0 AS NetSaleValueOfLocal,
	|	0 AS NetSellingValueOfMan
	|INTO TemporaryTableOfBalances
	|WHERE
	|	FALSE";
	
	Return QueryText
				
EndFunction


#EndRegion

#EndIf