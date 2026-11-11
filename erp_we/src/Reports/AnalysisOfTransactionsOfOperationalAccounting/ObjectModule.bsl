
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm, Undefined - report form or report settings form.
//       Undefined when a call is without context.
//   VariantKey - String, Undefined - the name of the predefined
//       or unique identifier of the custom version of the report.
//       Undefined when a call is without context.
//   Settings - Structure - Settings for the general report form (to change).
//       See ReportsClientServer.GetDefaultReportSettings.
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.OnCreateAtServer = True;
	
EndProcedure

#EndRegion

#Region EventHandlers

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Cancel - Boolean - Indicates that the form was not created.
//       See the description of the parameter of the same name "Managed form.Joining the server" in the syntax assistant.
//   StandardProcessing - Boolean - Indicates that the standard (system) event processing has been performed.
//       See the description of the parameter of the same name "Managed form.Access to the server" in the syntax assistant.
//
// See also:
//   Procedure for displaying the added commands in the Form: Server Report.Call the() command.
//   Global handler for this event: reportdetermined.Joining the Server().
//
// Example of adding a command:
//    Command = Form.Commands.Add("<Command name>");
//    The team.Action = "Pluggable_The team";
//    The team.Title = NStr("ru = '<Team presentation...>'");
//    Server report.Enter a team(Form, Command, "<Group View>");
// The handler of the command is written in the reportclientdetermined procedure.The command handler.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();
	
	If CommonClientServer.HasAttributeOrObjectProperty(ReportSettings.AdditionalProperties, "VariantKey") Then
		VariantKey = ReportSettings.AdditionalProperties.VariantKey;
	Else
		VariantKey = "AnalysisOfTransactionsOfOperationalAccounting";
	EndIf;
	
	QueryOptions = FinancialAccountingByFinancialRegisterData.ParametersForRequestingFinancialRegisterData();
	QueryOptions.VariantKey = VariantKey;
	QueryOptions.AdditionalSelection = SettingsComposer.FixedSettings.Filter;
	
	ReportPeriod = DataCompositionParameterValue(ReportSettings, "ReportPeriod");// StandardPeriod - 
	If ReportPeriod <> Undefined Then
		QueryOptions.StartDate = ReportPeriod.StartDate;
		QueryOptions.EndDate = ReportPeriod.EndDate;
	EndIf;
	
	NotReflectedInAccounting = DataCompositionParameterValue(ReportSettings, "NotReflectedInAccounting");
	If NotReflectedInAccounting <> Undefined Then
		QueryOptions.NotReflectedInAccounting = NotReflectedInAccounting;
	EndIf;
	
	FilterItems1 = New Array();
	FillInSelectionElements(FilterItems1, ReportSettings.Filter.Items);
	
	SetSelectionSettingParameter(QueryOptions, FilterItems1, "Recorder");
	SetSelectionSettingParameter(QueryOptions, FilterItems1, "ChartOfAccounts", QueryTextChartsOfAccounts());
	SetSelectionSettingParameter(QueryOptions, FilterItems1, "Organization", QueryTextCompanies());
	
	ExcludeManagementOrganizationData(ReportSettings, QueryOptions);
	
	Query = FinancialAccountingByFinancialRegisterData.RequestForAnalysisOfCorrespondenceOfOperationalAccounting(QueryOptions);
	
	DataCompositionSchema.DataSets.RecordsSet.Query = RequestTextForSetOfRegisteredRecords();
	
	SetDataLayoutParameter(ReportSettings, "NameOfRegisterOfServiceAccountingObjects", Query.Parameters.NameOfRegisterOfServiceAccountingObjects);
	SetDataLayoutParameter(ReportSettings, "Dr", Query.Parameters.Dr);
	SetDataLayoutParameter(ReportSettings, "Cr", Query.Parameters.Cr);
	
	TemplateComposer = New DataCompositionTemplateComposer; 
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	// Let 's compose the result
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate,, DetailsData, True,, Query.TempTablesManager);
	
	ResultDocument.Clear();
	
	// We output the result in a tabular document
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
EndProcedure

#EndRegion

#Region Internal

