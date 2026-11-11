
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
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		GenerateReportParameters(Parameters.CommandParameter, Form.ParametersForm, Parameters);
			
	EndIf;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the report or report settings contains the following properties:
//   	* Parameters - Structure - 
//   NewDCSettings - DataCompositionSettings - settings to upload to the settings Builder.
//
Procedure BeforeLoadVariantAtServer(Form, NewDCSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Setting up a contextual report on contracts
	ConfigureContractReport(Form, FormSettingsComposer);
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	// Setting default values
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - The Form of the report or report settings contains the following properties:
//   	* Parameters - Structure - 
//   NewDCUserSettings - DataCompositionUserSettings - settings to upload to the settings Builder.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	Report = Form.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Setting up a contextual report on contracts
	ConfigureContractReport(Form, FormSettingsComposer);
	
	NewDCUserSettings = FormSettingsComposer.UserSettings;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();

	ReportCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "ReportData").Value;
	CostDepreciationCurrency = DataCompositionClientServer.GetParameter(ReportSettings, "CostDepreciationCurrency").Value;
	DataSelectionValues = GetDataSelectionValues(ReportSettings);

	DataCompositionSchema.DataSets.LeaseSettlements.Query = QueryTextLeaseSettlements(ReportCurrency);
	DataCompositionSchema.DataSets.RentalItems.Query = QueryTextRentalItems(CostDepreciationCurrency);

	ReportPeriod = TMReportsServer.ParameterValue(ReportSettings, "Period");
	DataCompositionClientServer.SetParameter(ReportSettings, "PeriodLimit", New Boundary(EndOfDay(ReportPeriod), BoundaryType.Including));

	SetPrivilegedMode(True);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	AddInformationalMessageToHeader(ResultDocument, DataSelectionValues);
	
	SetPrivilegedMode(False);

EndProcedure

#EndRegion

#Region Private

