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

#EndRegion

#Region EventHandlers

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//   	* Parameters - Structure:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		GenerateReportParameters(Parameters.CommandParameter, ThisForm.ParametersForm, Parameters);
		
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
			
		EndIf;
		
	EndIf;
	
	ParametersForm = ThisForm.ParametersForm;
	
	If ParametersForm.Property("Filter")
	 And ParametersForm.Filter.Property("ARAPSettlement") Then
		NettingLink = ParametersForm.Filter.ARAPSettlement[0];
		Attributes = Common.ObjectAttributesValues(NettingLink, "Date,OperationKind,Organization,CompanyCreditor,CounterpartyDebtor,Creditor");
		If Attributes <> Undefined Then
			If ValueIsFilled(Attributes.Organization) Then	
				ParametersForm.Filter.Insert("Organization", Attributes.Organization);
				If ValueIsFilled(Attributes.CompanyCreditor) Then
					Filter = New Array;
					Filter.Add(Attributes.Organization);
					Filter.Add(Attributes.CompanyCreditor);
					ParametersForm.Filter.Insert("Organization", Filter);
				EndIf;
			EndIf;
			If ValueIsFilled(Attributes.CounterpartyDebtor) Then
				CounterpartyDebtor = Attributes.CounterpartyDebtor;
				If Not GetFunctionalOption("UsePartnersAndCounterparties") Then
					CounterpartyDebtor = Common.ObjectAttributeValue(Attributes.CounterpartyDebtor,"Partner");
				EndIf;
				SelectionByConagent = CounterpartyDebtor; 
				If ValueIsFilled(Attributes.Creditor)
					And Attributes.Creditor <> Attributes.CounterpartyDebtor Then
					Creditor = Attributes.Creditor;
					If Not GetFunctionalOption("UsePartnersAndCounterparties") Then
						Creditor = Common.ObjectAttributeValue(Attributes.Creditor,"Partner");
					EndIf; 
					SelectionByConagent = New Array;
					SelectionByConagent.Add(CounterpartyDebtor);
					SelectionByConagent.Add(Creditor);
				EndIf;
				If GetFunctionalOption("UsePartnersAndCounterparties") Then
					ParametersForm.Filter.Insert("Counterparty", SelectionByConagent);
				Else
					ParametersForm.Filter.Insert("Partner", SelectionByConagent);
				EndIf;
			EndIf;
			Period = New StandardPeriod;
			Period.Variant = StandardPeriodVariant.Custom;
			Period.StartDate = BegOfMonth(Attributes.Date);
			Period.EndDate = EndOfDay(Attributes.Date);
			ParametersForm.Filter.Insert("Period", Period);
		EndIf;
		ParametersForm.Filter.Delete("ARAPSettlement");
		
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	// Setting default values
	SetRequiredSettings(FormSettingsComposer, True);
	
	NewDCSettings = FormSettingsComposer.Settings;
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	
	SetRequiredSettings(SettingsComposer, UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	// Let's define the composition of the selected fields
	SelectedFieldsArray = New Array;
	FindSelectedFieldsRecursively(ReportSettings.Selection.Items, SelectedFieldsArray);
	ArrayOfNamesOfSelectedFields = New Array;
	For Each SelectedField In SelectedFieldsArray Do
		ArrayOfNamesOfSelectedFields.Add(String(SelectedField.Field));
	EndDo;
	CheckCompleteNamesOfSelectedFields(ArrayOfNamesOfSelectedFields);
	
	// Let's set the query texts of data sets:
	// Calculations by timing
	DataSet = DataCompositionSchema.DataSets.DataSet; // DataCompositionSchemaDataSetUnion 
	
	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRequestForSelectionByPartnerSegment());
	QueriesTexts.Add(
		QueryTextCalculationsByTerms(
			ArrayOfNamesOfSelectedFields, 
			ReportSettings, 
			DataCompositionSchema.CalculatedFields));
	QueryText = StrConcat(QueriesTexts, ";");
	DataSet.Items.CalculationsByTerms.Query = QueryText;
	
	// Payment plan
	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRequestForSelectionByPartnerSegment());
	QueriesTexts.Add(QueryTextTTExchangeRates());
	QueriesTexts.Add(
		QueryTextPaymentPlan_(
			ArrayOfNamesOfSelectedFields, 
			ReportSettings, 
			DataCompositionSchema.CalculatedFields));
	QueryText = StrConcat(QueriesTexts, ";");
	DataSet.Items.PaymentPlan_.Query = QueryText;
	
	// Shipment plan
	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRequestForSelectionByPartnerSegment());
	QueriesTexts.Add(QueryTextTTExchangeRates());
	QueriesTexts.Add(
		QueryTextShipmentPlan(
			ArrayOfNamesOfSelectedFields, 
			ReportSettings, 
			DataCompositionSchema.CalculatedFields));
	QueryText = StrConcat(QueriesTexts, ";");
	DataSet.Items.ShipmentPlan.Query = QueryText;
	
	// Calculations
	QueriesTexts = New Array;
	QueriesTexts.Add(TextOfRequestForSelectionByPartnerSegment());
	QueriesTexts.Add(QueryTextTTExchangeRates());
	QueriesTexts.Add(QueryTextCalculations(ArrayOfNamesOfSelectedFields));
	QueryText = StrConcat(QueriesTexts, ";");
	DataSet.Items.Calculations.Query = QueryText;
	
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
	
EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
EndProcedure

