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
	
	If MonthEndTransactionsServer.ThisFormIsOpenedFromMonthClosingForm(ThisForm) Then
		
		ThisForm.PurposeUseKey = "ContextClosingOfMonth";
		Parameters = ThisForm.Parameters;
		ParametersForm = ThisForm.ParametersForm;
		
		ParametersForm.PurposeUseKey = ThisForm.PurposeUseKey;
		
		ReportPeriod = New StandardPeriod(BegOfMonth(Parameters.RegistrationPeriod), EndOfMonth(Parameters.RegistrationPeriod));
		ParametersForm.Filter.Clear();
		ParametersForm.Filter.Insert("ReportPeriod", ReportPeriod);
		If Not Parameters.AllCompanies Then
			ParametersForm.Filter.Insert("Organization", Parameters.CompanyArray);
		EndIf;
		
	EndIf;
	
	VNAManagementIsUsed = False;
	VNAManagementIsUsed = NonCurrentAssets.VNAManagementIsUsed();
	If Not GetFunctionalOption("UseLoanAndDepositContracts") 
		And Not VNAManagementIsUsed Then
		
		RevaluationSectionField = DataCompositionSchema.DataSets.RegisterRecords.Fields.Find("RevaluationSection");
		RevaluationSections = RevaluationSectionField.GetAvailableValues();
		ListItem = RevaluationSections.FindByValue("FinancialInstrumentsARAP");
		RevaluationSections.Delete(ListItem);
		RevaluationSectionField.SetAvailableValues(RevaluationSections);
		
		SchemaURL = ThisForm.ReportSettings.SchemaURL;
		PutToTempStorage(DataCompositionSchema, ThisForm.ReportSettings.SchemaURL);
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	UseLoanAndDepositContracts = Constants.UseLoanAndDepositContracts.Get();
	DataCompositionClientServer.SetParameter(SettingsComposer, "UseLoanAndDepositContracts", UseLoanAndDepositContracts);
	UseTheLease = NonCurrentAssets.VNAManagementIsUsed();
	DataCompositionClientServer.SetParameter(SettingsComposer, "UseTheLease", UseTheLease);
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		RegisterRecords = DataCompositionSchema.DataSets.RegisterRecords; // DataCompositionSchemaDataSetUnion - 
		RegisterRecords.Items.VendorsARAPAccounting.Query = QueryTextVendorsARAPAccounting();
		RegisterRecords.Items.CustomersARAPAccounting.Query = QueryTextCustomersARAPAccounting();
	EndIf;
	
	If GetFunctionalOption("TradeManagement") Or Not GetFunctionalOption("LocalizationRFService") Then
		Field = DataCompositionSchema.CalculatedFields.Find("TAAccrualIsRequired");
		Field.Expression = "0";
		Field = DataCompositionSchema.TotalFields.Find("TAAccrualIsRequired");
		Field.Expression = "0";
	EndIf;
	
	RegisterRecords = DataCompositionSchema.DataSets.RegisterRecords; // DataCompositionSchemaDataSetUnion - 
	RegisterRecords.Items.PayrollCalculations.Query = QueryTextPayrollCalculations();
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.Full);
	ReportSettings = SettingsComposer.GetSettings();
	
	SetSelectionRequiringAccrual(ReportSettings);
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	DataCompositionServer.SetLayoutTemplateHeaders(StructureOfDynamicHeaders(), CompositionTemplate);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Procedure SetSelectionRequiringAccrual(ReportSettings)
	
	Filters = New Structure;
	GetSelectionsThatRequireAccrual(ReportSettings.Structure, Filters);
	If Filters.Property("Dimension") Then
		NewUse = Filters.Dimension.Use;
		For Each Filter In Filters Do
			Filter.Value.Use = NewUse;
		EndDo;
	EndIf;
	
EndProcedure