Function QueryTextLeaseSettlements(ReportCurrency)
	
	QueryText =
	"SELECT ALLOWED
	|	DimensionAccounting_1.Organization                 AS Organization,
	|	DimensionAccounting_1.Partner                     AS Partner,
	|	DimensionAccounting_1.Counterparty                  AS Counterparty,
	|	LeaseSettlements.Contract                    AS Contract,
	|	LeaseSettlements.Contract.LineOfBusiness AS LineOfBusiness,
	|	LeaseSettlements.Contract.ContractType        AS ContractType,
	|	LeaseSettlements.Contract.AssetHolder   AS AssetHolder,
	|	LeaseSettlements.AmountType                   AS AmountType,
	|	CASE
	|		WHEN &ReportData = 2
	|			THEN &ManagementAccountingCurrency
	|		WHEN &ReportData = 3
	|			THEN DimensionAccounting_1.Organization.LocalAccountingCurrency
	|		ELSE LeaseSettlements.Currency
	|	END AS Currency,
	|	
	// Calculations_Interests_Total
	|	CASE
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|				AND LeaseSettlements.BusinessTransactionSetting IN (
	|					VALUE(Catalog.BusinessTransactionsSettings.IncreaseOfLeaseInterest),
	|					VALUE(Catalog.BusinessTransactionsSettings.OBEntryLeaseContractsARAP))
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN LeaseSettlements.SumCompl
	|
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|				AND LeaseSettlements.BusinessTransactionSetting IN (
	|					VALUE(Catalog.BusinessTransactionsSettings.DecreaseOfLeaseInterest),
	|					VALUE(Catalog.BusinessTransactionsSettings.OBEntryLeaseContractsARAP))
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_Interests_Total,
	|
	// Calculations_Interests_Accrued
	|	CASE
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|				AND LeaseSettlements.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.AccrualOfLeaseInterest)
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN LeaseSettlements.SumCompl
	|		
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|				AND LeaseSettlements.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.OverchargedLeaseInterest)
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_Interests_Accrued,
	|
	// Settlements_Interest_Debited
	|	CASE
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|				AND LeaseSettlements.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.WriteOffOfLeaseInterest)
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN LeaseSettlements.SumCompl
	|		
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.Interests)
	|				AND LeaseSettlements.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.WriteOffOfLeaseInterest)
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Settlements_Interest_Debited,
	|
	// Calculations_BuyoutValue_Paid
	|	CASE
	|		WHEN LeaseSettlements.AmountType IN (
	|						VALUE(Enum.TypesOfLeasePayments.BuyoutValue),
	|						VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment))
	|					AND LeaseSettlements.BusinessTransactionSetting IN (
	|						VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePayment),
	|						VALUE(Catalog.BusinessTransactionsSettings.LeaseBuyoutValuePrepayment),
	|						VALUE(Catalog.BusinessTransactionsSettings.OBEntryLeaseContractsARAP))
	|					AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_BuyoutValue_Paid,
	|
	// Calculations_BuyoutValue_Accrued
	|	CASE
	|		WHEN LeaseSettlements.AmountType IN (
	|						VALUE(Enum.TypesOfLeasePayments.BuyoutValue),
	|						VALUE(Enum.TypesOfLeasePayments.BuyoutValuePrepayment))
	|					AND LeaseSettlements.BusinessTransactionSetting IN (
	|						VALUE(Catalog.BusinessTransactionsSettings.VendorInvoiceLeasedAssets),
	|						VALUE(Catalog.BusinessTransactionsSettings.OBEntryLeaseContractsARAP))
	|					AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|				OR LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|					AND LeaseSettlements.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.AccrualOfVATInPartOfBuyoutValue)
	|					AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_BuyoutValue_Accrued,
	|	
	// Calculations_DepositPayment_Paid
	|	CASE
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|				AND LeaseSettlements.BusinessTransactionSetting IN (
	|					VALUE(Catalog.BusinessTransactionsSettings.SecurityPayment),
	|					VALUE(Catalog.BusinessTransactionsSettings.OBEntryLeaseContractsARAP))
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_DepositPayment_Paid,
	|
	// Calculations_DepositPayment_SetOff
	|	CASE
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.DepositPayment)
	|					AND LeaseSettlements.BusinessTransactionSetting IN (
	|							VALUE(Catalog.BusinessTransactionsSettings.DepositPayment),
	|							VALUE(Catalog.BusinessTransactionsSettings.SecurityPaymentForOffBalanceAccounting),
	|							VALUE(Catalog.BusinessTransactionsSettings.OBEntryLeaseContractsARAP))
	|					AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|				OR LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|					AND LeaseSettlements.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.AccrualOfVATInPartOfSecurityPayment)
	|					AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_DepositPayment_SetOff,
	|	
	// Calculations_Commitments_Accrued
	|	CASE
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_Commitments_Accrued,
	|
	// Calculations_Commitments_Repaid 
	|	CASE
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.LeaseObligations)
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_Commitments_Repaid,
	|
	// Calculations_RentalService_Paid
	|	CASE
	|		WHEN (LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|				OR LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|				AND LeaseSettlements.BusinessTransactionSetting IN (
	|					VALUE(Catalog.BusinessTransactionsSettings.PaymentForLeaseServices),
	|					VALUE(Catalog.BusinessTransactionsSettings.OBEntryLeaseContractsARAP))
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_RentalService_Paid,
	|
	// Calculations_RentalService_Accrued
	|	CASE
	|		WHEN (LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|				OR LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|					AND LeaseSettlements.BusinessTransactionSetting IN (
	|						VALUE(Catalog.BusinessTransactionsSettings.ReceivingLeaseServices),
	|						VALUE(Catalog.BusinessTransactionsSettings.RecordingLeaseServicesInExpenses),
	|						VALUE(Catalog.BusinessTransactionsSettings.ReceiptOfVATInPartOfLeaseService),
	|						VALUE(Catalog.BusinessTransactionsSettings.OBEntryLeaseContractsARAP))
	|					AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN LeaseSettlements.SumCompl
	|		WHEN (LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalService)
	|				OR LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.RentalServicePrepayment))
	|					AND LeaseSettlements.BusinessTransactionSetting = VALUE(Catalog.BusinessTransactionsSettings.SecurityPaymentForOffBalanceAccounting)
	|			THEN -LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_RentalService_Accrued,
	|	
	// Calculations_VAT_ClosingBalance
	|	CASE
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN LeaseSettlements.SumCompl
	|		WHEN LeaseSettlements.AmountType = VALUE(Enum.TypesOfLeasePayments.VAT)
	|				AND LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN -LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_VAT_ClosingBalance,
	|
	// Calculations_ClosingBalance
	|	CASE
	|		WHEN LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -LeaseSettlements.SumCompl
	|		WHEN LeaseSettlements.RecordType = VALUE(AccumulationRecordType.Expense)
	|			THEN LeaseSettlements.SumCompl
	|		ELSE 0
	|	END AS Calculations_ClosingBalance
	|
	|FROM
	|	AccumulationRegister.FinancialInstrumentsARAP AS LeaseSettlements
	|
	|		INNER JOIN InformationRegister.AccountingDimensionByPartners AS DimensionAccounting_1
	|		ON DimensionAccounting_1.DimensionKey = LeaseSettlements.AccountingDimensionByPartners
	|
	|WHERE
	|	(LeaseSettlements.Period < &Period
	|		OR &Period = DATETIME(1, 1, 1))";
	
	If ReportCurrency = 4 Then
		QueryText = StrReplace(QueryText,".SumCompl",".Sum");
	ElsIf ReportCurrency = 2 Then
		QueryText = StrReplace(QueryText,".SumCompl",".SumMan");
	EndIf;

	Return QueryText;
	
