#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	ReportSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	ExternalDataSets = GetExternalDatasets();
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);

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
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnLoadUserSettingsAtServer = True;
	Settings.Events.AfterQuickSettingsBarFilled         = True;
	
	Settings.ImportSettingsOnChangeParameters = GetSettingsWhenChangingParameters();
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCUserSettings - DataCompositionUserSettings -
//       Custom settings to upload to the Settings Composer.
//
// See also:
//   "Managed Form Extension for a report.Prizagruzkepusers' settings in the server"
//    in the syntax assistant.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export

	AdvanceSelectionRule = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "AdvanceSelectionRule").Value; // EnumRef.ProcedureOfRegisteringTaxInvoicesForPrepayment
	FilterPeriod1 = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "FilterPeriod1").Value; // Standard Period -
	Organization = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "Organization").Value; // Referenceslink.Organizations -
		
	If ValueIsFilled(Organization) 
		And Not AdvanceSelectionRule = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments Then
		
		AdvanceSelectionRule = ObtainRuleForSelectingAdvancesFromAccountingPolicy(Organization, FilterPeriod1.StartDate);
		
		If ValueIsFilled(AdvanceSelectionRule) Then
			DataCompositionClientServer.SetParameter(SettingsComposer.UserSettings,
				"AdvanceSelectionRule",
				AdvanceSelectionRule);
			
			NewDCUserSettings = SettingsComposer.UserSettings;
		EndIf;
		
	EndIf;

EndProcedure

// Called after the report form settings panel is refilled.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   FillParameters - Structure - Parameters to be loaded into the report.
//
Procedure AfterQuickSettingsBarFilled(Form, FillParameters) Export
	
	Form.VariantModified = False;
	If TypeOf(FillParameters) = Type("Structure")
		And FillParameters.Property("VariantModified") Then
		FillParameters.VariantModified = False;
	EndIf;
	
	DCSettingsComposer = CommonClientServer.StructureProperty(FillParameters,
		"DCSettingsComposer"); // Linkerconstructioncomposed -
	
	If DCSettingsComposer = Undefined Then
		Return;
	EndIf;
	
	AdvanceSelectionRule = DataCompositionClientServer.GetParameter(
		DCSettingsComposer.UserSettings, "AdvanceSelectionRule").Value; // EnumRef.ProcedureOfRegisteringTaxInvoicesForPrepayment
	
	If AdvanceSelectionRule = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.AllPayments Then
		Return;
	EndIf;
	
	FilterPeriod1 = DataCompositionClientServer.GetParameter(
		DCSettingsComposer.UserSettings, "FilterPeriod1").Value; // StandardPeriod -
	Organization = DataCompositionClientServer.GetParameter(
		DCSettingsComposer, "Organization").Value; // CatalogRef.Companies -
	
	AdvanceSelectionRule = ObtainRuleForSelectingAdvancesFromAccountingPolicy(Organization, FilterPeriod1.StartDate);
	
	DataCompositionClientServer.SetParameter(Form.Report.SettingsComposer.UserSettings,
		"AdvanceSelectionRule", AdvanceSelectionRule);
	
EndProcedure

#EndRegion

#Region ServiceProceduresFunctions

Function GetSettingsWhenChangingParameters()
	
	Array = New Array;
	Array.Add(New DataCompositionParameter("Organization"));
	
	Return Array;
	
EndFunction

Function ObtainRuleForSelectingAdvancesFromAccountingPolicy(Organization, OnDate)
	
	AdvanceSelectionRule = Enums.ProcedureOfRegisteringTaxInvoicesForPrepayment.EmptyRef();
	
	AccountingPolicyParameters = AccountingPoliciesTaxSettings.CurrentParametersOfTaxesAndAccountingPoliciesAsOfDate(
			"VATAccountingSettings", Organization,
			?(ValueIsFilled(OnDate), OnDate, Undefined));
		
	If ValueIsFilled(AccountingPolicyParameters) Then
		AdvanceSelectionRule = AccountingPolicyParameters.RuleOfPrepaymentFilterToRegisterTaxInvoices;
	EndIf;
	
	Return AdvanceSelectionRule;
	
EndFunction

