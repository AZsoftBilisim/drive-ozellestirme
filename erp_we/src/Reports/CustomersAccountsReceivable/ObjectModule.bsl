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
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "StateOfSettlementsWithClient" Then
			
			GenerateParametersStateOfSettlementsWithClient(Parameters.CommandParameter, ThisForm, Parameters);
			
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "StateOfSettlementsWithClientOnDocuments" Then
			
			CommandParameter = Parameters.CommandParameter;
			
			SettingsStructure = ReportSettings(CommandParameter);
			ValuesOfFunctionalOptions = SettingsStructure.ValuesOfFunctionalOptions;
			
			VariantKey = NameOfVariantKeyDependsOnFlag("CustomerDebtOnObjectOfSettlement", 
			                                                          ValuesOfFunctionalOptions.BaseVersion);
			
			ThisForm.ParametersForm.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
			
			GenerateReportParameters(CommandParameter, ThisForm, Parameters);
			
			Parameters.VariantKey = VariantKey;
			ThisForm.CurrentVariantKey = VariantKey;
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function ReportSettings(CommandParameter)
	
	ValuesOfFunctionalOptions = New Structure;
	ValuesOfFunctionalOptions.Insert("UseAdvancedFeaturesOfSalesOrder", 
	                                     GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder"));
	ValuesOfFunctionalOptions.Insert("BaseVersion", GetFunctionalOption("BaseVersion"));
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("ValuesOfFunctionalOptions", ValuesOfFunctionalOptions);
	
	Return SettingsStructure;
	
EndFunction

Procedure GenerateReportParameters(CommandParameter, ThisForm, Parameters)
	
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
			SettingsComposer.FixedSettings.Filter,
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
			SettingsComposer.FixedSettings.Filter, 
			"Contract",
			FilterValue,
			DCComparisonType,,
			True);
	Else
		ARAPObject = ARAPAccountingServer.GetARAPObjectsForSelectingReport(CommandParameter);
		FormParameters.PurposeUseKey = TheFirstControl;
		Parameters.PurposeUseKey = TheFirstControl;
		FilterValue = ARAPObject;
		DCComparisonType = DataCompositionComparisonType.Equal;
		If TypeOf(ARAPObject) = Type("Array") Then
			FilterValue = New ValueList;
			FilterValue.LoadValues(ARAPObject);
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		CommonClientServer.SetFilterItem(
			SettingsComposer.FixedSettings.Filter, 
			"ARAPObject",
			FilterValue,
			DCComparisonType,,
			True);
	EndIf;
	
EndProcedure

Procedure GenerateParametersStateOfSettlementsWithClient(CommandParameter, ThisForm, Parameters)
	
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
	
	ThisIsBasic = GetFunctionalOption("BaseVersion");
	VariantKey = ThisForm.CurrentVariantKey;
	
	If ThereAreSubordinatePartners Then
		FormParameters.PurposeUseKey = "Partners_Group";
		Parameters.PurposeUseKey = "Partners_Group";
		VariantKey = NameOfVariantKeyDependsOnFlag("CustomersDebtContext", ThisIsBasic);
	Else
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		If ThisIsArray And CommandParameter.Count() = 1 Then
			VariantKey = NameOfVariantKeyDependsOnFlag("CustomerDebtContext", ThisIsBasic);
		Else
			VariantKey = NameOfVariantKeyDependsOnFlag("CustomersDebtContext", ThisIsBasic);
		EndIf;
	EndIf;
	ThisForm.CurrentVariantKey = VariantKey;
	Parameters.VariantKey = VariantKey;
	
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
		SettingsComposer.FixedSettings.Filter,
		"Partner",
		FilterValue,
		DCComparisonType,,
		True);
	