EndFunction

Function QueryTextRentalItems(CostDepreciationCurrency)
	
	QueryText =
	"SELECT ALLOWED
	|	LeasedAsset.Partner AS Partner,
	|	LeasedAsset.Counterparty AS Counterparty,
	|	LeasedAsset.Contract AS Contract,
	|	LeasedAsset.FixedAsset AS FixedAsset
	|INTO TTLeasedFA
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Period {&Period} ) AS LeasedAsset
	|{WHERE
	|	LeasedAsset.Partner.* AS Partner,
	|	LeasedAsset.Counterparty.* AS Counterparty,
	|	LeasedAsset.Contract.* AS Contract}
	|
	|INDEX BY
	|	FixedAsset
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FALocation.Organization AS Organization,
	|	FALocation.FixedAssetsLocation AS Department,
	|	FALocation.FixedAsset AS FixedAsset
	|INTO TTLocationOfFA
	|FROM
	|	InformationRegister.FALocation.SliceLast(
	|		&Period {&Period},
	|		CorrectionDate = DATETIME(1,1,1)
	|			AND FixedAsset IN (
	|				SELECT 
	|					LeasedAsset.FixedAsset 
	|				FROM 
	|					TTLeasedFA AS LeasedAsset)) AS FALocation
	|
	|INDEX BY
	|	Organization,
	|	FixedAsset,
	|	Department
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.Contract AS Contract,
	|	SUM(ISNULL(FACost.LocalCostBalance, 0)) AS RentalItems_Cost,
	|	SUM(ISNULL(-FixedAssetsDepreciationCharge.DepreciationLocalBalance, 0)) AS RentalItems_AccruedDepreciation,
	|	SUM(ISNULL(FACost.LocalCostBalance, 0)) + SUM(ISNULL(FixedAssetsDepreciationCharge.DepreciationLocalBalance, 0)) AS RentalItems_ResidualValue
	|FROM
	|	TTLeasedFA AS LeasedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.FixedAsset = LeasedAsset.FixedAsset
	|
	|		LEFT JOIN AccumulationRegister.FACost.Balance(
	|			&PeriodLimit {&PeriodLimit},
	|			(Organization, FixedAsset, Department) IN (
	|				SELECT 
	|					FALocation.Organization, 
	|					FALocation.FixedAsset, 
	|					FALocation.Department 
	|				FROM 
	|					TTLocationOfFA AS FALocation)) AS FACost
	|		ON FACost.Organization = FALocation.Organization
	|			AND FACost.FixedAsset = FALocation.FixedAsset
	|
	|		LEFT JOIN AccumulationRegister.FixedAssetsDepreciationCharge.Balance(
	|			&PeriodLimit {&PeriodLimit},
	|			(Organization, FixedAsset, Department) IN (
	|				SELECT 
	|					FALocation.Organization, 
	|					FALocation.FixedAsset, 
	|					FALocation.Department 
	|				FROM 
	|					TTLocationOfFA AS FALocation)) AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Organization = FALocation.Organization
	|			AND FixedAssetsDepreciationCharge.FixedAsset = FALocation.FixedAsset
	|
	|GROUP BY
	|	LeasedAsset.Contract";
	
	If CostDepreciationCurrency = 2 Then
		QueryText = StrReplace(QueryText,".LocalCost",".Cost");
		QueryText = StrReplace(QueryText,".DepreciationLocal",".Depreciation");
	EndIf;
	
	Return QueryText;
	