Function GetExternalDatasets()
	
	StructureOfDataSets = New Structure;
	
	CalculationParameters = VATAccountingERPInternal.InitializeParametersForPreparationOfAdvancePaymentsForVATPurposes();
	
	AdvanceSelectionRule = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "AdvanceSelectionRule").Value; // EnumRef.ProcedureOfRegisteringTaxInvoicesForPrepayment
	FilterPeriod1 = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "FilterPeriod1").Value; // Standard Period -
	Organization = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings, "Organization").Value; // Referenceslink.Organizations -
	
	CalculationParameters.StartDate                    = FilterPeriod1.StartDate;
	CalculationParameters.EndDate                 = FilterPeriod1.EndDate;
	CalculationParameters.Companies                   = Organization;
	CalculationParameters.AdvanceSelectionRule          = AdvanceSelectionRule;
	CalculationParameters.IncludeReferenceDataThatDoesNotRequireVAT = True;
	
	TTM = New TempTablesManager;
	
	Query = New Query;
	Query.TempTablesManager = TTM;
	
	VATAccountingERPInternal.PrepareVT_AdvancesReceived(TTM, CalculationParameters);
	
	SetPrivilegedMode(True);
	
	Query.SetParameter("StartDate",             FilterPeriod1.StartDate);
	Query.SetParameter("EndDate",          FilterPeriod1.EndDate);
	Query.SetParameter("TypeOfAmountCommission",       NStr("vi = 'Phí ngân hàng';
															|ru = 'Комиссия';
															|en = 'Fee'; fa = 'کارمزد';
															|it = 'Commissione';
															|pl = 'Fee';
															|tr = 'Komisyon'"));
	Query.SetParameter("TaxInvoiceBlank",      Documents.IssuedTaxInvoicePrepayment.EmptyRef());
	Query.SetParameter("InventoryTypesOwn", Enums.InventoryTypes.InventoryTypesOwn());
	Query.SetParameter("RefType", Common.MetadataObjectID("Document.IssuedTaxInvoicePrepayment"));
	
	Query.Text =
	"SELECT DISTINCT
	|	AdvanceData.LineOfBusiness AS LineOfBusiness,
	|	AdvanceData.Counterparty AS Counterparty,
	|	AdvanceData.ARAPDocument AS ARAPDocument,
	|	AdvanceData.ARAPObject AS ARAPObject
	|INTO TTAdvanceData
	|FROM
	|	BaseNDS_AdvancesReceived AS AdvanceData
	|
	|INDEX BY
	|	ARAPDocument,
	|	ARAPObject
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	AdvanceData.LineOfBusiness AS LineOfBusiness,
	|	AdvanceData.Counterparty AS Counterparty,
	|	AdvanceData.ARAPDocument AS ARAPDocument
	|INTO TTAdvanceDataCollapsed
	|FROM
	|	TTAdvanceData AS AdvanceData
	|
	|GROUP BY
	|	AdvanceData.LineOfBusiness,
	|	AdvanceData.Counterparty,
	|	AdvanceData.ARAPDocument
	|
	|INDEX BY
	|	ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IssuedTaxInvoicePrepayment.Ref AS Ref,
	|	IssuedTaxInvoicePrepayment.DocumentBasis AS DocumentBasis,
	|	IssuedTaxInvoicePrepayment.Date AS Date,
	|	CASE
	|		WHEN (CAST(SUBSTRING(IssuedTaxInvoicePrepayment.CorrectionNumber, 2, 1) AS STRING(1))) = """"
	|			THEN CAST(""0"" + IssuedTaxInvoicePrepayment.CorrectionNumber AS STRING(3))
	|		ELSE CAST(IssuedTaxInvoicePrepayment.CorrectionNumber AS STRING(3))
	|	END AS FixNumberForSorting
	|INTO TTInvoices
	|FROM
	|	Document.IssuedTaxInvoicePrepayment AS IssuedTaxInvoicePrepayment
	|WHERE
	|	IssuedTaxInvoicePrepayment.Date BETWEEN &StartDate AND &EndDate
	|	AND IssuedTaxInvoicePrepayment.DocumentBasis IN
	|			(SELECT
	|				T.ARAPDocument
	|			FROM
	|				TTAdvanceData AS T)
	|	AND IssuedTaxInvoicePrepayment.Posted
	|	AND NOT TRUE IN 
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		WHERE
	|			DocumentsRegistry.RefType = &RefType
	|			AND DocumentsRegistry.ReversedDocument = IssuedTaxInvoicePrepayment.Ref
	|			AND DocumentsRegistry.Posted)
	|
	|INDEX BY
	|	IssuedTaxInvoicePrepayment.DocumentBasis
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AdvanceData.LineOfBusiness AS LineOfBusiness,
	|	AdvanceData.Counterparty AS Counterparty,
	|	AdvanceData.ARAPDocument AS DocumentPayments,
	|	SUM(CASE
	|			WHEN ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, 0) + ISNULL(DocumentAmountsInAccountingCurrency.VATAmountCompl, 0) >= 0
	|				THEN 1
	|			ELSE -1
	|		END * (ISNULL(DocumentAmountsInAccountingCurrency.AmountExcludingVATCompl, 0) + ISNULL(DocumentAmountsInAccountingCurrency.VATAmountCompl, 0))) AS PaymentAmount
	|FROM
	|	TTAdvanceDataCollapsed AS AdvanceData
	|		LEFT JOIN InformationRegister.DocumentAmountsInAccountingCurrency AS DocumentAmountsInAccountingCurrency
	|		ON AdvanceData.ARAPDocument = DocumentAmountsInAccountingCurrency.Recorder
	|
	|GROUP BY
	|	AdvanceData.LineOfBusiness,
	|	AdvanceData.Counterparty,
	|	AdvanceData.ARAPDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Prepayments.LineOfBusiness AS LineOfBusiness,
	|	Prepayments.Counterparty AS Counterparty,
	|	Prepayments.ARAPDocument AS DocumentPayments,
	|	Prepayments.ARAPObject AS ARAPObject,
	|	Prepayments.MaturityDate AS OffsetDate,
	|	MAX(Prepayments.DocumentRecorder) AS DocumentRecorder,
	|	Prepayments.AccrueVAT AS AccrueVAT,
	|	SUM(Prepayments.Sum) AS AmountOfCreditOrBalanceOfAdvance
	|FROM
	|	BaseNDS_AdvancesReceived AS Prepayments
	|
	|GROUP BY
	|	Prepayments.LineOfBusiness,
	|	Prepayments.Counterparty,
	|	Prepayments.ARAPDocument,
	|	Prepayments.ARAPObject,
	|	Prepayments.MaturityDate,
	|	Prepayments.AccrueVAT
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InvoiceData_4.LineOfBusiness AS LineOfBusiness,
	|	InvoiceData_4.Counterparty AS Counterparty,
	|	InvoiceData_4.DocumentPayments AS DocumentPayments,
	|	InvoiceData_4.ARAPObject AS ARAPObject,
	|	ISNULL(InvoiceData_4.TaxInvoice, &TaxInvoiceBlank) AS TaxInvoice,
	|	InvoiceData_4.TypeOfAmountForSF AS TypeOfAmountForSF,
	|	InvoiceData_4.TypeOfVATAmount AS TypeOfVATAmount,
	|	SUM(InvoiceData_4.AmountByTaxInvoices) AS AmountByTaxInvoices,
	|	SUM(InvoiceData_4.VATAmount) AS VATAmount
	|FROM
	|	(SELECT
	|		AdvanceData.LineOfBusiness AS LineOfBusiness,
	|		AdvanceData.Counterparty AS Counterparty,
	|		Invoices_.DocumentBasis AS DocumentPayments,
	|		AdvanceData.ARAPObject AS ARAPObject,
	|		Invoices_.Ref AS TaxInvoice,
	|		CASE
	|			WHEN TableAdvances.InventoryType IN (&InventoryTypesOwn)
	|				THEN TableAdvances.VATRate.Rate1
	|			ELSE &TypeOfAmountCommission
	|		END AS TypeOfAmountForSF,
	|		TableAdvances.VATRate.Rate1 AS TypeOfVATAmount,
	|		CAST(TableAdvances.Sum * CASE
	|				WHEN TableAdvances.InventoryType IN (&InventoryTypesOwn)
	|					THEN ISNULL(TableAdvances.VATRate.Rate1, 0) / (CASE
	|							WHEN TableAdvances.VATRate.CalculatedRate = TRUE
	|								THEN TableAdvances.VATRate.Rate1
	|							ELSE 0
	|						END + 100)
	|				ELSE 0
	|			END AS NUMBER(31, 2)) AS VATAmountCalculated,
	|		TableAdvances.Sum AS AmountByTaxInvoices,
	|		CASE
	|			WHEN TableAdvances.InventoryType IN (&InventoryTypesOwn)
	|				THEN TableAdvances.VATAmount
	|			ELSE 0
	|		END AS VATAmount
	|	FROM
	|		TTAdvanceData AS AdvanceData
	|			LEFT JOIN TTInvoices AS Invoices_
	|			ON AdvanceData.ARAPDocument = Invoices_.DocumentBasis
	|			LEFT JOIN Document.IssuedTaxInvoicePrepayment.Prepayments AS TableAdvances
	|			ON (Invoices_.Ref = TableAdvances.Ref)
	|				AND AdvanceData.ARAPObject = TableAdvances.ARAPObject
	|	WHERE
	|		(Invoices_.FixNumberForSorting, TRUE) IN
	|				(SELECT
	|					MAX(T.FixNumberForSorting) AS FixNumberForSorting,
	|					TRUE
	|				FROM
	|					TTInvoices AS T
	|				WHERE
	|					Invoices_.DocumentBasis = T.DocumentBasis)) AS InvoiceData_4
	|
	|GROUP BY
	|	InvoiceData_4.LineOfBusiness,
	|	InvoiceData_4.Counterparty,
	|	InvoiceData_4.DocumentPayments,
	|	ISNULL(InvoiceData_4.TaxInvoice, &TaxInvoiceBlank),
	|	InvoiceData_4.TypeOfAmountForSF,
	|	InvoiceData_4.TypeOfVATAmount,
	|	InvoiceData_4.ARAPObject";
	
	ResultsPackage = Query.ExecuteBatch();
	
	Selection1 =  ResultsPackage[ResultsPackage.Count() - 3].Select();
	Selection2 =  ResultsPackage[ResultsPackage.Count() - 2].Select();
	Selection3 =  ResultsPackage[ResultsPackage.Count() - 1].Select();
	
	StructureOfDataSets.Insert("AdvanceData", Selection1);
	StructureOfDataSets.Insert("VATBase",       Selection2);
	StructureOfDataSets.Insert("SFData",    Selection3);
	
	
	Return StructureOfDataSets;
	
EndFunction

#EndRegion

#EndIf
