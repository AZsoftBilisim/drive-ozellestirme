#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	ReturnAssetsFromLeaseeLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReturnAssetsFromLeasee2_4") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableFixedAssetsDocuments(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(QueryTexts, Registers);
		
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableAssetsLeasedOut(QueryTexts, Registers);
		QueryTextTableScheduleOfPaymentsForIncomeRentalServices(QueryTexts, Registers);
		QueryTextTableScheduleOfChargesForIncomeRentalServices(QueryTexts, Registers);
		QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		ReturnAssetsFromLeaseeLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

// Generates tables of movements during deferred execution.
//
// Parameters:
//  TempTablesManager - TempTablesManager - Contains temporary tables that are used in the formation of Registered Records.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function TablesOfDeferredMotionFormation(TempTablesManager) Export

	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	
	GetDocumentData(Query);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParametersByPeriod(Query, Query.Parameters,, "TTListOfDocuments");
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	QueryTexts = New ValueList;
		
	QueryTextTableFACost(QueryTexts);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	
	QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableInitialFixedAssetsInformation(QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Undefined);
	QueryTextTableAssetsLeasedOut(QueryTexts, Undefined);
	QueryTextTableInvestmentInRent(Query, QueryTexts, Undefined);
	QueryTextTableOtherExpenses(Query, QueryTexts, Undefined);
	QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	ReturnAssetsFromLeaseeLocalization.TablesOfDeferredMotionFormation(QueryTexts);
	
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
	
	ReturnAssetsFromLeaseeLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "returning an OS from a lease".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  
// Returns:
//	ValueTableRow - added command.
//	
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReturnAssetsFromLeasee2_4) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReturnAssetsFromLeasee2_4.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReturnAssetsFromLeasee2_4);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		
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
	
	ReturnAssetsFromLeaseeLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReturnAssetsFromLeaseeLocalization.AddReportCommands(ReportsCommands, Parameters);

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

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ReturnAssetsFromLeasee2_4";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
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
										RedefiningParameterCalculation);
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
	|	DocumentData.Period  AS Period,
	|	DocumentData.Number   AS Number
	|FROM
	|	DocumentDataDetails AS DocumentData";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
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
	|	Document.ReturnAssetsFromLeasee2_4 AS DocumentsList
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
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Leaseholder               AS Leaseholder,
	|	DocumentData.Department           AS Department,
	|	DocumentData.FinanciallyLiablePerson                     AS FinanciallyLiablePerson,
	|	DocumentData.LocationAddress    AS LocationAddress,
	|	DocumentData.LocationAddressValue AS LocationAddressValue,
	|	DocumentData.ReceivingBusinessUnit AS ReceivingBusinessUnit,
	|	DocumentData.EmployeeResponsible           AS EmployeeResponsible,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	DocumentData.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
	|	DocumentData.ExpenseItemAccounting        AS ExpenseItemAccounting,
	|	DocumentData.ExpensesDimensionAccounting     AS ExpensesDimensionAccounting,
	|	DocumentData.DepartmentACC         AS DepartmentACC,
	|	DocumentData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping AS BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping,
	|	DocumentData.MethodForReflectingMaExpenses AS MethodForReflectingMaExpenses,
	|	DocumentData.ExpenseItemManagementAccounting        AS ExpenseItemManagementAccounting,
	|	DocumentData.ExpensesDimensionManagementAccounting     AS ExpensesDimensionManagementAccounting,
	|	DocumentData.BusinessUnitManagementAccounting         AS BusinessUnitManagementAccounting,
	|	DocumentData.LineOfBusinessManagementAccounting AS LineOfBusinessManagementAccounting,
	|	DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting AS BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting,
	|	DocumentData.DepreciationAccrualLocalAccounting AS DepreciationAccrualLocalAccounting,
	|	DocumentData.DepreciationAccrualMan AS DepreciationAccrualMan,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	VALUE(Enum.BusinessTransactions.ReturnAssetsFromLeasee) AS BusinessOperation,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.Contract <> VALUE(Catalog.CounterpartyContracts.EmptyRef) AS ReturnFromFinarenda,
	|
	|	CASE 
	|		WHEN DocumentData.LeaseholderIntercompanyARAP
	|			THEN DocumentData.Leaseholder
	|		ELSE DocumentData.Organization
	|	END AS SenderOrganization,
	|
	|	DocumentData.LeaseholderIntercompanyARAP AS LeaseholderIntercompanyARAP
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.ReturnAssetsFromLeasee2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref IN (
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
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure,
	|	DocumentTable.ExpenseItem AS ExpenseItem,
	|	DocumentTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	DocumentTable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	DocumentTable.GLAccountSettings AS GLAccountSettings
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.ReturnAssetsFromLeasee2_4.FA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (
	|		SELECT
	|			TTListOfDocuments.Ref
	|		FROM
	|			TTListOfDocuments AS TTListOfDocuments)
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	Query.Text = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	Query.Execute();
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ReturnAssetsFromLeasee2_4"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Trả lại TSCĐ đã thuê';
															|ru = 'Возврат ОС из аренды';
															|en = 'Return assets from lessee'; fa = 'برگشت دارایی‌ها از مستأجر';
															|it = 'Reso immobilizzazione dall''affitto';
															|pl = 'Zwrot środków trwałych z dzierżawy';
															|tr = 'Varlıkların kiralayandan iadesi'"));
	
	ValuesOfHoldingParameters.Insert("BO_Cost", Enums.BusinessTransactions.FixedAssetsCostParameterChange);
	ValuesOfHoldingParameters.Insert("BO_Depreciation", Enums.BusinessTransactions.FixedAssetDepreciationParameterChange);
	ValuesOfHoldingParameters.Insert("SettingUpHO_Cost", Catalogs.BusinessTransactionsSettings.FixedAssetsCostParameterChange);
	ValuesOfHoldingParameters.Insert("SettingUpHO_Depreciation", Catalogs.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange);
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	
	ValuesOfHoldingParameters.Insert("BO_ReturnAssetsFromLeasee", Enums.BusinessTransactions.ReturnAssetsFromLeasee);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReturningAssetsFromLessee", Catalogs.BusinessTransactionsSettings.ReturnAssetsFromLeasee);
	ValuesOfHoldingParameters.Insert("SettingUpHO_EarlyRentalTermination", Catalogs.BusinessTransactionsSettings.EarlyTerminationOfLeaseContract);
	ValuesOfHoldingParameters.Insert("SettingUpHO_EnablingNGLSVCostOfCHIA", Catalogs.BusinessTransactionsSettings.IncludeNonGuaranteedResidualValueInNetValueOfRentalInvestments);
	
	ValuesOfHoldingParameters.Insert("CurrencyOfMan", SettingsValueCached.ManagementAccountingCurrency());
	ValuesOfHoldingParameters.Insert("TypesOfContractsUnderFSB25", LeasedAssetAccountingClientServer.TypesOfProfitableLeaseContracts());
	
	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)     AS RecNo,
	|	DocumentData.Date                     AS Date,
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.ReceivingBusinessUnit  AS Department,
	|	DocumentData.Posted                 AS Posted,
	|	&BO_ReturnAssetsFromLeasee                    AS BusinessOperation,
	|	&MetadataIdentifier                 AS RefType,
	|	DocumentData.RecordInLocalAccounting       AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting        AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting       AS RecordInTA,
	|	DocumentData.FixedAssetsEvent                AS FixedAssetsEvent,
	|	FATable.FixedAsset               AS FixedAsset,
	|	FALSE                                     AS AdditionalRecord
	|
	|FROM
	|	Document.ReturnAssetsFromLeasee2_4 AS DocumentData
	|
	|		LEFT JOIN Document.ReturnAssetsFromLeasee2_4.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref";	
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref          AS Ref,
	|	DocumentData.Date            AS IBDocumentDate,
	|	DocumentData.Number           AS IBDocumentNumber,
	|	&MetadataIdentifier        AS RefType,
	|	DocumentData.Organization     AS Organization,
	|	DocumentData.Leaseholder       AS Counterparty,
	|	DocumentData.Contract         AS Contract,
	|	&BO_ReturnAssetsFromLeasee           AS BusinessOperation,
	|	UNDEFINED                    AS LineOfBusiness,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	DocumentData.EmployeeResponsible   AS EmployeeResponsible,
	|	DocumentData.Comment     AS Comment,
	|	DocumentData.Posted        AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE                            AS AdditionalRecord,
	|	DocumentData.Date            AS SourceDocumentDate,
	|	&NumberForPrinting                  AS SourceDocumentNumber,
	|	FALSE                            AS ReverseTransactionCorrection,
	|	UNDEFINED                    AS ReversedDocument,
	|	UNDEFINED                    AS CorrectedDocument,
	|	DocumentData.Date            AS RecordingInAccountingDate,
	|	UNDEFINED                    AS Priority
	|
	|FROM
	|	Document.ReturnAssetsFromLeasee2_4 AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref               AS Recorder,
	|	DocumentData.Period               AS Period,
	|	DocumentData.Organization          AS Organization,
	|	FALocation.FixedAsset   AS FixedAsset,
	|	DocumentData.FinanciallyLiablePerson                  AS FinanciallyLiablePerson,
	|	DocumentData.ReceivingBusinessUnit AS FixedAssetsLocation,
	|
	|	CASE
	|		WHEN DocumentData.LocationAddress <> """"
	|			THEN DocumentData.LocationAddress
	|		ELSE FALocation.LocationAddress
	|	END AS LocationAddress,
	|
	|	CASE
	|		WHEN DocumentData.LocationAddress <> """"
	|			THEN DocumentData.LocationAddressValue
	|		ELSE FALocation.LocationAddressValue
	|	END AS LocationAddressValue
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = DocumentData.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	DocumentData.Organization               AS Organization,
	|	TTAccountingFA.FixedAsset         AS FixedAsset,
	|	DocumentData.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	TTAccountingFA.LineOfBusiness  AS LineOfBusiness,
	|	TTAccountingFA.RunningTimeValue      AS RunningTimeValue,
	|	TTAccountingFA.EstimatedRunningTime           AS EstimatedRunningTime,
	|	CASE WHEN DocumentData.ReturnFromFinarenda 
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|		THEN TRUE
	|	ELSE
	|		DocumentData.RecordInLocalAccounting
	|	END AS RecordInLocalAccounting,
	|	CASE WHEN DocumentData.ReturnFromFinarenda 
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|		THEN TRUE
	|	ELSE
	|		DocumentData.RecordInManAccounting
	|	END AS RecordInManAccounting
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingFA AS TTAccountingFA
	|		ON TTAccountingFA.Ref = DocumentData.Ref
	|		AND TTAccountingFA.FixedAsset = FATable.FixedAsset
	|WHERE DocumentData.ReturnFromFinarenda
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	FixedAssetsAccountingProcedure.FixedAsset         AS FixedAsset,
	|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness  AS LineOfBusiness,
	|	FixedAssetsAccountingProcedure.RunningTimeValue      AS RunningTimeValue,
	|	FixedAssetsAccountingProcedure.EstimatedRunningTime           AS EstimatedRunningTime,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|
	|WHERE NOT DocumentData.ReturnFromFinarenda
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_) AS State,
	|	DocumentData.DepreciationAccrualMan = VALUE(Enum.DepreciationAccrualChangeOptions.Valid) AS AccrueDepreciationOrAmortization,
	|	DocumentData.MethodForReflectingMaExpenses AS ExpensesPostingMethod,
	|	DocumentData.ExpenseItemManagementAccounting        AS ExpenseItem,
	|	DocumentData.ExpensesDimensionManagementAccounting     AS DimensionOfExpenses,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
	|			THEN DocumentData.ReceivingBusinessUnit
	|		ELSE DocumentData.BusinessUnitManagementAccounting
	|	END AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataManagementAccounting
	|			THEN TTAccountingFA.LineOfBusiness
	|		ELSE DocumentData.LineOfBusinessManagementAccounting
	|	END AS LineOfBusiness
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|			
	|		LEFT JOIN TTAccountingFA AS TTAccountingFA
	|		ON TTAccountingFA.Ref = FATable.Ref
	|			AND TTAccountingFA.FixedAsset = FATable.FixedAsset
	|			
	|		LEFT JOIN TTAccountingProcedureForOsuu AS TTAccountingProcedureForOsuu
	|		ON TTAccountingProcedureForOsuu.Ref = FATable.Ref
	|			AND TTAccountingProcedureForOsuu.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND NOT DocumentData.ReturnFromFinarenda
	|	AND DocumentData.DepreciationAccrualMan IN (
	|		VALUE(Enum.DepreciationAccrualChangeOptions.Valid),
	|		VALUE(Enum.DepreciationAccrualChangeOptions.Stopped))
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_) AS State,
	|	TRUE                                     AS DepreciationAccrualManagementAccounting,
	|	TTAccountingProcedureForOsuu.ExpensesPostingMethod AS ExpensesPostingMethod,
	|	TTAccountingProcedureForOsuu.ExpenseItem          AS ExpenseItem,
	|	TTAccountingProcedureForOsuu.DimensionOfExpenses       AS DimensionOfExpenses,
	|	DocumentData.ReceivingBusinessUnit    AS Department,
	|	TTAccountingProcedureForOsuu.LineOfBusiness AS LineOfBusiness
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS TTAccountingProcedureForOsuu
	|		ON TTAccountingProcedureForOsuu.Ref = FATable.Ref
	|			AND TTAccountingProcedureForOsuu.FixedAsset = FATable.FixedAsset
	|WHERE
	|	DocumentData.ReturnFromFinarenda
	|	AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	CASE WHEN TTAccountingProcedureForOsuu.State = VALUE(Enum.FixedAssetsStates.Recognized_)
	|		THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks)
	|		ELSE TTAccountingProcedureForOsuu.State
	|	END                                   AS State,
	|	FALSE                                    AS DepreciationAccrualManagementAccounting,
	|	TTAccountingProcedureForOsuu.ExpensesPostingMethod AS ExpensesPostingMethod,
	|	TTAccountingProcedureForOsuu.ExpenseItem       AS ExpenseItem,
	|	TTAccountingProcedureForOsuu.DimensionOfExpenses    AS DimensionOfExpenses,
	|	TTAccountingProcedureForOsuu.Department        AS Department,
	|	TTAccountingProcedureForOsuu.LineOfBusiness AS LineOfBusiness
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS TTAccountingProcedureForOsuu
	|		ON TTAccountingProcedureForOsuu.Ref = FATable.Ref
	|			AND TTAccountingProcedureForOsuu.FixedAsset = FATable.FixedAsset
	|WHERE
	|	DocumentData.ReturnFromFinarenda
	|	AND FATable.FixedAssetsAccountingProcedure IN (
	|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.TakeIntoAccountAsRentalInvestment),
	|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.ToExpenseAs),
	|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.WriteOffToAssetItem))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTExtendedFATable");
	
	QueryText = ReturnAssetsFromLeaseeLocalization.QueryTextTableAccountingProcedureForOSBU();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
		
		QueryText =
		"SELECT
		|	DocumentData.Ref                  AS Recorder,
		|	DocumentData.Period                  AS Period,
		|	DocumentData.Organization             AS Organization,
		|	FATable.FixedAsset              AS FixedAsset,
		|
		|	TueAccountingProcedureForOSBU.BUState          AS BUState,
		|
		// DepreciationAccrualAccounting
		|	CASE 
		|		WHEN DocumentData.DepreciationAccrualLocalAccounting = VALUE(Enum.DepreciationAccrualChangeOptions.Valid)
		|			AND (TueAccountingProcedureForOSBU.DepreciationAccrualAccounting
		|				OR InitialFixedAssetsInformation.AccountingProcedureAC IN (
		|					VALUE(Enum.FARepaymentProcedure.DepreciationAccrual),
		|					VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS DepreciationAccrualAccounting,
		|
		|	DocumentData.ExpenseRecordMethodAC              AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemAccounting                       AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionAccounting                    AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
		|			THEN DocumentData.ReceivingBusinessUnit
		|		ELSE DocumentData.DepartmentACC
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
		|			THEN TTAccountingFA.LineOfBusiness
		|		ELSE DocumentData.LineOfBusinessBookkeeping
		|	END AS LineOfBusinessBookkeeping
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTExtendedFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|			
		|		LEFT JOIN TTAccountingFA AS TTAccountingFA
		|		ON TTAccountingFA.Ref = FATable.Ref
		|			AND TTAccountingFA.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS TueAccountingProcedureForOSBU
		|		ON TueAccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND TueAccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|		INNER JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND NOT DocumentData.ReturnFromFinarenda
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.DepreciationAccrualLocalAccounting IN (
		|		VALUE(Enum.DepreciationAccrualChangeOptions.Valid),
		|		VALUE(Enum.DepreciationAccrualChangeOptions.Stopped))
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref                  AS Recorder,
		|	DocumentData.Period                  AS Period,
		|	DocumentData.Organization             AS Organization,
		|	FATable.FixedAsset              AS FixedAsset,
		|
		|	TueAccountingProcedureForOSBU.BUState          AS BUState,
		|
		// DepreciationAccrualAccounting
		|	CASE 
		|		WHEN DocumentData.DepreciationAccrualLocalAccounting = VALUE(Enum.DepreciationAccrualChangeOptions.Valid)
		|			AND (TueAccountingProcedureForOSBU.DepreciationAccrualAccounting
		|				OR InitialFixedAssetsInformation.AccountingProcedureAC IN (
		|					VALUE(Enum.FARepaymentProcedure.DepreciationAccrual),
		|					VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)))
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS DepreciationAccrualAccounting,
		|
		|	DocumentData.MethodForReflectingMaExpenses AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemManagementAccounting         AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionManagementAccounting      AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
		|			THEN DocumentData.ReceivingBusinessUnit
		|		ELSE DocumentData.BusinessUnitManagementAccounting
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN DocumentData.BusinessUnitAndLineOfBusinessMatchAccountingDataBookkeeping
		|			THEN TTAccountingFA.LineOfBusiness
		|		ELSE DocumentData.LineOfBusinessManagementAccounting
		|	END AS LineOfBusinessBookkeeping
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTExtendedFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|			
		|		LEFT JOIN TTAccountingFA AS TTAccountingFA
		|		ON TTAccountingFA.Ref = FATable.Ref
		|			AND TTAccountingFA.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS TueAccountingProcedureForOSBU
		|		ON TueAccountingProcedureForOSBU.Ref = FATable.Ref
		|
		|		INNER JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND NOT DocumentData.ReturnFromFinarenda
		|	AND DocumentData.DepreciationAccrualMan IN (
		|		VALUE(Enum.DepreciationAccrualChangeOptions.Valid),
		|		VALUE(Enum.DepreciationAccrualChangeOptions.Stopped))
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref                  AS Recorder,
		|	DocumentData.Period                  AS Period,
		|	DocumentData.Organization             AS Organization,
		|	TueAccountingProcedureForOSBU.FixedAsset     AS FixedAsset,
		|
		|	TueAccountingProcedureForOSBU.BUState          AS BUState,
		|
		|	TRUE AS DepreciationAccrualAccounting,
		|
		|	TueAccountingProcedureForOSBU.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
		|	TueAccountingProcedureForOSBU.ExpenseItemAccounting          AS ExpenseItemAccounting,
		|	TueAccountingProcedureForOSBU.ExpensesDimensionAccounting       AS ExpensesDimensionAccounting,
		|	DocumentData.ReceivingBusinessUnit      AS DepartmentACC,
		|	TueAccountingProcedureForOSBU.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS TueAccountingProcedureForOSBU
		|		ON TueAccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND TueAccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA AS TTInitialInformationFA
		|		ON TTInitialInformationFA.Ref = FATable.Ref
		|			AND TTInitialInformationFA.FixedAsset = FATable.FixedAsset
		|WHERE
		|	DocumentData.ReturnFromFinarenda
		|	AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentData.Ref                  AS Recorder,
		|	DocumentData.Period                  AS Period,
		|	DocumentData.Organization             AS Organization,
		|	TueAccountingProcedureForOSBU.FixedAsset     AS FixedAsset,
		|
		|	CASE WHEN TueAccountingProcedureForOSBU.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
		|		THEN VALUE(Enum.FixedAssetsStates.TakenOffBooks)
		|		ELSE TueAccountingProcedureForOSBU.BUState
		|	END                                   AS BUState,
		|
		|	FALSE AS DepreciationAccrualAccounting,
		|
		|	TueAccountingProcedureForOSBU.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
		|	TueAccountingProcedureForOSBU.ExpenseItemAccounting          AS ExpenseItemAccounting,
		|	TueAccountingProcedureForOSBU.ExpensesDimensionAccounting       AS ExpensesDimensionAccounting,
		|	TueAccountingProcedureForOSBU.DepartmentACC           AS DepartmentACC,
		|	TueAccountingProcedureForOSBU.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS TueAccountingProcedureForOSBU
		|		ON TueAccountingProcedureForOSBU.Ref = FATable.Ref
		|			AND TueAccountingProcedureForOSBU.FixedAsset = FATable.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA AS TTInitialInformationFA
		|		ON TTInitialInformationFA.Ref = FATable.Ref
		|			AND TTInitialInformationFA.FixedAsset = FATable.FixedAsset
		|WHERE
		|	DocumentData.ReturnFromFinarenda
		|	AND FATable.FixedAssetsAccountingProcedure IN (
		|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.TakeIntoAccountAsRentalInvestment),
		|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.ToExpenseAs),
		|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.WriteOffToAssetItem))
		|
		|";

	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers)

	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTOperatingTimeOfObjectsOfOperation(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	DocumentData.Organization  AS Organization,
	|	DocumentData.Period       AS LastChangeDate,
	|	FATable.FixedAsset   AS FixedAsset,
	|
	|	InvestmentInRent.RentalPaymentsLocal AS CostUsedToCalculateDepreciationManag,
	|	0 AS CostForDepreciationCalculationTargetFinancing,
	|	ISNULL(FACost.CostPermanentDifference, 0) AS PermanentDifferencesUsedToCalculateDepreciation,
	|
	|	OSBUDepreciationParameters.UsefulLifeMonthsAC         AS UsefulLifeMonthsAC,
	|	OSBUDepreciationParameters.UsefulLifeMonthsTA         AS UsefulLifeMonthsTA,
	|	OSBUDepreciationParameters.AnnualDepreciationRate             AS AnnualDepreciationRate,
	|	OSBUDepreciationParameters.AccelerationFactor                 AS AccelerationFactor,
	|	OSBUDepreciationParameters.DepreciationSchedule                    AS DepreciationSchedule,
	|	OSBUDepreciationParameters.SpecialFactor               AS SpecialFactor,
	|	0                                                             AS ResidualValueMan,
	|
	// VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|	OSBUDepreciationParameters.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|		- ISNULL(AssetActivityRecords.Value, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// UsefulLifeForCalculatingDepreciationMonth
	|	OSBUDepreciationParameters.UsefulLifeForCalculatingDepreciationMonth
	|		- DATEDIFF(ISNULL(OSBUDepreciationParameters.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH) AS UsefulLifeForCalculatingDepreciationMonth
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN WDepreciationParametersOfOSBU AS OSBUDepreciationParameters
	|		ON (OSBUDepreciationParameters.FixedAsset = FATable.FixedAsset)
	|
	|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
	|		ON FATable.FixedAsset = AssetActivityRecords.Asset
	|
	|		INNER JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_InvestmentInRent AS InvestmentInRent
	|		ON InvestmentInRent.Ref = FATable.Ref
	|			AND InvestmentInRent.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
	|	AND TTLeasedToFA.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOperatingTimeOfObjectsOfOperation(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref       AS Recorder,
	|	DocumentData.Period       AS Period,
	|	DocumentData.Organization  AS Organization,
	|	DocumentData.Period       AS LastChangeDate,
	|	FATable.FixedAsset   AS FixedAsset,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths           AS UsefulLifeMonths,
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor        AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod  AS DepreciationMethod,
	|	0 AS ResidualValueMan,
	|	0 AS ResidualValueLocal,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
	|		- ISNULL(AssetActivityRecords.Value, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|		- DATEDIFF(ISNULL(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH) AS UsefulLifeForCalculatingDepreciationMonth,
	|
	|	InvestmentInRent.RentalPaymentsManag AS CostUsedToCalculateDepreciationManag,
	|	InvestmentInRent.RentalPaymentsLocal AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = FATable.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
	|		ON AssetActivityRecords.Ref = FATable.Ref
	|			AND AssetActivityRecords.Asset = FATable.FixedAsset
	|
	|		INNER JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_InvestmentInRent AS InvestmentInRent
	|		ON InvestmentInRent.Ref = FATable.Ref
	|			AND InvestmentInRent.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
	|	AND TTLeasedToFA.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableAssetsLeasedOut(QueryTexts, Registers)

	RegisterName = "AssetsLeasedOut";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref      AS Recorder,
	|	DocumentData.Period      AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset  AS FixedAsset
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure	

Procedure QueryTextTableFACost(QueryTexts)

	RegisterName = "FACost";

	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	NonCurrentAssetsInternal.QueryTextTableTTLeasedToFA(QueryTexts, "TTExtendedFATable");
	
	ListOfRequests = New Array;
	
	#Region ReturnFromFinarenda
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	&BO_ReturnAssetsFromLeasee                              AS BusinessOperation,
	|	FATable.FixedAsset                         AS FixedAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.ReceivingBusinessUnit            AS Department,
	|	TTFAAccountingParameters.LineOfBusiness         AS LineOfBusiness,
	|	DocumentData.FinancialAccountingGroup             AS FinancialAccountingGroup,
	|	UNDEFINED                                       AS Leaseholder,
	|
	|	InvestmentInRent.RentalPaymentsManag
	|		+ InvestmentInRent.InterestDiscountMan
	|		+ InvestmentInRent.NonGuaranteedResidualValueManag                    AS Cost,
	|
	|	InvestmentInRent.RentalPaymentsLocal
	|		+ InvestmentInRent.InterestDiscountLocal
	|		+ InvestmentInRent.NonGuaranteedResidualValueLocal                   AS LocalCost,
	|
	|	0                                                  AS CostInTaxAccounting,
	|	0                                                  AS CostPermanentDifference,
	|
	|	InvestmentInRent.RentalPaymentsLocal
	|		+ InvestmentInRent.InterestDiscountLocal
	|		+ InvestmentInRent.NonGuaranteedResidualValueLocal                   AS CostTemporaryDifference,
	|
	|	0                                                  AS CostTargetFinancing,
	|	0                                                  AS CostTargetFinancingTA,
	|	0                                                  AS CostTargetFinancingPD,
	|	0                                                  AS CostTargetFinancingTD,
	|	0                                                  AS DepreciationAllowance,
	|	0                                                  AS PreliminaryCostMan,
	|	0                                                  AS PreliminaryCostLocal,
	|	0                                                  AS CostRevaluationReserve,
	|	0                                                  AS CostRevaluationReserveLocal,
	|	0                                                  AS CostGainMA,
	|	0                                                  AS CostGainLocal,
	|	0                                                  AS SecurityDepositValue,
	|
	|	DocumentData.Leaseholder                          AS CorCompany,
	|	DocumentData.Department                      AS DebitBusinessUnit,
	|	DocumentData.Leaseholder                          AS CorCounterparty,
	|	UNDEFINED                                       AS CorLineOfBusiness,
	|	UNDEFINED                                       AS CorFinancialAccountingGroup,
	|	UNDEFINED                                       AS CorExpenseItem,
	|	UNDEFINED                                       AS CorExpenditureDimension,
	|	NOT InvestmentInRent.AccountingObject IS NULL         AS CostCalculation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	FATable.RowID                      AS FinRecordID,
	|	&SettingUpHO_ReturningAssetsFromLessee                     AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_InvestmentInRent AS InvestmentInRent
	|		ON InvestmentInRent.Ref = FATable.Ref
	|			AND InvestmentInRent.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
	|	AND TTLeasedToFA.State = VALUE(Enum.FixedAssetsStates.LeasedOut)
	|	AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region ReturnFromLease
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	&BO_Cost                                      AS BusinessOperation,
	|	FATable.FixedAsset                         AS FixedAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.Department                      AS Department,
	|	TTFAAccountingParameters.LineOfBusiness         AS LineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	DocumentData.Leaseholder                          AS Leaseholder,
	|
	|	FACost.Cost                              AS Cost,
	|	FACost.LocalCost                          AS LocalCost,
	|	FACost.CostInTaxAccounting                            AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                            AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference                            AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing                            AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA                          AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD                          AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD                          AS CostTargetFinancingTD,
	|
	|	FACost.DepreciationAllowance                  AS DepreciationAllowance,
	|	FACost.PreliminaryCostMan               AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal           AS PreliminaryCostLocal,
	|	FACost.CostRevaluationReserve              AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal          AS CostRevaluationReserveLocal,
	|	0                                                  AS CostGainMA,
	|	0                                                  AS CostGainLocal,
	|	0                                                  AS SecurityDepositValue,
	|
	|	DocumentData.Organization                        AS CorCompany,
	|	DocumentData.ReceivingBusinessUnit            AS DebitBusinessUnit,
	|	UNDEFINED                                       AS CorCounterparty,
	|	TTFAAccountingParameters.LineOfBusiness         AS CorLineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS CorFinancialAccountingGroup,
	|	UNDEFINED                                       AS CorExpenseItem,
	|	UNDEFINED                                       AS CorExpenditureDimension,
	|	NOT FACost.AccountingObject IS NULL               AS CostCalculation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_Cost AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = FATable.Ref
	|
	|		LEFT JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	NOT ISNULL(CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType, UNDEFINED) IN (&TypesOfContractsUnderFSB25)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	&BO_Cost                                      AS BusinessOperation,
	|	FATable.FixedAsset                         AS FixedAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.ReceivingBusinessUnit            AS Department,
	|	TTFAAccountingParameters.LineOfBusiness         AS LineOfBusiness,
	|	DocumentData.FinancialAccountingGroup             AS FinancialAccountingGroup,
	|	UNDEFINED                                       AS Leaseholder,
	|
	|	FACost.Cost                              AS Cost,
	|	FACost.LocalCost                          AS LocalCost,
	|	FACost.CostInTaxAccounting                            AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                            AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference                            AS CostTemporaryDifference,
	|	FACost.CostTargetFinancing                            AS CostTargetFinancing,
	|	FACost.CostTargetFinancingTA                          AS CostTargetFinancingTA,
	|	FACost.CostTargetFinancingPD                          AS CostTargetFinancingPD,
	|	FACost.CostTargetFinancingTD                          AS CostTargetFinancingTD,
	|	FACost.DepreciationAllowance                  AS DepreciationAllowance,
	|	FACost.PreliminaryCostMan               AS PreliminaryCostMan,
	|	FACost.PreliminaryCostLocal           AS PreliminaryCostLocal,
	|	FACost.CostRevaluationReserve              AS CostRevaluationReserve,
	|	FACost.CostRevaluationReserveLocal          AS CostRevaluationReserveLocal,
	|	0                                                  AS CostGainMA,
	|	0                                                  AS CostGainLocal,
	|	0                                                  AS SecurityDepositValue,
	|
	|	DocumentData.Leaseholder                          AS CorCompany,
	|	DocumentData.Department                      AS DebitBusinessUnit,
	|	DocumentData.Leaseholder                          AS CorCounterparty,
	|	TTFAAccountingParameters.LineOfBusiness         AS CorLineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS CorFinancialAccountingGroup,
	|	UNDEFINED                                       AS CorExpenseItem,
	|	UNDEFINED                                       AS CorExpenditureDimension,
	|	NOT FACost.AccountingObject IS NULL               AS CostCalculation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	FATable.RowID                      AS FinRecordID,
	|	&SettingUpHO_Cost                             AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = FATable.Ref
	|
	|		LEFT JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	NOT ISNULL(CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType, UNDEFINED) IN (&TypesOfContractsUnderFSB25)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	&BO_Cost                                      AS BusinessOperation,
	|	FATable.FixedAsset                         AS FixedAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.Department                      AS Department,
	|	TTFAAccountingParameters.LineOfBusiness         AS LineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	DocumentData.Leaseholder                          AS Leaseholder,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	FACost.CostInTaxAccounting                            AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                            AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference                            AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingTA,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostTargetFinancingTD,
	|
	|	0 AS DepreciationAllowance,
	|	0 AS PreliminaryCostMan,
	|	0 AS PreliminaryCostLocal,
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|	0 AS SecurityDepositValue,
	|
	|	DocumentData.Organization                        AS CorCompany,
	|	DocumentData.ReceivingBusinessUnit            AS DebitBusinessUnit,
	|	UNDEFINED                                       AS CorCounterparty,
	|	TTFAAccountingParameters.LineOfBusiness         AS CorLineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS CorFinancialAccountingGroup,
	|	UNDEFINED                                       AS CorExpenseItem,
	|	UNDEFINED                                       AS CorExpenditureDimension,
	|	NOT FACost.AccountingObject IS NULL               AS CostCalculation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_Cost AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = FATable.Ref
	|
	|		LEFT JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	ISNULL(CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType, UNDEFINED) IN (&TypesOfContractsUnderFSB25)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	&BO_Cost                                      AS BusinessOperation,
	|	FATable.FixedAsset                         AS FixedAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.ReceivingBusinessUnit            AS Department,
	|	TTFAAccountingParameters.LineOfBusiness         AS LineOfBusiness,
	|	DocumentData.FinancialAccountingGroup             AS FinancialAccountingGroup,
	|	UNDEFINED                                       AS Leaseholder,
	|
	|	0 AS Cost,
	|	0 AS LocalCost,
	|	FACost.CostInTaxAccounting                            AS CostInTaxAccounting,
	|	FACost.CostPermanentDifference                            AS CostPermanentDifference,
	|	FACost.CostTemporaryDifference                            AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingTA,
	|	0 AS CostTargetFinancingPD,
	|	0 AS CostTargetFinancingTD,
	|
	|	0 AS DepreciationAllowance,
	|	0 AS PreliminaryCostMan,
	|	0 AS PreliminaryCostLocal,
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|	0 AS SecurityDepositValue,
	|
	|	DocumentData.Leaseholder                          AS CorCompany,
	|	DocumentData.Department                      AS DebitBusinessUnit,
	|	DocumentData.Leaseholder                          AS CorCounterparty,
	|	TTFAAccountingParameters.LineOfBusiness         AS CorLineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS CorFinancialAccountingGroup,
	|	UNDEFINED                                       AS CorExpenseItem,
	|	UNDEFINED                                       AS CorExpenditureDimension,
	|	NOT FACost.AccountingObject IS NULL               AS CostCalculation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	FATable.RowID                      AS FinRecordID,
	|	&SettingUpHO_Cost                             AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = FATable.Ref
	|
	|		LEFT JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	ISNULL(CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType, UNDEFINED) IN (&TypesOfContractsUnderFSB25)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region WriteOffOfCollateralCost
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	&BO_Cost                                      AS BusinessOperation,
	|	FATable.FixedAsset                         AS FixedAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.Department                      AS Department,
	|	TTFAAccountingParameters.LineOfBusiness         AS LineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	DocumentData.Leaseholder                          AS Leaseholder,
	|
	|	0                                                  AS Cost,
	|	0                                                  AS LocalCost,
	|	0                                                  AS CostInTaxAccounting,
	|	0                                                  AS CostPermanentDifference,
	|	0                                                  AS CostTemporaryDifference,
	|	0                                                  AS CostTargetFinancing,
	|	0                                                  AS CostTargetFinancingTA,
	|	0                                                  AS CostTargetFinancingPD,
	|	0                                                  AS CostTargetFinancingTD,
	|	0                                                  AS DepreciationAllowance,
	|	0                                                  AS PreliminaryCostMan,
	|	0                                                  AS PreliminaryCostLocal,
	|	0                                                  AS CostRevaluationReserve,
	|	0                                                  AS CostRevaluationReserveLocal,
	|	0                                                  AS CostGainMA,
	|	0                                                  AS CostGainLocal,
	|	FACost.SecurityDepositValue                     AS SecurityDepositValue,
	|
	|	DocumentData.Organization                        AS CorCompany,
	|	TTFAAccountingParameters.LeaseholderBusinessUnit         AS DebitBusinessUnit,
	|	UNDEFINED                                       AS CorCounterparty,
	|	TTFAAccountingParameters.LineOfBusiness         AS CorLineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS CorFinancialAccountingGroup,
	|	UNDEFINED                                       AS CorExpenseItem,
	|	UNDEFINED                                       AS CorExpenditureDimension,
	|	TRUE                                             AS CostCalculation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_Cost AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = FATable.Ref
	|WHERE
	|	FACost.SecurityDepositValue <> 0
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region MovingRevaluationReserveOfCostOfFA
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|
	|	CASE
	|		WHEN DocumentData.Organization <> DocumentData.SenderOrganization
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetRevaluationReserveToAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost) 
	|	END                                              AS BusinessOperation,
	|
	|	FATable.FixedAsset                         AS FixedAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.Department                      AS Department,
	|	TTFAAccountingParameters.LineOfBusiness         AS LineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup          AS FinancialAccountingGroup,
	|	UNDEFINED                                       AS Leaseholder,
	|
	|	0                                                  AS Cost,
	|	0                                                  AS LocalCost,
	|	0                                                  AS CostInTaxAccounting,
	|	0                                                  AS CostPermanentDifference,
	|	0                                                  AS CostTemporaryDifference,
	|	0                                                  AS CostTargetFinancing,
	|	0                                                  AS CostTargetFinancingTA,
	|	0                                                  AS CostTargetFinancingPD,
	|	0                                                  AS CostTargetFinancingTD,
	|	0                                                  AS DepreciationAllowance,
	|	0                                                  AS PreliminaryCostMan,
	|	0                                                  AS PreliminaryCostLocal,
	|	0                                                  AS CostRevaluationReserve,
	|	0                                                  AS CostRevaluationReserveLocal,
	|	FACost.CostGainMA                       AS CostGainMA,
	|	FACost.CostGainLocal                   AS CostGainLocal,
	|	0                                                  AS SecurityDepositValue,
	|
	|	UNDEFINED                                       AS CorCompany,
	|	UNDEFINED                                       AS DebitBusinessUnit,
	|	UNDEFINED                                       AS CorCounterparty,
	|	UNDEFINED                                       AS CorLineOfBusiness,
	|	UNDEFINED                                       AS CorFinancialAccountingGroup,
	|	UNDEFINED                                       AS CorExpenseItem,
	|	UNDEFINED                                       AS CorExpenditureDimension,
	|	TRUE                                             AS CostCalculation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	FATable.RowID AS FinRecordID,
	|
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = FATable.Ref
	|
	|		LEFT JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	NOT CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
	|	AND DocumentData.FinancialAccountingGroup <> TTFAAccountingParameters.FinancialAccountingGroup
	|	AND (FACost.CostGainMA <> 0 OR FACost.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)             AS RecordType,
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|
	|	CASE
	|		WHEN DocumentData.Organization <> DocumentData.SenderOrganization
	|			THEN VALUE(Enum.BusinessTransactions.TransferFixedAssetRevaluationReserveFromAnotherCompany)
	|		ELSE VALUE(Enum.BusinessTransactions.ChangeRevaluationReserveOfFixedAssetsCost) 
	|	END                                              AS BusinessOperation,
	|
	|	FATable.FixedAsset                         AS FixedAsset,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.ReceivingBusinessUnit            AS Department,
	|	TTFAAccountingParameters.LineOfBusiness         AS LineOfBusiness,
	|	DocumentData.FinancialAccountingGroup             AS FinancialAccountingGroup,
	|	UNDEFINED                                       AS Leaseholder,
	|
	|	0                                                  AS Cost,
	|	0                                                  AS LocalCost,
	|	0                                                  AS CostInTaxAccounting,
	|	0                                                  AS CostPermanentDifference,
	|	0                                                  AS CostTemporaryDifference,
	|	0                                                  AS CostTargetFinancing,
	|	0                                                  AS CostTargetFinancingTA,
	|	0                                                  AS CostTargetFinancingPD,
	|	0                                                  AS CostTargetFinancingTD,
	|	0                                                  AS DepreciationAllowance,
	|	0                                                  AS PreliminaryCostMan,
	|	0                                                  AS PreliminaryCostLocal,
	|	0                                                  AS CostRevaluationReserve,
	|	0                                                  AS CostRevaluationReserveLocal,
	|	FACost.CostGainMA                       AS CostGainMA,
	|	FACost.CostGainLocal                   AS CostGainLocal,
	|	0                                                  AS SecurityDepositValue,
	|
	|	UNDEFINED                                       AS CorCompany,
	|	UNDEFINED                                       AS DebitBusinessUnit,
	|	UNDEFINED                                       AS CorCounterparty,
	|	UNDEFINED                                       AS CorLineOfBusiness,
	|	UNDEFINED                                       AS CorFinancialAccountingGroup,
	|	UNDEFINED                                       AS CorExpenseItem,
	|	UNDEFINED                                       AS CorExpenditureDimension,
	|	TRUE                                             AS CostCalculation,
	|	DocumentData.RecordInLocalAccounting                 AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                  AS RecordInManAccounting,
	|	
	|	FATable.RowID AS FinRecordID,
	|
	|	VALUE(Catalog.BusinessTransactionsSettings.ChangeRevaluationReserveOfFixedAssetsCost) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.AccountingObject = FATable.FixedAsset
	|			AND FACost.Ref = FATable.Ref
	|
	|		LEFT JOIN TTLeasedToFA AS TTLeasedToFA
	|		ON TTLeasedToFA.Ref = FATable.Ref
	|			AND TTLeasedToFA.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	NOT CAST(TTLeasedToFA.Contract AS Catalog.CounterpartyContracts).ContractType IN (&TypesOfContractsUnderFSB25)
	|	AND DocumentData.FinancialAccountingGroup <> TTFAAccountingParameters.FinancialAccountingGroup
	|	AND (FACost.CostGainMA <> 0 OR FACost.CostGainLocal <> 0)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);

EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	&BO_Depreciation                           AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|	FATable.FixedAsset                AS FixedAsset,
	|	DocumentData.Department             AS Department,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	FixedAssetsDepreciationCharge.Depreciation                 AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal             AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD               AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|	DocumentData.Organization               AS CorCompany,
	|	DocumentData.ReceivingBusinessUnit   AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	DocumentData.FinancialAccountingGroup    AS CorFinancialAccountingGroup,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation              AS AccrueDepreciation,
	|	
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_Depreciation AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)    AS RecordType,
	|	DocumentData.Ref                    AS Recorder,
	|	DocumentData.Period                    AS Period,
	|	&BO_Depreciation                           AS BusinessOperation,
	|	DocumentData.Organization               AS Organization,
	|	FATable.FixedAsset                AS FixedAsset,
	|	DocumentData.ReceivingBusinessUnit   AS Department,
	|	DocumentData.FinancialAccountingGroup    AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	FixedAssetsDepreciationCharge.Depreciation                 AS Depreciation,
	|	FixedAssetsDepreciationCharge.DepreciationLocal             AS DepreciationLocal,
	|	FixedAssetsDepreciationCharge.DepreciationInTaxAccounting               AS DepreciationInTaxAccounting,
	|	FixedAssetsDepreciationCharge.DepreciationPermanentDifferences               AS DepreciationPermanentDifferences,
	|	FixedAssetsDepreciationCharge.DepreciationTD               AS DepreciationTD,
	|	FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing               AS FixedAssetDepreciationTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing             AS DepreciationTaxAccountingTargetFinancing,
	|	FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD             AS DepreciationTargetFinancingPD,
	|	FixedAssetsDepreciationCharge.DepreciationOfTargetFinancingTD             AS DepreciationOfTargetFinancingTD,
	|	FixedAssetsDepreciationCharge.DepreciationRevaluationReserve AS DepreciationRevaluationReserve,
	|	DocumentData.Organization               AS CorCompany,
	|	DocumentData.Department             AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation              AS AccrueDepreciation,
	|	
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_Depreciation AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|			AND FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts, "TTExtendedFATable");
	
	QueryText =
	"// Moving depreciation
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	&BO_Depreciation                   AS BusinessOperation,
	|	DocumentData.SenderOrganization AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.ReceivingBusinessUnit AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization       AS CorCompany,
	|
	|	FixedAssetsDepreciationCharge.Depreciation         AS Sum,
	|	FixedAssetsDepreciationCharge.Depreciation         AS SumMan,
	|	FixedAssetsDepreciationCharge.DepreciationLocal + FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing AS SumCompl
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|UNION ALL
	|
	|// Moving the cost
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	&BO_Cost                     AS BusinessOperation,
	|	DocumentData.SenderOrganization AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.ReceivingBusinessUnit AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization       AS CorCompany,
	|
	|	FACost.Cost             AS Sum,
	|	FACost.Cost             AS SumMan,
	|	FACost.LocalCost + FACost.CostTargetFinancing AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTExtendedFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableScheduleOfPaymentsForIncomeRentalServices(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfPaymentsForIncomeRentalServices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATableAccordingToFSB25(QueryTexts);
	
	QueryText =
	"SELECT
	|	FATable.Ref AS EffectiveContractTerms,
	|	FATable.Period AS Period,
	|	FATable.Contract AS Contract,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.Period AS Date,
	|	FATable.Period AS ChangeDate,
	|	0 AS RentalService,
	|	0 AS RentalServiceVAT
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableScheduleOfChargesForIncomeRentalServices(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfChargesForIncomeRentalServices";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATableAccordingToFSB25(QueryTexts);
	
	QueryText =
	"SELECT
	|	FATable.Ref AS EffectiveContractTerms,
	|	FATable.Period AS Period,
	|	FATable.Contract AS Contract,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.Period AS Date,
	|	FATable.Period AS ChangeDate,
	|	0 AS RentalService,
	|	0 AS RentalServiceVAT
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableScheduleOfInterestChargesOnIncomeRental(QueryTexts, Registers)
	
	RegisterName = "ScheduleOfInterestChargesOnIncomeRental";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATableAccordingToFSB25(QueryTexts);
	
	QueryText =
	"SELECT
	|	ScheduleOfInterestChargesOnIncomeRental.ChangeDate AS ChangeDate,
	|	ScheduleOfInterestChargesOnIncomeRental.Interests AS Interests,
	|	ScheduleOfInterestChargesOnIncomeRental.Date AS Date,
	|	ScheduleOfInterestChargesOnIncomeRental.FixedAsset AS FixedAsset,
	|	ScheduleOfInterestChargesOnIncomeRental.Contract AS Contract
	|INTO TTInterestAccrualScheduleIsGeneral
	|FROM
	|	InformationRegister.ScheduleOfInterestChargesOnIncomeRental AS ScheduleOfInterestChargesOnIncomeRental
	|WHERE
	|	(ScheduleOfInterestChargesOnIncomeRental.Contract, ScheduleOfInterestChargesOnIncomeRental.FixedAsset) IN
	|			(SELECT
	|				FATable.Contract,
	|				FATable.FixedAsset
	|			FROM
	|				TTFATableAccordingToFSB25 AS FATable)
	|	AND ScheduleOfInterestChargesOnIncomeRental.Active
	|
	|INDEX BY
	|	Contract,
	|	FixedAsset,
	|	ChangeDate,
	|	Date
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FATable.Ref AS Ref,
	|	FATable.Period AS Period,
	|	FATable.Contract AS Contract,
	|	FATable.FixedAsset AS FixedAsset,
	|	InterestAccrualSchedule.ChangeDate AS ChangeDate,
	|	InterestAccrualSchedule.Interests AS Interests,
	|	InterestAccrualSchedule.Date AS Date
	|INTO TTInterestSchedule
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|		INNER JOIN TTInterestAccrualScheduleIsGeneral AS InterestAccrualSchedule
	|		ON (InterestAccrualSchedule.Contract = FATable.Contract)
	|			AND (InterestAccrualSchedule.FixedAsset = FATable.FixedAsset)
	|			AND (InterestAccrualSchedule.ChangeDate < FATable.Period)
	|			AND (InterestAccrualSchedule.Date <= ENDOFPERIOD(FATable.Period, MONTH))
	|			AND (InterestAccrualSchedule.Date >= BEGINOFPERIOD(FATable.Period, MONTH))
	|			AND (InterestAccrualSchedule.Interests > 0)
	|
	|INDEX BY
	|	Contract,
	|	FixedAsset,
	|	ChangeDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InterestAccrualSchedule.Ref AS Ref,
	|	InterestAccrualSchedule.FixedAsset AS FixedAsset,
	|	MAX(InterestAccrualSchedule.ChangeDate) AS ChangeDate
	|INTO TTInterestAccrualSchedulePeriods
	|FROM
	|	TTInterestSchedule AS InterestAccrualSchedule
	|
	|GROUP BY
	|	InterestAccrualSchedule.Ref,
	|	InterestAccrualSchedule.FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	InterestAccrualSchedule.Ref AS EffectiveContractTerms,
	|	InterestAccrualSchedule.Period AS Period,
	|	InterestAccrualSchedule.Contract AS Contract,
	|	InterestAccrualSchedule.FixedAsset AS FixedAsset,
	|	InterestAccrualSchedule.Date AS Date,
	|	InterestAccrualSchedule.Interests AS Interests,
	|	InterestAccrualSchedule.Period AS ChangeDate
	|FROM
	|	TTInterestSchedule AS InterestAccrualSchedule
	|		INNER JOIN TTInterestAccrualSchedulePeriods AS InterestAccrualSchedulePeriods
	|		ON InterestAccrualSchedule.Ref = InterestAccrualSchedulePeriods.Ref
	|			AND (InterestAccrualSchedulePeriods.FixedAsset = InterestAccrualSchedule.FixedAsset)
	|			AND (InterestAccrualSchedulePeriods.ChangeDate = InterestAccrualSchedule.ChangeDate)
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref,
	|	FATable.Period,
	|	FATable.Contract,
	|	FATable.FixedAsset,
	|	DATEADD(BEGINOFPERIOD(FATable.Period, MONTH), MONTH, 1),
	|	0,
	|	FATable.Period
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInvestmentInRent(Query, QueryTexts, Registers)
	
	RegisterName = "InvestmentInRent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTFATableAccordingToFSB25(QueryTexts);
	DeferredFARecordGeneration.QueryTextEmptyDeferredMovementTables(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region RecoveryOfRentalInterest // Dr <58.%> - Cr <58.AP>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	FATable.Ref                                AS Recorder,
	|	FATable.Period                                AS Period,
	|	FATable.Organization                           AS Organization,
	|	InvestmentsBalance.Contract                       AS Contract,
	|	InvestmentsBalance.AccountingObject                   AS FixedAsset,
	|	InvestmentsBalance.Currency                        AS Currency,
	|	InvestmentsBalance.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	0                                               AS RentalPayments,
	|	0                                               AS RentalPaymentsLocal,
	|	0                                               AS RentalPaymentsManag,
	|	0                                               AS NonGuaranteedResidualValueLocal,
	|	0                                               AS NonGuaranteedResidualValueManag,
	|	-InvestmentsBalance.InterestDiscount            AS InterestDiscount,
	|	-InvestmentsBalance.InterestDiscountLocal        AS InterestDiscountLocal,
	|	-InvestmentsBalance.InterestDiscountMan         AS InterestDiscountMan,
	|	&SettingUpHO_EarlyRentalTermination AS BusinessTransactionSetting,
	|	FATable.RowID                   AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.InterestDiscount <> 0
	|		OR InvestmentsBalance.InterestDiscountLocal <> 0
	|		OR InvestmentsBalance.InterestDiscountMan <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	FATable.Ref                                AS Recorder,
	|	FATable.Period                                AS Period,
	|	FATable.Organization                           AS Organization,
	|	InvestmentsBalance.Contract                       AS Contract,
	|	InvestmentsBalance.AccountingObject                   AS FixedAsset,
	|	InvestmentsBalance.Currency                        AS Currency,
	|	InvestmentsBalance.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	-InvestmentsBalance.InterestDiscount            AS RentalPayments,
	|	-InvestmentsBalance.InterestDiscountLocal        AS RentalPaymentsLocal,
	|	-InvestmentsBalance.InterestDiscountMan         AS RentalPaymentsManag,
	|	0                                               AS NonGuaranteedResidualValueLocal,
	|	0                                               AS NonGuaranteedResidualValueManag,
	|	0                                               AS InterestDiscount,
	|	0                                               AS InterestDiscountLocal,
	|	0                                               AS InterestDiscountMan,
	|	&SettingUpHO_EarlyRentalTermination AS BusinessTransactionSetting,
	|	FATable.RowID                   AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.InterestDiscount <> 0
	|		OR InvestmentsBalance.InterestDiscountLocal <> 0
	|		OR InvestmentsBalance.InterestDiscountMan <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region InclusionOfNGLSVCostOfInvestmentInLease // Dr <58.AP> - Cr <58.NGLS>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	FATable.Ref                                AS Recorder,
	|	FATable.Period                                AS Period,
	|	FATable.Organization                           AS Organization,
	|	InvestmentsBalance.Contract                       AS Contract,
	|	InvestmentsBalance.AccountingObject                   AS FixedAsset,
	|	InvestmentsBalance.Currency                        AS Currency,
	|	InvestmentsBalance.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	0                                               AS RentalPayments,
	|	InvestmentsBalance.NonGuaranteedResidualValueLocal                      AS RentalPaymentsLocal,
	|	InvestmentsBalance.NonGuaranteedResidualValueManag                       AS RentalPaymentsManag,
	|	0                                               AS NonGuaranteedResidualValueLocal,
	|	0                                               AS NonGuaranteedResidualValueManag,
	|	0                                               AS InterestDiscount,
	|	0                                               AS InterestDiscountMan,
	|	0                                               AS InterestDiscountLocal,
	|	&SettingUpHO_EnablingNGLSVCostOfCHIA         AS BusinessTransactionSetting,
	|	FATable.RowID                   AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	FATable.Ref                                AS Recorder,
	|	FATable.Period                                AS Period,
	|	FATable.Organization                           AS Organization,
	|	InvestmentsBalance.Contract                       AS Contract,
	|	InvestmentsBalance.AccountingObject                   AS FixedAsset,
	|	InvestmentsBalance.Currency                        AS Currency,
	|	InvestmentsBalance.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	0                                               AS RentalPayments,
	|	0                                               AS RentalPaymentsLocal,
	|	0                                               AS RentalPaymentsManag,
	|	InvestmentsBalance.NonGuaranteedResidualValueLocal                      AS NonGuaranteedResidualValueLocal,
	|	InvestmentsBalance.NonGuaranteedResidualValueManag                       AS NonGuaranteedResidualValueManag,
	|	0                                               AS InterestDiscount,
	|	0                                               AS InterestDiscountLocal,
	|	0                                               AS InterestDiscountMan,
	|	&SettingUpHO_EnablingNGLSVCostOfCHIA         AS BusinessTransactionSetting,
	|	FATable.RowID                   AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region AssetReturnedFromLeaseHasBeenAcceptedForAccounting  // Dr <01.01> - Cr <58.AP>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	FATable.Ref                                AS Recorder,
	|	FATable.Period                                AS Period,
	|	FATable.Organization                           AS Organization,
	|	InvestmentsBalance.Contract                       AS Contract,
	|	InvestmentsBalance.AccountingObject                   AS FixedAsset,
	|	InvestmentsBalance.Currency                        AS Currency,
	|	InvestmentsBalance.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	InvestmentsBalance.RentalPayments
	|		+ InvestmentsBalance.InterestDiscount       AS RentalPayments,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal                AS RentalPaymentsLocal,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag                 AS RentalPaymentsManag,
	|	0                                               AS NonGuaranteedResidualValueLocal,
	|	0                                               AS NonGuaranteedResidualValueManag,
	|	0                                               AS InterestDiscount,
	|	0                                               AS InterestDiscountLocal,
	|	0                                               AS InterestDiscountMan,
	|	&SettingUpHO_ReturningAssetsFromLessee                  AS BusinessTransactionSetting,
	|	FATable.RowID                   AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.IncludeInFixedAssets)
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.RentalPaymentsLocal + InvestmentsBalance.InterestDiscountLocal + InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.RentalPaymentsManag + InvestmentsBalance.InterestDiscountMan + InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region ReturnAsPartOfRentalInvestments // Dr <58.VA> - Cr <58.AP>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	FATable.Ref                                AS Recorder,
	|	FATable.Period                                AS Period,
	|	FATable.Organization                           AS Organization,
	|	InvestmentsBalance.Contract                       AS Contract,
	|	InvestmentsBalance.AccountingObject                   AS FixedAsset,
	|	InvestmentsBalance.Currency                        AS Currency,
	|	InvestmentsBalance.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	InvestmentsBalance.RentalPayments
	|		+ InvestmentsBalance.InterestDiscount       AS RentalPayments,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal                AS RentalPaymentsLocal,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag                 AS RentalPaymentsManag,
	|	0                                               AS NonGuaranteedResidualValueLocal,
	|	0                                               AS NonGuaranteedResidualValueManag,
	|	0                                               AS InterestDiscount,
	|	0                                               AS InterestDiscountLocal,
	|	0                                               AS InterestDiscountMan,
	|	&SettingUpHO_ReturningAssetsFromLessee                  AS BusinessTransactionSetting,
	|	FATable.RowID                   AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.TakeIntoAccountAsRentalInvestment)
	|		AND (InvestmentsBalance.RentalPaymentsLocal + InvestmentsBalance.InterestDiscountLocal + InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.RentalPaymentsManag + InvestmentsBalance.InterestDiscountMan + InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region WriteOffOfObjectAsExpense // Dr <91.02> - Cr <58.AP>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	FATable.Ref                                AS Recorder,
	|	FATable.Period                                AS Period,
	|	FATable.Organization                           AS Organization,
	|	InvestmentsBalance.Contract                       AS Contract,
	|	InvestmentsBalance.AccountingObject                   AS FixedAsset,
	|	InvestmentsBalance.Currency                        AS Currency,
	|	InvestmentsBalance.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	InvestmentsBalance.RentalPayments
	|		+ InvestmentsBalance.InterestDiscount       AS RentalPayments,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal                AS RentalPaymentsLocal,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag                 AS RentalPaymentsManag,
	|	0                                               AS NonGuaranteedResidualValueLocal,
	|	0                                               AS NonGuaranteedResidualValueManag,
	|	0                                               AS InterestDiscount,
	|	0                                               AS InterestDiscountLocal,
	|	0                                               AS InterestDiscountMan,
	|	&SettingUpHO_ReturningAssetsFromLessee                  AS BusinessTransactionSetting,
	|	FATable.RowID                   AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.ToExpenseAs)
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.RentalPaymentsLocal + InvestmentsBalance.InterestDiscountLocal + InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.RentalPaymentsManag + InvestmentsBalance.InterestDiscountMan + InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region WriteOffToAPArticle // Dr <XXX> - Cr <58.AP>
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	FATable.Ref                                AS Recorder,
	|	FATable.Period                                AS Period,
	|	FATable.Organization                           AS Organization,
	|	InvestmentsBalance.Contract                       AS Contract,
	|	InvestmentsBalance.AccountingObject                   AS FixedAsset,
	|	InvestmentsBalance.Currency                        AS Currency,
	|	InvestmentsBalance.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	InvestmentsBalance.RentalPayments
	|		+ InvestmentsBalance.InterestDiscount       AS RentalPayments,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal                AS RentalPaymentsLocal,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag                 AS RentalPaymentsManag,
	|	0                                               AS NonGuaranteedResidualValueLocal,
	|	0                                               AS NonGuaranteedResidualValueManag,
	|	0                                               AS InterestDiscount,
	|	0                                               AS InterestDiscountLocal,
	|	0                                               AS InterestDiscountMan,
	|	&SettingUpHO_ReturningAssetsFromLessee                  AS BusinessTransactionSetting,
	|	FATable.RowID                   AS FinRecordID
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.WriteOffToAssetItem)
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.RentalPaymentsLocal + InvestmentsBalance.InterestDiscountLocal + InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.RentalPaymentsManag + InvestmentsBalance.InterestDiscountMan + InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherAssetsAndLiabilitiesRecords(Query, QueryTexts, Registers)
	
	RegisterName = "OtherAssetsAndLiabilitiesRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	// Write-off to the item of assets/liabilities Dr <XXX> - Cr <58.AP>
	QueryText =
	"SELECT
	|	FATable.Ref                       AS Recorder,
	|	FATable.Period                       AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	FATable.Organization                  AS Organization,
	|	FATable.Department                AS Department,
	|	FATable.LineOfBusiness      AS LineOfBusiness,
	|	FATable.ExpenseItem               AS AssetRef,
	|	FATable.AssetsLiabilitiesDimension     AS Dimension,
	|	FATable.GLAccountSettings         AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit) AS DebitCredit,
	|
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal       AS SumCompl,
	|	0                                      AS PermanentDifference,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal       AS CostTD,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag        AS SumMan,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag        AS AmountIncludingVAT,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag        AS AmountExcludingVAT,
	|
	|	FATable.RowID          AS FinRecordID,
	|	&SettingUpHO_ReturningAssetsFromLessee         AS BusinessTransactionSetting
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.WriteOffToAssetItem)
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.RentalPaymentsLocal + InvestmentsBalance.InterestDiscountLocal + InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.RentalPaymentsManag + InvestmentsBalance.InterestDiscountMan + InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Add_Fields = "Recorder";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTExtendedFATable(QueryTexts);
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(
		QueryTexts, "TTExtendedFATable", "TTInitialInformationFA_SubjectToCorrections", True);
		
	QueryText = ReturnAssetsFromLeaseeLocalization.QueryTextTableInitialFixedAssetsInformation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref AS Recorder,
		|	DocumentData.Period AS Period,
		|	DATETIME(1,1,1) AS CorrectionDate,
		|
		|	DocumentData.Organization AS Organization,
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA AS InitialCostMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentAC AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|
		|	CASE WHEN InitialFixedAssetsInformation.AccountingProcedureAC <> VALUE(Enum.FARepaymentProcedure.EmptyRef) THEN
		|		DocumentData.Ref
		|	ELSE InitialFixedAssetsInformation.DeregistrationDocumentACC END AS DeregistrationDocumentACC,
		|	CASE WHEN InitialFixedAssetsInformation.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.EmptyRef) THEN
		|		DocumentData.Ref
		|	ELSE InitialFixedAssetsInformation.DeregistrationDocumentMA END AS DeregistrationDocumentMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|		INNER JOIN DocumentDataFATable AS FATable
		|			ON FATable.Ref = DocumentData.Ref
		|
		|		INNER JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
		|			AND FATable.FixedAsset = InitialFixedAssetsInformation.FixedAsset
		|
		|WHERE
		|	DocumentData.ReturnFromFinarenda
		|	AND FATable.FixedAssetsAccountingProcedure IN (
		|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.TakeIntoAccountAsRentalInvestment),
		|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.ToExpenseAs),
		|		VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.WriteOffToAssetItem))
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTFATableAccordingToFSB25(QueryTexts)
	
	TableName = "TTFATableAccordingToFSB25";

	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.ReceivingBusinessUnit AS Department,
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.FixedAssetsAccountingProcedure AS FixedAssetsAccountingProcedure,
	|	FATable.ExpenseItem AS ExpenseItem,
	|	FATable.DimensionOfExpenses AS DimensionOfExpenses,
	|	FATable.AssetsLiabilitiesDimension AS AssetsLiabilitiesDimension,
	|	FATable.GLAccountSettings AS GLAccountSettings,
	|	FATable.RowID AS RowID,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Contract.LineOfBusiness AS LineOfBusiness
	|INTO TTFATableAccordingToFSB25
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|WHERE
	|	DocumentData.ReturnFromFinarenda
	|
	|INDEX BY
	|	Ref,
	|	Contract,
	|	FixedAsset,
	|	Period";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTOtherExpenses_(Query, QueryTexts, Add_Fields)
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_(Add_Fields, True);
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableTTInitialOtherExpenses(QueryTexts, Add_Fields)
	
	RegisterName = "TTInitialOtherExpenses";
	
	QueryTextTableTTFATableAccordingToFSB25(QueryTexts);
	
	ListOfMergeRequests = New Array;
	ListOfMergeRequests.Add(AccumulationRegisters.OtherExpenses.TextDescriptionTTInitialOtherExpenses(Add_Fields));
	
	#Region ReturnAsPartOfRentalInvestments // Dr <58.VA> - Cr <58.AP>
	QueryText =
	"SELECT
	|	FATable.Period                        AS Period,
	|	VALUE(AccumulationRecordType.Receipt)  AS RecordType,
	|	
	|	FATable.Organization                   AS Organization,
	|	FATable.Department                 AS Department,
	|	FATable.ExpenseItem                AS ExpenseItem,
	|	FATable.FixedAsset              AS DimensionOfExpenses,
	|	FATable.LineOfBusiness       AS LineOfBusiness,
	|	UNDEFINED                            AS VATActivityType,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag         AS AmountIncludingVAT,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag         AS AmountExcludingVAT,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag         AS AmountExcludingVATMan,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal        AS AmountIncludingVATCompl,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal        AS AmountExcludingVATCompl,
	|
	|	0                                       AS PermanentDifference,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal        AS CostTD,
	|	
	|	&BO_ReturnAssetsFromLeasee                   AS BusinessOperation,
	|	UNDEFINED                            AS ItemsLocationAttributes,
	|
	|	FATable.RowID           AS FinRecordID,
	|	&SettingUpHO_ReturningAssetsFromLessee          AS BusinessTransactionSetting,
	|	FATable.Ref                        AS Recorder
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.TakeIntoAccountAsRentalInvestment)
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.RentalPaymentsLocal + InvestmentsBalance.InterestDiscountLocal + InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.RentalPaymentsManag + InvestmentsBalance.InterestDiscountMan + InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)";

	ListOfMergeRequests.Add(QueryText);
	#EndRegion

	#Region WriteOffOfObjectAsExpense // Dr <91.02> - Cr <58.AP>
	QueryText =
	"SELECT
	|	FATable.Period                       AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	
	|	FATable.Organization                   AS Organization,
	|	FATable.Department                 AS Department,
	|	FATable.ExpenseItem                AS ExpenseItem,
	|	FATable.FixedAsset              AS DimensionOfExpenses,
	|	FATable.LineOfBusiness       AS LineOfBusiness,
	|	UNDEFINED                            AS VATActivityType,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag         AS AmountIncludingVAT,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag         AS AmountExcludingVAT,
	|	InvestmentsBalance.RentalPaymentsManag
	|		+ InvestmentsBalance.InterestDiscountMan
	|		+ InvestmentsBalance.NonGuaranteedResidualValueManag         AS AmountExcludingVATMan,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal        AS AmountIncludingVATCompl,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal        AS AmountExcludingVATCompl,
	|
	|	0                                       AS PermanentDifference,
	|	InvestmentsBalance.RentalPaymentsLocal
	|		+ InvestmentsBalance.InterestDiscountLocal
	|		+ InvestmentsBalance.NonGuaranteedResidualValueLocal        AS CostTD,
	|	
	|	&BO_ReturnAssetsFromLeasee                   AS BusinessOperation,
	|	UNDEFINED                            AS ItemsLocationAttributes,
	|
	|	FATable.RowID           AS FinRecordID,
	|	&SettingUpHO_ReturningAssetsFromLessee          AS BusinessTransactionSetting,
	|	FATable.Ref                        AS Recorder
	|FROM
	|	TTFATableAccordingToFSB25 AS FATable
	|	INNER JOIN TT_InvestmentInRent AS InvestmentsBalance
	|		ON FATable.FixedAsset = InvestmentsBalance.AccountingObject
	|		AND FATable.Contract = InvestmentsBalance.Contract
	|		AND FATable.FixedAssetsAccountingProcedure = VALUE(Enum.OptionsForFAAccountingWhenReturningFromLessee.ToExpenseAs)
	|		AND InvestmentsBalance.Ref = FATable.Ref
	|		AND (InvestmentsBalance.RentalPaymentsLocal + InvestmentsBalance.InterestDiscountLocal + InvestmentsBalance.NonGuaranteedResidualValueLocal <> 0
	|		OR InvestmentsBalance.RentalPaymentsManag + InvestmentsBalance.InterestDiscountMan + InvestmentsBalance.NonGuaranteedResidualValueManag <> 0)";
	
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting_

Function RequestTextTTReflectedInLocalAccounting() Export

	Return ReturnAssetsFromLeaseeLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return ReturnAssetsFromLeaseeLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

Function GetDataForPrintedFormOS1(PrintParameters, ObjectsArray) Export
	
	Return ReturnAssetsFromLeaseeLocalization.GetDataForPrintedFormOS1(PrintParameters, ObjectsArray);
		
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
	
	//ItemOfFAExpenses
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();

	ChoiceParameters.DataPath = "Object.FA";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ArticleType = "ItemTypeExpenses";

	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.SelectingItemOfAssetsLiabilities = True;
	ChoiceParameters.AssetsLiabilitiesDimension = "AssetsLiabilitiesDimension";

	ChoiceParameters.FormItems.AssetRef.Add("FAExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("FADimensionOfExpenses");
	ChoiceParameters.FormItems.AssetsLiabilitiesDimension.Add("FAAssetsLiabilitiesDimension");
	
	ArraySelectionFAAccountingProcedure = New Array;
	ArraySelectionFAAccountingProcedure.Add(Enums.OptionsForFAAccountingWhenReturningFromLessee.TakeIntoAccountAsRentalInvestment);
	ArraySelectionFAAccountingProcedure.Add(Enums.OptionsForFAAccountingWhenReturningFromLessee.ToExpenseAs);
	ArraySelectionFAAccountingProcedure.Add(Enums.OptionsForFAAccountingWhenReturningFromLessee.WriteOffToAssetItem);
	
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("FixedAssetsAccountingProcedure", ArraySelectionFAAccountingProcedure);

	ArticleSelectionAndAnalyticsOptions.Add(ChoiceParameters);
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

// Returns parameters for setting up accounting accounts in the document.
// Returns:
//  See GLAccountSettingsServer.SetupParameters.
//
Function AccountingAccountSettings_() Export
	
	SetupParameters = GLAccountSettingsServer.SetupParameters();
	
	SetupParameters.AvailabilityByOperation = True;
	SetupParameters.DataPath = "Object.FA";
	SetupParameters.ArticleType = "ItemTypeExpenses";
	
	// Form elements that are used for customization.
	SetupParameters.FormItems.Add("FATransactionRecordingPresentation");
	
	Return SetupParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
