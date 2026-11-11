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
	Settings.Events.BeforeImportSettingsToComposer = True;
	Settings.Events.BeforeFillQuickSettingsBar = True;
EndProcedure

#EndRegion

#Region EventHandlers

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
	ParametersForm = ThisForm.ParametersForm;
	
	If Parameters.Property("CommandParameter") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		ParametersForm.Insert("CommandParameter", Parameters.CommandParameter);
		
		ValuesOfFunctionalOptions = New Structure("BaseVersion", GetFunctionalOption("BaseVersion"));
		
		CommandParameter = Parameters.CommandParameter;
		
		If TypeOf(CommandParameter) = Type("Array") Then
			ThisIsArray = True;
			If CommandParameter.Count() > 0 Then
				TheFirstControl = CommandParameter[0];
			Else
				TheFirstControl = Undefined;
			EndIf;
		Else
			ThisIsArray = False;
			TheFirstControl = CommandParameter;
		EndIf;
		
		If TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_4")
			Or TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_5_11") Then
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("ReconciliationOfSettlements", 
			                                                                    ValuesOfFunctionalOptions.BaseVersion);
		ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.Counterparties") Then
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("ByCounterpartiesContext", 
			                                                                    ValuesOfFunctionalOptions.BaseVersion);
		ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.CounterpartyContracts") Then
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("PartnersARAPAccounting", 
			                                                                    ValuesOfFunctionalOptions.BaseVersion);
		ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.Partners") Or
			      TypeOf(TheFirstControl) = Type("CatalogRef.PartnersSegments") Then
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("ByPartnersContext", 
			                                                                    ValuesOfFunctionalOptions.BaseVersion);
		ElsIf TypeOf(TheFirstControl) = Type("DocumentRef.ARAPSettlement") Then
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("OnDebtOffsetContext", 
			                                                                    ValuesOfFunctionalOptions.BaseVersion);
		EndIf;
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	If NewDCSettings <> Undefined Then
		SettingsComposer.LoadSettings(NewDCSettings);
	EndIf;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	// Setting default values
	SetRequiredSettings(FormSettingsComposer, True);
	
	NewDCSettings = FormSettingsComposer.Settings;
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on a variant key or report parameters.
//   In order for the schema changes to take effect, the Reportserver method should be called.Connect the Schema().
//   The additional properties of the New Configuration parameter and the Configuration property of the object Settings linker
//   include the properties of the key variant, the key of the defined variant, the context variant 
//   and the form parameter Selection.
//
// Parameters:
//   Context - Arbitrary - 
//       Parameters of the context in which the report is used.
//       Used for passing the ReportServer method parameters.Connect the circuit().
//   SchemaKey - String -
//       ID of the current configuration Builder schema.
//       By default, it is empty (this means that the linker is initialized based on the main schema).
//       Used for optimization to reinitialize the linker as rarely as possible.
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       Name of the predefined or unique ID of the custom version of the report.
//       Undefined when calling for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Builder after it is initialized.
//       Undefined when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings builder after its initialization.
//       It is uncertain when the user settings do not need to be loaded (already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If TypeOf(Context) = Type("ClientApplicationForm")
		And NewDCSettings <> Undefined Then
		If Context.ParametersForm.Property("CommandParameter") Then
			Parameters = Context.Parameters;
			GenerateReportParameters(Context.ParametersForm.CommandParameter, Context, Parameters, NewDCSettings);
		EndIf;
	EndIf;
	
EndProcedure

// Is called before refilling the settings panel of the report form.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   FillParameters - Structure - Parameters to be uploaded to the report:
//   * ReportObjectOrFullName - ReportObject - report.
//
Procedure BeforeFillQuickSettingsBar(ThisForm, FillParameters) Export
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		If TypeOf(FillParameters.ReportObjectOrFullName) = Type("String") Then
			UserSettingsElements = SettingsComposer.Settings.Filter.Items;
		Else
			FilterReport_ = FillParameters.ReportObjectOrFullName.SettingsComposer.Settings.Filter; // DataCompositionFilter -
			UserSettingsElements = FilterReport_.Items;
		EndIf;
		
		For Each FilterElement In UserSettingsElements Do
			If FilterElement.LeftValue = New DataCompositionField("Partner") Then
				FilterElement.UserSettingPresentation = "Counterparty";
				Break;
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(SettingsComposer, UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	ReportDataParameter = DataCompositionClientServer.GetParameter(ReportSettings,"ReportData");
	Calculations = DataCompositionSchema.DataSets.Calculations; // DataCompositionSchemaDataSetUnion -
	
	// Let's define the composition of the selected fields
	SelectedFieldsArray = New Array;
	FindSelectedFieldsRecursively(ReportSettings.Selection.Items, SelectedFieldsArray);
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRequestForSelectionByPartnerSegment());
	QueriesTexts.Add(QueryTextCustomersARAPAccounting(SelectedFieldsArray, ReportSettings, DataCompositionSchema.CalculatedFields));
	QueryText = StrConcat(QueriesTexts, ";");
	Calculations.Items.CustomersARAPAccounting.Query = QueryText;
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRequestForSelectionByPartnerSegment());
	QueriesTexts.Add(QueryTextVendorsARAPAccounting(SelectedFieldsArray, ReportSettings, DataCompositionSchema.CalculatedFields));
	QueryText = StrConcat(QueriesTexts, ";");
	Calculations.Items.VendorsARAPAccounting.Query = QueryText;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	//A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
	// We will inform the report form that the settings have been modified
	If UserSettingsModified Then
		SettingsComposer.UserSettings.AdditionalProperties.Insert("UserSettingsModified", True);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetRequiredSettings(Var_SettingsComposer, UserSettingsModified)
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(Var_SettingsComposer);
	SetReportDate(Var_SettingsComposer, UserSettingsModified);
	
EndProcedure

Procedure SetReportDate(Var_SettingsComposer, UserSettingsModified)
	
	ReportDateParameterBorder = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "PeriodEndBoundary");
	ReportDateParameterBorder.Use = True;

	PeriodParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "Period"); // DataCompositionSettingsParameterValue -
	PeriodValue_ = PeriodParameter.Value; // StandardPeriod - 
	If PeriodParameter.Use And ValueIsFilled(PeriodValue_.StartDate) Then
		DataCompositionClientServer.SetParameter(Var_SettingsComposer, "BeginBalance", PeriodValue_.StartDate);
		ReportDateParameterBorder.Value = New Boundary(EndOfDay(PeriodValue_.EndDate), BoundaryType.Including);
	Else
		DataCompositionClientServer.SetParameter(Var_SettingsComposer, "BeginBalance", Date(1,1,1,0,0,1));
		ReportDateParameterBorder.Value = Date(1,1,1)
	EndIf;
	
EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
EndProcedure