Function QueryTextCalculationsByTerms(SelectedFieldsArray, ReportSettings, CalculatedFields)
	
	ThereIsResourceForThisRequest = False;
	ResourceFieldsBalancesTurnover = New Array;
	ResourceFieldsCalculations = ResourceFieldsCalculations(SelectedFieldsArray);
	ResourceFieldsRegisterData = New Array;
	FieldArray = ResourceFields();
	FieldPattern = "
	             |%1 AS %2";
	For Each FieldName In FieldArray Do
		If SelectedFieldsArray.Find(FieldName) <> Undefined Then
			If FieldName = "CustomerAccountsReceivableOpeningBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CASE &ReportData
					|	WHEN 4
					|		THEN CalculationsByTerms.DebtOpeningBalance
					|	WHEN 2
					|		THEN CalculationsByTerms.ARAPManOpeningBalance
					|	ELSE CalculationsByTerms.DebtLocalOpeningBalance
					|END AS CustomerAccountsReceivableOpeningBalance");
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "AccountsPayableOfCompanyOpeningBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CASE &ReportData
					|	WHEN 4
					|		THEN CalculationsByTerms.PrepaymentOpeningBalance
					|	WHEN 2
					|		THEN CalculationsByTerms.PrepaymentManOpeningBalance
					|	ELSE CalculationsByTerms.PrepaymentLocalOpeningBalance
					|END AS AccountsPayableOfCompanyOpeningBalance"); 
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "CustomerAccountsReceivableClosingBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CASE &ReportData
					|	WHEN 4
					|		THEN CalculationsByTerms.DebtClosingBalance
					|	WHEN 2
					|		THEN CalculationsByTerms.ARAPManClosingBalance
					|	ELSE CalculationsByTerms.DebtLocalClosingBalance
					|END AS CustomerAccountsReceivableClosingBalance"); 
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "AccountsPayableOfCompanyClosingBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CASE &ReportData
					|	WHEN 4
					|		THEN CalculationsByTerms.PrepaymentClosingBalance
					|	WHEN 2
					|		THEN CalculationsByTerms.PrepaymentManClosingBalance
					|	ELSE CalculationsByTerms.PrepaymentLocalClosingBalance
					|END AS AccountsPayableOfCompanyClosingBalance"); 
				ThereIsResourceForThisRequest = True;
			Else
				ResourceFieldsBalancesTurnover.Add(StrTemplate(FieldPattern, "0", FieldName));
			EndIf;
			If FieldName = "Shipped" 
				Or FieldName = "SetOff" 
				Or FieldName = "Paid" 
				Or FieldName = "WriteOffRevaluation" Then
				ResourceFieldsRegisterData.Add(StrTemplate(FieldPattern, "&" + FieldName, FieldName));
			Else 
				ResourceFieldsRegisterData.Add(StrTemplate(FieldPattern, "0", FieldName));
			EndIf;
		EndIf;
	EndDo;
	
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
	|		(SELECT
	|			SelectionByPartnerSegment.Partner
	|		FROM
	|			SelectionByPartnerSegment
	|		WHERE
	|			SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|
	|INDEX BY
	|	DimensionKey
	|;
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization                                     AS Organization,
	|	DimensionAccounting_1.Partner                                         AS Partner,
	|	DimensionAccounting_1.Counterparty                                      AS Counterparty,
	|	DimensionAccounting_1.Contract                                         AS Contract,
	|	CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|	END                                                          AS LineOfBusiness,
	|	CalculationsByTerms.ARAPObject                                 AS ARAPObject,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsByTerms.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                                          AS Currency,
	|	VALUE(Catalog.ARAPObjects.EmptyRef)              AS CorARAPObject,
	|	VALUE(Catalog.Partners.EmptyRef)                     AS BalancedClient,
	|	VALUE(Catalog.Companies.EmptyRef)                  AS CorCompany,
	|	VALUE(Catalog.Counterparties.EmptyRef)                  AS CorCounterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef)         AS CorContract,
	|	CalculationsByTerms.ARAPDocument                              AS ARAPDocument,
	|	CalculationsByTerms.OccurrenceDate                              AS OccurrenceDate,
	|	CalculationsByTerms.PlannedRepaymentDate                         AS PlannedRepaymentDate,
	|
	|	NULL                                                           AS Recorder,
	|	CalculationsByTerms.Recorder                                    AS ARAPAccountingRecorder,
	|	CalculationsByTerms.SecondPeriod                                  AS SecondPeriod,
	|
	|	&ResourceFieldsBalancesTurnover
	|
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
	|	&ThereIsResourceForThisRequest
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.Organization                             AS Organization,
	|	Calculations.Partner                                 AS Partner,
	|	Calculations.Counterparty                              AS Counterparty,
	|	Calculations.Contract                                 AS Contract,
	|	Calculations.LineOfBusiness                 AS LineOfBusiness,
	|	Calculations.ARAPObject                          AS ARAPObject,
	|	Calculations.Currency                                  AS Currency,
	|	Calculations.CorARAPObject                       AS CorARAPObject,
	|	Calculations.BalancedClient                               AS BalancedClient,
	|	Calculations.CorCompany                          AS CorCompany,
	|	Calculations.CorCounterparty                           AS CorCounterparty,
	|	Calculations.CorContract                              AS CorContract,
	|	Calculations.ARAPDocument                       AS ARAPDocument,
	|	Calculations.OccurrenceDate                       AS OccurrenceDate,
	|	Calculations.PlannedRepaymentDate                  AS PlannedRepaymentDate,
	|
	|	Calculations.Recorder                             AS Recorder,
	|	Calculations.ARAPAccountingRecorder                     AS ARAPAccountingRecorder,
	|	Calculations.SecondPeriod                           AS SecondPeriod,
	|
	|	&ResourceFieldsCalculations
	|
	|FROM (
	|	SELECT
	|		DimensionAccounting_1.Organization                                       AS Organization,
	|		DimensionAccounting_1.Partner                                           AS Partner,
	|		DimensionAccounting_1.Counterparty                                        AS Counterparty,
	|		DimensionAccounting_1.Contract                                           AS Contract,
	|		CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|		END                                                            AS LineOfBusiness,
	|		CalculationsByTerms.ARAPObject                                   AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsByTerms.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                                            AS Currency,
	|		CalculationsByTerms.CorARAPObject                                AS CorARAPObject,
	|		ISNULL(CalculationsByTerms.CorPartnerAccountingDimension.Partner, 
	|		         VALUE(Catalog.Partners.EmptyRef))             AS BalancedClient,
	|		ISNULL(CalculationsByTerms.CorPartnerAccountingDimension.Organization, 
	|		         VALUE(Catalog.Companies.EmptyRef))          AS CorCompany,
	|		ISNULL(CalculationsByTerms.CorPartnerAccountingDimension.Counterparty, 
	|		         VALUE(Catalog.Counterparties.EmptyRef))          AS CorCounterparty,
	|		ISNULL(CalculationsByTerms.CorPartnerAccountingDimension.Contract, 
	|		         VALUE(Catalog.CounterpartyContracts.EmptyRef)) AS CorContract,
	|		CalculationsByTerms.ARAPDocument                                AS ARAPDocument,
	|		CalculationsByTerms.OccurrenceDate                                AS OccurrenceDate,
	|		CalculationsByTerms.PlannedRepaymentDate                           AS PlannedRepaymentDate,
	|		
	|		CalculationsByTerms.DocumentRecorder                              AS Recorder,
	|		CalculationsByTerms.Recorder                                      AS ARAPAccountingRecorder,
	|		CalculationsByTerms.Period                                           AS SecondPeriod,
	|		
	|		&ResourceFieldsRegisterData
	|		
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates AS CalculationsByTerms
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|	{WHERE
	|		CalculationsByTerms.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod}) AS Calculations
	|
	|GROUP BY
	|	Calculations.Organization,
	|	Calculations.Partner,
	|	Calculations.Counterparty,
	|	Calculations.Contract,
	|	Calculations.LineOfBusiness,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.CorARAPObject,
	|	Calculations.BalancedClient,
	|	Calculations.CorCompany,
	|	Calculations.CorCounterparty,
	|	Calculations.CorContract,
	|	Calculations.ARAPDocument,
	|	Calculations.OccurrenceDate,
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.Recorder,
	|	Calculations.ARAPAccountingRecorder,
	|	Calculations.SecondPeriod
	|HAVING
	|	(&SelectionOfSelectedFields)
	|";
	
	QueryText = StrReplace(QueryText, "&ResourceFieldsBalancesTurnover", StrConcat(ResourceFieldsBalancesTurnover, ","));
	QueryText = StrReplace(QueryText, "&ResourceFieldsCalculations", StrConcat(ResourceFieldsCalculations, ","));
	QueryText = StrReplace(QueryText, "&ResourceFieldsRegisterData", StrConcat(ResourceFieldsRegisterData, ","));
	
	QueryText = StrReplace(QueryText, "&ThereIsResourceForThisRequest", ?(ThereIsResourceForThisRequest, "TRUE", "FALSE"));
	
	QueryText = StrReplace(QueryText,"&Shipped", ARAPAccountingReports.TemplateOfShippedField());
	QueryText = StrReplace(QueryText,"&SetOff", ARAPAccountingReports.TemplateOfCreditedField());
	QueryText = StrReplace(QueryText,"&Paid", ARAPAccountingReports.TemplateForPaidField());
	QueryText = StrReplace(QueryText,"&WriteOffRevaluation", ARAPAccountingReports.TemplateForWriteOffRevaluationField());
	
	ARAPAccountingReports.AddSelectionsOfSelectedFieldsToQuery(QueryText, ReportSettings, DataCompositionSchema.CalculatedFields, "Calculations");
	
	Return QueryText;
	