EndProcedure

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UserSettingsModified = False;
	SetRequiredSettings(SettingsComposer, UserSettingsModified);
	
	// Generate a report
	ReportSettings = SettingsComposer.GetSettings();
	
	QueryText = QueryText();
	
	ARAPAccountingReports.AddSelectionsOfSelectedFieldsToQuery(QueryText, ReportSettings, DataCompositionSchema.CalculatedFields, "Calculations");
	
	DataCompositionSchema.DataSets.DataSet.Query = QueryText;
	
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
	BalanceDateParameter = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "ReportDate");
	BalanceDateParameter.Use = True;
	
	ReportDateParameterBorder = DataCompositionClientServer.GetParameter(Var_SettingsComposer, "DateOfReportBorder");
	ReportDateParameterBorder.Use = True;
	
	If TypeOf(BalanceDateParameter.Value) = Type("StandardBeginningDate") Then
		If Not ValueIsFilled(BalanceDateParameter.Value.Date) Then
			ReportDateParameterBorder.Value = Date(1, 1, 1);
		Else
			ReportDateParameterBorder.Value = New Boundary(EndOfDay(BalanceDateParameter.Value.Date), BoundaryType.Including);
		EndIf;
	Else
		If Not ValueIsFilled(BalanceDateParameter.Value) Then
			ReportDateParameterBorder.Value = Date(1, 1, 1);
		Else
			ReportDateParameterBorder.Value = New Boundary(EndOfDay(BalanceDateParameter.Value), BoundaryType.Including);
		EndIf;
	EndIf;
EndProcedure

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
EndProcedure

Function QueryText()
	
	QueryText = "
	|SELECT ALLOWED DISTINCT
	|	Segments.Partner AS Partner,
	|	TRUE AS FilterByPartnerSegmentIsUsed
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
	|;
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
	|		DimensionAccounting_1.Organization.* AS Organization,
	|		DimensionAccounting_1.Partner.* AS Partner,
	|		DimensionAccounting_1.Counterparty.* AS Counterparty,
	|		DimensionAccounting_1.Contract.* AS Contract,
	|		(DimensionAccounting_1.Partner IN
	|				(SELECT
	|					SelectionByPartnerSegment.Partner
	|				FROM
	|					SelectionByPartnerSegment
	|				WHERE
	|					SelectionByPartnerSegment.FilterByPartnerSegmentIsUsed = &FilterByPartnerSegmentIsUsed))}
	|INDEX BY
	|	DimensionKey
	|;
	|SELECT ALLOWED
	|	Calculations.Organization                       AS Organization,
	|	Calculations.Partner                           AS Partner,
	|	Calculations.Counterparty                        AS Counterparty,
	|	Calculations.Contract                           AS Contract,
	|	Calculations.LineOfBusiness           AS LineOfBusiness,
	|	Calculations.ARAPObject                    AS ARAPObject,
	|	Calculations.Currency                            AS Currency,
	|	Calculations.ARAPDocument                 AS ARAPDocument,
	|	Calculations.PlannedRepaymentDate            AS PlannedRepaymentDate,
	|	Calculations.OccurrenceDate                 AS OccurrenceDate,
	|	SUM(Calculations.AccountsPayableOfCompany)                    AS AccountsPayableOfCompany,
	|	SUM(Calculations.CustomerAccountsReceivable)                AS CustomerAccountsReceivable,
	|	SUM(Calculations.OverdueCustomerDebt)      AS OverdueCustomerDebt,
	|	
	|	SUM(Calculations.ScheduledPaymentInAdvance)        AS ScheduledPaymentInAdvance,
	|	SUM(Calculations.ScheduledPaymentPrepayment)   AS ScheduledPaymentPrepayment,
	|	SUM(Calculations.ScheduledPaymentCredit)       AS ScheduledPaymentCredit,
	|	SUM(Calculations.ScheduledPaymentRegardless)   AS ScheduledPaymentRegardless,
	|	SUM(Calculations.ScheduledPaymentOverdue)   AS ScheduledPaymentOverdue,
	|	SUM(Calculations.ScheduledPaymentForEverything)        AS ScheduledPaymentForEverything,
	|	SUM(Calculations.BeingPaid)               AS BeingPaid,
	|	
	|	SUM(Calculations.ScheduledShipment)           AS ScheduledShipment,
	|	SUM(Calculations.ScheduledShipmentOverdue) AS ScheduledShipmentOverdue,
	|	SUM(Calculations.BeingShipped)                AS BeingShipped
	|INTO TTCalculations
	|FROM (
	|	SELECT
	|		DimensionAccounting_1.Organization                                     AS Organization,
	|		DimensionAccounting_1.Partner                                         AS Partner,
	|		DimensionAccounting_1.Counterparty                                      AS Counterparty,
	|		DimensionAccounting_1.Contract                                         AS Contract,
	|		CASE WHEN NOT CalculationsByTerms.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsByTerms.ARAPObject.LineOfBusiness
	|		END                                                          AS LineOfBusiness,
	|		CalculationsByTerms.ARAPObject                                 AS ARAPObject,
	|		CalculationsByTerms.Currency                                         AS Currency,
	|		CalculationsByTerms.ARAPDocument                              AS ARAPDocument,
	|		CalculationsByTerms.PlannedRepaymentDate                         AS PlannedRepaymentDate,
	|		CalculationsByTerms.OccurrenceDate                              AS OccurrenceDate,
	|		CalculationsByTerms.PrepaymentBalance                              AS AccountsPayableOfCompany,
	|		CalculationsByTerms.DebtBalance                                    AS CustomerAccountsReceivable,
	|		CASE 
	|			WHEN CalculationsByTerms.PlannedRepaymentDate < BEGINOFPERIOD(&ReportDate, DAY)
	|				THEN CalculationsByTerms.DebtBalance
	|			ELSE 0 
	|		END                                                          AS OverdueCustomerDebt,
	|		
	|		0                                                              AS ScheduledPaymentInAdvance,
	|		0                                                              AS ScheduledPaymentPrepayment,
	|		CalculationsByTerms.DebtBalance                                    AS ScheduledPaymentCredit,
	|		0                                                              AS ScheduledPaymentRegardless,
	|		CASE 
	|			WHEN CalculationsByTerms.PlannedRepaymentDate < BEGINOFPERIOD(&ReportDate,DAY)
	|				THEN CalculationsByTerms.DebtBalance
	|			ELSE 0 
	|		END                                                          AS ScheduledPaymentOverdue,
	|		CalculationsByTerms.DebtBalance                                    AS ScheduledPaymentForEverything,
	|		0                                                              AS BeingPaid,
	|		
	|		0                                                              AS ScheduledShipment,
	|		0                                                              AS ScheduledShipmentOverdue,
	|		0                                                              AS BeingShipped
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingByDueDates.Balance(&DateOfReportBorder,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsByTerms
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsByTerms.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DimensionAccounting_1.Organization                                    AS Organization,
	|		DimensionAccounting_1.Partner                                        AS Partner,
	|		DimensionAccounting_1.Counterparty                                     AS Counterparty,
	|		DimensionAccounting_1.Contract                                        AS Contract,
	|		CASE WHEN NOT PaymentPlanCalculations.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE PaymentPlanCalculations.ARAPObject.LineOfBusiness
	|		END                                                         AS LineOfBusiness,
	|		PaymentPlanCalculations.ARAPObject                               AS ARAPObject,
	|		PaymentPlanCalculations.Currency                                       AS Currency,
	|		PaymentPlanCalculations.DocumentPlan                                 AS DocumentPlan,
	|		PaymentPlanCalculations.PlannedRepaymentDate                       AS PlannedRepaymentDate,
	|		PaymentPlanCalculations.OccurrenceDate                            AS OccurrenceDate,
	|		0                                                             AS AccountsPayableOfCompany,
	|		0                                                             AS CustomerAccountsReceivable,
	|		0                                                             AS OverdueCustomerDebt,
	|		
	|		CASE
	|			WHEN PaymentPlanCalculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision)
	|				THEN PaymentPlanCalculations.AmountDueBalance 
	|			ELSE 0 
	|		END                                                         AS ScheduledPaymentInAdvance,
	|		CASE
	|			WHEN PaymentPlanCalculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
	|				THEN PaymentPlanCalculations.AmountDueBalance 
	|			ELSE 0 
	|		END                                                         AS ScheduledPaymentPrepayment,
	|		CASE
	|			WHEN PaymentPlanCalculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)
	|				THEN PaymentPlanCalculations.AmountDueBalance 
	|			ELSE 0 
	|		END                                                          AS ScheduledPaymentCredit,
	|		CASE
	|			WHEN PaymentPlanCalculations.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned)
	|				THEN PaymentPlanCalculations.AmountDueBalance 
	|			ELSE 0 
	|		END                                                          AS ScheduledPaymentRegardless,
	|		CASE 
	|			WHEN PaymentPlanCalculations.PlannedRepaymentDate < BEGINOFPERIOD(&ReportDate,DAY)
	|				THEN PaymentPlanCalculations.AmountDueBalance
	|			ELSE 0 
	|		END                                                          AS ScheduledPaymentOverdue,
	|		PaymentPlanCalculations.AmountDueBalance                                AS ScheduledPaymentForEverything,
	|		0                                                              AS BeingPaid,
	|		
	|		0                                                              AS ScheduledShipment,
	|		0                                                              AS ScheduledShipmentOverdue,
	|		0                                                              AS BeingShipped
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(&DateOfReportBorder,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)
	|			AND VALUETYPE(DocumentPlan) IN (&TypesOfPlanDocuments)) AS PaymentPlanCalculations
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON PaymentPlanCalculations.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|	
	|	UNION ALL
	|	
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
	|		CalculationsShipmentPlan.Currency                  AS Currency,
	|		CalculationsShipmentPlan.DocumentPlan            AS DocumentPlan,
	|		CalculationsShipmentPlan.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|		CalculationsShipmentPlan.OccurrenceDate       AS OccurrenceDate,
	|		0                                           AS AccountsPayableOfCompany,
	|		0                                           AS CustomerAccountsReceivable,
	|		0                                           AS OverdueCustomerDebt,
	|		
	|		0                                           AS ScheduledPaymentInAdvance,
	|		0                                           AS ScheduledPaymentPrepayment,
	|		0                                           AS ScheduledPaymentCredit,
	|		0                                           AS ScheduledPaymentRegardless,
	|		0                                           AS ScheduledPaymentOverdue,
	|		0                                           AS ScheduledPaymentForEverything,
	|		0                                           AS BeingPaid,
	|		
	|		CalculationsShipmentPlan.SumBalance            AS ScheduledShipment,
	|		CASE 
	|			WHEN CalculationsShipmentPlan.PlannedRepaymentDate < BEGINOFPERIOD(&ReportDate,DAY)
	|				THEN CalculationsShipmentPlan.SumBalance
	|			ELSE 0 
	|		END                                       AS ScheduledShipmentOverdue,
	|		0                                           AS BeingShipped
	|	FROM
	|		AccumulationRegister.CustomersARAPAccountingPlannedShipments.Balance(&DateOfReportBorder, NOT UnallocatedAdvancePayment
	|				AND AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsShipmentPlan
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsShipmentPlan.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|		
	|	UNION ALL
	|	
	|	SELECT
	|		DimensionAccounting_1.Organization             AS Organization,
	|		DimensionAccounting_1.Partner                 AS Partner,
	|		DimensionAccounting_1.Counterparty              AS Counterparty,
	|		DimensionAccounting_1.Contract                 AS Contract,
	|		CASE WHEN NOT CustomersARAPAccounting.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CustomersARAPAccounting.ARAPObject.LineOfBusiness
	|		END                                  AS LineOfBusiness,
	|		CustomersARAPAccounting.ARAPObject       AS ARAPObject,
	|		CustomersARAPAccounting.Currency               AS Currency,
	|		UNDEFINED                           AS DocumentPlan,
	|		DATETIME(1,1,1)                       AS PlannedRepaymentDate,
	|		DATETIME(1,1,1)                       AS OccurrenceDate,
	|		0                                      AS AccountsPayableOfCompany,
	|		0                                      AS CustomerAccountsReceivable,
	|		0                                      AS OverdueCustomerDebt,
	|		
	|		0                                      AS ScheduledPaymentInAdvance,
	|		0                                      AS ScheduledPaymentPrepayment,
	|		0                                      AS ScheduledPaymentCredit,
	|		0                                      AS ScheduledPaymentRegardless,
	|		0                                      AS ScheduledPaymentOverdue,
	|		0                                      AS ScheduledPaymentForEverything,
	|		CustomersARAPAccounting.BeingPaidBalance  AS BeingPaid,
	|		
	|		0                                      AS ScheduledShipment,
	|		0                                      AS ScheduledShipmentOverdue,
	|		CustomersARAPAccounting.BeingShippedBalance   AS BeingShipped
	|	FROM
	|		AccumulationRegister.CustomersARAPAccounting.Balance(&DateOfReportBorder,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CustomersARAPAccounting
	|		INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|			ON DimensionAccounting_1.DimensionKey = CustomersARAPAccounting.AccountingDimensionByPartners) AS Calculations
	|GROUP BY
	|	Calculations.Organization,
	|	Calculations.Partner,
	|	Calculations.Counterparty,
	|	Calculations.Contract,
	|	Calculations.LineOfBusiness,
	|	Calculations.ARAPObject,
	|	Calculations.Currency,
	|	Calculations.ARAPDocument,
	|	Calculations.PlannedRepaymentDate,
	|	Calculations.OccurrenceDate
	|HAVING
	|	(&SelectionOfSelectedFields)
	|;
	|SELECT ALLOWED
	|	Calculations.Organization                AS Organization,
	|	Calculations.Partner                    AS Partner,
	|	Calculations.Counterparty                 AS Counterparty,
	|	Calculations.Contract                    AS Contract,
	|	Calculations.LineOfBusiness    AS LineOfBusiness,
	|	Calculations.ARAPObject             AS ARAPObject,
	|	Calculations.Currency                     AS Currency,
	|	Calculations.ARAPDocument          AS ARAPDocument,
	|	Calculations.PlannedRepaymentDate     AS PlannedRepaymentDate,
	|	Calculations.OccurrenceDate          AS OccurrenceDate,
	|	Calculations.AccountsPayableOfCompany                    AS AccountsPayableOfCompany,
	|	Calculations.CustomerAccountsReceivable                AS CustomerAccountsReceivable,
	|	Calculations.OverdueCustomerDebt      AS OverdueCustomerDebt,
	|	
	|	Calculations.ScheduledPaymentInAdvance        AS ScheduledPaymentInAdvance,
	|	Calculations.ScheduledPaymentPrepayment   AS ScheduledPaymentPrepayment,
	|	Calculations.ScheduledPaymentCredit       AS ScheduledPaymentCredit,
	|	Calculations.ScheduledPaymentRegardless   AS ScheduledPaymentRegardless,
	|	Calculations.ScheduledPaymentOverdue   AS ScheduledPaymentOverdue,
	|	Calculations.ScheduledPaymentForEverything        AS ScheduledPaymentForEverything,
	|	Calculations.BeingPaid               AS BeingPaid,
	|	
	|	Calculations.ScheduledShipment           AS ScheduledShipment,
	|	Calculations.ScheduledShipmentOverdue AS ScheduledShipmentOverdue,
	|	Calculations.BeingShipped                AS BeingShipped,
	|
	|	ISNULL(Contracts.ShipmentIsProhibitedInCaseOfARAPOverdue, FALSE) AS ShipmentIsProhibitedInCaseOfARAPOverdue,
	|	ISNULL(Contracts.LimitDebtAmount, FALSE)       AS LimitDebtAmount,
	|	ISNULL(Contracts.AllowableAmountPayable, 0)            AS AllowableAmountPayable
	|
	|FROM TTCalculations AS Calculations
	|	LEFT JOIN Catalog.CounterpartyContracts AS Contracts
	|		ON Contracts.Ref = Calculations.Contract
	|";
	
	QueryText = StrReplace(QueryText,"&TypesOfPlanDocuments", GetPlanDocumentTypes());
	
	Return QueryText;
	
EndFunction

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "CustomersAccountsReceivable" Then
		Return "CustomerDebtBasic";
	ElsIf VariantKeyName = "CustomerDebtOnObjectOfSettlement" Then
		Return "CustomerDebtOnObjectOfSettlementsBasic";
	ElsIf VariantKeyName = "CustomerDebtContext" Then
		Return "CustomerDebtContextBasic";
	ElsIf VariantKeyName = "CustomersDebtContext" Then
		Return "CustomersDebtContextBasic";
	EndIf;
	
EndFunction

Function GetPlanDocumentTypes()
	
	TextOfDocumentTypes = ""; 
	
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.MaterialProviderOrder2_5), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.SalesOrder), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.RequestForReturnOfGoodsFromCustomer), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.ContractSchedule)";
	
	Return TextOfDocumentTypes;
	
EndFunction

#EndRegion

#EndIf