EndFunction

Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
EndProcedure

Procedure ConfigureContractReport(Form, FormSettingsComposer)
	
	If Not Form.Parameters.Property("VariantKey")
		Or Form.Parameters.VariantKey <> "ByCustomerContract" Then
		Return;
	EndIf;
	
	CommandParameter = Form.Parameters.CommandParameter;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		ListOfAgreements = CommandParameter;
	Else
		ListOfAgreements = New Array;
		ListOfAgreements.Add(CommandParameter);
	EndIf;
		
	QueryText = 
	"SELECT
	|	ISNULL(MAX(LeaseContract.HasSecurityDeposit), FALSE) AS HasSecurityDeposit,
	|	ISNULL(MAX(LeaseContract.ThereIsBuyoutOfLeasedAssets), FALSE) AS ThereIsBuyoutOfLeasedAssets,
	|	ISNULL(MAX(LeaseContract.ContractType = VALUE(Enum.TypesOfLeaseContracts.Leasing)), FALSE) AS ThereIsLeaseAgreement
	|FROM
	|	Catalog.LeaseContract AS LeaseContract
	|WHERE
	|	LeaseContract.Ref IN (&ListOfAgreements)";
	
	Query = New Query(QueryText);
	Query.SetParameter("ListOfAgreements", ListOfAgreements);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	HasSecurityDeposit = False;
	ThereIsBuyoutOfLeasedAssets = False;
	ThereIsLeaseAgreement = False;

	If Selection.Next() Then
		HasSecurityDeposit = Selection.HasSecurityDeposit;
		ThereIsBuyoutOfLeasedAssets = Selection.ThereIsBuyoutOfLeasedAssets;
		ThereIsLeaseAgreement = Selection.ThereIsLeaseAgreement;
	EndIf;
	
	ItemsNames = New Array;
	
	If Not ThereIsLeaseAgreement Then
		ItemsNames.Add("RentalItems.RentalItems_AccruedDepreciation");
		ItemsNames.Add("RentalItems.RentalItems_ResidualValue");
		ItemsNames.Add("RentalItems.RentalItems_Cost");
	EndIf;
	
	If Not HasSecurityDeposit Then
		ItemsNames.Add("DepositPayment.Calculations_DepositPayment_Paid");
		ItemsNames.Add("DepositPayment.Calculations_DepositPayment_SetOff");
		ItemsNames.Add("DepositPayment.Calculations_DepositPayment_ClosingBalance");
	EndIf;

	If Not ThereIsBuyoutOfLeasedAssets Then
		ItemsNames.Add("BuyoutValue.Calculations_BuyoutValue_Paid");
		ItemsNames.Add("BuyoutValue.Calculations_BuyoutValue_Accrued");
		ItemsNames.Add("BuyoutValue.Calculations_BuyoutValue_ClosingBalance");
	EndIf;
	
	If ItemsNames.Count() <> 0 Then
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, ItemsNames, True);
	EndIf;

EndProcedure

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
		
	ElsIf TypeOf(TheFirstControl) = Type("CatalogRef.LeaseContract") Then
		
		FormParameters.Filter = New Structure("Contract", CommandParameter);
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		
	EndIf;
	
EndProcedure

Function GetDataSelectionValues(MainCircuitSettings)

	FilterItems1 = MainCircuitSettings.Filter.Items;
	
	DataSelectionValues = New Structure;
	
	DataSelectionValues.Insert("CompaniesList", TMReportsServer.FilterValue("Organization", FilterItems1));
	If DataSelectionValues.CompaniesList.Count() = 0 Then
		DataSelectionValues.CompaniesList = NonCurrentAssetsInternal.ListOfAllowedOrganizations();
	EndIf;
	
	Period = TMReportsServer.ParameterValue(MainCircuitSettings, "Period");
	DataSelectionValues.Insert("Period", ?(Period <> Undefined, Period.Date, '000101010000'));
	
	Return DataSelectionValues;
	
EndFunction