Procedure GetSelectionsThatRequireAccrual(ReportStructure, Filters)
	
	For Each Group In ReportStructure Do
		
		If TypeOf(Group) = Type("DataCompositionGroup")
			Or TypeOf(Group) = Type("DataCompositionTableGroup") Then
			FilterElement = FindSelectionByPresentation(Group.Filter.Items, "RequireAccrual");
			If FilterElement <> Undefined Then
				Filters.Insert(Group.Name, FilterElement);
			EndIf;
			GetSelectionsThatRequireAccrual(Group.Structure, Filters);
			
		ElsIf TypeOf(Group) = Type("DataCompositionTable") Then
			GetSelectionsThatRequireAccrual(Group.Rows, Filters);
			GetSelectionsThatRequireAccrual(Group.Columns, Filters);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Function FindSelectionByPresentation(Filter, Presentation)
	
	Result = Undefined;
	For Each Item In Filter Do
		If StrStartsWith(Item.Presentation, Presentation) Then
			Result = Item;
			Break;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

Function StructureOfDynamicHeaders()
	
	DynamicHeaders = New Map;
	
	DynamicHeaders.Insert("1", Constants.ManagementAccountingCurrency.Get());
	
	Return DynamicHeaders;
	
EndFunction

Function QueryTextVendorsARAPAccounting()
	
	Return
	"SELECT
	|	&BeginOfPeriod AS Period,
	|	BEGINOFPERIOD(&BeginOfPeriod, DAY) AS BalanceDate,
	|	UNDEFINED AS Recorder,
	|	Calculations.Currency AS Currency,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.PurchaseOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Dimension.Organization AS Organization,
	|	Dimension.Partner AS Partner,
	|	Dimension.Counterparty AS Counterparty,
	|	Dimension.Contract AS Contract,
	|	Calculations.PurchaseOrder.LineOfBusiness AS LineOfBusiness,
	|	Calculations.DebtBalance AS Sum,
	|	Calculations.ARAPManBalance AS SumMan,
	|	Calculations.DebtLocalBalance AS SumCompl,
	|	0 AS IncomeMan,
	|	0 AS ExpenseMan,
	|	0 AS IncomeCompl,
	|	0 AS ExpenseCompl,
	|	Calculations.PrepaymentManBalance AS PrepaymentMan,
	|	Calculations.PrepaymentLocalBalance AS PrepaymentLocal,
	|	Calculations.PurchaseOrder AS ARAPObject,
	|	Calculations.ARAPDocument AS ARAPDocument
	|INTO TTBalancesAndRevolutions
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments.Balance(
	|			&Period,
	|			Currency <> &CurrencyOfMan
	|				OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency {(AccountingDimensionByPartners).*, (PurchaseOrder).*, (ARAPDocument).*, (Currency).*}) AS Calculations
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|{WHERE
	|	Dimension.Organization.*,
	|	Dimension.Partner.*,
	|	Dimension.Counterparty.*,
	|	Dimension.Contract.*,
	|	Calculations.PurchaseOrder.LineOfBusiness.*}
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.Period,
	|	BEGINOFPERIOD(Calculations.Period, DAY),
	|	Calculations.Recorder,
	|	Calculations.Currency,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.PurchaseOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Dimension.Organization AS Organization,
	|	Dimension.Partner AS Partner,
	|	Dimension.Counterparty AS Counterparty,
	|	Dimension.Contract AS Contract,
	|	Calculations.PurchaseOrder.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Calculations.Debt
	|		ELSE -Calculations.Debt
	|	END AS Sum,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Calculations.ARAPMan
	|		ELSE -Calculations.ARAPMan
	|	END AS SumMan,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Calculations.DebtLocal
	|		ELSE -Calculations.DebtLocal
	|	END AS SumCompl,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN Calculations.ARAPMan + Calculations.PrepaymentMan
	|		ELSE 0
	|	END AS IncomeMan,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN -(Calculations.ARAPMan + Calculations.PrepaymentMan)
	|		ELSE 0
	|	END AS ExpenseMan,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN Calculations.DebtLocal + Calculations.PrepaymentLocal
	|		ELSE 0
	|	END AS IncomeCompl,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN -(Calculations.DebtLocal + Calculations.PrepaymentLocal)
	|		ELSE 0
	|	END AS ExpenseCompl,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -Calculations.PrepaymentMan
	|		ELSE Calculations.PrepaymentMan
	|	END AS  PrepaymentMan,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -Calculations.PrepaymentLocal
	|		ELSE Calculations.PrepaymentLocal
	|	END AS PrepaymentLocal,
	|	Calculations.PurchaseOrder,
	|	Calculations.ARAPDocument
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingByDocuments AS Calculations
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Calculations.Currency <> &CurrencyOfMan OR Calculations.Currency <> Dimension.Organization.LocalAccountingCurrency)
	|{WHERE
	|	Calculations.Recorder,
	|	Calculations.Currency.*,
	|	Calculations.Period,
	|	Calculations.AccountingDimensionByPartners.*,
	|	Calculations.PurchaseOrder.*,
	|	Calculations.ARAPDocument.*,
	|	Dimension.Organization.*,
	|	Dimension.Partner.*,
	|	Dimension.Counterparty.*,
	|	Dimension.Contract.*,
	|	Calculations.PurchaseOrder.LineOfBusiness.*}
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceAndTurnovers.Period AS Period,
	|	BalanceAndTurnovers.BalanceDate AS BalanceDate,
	|	BalanceAndTurnovers.Recorder AS Recorder,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	BalanceAndTurnovers.Counterparty AS Dimension,
	|	BalanceAndTurnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceAndTurnovers.Organization AS Organization,
	|	BalanceAndTurnovers.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BalanceAndTurnovers.Partner AS Partner,
	|	BalanceAndTurnovers.Counterparty AS Counterparty,
	|	BalanceAndTurnovers.Contract AS Contract,
	|	BalanceAndTurnovers.LineOfBusiness AS LineOfBusiness,
	|	SUM(BalanceAndTurnovers.Sum) AS Sum,
	|	SUM(BalanceAndTurnovers.SumMan) AS SumMan,
	|	SUM(BalanceAndTurnovers.SumCompl) AS SumCompl,
	|	SUM(CASE WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) THEN 0 ELSE BalanceAndTurnovers.SumMan END) AS SumManBefore,
	|	SUM(CASE WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) THEN 0 ELSE BalanceAndTurnovers.SumCompl END) AS SumComplBefore,
	|	SUM(BalanceAndTurnovers.IncomeMan) AS IncomeMan,
	|	-SUM(BalanceAndTurnovers.ExpenseMan) AS ExpenseMan,
	|	SUM(BalanceAndTurnovers.IncomeCompl) AS IncomeCompl,
	|	-SUM(BalanceAndTurnovers.ExpenseCompl) AS ExpenseCompl,
	|	BalanceAndTurnovers.ARAPObject AS ObjectOfARAP,
	|	BalanceAndTurnovers.ARAPDocument AS ARAPDocument,
	|	VALUE(Enum.ContractRateOptions.Mutable) AS ContractRateOption,
	|	UNDEFINED AS ContractWithFixedCourse,
	|	""VendorsARAPAccounting"" AS RevaluationSection,
	|	200 AS ProcedureOfRevaluationSection
	|{SELECT
	|	RevaluationSection,
	|	Period,
	|	BalanceDate,
	|	Recorder,
	|	Currency.*,
	|	Dimension.*,
	|	AccountingDimensionByPartners.*,
	|	Organization.*,
	|	LocalAccountingCurrency.*,
	|	Partner.*,
	|	Counterparty.*,
	|	Contract.*,
	|	LineOfBusiness.*,
	|	Sum,
	|	SumMan,
	|	SumCompl,
	|	SumManBefore,
	|	SumComplBefore,
	|	IncomeMan,
	|	ExpenseMan,
	|	IncomeCompl,
	|	ExpenseCompl,
	|	ObjectOfARAP.*,
	|	ARAPDocument.*,
	|	ContractRateOption,
	|	ContractWithFixedCourse,
	|	ProcedureOfRevaluationSection}
	|FROM
	|	TTBalancesAndRevolutions AS BalanceAndTurnovers
	|{WHERE
	|	""VendorsARAPAccounting"" AS RevaluationSection,
	|	BalanceAndTurnovers.Period,
	|	BalanceAndTurnovers.Counterparty.* AS Dimension,
	|	BalanceAndTurnovers.Organization.*,
	|	BalanceAndTurnovers.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BalanceAndTurnovers.Partner.*,
	|	BalanceAndTurnovers.Counterparty.*,
	|	BalanceAndTurnovers.Contract.*,
	|	BalanceAndTurnovers.LineOfBusiness.*,
	|	BalanceAndTurnovers.Currency.*,
	|	BalanceAndTurnovers.Sum,
	|	BalanceAndTurnovers.SumMan,
	|	BalanceAndTurnovers.SumCompl,
	|	CASE WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) THEN 0 ELSE BalanceAndTurnovers.SumMan END AS SumManBefore,
	|	CASE WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) THEN 0 ELSE BalanceAndTurnovers.SumCompl END AS SumComplBefore,
	|	BalanceAndTurnovers.IncomeMan,
	|	BalanceAndTurnovers.ExpenseMan,
	|	BalanceAndTurnovers.IncomeCompl,
	|	BalanceAndTurnovers.ExpenseCompl,
	|	BalanceAndTurnovers.ARAPObject AS ObjectOfARAP,
	|	BalanceAndTurnovers.ARAPDocument}
	|
	|GROUP BY
	|	BalanceAndTurnovers.Period,
	|	BalanceAndTurnovers.BalanceDate,
	|	BalanceAndTurnovers.Recorder,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.AccountingDimensionByPartners,
	|	BalanceAndTurnovers.Organization,
	|	BalanceAndTurnovers.Partner,
	|	BalanceAndTurnovers.Counterparty,
	|	BalanceAndTurnovers.Contract,
	|	BalanceAndTurnovers.LineOfBusiness,
	|	BalanceAndTurnovers.ARAPObject,
	|	BalanceAndTurnovers.ARAPDocument
	|	
	|ORDER BY
	|	Period";
	
EndFunction

Function QueryTextCustomersARAPAccounting()
	
	Return
	"SELECT
	|	&BeginOfPeriod AS Period,
	|	BEGINOFPERIOD(&BeginOfPeriod, DAY) AS BalanceDate,
	|	UNDEFINED AS Recorder,
	|	Calculations.Currency AS Currency,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.SalesOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Dimension.Organization AS Organization,
	|	Dimension.Partner AS Partner,
	|	Dimension.Counterparty AS Counterparty,
	|	Dimension.Contract AS Contract,
	|	Calculations.SalesOrder.LineOfBusiness AS LineOfBusiness,
	|	Calculations.DebtBalance AS Sum,
	|	Calculations.ARAPManBalance AS SumMan,
	|	Calculations.DebtLocalBalance AS SumCompl,
	|	0 AS IncomeMan,
	|	0 AS ExpenseMan,
	|	0 AS IncomeCompl,
	|	0 AS ExpenseCompl,
	|	Calculations.PrepaymentManBalance AS PrepaymentMan,
	|	Calculations.PrepaymentLocalBalance AS PrepaymentLocal,
	|	Calculations.SalesOrder AS ARAPObject,
	|	Calculations.ARAPDocument AS ARAPDocument
	|INTO TTBalancesAndRevolutions
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments.Balance(
	|			&Period,
	|			Currency <> &CurrencyOfMan
	|				OR Currency <> AccountingDimensionByPartners.Organization.LocalAccountingCurrency {(AccountingDimensionByPartners).*, (SalesOrder).*, (ARAPDocument).*, (Currency).*}) AS Calculations
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|{WHERE
	|	Dimension.Organization.*,
	|	Dimension.Partner.*,
	|	Dimension.Counterparty.*,
	|	Dimension.Contract.*,
	|	Calculations.SalesOrder.LineOfBusiness.*}
	|
	|UNION ALL
	|
	|SELECT
	|	Calculations.Period,
	|	BEGINOFPERIOD(Calculations.Period, DAY),
	|	Calculations.Recorder,
	|	Calculations.Currency,
	|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	Calculations.SalesOrder.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	Dimension.Organization AS Organization,
	|	Dimension.Partner AS Partner,
	|	Dimension.Counterparty AS Counterparty,
	|	Dimension.Contract AS Contract,
	|	Calculations.SalesOrder.LineOfBusiness AS LineOfBusiness,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Calculations.Debt
	|		ELSE -Calculations.Debt
	|	END AS Debt,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Calculations.ARAPMan
	|		ELSE -Calculations.ARAPMan
	|	END AS ARAPMan,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN Calculations.DebtLocal
	|		ELSE -Calculations.DebtLocal
	|	END AS DebtLocal,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN Calculations.ARAPMan + Calculations.PrepaymentMan
	|		ELSE 0
	|	END AS IncomeMan,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN -(Calculations.ARAPMan + Calculations.PrepaymentMan)
	|		ELSE 0
	|	END AS ExpenseMan,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN Calculations.DebtLocal + Calculations.PrepaymentLocal
	|		ELSE 0
	|	END AS IncomeCompl,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND VALUETYPE(Calculations.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN -(Calculations.DebtLocal + Calculations.PrepaymentLocal)
	|		ELSE 0
	|	END AS ExpenseCompl,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -Calculations.PrepaymentMan
	|		ELSE Calculations.PrepaymentMan
	|	END AS  PrepaymentMan,
	|	CASE
	|		WHEN Calculations.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN -Calculations.PrepaymentLocal
	|		ELSE Calculations.PrepaymentLocal
	|	END AS PrepaymentLocal,
	|	Calculations.SalesOrder,
	|	Calculations.ARAPDocument
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingByDocuments AS Calculations
	|	LEFT JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|	ON Calculations.AccountingDimensionByPartners = Dimension.DimensionKey
	|WHERE
	|	Calculations.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND (Calculations.Currency <> &CurrencyOfMan OR Calculations.Currency <> Dimension.Organization.LocalAccountingCurrency)
	|{WHERE
	|	Calculations.Recorder,
	|	Calculations.Currency.*,
	|	Calculations.Period,
	|	Calculations.AccountingDimensionByPartners.*,
	|	Calculations.SalesOrder.*,
	|	Calculations.ARAPDocument.*,
	|	Dimension.Organization.*,
	|	Dimension.Partner.*,
	|	Dimension.Counterparty.*,
	|	Dimension.Contract.*,
	|	Calculations.SalesOrder.LineOfBusiness.*}
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceAndTurnovers.Period AS Period,
	|	BalanceAndTurnovers.BalanceDate AS BalanceDate,
	|	BalanceAndTurnovers.Recorder AS Recorder,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	BalanceAndTurnovers.Counterparty AS Dimension,
	|	BalanceAndTurnovers.AccountingDimensionByPartners AS AccountingDimensionByPartners,
	|	BalanceAndTurnovers.Organization AS Organization,
	|	BalanceAndTurnovers.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BalanceAndTurnovers.Partner AS Partner,
	|	BalanceAndTurnovers.Counterparty AS Counterparty,
	|	BalanceAndTurnovers.Contract AS Contract,
	|	BalanceAndTurnovers.LineOfBusiness AS LineOfBusiness,
	|	SUM(BalanceAndTurnovers.Sum) AS Sum,
	|	SUM(BalanceAndTurnovers.SumMan) AS SumMan,
	|	SUM(BalanceAndTurnovers.SumCompl) AS SumCompl,
	|	SUM(CASE WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) THEN 0 ELSE BalanceAndTurnovers.SumMan END) AS SumManBefore,
	|	SUM(CASE WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) THEN 0 ELSE BalanceAndTurnovers.SumCompl END) AS SumComplBefore,
	|	SUM(BalanceAndTurnovers.IncomeMan) AS IncomeMan,
	|	-SUM(BalanceAndTurnovers.ExpenseMan) AS ExpenseMan,
	|	SUM(BalanceAndTurnovers.IncomeCompl) AS IncomeCompl,
	|	-SUM(BalanceAndTurnovers.ExpenseCompl) AS ExpenseCompl,
	|	BalanceAndTurnovers.ARAPObject AS ObjectOfARAP,
	|	BalanceAndTurnovers.ARAPDocument AS ARAPDocument,
	|	VALUE(Enum.ContractRateOptions.Mutable) AS ContractRateOption,
	|	UNDEFINED AS ContractWithFixedCourse,
	|	""CustomersARAPAccounting"" AS RevaluationSection,
	|	100 AS ProcedureOfRevaluationSection
	|{SELECT
	|	RevaluationSection,
	|	Period,
	|	BalanceDate,
	|	Recorder,
	|	Currency.*,
	|	Dimension.*,
	|	AccountingDimensionByPartners.*,
	|	Organization.*,
	|	LocalAccountingCurrency.*,
	|	Partner.*,
	|	Counterparty.*,
	|	Contract.*,
	|	LineOfBusiness.*,
	|	Sum,
	|	SumMan,
	|	SumCompl,
	|	SumManBefore,
	|	SumComplBefore,
	|	ExpenseMan,
	|	IncomeCompl,
	|	ExpenseCompl,
	|	ObjectOfARAP.*,
	|	ARAPDocument.*,
	|	ContractRateOption,
	|	ContractWithFixedCourse,
	|	ProcedureOfRevaluationSection}
	|FROM
	|	TTBalancesAndRevolutions AS BalanceAndTurnovers
	|{WHERE
	|	""CustomersARAPAccounting"" AS RevaluationSection,
	|	BalanceAndTurnovers.Period,
	|	BalanceAndTurnovers.Counterparty.* AS Dimension,
	|	BalanceAndTurnovers.Organization.*,
	|	BalanceAndTurnovers.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BalanceAndTurnovers.Partner.*,
	|	BalanceAndTurnovers.Counterparty.*,
	|	BalanceAndTurnovers.Contract.*,
	|	BalanceAndTurnovers.LineOfBusiness.*,
	|	BalanceAndTurnovers.Currency.*,
	|	BalanceAndTurnovers.Sum,
	|	BalanceAndTurnovers.SumMan,
	|	BalanceAndTurnovers.SumCompl,
	|	CASE WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) THEN 0 ELSE BalanceAndTurnovers.SumMan END AS SumManBefore,
	|	CASE WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation) THEN 0 ELSE BalanceAndTurnovers.SumCompl END AS SumComplBefore,
	|	BalanceAndTurnovers.IncomeMan,
	|	BalanceAndTurnovers.ExpenseMan,
	|	BalanceAndTurnovers.IncomeCompl,
	|	BalanceAndTurnovers.ExpenseCompl,
	|	BalanceAndTurnovers.ARAPObject AS ObjectOfARAP,
	|	BalanceAndTurnovers.ARAPDocument}
	|
	|GROUP BY
	|	BalanceAndTurnovers.Period,
	|	BalanceAndTurnovers.BalanceDate,
	|	BalanceAndTurnovers.Recorder,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.AccountingDimensionByPartners,
	|	BalanceAndTurnovers.Organization,
	|	BalanceAndTurnovers.Partner,
	|	BalanceAndTurnovers.Counterparty,
	|	BalanceAndTurnovers.Contract,
	|	BalanceAndTurnovers.LineOfBusiness,
	|	BalanceAndTurnovers.ARAPObject,
	|	BalanceAndTurnovers.ARAPDocument
	|	
	|ORDER BY
	|	Period";
	
EndFunction

Function QueryTextPayrollCalculations()
	
	QueryText = 
	 "SELECT
	 |	DATETIME(1, 1, 1) AS Period,
	 |	DATETIME(1, 1, 1) AS BalanceDate,
	 |	UNDEFINED AS Recorder,
	 |	VALUE(Catalog.Currencies.EmptyRef) AS Currency,
	 |	VALUE(Catalog.Companies.EmptyRef) AS Organization,
	 |	VALUE(Catalog.Currencies.EmptyRef) AS LocalAccountingCurrency,
	 |	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness,
	 |	VALUE(Catalog.BusinessStructure.EmptyRef) AS Department,
	 |	UNDEFINED AS Partner,
	 |	UNDEFINED AS Counterparty,
	 |	UNDEFINED AS Contract,
	 |	0 AS Sum,
	 |	0 AS SumMan,
	 |	0 AS SumCompl,
	 |	0 AS IncomeMan,
	 |	0 AS ExpenseMan,
	 |	0 AS IncomeCompl,
	 |	0 AS ExpenseCompl,
	 |	0 AS SumManBefore,
	 |	0 AS SumComplBefore,
	 |	UNDEFINED AS ARAPObject,
	 |	UNDEFINED AS ARAPDocument,
	 |	VALUE(Enum.ContractRateOptions.Mutable) AS ContractRateOption,
	 |	UNDEFINED AS ContractWithFixedCourse,
	 |	VALUE(Enum.ContractKindsOfFinancialInstruments.EmptyRef) AS ContractKind,
	 |	""""""Calculation of Payment Service"""""" AS RevaluationSection,
	 |	1400 AS ProcedureOfRevaluationSection
	 |WHERE
	 |	FALSE
	 |
	 |ORDER BY
	 |	Period";

	//++ WE 
	QueryText = 
	"SELECT ALLOWED
	|	&BeginOfPeriod AS Period,
	|	BEGINOFPERIOD(&BeginOfPeriod, DAY) AS BalanceDate,
	|	UNDEFINED AS Recorder,
	|	PayrollCalculationsHR.Organization.LocalAccountingCurrency AS Currency,
	|	PayrollCalculationsHR.Organization AS Organization,
	|	UNDEFINED AS LineOfBusiness,
	|	UNDEFINED AS Department,
	|	PayrollCalculationsHR.SumBalance AS Sum,
	|	PayrollCalculationsHR.SumManBalance AS SumMan,
	|	PayrollCalculationsHR.SumComplBalance AS SumCompl,
	|	0 AS IncomeMan,
	|	0 AS ExpenseMan,
	|	0 AS IncomeCompl,
	|	0 AS ExpenseCompl
	|INTO TTBalancesAndRevolutions
	|FROM
	|	AccumulationRegister.PayrollCalculationsHR.Balance(&Period, Organization.LocalAccountingCurrency <> &CurrencyOfMan) AS PayrollCalculationsHR
	|
	|UNION ALL
	|
	|SELECT
	|	PayrollCalculationsHR.Period,
	|	BEGINOFPERIOD(PayrollCalculationsHR.Period, DAY),
	|	PayrollCalculationsHR.Recorder,
	|	PayrollCalculationsHR.Organization.LocalAccountingCurrency,
	|	PayrollCalculationsHR.Organization,
	|	UNDEFINED,
	|	UNDEFINED,
	|	CASE
	|		WHEN PayrollCalculationsHR.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN PayrollCalculationsHR.Sum
	|		ELSE -PayrollCalculationsHR.Sum
	|	END,
	|	CASE
	|		WHEN PayrollCalculationsHR.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN PayrollCalculationsHR.SumMan
	|		ELSE -PayrollCalculationsHR.SumMan
	|	END,
	|	CASE
	|		WHEN PayrollCalculationsHR.RecordType = VALUE(AccumulationRecordType.Receipt)
	|			THEN PayrollCalculationsHR.SumCompl
	|		ELSE -PayrollCalculationsHR.SumCompl
	|	END,
	|	CASE
	|		WHEN PayrollCalculationsHR.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND VALUETYPE(PayrollCalculationsHR.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN PayrollCalculationsHR.SumMan
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN PayrollCalculationsHR.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND VALUETYPE(PayrollCalculationsHR.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN -PayrollCalculationsHR.SumMan
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN PayrollCalculationsHR.RecordType = VALUE(AccumulationRecordType.Receipt)
	|				AND VALUETYPE(PayrollCalculationsHR.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN PayrollCalculationsHR.SumCompl
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN PayrollCalculationsHR.RecordType = VALUE(AccumulationRecordType.Expense)
	|				AND VALUETYPE(PayrollCalculationsHR.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|			THEN -PayrollCalculationsHR.SumCompl
	|		ELSE 0
	|	END
	|FROM
	|	AccumulationRegister.PayrollCalculationsHR AS PayrollCalculationsHR
	|WHERE
	|	PayrollCalculationsHR.Period BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|	AND PayrollCalculationsHR.SumMan <> 0
	|{WHERE
	|	PayrollCalculationsHR.Recorder,
	|	PayrollCalculationsHR.Organization.*}
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	BalanceAndTurnovers.Period AS Period,
	|	BalanceAndTurnovers.BalanceDate AS BalanceDate,
	|	BalanceAndTurnovers.Recorder AS Recorder,
	|	BalanceAndTurnovers.Currency AS Currency,
	|	BalanceAndTurnovers.Organization AS Organization,
	|	BalanceAndTurnovers.Department AS Department,
	|	BalanceAndTurnovers.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BalanceAndTurnovers.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS Partner,
	|	UNDEFINED AS Counterparty,
	|	UNDEFINED AS Contract,
	|	SUM(BalanceAndTurnovers.Sum) AS Sum,
	|	SUM(BalanceAndTurnovers.SumMan) AS SumMan,
	|	SUM(BalanceAndTurnovers.SumCompl) AS SumCompl,
	|	SUM(CASE
	|			WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|				THEN 0
	|			ELSE BalanceAndTurnovers.SumMan
	|		END) AS SumManBefore,
	|	SUM(CASE
	|			WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|				THEN 0
	|			ELSE BalanceAndTurnovers.SumCompl
	|		END) AS SumComplBefore,
	|	SUM(BalanceAndTurnovers.IncomeMan) AS IncomeMan,
	|	SUM(BalanceAndTurnovers.ExpenseMan) AS ExpenseMan,
	|	SUM(BalanceAndTurnovers.IncomeCompl) AS IncomeCompl,
	|	SUM(BalanceAndTurnovers.ExpenseCompl) AS ExpenseCompl,
	|	UNDEFINED AS ARAPObject,
	|	UNDEFINED AS ARAPDocument,
	|	VALUE(Enum.ContractRateOptions.Mutable) AS ContractRateOption,
	|	UNDEFINED AS ContractWithFixedCourse,
	|	VALUE(Enum.ContractKindsOfFinancialInstruments.EmptyRef) AS ContractKind,
	|	""PayrollCalculationsHR"" AS RevaluationSection,
	|	1300 AS ProcedureOfRevaluationSection
	|{SELECT
	|	RevaluationSection,
	|	Period,
	|	BalanceDate,
	|	Recorder,
	|	Currency.*,
	|	Organization.*,
	|	LocalAccountingCurrency.*,
	|	Partner,
	|	Counterparty,
	|	LineOfBusiness,
	|	Sum,
	|	SumMan,
	|	SumCompl,
	|	SumManBefore,
	|	SumComplBefore,
	|	IncomeCompl,
	|	ExpenseCompl,
	|	IncomeMan,
	|	ExpenseMan,
	|	ContractRateOption,
	|	ContractWithFixedCourse,
	|	ContractKind,
	|	ProcedureOfRevaluationSection}
	|FROM
	|	TTBalancesAndRevolutions AS BalanceAndTurnovers
	|{WHERE
	|	(""PayrollCalculationsHR"") AS RevaluationSection,
	|	BalanceAndTurnovers.Period,
	|	BalanceAndTurnovers.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	BalanceAndTurnovers.Department,
	|	BalanceAndTurnovers.Sum,
	|	BalanceAndTurnovers.SumMan,
	|	BalanceAndTurnovers.SumCompl,
	|	(CASE
	|			WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|				THEN 0
	|			ELSE BalanceAndTurnovers.SumMan
	|		END) AS SumManBefore,
	|	(CASE
	|			WHEN VALUETYPE(BalanceAndTurnovers.Recorder) = TYPE(Document.ExchangeDifferenceCalculation)
	|				THEN 0
	|			ELSE BalanceAndTurnovers.SumCompl
	|		END) AS SumComplBefore,
	|	BalanceAndTurnovers.IncomeCompl,
	|	BalanceAndTurnovers.ExpenseCompl,
	|	BalanceAndTurnovers.IncomeMan,
	|	BalanceAndTurnovers.ExpenseMan,
	|	(VALUE(Enum.ContractKindsOfFinancialInstruments.EmptyRef)) AS ContractKind}
	|
	|GROUP BY
	|	BalanceAndTurnovers.Period,
	|	BalanceAndTurnovers.BalanceDate,
	|	BalanceAndTurnovers.Recorder,
	|	BalanceAndTurnovers.Currency,
	|	BalanceAndTurnovers.Organization,
	|	BalanceAndTurnovers.Department,
	|	BalanceAndTurnovers.LineOfBusiness,
	|	BalanceAndTurnovers.Organization.LocalAccountingCurrency
	|
	|ORDER BY
	|	Period";	
	
	//-- WE 
	
	Return QueryText;
	
EndFunction	

#EndRegion

#EndIf