EndFunction

Function QueryTextPaymentPlan_(SelectedFieldsArray, ReportSettings, CalculatedFields)
	
	ThereIsResourceForThisRequest = False;
	ResourceFieldsBalancesTurnover = New Array;
	ResourceFieldsCalculations = ResourceFieldsCalculations(SelectedFieldsArray);
	ResourceFieldsRegisterData = New Array;
	FieldArray = ResourceFields();
	FieldPattern = "
	             |%1 AS %2";
	For Each FieldName In FieldArray Do
		If SelectedFieldsArray.Find(FieldName) <> Undefined Then
			If FieldName = "SheduledPaymentOpeningBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|PaymentPlanCalculations.AmountDueOpeningBalance *
					|		CurrencyExchangeRate.ZoomRatio AS SheduledPaymentOpeningBalance");
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "SheduledPaymentClosingBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|PaymentPlanCalculations.AmountDueClosingBalance *
					|		CurrencyExchangeRate.ZoomRatio AS SheduledPaymentClosingBalance"); 
				ThereIsResourceForThisRequest = True;
			Else
				ResourceFieldsBalancesTurnover.Add(StrTemplate(FieldPattern, "0", FieldName));
			EndIf;
			If FieldName = "OrderedForPayment" Then
				ResourceFieldsRegisterData.Add("
					|CASE
					|	WHEN VALUETYPE(PaymentPlanCalculations.DocumentPlan) IN (&TypesOfPlanDocuments)
					|			AND PaymentPlanCalculations.RecordType = VALUE(AccumulationRecordType.Receipt)
					|		THEN PaymentPlanCalculations.AmountDue
					|	ELSE 0
					|END * CurrencyExchangeRate.ZoomRatio AS OrderedForPayment");
			Else 
				ResourceFieldsRegisterData.Add(StrTemplate(FieldPattern, "0", FieldName));
			EndIf;
		EndIf;
	EndDo;
	
	QueryText = "
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization AS Organization,
	|	DimensionAccounting_1.Partner AS Partner,
	|	DimensionAccounting_1.Counterparty AS Counterparty,
	|	DimensionAccounting_1.Contract AS Contract,
	|	DimensionAccounting_1.LineOfBusiness AS LineOfBusinessOfAnalytics,
	|
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
	|
	|INDEX BY
	|	DimensionKey
	|;
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization               AS Organization,
	|	DimensionAccounting_1.Partner                   AS Partner,
	|	DimensionAccounting_1.Counterparty                AS Counterparty,
	|	DimensionAccounting_1.Contract                   AS Contract,
	|	CASE WHEN NOT PaymentPlanCalculations.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE PaymentPlanCalculations.ARAPObject.LineOfBusiness
	|	END                                    AS LineOfBusiness,
	|	PaymentPlanCalculations.ARAPObject          AS ARAPObject,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN PaymentPlanCalculations.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                    AS Currency,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
	|	VALUE(Catalog.Partners.EmptyRef)        AS BalancedClient,
	|	VALUE(Catalog.Companies.EmptyRef)     AS CorCompany,
	|	VALUE(Catalog.Counterparties.EmptyRef)     AS CorCounterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS CorContract,
	|	PaymentPlanCalculations.DocumentPlan            AS ARAPDocument,
	|	PaymentPlanCalculations.OccurrenceDate       AS OccurrenceDate,
	|	PaymentPlanCalculations.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|	
	|	NULL                                     AS Recorder,
	|	PaymentPlanCalculations.Recorder             AS ARAPAccountingRecorder,
	|	PaymentPlanCalculations.SecondPeriod           AS SecondPeriod,
	|	
	|	&ResourceFieldsBalancesTurnover
	|	
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.BalanceAndTurnovers({(&BeginOfPeriod)}, {(&EndOfPeriod)}, Auto, ,
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS PaymentPlanCalculations
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|		ON PaymentPlanCalculations.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|		LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|		ON (CurrencyExchangeRate.Currency = PaymentPlanCalculations.Currency)
	|			AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|WHERE
	|	&ThereIsResourceForThisRequest
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.Organization                             AS Organization,
	|	Calculations.Partner                                 AS Partner,
	|	Calculations.Counterparty                              AS Counterparty,
	|	Calculations.Contract                                 AS Contract,
	|	Calculations.LineOfBusiness                 AS LineOfBusiness,
	|	Calculations.ARAPObject                          AS ARAPObject,
	|	Calculations.Currency                                  AS Currency,
	|	VALUE(Catalog.ARAPObjects.EmptyRef)      AS CorARAPObject,
	|	VALUE(Catalog.Partners.EmptyRef)             AS BalancedClient,
	|	VALUE(Catalog.Companies.EmptyRef)          AS CorCompany,
	|	VALUE(Catalog.Counterparties.EmptyRef)          AS CorCounterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS CorContract,
	|	Calculations.ARAPDocument                       AS ARAPDocument,
	|	Calculations.OccurrenceDate                       AS OccurrenceDate,
	|	Calculations.PlannedRepaymentDate                  AS PlannedRepaymentDate,
	|
	|	Calculations.Recorder                             AS Recorder,
	|	Calculations.ARAPAccountingRecorder                     AS ARAPAccountingRecorder,
	|	Calculations.SecondPeriod                           AS SecondPeriod,
	|
	|	&ResourceFieldsCalculations
	|
	|FROM (
	|	SELECT
	|		DimensionAccounting_1.Organization               AS Organization,
	|		DimensionAccounting_1.Partner                   AS Partner,
	|		DimensionAccounting_1.Counterparty                AS Counterparty,
	|		DimensionAccounting_1.Contract                   AS Contract,
	|		CASE WHEN NOT PaymentPlanCalculations.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE PaymentPlanCalculations.ARAPObject.LineOfBusiness
	|		END                                    AS LineOfBusiness,
	|		PaymentPlanCalculations.ARAPObject          AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN PaymentPlanCalculations.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                    AS Currency,
	|		PaymentPlanCalculations.DocumentPlan            AS ARAPDocument,
	|		PaymentPlanCalculations.OccurrenceDate       AS OccurrenceDate,
	|		PaymentPlanCalculations.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|		
	|		PaymentPlanCalculations.DocumentRecorder     AS Recorder,
	|		PaymentPlanCalculations.Recorder             AS ARAPAccountingRecorder,
	|		PaymentPlanCalculations.Period                  AS SecondPeriod,
	|		
	|		&ResourceFieldsRegisterData
	|		
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan AS PaymentPlanCalculations
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON PaymentPlanCalculations.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|			LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|			ON (CurrencyExchangeRate.Currency = PaymentPlanCalculations.Currency)
	|				AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|	{WHERE
	|		PaymentPlanCalculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod}) AS Calculations
	|
	|GROUP BY
	|	Calculations.Organization,
	|	Calculations.Partner,
	|	Calculations.Counterparty,
	|	Calculations.Contract,
	|	Calculations.LineOfBusiness,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	Calculations.OccurrenceDate,
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.Recorder,
	|	Calculations.ARAPAccountingRecorder,
	|	Calculations.SecondPeriod
	|HAVING
	|	(&SelectionOfSelectedFields)
	|";
	
	QueryText = StrReplace(QueryText, "&ResourceFieldsBalancesTurnover", StrConcat(ResourceFieldsBalancesTurnover, ","));
	QueryText = StrReplace(QueryText, "&ResourceFieldsCalculations", StrConcat(ResourceFieldsCalculations, ","));
	QueryText = StrReplace(QueryText, "&ResourceFieldsRegisterData", StrConcat(ResourceFieldsRegisterData, ","));
	
	QueryText = StrReplace(QueryText, "&ThereIsResourceForThisRequest", ?(ThereIsResourceForThisRequest, "TRUE", "FALSE"));
	
	QueryText = StrReplace(QueryText,"&OrderedForPayment", "FALSE");
	QueryText = StrReplace(QueryText,"&TypesOfPlanDocuments", GetPlanDocumentTypes());
	
	ARAPAccountingReports.AddSelectionsOfSelectedFieldsToQuery(QueryText, ReportSettings, DataCompositionSchema.CalculatedFields, "Calculations");
	
	Return QueryText;
	
EndFunction

Function QueryTextShipmentPlan(SelectedFieldsArray, ReportSettings, CalculatedFields)
	
	ThereIsResourceForThisRequest = False;
	ResourceFieldsBalancesTurnover = New Array;
	ResourceFieldsCalculations = ResourceFieldsCalculations(SelectedFieldsArray);
	ResourceFieldsRegisterData = New Array;
	FieldArray = ResourceFields();
	FieldPattern = "
	             |%1 AS %2";
	For Each FieldName In FieldArray Do
		If SelectedFieldsArray.Find(FieldName) <> Undefined Then
			If FieldName = "ScheduledShipmentOpeningBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CalculationsShipmentPlan.SumOpeningBalance *
					|		CurrencyExchangeRate.ZoomRatio AS ScheduledShipmentOpeningBalance");
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "ScheduledShipmentClosingBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CalculationsShipmentPlan.SumClosingBalance *
					|		CurrencyExchangeRate.ZoomRatio AS ScheduledShipmentClosingBalance");
				ThereIsResourceForThisRequest = True;
			Else
				ResourceFieldsBalancesTurnover.Add(StrTemplate(FieldPattern, "0", FieldName));
			EndIf;
			If FieldName = "Ordered" Then
				ResourceFieldsRegisterData.Add("
					|CASE WHEN VALUETYPE(CalculationsShipmentPlan.DocumentPlan) IN (&TypesOfPlanDocuments)
					|			AND CalculationsShipmentPlan.RecordType = VALUE(AccumulationRecordType.Receipt)
					|		THEN CalculationsShipmentPlan.Sum
					|	ELSE 0
					|END * CurrencyExchangeRate.ZoomRatio              AS Ordered");
			Else 
				ResourceFieldsRegisterData.Add(StrTemplate(FieldPattern, "0", FieldName));
			EndIf;
		EndIf;
	EndDo;
	
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
	|
	|INDEX BY
	|	DimensionKey
	|;
	|
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization                  AS Organization,
	|	DimensionAccounting_1.Partner                      AS Partner,
	|	DimensionAccounting_1.Counterparty                   AS Counterparty,
	|	DimensionAccounting_1.Contract                      AS Contract,
	|	CASE WHEN NOT CalculationsShipmentPlan.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CalculationsShipmentPlan.ARAPObject.LineOfBusiness
	|	END                                       AS LineOfBusiness,
	|	CalculationsShipmentPlan.ARAPObject          AS ARAPObject,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CalculationsShipmentPlan.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                       AS Currency,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
	|	VALUE(Catalog.Partners.EmptyRef)        AS BalancedClient,
	|	VALUE(Catalog.Companies.EmptyRef)     AS CorCompany,
	|	VALUE(Catalog.Counterparties.EmptyRef)     AS CorCounterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS CorContract,
	|	CalculationsShipmentPlan.DocumentPlan            AS ARAPDocument,
	|	CalculationsShipmentPlan.OccurrenceDate       AS OccurrenceDate,
	|	CalculationsShipmentPlan.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|	
	|	NULL                                        AS Recorder,
	|	CalculationsShipmentPlan.Recorder             AS ARAPAccountingRecorder,
	|	CalculationsShipmentPlan.SecondPeriod           AS SecondPeriod,
	|	
	|	&ResourceFieldsBalancesTurnover
	|	
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingPlannedShipments.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto, ,
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsShipmentPlan
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON CalculationsShipmentPlan.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|		LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|			ON (CurrencyExchangeRate.Currency = CalculationsShipmentPlan.Currency)
	|				AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|WHERE
	|	&ThereIsResourceForThisRequest
	|
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.Organization                             AS Organization,
	|	Calculations.Partner                                 AS Partner,
	|	Calculations.Counterparty                              AS Counterparty,
	|	Calculations.Contract                                 AS Contract,
	|	Calculations.LineOfBusiness                 AS LineOfBusiness,
	|	Calculations.ARAPObject                          AS ARAPObject,
	|	Calculations.Currency                                  AS Currency,
	|	VALUE(Catalog.ARAPObjects.EmptyRef)      AS CorARAPObject,
	|	VALUE(Catalog.Partners.EmptyRef)             AS BalancedClient,
	|	VALUE(Catalog.Companies.EmptyRef)          AS CorCompany,
	|	VALUE(Catalog.Counterparties.EmptyRef)          AS CorCounterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS CorContract,
	|	Calculations.ARAPDocument                       AS ARAPDocument,
	|	Calculations.OccurrenceDate                       AS OccurrenceDate,
	|	Calculations.PlannedRepaymentDate                  AS PlannedRepaymentDate,
	|
	|	Calculations.Recorder                             AS Recorder,
	|	Calculations.ARAPAccountingRecorder                     AS ARAPAccountingRecorder,
	|	Calculations.SecondPeriod                           AS SecondPeriod,
	|
	|	&ResourceFieldsCalculations
	|
	|FROM (
	|	SELECT
	|		DimensionAccounting_1.Organization                  AS Organization,
	|		DimensionAccounting_1.Partner                      AS Partner,
	|		DimensionAccounting_1.Counterparty                   AS Counterparty,
	|		DimensionAccounting_1.Contract                      AS Contract,
	|		CASE WHEN NOT CalculationsShipmentPlan.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsShipmentPlan.ARAPObject.LineOfBusiness
	|		END                                       AS LineOfBusiness,
	|		CalculationsShipmentPlan.ARAPObject          AS ARAPObject,
	|		CASE &ReportData
	|			WHEN 4
	|				THEN CalculationsShipmentPlan.Currency
	|			WHEN 2
	|				THEN &ManagementAccountingCurrency
	|			ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		END                                       AS Currency,
	|		CalculationsShipmentPlan.DocumentPlan            AS ARAPDocument,
	|		CalculationsShipmentPlan.OccurrenceDate       AS OccurrenceDate,
	|			CalculationsShipmentPlan.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|		
	|		CalculationsShipmentPlan.DocumentRecorder     AS Recorder,
	|		CalculationsShipmentPlan.Recorder             AS ARAPAccountingRecorder,
	|		CalculationsShipmentPlan.Period                  AS SecondPeriod,
	|		
	|		&ResourceFieldsRegisterData
	|		
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingPlannedShipments AS CalculationsShipmentPlan
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsShipmentPlan.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|			LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|				ON (CurrencyExchangeRate.Currency = CalculationsShipmentPlan.Currency)
	|					AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|	{WHERE
	|		CalculationsShipmentPlan.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod}) AS Calculations
	|
	|GROUP BY
	|	Calculations.Organization,
	|	Calculations.Partner,
	|	Calculations.Counterparty,
	|	Calculations.Contract,
	|	Calculations.LineOfBusiness,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	Calculations.OccurrenceDate,
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.Recorder,
	|	Calculations.ARAPAccountingRecorder,
	|	Calculations.SecondPeriod
	|HAVING
	|	(&SelectionOfSelectedFields)
	|";
	
	QueryText = StrReplace(QueryText, "&ResourceFieldsBalancesTurnover", StrConcat(ResourceFieldsBalancesTurnover, ","));
	QueryText = StrReplace(QueryText, "&ResourceFieldsCalculations", StrConcat(ResourceFieldsCalculations, ","));
	QueryText = StrReplace(QueryText, "&ResourceFieldsRegisterData", StrConcat(ResourceFieldsRegisterData, ","));
	
	QueryText = StrReplace(QueryText, "&ThereIsResourceForThisRequest", ?(ThereIsResourceForThisRequest, "TRUE", "FALSE"));
	
	QueryText = StrReplace(QueryText,"&Ordered", "FALSE");
	QueryText = StrReplace(QueryText,"&TypesOfPlanDocuments", GetPlanDocumentTypes());
	
	ARAPAccountingReports.AddSelectionsOfSelectedFieldsToQuery(QueryText, ReportSettings, DataCompositionSchema.CalculatedFields, "Calculations");
	
	Return QueryText;
	
EndFunction

Function QueryTextCalculations(SelectedFieldsArray)
	
	ThereIsResourceForThisRequest = False;
	ResourceFieldsBalancesTurnover = New Array;
	FieldArray = ResourceFields();
	FieldPattern = "
	             |%1 AS %2";
	For Each FieldName In FieldArray Do
		If SelectedFieldsArray.Find(FieldName) <> Undefined Then
			If FieldName = "BeingPaid" Then
				ResourceFieldsBalancesTurnover.Add("
					|CustomersARAPAccounting.BeingPaidTurnover * CurrencyExchangeRate.ZoomRatio AS BeingPaid");
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "BeingPaidOpeningBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CustomersARAPAccounting.BeingPaidOpeningBalance * CurrencyExchangeRate.ZoomRatio AS BeingPaidOpeningBalance");
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "BeingPaidClosingBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CustomersARAPAccounting.BeingPaidClosingBalance * CurrencyExchangeRate.ZoomRatio AS BeingPaidClosingBalance");
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "BeingShipped" Then
				ResourceFieldsBalancesTurnover.Add("
					|CustomersARAPAccounting.BeingShippedTurnover * CurrencyExchangeRate.ZoomRatio AS BeingShipped"); 
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "BeingShippedOpeningBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CustomersARAPAccounting.BeingShippedOpeningBalance * CurrencyExchangeRate.ZoomRatio AS BeingShippedOpeningBalance"); 
				ThereIsResourceForThisRequest = True;
			ElsIf FieldName = "BeingShippedClosingBalance" Then
				ResourceFieldsBalancesTurnover.Add("
					|CustomersARAPAccounting.BeingShippedClosingBalance * CurrencyExchangeRate.ZoomRatio AS BeingShippedClosingBalance"); 
				ThereIsResourceForThisRequest = True;
			Else
				ResourceFieldsBalancesTurnover.Add(StrTemplate(FieldPattern, "0", FieldName));
			EndIf;
		EndIf;
	EndDo;
	
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
	|
	|INDEX BY
	|	DimensionKey
	|;
	|SELECT ALLOWED
	|	DimensionAccounting_1.Organization                  AS Organization,
	|	DimensionAccounting_1.Partner                      AS Partner,
	|	DimensionAccounting_1.Counterparty                   AS Counterparty,
	|	DimensionAccounting_1.Contract                      AS Contract,
	|	CASE WHEN NOT CustomersARAPAccounting.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|		THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|		ELSE CustomersARAPAccounting.ARAPObject.LineOfBusiness
	|	END                                       AS LineOfBusiness,
	|	CustomersARAPAccounting.ARAPObject            AS ARAPObject,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN CustomersARAPAccounting.Currency
	|		WHEN 2
	|			THEN &ManagementAccountingCurrency
	|		ELSE DimensionAccounting_1.Organization.LocalAccountingCurrency
	|	END                                       AS Currency,
	|	VALUE(Catalog.ARAPObjects.EmptyRef) AS CorARAPObject,
	|	VALUE(Catalog.Partners.EmptyRef)        AS BalancedClient,
	|	VALUE(Catalog.Companies.EmptyRef)     AS CorCompany,
	|	VALUE(Catalog.Counterparties.EmptyRef)     AS CorCounterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS CorContract,
	|	UNDEFINED                                AS ARAPDocument,
	|	DATETIME(1,1,1)                            AS OccurrenceDate,
	|	DATETIME(1,1,1)                            AS PlannedRepaymentDate,
	|	
	|	CASE
	|		WHEN CustomersARAPAccounting.Recorder = UNDEFINED
	|			THEN NULL
	|		ELSE CustomersARAPAccounting.Recorder
	|	END                                       AS Recorder,
	|	CustomersARAPAccounting.Recorder               AS ARAPAccountingRecorder,
	|	CustomersARAPAccounting.SecondPeriod             AS SecondPeriod,
	|	
	|	&ResourceFieldsBalancesTurnover
	|	
	|FROM
	|	AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers({&BeginOfPeriod}, {&EndOfPeriod}, Auto, ,
	|		AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CustomersARAPAccounting
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON CustomersARAPAccounting.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|		LEFT JOIN ExchangeRates AS CurrencyExchangeRate
	|			ON (CurrencyExchangeRate.Currency = CustomersARAPAccounting.Currency)
	|				AND (CurrencyExchangeRate.Organization = DimensionAccounting_1.Organization)
	|WHERE
	|	&ThereIsResourceForThisRequest
	|";
	
	QueryText = StrReplace(QueryText, "&ResourceFieldsBalancesTurnover", StrConcat(ResourceFieldsBalancesTurnover, ","));
	
	QueryText = StrReplace(QueryText, "&ThereIsResourceForThisRequest", ?(ThereIsResourceForThisRequest, "TRUE", "FALSE"));
	
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

Function QueryTextTTExchangeRates()
	
	QueryText = "
	|SELECT ALLOWED
	|	Companies.Ref AS Organization,
	|	CurrencyExchangeRate.Currency  AS Currency,
	|	CASE &ReportData
	|		WHEN 4
	|			THEN 1
	|		WHEN 2
	|			THEN ISNULL(CurrencyExchangeRate.CourseNumerator, 1) * ISNULL(ManSExchangeRate.CourseDenominator, 1) / (ISNULL(CurrencyExchangeRate.CourseDenominator, 1) * ISNULL(ManSExchangeRate.CourseNumerator, 1))
	|		ELSE ISNULL(CurrencyExchangeRate.CourseNumerator, 1) / ISNULL(CurrencyExchangeRate.CourseDenominator, 1)
	|	END AS ZoomRatio
	|INTO ExchangeRates
	|FROM
	|	Catalog.Companies AS Companies
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast({(&EndOfPeriod)}) AS CurrencyExchangeRate
	|		ON Companies.LocalAccountingCurrency = CurrencyExchangeRate.BaseCurrency
	|		LEFT JOIN InformationRegister.RelativeExchangeRates.SliceLast(
	|				{(&EndOfPeriod)},
	|				Currency = &ManagementAccountingCurrency) AS ManSExchangeRate
	|		ON Companies.LocalAccountingCurrency = ManSExchangeRate.BaseCurrency
	|{WHERE
	|	Companies.Ref.* AS Organization}
	|INDEX BY
	|	Organization,
	|	Currency
	|";
	
	Return QueryText;
	
EndFunction

Function GetPlanDocumentTypes()
	
	TextOfDocumentTypes = ""; 
	
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.MaterialProviderOrder2_5), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.SalesOrder), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.RequestForReturnOfGoodsFromCustomer), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.ContractSchedule)";
	
	Return TextOfDocumentTypes;
EndFunction

Procedure GenerateReportParameters(CommandParameter, FormParameters, Parameters)
	
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
			FixedSettings = New DataCompositionSettings();
			FilterElement = FixedSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue = New DataCompositionField("Partner");
			FilterValue = CommandParameter;
			If ThisIsArray Then
				FilterValue = New ValueList;
				FilterValue.LoadValues(CommandParameter);
				FilterElement.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
			Else
				FilterElement.ComparisonType = DataCompositionComparisonType.InHierarchy;
			EndIf;
			FilterElement.RightValue = FilterValue;
			FormParameters.FixedSettings = FixedSettings;
			Parameters.FixedSettings = FixedSettings;
			FormParameters.PurposeUseKey = "Partners_Group";
			Parameters.PurposeUseKey = "Partners_Group";
		Else
			FormParameters.Filter = New Structure("Partner", CommandParameter);
			FormParameters.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
		EndIf;
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.CounterpartyContracts") 
		Or TypeOf(TheFirstControl) = Type("CatalogRef.IntercompanyContracts") Then
		FormParameters.Filter = New Structure("Contract", CommandParameter);
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.ARAPObjects") Then
		If ThisIsArray Then
			FormParameters.Filter = New Structure("ARAPObject", CommandParameter);
			FormParameters.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
		Else
			FormParameters.Filter = New Structure("ARAPObject", TheFirstControl);
			FormParameters.PurposeUseKey = TheFirstControl;
			Parameters.PurposeUseKey = TheFirstControl;
		EndIf;
	ElsIf Not TypeOf(TheFirstControl) = Type("DocumentRef.ARAPSettlement") Then
		ARAPObject = ARAPObjectsServer.ObjectOfCalculationsFromLink(TheFirstControl);
		FormParameters.Filter = New Structure("ARAPObject", ARAPObject);
		FormParameters.PurposeUseKey = ARAPObject;
		Parameters.PurposeUseKey = ARAPObject;
	EndIf;
	
EndProcedure

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

Function ResourceFieldsCalculations(SelectedFieldsArray)
	
	ResourceFieldsCalculations = New Array;
	FieldPattern = "
	             |SUM(Calculations.%1) AS %1";
	FieldArray = ResourceFields();
	
	For Each FieldName In FieldArray Do
		If SelectedFieldsArray.Find(FieldName) <> Undefined Then
			ResourceFieldsCalculations.Add(StrTemplate(FieldPattern, FieldName));
		EndIf;
	EndDo;
	
	Return ResourceFieldsCalculations;
	
EndFunction

Function ResourceFields()
	
	FieldArray = New Array;
	FieldArray.Add("CustomerAccountsReceivableOpeningBalance");
	FieldArray.Add("AccountsPayableOfCompanyOpeningBalance");
	FieldArray.Add("SheduledPaymentOpeningBalance");
	FieldArray.Add("ScheduledShipmentOpeningBalance");
	FieldArray.Add("BeingPaidOpeningBalance");
	FieldArray.Add("BeingShippedOpeningBalance");
	
	FieldArray.Add("Ordered");
	FieldArray.Add("OrderedForPayment");
	FieldArray.Add("Shipped");
	FieldArray.Add("SetOff");
	FieldArray.Add("Paid");
	FieldArray.Add("WriteOffRevaluation");
	FieldArray.Add("BeingPaid");
	FieldArray.Add("BeingShipped");
	
	FieldArray.Add("CustomerAccountsReceivableClosingBalance");
	FieldArray.Add("AccountsPayableOfCompanyClosingBalance");
	FieldArray.Add("SheduledPaymentClosingBalance");
	FieldArray.Add("ScheduledShipmentClosingBalance");
	FieldArray.Add("BeingPaidClosingBalance");
	FieldArray.Add("BeingShippedClosingBalance");
	
	Return FieldArray;
	
EndFunction 

Procedure CheckCompleteNamesOfSelectedFields(ArrayOfNamesOfSelectedFields)
	
	ResourceFields = ResourceFields();
	For Each FieldName In ResourceFields Do
		If StrFind(FieldName, "OpeningBalance") > 0
			And ArrayOfNamesOfSelectedFields.Find(FieldName) <> Undefined Then
			FieldNameClosingBalance = StrReplace(FieldName, "OpeningBalance", "ClosingBalance");
			If ResourceFields.Find(FieldNameClosingBalance) <> Undefined
				And ArrayOfNamesOfSelectedFields.Find(FieldNameClosingBalance) = Undefined Then
				ArrayOfNamesOfSelectedFields.Add(FieldNameClosingBalance);
			EndIf;
		EndIf;
		If StrFind(FieldName, "ClosingBalance") > 0
			And ArrayOfNamesOfSelectedFields.Find(FieldName) <> Undefined Then
			FieldNameOpeningBalance = StrReplace(FieldName, "ClosingBalance", "OpeningBalance");
			If ResourceFields.Find(FieldNameOpeningBalance) <> Undefined
				And ArrayOfNamesOfSelectedFields.Find(FieldNameOpeningBalance) = Undefined Then
				ArrayOfNamesOfSelectedFields.Add(FieldNameOpeningBalance);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndIf