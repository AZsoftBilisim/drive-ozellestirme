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
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "StateOfSettlementsWithSupplier" Then
			
			GenerateParametersStateOfSettlementsWithSupplier(Parameters.CommandParameter, ThisForm, Parameters);
			
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "StateOfSettlementsWithSupplierAccordingToDocuments" Then
			
			CommandParameter = Parameters.CommandParameter;
			
			SettingsStructure = ReportSettings(CommandParameter);
			ValuesOfFunctionalOptions = SettingsStructure.ValuesOfFunctionalOptions;
			
			ThisForm.ParametersForm.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
			
			GenerateReportParameters(Parameters.CommandParameter, ThisForm, Parameters);
			
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("IndebtednessToSuppliersForSettlementObject", 
			                                                                    ValuesOfFunctionalOptions.BaseVersion);
			ThisForm.CurrentVariantKey = NameOfVariantKeyDependsOnFlag("IndebtednessToSuppliersForSettlementObject", 
			                                                                           ValuesOfFunctionalOptions.BaseVersion);
			
		EndIf;
		
	EndIf;
	
	ParametersForm = ThisForm.ParametersForm;

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
	|	Calculations.Organization                          AS Organization,
	|	Calculations.Partner                              AS Partner,
	|	Calculations.Counterparty                           AS Counterparty,
	|	Calculations.Contract                              AS Contract,
	|	Calculations.LineOfBusiness              AS LineOfBusiness,
	|	Calculations.ARAPObject                       AS ARAPObject,
	|	Calculations.Currency                               AS Currency,
	|	Calculations.ARAPDocument                    AS ARAPDocument,
	|	Calculations.PlannedRepaymentDate               AS PlannedRepaymentDate,
	|	Calculations.OccurrenceDate                    AS OccurrenceDate,
	|	SUM(Calculations.AccountsPayableOfCompany)                       AS AccountsPayableOfCompany,
	|	SUM(Calculations.DebtOfSupplier)                AS DebtOfSupplier,
	|	
	|	SUM(Calculations.ScheduledPaymentInAdvance)           AS ScheduledPaymentInAdvance,
	|	SUM(Calculations.ScheduledPaymentPrepayment)      AS ScheduledPaymentPrepayment,
	|	SUM(Calculations.ScheduledPaymentCredit)          AS ScheduledPaymentCredit,
	|	SUM(Calculations.ScheduledPaymentRegardless)      AS ScheduledPaymentRegardless,
	|	SUM(Calculations.ScheduledPaymentOverdue)      AS ScheduledPaymentOverdue,
	|	SUM(Calculations.ScheduledPaymentForEverything)           AS ScheduledPaymentForEverything,
	|	SUM(Calculations.BeingPaid)                  AS BeingPaid,
	|	
	|	SUM(Calculations.ScheduledReceipt)           AS ScheduledReceipt,
	|	SUM(Calculations.ScheduledReceiptIsOverdue) AS ScheduledReceiptIsOverdue
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
	|		CalculationsByTerms.DebtBalance                                    AS AccountsPayableOfCompany,
	|		CalculationsByTerms.PrepaymentBalance                              AS DebtOfSupplier,
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
	|		0                                                              AS ScheduledReceipt,
	|		0                                                              AS ScheduledReceiptIsOverdue
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingByDueDates.Balance(&DateOfReportBorder,
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
	|		0                                                             AS DebtOfSupplier,
	|		
	|		CASE
	|			WHEN PaymentPlanCalculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation)
	|				THEN PaymentPlanCalculations.AmountDueBalance 
	|			ELSE 0 
	|		END                                                         AS ScheduledPaymentInAdvance,
	|		CASE
	|			WHEN PaymentPlanCalculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt)
	|				THEN PaymentPlanCalculations.AmountDueBalance 
	|			ELSE 0 
	|		END                                                         AS ScheduledPaymentPrepayment,
	|		CASE
	|			WHEN PaymentPlanCalculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment)
	|				THEN PaymentPlanCalculations.AmountDueBalance 
	|			ELSE 0 
	|		END                                                          AS ScheduledPaymentCredit,
	|		CASE
	|			WHEN PaymentPlanCalculations.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt)
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
	|		0                                                              AS ScheduledReceipt,
	|		0                                                              AS ScheduledReceiptIsOverdue
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(&DateOfReportBorder,
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
	|		CASE WHEN NOT CalculationsDeliveryPlan.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE CalculationsDeliveryPlan.ARAPObject.LineOfBusiness
	|		END                                       AS LineOfBusiness,
	|		CalculationsDeliveryPlan.ARAPObject          AS ARAPObject,
	|		CalculationsDeliveryPlan.Currency                  AS Currency,
	|		CalculationsDeliveryPlan.DocumentPlan            AS DocumentPlan,
	|		CalculationsDeliveryPlan.PlannedRepaymentDate  AS PlannedRepaymentDate,
	|		CalculationsDeliveryPlan.OccurrenceDate       AS OccurrenceDate,
	|		0                                           AS AccountsPayableOfCompany,
	|		0                                           AS DebtOfSupplier,
	|		
	|		0                                           AS ScheduledPaymentInAdvance,
	|		0                                           AS ScheduledPaymentPrepayment,
	|		0                                           AS ScheduledPaymentCredit,
	|		0                                           AS ScheduledPaymentRegardless,
	|		0                                           AS ScheduledPaymentOverdue,
	|		0                                           AS ScheduledPaymentForEverything,
	|		0                                           AS BeingPaid,
	|		
	|		CalculationsDeliveryPlan.SumBalance            AS ScheduledReceipt,
	|		CASE 
	|			WHEN CalculationsDeliveryPlan.PlannedRepaymentDate < BEGINOFPERIOD(&ReportDate,DAY)
	|				THEN CalculationsDeliveryPlan.SumBalance
	|			ELSE 0 
	|		END                                       AS ScheduledReceiptIsOverdue
	|	FROM
	|		AccumulationRegister.VendorsARAPAccountingPlannedDeliveries.Balance(&DateOfReportBorder, NOT UnallocatedAdvancePayment
	|			AND AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS CalculationsDeliveryPlan
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON CalculationsDeliveryPlan.AccountingDimensionByPartners = DimensionAccounting_1.DimensionKey
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DimensionAccounting_1.Organization                AS Organization,
	|		DimensionAccounting_1.Partner                    AS Partner,
	|		DimensionAccounting_1.Counterparty                 AS Counterparty,
	|		DimensionAccounting_1.Contract                    AS Contract,
	|		CASE WHEN NOT VendorsARAPAccounting.ARAPObject.ARAPAccountingRegistersAreNotDividedByLinesOfBusiness
	|			THEN DimensionAccounting_1.LineOfBusinessOfAnalytics
	|			ELSE VendorsARAPAccounting.ARAPObject.LineOfBusiness
	|		END                                     AS LineOfBusiness,
	|		VendorsARAPAccounting.ARAPObject       AS ARAPObject,
	|		VendorsARAPAccounting.Currency               AS Currency,
	|		UNDEFINED                              AS DocumentPlan,
	|		DATETIME(1,1,1)                          AS PlannedRepaymentDate,
	|		DATETIME(1,1,1)                          AS OccurrenceDate,
	|		0                                         AS AccountsPayableOfCompany,
	|		0                                         AS DebtOfSupplier,
	|		
	|		0                                         AS ScheduledPaymentInAdvance,
	|		0                                         AS ScheduledPaymentPrepayment,
	|		0                                         AS ScheduledPaymentCredit,
	|		0                                         AS ScheduledPaymentRegardless,
	|		0                                         AS ScheduledPaymentOverdue,
	|		0                                         AS ScheduledPaymentForEverything,
	|		-VendorsARAPAccounting.BeingPaidBalance AS BeingPaid,
	|		
	|		0                                         AS ScheduledReceipt,
	|		0                                         AS ScheduledReceiptIsOverdue
	|	FROM
	|		AccumulationRegister.VendorsARAPAccounting.Balance(&DateOfReportBorder,
	|			AccountingDimensionByPartners IN
	|				(SELECT
	|					TT_AccountingDimensionByPartners.DimensionKey
	|				FROM
	|					TT_AccountingDimensionByPartners)) AS VendorsARAPAccounting
	|			INNER JOIN TT_AccountingDimensionByPartners AS DimensionAccounting_1
	|				ON DimensionAccounting_1.DimensionKey = VendorsARAPAccounting.AccountingDimensionByPartners
	|	WHERE
	|		VendorsARAPAccounting.BeingPaidBalance < 0) AS Calculations
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
	|";
	
	QueryText = StrReplace(QueryText,"&TypesOfPlanDocuments", GetPlanDocumentTypes());
	
	Return QueryText;
	
EndFunction

Procedure GenerateParametersStateOfSettlementsWithSupplier(CommandParameter, ThisForm, Parameters)
	
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
	
	ThisBasicVersion = GetFunctionalOption("BaseVersion");
	VariantKey = ThisForm.CurrentVariantKey;
	If ThereAreSubordinatePartners Then
		FormParameters.PurposeUseKey = "Partners_Group";
		Parameters.PurposeUseKey = "Partners_Group";
  
		VariantKey = NameOfVariantKeyDependsOnFlag("DebtToServiceProviders", 
		                                                          ThisBasicVersion);
	Else
																															
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
  
		If ThisIsArray And CommandParameter.Count() = 1 Then
			VariantKey = NameOfVariantKeyDependsOnFlag("DebtToServiceProvider", 
			                                                          ThisBasicVersion);
		Else
			VariantKey = NameOfVariantKeyDependsOnFlag("DebtToServiceProviders", 
			                                                          ThisBasicVersion);
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

Function ReportSettings(CommandParameter)
	
	ValuesOfFunctionalOptions = New Structure;
	ValuesOfFunctionalOptions.Insert("BaseVersion", GetFunctionalOption("BaseVersion"));
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("ValuesOfFunctionalOptions", ValuesOfFunctionalOptions);
	
	Return SettingsStructure
	
EndFunction

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "VendorsAccountsPayable" Then
		Return "DebtToSuppliersBasic";
	ElsIf VariantKeyName = "IndebtednessToSuppliersForSettlementObject" Then
		Return "DebtToSuppliersForObjectOfSettlementsBasic";
	ElsIf VariantKeyName = "DebtToServiceProvider" Then
		Return "DebtToSupplierContextBasic";
	ElsIf VariantKeyName = "DebtToServiceProviders" Then
		Return "DebtToSuppliersContextBasic";
	EndIf;
	
EndFunction

Function GetPlanDocumentTypes()
	
	TextOfDocumentTypes = ""; 
	
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.SubcontractOrder2_5), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.PurchaseOrder), ";
	TextOfDocumentTypes = TextOfDocumentTypes + "TYPE(Document.ContractSchedule)";
	
	Return TextOfDocumentTypes;
	
EndFunction

#EndRegion

#EndIf