Function UserSettings(SetValues) Export
	
	UserSettings = SettingsComposer.UserSettings;
	
	For Each ValueToSet In SetValues Do
		For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
			If TypeOf(FilterElement) = Type("DataCompositionFilterItem") 
				And FilterElement.LeftValue = New DataCompositionField(ValueToSet.Key) Then
				UserSetting = UserSettings.Items.Find(FilterElement.UserSettingID);
				If UserSetting <> Undefined Then
					If TypeOf(ValueToSet.Value) = Type("ValueList") Then
						UserSetting.ComparisonType = DataCompositionComparisonType.InList;
						UserSetting.RightValue = ValueToSet.Value;
					ElsIf TypeOf(ValueToSet.Value) = Type("Array") Then
						UserSetting.ComparisonType = DataCompositionComparisonType.InList;
						UserSetting.RightValue = New ValueList();
						UserSetting.RightValue.LoadValues(ValueToSet.Value);
					Else
						UserSetting.ComparisonType = DataCompositionComparisonType.Equal;
						UserSetting.RightValue = ValueToSet.Value;
					EndIf;
					UserSetting.Use = True;
				EndIf;
			EndIf;
		EndDo;
		
		For Each DataParameter In SettingsComposer.Settings.DataParameters.Items Do
			If DataParameter.Parameter = New DataCompositionParameter(ValueToSet.Key) Then
				UserSetting = UserSettings.Items.Find(DataParameter.UserSettingID);
				If UserSetting <> Undefined Then
					If ValueToSet.Key = "ReportPeriod" Then
						If TypeOf(ValueToSet.Value) = Type("StandardPeriodVariant") Then
							UserSetting.Value = New StandardPeriod(ValueToSet.Value);
						Else
							UserSetting.Value = ValueToSet.Value;
						EndIf;
					EndIf;
					UserSetting.Use = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Return UserSettings;
	
EndFunction

#EndRegion

#Region Private

// Returns the value of the data layout parameter.
//
// Parameters:
//  ReportSettings - DataCompositionSettings - generated report settings,
//  ParameterName - String - the name of the parameter whose value you want to get.
// 
// Returns:
//  Arbitrary - value of the data layout parameter
//
Function DataCompositionParameterValue(ReportSettings, ParameterName) Export
	
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	
	If Parameter <> Undefined Then
		If Parameter.Use Then
			Return Parameter.Value;
		EndIf;
	EndIf;
	
	Return Undefined;
	
EndFunction

// Sets the value of the data layout parameter.
//
// Parameters:
//  ReportSettings - DataCompositionSettings - generated report settings,
//  ParameterName - String - the name of the parameter whose value you want to get.
//  ParameterValue - Arbitrary - parameter value to set
//
Procedure SetDataLayoutParameter(ReportSettings, ParameterName, ParameterValue)
	
	Parameter = ReportSettings.DataParameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	
	If Parameter <> Undefined Then
		Parameter.Use = True;
		Parameter.Value = ParameterValue;
	EndIf;
	
EndProcedure

Procedure SetSelectionSettingParameter(QueryOptions, FilterItems1, FieldName, QueryText = "")
	
	FieldSelectionElement = Undefined;
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.LeftValue = New DataCompositionField(FieldName) Then
			FieldSelectionElement = FilterElement;
			Break;
		EndIf;
	EndDo;
	
	If FieldSelectionElement = Undefined Then
		Return;
	EndIf;
	
	If FieldSelectionElement.ComparisonType = DataCompositionComparisonType.Equal Then
		QueryOptions[FieldName] = FieldSelectionElement.RightValue;
	ElsIf FieldSelectionElement.ComparisonType = DataCompositionComparisonType.InList Then
		QueryOptions[FieldName] = FieldSelectionElement.RightValue.UnloadValues();
	ElsIf Not IsBlankString(QueryText) Then
		DataLayoutUtilityScheme = DataCompositionServer.EmptyCircuit();
		DataSet = DataCompositionServer.AddEmptyDataSet(DataLayoutUtilityScheme);
		DataSet.AutoFillAvailableFields = True;
		DataSet.Query = QueryText;
		
		AddressOfDataCompositionSchema = PutToTempStorage(DataLayoutUtilityScheme);
		
		SettingsServiceComposer = New DataCompositionSettingsComposer();
		SettingsServiceComposer.Initialize(New DataCompositionAvailableSettingsSource(AddressOfDataCompositionSchema));
		
		SelectedField = SettingsServiceComposer.Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
		SelectedField.Field = New DataCompositionField(FieldName);
		
		DetailedRecords = SettingsServiceComposer.Settings.Structure.Add(Type("DataCompositionGroup"));
		DetailedRecords.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
		
		FilterElement = SettingsServiceComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FillPropertyValues(FilterElement, FieldSelectionElement);
		
		TemplateComposer = New DataCompositionTemplateComposer();
		CompositionTemplate = TemplateComposer.Execute(DataLayoutUtilityScheme, SettingsServiceComposer.Settings,,, Type("DataCompositionValueCollectionTemplateGenerator"));
		
		DataCompositionProcessor = New DataCompositionProcessor();
		DataCompositionProcessor.Initialize(CompositionTemplate,,, True);
		
		ProcessorOutputToValueTable = New DataCompositionResultValueCollectionOutputProcessor();
		ResultTable2 = ProcessorOutputToValueTable.Output(DataCompositionProcessor, False);
		
		QueryOptions[FieldName] = ResultTable2.UnloadColumn(FieldName);
	EndIf;
	
EndProcedure

Procedure FillInSelectionElements(Array, FilterItems1)
	
	For Each FilterElement In FilterItems1 Do
		If FilterElement.Use Then
			If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
				FillInSelectionElements(Array, FilterElement.Items);
			Else
				Array.Add(FilterElement);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

Procedure ExcludeManagementOrganizationData(ReportSettings, QueryOptions)
	
	NotGenerateReport_ = False;
	ManagementCompany = Catalogs.Companies.ManagementCompany;
	
	If ValueIsFilled(QueryOptions.Recorder) Then
	ElsIf QueryOptions.Organization = Undefined Then
		FilterElement = ReportSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("Organization");
		FilterElement.ComparisonType = DataCompositionComparisonType.NotEqual;
		FilterElement.RightValue = ManagementCompany;
	ElsIf TypeOf(QueryOptions.Organization) = Type("Array") Then
		If QueryOptions.Organization.Count() = 0 Then
		ElsIf QueryOptions.Organization.Count() > 1 Then
			ValueIndex = QueryOptions.Organization.Find(ManagementCompany);
			If ValueIndex <> Undefined Then
				QueryOptions.Organization.Delete(ValueIndex);
			EndIf;
		Else
			NotGenerateReport_ = QueryOptions.Organization[0] = ManagementCompany;
		EndIf;
	Else
		NotGenerateReport_ = QueryOptions.Organization = ManagementCompany;
	EndIf;
	
	If NotGenerateReport_ Then
		Raise(StrTemplate(
			NStr("vi = 'Đối với doanh nghiệp ""%1"", không xem xét phân tích kế toán hoạt động';
				|ru = 'Для организации ""%1"" анализ оперативного учета не предусмотрен';
				|en = 'Operational accounting analysis is not provided for ""%1"" company.'; fa = 'Operational accounting analysis is not provided for ""%1"" company.';
				|it = 'Для организации ""%1"" анализ оперативного учета не предусмотрен';
				|pl = 'Operational accounting analysis is not provided for ""%1"" company.';
				|tr = '""%1"" iş yeri için operasyonel muhasebe analizi öngörülmemiştir'"),
			ManagementCompany));
	EndIf;
	
EndProcedure

Function QueryTextChartsOfAccounts()
	
	QueryText = "
	|SELECT
	|	ChartsOfAccounts.Ref AS ChartOfAccounts
	|FROM
	|	Catalog.FinancialAccountingChartsOfAccounts AS ChartsOfAccounts
	|WHERE
	|	NOT ChartsOfAccounts.DeletionMark
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextCompanies()
	
	QueryText = "
	|SELECT
	|	Companies.Ref AS Organization
	|FROM
	|	Catalog.Companies AS Companies
	|WHERE
	|	NOT Companies.DeletionMark
	|	AND Companies.Ref <> VALUE(Catalog.Companies.ManagementCompany)
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextForSetOfRegisteredRecords()
	
	QueryText = "
	|SELECT
	|	PartsOfDoubleEntry.DrCr = &Cr AS DebitCredit,
	|	RecordsSet.RecNo AS CorrespondenceNumber,
	|	RecordsSet.ChartOfAccounts AS ChartOfAccounts,
	|	RecordsSet.PostingGenerationSetting AS PostingGenerationSetting,
	|	RecordsSet.Period AS Period,
	|	RecordsSet.Organization AS Organization,
	|	RecordsSet.Recorder AS Recorder,
	|	RecordsSet.ReflectionStatus AS ReflectionStatus,
	|	RecordsSet.FinRecordID AS FinRecordID,
	|	CASE
	|		WHEN RecordsSet.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|		  OR RecordsSet.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|			THEN RecordsSet.SettingUpBusinessTransaction
	|		WHEN RecordsSet.ChartOfAccounts.TransactionsWithoutCorrespondence
	|		  AND RecordsSet.AccountingObjectDr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|		  AND RecordsSet.AccountingObjectCr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|		  AND (RecordsSet.RegisterNameDr = &NameOfRegisterOfServiceAccountingObjects
	|			OR RecordsSet.RegisterNameCr = &NameOfRegisterOfServiceAccountingObjects)
	|			THEN RecordsSet.SettingUpBusinessTransaction
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.FinRecordID
	|		ELSE RecordsSet.SettingUpBusinessTransaction
	|	END AS CorrespondenceKey,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.GLAccountCr
	|		ELSE RecordsSet.GLAccountDr
	|	END AS GLAccount,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.LongTermCr
	|		ELSE RecordsSet.LongTermDr
	|	END AS LongTerm,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.RegisterNameCr
	|		ELSE RecordsSet.RegisterNameDr
	|	END AS RegisterName,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.AccountingObjectCr
	|		ELSE RecordsSet.AccountingObjectDr
	|	END AS AccountingObject,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.SettingObject1Cr
	|		ELSE RecordsSet.SettingObject1Dr
	|	END AS SettingObject1,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.CurrencyCr
	|		ELSE RecordsSet.CurrencyDr
	|	END AS Currency,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.SumManCr
	|		ELSE RecordsSet.SumManDr
	|	END AS SumMan,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.SumComplCr
	|		ELSE RecordsSet.SumComplDr
	|	END AS SumCompl,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.SumCurrCr
	|		ELSE RecordsSet.SumCurrDr
	|	END AS SumCurr,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN RecordsSet.CountCr
	|		ELSE RecordsSet.CountDr
	|	END AS Count,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN 0
	|		WHEN RecordsSet.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|			THEN 0
	|		WHEN RecordsSet.ChartOfAccounts.TransactionsWithoutCorrespondence
	|			THEN RecordsSet.SumManDr
	|		WHEN RecordsSet.RegisterNameDr <> &NameOfRegisterOfServiceAccountingObjects
	|			THEN 0
	|		WHEN RecordsSet.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|			THEN 0
	|		ELSE RecordsSet.SumManDr
	|	END AS ServiceAmountOfManDr,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN 0
	|		WHEN RecordsSet.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|			THEN 0
	|		WHEN RecordsSet.ChartOfAccounts.TransactionsWithoutCorrespondence
	|			THEN RecordsSet.SumManCr
	|		WHEN RecordsSet.RegisterNameCr <> &NameOfRegisterOfServiceAccountingObjects
	|			THEN 0
	|		WHEN RecordsSet.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|			THEN 0
	|		ELSE RecordsSet.SumManCr
	|	END AS ServiceAmountOfManCr,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Cr
	|			THEN 0
	|		WHEN RecordsSet.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|			THEN 0
	|		WHEN RecordsSet.ChartOfAccounts.TransactionsWithoutCorrespondence
	|			THEN RecordsSet.SumComplDr
	|		WHEN RecordsSet.RegisterNameDr <> &NameOfRegisterOfServiceAccountingObjects
	|			THEN 0
	|		WHEN RecordsSet.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|			THEN 0
	|		ELSE RecordsSet.SumComplDr
	|	END AS ServiceAmountLocalDr,
	|	CASE
	|		WHEN PartsOfDoubleEntry.DrCr = &Dr
	|			THEN 0
	|		WHEN RecordsSet.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|			THEN 0
	|		WHEN RecordsSet.ChartOfAccounts.TransactionsWithoutCorrespondence
	|			THEN RecordsSet.SumComplCr
	|		WHEN RecordsSet.RegisterNameCr <> &NameOfRegisterOfServiceAccountingObjects
	|			THEN 0
	|		WHEN RecordsSet.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)
	|			THEN 0
	|		ELSE RecordsSet.SumComplCr
	|	END AS ServiceAmountOfLocalCr,
	|	RecordsSet.FinRecordID = """" AS AccountIDNotFilledIn,
	|	RecordsSet.RegisterNameDr = """"
	|		OR RecordsSet.RegisterNameCr = """" AS NoCorrespondence,
	|	RecordsSet.SumManDr <> RecordsSet.SumManCr
	|		OR RecordsSet.SumComplDr <> RecordsSet.SumComplCr AS BalanceIsBroken
	|FROM
	|	TTSetOfRegisteredRecords AS RecordsSet
	|	,
	|	(SELECT
	|		&Dr AS DrCr
	|	UNION ALL
	|	SELECT
	|		&Cr AS DrCr
	|	) AS PartsOfDoubleEntry
	|WHERE
	|	(PartsOfDoubleEntry.DrCr = &Dr
	|		AND RecordsSet.AccountingObjectDr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|		AND (RecordsSet.ChartOfAccounts.TransactionsWithCorrespondence
	|			OR RecordsSet.RegisterNameDr <> &NameOfRegisterOfServiceAccountingObjects
	|			OR RecordsSet.AccountingObjectDr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)))
	|	OR
	|	(PartsOfDoubleEntry.DrCr = &Cr
	|		AND RecordsSet.AccountingObjectCr <> VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ImproperValues)
	|		AND (RecordsSet.ChartOfAccounts.TransactionsWithCorrespondence
	|			OR RecordsSet.RegisterNameCr <> &NameOfRegisterOfServiceAccountingObjects
	|			OR RecordsSet.AccountingObjectCr = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.OBEntry)))
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf