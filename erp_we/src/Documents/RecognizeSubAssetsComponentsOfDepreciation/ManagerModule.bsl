#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	
	RecognizeSubAssetsComponentsOfDepreciationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure:
//     * Key - String - table name.
//     * Value - ValueTable - table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.RecognizeSubAssetsComponentsOfDepreciation") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		AddlParameters.OnlyMarkedOnes = Registers <> Undefined;
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers);
		QueryTextTableFACost(Query, QueryTexts, Registers);
		QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers);
		
		RecognizeSubAssetsComponentsOfDepreciationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements when calculating the cost.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains the necessary temporary tables.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesForCalculatingCost(TempTablesManager) Export
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;

	GetDocumentData(Query);

	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");

	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 

	QueryTexts = New ValueList;

	QueryTextTableFACost(Query, QueryTexts, Undefined);
	QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Undefined);
	QueryTextTableFALocation(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	RecognizeSubAssetsComponentsOfDepreciationLocalization.TablesForCalculatingCost(Query, QueryTexts);

	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
							
	Return MovementTables;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.AllocateVariancesToFixedAssetCost.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the document "acceptance for OS accounting".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Order	- Number	- The order of the command.
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands, Order = 0) Export
	
	If AccessRight("Insert", Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.Order = Order;
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion
	
#Region Internal

Procedure FillInCost(Object, RowsSelected = Undefined) Export

	If Not CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(Object.Date) Then
		Return;
	EndIf; 
	
	DocumentDate = ?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate());
	FATable = Object.DepreciationComponents.Unload(RowsSelected);

	TempTablesManager = New TempTablesManager;
	
	QueryText = 
	"SELECT
	|	FATable.LineNumber AS LineNumber,
	|	FATable.DepreciationComponent AS DepreciationComponent,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.CostInManagementAccounting AS CostInManagementAccounting,
	|	FATable.CostInAccounting AS CostInAccounting,
	|	FATable.RowID AS RowID
	|
	|INTO FATable
	|
	|FROM
	|	&FATable AS FATable
	|
	|WHERE
	|	FATable.DepreciationComponent <> VALUE(Catalog.Assets.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&RecordInLocalAccounting AS RecordInLocalAccounting,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	FATable.DepreciationComponent AS AccountingObject,
	|	1 AS Priority
	|
	|INTO TTPortionOfDataToBeCalculated
	|
	|FROM
	|	FATable AS FATable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|
	|	&Ref AS Ref,
	|	&Date AS Date,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|
	|	FATable.LineNumber AS LineNumber,
	|	FATable.DepreciationComponent AS AccountingObject,
	|
	|	&CostGenerationProcedure AS CostGenerationProcedure,
	|
	|	FALSE AS ExpensesAreDistributedByObjects,
	|
	|	CASE
	|		WHEN FATable.DepreciationComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
	|				AND NOT FATable.DepreciationComponent.ConsiderResidualLiabilityValue
	|			THEN FATable.FixedAsset
	|		ELSE FATable.DepreciationComponent
	|	END AS ExpensesCapitalizationDimension,
	|
	|	FALSE AS ActualCost,
	|	FALSE AS AttributingDeviationsToCost,
	|	DATETIME(1,1,1) AS SourceDocumentDate,
	|
	|	FATable.CostInManagementAccounting AS AmountOfUU,
	|	FATable.CostInAccounting AS AmountAccounting,
	|	0 AS AmountFA,
	|
	|	UNDEFINED AS TargetFinancingApplicationOption,
	|	0 AS AmountOfTargetFunds,
	|
	|	&RecordInLocalAccounting AS RecordInLocalAccounting,
	|	&RecordInManAccounting AS RecordInManAccounting,
	|	&RecordInLocalAccounting AS PostInAccounting,
	|	FALSE AS RecordInTA,
	|	&RecordInLocalAccounting AS TakeIntoAccountPD,
	|
	|	FATable.RowID AS RowID
	|
	|INTO TTTableOfObjects
	|
	|FROM
	|	FATable AS FATable
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Date", DocumentDate);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("BusinessOperation", Object.BusinessOperation);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("CostGenerationProcedure", Object.CostGenerationProcedure);
	Query.SetParameter("FATable", FATable);
	
	Query.Execute();
	
	FACostCalculation.GenerateTTCurrentExpenses(DocumentDate, TempTablesManager);
	
	QueryText = 
	"SELECT
	|	TTCurExpenses.AccountingObject AS AccountingObject,
	|	SUM(TTCurExpenses.SumMan) AS SumMan,
	|	SUM(TTCurExpenses.SumCompl) AS SumCompl
	|FROM
	|	TTCurExpenses AS TTCurExpenses
	|
	|GROUP BY
	|	TTCurExpenses.AccountingObject
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Result = Query.Execute();

	DocumentExpenses = Result.Unload();
	
	If RowsSelected <> Undefined Then
		StringsList = RowsSelected;
	Else
		StringsList = Object.DepreciationComponents;
	EndIf; 
	
	For Each RowData In StringsList Do
		
		TheStructureOfTheSearch = New Structure("AccountingObject", RowData.DepreciationComponent);
		ListOfExpenseLines = DocumentExpenses.FindRows(TheStructureOfTheSearch);
		If ListOfExpenseLines.Count() <> 0 Then
			If Object.RecordInLocalAccounting Then
				RowData.CostInAccounting = ListOfExpenseLines[0].SumCompl;
			EndIf; 
			If Object.RecordInManAccounting Then
				RowData.CostInManagementAccounting = ListOfExpenseLines[0].SumMan;
			EndIf;
		Else
			RowData.CostInManagementAccounting = 0;
			RowData.CostInAccounting = 0;
		EndIf;
		
	EndDo;
	
EndProcedure

Function PresentationOfDetails(Organization, Date) Export

	PresentationOfDetails = New Map;

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	CurrencyOfManPresentation = String(CurrencyOfMan);
	ComplCurrencyPresentation = String(ComplCurrency);
	
	FALocalAccountingIsConductedIndependently = AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(
		Organization, EndOfMonth(?(Date <> '000101010000', Date, CurrentSessionDate())));
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
		NStr("vi = 'Giá trị';
			|ru = 'Стоимость';
			|en = 'Cost'; fa = 'بهای تمام‌شده';
			|it = 'Cost';
			|pl = 'Cost';
			|tr = 'Maliyet'"), 
		NStr("vi = 'Giá trị (KTDN)';
			|ru = 'Стоимость (БУ)';
			|en = 'Cost (LA)'; fa = 'بها (محلی)';
			|it = 'Costo (contabilità)';
			|pl = 'Wartość (EK)';
			|tr = 'Maliyet (LA)'"), 
		FALocalAccountingIsConductedIndependently, 
		ComplCurrency = CurrencyOfMan,
		ComplCurrencyPresentation);
	
	PresentationOfDetails.Insert("DepreciationComponents.CostInAccounting", FieldPresentation);
	
	//
	FieldPresentation = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
		NStr("vi = 'Giá trị';
			|ru = 'Стоимость';
			|en = 'Cost'; fa = 'بهای تمام‌شده';
			|it = 'Cost';
			|pl = 'Cost';
			|tr = 'Maliyet'"), 
		NStr("vi = 'Giá trị (KTQT)';
			|ru = 'Стоимость (УУ)';
			|en = 'Cost (MA)'; fa = 'بها (مدیریت)';
			|it = 'Costo contabilità gestionale';
			|pl = 'Wartość (EZ)';
			|tr = 'Maliyet (YM)'"), 
		FALocalAccountingIsConductedIndependently, 
		ComplCurrency = CurrencyOfMan,
		CurrencyOfManPresentation);
		
	PresentationOfDetails.Insert("DepreciationComponents.CostInManagementAccounting", FieldPresentation);
	
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị thanh lý tài chính';
																			|ru = 'Ликвидационная стоимость регл.';
																			|en = 'Residual value local'; fa = 'Residual value local';
																			|it = 'Ликвидационная стоимость регл.';
																			|pl = 'Residual value local';
																			|tr = 'Artık değer (yerel)'"), ComplCurrencyPresentation);
	PresentationOfDetails.Insert("DepreciationComponents.ResidualValueLocal", FieldPresentation);
	
	FieldPresentation = NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị thanh lý quản lý';
																			|ru = 'Ликвидационная стоимость упр.';
																			|en = 'Residual value mgmt'; fa = 'Residual value mgmt';
																			|it = 'Residual value mgmt';
																			|pl = 'Residual value mgmt';
																			|tr = 'Tasfiye değeri yön.'"), CurrencyOfManPresentation);
	PresentationOfDetails.Insert("DepreciationComponents.ResidualValueMan", FieldPresentation);
	
	Return PresentationOfDetails;
	
EndFunction

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.RecognizeSubAssetsComponentsOfDepreciation";
	TemporaryTableQueryTexts = New Map();
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RedefiningParameterCalculation = New Structure;
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	EndIf;
		
	If QueryText = Undefined Then
		
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	If RegisterName = "DocumentsRegistry"
		Or RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RequestHasSource,
										RedefiningParameterCalculation);
	Else	
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
										QueryText,
										FullDocumentName,
										SynonymForDocumentTable,
										RedefiningParameterCalculation,
										TemporaryTableQueryTexts);
	EndIf; 

	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters)
	
	DocumentsPosting.FillInInitializationParameters(Query, DocumentRef, AddlParameters);
	
	CreateTTTableWithListOfDocuments(Query);
	GetDocumentData(Query);

	Query.Text =
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	RecognizeSubAssetsComponentsOfDepreciationLocalization.FillInInitializationParameters(Query, Attributes);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");
	
EndProcedure

Procedure CreateTTTableWithListOfDocuments(Query)
	
	Query.Text =
	"SELECT
	|	DocumentsList.Ref AS Ref,
	|	DocumentsList.Organization AS Organization,
	|	DocumentsList.Date AS Period
	|
	|INTO TTListOfDocuments
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentsList
	|
	|WHERE
	|	DocumentsList.Ref = &Ref
	|
	|INDEX BY
	|	Ref
	|";
	
	Query.Execute();
	
EndProcedure

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref                                            AS Ref,
	|	DocumentData.Date                                              AS Period,
	|	DocumentData.Number                                             AS Number,
	|	DocumentData.Organization                                       AS Organization,
	|	DocumentData.Organization.ParentCompany                   AS ParentCompany,
	|	DocumentData.BusinessOperation                             AS BusinessOperation,
	|	DocumentData.EmployeeResponsible                                     AS EmployeeResponsible,
	|	DocumentData.Comment                                       AS Comment,
	|	DocumentData.Posted                                          AS Posted,
	|	DocumentData.DeletionMark                                   AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting                                AS RecordInLocalAccounting,
	|	DocumentData.RecordInLocalAccounting                                AS PostInAccounting,
	|	DocumentData.RecordInManAccounting                                 AS RecordInManAccounting,
	|	DocumentData.FinancialAccountingGroup                            AS FinancialAccountingGroup,
	|	DocumentData.AccountingProcedureAC                                    AS AccountingProcedureAC,
	|	DocumentData.AccountingProcedureMA                                    AS AccountingProcedureMA,
	|	DocumentData.DepreciationAccrualAccounting                            AS DepreciationAccrualAccounting,
	|	DocumentData.DepreciationAccrualManagementAccounting                            AS DepreciationAccrualManagementAccounting,
	|	DocumentData.FixedAssetsEvent                                         AS FixedAssetsEvent,
	|	DocumentData.UsefulLifeAccounting                               AS UsefulLifeAccounting,
	|	DocumentData.UsefulLifeManagementAccounting                               AS UsefulLifeManagementAccounting,
	|	DocumentData.AccelerationFactorManagementAccounting                            AS AccelerationFactorManagementAccounting,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting                      AS DepreciationAccrualMethodManagementAccounting,
	|	DocumentData.LineOfBusiness                           AS LineOfBusiness,
	|	DocumentData.FixedAssetsLocation                                   AS FixedAssetsLocation,
	|	DocumentData.DepreciationMethodAccounting                      AS DepreciationMethodAccounting,
	|	DocumentData.AccelerationFactorAccounting                            AS AccelerationFactorAccounting,
	|	BusinessTransactionsSettings.Ref                             AS BusinessTransactionSetting,
	|
	|	DocumentData.ExpenseItemManagementAccounting    AS ExpenseItemManagementAccounting,
	|	DocumentData.ExpenseItemAccounting    AS ExpenseItemAccounting,
	|	DocumentData.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	DocumentData.ExpensesDimensionManagementAccounting AS ExpensesDimensionManagementAccounting,
	|	DocumentData.FixedAssetsLocation     AS DepartmentACC,
	|	DocumentData.FixedAssetsLocation     AS BusinessUnitManagementAccounting,
	|	DocumentData.LineOfBusiness AS LineOfBusinessBookkeeping,
	|	DocumentData.LineOfBusiness AS LineOfBusinessManagementAccounting,
	|	TRUE AS BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping,
	|	TRUE AS BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting,
	|
	|	&AcceptanceForAccountingOS_DocumentDetails
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|
	|WHERE
	|	DocumentData.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|";
	RecognizeSubAssetsComponentsOfDepreciationLocalization.AddDocumentDetailsToRequestText(QueryText, "DocumentData");
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataTableComponents
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.DepreciationComponent AS DepreciationComponent,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.DepreciationComponent AS AccountingObject,
	|
	|	DocumentTable.CostInManagementAccounting AS CostInManagementAccounting,
	|	DocumentTable.CostInAccounting AS CostInAccounting,
	|
	|	DocumentTable.ResidualValueMan AS ResidualValueMan,
	|	DocumentTable.ResidualValueLocal AS ResidualValueLocal,
	|	DocumentTable.RunningTimeValue AS RunningTimeValue,
	|	DocumentTable.EstimatedRunningTime AS EstimatedRunningTime
	|
	|INTO DocumentDataTableComponents
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	NonCurrentAssetsInternal.ValuesOfParametersForFAAcceptanceForAccounting(ValuesOfHoldingParameters);
	
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.RecognizeSubAssetsComponentsOfDepreciation"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Tiếp nhận vào kế toán các bộ phận và thành phần khấu hao';
															|ru = 'Принятие к учету узлов и компонентов амортизации';
															|en = 'Recognize sub-assets and components of depreciation'; fa = 'شناسایی دارایی‌های فرعی و اجزای استهلاک';
															|it = 'Ricezione in contabilità di nodi e componenti di ammortamento';
															|pl = 'Przyjęcie do ewidencji węzłów i komponentów amortyzacji';
															|tr = 'Alt varlıkların ve amortisman bileşenlerinin muhasebeleştirilmesi'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());

	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS IBDocumentDate,
	|	DocumentData.Number                   AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Organization             AS Organization,
	|	UNDEFINED                            AS Contract,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	UNDEFINED                            AS LineOfBusiness,
	|	DocumentData.FixedAssetsLocation         AS Department,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	DocumentData.Date                    AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	DocumentData.Date                    AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(ComponentTable.LineNumber-1, 0) AS RecNo,
	|	FALSE                                    AS AdditionalRecord,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.FixedAssetsLocation         AS Department,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	ComponentTable.DepreciationComponent AS FixedAsset
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|		LEFT JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS ComponentTable
	|		ON DocumentData.Ref = ComponentTable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	1                                       AS RecNo,
	|	FALSE                                    AS AdditionalRecord,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.FixedAssetsLocation         AS Department,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	TableOfOwners.FixedAsset       AS FixedAsset
	|
	|FROM
	|	Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|
	|		INNER JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS TableOfOwners
	|		ON DocumentData.Ref = TableOfOwners.Ref
	|
	|		LEFT JOIN Document.RecognizeSubAssetsComponentsOfDepreciation.DepreciationComponents AS TableOwnersPrevious
	|		ON TableOwnersPrevious.Ref = TableOfOwners.Ref
	|			AND TableOwnersPrevious.FixedAsset = TableOfOwners.FixedAsset
	|			AND TableOwnersPrevious.LineNumber < TableOfOwners.LineNumber
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND TableOwnersPrevious.Ref IS NULL
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTOwnersInformation(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	DocumentData.Organization               AS Organization,
	|	FATable.DepreciationComponent            AS FixedAsset,
	|	TTOwnersInformation.FinanciallyLiablePerson                  AS FinanciallyLiablePerson,
	|	TTOwnersInformation.FixedAssetsLocation      AS FixedAssetsLocation,
	|	TTOwnersInformation.LocationAddress AS LocationAddress,
	|	TTOwnersInformation.LocationAddressValue AS LocationAddressValue,
	|	DocumentData.RecordInLocalAccounting        AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting         AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataTableComponents AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTOwnersInformation AS TTOwnersInformation
	|		ON TTOwnersInformation.Ref = FATable.Ref
	|			AND TTOwnersInformation.RowID = FATable.RowID
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTOwnersInformation(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	FATable.DepreciationComponent               AS FixedAsset,
	|	TTOwnersInformation.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	FATable.RunningTimeValue                AS RunningTimeValue,
	|	FATable.EstimatedRunningTime                     AS EstimatedRunningTime,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataTableComponents AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTOwnersInformation AS TTOwnersInformation
	|		ON TTOwnersInformation.Ref = FATable.Ref
	|			AND TTOwnersInformation.RowID = FATable.RowID
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTOwnersInformation(QueryTexts);
	
	QueryText = RecognizeSubAssetsComponentsOfDepreciationLocalization.QueryTextTableAccountingProcedureForOSBU();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText =
		"SELECT
		|	DocumentData.Ref         AS Recorder,
		|	DocumentData.Period         AS Period,
		|	DocumentData.Organization    AS Organization,
		|	FATable.DepreciationComponent AS FixedAsset,
		|
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|
		|	DocumentData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE TTOwnersInformation.ExpenseRecordMethodAC
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN DocumentData.ExpenseItemAccounting
		|		ELSE TTOwnersInformation.ExpenseItemAccounting
		|	END AS ExpenseItemAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN DocumentData.ExpensesDimensionAccounting
		|		ELSE TTOwnersInformation.ExpensesDimensionAccounting
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE TTOwnersInformation.DepartmentACC
		|	END AS DepartmentACC,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE TTOwnersInformation.LineOfBusinessBookkeeping
		|	END AS LineOfBusinessBookkeeping
		|
		|FROM
		|	DocumentDataTableComponents AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTOwnersInformation AS TTOwnersInformation
		|		ON TTOwnersInformation.Ref = FATable.Ref
		|			AND TTOwnersInformation.RowID = FATable.RowID
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref         AS Recorder,
		|	DocumentData.Period         AS Period,
		|	DocumentData.Organization    AS Organization,
		|	FATable.DepreciationComponent AS FixedAsset,
		|
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|
		|	DocumentData.DepreciationAccrualManagementAccounting AS DepreciationAccrualAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE TTOwnersInformation.ExpenseRecordMethodAC
		|	END AS ExpenseRecordMethodAC,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN DocumentData.ExpenseItemManagementAccounting
		|		ELSE TTOwnersInformation.ExpenseItemAccounting
		|	END AS ExpenseItemAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN DocumentData.ExpensesDimensionAccounting
		|		ELSE TTOwnersInformation.ExpensesDimensionAccounting
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE TTOwnersInformation.DepartmentACC
		|	END AS DepartmentACC,
		|
		|	CASE 
		|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
		|			THEN UNDEFINED
		|		ELSE TTOwnersInformation.LineOfBusinessBookkeeping
		|	END AS LineOfBusinessBookkeeping
		|
		|FROM
		|	DocumentDataTableComponents AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTOwnersInformation AS TTOwnersInformation
		|		ON TTOwnersInformation.Ref = FATable.Ref
		|			AND TTOwnersInformation.RowID = FATable.RowID
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTOwnersInformation(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                   AS Recorder,
	|	DocumentData.Period                   AS Period,
	|	DocumentData.Organization              AS Organization,
	|	FATable.DepreciationComponent           AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_) AS State,
	|	DocumentData.DepreciationAccrualManagementAccounting   AS AccrueDepreciationOrAmortization,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TTOwnersInformation.MethodForReflectingMaExpenses
	|	END AS ExpensesPostingMethod,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DocumentData.ExpenseItemManagementAccounting
	|		ELSE TTOwnersInformation.ExpenseItemManagementAccounting
	|	END AS ExpenseItem,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DocumentData.ExpensesDimensionManagementAccounting
	|		ELSE TTOwnersInformation.ExpensesDimensionManagementAccounting
	|	END AS DimensionOfExpenses,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TTOwnersInformation.BusinessUnitManagementAccounting
	|	END AS Department,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN UNDEFINED
	|		ELSE TTOwnersInformation.LineOfBusinessManagementAccounting
	|	END AS LineOfBusiness
	|
	|FROM
	|	DocumentDataTableComponents AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTOwnersInformation AS TTOwnersInformation
	|		ON TTOwnersInformation.Ref = FATable.Ref
	|			AND TTOwnersInformation.RowID = FATable.RowID
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|";
		
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers)
	
	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	QueryText = RecognizeSubAssetsComponentsOfDepreciationLocalization.QueryTextTableOSBUDepreciationParameters();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		QueryText =
		"SELECT
		|	DocumentData.Ref         AS Recorder,
		|	DocumentData.Period         AS Period,
		|	DocumentData.Organization    AS Organization,
		|	FATable.DepreciationComponent AS FixedAsset,
		|
		|	DocumentData.Period AS LastChangeDate,
		|	DocumentData.UsefulLifeAccounting AS UsefulLifeMonthsAC,
		|	DocumentData.AccelerationFactorAccounting AS AccelerationFactor,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|				OR DocumentData.DepreciationMethodAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRatesPer1000KmOfMileage)
		|			THEN FATable.EstimatedRunningTime
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	DocumentData.UsefulLifeAccounting AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationManag,
		|
		|	FATable.ResidualValueLocal AS ResidualValueMan
		|
		|FROM
		|	DocumentDataTableComponents AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.DepreciationComponent
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref         AS Recorder,
		|	DocumentData.Period         AS Period,
		|	DocumentData.Organization    AS Organization,
		|	FATable.DepreciationComponent AS FixedAsset,
		|
		|	DocumentData.Period              AS LastChangeDate,
		|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeMonthsAC,
		|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactor,
		|
		|	CASE
		|		WHEN DocumentData.DepreciationAccrualMethodManagementAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
		|				OR DocumentData.DepreciationAccrualMethodManagementAccounting = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRatesPer1000KmOfMileage)
		|			THEN FATable.EstimatedRunningTime
		|	END AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationManag,
		|
		|	FATable.ResidualValueLocal AS ResidualValueMan
		|
		|FROM
		|	DocumentDataTableComponents AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.DepreciationComponent
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);

	QueryText =
	"SELECT
	|	DocumentData.Ref               AS Recorder,
	|	DocumentData.Period               AS Period,
	|	DocumentData.Period               AS LastChangeDate,
	|	DocumentData.Organization          AS Organization,
	|	FATable.DepreciationComponent       AS FixedAsset,
	|
	|	DocumentData.UsefulLifeManagementAccounting  AS UsefulLifeMonths,
	|	DocumentData.UsefulLifeManagementAccounting  AS UsefulLifeForCalculatingDepreciationMonth,
	|	FATable.EstimatedRunningTime             AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactor,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethod,
	|
	|	FATable.ResidualValueMan       AS ResidualValueMan,
	|	FATable.ResidualValueLocal   AS ResidualValueLocal,
	|
	|	ISNULL(CostCalculation.AmountOfUU, FATable.CostInManagementAccounting) AS CostUsedToCalculateDepreciationManag,
	|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting) AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataTableComponents AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
	|		ON CostCalculation.Ref = FATable.Ref
	|			AND CostCalculation.AccountingObject = FATable.DepreciationComponent
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTableTTInitialInformationComponent(QueryTexts);
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);

	QueryText = RecognizeSubAssetsComponentsOfDepreciationLocalization.QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryTextTableTTOwnersInformation(QueryTexts);
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
		QueryText =
		"SELECT
		|	DocumentData.Ref           AS Recorder,
		|	DocumentData.Period           AS Period,
		|	FATable.DepreciationComponent   AS FixedAsset,
		|	DocumentData.Organization      AS Organization,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.Period 
		|		ELSE TTInitialInformationComponent.CommissioningDateAC
		|	END AS CommissioningDateAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN DocumentData.Period 
		|		ELSE TTInitialInformationComponent.CommissioningDateMA
		|	END AS CommissioningDateMA,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting 
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses) 
		|			THEN DocumentData.Ref 
		|		ELSE TTInitialInformationComponent.CommissioningDocumentAC
		|	END AS CommissioningDocumentAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses) 
		|			THEN DocumentData.Ref 
		|		ELSE TTInitialInformationComponent.CommissioningDocumentMA
		|	END AS CommissioningDocumentMA,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting 
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses) 
		|			THEN DocumentData.DepreciationMethodAccounting 
		|		ELSE TTInitialInformationComponent.DepreciationMethodAccounting
		|	END AS DepreciationMethodAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses) 
		|			THEN DocumentData.AccountingProcedureAC 
		|		ELSE TTInitialInformationComponent.AccountingProcedureAC
		|	END AS AccountingProcedureAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses) 
		|			THEN DocumentData.AccountingProcedureMA 
		|		ELSE TTInitialInformationComponent.AccountingProcedureMA
		|	END AS AccountingProcedureMA,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses) 
		|			THEN ISNULL(CostCalculation.AmountAccounting, FATable.CostInAccounting)
		|		ELSE TTInitialInformationComponent.InitialCostLocalAccounting
		|	END AS InitialCostLocalAccounting,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|			THEN ISNULL(CostCalculation.AmountOfUU, FATable.CostInManagementAccounting)
		|		ELSE TTInitialInformationComponent.InitialCostMA
		|	END AS InitialCostMA
		|
		|FROM
		|	DocumentDataTableComponents AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.DepreciationComponent
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|		LEFT JOIN TTInitialInformationComponent AS TTInitialInformationComponent
		|		ON TTInitialInformationComponent.Ref = FATable.Ref
		|			AND TTInitialInformationComponent.FixedAsset = FATable.DepreciationComponent
		|
		|WHERE
		|	(DocumentData.RecordInLocalAccounting
		|				AND DocumentData.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|		OR DocumentData.RecordInManAccounting
		|				AND DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses))
		|
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref          AS Recorder,
		|	DocumentData.Period          AS Period,
		|	FATable.DepreciationComponent  AS FixedAsset,
		|	DocumentData.Organization     AS Organization,
		|
		|	DocumentData.Period AS CommissioningDateAC,
		|	DocumentData.Period AS CommissioningDateMA,
		|	DocumentData.Ref AS CommissioningDocumentAC,
		|	DocumentData.Ref AS CommissioningDocumentMA,
		|
		|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|
		|	CASE DocumentData.AccountingProcedureMA
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.CostIsNotRedeemable)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|	END AS AccountingProcedureAC,
		|
		|	DocumentData.AccountingProcedureMA AS AccountingProcedureMA,
		|
		|	ISNULL(CostCalculation.AmountOfUU, FATable.CostInAccounting) AS InitialCostLocalAccounting,
		|	ISNULL(CostCalculation.AmountAccounting, FATable.CostInManagementAccounting) AS InitialCostMA
		|
		|FROM
		|	DocumentDataTableComponents AS FATable
		|
		|		INNER JOIN DocumentDataDetails AS DocumentData
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculationGrouped AS CostCalculation
		|		ON CostCalculation.Ref = FATable.Ref
		|			AND CostCalculation.AccountingObject = FATable.DepreciationComponent
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = FATable.Ref
		|
		|WHERE
		|	DocumentData.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|";
		
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFACost(Query, QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTOwnersInformation(QueryTexts);
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	QueryText = RecognizeSubAssetsComponentsOfDepreciationLocalization.QueryTextTableFACost(QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	DocumentData.Ref                       AS Recorder,
		|	DocumentData.Period                       AS Period,
		|	DocumentData.Organization                  AS Organization,
		|	TTOwnersInformation.FixedAssetsLocation         AS Department,
		|	DocumentData.FinancialAccountingGroup       AS FinancialAccountingGroup,
		|	TTOwnersInformation.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.BusinessOperation        AS BusinessOperation,
		|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
		|	FATable.DepreciationComponent               AS FixedAsset,
		|
		|	VALUE(Enum.KindsOfExpenseCapitalizationDimension.FixedAssets) AS DimensionKindExpenseCapitalization,
		|
		|	CASE 
		|		WHEN FATable.DepreciationComponent.OSType = VALUE(Enum.FATypes.Node)
		|				OR (FATable.DepreciationComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
		|					AND FATable.DepreciationComponent.ConsiderResidualLiabilityValue)
		|			THEN FATable.DepreciationComponent
		|		ELSE FATable.FixedAsset
		|	END AS ExpensesCapitalizationDimension,
		|
		|	ISNULL(TTCostCalculation.Department, UNDEFINED)                AS DebitBusinessUnit,
		|	ISNULL(TTCostCalculation.LineOfBusiness, UNDEFINED)      AS CorLineOfBusiness,
		|	ISNULL(TTCostCalculation.ExpenseItem, UNDEFINED)               AS CorExpenseItem,
		|	ISNULL(TTCostCalculation.DimensionOfExpenses, UNDEFINED)            AS CorExpenditureDimension,
		|	NOT TTCostCalculation.AccountingObject IS NULL                             AS CostCalculation,
		|
		|	ISNULL(TTCostCalculation.AmountOfUU, FATable.CostInManagementAccounting) AS Cost,
		|	ISNULL(TTCostCalculation.AmountAccounting, FATable.CostInAccounting) AS LocalCost,
		|	ISNULL(TTCostCalculation.AmountFA, 0) AS CostInTaxAccounting,
		|	ISNULL(TTCostCalculation.AmountPermanentDifferences, 0) AS CostPermanentDifference,
		|
		|	ISNULL(TTCostCalculation.AmountAccounting, FATable.CostInAccounting)
		|	 - ISNULL(TTCostCalculation.AmountFA, 0)
		|	 - ISNULL(TTCostCalculation.AmountPermanentDifferences, 0) AS CostTemporaryDifference,
		|
		|	0 AS PreliminaryCostMan,
		|	0 AS PreliminaryCostLocal,
		|	
		|	TTCostCalculation.RowID AS FinRecordID,
		|	DocumentData.BusinessTransactionSetting AS BusinessTransactionSetting 
		|	
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataTableComponents AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTCostCalculation AS TTCostCalculation
		|		ON TTCostCalculation.Ref = FATable.Ref
		|			AND TTCostCalculation.AccountingObject = FATable.DepreciationComponent
		|
		|		LEFT JOIN TTOwnersInformation AS TTOwnersInformation
		|		ON TTOwnersInformation.Ref = FATable.Ref
		|			AND TTOwnersInformation.RowID = FATable.RowID
		|
		|UNION ALL
		|
		// You need to write down the preliminary cost separately to calculate depreciation
		|SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	DocumentData.Ref                       AS Recorder,
		|	DocumentData.Period                       AS Period,
		|	DocumentData.Organization                  AS Organization,
		|	TTOwnersInformation.FixedAssetsLocation         AS Department,
		|	DocumentData.FinancialAccountingGroup       AS FinancialAccountingGroup,
		|	TTOwnersInformation.LineOfBusiness AS LineOfBusiness,
		|	DocumentData.BusinessOperation        AS BusinessOperation,
		|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
		|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
		|	FATable.DepreciationComponent               AS FixedAsset,
		|
		|	VALUE(Enum.KindsOfExpenseCapitalizationDimension.FixedAssets) AS DimensionKindExpenseCapitalization,
		|
		|	CASE 
		|		WHEN FATable.DepreciationComponent.OSType = VALUE(Enum.FATypes.Node)
		|				OR (FATable.DepreciationComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent)
		|					AND FATable.DepreciationComponent.ConsiderResidualLiabilityValue)
		|			THEN FATable.DepreciationComponent
		|		ELSE FATable.FixedAsset
		|	END AS ExpensesCapitalizationDimension,
		|
		|	UNDEFINED                                 AS DebitBusinessUnit,
		|	UNDEFINED                                 AS CorLineOfBusiness,
		|	UNDEFINED                                 AS CorExpenseItem,
		|	UNDEFINED                                 AS CorExpenditureDimension,
		|	FALSE                                         AS CostCalculation,
		|
		|	0                                            AS Cost,
		|	0                                            AS LocalCost,
		|	0                                            AS CostInTaxAccounting,
		|	0                                            AS CostPermanentDifference,
		|	0                                            AS CostTemporaryDifference,
		|
		|	FATable.CostInManagementAccounting                        AS PreliminaryCostMan,
		|	FATable.CostInAccounting                        AS PreliminaryCostLocal,
		|
		|	&IDOfUnusedFinRecord AS FinRecordID,
		|	UNDEFINED AS BusinessTransactionSetting
		|	
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataTableComponents AS FATable
		|		ON DocumentData.Ref = FATable.Ref
		|
		|		LEFT JOIN TTOwnersInformation AS TTOwnersInformation
		|		ON TTOwnersInformation.Ref = FATable.Ref
		|			AND TTOwnersInformation.RowID = FATable.RowID
		|
		|WHERE
		|	(FATable.CostInAccounting <> 0 OR FATable.CostInManagementAccounting <> 0)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOtherExpenses(Query, QueryTexts, Registers)

	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Add_Fields = "Recorder,VariancePeriod";
	Add_Fields = "Recorder,VariancePeriod,AITAmount";
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(Query, QueryTexts, Registers)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	NonCurrentAssetsInternal.TextOfTrafficRequestIncomeExpensesOtherAssetsLiabilitiesAcceptanceForAccounting(ListOfMergeRequests);	
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers)
	
	RegisterName = "SubAssetsComponentsOfDepreciation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	FATable.DepreciationComponent AS SubAssetComponent,
	|	FATable.FixedAsset AS FixedAsset
	|FROM
	|	DocumentDataTableComponents AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts, Add_Fields)

	RegisterName = "TTInitialOtherExpenses";
	
	FACostCalculation.AddEmptyCostCalculationTables(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTTaxSystemSettings(QueryTexts);

	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
	NonCurrentAssetsInternal.TextOfRequestOtherexpensesOfAcceptanceForAccounting(ListOfMergeRequests);
	NonCurrentAssetsInternal.QueryTextOfOtherExpensesShouldNotBeTakenIntoAccountAndIncludedInExpenses(ListOfMergeRequests, True, True, False);
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName);

	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTOwnersInformation(QueryTexts)
	
	TableName = "TTOwnersInformation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText = RecognizeSubAssetsComponentsOfDepreciationLocalization.QueryTextTableTTOwnersInformation(QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "DocumentDataTableComponents");
		NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "DocumentDataTableComponents");
		NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts, "DocumentDataTableComponents");
		NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, "DocumentDataTableComponents");
		NonCurrentAssetsInternal.QueryTextTableTTCompositionOfCGU(QueryTexts, "DocumentDataTableComponents");
		
		QueryText = 
		"SELECT
		|	TableComponents.Ref AS Ref,
		|	TableComponents.RowID AS RowID,
		|
		|	FALocation.FixedAssetsLocation AS FixedAssetsLocation,
		|	FALocation.FinanciallyLiablePerson AS FinanciallyLiablePerson,
		|	FALocation.LeaseholderEmployeeInCharge AS LeaseholderEmployeeInCharge,
		|	FALocation.LocationAddress AS LocationAddress,
		|	FALocation.LocationAddressValue AS LocationAddressValue,
		|	FALocation.LeaseholderBusinessUnit AS LeaseholderBusinessUnit,
		|	FALocation.Leaseholder AS Leaseholder,
		|
		|	FixedAssetsAccountingProcedureManagementAccounting.ExpensesPostingMethod AS MethodForReflectingMaExpenses,
		|	FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem AS ExpenseItemManagementAccounting,
		|	FixedAssetsAccountingProcedureManagementAccounting.DimensionOfExpenses AS ExpensesDimensionManagementAccounting,
		|	FixedAssetsAccountingProcedureManagementAccounting.Department AS BusinessUnitManagementAccounting,
		|	FixedAssetsAccountingProcedureManagementAccounting.LineOfBusiness AS LineOfBusinessManagementAccounting,
		|	FixedAssetsAccountingProcedureManagementAccounting.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherMaOrganization,
		|	FixedAssetsAccountingProcedureManagementAccounting.CompanyRecipientOfExpenses AS OrganizationRecipientOfMaExpenses,
		|
		|	AccountingProcedureForOSBU.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
		|	AccountingProcedureForOSBU.ExpenseItemAccounting AS ExpenseItemAccounting,
		|	AccountingProcedureForOSBU.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
		|	AccountingProcedureForOSBU.DepartmentACC AS DepartmentACC,
		|	AccountingProcedureForOSBU.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
		|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompanyAC,
		|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses AS CompanyRecipientOfExpensesAC,
		|
		|	FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness,
		|
		|	CGUComposition.CGU AS CGU
		|
		|INTO TTOwnersInformation
		|
		|FROM
		|	DocumentDataTableComponents AS TableComponents
		|
		|		LEFT JOIN TTLocationOfFA AS FALocation
		|		ON FALocation.Ref = TableComponents.Ref
		|			AND FALocation.FixedAsset = TableComponents.FixedAsset
		|
		|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
		|		ON FALocation.Ref = TableComponents.Ref
		|			AND FixedAssetsAccountingProcedure.FixedAsset = TableComponents.FixedAsset
		|
		|		LEFT JOIN TTAccountingProcedureForOsuu AS FixedAssetsAccountingProcedureManagementAccounting
		|		ON FALocation.Ref = TableComponents.Ref
		|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = TableComponents.FixedAsset
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
		|		ON AccountingProcedureForOSBU.Ref = TableComponents.Ref
		|			AND AccountingProcedureForOSBU.FixedAsset = TableComponents.FixedAsset
		|
		|		LEFT JOIN TTCompositionOfCGU AS CGUComposition
		|		ON FALocation.Ref = TableComponents.Ref
		|			AND CGUComposition.NonCurrentAsset = TableComponents.FixedAsset
		|
		|INDEX BY
		|	Ref,
		|	RowID
		|";
		
	EndIf;
			
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTableTTInitialInformationComponent(QueryTexts)
	
	TableName = "TTInitialInformationComponent";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

	QueryTextTableTTComponentsList(QueryTexts);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"InitialFixedAssetsInformation", TableName, "TTComponentsList", QueryTexts);
	
EndProcedure

Procedure QueryTextTableTTComponentsList(QueryTexts)
	
	TableName = "TTComponentsList";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.DepreciationComponent AS FixedAsset
	|
	|INTO TTComponentsList
	|
	|FROM
	|	DocumentDataTableComponents AS FATable
	|	
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset,
	|	Organization
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return RecognizeSubAssetsComponentsOfDepreciationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return RecognizeSubAssetsComponentsOfDepreciationLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	// ExpenseItemAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccounting");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	// ExpenseItemManagementAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemManagementAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionManagementAccounting");
	
	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - See ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	Parameters.FillInIf.ObjectFieldsFilledIn = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "CostGenerationProcedure", Parameters);

EndProcedure

#EndRegion

#Region InfobaseUpdate

// Adds procedures to the list that handle updating information security
// data for all supported library versions or configurations.
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - Value tablesdescription of fields, see the procedure
//                Updating the information database.New Update processing table.
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly Mode = False;
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.RecognizeSubAssetsComponentsOfDepreciation.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.27.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("5807569b-0b3d-4ed8-9d23-558239432597");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.RecognizeSubAssetsComponentsOfDepreciation.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Cập nhật các chứng từ ""Ghi nhận vào kế toán các cụm linh kiện và thành phần khấu hao"":
								  |- Điền mục tin ""Phương thức hình thành giá trị""';
								  |ru = 'Обновляет документы ""Принятие к учету узлов и компонентов амортизации"":
								  |- Заполняет реквизит ""Порядок формирования стоимости""';
								  |en = 'Updates the ""Recognize sub-assets and components of depreciation"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.'; fa = 'Updates the ""Recognize sub-assets and components of depreciation"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.';
								  |it = 'Updates the ""Recognize sub-assets and components of depreciation"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.';
								  |pl = 'Updates the ""Recognize sub-assets and components of depreciation"" documents:
								  |- Fills in the ""Сost generation procedure"" attribute.';
								  |tr = '""Alt Üniteler ve Amortisman Bileşenlerinin Muhasebeleştirilmesi"" belgelerini günceller:
								  | - ""Maliyet oluşturma düzeni"" özniteliğini doldurur'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Documents.RecognizeSubAssetsComponentsOfDepreciation.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.RecognizeSubAssetsComponentsOfDepreciation";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Ref.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Ref");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentsList.Ref
	|FROM
	|	(SELECT
	|		DocumentData.Ref AS Ref
	|	FROM
	|		Document.RecognizeSubAssetsComponentsOfDepreciation AS DocumentData
	|	WHERE
	|		DocumentData.CostGenerationProcedure = VALUE(Enum.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.EmptyRef)
	|
	|	) AS DocumentsList
	|";
	Query = New Query(QueryText);

	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Measurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(
		"Document.RecognizeSubAssetsComponentsOfDepreciation.ProcessDataForMigrationToNewVersion");

	FullObjectName = "Document.RecognizeSubAssetsComponentsOfDepreciation";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	ObjectsWithIssuesCount = 0;
	ObjectsProcessed = 0;

	For Each Document In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Document.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			DocumentObject = Document.Ref.GetObject(); // DocumentObject.RecognizeSubAssetsComponentsOfDepreciation
			If DocumentObject = Undefined Then
				CommitTransaction();
				Continue;
			EndIf;
			
			If Not ValueIsFilled(DocumentObject.CostGenerationProcedure) Then
				DocumentObject.CostGenerationProcedure = Enums.CostGenerationProcedureOfFixedAssetsAndIntangibleAssets.IncludeExpensesReceivedBeforeDocumentCreationDateInCost;
			EndIf;
			
			If DocumentObject.Modified() Then
				InfobaseUpdate.WriteData(DocumentObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(DocumentObject.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;

			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Document.Ref);
			
		EndTry;
		
	EndDo;
	
 	NonCurrentAssetsInternal.CheckHandlerExecution(
 		ObjectsWithIssuesCount, 
 		ObjectsProcessed, 
 		FullObjectName);
 		
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(Measurement, ObjectsProcessed);	
	
EndProcedure
 
#EndRegion

#EndRegion

#EndIf