Function QueryTextCustomersARAPAccounting(SelectedFieldsArray, ReportSettings, CalculatedFields)
	
	QueryText = "
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization AS Organization,
	|	DimensionAccounting_1.Partner AS Partner,
	|	DimensionAccounting_1.Counterparty AS Counterparty,
	|	DimensionAccounting_1.Contract AS Contract,
	|	DimensionAccounting_1.LineOfBusiness AS LineOfBusinessOfAnalytics,
	|	DimensionAccounting_1.DimensionKey AS DimensionKey
	|INTO TT_AccountingDimensionByPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|WHERE
	|		DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|{WHERE
	|	DimensionAccounting_1.Organization.* AS Organization,
	|	DimensionAccounting_1.Partner.* AS Partner,
	|	DimensionAccounting_1.Counterparty.* AS Counterparty,
	|	DimensionAccounting_1.Contract.* AS Contract,
	|	(DimensionAccounting_1.Partner IN
	|			(SELECT
	|				SelectionByPartnerSegment.Partner
	|			FROM
	|				SelectionByPartnerSegment
	|			WHERE
	|				SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|INDEX BY
	|	DimensionKey
	|;
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization                       AS Organization,
	|	DimensionAccounting_1.Partner                           AS Partner,
	|	DimensionAccounting_1.Counterparty                        AS Counterparty,
	|	DimensionAccounting_1.Contract                           AS Contract,
	|	CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|	END                                            AS LineOfBusiness,
	|	CalculationsByTerms.ARAPObject                   AS ARAPObject,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                            AS Currency,
	|	CalculationsByTerms.ARAPDocument                AS ARAPDocument,
	|	CalculationsByTerms.OccurrenceDate                AS OccurrenceDate,
	|	CalculationsByTerms.PlannedRepaymentDate           AS PlannedRepaymentDate,
	|
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManOpeningBalance
	|		ELSE CalculationsByTerms.DebtLocalOpeningBalance
	|	END                                            AS PartnerDebt_OpeningBalance,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManOpeningBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalOpeningBalance
	|	END                                            AS AccountsPayableOfCompanyOpeningBalance,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtOpeningBalance - CalculationsByTerms.PrepaymentOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManOpeningBalance - CalculationsByTerms.PrepaymentManOpeningBalance
	|		ELSE CalculationsByTerms.DebtLocalOpeningBalance - CalculationsByTerms.PrepaymentLocalOpeningBalance
	|	END                                            AS InitialBalance_,
	|
	|	0                                                AS PaidToPartner,
	|	0                                                AS ShippedToPartner,
	|	0                                                AS SetOff,
	|	0                                                AS ShippedToUs,
	|	0                                                AS PaidToUs,
	|	0                                                AS WriteOffRevaluation,
	|
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManClosingBalance
	|		ELSE CalculationsByTerms.DebtLocalClosingBalance
	|	END                                            AS PartnerDebt_ClosingBalance,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManClosingBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalClosingBalance
	|	END                                            AS AccountsPayableOfCompanyClosingBalance,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtClosingBalance - CalculationsByTerms.PrepaymentClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManClosingBalance - CalculationsByTerms.PrepaymentManClosingBalance
	|		ELSE CalculationsByTerms.DebtLocalClosingBalance - CalculationsByTerms.PrepaymentLocalClosingBalance
	|	END                                            AS FinalBalance,
	|
	|	2                                                AS PaymentType_,
	|	NULL                                             AS Recorder,
	|	CalculationsByTerms.Recorder                      AS ARAPAccountingRecorder,
	|
	|	CalculationsByTerms.SecondPeriod                    AS SecondPeriod,
	|	CalculationsByTerms.DayPeriod                       AS DayPeriod,
	|	CalculationsByTerms.WeekPeriod                     AS WeekPeriod,
	|	CalculationsByTerms.TenDaysPeriod                     AS TenDaysPeriod,
	|	CalculationsByTerms.MonthPeriod                      AS MonthPeriod,
	|	CalculationsByTerms.QuarterPeriod                    AS QuarterPeriod,
	|	CalculationsByTerms.HalfYearPeriod                  AS HalfYearPeriod,
	|	CalculationsByTerms.YearPeriod                        AS YearPeriod
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto, ,
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsByTerms
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|WHERE
	|	&PaymentType_ <= 2
	|	AND (CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManOpeningBalance
	|		ELSE CalculationsByTerms.DebtLocalOpeningBalance
	|	END <> 0 OR
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManOpeningBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalOpeningBalance
	|	END <> 0 OR
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManClosingBalance
	|		ELSE CalculationsByTerms.DebtLocalClosingBalance
	|	END <> 0 OR
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManClosingBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalClosingBalance
	|	END <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Counterparty,
	|	DimensionAccounting_1.Contract,
	|	CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|	END,
	|	CalculationsByTerms.ARAPObject,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                            AS Currency,
	|	CalculationsByTerms.ARAPDocument,
	|	CalculationsByTerms.OccurrenceDate,
	|	CalculationsByTerms.PlannedRepaymentDate,
	|
	|	0                                                AS PartnerDebt_OpeningBalance,
	|	0                                                AS AccountsPayableOfCompanyOpeningBalance,
	|	0                                                AS InitialBalance_,
	|	0                                                AS PaidToPartner,
	|	&ShippedToPartner                               AS ShippedToPartner,
	|	&SetOff                                         AS SetOff,
	|	0                                                AS ShippedToUs,
	|	&PaidToUs                                     AS PaidToUs,
	|	&WriteOffRevaluation                              AS WriteOffRevaluation,
	|	0                                                AS PartnerDebt_ClosingBalance,
	|	0                                                AS AccountsPayableOfCompanyClosingBalance,
	|	0                                                AS FinalBalance,
	|
	|	2                                                AS PaymentType_,
	|	CalculationsByTerms.DocumentRecorder              AS Recorder,
	|	CalculationsByTerms.Recorder                      AS ARAPAccountingRecorder,
	|
	|	CalculationsByTerms.Period                           AS SecondPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, DAY)      AS DayPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, WEEK)    AS WeekPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, TENDAYS)    AS TenDaysPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, MONTH)     AS MonthPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, QUARTER)   AS QuarterPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, YEAR)       AS YearPeriod
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|		ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|WHERE
	|	&PaymentType_ <= 2
	|	AND CalculationsByTerms.Active
	|	AND (&SelectionOfSelectedFields)
	|{WHERE
	|	CalculationsByTerms.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod}
	|";
	
	SelectionText_ = "";
	For Each SelectedField In SelectedFieldsArray Do
		If CalculatedFields.Find(String(SelectedField.Field)) = Undefined
			And ReportSettings.SelectionAvailableFields.Items.Find(SelectedField.Field) <> Undefined
			And ReportSettings.SelectionAvailableFields.Items.Find(SelectedField.Field).Type.Types().Find(Type("Number")) <> Undefined Then
			If StrFind(String(SelectedField.Field),"UserFields") = 0 
				And StrFind("&ShippedToPartner, &SetOff, &PaidToUs, &WriteOffRevaluation", String(SelectedField.Field)) > 0 Then
				SelectionText_ = SelectionText_ + ?(SelectionText_ = "","", "OR") +"
					|	&" + String(SelectedField.Field) + " <> 0 ";
			EndIf;
		EndIf;
	EndDo;
	QueryText = StrReplace(QueryText, "&SelectionOfSelectedFields", ?(SelectionText_ = "", "FALSE", SelectionText_));
	
	QueryText = StrReplace(QueryText,"&ShippedToPartner", ARAPAccountingReports.TemplateOfShippedField());
	QueryText = StrReplace(QueryText,"&SetOff", ARAPAccountingReports.TemplateOfCreditedField());
	QueryText = StrReplace(QueryText,"&PaidToUs", ARAPAccountingReports.TemplateForPaidField());
	QueryText = StrReplace(QueryText,"&WriteOffRevaluation", ARAPAccountingReports.TemplateForWriteOffRevaluationField());
	
	Return QueryText;
	
EndFunction

Function QueryTextVendorsARAPAccounting(SelectedFieldsArray, ReportSettings, CalculatedFields)
	
	QueryText = "
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization AS Organization,
	|	DimensionAccounting_1.Partner AS Partner,
	|	DimensionAccounting_1.Counterparty AS Counterparty,
	|	DimensionAccounting_1.Contract AS Contract,
	|	DimensionAccounting_1.LineOfBusiness AS LineOfBusinessOfAnalytics,
	|	DimensionAccounting_1.DimensionKey AS DimensionKey
	|INTO TT_AccountingDimensionByPartners
	|FROM
	|	InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|WHERE
	|		DimensionAccounting_1.Partner <> VALUE(Catalog.Partners.OurEnterprise)
	|{WHERE
	|	DimensionAccounting_1.Organization.* AS Organization,
	|	DimensionAccounting_1.Partner.* AS Partner,
	|	DimensionAccounting_1.Counterparty.* AS Counterparty,
	|	DimensionAccounting_1.Contract.* AS Contract,
	|	(DimensionAccounting_1.Partner IN
	|			(SELECT
	|				SelectionByPartnerSegment.Partner
	|			FROM
	|				SelectionByPartnerSegment
	|			WHERE
	|				SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|INDEX BY
	|	DimensionKey
	|;
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization                       AS Organization,
	|	DimensionAccounting_1.Partner                           AS Partner,
	|	DimensionAccounting_1.Counterparty                        AS Counterparty,
	|	DimensionAccounting_1.Contract                           AS Contract,
	|	CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|	END                                            AS LineOfBusiness,
	|	CalculationsByTerms.ARAPObject                   AS ARAPObject,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                            AS Currency,
	|	CalculationsByTerms.ARAPDocument                AS ARAPDocument,
	|	CalculationsByTerms.OccurrenceDate                AS OccurrenceDate,
	|	CalculationsByTerms.PlannedRepaymentDate           AS PlannedRepaymentDate,
	|
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManOpeningBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalOpeningBalance
	|	END                                            AS PartnerDebt_OpeningBalance,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManOpeningBalance
	|		ELSE CalculationsByTerms.DebtLocalOpeningBalance
	|	END                                            AS AccountsPayableOfCompanyOpeningBalance,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentOpeningBalance - CalculationsByTerms.DebtOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManOpeningBalance - CalculationsByTerms.ARAPManOpeningBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalOpeningBalance - CalculationsByTerms.DebtLocalOpeningBalance
	|	END                                            AS InitialBalance_,
	|
	|	0                                                AS PaidToPartner,
	|	0                                                AS ShippedToPartner,
	|	0                                                AS SetOff,
	|	0                                                AS ShippedToUs,
	|	0                                                AS PaidToUs,
	|	0                                                AS WriteOffRevaluation,
	|
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManClosingBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalClosingBalance
	|	END                                            AS PartnerDebt_ClosingBalance,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManClosingBalance
	|		ELSE CalculationsByTerms.DebtLocalClosingBalance
	|	END                                            AS AccountsPayableOfCompanyClosingBalance,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentClosingBalance - CalculationsByTerms.DebtClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManClosingBalance - CalculationsByTerms.ARAPManClosingBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalClosingBalance - CalculationsByTerms.DebtLocalClosingBalance
	|	END                                            AS FinalBalance,
	|
	|	3                                                AS PaymentType_,
	|	NULL                                             AS Recorder,
	|	CalculationsByTerms.Recorder                      AS ARAPAccountingRecorder,
	|
	|	CalculationsByTerms.SecondPeriod                    AS SecondPeriod,
	|	CalculationsByTerms.DayPeriod                       AS DayPeriod,
	|	CalculationsByTerms.WeekPeriod                     AS WeekPeriod,
	|	CalculationsByTerms.TenDaysPeriod                     AS TenDaysPeriod,
	|	CalculationsByTerms.MonthPeriod                      AS MonthPeriod,
	|	CalculationsByTerms.QuarterPeriod                    AS QuarterPeriod,
	|	CalculationsByTerms.HalfYearPeriod                  AS HalfYearPeriod,
	|	CalculationsByTerms.YearPeriod                        AS YearPeriod
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto, ,
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsByTerms
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|WHERE
	|	&PaymentType_ <> 2
	|	AND (CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManOpeningBalance
	|		ELSE CalculationsByTerms.DebtLocalOpeningBalance
	|	END <> 0 OR
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentOpeningBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManOpeningBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalOpeningBalance
	|	END <> 0 OR
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManClosingBalance
	|		ELSE CalculationsByTerms.DebtLocalClosingBalance
	|	END <> 0 OR
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentClosingBalance
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManClosingBalance
	|		ELSE CalculationsByTerms.PrepaymentLocalClosingBalance
	|	END <> 0 OR
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.DebtTurnover
	|		WHEN 2
	|			THEN CalculationsByTerms.ARAPManTurnover
	|		ELSE CalculationsByTerms.DebtLocalTurnover
	|	END <> 0 OR
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.PrepaymentTurnover
	|		WHEN 2
	|			THEN CalculationsByTerms.PrepaymentManTurnover
	|		ELSE CalculationsByTerms.PrepaymentLocalTurnover
	|	END <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	DimensionAccounting_1.Organization,
	|	DimensionAccounting_1.Partner,
	|	DimensionAccounting_1.Counterparty,
	|	DimensionAccounting_1.Contract,
	|	CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|	END,
	|	CalculationsByTerms.ARAPObject,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                            AS Currency,
	|	CalculationsByTerms.ARAPDocument,
	|	CalculationsByTerms.OccurrenceDate,
	|	CalculationsByTerms.PlannedRepaymentDate,
	|
	|	0                                                AS PartnerDebt_OpeningBalance,
	|	0                                                AS AccountsPayableOfCompanyOpeningBalance,
	|	0                                                AS InitialBalance_,
	|	&PaidToPartner                                AS PaidToPartner,
	|	0                                                AS ShippedToPartner,
	|	&SetOff                                         AS SetOff,
	|	&ShippedToUs                                    AS ShippedToUs,
	|	0                                                AS PaidToUs,
	|	&WriteOffRevaluation                              AS WriteOffRevaluation,
	|	0                                                AS PartnerDebt_ClosingBalance,
	|	0                                                AS AccountsPayableOfCompanyClosingBalance,
	|	0                                                AS FinalBalance,
	|
	|	3                                                AS PaymentType_,
	|	CalculationsByTerms.DocumentRecorder              AS Recorder,
	|	CalculationsByTerms.Recorder                      AS ARAPAccountingRecorder,
	|
	|	CalculationsByTerms.Period                           AS SecondPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, DAY)      AS DayPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, WEEK)    AS WeekPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, TENDAYS)    AS TenDaysPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, MONTH)     AS MonthPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, QUARTER)   AS QuarterPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, HALFYEAR) AS HalfYearPeriod,
	|	BEGINOFPERIOD(CalculationsByTerms.Period, YEAR)       AS YearPeriod
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDueDates AS CalculationsByTerms
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|		ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|WHERE
	|	&PaymentType_ <> 2
	|	AND CalculationsByTerms.Active
	|	AND (&SelectionOfSelectedFields)
	|{WHERE
	|	CalculationsByTerms.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod}
	|";
	
	SelectionText_ = "";
	For Each SelectedField In SelectedFieldsArray Do
		If CalculatedFields.Find(String(SelectedField.Field)) = Undefined
			And ReportSettings.SelectionAvailableFields.Items.Find(SelectedField.Field) <> Undefined
			And ReportSettings.SelectionAvailableFields.Items.Find(SelectedField.Field).Type.Types().Find(Type("Number")) <> Undefined Then
			If StrFind(String(SelectedField.Field),"UserFields") = 0 
				And StrFind("&ShippedToUs, &SetOff, &PaidToPartner, &WriteOffRevaluation", String(SelectedField.Field)) > 0 Then
				SelectionText_ = SelectionText_ + ?(SelectionText_ = "","", "OR") +"
					|	&" + String(SelectedField.Field) + " <> 0 ";
			EndIf;
		EndIf;
	EndDo;
	QueryText = StrReplace(QueryText, "&SelectionOfSelectedFields", ?(SelectionText_ = "", "FALSE", SelectionText_));
	
	QueryText = StrReplace(QueryText,"&ShippedToUs", ARAPAccountingReports.TemplateOfShippedField());
	QueryText = StrReplace(QueryText,"&SetOff", ARAPAccountingReports.TemplateOfCreditedField());
	QueryText = StrReplace(QueryText,"&PaidToPartner", ARAPAccountingReports.TemplateForPaidField());
	QueryText = StrReplace(QueryText,"&WriteOffRevaluation", ARAPAccountingReports.TemplateForWriteOffRevaluationField());
	
	Return QueryText;
	
EndFunction

Function TextOfRequestForSelectionByPartnerSegment()
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	Segments.Partner AS Partner,
	|	TRUE           AS FilterByPartnerSegmentIsUsed
	|INTO SelectionByPartnerSegment
	|FROM
	|	InformationRegister.SegmentPartners AS Segments
	|{WHERE
	|	Segments.Segment.* AS PartnersSegment,
	|	Segments.Partner.* AS Partner}
	|
	|INDEX BY
	|	Partner,
	|	FilterByPartnerSegmentIsUsed
	|";
	
	Return QueryText;
	
EndFunction

Procedure GenerateReportParameters(CommandParameter, ThisForm, Parameters, NewDCSettings)
	
	FormParameters = ThisForm.ParametersForm;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		ThisIsArray = True;
		If CommandParameter.Count() > 0 Then
			TheFirstControl = CommandParameter[0];
		Else
			TheFirstControl = Undefined;
		EndIf;
	Else
		ThisIsArray = False;
		TheFirstControl = CommandParameter;
	EndIf;
	
	If TypeOf(TheFirstControl) = Type("CatalogRef.Partners") Then
		If ThisIsArray Then
			ThereAreSubordinatePartners = False;
			For Each CommandParameterElement In CommandParameter Do
				If PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameterElement) Then
					ThereAreSubordinatePartners = True;
					Break;
				EndIf;
			EndDo;
		Else
			ThereAreSubordinatePartners = PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameter);
		EndIf;
		
		If ThereAreSubordinatePartners Then
			FormParameters.PurposeUseKey = "Partners_Group";
			Parameters.PurposeUseKey = "Partners_Group";
		Else
			FormParameters.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
		EndIf;
		FilterValue = CommandParameter;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If ThisIsArray Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(CommandParameter);
			If ThereAreSubordinatePartners Then
				DCComparisonType = DataCompositionComparisonType.InListByHierarchy;
			Else
				DCComparisonType = DataCompositionComparisonType.InList;
			EndIf;
		Else
			If ThereAreSubordinatePartners Then
				DCComparisonType = DataCompositionComparisonType.InHierarchy;
			Else
				DCComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
		EndIf;
		CommonClientServer.SetFilterItem(
			NewDCSettings.Filter,
			"Partner",
			FilterValue,
			DCComparisonType,,
			True);
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.CounterpartyContracts") 
		Or TypeOf(TheFirstControl) = Type("CatalogRef.IntercompanyContracts") Then
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		FilterValue = TheFirstControl;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If ThisIsArray Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(CommandParameter);
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		CommonClientServer.SetFilterItem(
			NewDCSettings.Filter, 
			"Contract",
			FilterValue,
			DCComparisonType,,
			True);
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.PartnersSegments") Then
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		FilterValue = TheFirstControl;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If ThisIsArray Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(CommandParameter);
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		CommonClientServer.SetFilterItem(
			NewDCSettings.Filter, 
			"PartnersSegment",
			FilterValue,
			DCComparisonType,,
			True);
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.ARAPObjects") Then
		If ThisIsArray Then
			FormParameters.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
		Else
			FormParameters.PurposeUseKey = TheFirstControl;
			Parameters.PurposeUseKey = TheFirstControl;
		EndIf;
		FilterValue = TheFirstControl;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If ThisIsArray Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(CommandParameter);
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		CommonClientServer.SetFilterItem(
			NewDCSettings.Filter, 
			"ARAPObject",
			FilterValue,
			DCComparisonType,,
			True);
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.Counterparties") Then
		FormParameters.PurposeUseKey = "Counterparty";
		Parameters.PurposeUseKey = "Counterparty";
		FilterValue = TheFirstControl;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If ThisIsArray Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(CommandParameter);
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		CommonClientServer.SetFilterItem(
			NewDCSettings.Filter, 
			"Counterparty",
			FilterValue,
			DCComparisonType,,
			True);
	ElsIf TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_4")
		Or TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_5_11") Then
		Attributes = Undefined;
		If TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_4") Then
			Attributes = Documents.ARAPReconciliation2_4.DocumentAttributes(TheFirstControl);
		ElsIf TypeOf(TheFirstControl) = Type("DocumentRef.ARAPReconciliation2_5_11") Then
			Attributes = Documents.ARAPReconciliation2_5_11.DocumentAttributes(TheFirstControl);
		EndIf;
		
		If Attributes <> Undefined Then
			If ValueIsFilled(Attributes.Organization) Then	
				CommonClientServer.SetFilterItem(
					NewDCSettings.Filter, 
					"Organization",
					Attributes.Organization,
					DataCompositionComparisonType.Equal,,
					True);
			EndIf;
			If ValueIsFilled(Attributes.Counterparty) Then
				If GetFunctionalOption("UsePartnersAndCounterparties") Then
					CommonClientServer.SetFilterItem(
						NewDCSettings.Filter, 
						"Counterparty",
						Attributes.Counterparty,
						DataCompositionComparisonType.Equal,,
						True);
				Else
					CommonClientServer.SetFilterItem(
						NewDCSettings.Filter, 
						"Partner",
						Common.ObjectAttributeValue(Attributes.Counterparty,"Partner"),
						DataCompositionComparisonType.Equal,,
						True);
				EndIf;
			EndIf;
			Period = DataCompositionClientServer.GetParameter(NewDCSettings, "Period");
			Period.Value.Variant = StandardPeriodVariant.Custom;
			Period.Value.StartDate = Attributes.BeginOfPeriod;
			Period.Value.EndDate = Attributes.EndOfPeriod;
			Period.Use = True;
		EndIf;
	ElsIf TypeOf(TheFirstControl) = Type("DocumentRef.ARAPSettlement") Then
		Attributes = GetSelectionsForDebtOffsetting(TheFirstControl);
		CommonClientServer.SetFilterItem(
			NewDCSettings.Filter, 
			"Organization",
			Attributes.Organization,
			DataCompositionComparisonType.InList,,
			True);
		CommonClientServer.SetFilterItem(
			NewDCSettings.Filter, 
			"Partner",
			Attributes.Partner,
			DataCompositionComparisonType.InList,,
			True);
		Period = DataCompositionClientServer.GetParameter(NewDCSettings, "Period");
		Period.Value.Variant = StandardPeriodVariant.Custom;
		Period.Value.StartDate = BegOfMonth(Attributes.Date);
		Period.Value.EndDate = CurrentSessionDate();
		Period.Use = True;
	Else
		ARAPObject = ARAPAccountingServer.ObjectOfCalculationsByReference(TheFirstControl);
		FormParameters.PurposeUseKey = ARAPObject;
		Parameters.PurposeUseKey = ARAPObject;
		FilterValue = ARAPObject;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If TypeOf(ARAPObject) = Type("Array") Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(ARAPObject);
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		CommonClientServer.SetFilterItem(
			NewDCSettings.Filter, 
			"ARAPObject",
			FilterValue,
			DCComparisonType,,
			True);
	EndIf;
	