Procedure AddInformationalMessageToHeader(TabDoc, DataSelectionValues)

	IssuesList = New Array;
	
	CheckRelevanceOfReport(DataSelectionValues, IssuesList);
	
	If IssuesList.Count() = 0 Then
		Return;
	EndIf; 
	
	IssuesList = TMCommonUse.DeleteDuplicateElementsFromArray(IssuesList);
	
	MessageText = StrConcat(IssuesList, Chars.LF);

	TabDoc.Area("R1C1").Text = MessageText;
	TabDoc.Area("R1C1").TextColor = Metadata.StyleItems.TextColorIssue.Value;
	TabDoc.Area(1, 1, 1, ).RowHeight = 0;
	
EndProcedure

Procedure CheckRelevanceOfReport(DataSelectionValues, IssuesList)

	InformationRegisters.FixedAssetDepreciationPackages.CreateDepreciationPackages(DataSelectionValues.CompaniesList);
	
	QueryText = 
	"SELECT
	|	OrganizationSCat.Presentation AS OrganizationPresentation
	|FROM
	|	Catalog.Companies AS OrganizationSCat
	|WHERE
	|	OrganizationSCat.Ref IN (
	|		SELECT
	|			JobsForCalculating.Organization
	|		FROM
	|			InformationRegister.JobsForCalculatingNonCurrentAssetCost AS JobsForCalculating
	|		WHERE
	|			JobsForCalculating.Organization IN(&CompaniesList)
	|			AND JobsForCalculating.Month <= &Period
	|		
	|		UNION ALL
	|
	|		SELECT
	|			JobsForCalculating.Organization
	|		FROM
	|			InformationRegister.JobsForCalculatingFixedAssetDepreciation AS JobsForCalculating
	|		WHERE
	|			JobsForCalculating.Organization IN(&CompaniesList)
	|			AND JobsForCalculating.Month <= &Period
	|		
	|		UNION ALL
	|
	|		SELECT
	|			JobsForCalculating.Organization
	|		FROM
	|			InformationRegister.JobsForGeneratingFixedAssetRecords AS JobsForCalculating
	|		WHERE
	|			JobsForCalculating.Organization IN(&CompaniesList)
	|			AND JobsForCalculating.Month <= &Period
	|		
	|		UNION ALL
	|
	|		SELECT
	|			JobsForCalculating.Organization
	|		FROM
	|			InformationRegister.JobsForMonthEndClosing AS JobsForCalculating
	|		WHERE
	|			JobsForCalculating.Organization IN(&CompaniesList)
	|			AND JobsForCalculating.Month <= &Period
	|			AND JobsForCalculating.Operation = VALUE(Catalog.MonthEndClosingOperations.AccrualOfLeaseInterest)
	|		)";
	
	Query = New Query(QueryText);
	Query.SetParameter("CompaniesList", DataSelectionValues.CompaniesList);
	Query.SetParameter("Period", DataSelectionValues.Period);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		Return;
	EndIf; 
	
	IssuesList.Add(NStr("vi = 'Dữ liệu trong báo cáo có thể chưa cập nhật:';
						|ru = 'Данные в отчете могут быть неактуальны:';
						|en = 'The data in the report may be out of date:'; fa = 'The data in the report may be out of date:';
						|it = 'I dati nel report potrebbero essere obsoleti:';
						|pl = 'Dane w raporcie mogą być nieaktualne:';
						|tr = 'Raporda yer alan veriler güncel olmayabilir:'"));
	
	Selection = Result.Select();
	While Selection.Next() Do
		MessageText = NStr("vi = '- đối với doanh nghiệp ""%1"" cần hoàn thành việc đóng tháng';
							|ru = '- для организации ""%1"" необходимо выполнить закрытие месяца';
							|en = '- for the company ""%1"" you must perform a month-end closing'; fa = '- for the company ""%1"" you must perform a month-end closing';
							|it = '- per l''azienda ""%1"" è necessario effettuare la chiusura di fine periodo';
							|pl = '- dla firmy ""%1"" należy wykonać zamknięcie miesiąca';
							|tr = '- ""%1"" iş yeri için ay sonu kapanışı işleminin gerçekleştirilmesi gerekmektedir'");
		MessageText = StrTemplate(MessageText, Selection.OrganizationPresentation);
		IssuesList.Add(MessageText); 
	EndDo;
	
EndProcedure

#EndRegion

#EndIf