EndProcedure

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "ReconciliationOfSettlements" Then
		Return "ReconciliationOfMutualSettlementsContextBasic";
	ElsIf VariantKeyName = "OnDebtOffsetContext" Then
		Return "ForDebtOffsetContextBasic";
	ElsIf VariantKeyName = "ByCounterpartiesContext" Then
		Return "ForCounterpartiesContextBasic";
	ElsIf VariantKeyName = "PartnersARAPAccounting" Then
		Return "SettlementsWithPartnersAreBasic";
	ElsIf VariantKeyName = "ByPartnersContext" Then
		Return "ByPartnersContextBasic";
	EndIf;
	
EndFunction

Procedure FindSelectedFieldsRecursively(ItemsCollection, ItemArray)

	For Each Item In ItemsCollection Do
		
		If TypeOf(Item) = Type("DataCompositionSelectedField") Then
			If Item.Use Then
				ItemArray.Add(Item);
			EndIf;
		Else
			FindSelectedFieldsRecursively(Item.Items, ItemArray);
		EndIf;
		
	EndDo;

EndProcedure

Function GetSelectionsForDebtOffsetting(Ref)
	
	Result = New Structure;
	Result.Insert("Organization", New ValueList);
	Result.Insert("Partner", New ValueList);
	Result.Insert("Date", Date(1, 1, 1));
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text = 
		"SELECT
		|	ARAPSettlement.Organization AS Organization,
		|	ARAPSettlement.Date AS Date,
		|	ARAPSettlement.CounterpartyDebtor AS CounterpartyDebtor,
		|	ARAPSettlement.Creditor AS Creditor,
		|	ARAPSettlement.CompanyCreditor AS CompanyCreditor
		|FROM
		|	Document.ARAPSettlement AS ARAPSettlement
		|WHERE
		|	ARAPSettlement.Ref = &Ref
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccountsReceivable.Partner AS Partner
		|FROM
		|	Document.ARAPSettlement.AccountsReceivable AS AccountsReceivable
		|WHERE
		|	AccountsReceivable.Ref = &Ref
		|
		|UNION ALL
		|
		|SELECT
		|	AccountsPayable.Partner
		|FROM
		|	Document.ARAPSettlement.AccountsPayable AS AccountsPayable
		|WHERE
		|	AccountsPayable.Ref = &Ref";
	
	QueryResult = Query.ExecuteBatch();
	
	Selection = QueryResult[0].Select();
	While Selection.Next() Do
		If ValueIsFilled(Selection.Organization) Then
			Result.Organization.Add(Selection.Organization);
		EndIf;
		If ValueIsFilled(Selection.CounterpartyDebtor)
			And TypeOf(Selection.CounterpartyDebtor) = Type("CatalogRef.Companies") Then
			Result.Organization.Add(Selection.CounterpartyDebtor);
		EndIf;
		If ValueIsFilled(Selection.Creditor)
			And TypeOf(Selection.Creditor) = Type("CatalogRef.Companies") Then
			Result.Organization.Add(Selection.Creditor);
		EndIf;
		If ValueIsFilled(Selection.CompanyCreditor) Then
			Result.Organization.Add(Selection.CompanyCreditor);
		EndIf;
		Result.Date = Selection.Date;
	EndDo;
	
	Partners = New Array;
	Selection = QueryResult[1].Select();
	While Selection.Next() Do
		If ValueIsFilled(Selection.Partner) Then
			Partners.Add(Selection.Partner);
		EndIf;
	EndDo;
	Partners = CommonClientServer.CollapseArray(Partners);
	
	Result.Partner.LoadValues(Partners);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf