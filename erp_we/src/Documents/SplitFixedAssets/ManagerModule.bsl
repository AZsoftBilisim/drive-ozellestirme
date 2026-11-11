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
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("ImpairmentFA");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	
	SplitFixedAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.SplitFixedAssets") Then
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
		
		QueryTextTableTTIsListOfAllFA(QueryTexts);
		NonCurrentAssetsInternal.QueryTextTableTTFAList(QueryTexts, "TTIsListOfAllFA");
		
		QueryTextTableFACost(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(Query, QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers);
		QueryTextTableFALocation(Query, QueryTexts, Registers);
		QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers);
		QueryTextTableCGUComposition(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		SplitFixedAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers);

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
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters();
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
	QueryTexts = New ValueList;
	
	QueryTextTableTTIsListOfAllFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTFAList(QueryTexts, "TTIsListOfAllFA");

	QueryTextTableFACost(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Undefined);
	QueryTextTableImpairmentFA(Query, QueryTexts, Undefined);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	
	QueryTextTableFixedAssetsAccountingProcedure(Query, QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Undefined);
	QueryTextTableFALocation(Query, QueryTexts, Undefined);
	QueryTextTableCGUComposition(Query, QueryTexts, Undefined);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	SplitFixedAssetsLocalization.TablesOfDeferredMotionFormation(Query, QueryTexts);

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
	
	Documents.ChangeFixedAssetFinancialDetails2_4.AddGenerateCommand(GenerationCommands);
	Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);
	
	Command = AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ListForm";
	EndIf;
	
	SplitFixedAssetsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds the command to create the document "OS Disassembly".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.SplitFixedAssets) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.SplitFixedAssets.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.SplitFixedAssets);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_4";
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	SplitFixedAssetsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	SplitFixedAssetsLocalization.AddPrintCommands(PrintCommands);

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

// Auxiliary details.
// 
// Parameters:
//  Object - FormDataStructure -
// 
// Returns:
//  FixedStructure - 
Function AuxiliaryAttributes(Object) Export

	DateOfParameters = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("Organization", Object.Organization);
	AuxiliaryAttributes.Insert("BusinessOperation", Object.BusinessOperation);
	AuxiliaryAttributes.Insert("Date", Object.Date);
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Object.Date));

	CurrencyOfMan  = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, DateOfParameters));
		
	AuxiliaryAttributes.Insert(
		"FSB6IsApplied",
		AccountingPoliciesTaxSettingsCached.FSB6IsApplied(Object.Organization, DateOfParameters));

	SplitFixedAssetsLocalization.AddAuxiliaryDetails(Object, AuxiliaryAttributes);
	
	AuxiliaryAttributes = New FixedStructure(AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;
	
EndFunction

Function FillInDetailsDependingOnProperties(Object, AuxiliaryAttributes, ItemDetailsParameters) Export

	ChangedBankingDetails = New Array;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If AttributeParameters.Property = "Visible" And AttributeParameters.Value = False
			Or AttributeParameters.Property = "ReadOnly" And AttributeParameters.Value = True Then
			Action = "Clear";
		ElsIf AttributeParameters.Property = "Visible" And AttributeParameters.Value = True Then
			Action = "Fill";
		Else
			Continue;
		EndIf;
		
		If AttributeParameters.AttributeName = "DepreciationAccrualMethodManagementAccounting" Then
			
			AttributeValue = Enums.AccrualMethodOfFixedAssetsDepreciation.Linear;
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				Object,
				AttributeParameters.AttributeName,
				Action,
				AttributeValue,
				Undefined,
				ChangedBankingDetails);

		ElsIf AttributeParameters.AttributeName = "UsefulLifeManagementAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				Object,
				AttributeParameters.AttributeName,
				Action,
				Object.UsefulLifeAccounting,
				0,
				ChangedBankingDetails);

		ElsIf AttributeParameters.AttributeName = "AccelerationFactorManagementAccounting" Then
		
			NonCurrentAssetsInternal.FillClearBankingDetails(
				Object,
				AttributeParameters.AttributeName,
				Action,
				1,
				0,
				ChangedBankingDetails);
				
		ElsIf AttributeParameters.AttributeName = "DepreciationMethodAccounting" Then
			
			AttributeValue = Enums.AccrualMethodOfFixedAssetsDepreciation.Linear;
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				Object,
				AttributeParameters.AttributeName, 
				Action, 
				AttributeValue,
				Undefined,
				ChangedBankingDetails);
	
		ElsIf AttributeParameters.AttributeName = "UsefulLifeAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				Object,
				AttributeParameters.AttributeName, 
				Action, 
				Object.UsefulLifeManagementAccounting,
				0,
				ChangedBankingDetails);
	
		ElsIf AttributeParameters.AttributeName = "AccelerationFactorAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				Object,
				AttributeParameters.AttributeName, 
				Action, 
				1,
				0,
				ChangedBankingDetails);
	
		EndIf;
		
	EndDo; 
	
	Return StrConcat(ChangedBankingDetails, ",");
	
EndFunction

Procedure FillInDefaultValues(RowData, Object) Export
	
	If Object.BusinessOperation = Enums.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation Then
		
		If Not ValueIsFilled(RowData.FinancialAccountingGroup) Then
			RowData.FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(
													Enums.KindsOfNonCurrentAssets.FixedAsset);
		EndIf;
		
	EndIf; 
	
EndProcedure

Function CheckSelectionOfFixedAssets(FixedAsset, ListOfFA, Date) Export

	ParametersForSelectingFixedAssets = New Structure;
	ParametersForSelectingFixedAssets.Insert("ProblematicFA", New Array);
	ParametersForSelectingFixedAssets.Insert("ParameterValues", New Structure);
	
	QueryText = SplitFixedAssetsLocalization.RequestTextForFAVerification();
	
	If QueryText <> Undefined Then
	
		Query = New Query(QueryText);
		Query.SetParameter("ListOfFA", ListOfFA);
		Query.SetParameter("FixedAsset", FixedAsset);
		Query.SetParameter("Date", Date);
		
		Result = Query.ExecuteBatch();
		
		FASelection_1 = Result[0].Select();
		FASelection_1.Select();
		FASelection_1.Next();
		
		Selection = Result[1].Select();
		While Selection.Next() Do
			ParametersForSelectingFixedAssets.ProblematicFA.Add(Selection.Ref);
		EndDo;
		
		SplitFixedAssetsLocalization.UpdateFACheckResult(Selection, FASelection_1, ParametersForSelectingFixedAssets);
		
	EndIf;
	
	Return ParametersForSelectingFixedAssets;

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
	
	FullDocumentName = "Document.SplitFixedAssets";
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
	|	Document.SplitFixedAssets AS DocumentsList
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
	SplitFixedAssetsLocalization.GetDocumentData(ListOfRequests);
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref               AS Ref,
	|	DocumentData.Date                 AS Period,
	|	DocumentData.Number                AS Number,
	|	DocumentData.Organization          AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.Department        AS Department,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.FixedAsset     AS FixedAsset,
	|	DocumentData.ExpenseItemAccounting     AS ExpenseItemAccounting,
	|	DocumentData.ExpensesDimensionAccounting  AS ExpensesDimensionAccounting,
	|	DocumentData.ExpenseItemManagementAccounting     AS ExpenseItemManagementAccounting,
	|	DocumentData.ExpensesDimensionManagementAccounting  AS ExpensesDimensionManagementAccounting,
	|	DocumentData.FixedAssetsEvent            AS FixedAssetsEvent,
	|	DocumentData.EmployeeResponsible        AS EmployeeResponsible,
	|	DocumentData.Comment          AS Comment,
	|	DocumentData.Posted             AS Posted,
	|	DocumentData.DeletionMark      AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting   AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting    AS RecordInManAccounting,
	|	DocumentData.WriteOffNodes          AS WriteOffNodes,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
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
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|
	|	DocumentTable.CostInManagementAccounting AS CostInManagementAccounting,
	|	DocumentTable.CostInAccounting AS CostInAccounting,
	|	DocumentTable.CostInTaxAccounting AS CostInTaxAccounting,
	|	DocumentTable.CostPermanentDifference AS CostPermanentDifference,
	|	DocumentTable.CostTemporaryDifference AS CostTemporaryDifference,
	|
	|	DocumentTable.ResidualValueMan AS ResidualValueMan,
	|	DocumentTable.ResidualValueLocal AS ResidualValueLocal,
	|
	|	DocumentTable.AnnualDepreciationRateAccounting AS AnnualDepreciationRateAccounting,
	|	DocumentTable.DepreciationSchedule AS DepreciationSchedule,
	|	DocumentTable.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentTable.AccelerationFactorAccounting AS AccelerationFactorAccounting,
	|	DocumentTable.AccelerationFactorManagementAccounting AS AccelerationFactorManagementAccounting,
	|	DocumentTable.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	DocumentTable.DepreciationAccrualMethodManagementAccounting AS DepreciationAccrualMethodManagementAccounting,
	|	DocumentTable.UsefulLifeAccounting AS UsefulLifeAccounting,
	|	DocumentTable.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
	|	DocumentTable.RunningTimeValue AS RunningTimeValue,
	|	DocumentTable.EstimatedRunningTime AS EstimatedRunningTime
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.SplitFixedAssets.FA AS DocumentTable
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.SplitFixedAssets"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'TSCĐ ngừng hoạt động';
															|ru = 'Разукомплектация ОС';
															|en = 'Split fixed assets'; fa = 'تفکیک دارایی‌های ثابت';
															|it = 'smantellamento Capitale fisso';
															|pl = 'Zdekompletowanie ST';
															|tr = 'SV''lerin bölünmesi'"));
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
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
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	DocumentData.Department           AS Department,
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
	|	Document.SplitFixedAssets AS DocumentData
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
	|	0                                       AS RecNo,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting      AS RecordInTA,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	DocumentData.FixedAsset        AS FixedAsset
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	CASE
	|		WHEN DocumentData.FixedAsset <> VALUE(Catalog.Assets.EmptyRef)
	|			THEN FATable.LineNumber
	|		ELSE ISNULL(FATable.LineNumber-1, 0)    
	|	END                                   AS RecNo,
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department,
	|	DocumentData.BusinessOperation   AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting      AS RecordInTA,
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	FATable.FixedAsset              AS FixedAsset
	|
	|FROM
	|	Document.SplitFixedAssets AS DocumentData
	|
	|		LEFT JOIN Document.SplitFixedAssets.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND (DocumentData.FixedAsset = VALUE(Catalog.Assets.EmptyRef)
	|			OR NOT FATable.Ref IS NULL)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFACost(Query, QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	ImpairmentFAServer.QueryTextEmptyTableDepreciationIn(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "TTIsListOfAllFA");
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTIsListOfAllFA");
	NonCurrentAssetsInternal.QueryTextTableTTVATTaxation(QueryTexts, "TTIsListOfAllFA");
	

	QueryTextTableTTCoefficients(QueryTexts);
	QueryTextTableTTFATableGrouped(QueryTexts);
	QueryTextTableTTAllocationOfCost(QueryTexts);
	
	MergeRequestTexts = New Array;
	
	#Region Recognition
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.Department                AS Department,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup
	|	END                                        AS FinancialAccountingGroup,
	|
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS LineOfBusiness,
	|	FALocation.Leaseholder                  AS Leaseholder,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	FATable.FixedAsset                   AS FixedAsset,
	|	TTVATTaxation.VATTaxation      AS VATTaxation,
	|
	|	DocumentData.Department                               AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS CorLineOfBusiness,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS CorFinancialAccountingGroup,
	|	NOT TT_CostOfVNA.AccountingObject IS NULL     AS CostCalculation,
	|	FATable.CostInManagementAccounting                        AS PreliminaryCostMan,
	|	FATable.CostInAccounting                        AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostInManagementAccounting
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit)
	|				AND DocumentData.RecordInLocalAccounting
	|			THEN FATable.CostInAccounting - CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|				AND DocumentData.RecordInLocalAccounting
	|			THEN FATable.CostInAccounting - &CostTargetFinancing
	|
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|				AND DocumentData.RecordInLocalAccounting
	|			THEN FATable.CostInAccounting
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInTaxAccounting
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostPermanentDifference
	|					- CASE 
	|						WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit)
	|							THEN CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|
	|						WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|							THEN &CostTargetFinancing
	|						ELSE 0
	|					END
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN CASE 
	|					WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit)
	|						THEN FATable.CostInAccounting - CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|
	|					WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|						THEN FATable.CostInAccounting
	|
	|					WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|						THEN FATable.CostInAccounting - &CostTargetFinancing
	|					ELSE 0
	|				END 
	|					- FATable.CostInTaxAccounting 
	|					- (FATable.CostPermanentDifference
	|						- CASE 
	|							WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit)
	|								THEN CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|
	|							WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|								THEN &CostTargetFinancing
	|							ELSE 0
	|						END)
	|		ELSE 0
	|	END AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit)
	|				AND DocumentData.RecordInLocalAccounting 
	|			THEN CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|				AND DocumentData.RecordInLocalAccounting 
	|			THEN &CostTargetFinancing
	|		ELSE 0
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit)
	|				AND DocumentData.RecordInLocalAccounting 
	|			THEN CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|				AND DocumentData.RecordInLocalAccounting 
	|			THEN &CostTargetFinancing
	|		ELSE 0
	|	END AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.CostRevaluationReserve
	|					* CASE WHEN ISNULL(TT_CostOfVNA.Cost, 0) = 0
	|						THEN 1
	|						ELSE FATable.CostInManagementAccounting / ISNULL(TT_CostOfVNA.Cost, 0)
	|					END
	|		ELSE 0
	|	END AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostRevaluationReserveLocal
	|					* CASE WHEN (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0)) = 0
	|						THEN 1
	|						ELSE FATable.CostInAccounting / (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0))
	|					END
	|		ELSE 0
	|	END AS CostRevaluationReserveLocal,
	|
	|
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|	
	|	FATable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SelectFixedAssetsCostUponSplitting) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = DocumentData.Ref
	|			AND TT_CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = DocumentData.Ref
	|			AND FALocation.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = DocumentData.Ref
	|			AND TTVATTaxation.FixedAsset = DocumentData.FixedAsset
	|
	|		INNER JOIN TTCoefficients AS TTCoefficients
	|		ON TTCoefficients.Ref = DocumentData.Ref
	|			AND TTCoefficients.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = DocumentData.Ref
	|
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ReductionOfCostOfOriginalFAWithPartialDisassembly
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.Department                AS Department,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS LineOfBusiness,
	|	FALocation.Leaseholder                  AS Leaseholder,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	DocumentData.FixedAsset             AS FixedAsset,
	|	TTVATTaxation.VATTaxation      AS VATTaxation,
	|
	|	DocumentData.Department                AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS CorLineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|
	|	NOT TT_CostOfVNA.AccountingObject IS NULL     AS CostCalculation,
	|	0                                            AS PreliminaryCostMan,
	|	0                                            AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostInManagementAccounting
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInAccounting - CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInTaxAccounting
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostPermanentDifference - CAST(FATable.CostPermanentDifference * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInAccounting - CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|					- FATable.CostInTaxAccounting
	|					- (FATable.CostPermanentDifference - CAST(FATable.CostPermanentDifference * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2)))
	|		ELSE 0
	|	END AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|		ELSE 0
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN CAST(FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0) AS NUMBER(31,2))
	|		ELSE 0
	|	END AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.CostRevaluationReserve
	|					* CASE WHEN ISNULL(TT_CostOfVNA.Cost, 0) = 0
	|						THEN 1
	|						ELSE FATable.CostInManagementAccounting / ISNULL(TT_CostOfVNA.Cost, 0)
	|					END
	|		ELSE 0
	|	END AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostRevaluationReserveLocal
	|					* CASE WHEN (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0)) = 0
	|						THEN 1
	|						ELSE FATable.CostInAccounting / (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0))
	|					END
	|		ELSE 0
	|	END AS CostRevaluationReserveLocal,
	|
	
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|	
	|	FATable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SelectFixedAssetsCostUponSplitting) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = DocumentData.Ref
	|			AND TT_CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = DocumentData.Ref
	|			AND FALocation.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = DocumentData.Ref
	|			AND TTVATTaxation.FixedAsset = DocumentData.FixedAsset
	|
	|
	|WHERE
	|	DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit), 
	|		VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ReducingCostOfOriginalFAWithCompleteDisassembly
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.Department                AS Department,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS LineOfBusiness,
	|	FALocation.Leaseholder                  AS Leaseholder,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	DocumentData.FixedAsset             AS FixedAsset,
	|	TTVATTaxation.VATTaxation      AS VATTaxation,
	|
	|	DocumentData.Department                AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS CorLineOfBusiness,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS CorFinancialAccountingGroup,
	|	TRUE                                       AS CostCalculation,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfCost.PreliminaryCostMan
	|		ELSE 0
	|	END                                        AS PreliminaryCostMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.PreliminaryCostLocal
	|		ELSE 0
	|	END                                        AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfCost.Cost
	|		ELSE 0
	|	END                                        AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.LocalCost
	|		ELSE 0
	|	END                                        AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.CostInTaxAccounting
	|		ELSE 0
	|	END                                        AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.CostPermanentDifference
	|		ELSE 0
	|	END                                        AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.LocalCost
	|		ELSE 0
	|	END
	|	 -CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.CostInTaxAccounting
	|		ELSE 0
	|		END
	|	 -CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.CostPermanentDifference
	|		ELSE 0
	|	 END                                       AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.CostTargetFinancing
	|		ELSE 0
	|	END                                        AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.CostTargetFinancingPD
	|		ELSE 0
	|	END                                        AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfCost.CostRevaluationReserve
	|		ELSE 0
	|	END                                        AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfCost.CostRevaluationReserveLocal
	|		ELSE 0
	|	END                                        AS CostRevaluationReserveLocal,
	|
	|	0                                            AS CostGainMA,
	|	0                                            AS CostGainLocal,
	|	
	|	AllocationOfCost.RowID       AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SelectFixedAssetsCostUponSplitting) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTAllocationOfCost AS AllocationOfCost
	|		ON AllocationOfCost.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = DocumentData.Ref
	|			AND FALocation.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = DocumentData.Ref
	|			AND TTVATTaxation.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.Department                AS Department,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS LineOfBusiness,
	|	FALocation.Leaseholder                  AS Leaseholder,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	DocumentData.FixedAsset             AS FixedAsset,
	|	TTVATTaxation.VATTaxation      AS VATTaxation,
	|
	|	DocumentData.Department                AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS CorLineOfBusiness,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS CorFinancialAccountingGroup,
	|	FALSE                                         AS CostCalculation,
	|	0                                            AS PreliminaryCostMan,
	|	0                                            AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostInManagementAccounting
	|		ELSE 0
	|	END                                        AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInAccounting
	|		ELSE 0
	|	END                                        AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInTaxAccounting
	|		ELSE 0
	|	END                                        AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostPermanentDifference
	|		ELSE 0
	|	END                                        AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostTemporaryDifference
	|		ELSE 0
	|	END                                        AS CostTemporaryDifference,
	|	0                                            AS CostTargetFinancing,
	|	0                                            AS CostTargetFinancingPD,
	|	0                                            AS CostRevaluationReserve,
	|	0                                            AS CostRevaluationReserveLocal,
	|	0                                            AS CostGainMA,
	|	0                                            AS CostGainLocal,
	|	
	|	FATable.RowID                AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SelectFixedAssetsCostUponSplitting) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = DocumentData.Ref
	|			AND TT_CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = DocumentData.Ref
	|			AND FALocation.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = DocumentData.Ref
	|			AND TTVATTaxation.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND TT_CostOfVNA.Ref IS NULL
	|
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region CostGainMA
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.Department                AS Department,
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup
	|	END                                        AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS LineOfBusiness,
	|	UNDEFINED                                 AS Leaseholder,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	FATable.FixedAsset                   AS FixedAsset,
	|	UNDEFINED                                 AS VATTaxation,
	|
	|	UNDEFINED                                 AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS CorLineOfBusiness,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS CorFinancialAccountingGroup,
	|	NOT TT_CostOfVNA.AccountingObject IS NULL     AS CostCalculation,
	|
	|	0                                            AS PreliminaryCostMan,
	|	0                                            AS PreliminaryCostLocal,
	|	0                                            AS Cost,
	|	0                                            AS LocalCost,
	|	0                                            AS CostInTaxAccounting,
	|	0                                            AS CostPermanentDifference,
	|	0                                            AS CostTemporaryDifference,
	|	0                                            AS CostTargetFinancing,
	|	0                                            AS CostTargetFinancingPD,
	|	0                                            AS CostRevaluationReserve,
	|	0                                            AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.CostGainMA
	|					* CASE WHEN ISNULL(TT_CostOfVNA.Cost, 0) = 0
	|						THEN 1
	|						ELSE FATable.CostInManagementAccounting / ISNULL(TT_CostOfVNA.Cost, 0)
	|					END
	|		ELSE 0
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostGainLocal
	|					* CASE WHEN (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0)) = 0
	|						THEN 1
	|						ELSE FATable.CostInAccounting / (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0))
	|					END
	|		ELSE 0
	|	END AS CostGainLocal,
	|	
	|	FATable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SelectFixedAssetsCostUponSplitting) AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = DocumentData.Ref
	|			AND TT_CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = DocumentData.Ref
	|			AND FALocation.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND TT_CostOfVNA.CostGainMA <> 0
	|		OR DocumentData.RecordInLocalAccounting AND TT_CostOfVNA.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.Department                AS Department,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS LineOfBusiness,
	|	UNDEFINED                                 AS Leaseholder,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	DocumentData.FixedAsset             AS FixedAsset,
	|	UNDEFINED                                 AS VATTaxation,
	|
	|	DocumentData.Department                AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS CorLineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,

	|	NOT TT_CostOfVNA.AccountingObject IS NULL     AS CostCalculation,
	|
	|	0                                            AS PreliminaryCostMan,
	|	0                                            AS PreliminaryCostLocal,
	|	0                                            AS Cost,
	|	0                                            AS LocalCost,
	|	0                                            AS CostInTaxAccounting,
	|	0                                            AS CostPermanentDifference,
	|	0                                            AS CostTemporaryDifference,
	|	0                                            AS CostTargetFinancing,
	|	0                                            AS CostTargetFinancingPD,
	|	0                                            AS CostRevaluationReserve,
	|	0                                            AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.CostGainMA
	|					* CASE WHEN ISNULL(TT_CostOfVNA.Cost, 0) = 0
	|						THEN 1
	|						ELSE FATable.CostInManagementAccounting / ISNULL(TT_CostOfVNA.Cost, 0)
	|					END
	|		ELSE 0
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostGainLocal
	|					* CASE WHEN (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0)) = 0
	|						THEN 1
	|						ELSE FATable.CostInAccounting / (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0))
	|					END
	|		ELSE 0
	|	END AS CostGainLocal,
	|	
	|	FATable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SelectFixedAssetsCostUponSplitting) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = DocumentData.Ref
	|			AND TT_CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = DocumentData.Ref
	|			AND FALocation.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND TT_CostOfVNA.CostGainMA <> 0
	|		OR DocumentData.RecordInLocalAccounting AND TT_CostOfVNA.CostGainLocal <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region WriteOffOfNodesComponentOfDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	FALocation.FixedAssetsLocation            AS Department,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS LineOfBusiness,
	|	FALocation.Leaseholder                  AS Leaseholder,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	TTUnitsDepreciationComponents.SubAssetComponent    AS FixedAsset,
	|	TTVATTaxation.VATTaxation      AS VATTaxation,
	|
	|	DocumentData.Department                AS DebitBusinessUnit,
	|	AccountingProcedureForOwnerSFA.LineOfBusiness AS CorLineOfBusiness,
	|	AccountingProcedureForOwnerSFA.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|	TRUE                                       AS CostCalculation,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.PreliminaryCostMan
	|		ELSE 0
	|	END                                        AS PreliminaryCostMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.PreliminaryCostLocal
	|		ELSE 0
	|	END                                        AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.Cost
	|		ELSE 0
	|	END                                        AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.LocalCost
	|		ELSE 0
	|	END                                        AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostInTaxAccounting
	|		ELSE 0
	|	END                                        AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostPermanentDifference
	|		ELSE 0
	|	END                                        AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.LocalCost
	|		ELSE 0
	|	END
	|	 -CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostInTaxAccounting
	|		ELSE 0
	|		END
	|	 -CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostPermanentDifference
	|		ELSE 0
	|	 END                                       AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostTargetFinancing
	|		ELSE 0
	|	END                                        AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostTargetFinancingPD
	|		ELSE 0
	|	END                                        AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.CostRevaluationReserve
	|		ELSE 0
	|	END                                        AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostRevaluationReserveLocal
	|		ELSE 0
	|	END                                        AS CostRevaluationReserveLocal,
	|
	|	0                                            AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                            AS CostGainMA,
	|	0                                            AS CostGainLocal,
	|	
	|	TTUnitsDepreciationComponents.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SplitSubAssetsComponentsOfDepreciation) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = TTUnitsDepreciationComponents.Ref
	|			AND TT_CostOfVNA.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = TTUnitsDepreciationComponents.Ref
	|			AND FALocation.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = TTUnitsDepreciationComponents.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS AccountingProcedureForOwnerSFA
	|		ON AccountingProcedureForOwnerSFA.Ref = DocumentData.Ref
	|			AND AccountingProcedureForOwnerSFA.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = TTUnitsDepreciationComponents.Ref
	|			AND TTVATTaxation.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.Department                AS Department,
	|	AccountingProcedureForOwnerSFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	AccountingProcedureForOwnerSFA.LineOfBusiness AS LineOfBusiness,
	|	LocationOfOwnerSFA.Leaseholder         AS Leaseholder,
	|	DocumentData.BusinessOperation        AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting,
	|	DocumentData.FixedAsset             AS FixedAsset,
	|	TTVATTaxation.VATTaxation      AS VATTaxation,
	|
	|	FALocation.FixedAssetsLocation            AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness       AS CorLineOfBusiness,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup        AS CorFinancialAccountingGroup,
	|	TRUE                                       AS CostCalculation,
	|
	|	0                                            AS PreliminaryCostMan,
	|	0                                            AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.Cost
	|		ELSE 0
	|	END                                        AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.LocalCost
	|		ELSE 0
	|	END                                        AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostInTaxAccounting
	|		ELSE 0
	|	END                                        AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostPermanentDifference
	|		ELSE 0
	|	END                                        AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.LocalCost
	|		ELSE 0
	|	END
	|	 -CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostInTaxAccounting
	|		ELSE 0
	|		END
	|	 -CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostPermanentDifference
	|		ELSE 0
	|	 END                                       AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostTargetFinancing
	|		ELSE 0
	|	END                                        AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostTargetFinancingPD
	|		ELSE 0
	|	END                                        AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_CostOfVNA.CostRevaluationReserve
	|		ELSE 0
	|	END                                        AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.CostRevaluationReserveLocal
	|		ELSE 0
	|	END                                        AS CostRevaluationReserveLocal,
	|
	|	0                                            AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                            AS CostGainMA,
	|	0                                            AS CostGainLocal,
	|	
	|	TTUnitsDepreciationComponents.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SplitSubAssetsComponentsOfDepreciation) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = TTUnitsDepreciationComponents.Ref
	|			AND TT_CostOfVNA.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTLocationOfFA AS FALocation
	|		ON FALocation.Ref = TTUnitsDepreciationComponents.Ref
	|			AND FALocation.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTLocationOfFA AS LocationOfOwnerSFA
	|		ON LocationOfOwnerSFA.Ref = DocumentData.Ref
	|			AND LocationOfOwnerSFA.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = TTUnitsDepreciationComponents.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS AccountingProcedureForOwnerSFA
	|		ON AccountingProcedureForOwnerSFA.Ref = DocumentData.Ref
	|			AND AccountingProcedureForOwnerSFA.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = DocumentData.Ref
	|			AND TTVATTaxation.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostTargetFinancing, 0)", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&CostTargetFinancing", AmountDistributionText);
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	QueryTextTableTTAllocationOfDepreciation(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTIsListOfAllFA");
	
	MergeRequestTexts = New Array;
	
	#Region IncreaseInDepreciationOfNewFA
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	AllocationOfDepreciation.FixedAsset           AS FixedAsset,
	|	AllocationOfDepreciation.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	AllocationOfDepreciation.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|	AllocationOfDepreciation.LineOfBusiness    AS LineOfBusiness,
	|	AllocationOfDepreciation.AccrueDepreciation             AS AccrueDepreciation,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfDepreciation.Depreciation
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationTD
	|		ELSE 0
	|	END AS DepreciationTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationTaxAccountingTargetFinancing
	|		ELSE 0
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationTargetFinancingPD
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationOfTargetFinancingTD
	|		ELSE 0
	|	END AS DepreciationOfTargetFinancingTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfDepreciation.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS DepreciationRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	AllocationOfDepreciation.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SelectFixedAssetDepreciationChargeUponSplitting) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTAllocationOfDepreciation AS AllocationOfDepreciation
	|		ON AllocationOfDepreciation.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ReductionOfDepreciationOfOriginalFA
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.FixedAsset                AS FixedAsset,
	|	AllocationOfDepreciation.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	AllocationOfDepreciation.FinancialAccountingGroup     AS CorFinancialAccountingGroup,
	|	AllocationOfDepreciation.LineOfBusiness    AS LineOfBusiness,
	|	AllocationOfDepreciation.AccrueDepreciation             AS AccrueDepreciation,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfDepreciation.Depreciation
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationTD
	|		ELSE 0
	|	END AS DepreciationTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationTaxAccountingTargetFinancing
	|		ELSE 0
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationTargetFinancingPD
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationOfTargetFinancingTD
	|		ELSE 0
	|	END AS DepreciationOfTargetFinancingTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfDepreciation.DepreciationRevaluationReserve
	|		ELSE 0
	|	END AS DepreciationRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfDepreciation.DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	AllocationOfDepreciation.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SelectFixedAssetDepreciationChargeUponSplitting) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTAllocationOfDepreciation AS AllocationOfDepreciation
	|		ON AllocationOfDepreciation.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region WriteOffOfNodesComponentOfDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	TTUnitsDepreciationComponents.SubAssetComponent       AS FixedAsset,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	AccountingProcedureForOwnerSFA.FinancialAccountingGroup  AS CorFinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness          AS LineOfBusiness,
	|	FALSE                                            AS AccrueDepreciation,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_DepreciationOfVNA.Depreciation
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_DepreciationOfVNA.DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_DepreciationOfVNA.DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_DepreciationOfVNA.DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_DepreciationOfVNA.DepreciationTD
	|		ELSE 0
	|	END AS DepreciationTD,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTaxAccountingTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|	0 AS DepreciationOfTargetFinancingTD,
	|
	|	0 AS DepreciationRevaluationReserve,
	|	0 AS DepreciationRevaluationReserveLocal,
	|
	|	TTUnitsDepreciationComponents.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SplitSubAssetsComponentsOfDepreciation) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|		ON TT_DepreciationOfVNA.Ref = TTUnitsDepreciationComponents.Ref
	|			AND TT_DepreciationOfVNA.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = TTUnitsDepreciationComponents.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS AccountingProcedureForOwnerSFA
	|		ON AccountingProcedureForOwnerSFA.Ref = DocumentData.Ref
	|			AND AccountingProcedureForOwnerSFA.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.FixedAsset                AS FixedAsset,
	|	AccountingProcedureForOwnerSFA.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup           AS CorFinancialAccountingGroup,
	|	AccountingProcedureForOwnerSFA.LineOfBusiness AS LineOfBusiness,
	|	FALSE                                            AS AccrueDepreciation,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_DepreciationOfVNA.Depreciation
	|		ELSE 0
	|	END AS Depreciation,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_DepreciationOfVNA.DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_DepreciationOfVNA.DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_DepreciationOfVNA.DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_DepreciationOfVNA.DepreciationTD
	|		ELSE 0
	|	END AS DepreciationTD,
	|
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTaxAccountingTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|	0 AS DepreciationOfTargetFinancingTD,
	|
	|	0 AS DepreciationRevaluationReserve,
	|	0 AS DepreciationRevaluationReserveLocal,
	|
	|	TTUnitsDepreciationComponents.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.SplitSubAssetsComponentsOfDepreciation) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|		ON TT_DepreciationOfVNA.Ref = TTUnitsDepreciationComponents.Ref
	|			AND TT_DepreciationOfVNA.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = TTUnitsDepreciationComponents.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS AccountingProcedureForOwnerSFA
	|		ON AccountingProcedureForOwnerSFA.Ref = DocumentData.Ref
	|			AND AccountingProcedureForOwnerSFA.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableImpairmentFA(Query, QueryTexts, Registers)

	RegisterName = "ImpairmentFA";
	
	QueryTextTableTTAllocationOfImpairment(QueryTexts);
	
	MergeRequestTexts = New Array;
	
	#Region IncreaseInImpairmentOfNewFA
	QueryText =
	"SELECT 
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	FATable.FixedAsset                      AS NonCurrentAsset,
	|	AllocationOfImpairment.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	AllocationOfImpairment.LineOfBusiness    AS LineOfBusiness,
	|	AllocationOfImpairment.CGU                       AS CGU,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfImpairment.ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfImpairment.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfImpairment.LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfImpairment.LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|
	|	FATable.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfFA) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAllocationOfImpairment AS AllocationOfImpairment
	|		ON AllocationOfImpairment.Ref = FATable.Ref
	|			AND AllocationOfImpairment.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|	AND (AllocationOfImpairment.ImpairmenMan <> 0 
	|		OR AllocationOfImpairment.ImpairmentLocalAssets <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region ReductionOfImpairmentOfInitialFA
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.FixedAsset                AS NonCurrentAsset,
	|	AllocationOfImpairment.FinancialAccountingGroup     AS FinancialAccountingGroup,
	|	AllocationOfImpairment.LineOfBusiness    AS LineOfBusiness,
	|	AllocationOfImpairment.CGU                       AS CGU,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfImpairment.ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfImpairment.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN AllocationOfImpairment.LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN AllocationOfImpairment.LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|
	|	AllocationOfImpairment.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfFA) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTAllocationOfImpairment AS AllocationOfImpairment
	|		ON AllocationOfImpairment.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|	AND (AllocationOfImpairment.ImpairmenMan <> 0 
	|		OR AllocationOfImpairment.ImpairmentLocalAssets <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion
	
	#Region WriteOffOfNodesComponentOfDepreciation
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	TTUnitsDepreciationComponents.SubAssetComponent       AS NonCurrentAsset,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness          AS LineOfBusiness,
	|	TT_ImpairmentFA.CGU                          AS CGU,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_ImpairmentFA.ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_ImpairmentFA.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_ImpairmentFA.LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_ImpairmentFA.LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|
	|	TTUnitsDepreciationComponents.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfFA) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = TTUnitsDepreciationComponents.Ref
	|			AND TT_ImpairmentFA.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = TTUnitsDepreciationComponents.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|	AND (TT_ImpairmentFA.ImpairmenMan <> 0 
	|		OR TT_ImpairmentFA.ImpairmentLocalAssets <> 0)
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)          AS RecordType,
	|	DocumentData.Ref                          AS Recorder,
	|	DocumentData.Period                          AS Period,
	|	DocumentData.Organization                     AS Organization,
	|	DocumentData.Department                   AS Department,
	|	DocumentData.BusinessOperation           AS BusinessOperation,
	|	DocumentData.FixedAsset                AS NonCurrentAsset,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness          AS LineOfBusiness,
	|	TT_ImpairmentFA.CGU                          AS CGU,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_ImpairmentFA.ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_ImpairmentFA.ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN TT_ImpairmentFA.LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_ImpairmentFA.LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|
	|	TTUnitsDepreciationComponents.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.ReclassificationOfFA) AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = TTUnitsDepreciationComponents.Ref
	|			AND TT_ImpairmentFA.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|	AND (TT_ImpairmentFA.ImpairmenMan <> 0 
	|		OR TT_ImpairmentFA.ImpairmentLocalAssets <> 0)
	|";
	MergeRequestTexts.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(MergeRequestTexts, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTAllocationOfDepreciation(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTIsListOfAllFA");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	VALUE(Enum.BusinessTransactions.SelectFixedAssetDepreciationChargeUponSplitting) AS BusinessOperation,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	FixedAssetsDepreciationCharge.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.FinancialAccountingGroup
	|		ELSE FixedAssetsDepreciationCharge.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	FixedAssetsDepreciationCharge.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	DocumentData.FixedAsset  AS CorDimensionOfAssetsLiabilities,
	|	FixedAssetsDepreciationCharge.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FixedAssetsDepreciationCharge.Depreciation
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FixedAssetsDepreciationCharge.Depreciation
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FixedAssetsDepreciationCharge.DepreciationLocal + FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing
	|		ELSE 0
	|	END AS SumCompl
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAllocationOfDepreciation AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.FixedAsset = FATable.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	VALUE(Enum.BusinessTransactions.SelectFixedAssetsCostUponSplitting) AS BusinessOperation,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	DocumentData.FixedAsset  AS AssetsLiabilitiesDimension,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	FixedAssetsAccountingProcedure.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup
	|	END AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostInManagementAccounting
	|		ELSE 0
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN FATable.CostInManagementAccounting
	|		ELSE 0
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInAccounting
	|		ELSE 0
	|	END AS SumCompl
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = FATable.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTIsListOfAllFA");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	FATable.FixedAsset              AS FixedAsset,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.FinancialAccountingGroup
	|		ELSE FixedAssetsAccountingProcedure.FinancialAccountingGroup
	|	END AS FinancialAccountingGroup,
	|
	|	FixedAssetsAccountingProcedure.LineOfBusiness  AS LineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.RunningTimeValue
	|		ELSE FixedAssetsAccountingProcedure.RunningTimeValue
	|	END AS RunningTimeValue,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|			THEN FATable.EstimatedRunningTime
	|		ELSE FixedAssetsAccountingProcedure.EstimatedRunningTime
	|	END AS EstimatedRunningTime
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(Query, QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts, "TTIsListOfAllFA");
	
	ListOfRequests = New Array;
	
	#Region New_FA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	FATable.FixedAsset                             AS FixedAsset,
	|	AccountingProcedureForOSBU.BUState                           AS BUState,
	|	AccountingProcedureForOSBU.StateTa                           AS StateTa,
	|	AccountingProcedureForOSBU.DepreciationAccrualAccounting                AS DepreciationAccrualAccounting,
	|	AccountingProcedureForOSBU.DepreciationAccrualTaxAccounting                AS DepreciationAccrualTaxAccounting,
	|	AccountingProcedureForOSBU.ExpenseRecordMethodAC             AS ExpenseRecordMethodAC,
	|	AccountingProcedureForOSBU.ExpenseItemAccounting                      AS ExpenseItemAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionAccounting                   AS ExpensesDimensionAccounting,
	|	AccountingProcedureForOSBU.DepartmentACC                       AS DepartmentACC,
	|	AccountingProcedureForOSBU.LineOfBusinessBookkeeping             AS LineOfBusinessBookkeeping,
	|	AccountingProcedureForOSBU.ExpenseRecordMethodTA             AS ExpenseRecordMethodTA,
	|	AccountingProcedureForOSBU.ExpenseItemTaxAccounting                      AS ExpenseItemTaxAccounting,
	|	AccountingProcedureForOSBU.ExpensesDimensionTaxAccounting                   AS ExpensesDimensionTaxAccounting,
	|	AccountingProcedureForOSBU.BusinessUnitTaxAccounting                       AS BusinessUnitTaxAccounting,
	|	AccountingProcedureForOSBU.LineOfBusinessTaxAccounting             AS LineOfBusinessTaxAccounting,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany   AS TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses         AS CompanyRecipientOfExpenses,
	|	AccountingProcedureForOSBU.DepreciationGroup                 AS DepreciationGroup,
	|	AccountingProcedureForOSBU.RealEstate                   AS RealEstate,
	|	AccountingProcedureForOSBU.VATTaxation                    AS VATTaxation,
	|	AccountingProcedureForOSBU.InvestmentTaxDeduction          AS InvestmentTaxDeduction
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = DocumentData.Ref
	|			AND AccountingProcedureForOSBU.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region SplitSubAssetsComponentsOfDepreciation
	QueryText = 
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	FATable.FixedAsset                             AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_)       AS BUState,
	|	VALUE(Enum.FixedAssetsStates.NotRecognized_)     AS StateTa,
	|	AccountingProcedureForOSBU.DepreciationAccrualAccounting                AS DepreciationAccrualAccounting,
	|	FALSE                                                   AS DepreciationAccrualTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN AccountingProcedureForOSBU.ExpenseRecordMethodAC
	|		ELSE VALUE(Catalog.WaysToReflectExpenses.EmptyRef)
	|	END AS ExpenseRecordMethodAC,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN AccountingProcedureForOSBU.ExpenseItemAccounting
	|		ELSE DocumentData.ExpenseItemAccounting
	|	END AS ExpenseItemAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN AccountingProcedureForOSBU.ExpensesDimensionAccounting
	|		ELSE DocumentData.ExpensesDimensionAccounting
	|	END AS ExpensesDimensionAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN AccountingProcedureForOSBU.DepartmentACC
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS DepartmentACC,
	|
	|	CASE 
	|		WHEN DocumentData.ExpenseItemAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN AccountingProcedureForOSBU.LineOfBusinessBookkeeping
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusinessBookkeeping,
	|
	|	UNDEFINED                                           AS ExpenseRecordMethodTA,
	|	UNDEFINED                                           AS ExpenseItemTaxAccounting,
	|	UNDEFINED                                           AS ExpensesDimensionTaxAccounting,
	|	UNDEFINED                                           AS BusinessUnitTaxAccounting,
	|	UNDEFINED                                           AS LineOfBusinessTaxAccounting,
	|	AccountingProcedureForOSBU.TransferExpensesToAnotherCompany   AS TransferExpensesToAnotherCompany,
	|	AccountingProcedureForOSBU.CompanyRecipientOfExpenses         AS CompanyRecipientOfExpenses,
	|	AccountingProcedureForOSBU.DepreciationGroup                 AS DepreciationGroup,
	|	AccountingProcedureForOSBU.RealEstate                   AS RealEstate,
	|	AccountingProcedureForOSBU.VATTaxation                    AS VATTaxation,
	|	UNDEFINED                                           AS InvestmentTaxDeduction
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = DocumentData.Ref
	|			AND AccountingProcedureForOSBU.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OriginalFA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	DocumentData.FixedAsset                       AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)         AS BUState,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)         AS StateTa,
	|	FALSE                                                   AS DepreciationAccrualAccounting,
	|	FALSE                                                   AS DepreciationAccrualTaxAccounting,
	|	UNDEFINED                                           AS ExpenseRecordMethodAC,
	|	UNDEFINED                                           AS ExpenseItemAccounting,
	|	UNDEFINED                                           AS ExpensesDimensionAccounting,
	|	UNDEFINED                                           AS DepartmentACC,
	|	UNDEFINED                                           AS LineOfBusinessBookkeeping,
	|	UNDEFINED                                           AS ExpenseRecordMethodTA,
	|	UNDEFINED                                           AS ExpenseItemTaxAccounting,
	|	UNDEFINED                                           AS ExpensesDimensionTaxAccounting,
	|	UNDEFINED                                           AS BusinessUnitTaxAccounting,
	|	UNDEFINED                                           AS LineOfBusinessTaxAccounting,
	|	FALSE                                                   AS TransferExpensesToAnotherCompany,
	|	UNDEFINED                                           AS CompanyRecipientOfExpenses,
	|	AccountingProcedureForOSBU.DepreciationGroup                 AS DepreciationGroup,
	|	AccountingProcedureForOSBU.RealEstate                   AS RealEstate,
	|	AccountingProcedureForOSBU.VATTaxation                    AS VATTaxation,
	|	AccountingProcedureForOSBU.InvestmentTaxDeduction          AS InvestmentTaxDeduction
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = DocumentData.Ref
	|			AND AccountingProcedureForOSBU.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region WriteOffOfNodes
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	TTUnitsDepreciationComponents.SubAssetComponent              AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)         AS BUState,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)         AS StateTa,
	|	FALSE                                                   AS DepreciationAccrualAccounting,
	|	FALSE                                                   AS DepreciationAccrualTaxAccounting,
	|	UNDEFINED                                           AS ExpenseRecordMethodAC,
	|	UNDEFINED                                           AS ExpenseItemAccounting,
	|	UNDEFINED                                           AS ExpensesDimensionAccounting,
	|	UNDEFINED                                           AS DepartmentACC,
	|	UNDEFINED                                           AS LineOfBusinessBookkeeping,
	|	UNDEFINED                                           AS ExpenseRecordMethodTA,
	|	UNDEFINED                                           AS ExpenseItemTaxAccounting,
	|	UNDEFINED                                           AS ExpensesDimensionTaxAccounting,
	|	UNDEFINED                                           AS BusinessUnitTaxAccounting,
	|	UNDEFINED                                           AS LineOfBusinessTaxAccounting,
	|	FALSE                                                   AS TransferExpensesToAnotherCompany,
	|	UNDEFINED                                           AS CompanyRecipientOfExpenses,
	|	AccountingProcedureForOSBU.DepreciationGroup                 AS DepreciationGroup,
	|	AccountingProcedureForOSBU.RealEstate                   AS RealEstate,
	|	AccountingProcedureForOSBU.VATTaxation                    AS VATTaxation,
	|	AccountingProcedureForOSBU.InvestmentTaxDeduction          AS InvestmentTaxDeduction
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TueAccountingProcedureForOSBU AS AccountingProcedureForOSBU
	|		ON AccountingProcedureForOSBU.Ref = TTUnitsDepreciationComponents.Ref
	|			AND AccountingProcedureForOSBU.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts, "TTIsListOfAllFA");
	
	ListOfRequests = New Array;
	
	#Region New_FA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	FATable.FixedAsset                             AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_)       AS State,
	|	AccountingProcedure.AccrueDepreciationOrAmortization                      AS AccrueDepreciationOrAmortization,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|				AND DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN VALUE(Catalog.WaysToReflectExpenses.EmptyRef)
	|		ELSE AccountingProcedure.ExpenseItem
	|	END AS ExpensesPostingMethod,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|				AND DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DocumentData.ExpenseItemManagementAccounting
	|		ELSE AccountingProcedure.ExpenseItem
	|	END AS ExpenseItem,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|				AND DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN DocumentData.ExpensesDimensionManagementAccounting
	|		ELSE AccountingProcedure.DimensionOfExpenses
	|	END AS DimensionOfExpenses,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|				AND DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE AccountingProcedure.Department
	|	END AS Department,
	|
	|	CASE 
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|				AND DocumentData.ExpenseItemManagementAccounting <> VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		ELSE AccountingProcedure.LineOfBusiness
	|	END AS LineOfBusiness,
	|
	|	AccountingProcedure.TransferExpensesToAnotherCompany       AS TransferExpensesToAnotherCompany,
	|	AccountingProcedure.CompanyRecipientOfExpenses             AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTAccountingProcedureForOsuu AS AccountingProcedure
	|		ON AccountingProcedure.Ref = DocumentData.Ref
	|			AND AccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region OriginalFA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	DocumentData.FixedAsset                       AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)         AS State,
	|	FALSE                                                   AS AccrueDepreciationOrAmortization,
	|	UNDEFINED                                           AS ExpensesPostingMethod,
	|	UNDEFINED                                           AS ExpenseItem,
	|	UNDEFINED                                           AS DimensionOfExpenses,
	|	UNDEFINED                                           AS Department,
	|	UNDEFINED                                           AS LineOfBusiness,
	|	FALSE                                                   AS TransferExpensesToAnotherCompany,
	|	UNDEFINED                                           AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	#Region WriteOffOfNodes
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	TTUnitsDepreciationComponents.SubAssetComponent              AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)         AS State,
	|	FALSE                                                   AS AccrueDepreciationOrAmortization,
	|	UNDEFINED                                           AS ExpensesPostingMethod,
	|	UNDEFINED                                           AS ExpenseItem,
	|	UNDEFINED                                           AS DimensionOfExpenses,
	|	UNDEFINED                                           AS Department,
	|	UNDEFINED                                           AS LineOfBusiness,
	|	FALSE                                                   AS TransferExpensesToAnotherCompany,
	|	UNDEFINED                                           AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion

	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers)

	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts, "TTIsListOfAllFA");
	NonCurrentAssetsInternal.QueryTextTTCostBHAGrouped(Query, QueryTexts);
	QueryTextTableTTFATableGrouped(QueryTexts);
	
	ListOfRequests = New Array;

	#Region New_FA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	FATable.FixedAsset                             AS FixedAsset,
	|	RegisterTable.LastChangeDate                AS LastChangeDate,
	|	RegisterTable.UsefulLifeMonthsAC           AS UsefulLifeMonthsAC,
	|	RegisterTable.UsefulLifeMonthsTA           AS UsefulLifeMonthsTA,
	|	RegisterTable.AnnualDepreciationRate               AS AnnualDepreciationRate,
	|	RegisterTable.AccelerationFactor                   AS AccelerationFactor,
	|	RegisterTable.DepreciationSchedule                      AS DepreciationSchedule,
	|	RegisterTable.SpecialFactor                 AS SpecialFactor,
	|	FATable.ResidualValueLocal                  AS ResidualValueMan,
	|
	|	RegisterTable.UsefulLifeForCalculatingDepreciationMonth    AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterTable.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits  AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// CostUsedToCalculateDepreciationManag
	|	CASE 
	|		WHEN RegisterTable.UsefulLifeMonthsAC <> RegisterTable.UsefulLifeForCalculatingDepreciationMonth
	|			THEN 
	|				CASE
	|					WHEN (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0)) = 0
	|						THEN 0
	|					ELSE RegisterTable.CostUsedToCalculateDepreciationManag 
	|							* FATable.CostInAccounting / (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0))
	|				END
	|		ELSE FATable.CostInAccounting
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	// CostForDepreciationCalculationTargetFinancing
	|	CASE 
	|		WHEN RegisterTable.CostForDepreciationCalculationTargetFinancing = 0
	|			THEN 0
	|		WHEN RegisterTable.UsefulLifeMonthsAC <> RegisterTable.UsefulLifeForCalculatingDepreciationMonth
	|			THEN 
	|				CASE
	|					WHEN (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0)) = 0
	|						THEN 0
	|					ELSE RegisterTable.CostForDepreciationCalculationTargetFinancing 
	|							* FATable.CostInAccounting / (ISNULL(TT_CostOfVNA.LocalCost, 0) + ISNULL(TT_CostOfVNA.CostTargetFinancing, 0))
	|				END
	|		ELSE FATable.CostInAccounting * ISNULL(TT_CostOfVNA.ShareOfCentralBank, 0)
	|	END AS CostForDepreciationCalculationTargetFinancing,
	|
	|	FATable.CostPermanentDifference AS PermanentDifferencesUsedToCalculateDepreciation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = DocumentData.Ref
	|			AND TT_CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		INNER JOIN WDepreciationParametersOfOSBU AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region SplitSubAssetsComponentsOfDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	FATable.FixedAsset                             AS FixedAsset,
	|	RegisterTable.LastChangeDate                AS LastChangeDate,
	|	FATable.UsefulLifeAccounting                          AS UsefulLifeMonthsAC,
	|	UNDEFINED                                           AS UsefulLifeMonthsTA,
	|	FATable.AnnualDepreciationRateAccounting                    AS AnnualDepreciationRate,
	|	FATable.AccelerationFactorAccounting                       AS AccelerationFactor,
	|	FATable.DepreciationSchedule                            AS DepreciationSchedule,
	|	1                                                      AS SpecialFactor,
	|	FATable.ResidualValueLocal                  AS ResidualValueMan,
	|
	|	FATable.UsefulLifeAccounting                          AS UsefulLifeForCalculatingDepreciationMonth,
	|	FATable.EstimatedRunningTime                               AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	FATable.CostInAccounting                                  AS CostUsedToCalculateDepreciationManag,
	|	0                                                      AS CostForDepreciationCalculationTargetFinancing,
	|
	|	UNDEFINED                                           AS PermanentDifferencesUsedToCalculateDepreciation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN WDepreciationParametersOfOSBU AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OriginalFA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	DocumentData.FixedAsset                       AS FixedAsset,
	|	RegisterTable.LastChangeDate                AS LastChangeDate,
	|	RegisterTable.UsefulLifeMonthsAC           AS UsefulLifeMonthsAC,
	|	RegisterTable.UsefulLifeMonthsTA           AS UsefulLifeMonthsTA,
	|	RegisterTable.AnnualDepreciationRate               AS AnnualDepreciationRate,
	|	RegisterTable.AccelerationFactor                   AS AccelerationFactor,
	|	RegisterTable.DepreciationSchedule                      AS DepreciationSchedule,
	|	RegisterTable.SpecialFactor                 AS SpecialFactor,
	|
	|	RegisterTable.ResidualValueMan
	|		- TTFATableGrouped.ResidualValueLocal AS ResidualValueMan,
	|
	|	RegisterTable.UsefulLifeForCalculatingDepreciationMonth    AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterTable.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits  AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// CostUsedToCalculateDepreciationManag
	|	RegisterTable.CostUsedToCalculateDepreciationManag
	|		- CASE 
	|			WHEN RegisterTable.UsefulLifeMonthsAC <> RegisterTable.UsefulLifeForCalculatingDepreciationMonth
	|				THEN CASE
	|						WHEN (ISNULL(TTCostBHAGrouped.LocalCost, 0) + ISNULL(TTCostBHAGrouped.CostTargetFinancing, 0)) = 0
	|							THEN 0
	|						ELSE CAST(RegisterTable.CostUsedToCalculateDepreciationManag 
	|										* TTFATableGrouped.CostInAccounting 
	|											/ (ISNULL(TTCostBHAGrouped.LocalCost, 0) 
	|												+ ISNULL(TTCostBHAGrouped.CostTargetFinancing, 0)) AS NUMBER(31, 2))
	|					END
	|			ELSE TTFATableGrouped.CostInAccounting
	|		END AS CostUsedToCalculateDepreciationManag,
	|
	// CostForDepreciationCalculationTargetFinancing
	|	RegisterTable.CostForDepreciationCalculationTargetFinancing
	|		- CASE 
	|			WHEN RegisterTable.CostForDepreciationCalculationTargetFinancing = 0
	|				THEN 0
	|			WHEN RegisterTable.UsefulLifeMonthsAC <> RegisterTable.UsefulLifeForCalculatingDepreciationMonth
	|				THEN CASE
	|						WHEN (ISNULL(TTCostBHAGrouped.LocalCost, 0) + ISNULL(TTCostBHAGrouped.CostTargetFinancing, 0)) = 0
	|							THEN 0
	|						ELSE CAST(RegisterTable.CostForDepreciationCalculationTargetFinancing 
	|										* TTFATableGrouped.CostInAccounting 
	|											/ (ISNULL(TTCostBHAGrouped.LocalCost, 0) 
	|												+ ISNULL(TTCostBHAGrouped.CostTargetFinancing, 0)) AS NUMBER(31, 2))
	|					END
	|			ELSE TTFATableGrouped.CostInAccounting
	|		END AS CostForDepreciationCalculationTargetFinancing,
	|
	// PermanentDifferencesUsedToCalculateDepreciation
	|	RegisterTable.PermanentDifferencesUsedToCalculateDepreciation 
	|		- TTFATableGrouped.CostPermanentDifference AS PermanentDifferencesUsedToCalculateDepreciation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTCostBHAGrouped AS TTCostBHAGrouped
	|		ON TTCostBHAGrouped.Ref = DocumentData.Ref
	|			AND TTCostBHAGrouped.AccountingObject = DocumentData.FixedAsset
	|
	|		INNER JOIN WDepreciationParametersOfOSBU AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInLocalAccounting
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|		VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)

	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts, "TTIsListOfAllFA");
	NonCurrentAssetsInternal.QueryTextTTCostBHAGrouped(Query, QueryTexts);
	QueryTextTableTTFATableGrouped(QueryTexts);
	
	ListOfRequests = New Array;
	
	#Region New_FA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	FATable.FixedAsset                             AS FixedAsset,
	|	RegisterTable.LastChangeDate                AS LastChangeDate,
	|	RegisterTable.UsefulLifeMonths                      AS UsefulLifeMonths,
	|	RegisterTable.AccelerationFactor                   AS AccelerationFactor,
	|	RegisterTable.DepreciationMethod             AS DepreciationMethod,
	|	FATable.ResidualValueMan                      AS ResidualValueMan,
	|	FATable.ResidualValueLocal                  AS ResidualValueLocal,
	|	RegisterTable.UsefulLifeForCalculatingDepreciationMonth   AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterTable.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// CostUsedToCalculateDepreciationManag
	|	CASE 
	|		WHEN RegisterTable.UsefulLifeMonths <> RegisterTable.UsefulLifeForCalculatingDepreciationMonth
	|			THEN 
	|				CASE
	|					WHEN ISNULL(TT_CostOfVNA.Cost, 0) = 0
	|						THEN 0
	|					ELSE RegisterTable.CostUsedToCalculateDepreciationManag 
	|							* FATable.CostInManagementAccounting / ISNULL(TT_CostOfVNA.Cost, 0)
	|				END
	|		ELSE FATable.CostInManagementAccounting
	|	END AS CostUsedToCalculateDepreciationManag,
	|
	// CostUsedToCalculateDepreciationLocal
	|	CASE 
	|		WHEN RegisterTable.UsefulLifeMonths <> RegisterTable.UsefulLifeForCalculatingDepreciationMonth
	|			THEN 
	|				CASE
	|					WHEN ISNULL(TT_CostOfVNA.LocalCost, 0) = 0
	|						THEN 0
	|					ELSE RegisterTable.CostUsedToCalculateDepreciationLocal 
	|							* FATable.CostInAccounting / ISNULL(TT_CostOfVNA.LocalCost, 0)
	|				END
	|		ELSE FATable.CostInAccounting
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = DocumentData.Ref
	|			AND TT_CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		INNER JOIN TTOsuuDepreciationParameters AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region SplitSubAssetsComponentsOfDepreciation
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	FATable.FixedAsset                             AS FixedAsset,
	|	RegisterTable.LastChangeDate                AS LastChangeDate,
	|	FATable.UsefulLifeManagementAccounting                          AS UsefulLifeMonths,
	|	FATable.AccelerationFactorManagementAccounting                       AS AccelerationFactor,
	|	FATable.DepreciationAccrualMethodManagementAccounting                 AS DepreciationMethod,
	|	FATable.ResidualValueMan                      AS ResidualValueMan,
	|	FATable.ResidualValueLocal                  AS ResidualValueLocal,
	|	FATable.UsefulLifeManagementAccounting                          AS UsefulLifeForCalculatingDepreciationMonth,
	|	FATable.EstimatedRunningTime                               AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	FATable.CostInManagementAccounting                                  AS CostUsedToCalculateDepreciationManag,
	|	FATable.CostInAccounting                                  AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTOsuuDepreciationParameters AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OriginalFA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	DocumentData.FixedAsset                       AS FixedAsset,
	|	RegisterTable.LastChangeDate                AS LastChangeDate,
	|	RegisterTable.UsefulLifeMonths                      AS UsefulLifeMonths,
	|	RegisterTable.AccelerationFactor                   AS AccelerationFactor,
	|	RegisterTable.DepreciationMethod             AS DepreciationMethod,
	|
	|	RegisterTable.ResidualValueMan
	|		- TTFATableGrouped.ResidualValueMan AS ResidualValueMan,
	|
	|	RegisterTable.ResidualValueLocal
	|		- TTFATableGrouped.ResidualValueLocal AS ResidualValueLocal,
	|
	|	RegisterTable.UsefulLifeForCalculatingDepreciationMonth   AS UsefulLifeForCalculatingDepreciationMonth,
	|	RegisterTable.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	// CostUsedToCalculateDepreciationManag
	|	RegisterTable.CostUsedToCalculateDepreciationManag
	|		- CASE 
	|			WHEN RegisterTable.UsefulLifeMonths <> RegisterTable.UsefulLifeForCalculatingDepreciationMonth
	|				THEN CASE
	|						WHEN ISNULL(TTCostBHAGrouped.Cost, 0) = 0
	|							THEN 0
	|						ELSE CAST(RegisterTable.CostUsedToCalculateDepreciationManag 
	|										* TTFATableGrouped.CostInManagementAccounting / ISNULL(TTCostBHAGrouped.Cost, 0) AS NUMBER(31, 2))
	|					END
	|			ELSE TTFATableGrouped.CostInManagementAccounting
	|		END AS CostUsedToCalculateDepreciationManag,
	|
	// CostUsedToCalculateDepreciationLocal
	|	RegisterTable.CostUsedToCalculateDepreciationLocal
	|		- CASE
	|			WHEN RegisterTable.UsefulLifeMonths <> RegisterTable.UsefulLifeForCalculatingDepreciationMonth
	|				THEN CASE
	|						WHEN ISNULL(TTCostBHAGrouped.LocalCost, 0) = 0
	|							THEN 0
	|						ELSE CAST(RegisterTable.CostUsedToCalculateDepreciationLocal 
	|										* TTFATableGrouped.CostInAccounting / ISNULL(TTCostBHAGrouped.LocalCost, 0) AS NUMBER(31, 2))
	|					END
	|			ELSE TTFATableGrouped.CostInAccounting
	|		END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTCostBHAGrouped AS TTCostBHAGrouped
	|		ON TTCostBHAGrouped.Ref = DocumentData.Ref
	|			AND TTCostBHAGrouped.AccountingObject = DocumentData.FixedAsset
	|
	|		INNER JOIN TTOsuuDepreciationParameters AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit),
	|		VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
		
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers)

	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTIsListOfAllFA");
	
	ListOfRequests = New Array;

	#Region New_FA
	QueryText =
	"SELECT
	|	DocumentData.Ref             AS Recorder,
	|	DocumentData.Period             AS Period,
	|	DocumentData.Organization        AS Organization,
	|	FATable.FixedAsset         AS FixedAsset,
	|	RegisterTable.ReceiptMethod  AS ReceiptMethod,
	|	RegisterTable.Counterparty         AS Counterparty,
	
	// AccountingProcedureAC
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN RegisterTable.AccountingProcedureAC
	|		ELSE NewOSRegisterTable.AccountingProcedureAC
	|	END AS AccountingProcedureAC,

	// AccountingProcedureMA
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN RegisterTable.AccountingProcedureMA
	|		ELSE NewOSRegisterTable.AccountingProcedureMA
	|	END AS AccountingProcedureMA,
	
	// DepreciationMethodAccounting
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN RegisterTable.DepreciationMethodAccounting
	|		ELSE NewOSRegisterTable.DepreciationMethodAccounting
	|	END AS DepreciationMethodAccounting,
	
	// InitialCostLocalAccounting
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInAccounting
	|		ELSE NewOSRegisterTable.InitialCostLocalAccounting
	|	END AS InitialCostLocalAccounting,
	
	// InitialCostMA
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN FATable.CostInManagementAccounting
	|		ELSE NewOSRegisterTable.InitialCostMA
	|	END AS InitialCostMA,
	
	// CommissioningDateAC
	|	CASE 
	|		WHEN RegisterTable.CommissioningDateAC = DATETIME(1,1,1)
	|			THEN DATETIME(1,1,1)
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN RegisterTable.CommissioningDateAC
	|		ELSE NewOSRegisterTable.CommissioningDateAC
	|	END AS CommissioningDateAC,
	
	// CommissioningDateMA
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN RegisterTable.CommissioningDateMA
	|		ELSE NewOSRegisterTable.CommissioningDateMA
	|	END AS CommissioningDateMA,
	
	// CommissioningDocumentAC
	|	CASE 
	|		WHEN RegisterTable.CommissioningDateAC = DATETIME(1,1,1)
	|			THEN UNDEFINED
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN DocumentData.Ref
	|		ELSE NewOSRegisterTable.CommissioningDocumentAC
	|	END AS CommissioningDocumentAC,
	
	// CommissioningDocumentMA
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|			THEN DocumentData.Ref
	|		ELSE NewOSRegisterTable.CommissioningDocumentMA
	|	END AS CommissioningDocumentMA,
	|
	|	UNDEFINED AS DeregistrationDocumentACC,
	|	UNDEFINED AS DeregistrationDocumentMA
	|
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTInitialInformationFA AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|	
	|		LEFT JOIN TTInitialInformationFA AS NewOSRegisterTable
	|		ON NewOSRegisterTable.Ref = FATable.Ref
	|			AND NewOSRegisterTable.FixedAsset = FATable.FixedAsset
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region OriginalFA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	DocumentData.FixedAsset                       AS FixedAsset,
	|	RegisterTable.ReceiptMethod                      AS ReceiptMethod,
	|	RegisterTable.Counterparty                             AS Counterparty,
	|
	|	RegisterTable.AccountingProcedureAC                         AS AccountingProcedureAC,
	|	RegisterTable.AccountingProcedureMA                         AS AccountingProcedureMA,
	|	RegisterTable.DepreciationMethodAccounting           AS DepreciationMethodAccounting,
	|	RegisterTable.InitialCostLocalAccounting              AS InitialCostLocalAccounting,
	|	RegisterTable.InitialCostMA              AS InitialCostMA,
	|	RegisterTable.CommissioningDateAC               AS CommissioningDateAC,
	|	RegisterTable.CommissioningDateMA               AS CommissioningDateMA,
	|	RegisterTable.CommissioningDocumentAC           AS CommissioningDocumentAC,
	|	RegisterTable.CommissioningDocumentMA           AS CommissioningDocumentMA,
	|
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND RegisterTable.CommissioningDateAC <> DATETIME(1,1,1)
	|			THEN DocumentData.Ref 
	|		ELSE RegisterTable.DeregistrationDocumentACC
	|	END AS DeregistrationDocumentACC,
	|
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND RegisterTable.CommissioningDateMA <> DATETIME(1,1,1)
	|			THEN DocumentData.Ref 
	|		ELSE RegisterTable.DeregistrationDocumentMA
	|	END AS DeregistrationDocumentMA
	|
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTInitialInformationFA AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region NodesAreDepreciationComponentsOfOriginalFA
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Organization                            AS Organization,
	|	TTUnitsDepreciationComponents.SubAssetComponent              AS FixedAsset,
	|	RegisterTable.ReceiptMethod                      AS ReceiptMethod,
	|	RegisterTable.Counterparty                             AS Counterparty,
	|
	|	RegisterTable.AccountingProcedureAC                         AS AccountingProcedureAC,
	|	RegisterTable.AccountingProcedureMA                         AS AccountingProcedureMA,
	|	RegisterTable.DepreciationMethodAccounting           AS DepreciationMethodAccounting,
	|	RegisterTable.InitialCostLocalAccounting              AS InitialCostLocalAccounting,
	|	RegisterTable.InitialCostMA              AS InitialCostMA,
	|	RegisterTable.CommissioningDateAC               AS CommissioningDateAC,
	|	RegisterTable.CommissioningDateMA               AS CommissioningDateMA,
	|	RegisterTable.CommissioningDocumentAC           AS CommissioningDocumentAC,
	|	RegisterTable.CommissioningDocumentMA           AS CommissioningDocumentMA,
	|
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND RegisterTable.CommissioningDateAC <> DATETIME(1,1,1)
	|			THEN DocumentData.Ref 
	|		ELSE RegisterTable.DeregistrationDocumentACC
	|	END AS DeregistrationDocumentACC,
	|
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND RegisterTable.CommissioningDateMA <> DATETIME(1,1,1)
	|			THEN DocumentData.Ref 
	|		ELSE RegisterTable.DeregistrationDocumentMA
	|	END AS DeregistrationDocumentMA
	|
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTInitialInformationFA AS RegisterTable
	|		ON RegisterTable.Ref = TTUnitsDepreciationComponents.Ref
	|			AND RegisterTable.FixedAsset = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFALocation(Query, QueryTexts, Registers)

	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts, "TTIsListOfAllFA");
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                        AS Recorder,
	|	DocumentData.Period                        AS Period,
	|	DocumentData.Organization                   AS Organization,
	|	FATable.FixedAsset                    AS FixedAsset,
	|	RegisterTable.FinanciallyLiablePerson                           AS FinanciallyLiablePerson,
	|	RegisterTable.FixedAssetsLocation               AS FixedAssetsLocation,
	|	RegisterTable.LocationAddress          AS LocationAddress,
	|	RegisterTable.LocationAddressValue  AS LocationAddressValue,
	|	RegisterTable.Leaseholder                     AS Leaseholder,
	|	RegisterTable.LeaseholderBusinessUnit       AS LeaseholderBusinessUnit,
	|	RegisterTable.LeaseholderEmployeeInCharge                 AS LeaseholderEmployeeInCharge,
	|	DocumentData.RecordInLocalAccounting            AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting             AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTLocationOfFA AS RegisterTable
	|		ON RegisterTable.Ref = DocumentData.Ref
	|			AND RegisterTable.FixedAsset = DocumentData.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers)
	
	RegisterName = "SubAssetsComponentsOfDepreciation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	FATable.FixedAsset        AS SubAssetComponent,
	|	DocumentData.FixedAsset  AS FixedAsset
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableCGUComposition(Query, QueryTexts, Registers)

	RegisterName = "CGUComposition";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTCompositionOfCGU(QueryTexts, "TTIsListOfAllFA");
	
	QueryText =
	"SELECT
	|	DocumentData.Period AS Period,
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAsset AS NonCurrentAsset,
	|	CGUComposition.CGU AS CGU
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTCompositionOfCGU AS CGUComposition
	|		ON CGUComposition.Ref = DocumentData.Ref
	|			AND CGUComposition.NonCurrentAsset = DocumentData.FixedAsset
	|	
	|WHERE
	|	CGUComposition.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableTTIsListOfAllFA(QueryTexts)
	
	TableName = "TTIsListOfAllFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts, "DocumentDataDetails");

	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.FixedAsset AS FixedAsset
	|
	|INTO TTIsListOfAllFA
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref AS Ref,
	|	FATable.SubAssetComponent AS FixedAsset
	|
	|FROM
	|	TTUnitsDepreciationComponents AS FATable
	|
	|INDEX BY
	|	FixedAsset
	|";
		
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTAllocationOfCost(QueryTexts)

	TableName = "TTAllocationOfCost";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTCoefficients(QueryTexts);
	QueryTextTableTTFATableGrouped(QueryTexts);
	
	QueryText = 
	"SELECT
	|	FATable.Ref                 AS Ref,
	|	FATable.FixedAsset       AS FixedAsset,
	|	DocumentData.FixedAsset AS MainMeansSource,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &PreliminaryCostOfMan
	|		ELSE 0
	|	END AS PreliminaryCostMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &PreliminaryCostLocal
	|		ELSE 0
	|	END AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &CostMan
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &LocalCost
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInTaxAccounting <> 0
	|			THEN &CostInTaxAccounting
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostPermanentDifference <> 0
	|			THEN &CostPermanentDifference1
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &CostPermanentDifference2
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostTemporaryDifference <> 0
	|			THEN &CostTemporaryDifference
	|		ELSE 0
	|	END AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &CostTargetFinancing
	|		ELSE 0
	|	END AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &Cost_PRCF
	|		ELSE 0
	|	END AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &RevaluationReserveForMan
	|		ELSE 0
	|	END AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &CostRevaluationReserveLocal
	|		ELSE 0
	|	END AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|			THEN TT_CostOfVNA.TAExpenseAmountOfInvestmentTaxDeduction
	|		ELSE 0
	|	END AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	
	|	FATable.RowID AS RowID
	|
	|INTO TTAllocationOfCost
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = DocumentData.Ref
	|			AND TT_CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		INNER JOIN TTCoefficients AS TTCoefficients
	|		ON TTCoefficients.Ref = FATable.Ref
	|			AND TTCoefficients.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = FATable.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref                 AS Ref,
	|	FATable.FixedAsset       AS FixedAsset,
	|	TTUnitsDepreciationComponents.SubAssetComponent AS MainMeansSource,
	|
	|	0 AS PreliminaryCostMan,
	|	0 AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &CostMan
	|		ELSE 0
	|	END AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &LocalCost
	|		ELSE 0
	|	END AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInTaxAccounting <> 0
	|			THEN &CostInTaxAccounting
	|		ELSE 0
	|	END AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostPermanentDifference <> 0
	|			THEN &CostPermanentDifference1
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &CostPermanentDifference2
	|		ELSE 0
	|	END AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostTemporaryDifference <> 0
	|			THEN &CostTemporaryDifference
	|		ELSE 0
	|	END AS CostTemporaryDifference,
	|
	|	0 AS CostTargetFinancing,
	|	0 AS CostTargetFinancingPD,
	|
	|	0 AS CostRevaluationReserve,
	|	0 AS CostRevaluationReserveLocal,
	|	0 AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	
	|	FATable.RowID AS RowID
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = TTUnitsDepreciationComponents.Ref
	|			AND TT_CostOfVNA.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		INNER JOIN TTCoefficients AS TTCoefficients
	|		ON TTCoefficients.Ref = FATable.Ref
	|			AND TTCoefficients.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|
	|INDEX BY
	|	Ref
	|";
	
	// PreliminaryCostMan
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.PreliminaryCostMan, 0)", 
		"FATable.CostInManagementAccounting", 
		"TTCoefficients.CostOfPreviousLinesMA", 
		"TTFATableGrouped.CostInManagementAccounting");
	QueryText = StrReplace(QueryText, "&PreliminaryCostOfMan", AmountDistributionText);
	
	// PreliminaryCostLocal
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.PreliminaryCostLocal, 0)", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&PreliminaryCostLocal", AmountDistributionText);
	
	// Cost
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.Cost, 0)", 
		"FATable.CostInManagementAccounting", 
		"TTCoefficients.CostOfPreviousLinesMA", 
		"TTFATableGrouped.CostInManagementAccounting");
	QueryText = StrReplace(QueryText, "&CostMan", AmountDistributionText);
	
	// LocalCost
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.LocalCost, 0)", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&LocalCost", AmountDistributionText);
	
	// CostInTaxAccounting
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostInTaxAccounting, 0)", 
		"FATable.CostInTaxAccounting", 
		"TTCoefficients.CostOfPreviousLinesIsTA", 
		"TTFATableGrouped.CostInTaxAccounting");
	QueryText = StrReplace(QueryText, "&CostInTaxAccounting", AmountDistributionText);
	
	// CostPermanentDifference1
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostPermanentDifference, 0)", 
		"FATable.CostPermanentDifference", 
		"TTCoefficients.CostOfPreviousLinesIsPD", 
		"TTFATableGrouped.CostPermanentDifference");
	QueryText = StrReplace(QueryText, "&CostPermanentDifference1", AmountDistributionText);
	
	// CostPermanentDifference2
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostPermanentDifference, 0)", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&CostPermanentDifference2", AmountDistributionText);
	
	// CostTemporaryDifference
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostTemporaryDifference, 0)", 
		"FATable.CostTemporaryDifference", 
		"TTCoefficients.CostOfPreviousLinesOfTD", 
		"TTFATableGrouped.CostTemporaryDifference");
	QueryText = StrReplace(QueryText, "&CostTemporaryDifference", AmountDistributionText);
	
	// CostTargetFinancing
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostTargetFinancing, 0)", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&CostTargetFinancing", AmountDistributionText);
	
	// CostTargetFinancingPD
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostTargetFinancingPD, 0)", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&Cost_PRCF", AmountDistributionText);
	
	// CostRevaluationReserve
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostRevaluationReserve, 0)", 
		"FATable.CostInManagementAccounting", 
		"TTCoefficients.CostOfPreviousLinesMA", 
		"TTFATableGrouped.CostInManagementAccounting");
	QueryText = StrReplace(QueryText, "&RevaluationReserveForMan", AmountDistributionText);
	
	// CostRevaluationReserveLocal
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"ISNULL(TT_CostOfVNA.CostRevaluationReserveLocal, 0)", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&CostRevaluationReserveLocal", AmountDistributionText);
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTAllocationOfDepreciation(QueryTexts)

	TableName = "TTAllocationOfDepreciation";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTIsListOfAllFA");
	QueryTextTableTTCoefficients(QueryTexts);
	QueryTextTableTTFATableGrouped(QueryTexts);
	
	QueryText = 
	"SELECT
	|	FATable.Ref                                AS Ref,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	DocumentData.FixedAsset                AS MainMeansSource,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness          AS LineOfBusiness,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation                    AS AccrueDepreciation,
	|	
	// Depreciation
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &ManDepreciation
	|		ELSE 0
	|	END AS Depreciation,
	|		
	// DepreciationLocal
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|		
	// DepreciationInTaxAccounting
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInTaxAccounting <> 0
	|			THEN &DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|		
	// DepreciationPermanentDifferences
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostPermanentDifference <> 0
	|			THEN &DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|		
	// DepreciationTD
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &DepreciationLocal
	|		ELSE 0
	|	END 
	|		- CASE
	|			WHEN DocumentData.RecordInLocalAccounting 
	|					AND TTFATableGrouped.CostInTaxAccounting <> 0
	|				THEN &DepreciationInTaxAccounting
	|			ELSE 0
	|		END
	|		- CASE
	|			WHEN DocumentData.RecordInLocalAccounting 
	|					AND TTFATableGrouped.CostPermanentDifference <> 0
	|				THEN &DepreciationPermanentDifferences
	|			ELSE 0
	|		END AS DepreciationTD,
	|		
	// FixedAssetDepreciationTargetFinancing
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &Depreciation_CF
	|		ELSE 0
	|	END AS FixedAssetDepreciationTargetFinancing,
	|		
	// DepreciationTaxAccountingTargetFinancing
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInTaxAccounting <> 0
	|			THEN &Depreciation_NUCF
	|		ELSE 0
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|		
	// DepreciationTargetFinancingPD
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostPermanentDifference <> 0
	|			THEN &Depreciation_PRCF
	|		ELSE 0
	|	END AS DepreciationTargetFinancingPD,
	|		
	// DepreciationOfTargetFinancingTD
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &Depreciation_CF
	|		ELSE 0
	|	END 
	|		- CASE
	|			WHEN DocumentData.RecordInLocalAccounting 
	|					AND TTFATableGrouped.CostInTaxAccounting <> 0
	|				THEN &Depreciation_NUCF
	|			ELSE 0
	|		END
	|		- CASE
	|			WHEN DocumentData.RecordInLocalAccounting 
	|					AND TTFATableGrouped.CostPermanentDifference <> 0
	|				THEN &Depreciation_PRCF
	|			ELSE 0
	|		END AS DepreciationOfTargetFinancingTD,
	|		
	// DepreciationRevaluationReserve
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &RevaluationReserveForManDepreciation
	|		ELSE 0
	|	END AS DepreciationRevaluationReserve,
	|		
	// DepreciationRevaluationReserveLocal
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &DepreciationRevaluationReserveLocal
	|		ELSE 0
	|	END AS DepreciationRevaluationReserveLocal,
	|	
	|	FATable.RowID AS RowID
	|	
	|INTO TTAllocationOfDepreciation
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = DocumentData.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = DocumentData.Ref
	|			AND FACost.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|		INNER JOIN TTCoefficients AS TTCoefficients
	|		ON TTCoefficients.Ref = FATable.Ref
	|			AND TTCoefficients.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = FATable.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref                                AS Ref,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	TTUnitsDepreciationComponents.SubAssetComponent       AS MainMeansSource,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness          AS LineOfBusiness,
	|	FixedAssetsDepreciationCharge.AccrueDepreciation                    AS AccrueDepreciation,
	|	
	// Depreciation
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting 
	|				AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &ManDepreciation
	|		ELSE 0
	|	END AS Depreciation,
	|		
	// DepreciationLocal
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &DepreciationLocal
	|		ELSE 0
	|	END AS DepreciationLocal,
	|		
	// DepreciationInTaxAccounting
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInTaxAccounting <> 0
	|			THEN &DepreciationInTaxAccounting
	|		ELSE 0
	|	END AS DepreciationInTaxAccounting,
	|		
	// DepreciationPermanentDifferences
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostPermanentDifference <> 0
	|			THEN &DepreciationPermanentDifferences
	|		ELSE 0
	|	END AS DepreciationPermanentDifferences,
	|		
	// DepreciationTD
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting 
	|				AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &DepreciationLocal
	|		ELSE 0
	|	END 
	|		- CASE
	|			WHEN DocumentData.RecordInLocalAccounting 
	|					AND TTFATableGrouped.CostInTaxAccounting <> 0
	|				THEN &DepreciationInTaxAccounting
	|			ELSE 0
	|		END
	|		- CASE
	|			WHEN DocumentData.RecordInLocalAccounting 
	|					AND TTFATableGrouped.CostPermanentDifference <> 0
	|				THEN &DepreciationPermanentDifferences
	|			ELSE 0
	|		END AS DepreciationTD,
	|		
	|	0 AS FixedAssetDepreciationTargetFinancing,
	|	0 AS DepreciationTaxAccountingTargetFinancing,
	|	0 AS DepreciationTargetFinancingPD,
	|	0 AS DepreciationOfTargetFinancingTD,
	|		
	|	0 AS DepreciationRevaluationReserve,
	|	0 AS DepreciationRevaluationReserveLocal,
	|	
	|	FATable.RowID AS RowID
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = TTUnitsDepreciationComponents.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = DocumentData.Ref
	|			AND FACost.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|		INNER JOIN TTCoefficients AS TTCoefficients
	|		ON TTCoefficients.Ref = FATable.Ref
	|			AND TTCoefficients.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|
	|INDEX BY
	|	Ref
	|";
	
	// ManDepreciation
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.Cost, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) * (CAST(TTFATableGrouped.CostInManagementAccounting AS NUMBER (25, 12)) / CAST(ISNULL(FACost.Cost, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.Depreciation, 0) 
		|END", 
		"FATable.CostInManagementAccounting", 
		"TTCoefficients.CostOfPreviousLinesMA",
		"TTFATableGrouped.CostInManagementAccounting");
	QueryText = StrReplace(QueryText, "&ManDepreciation", AmountDistributionText);
	
	// DepreciationLocal
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) * (CAST(TTFATableGrouped.CostInAccounting AS NUMBER (25, 12)) / CAST(ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.DepreciationLocal, 0) 
		|END", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&DepreciationLocal", AmountDistributionText);
	
	// DepreciationInTaxAccounting
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.CostInTaxAccounting, 0) + ISNULL(FACost.CostTargetFinancingTA, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) * (CAST(TTFATableGrouped.CostInTaxAccounting AS NUMBER (25, 12)) / CAST(ISNULL(FACost.CostInTaxAccounting, 0) + ISNULL(FACost.CostTargetFinancingTA, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.DepreciationInTaxAccounting, 0) 
		|END", 
		"FATable.CostInTaxAccounting", 
		"TTCoefficients.CostOfPreviousLinesIsTA", 
		"TTFATableGrouped.CostInTaxAccounting");
	QueryText = StrReplace(QueryText, "&DepreciationInTaxAccounting", AmountDistributionText);
	
	// DepreciationPermanentDifferences
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.CostPermanentDifference, 0) + ISNULL(FACost.CostTargetFinancingPD, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) * (CAST(TTFATableGrouped.CostPermanentDifference AS NUMBER (25, 12)) / CAST(ISNULL(FACost.CostPermanentDifference, 0) + ISNULL(FACost.CostTargetFinancingPD, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.DepreciationPermanentDifferences, 0) 
		|END", 
		"FATable.CostPermanentDifference", 
		"TTCoefficients.CostOfPreviousLinesIsPD", 
		"TTFATableGrouped.CostPermanentDifference");
	QueryText = StrReplace(QueryText, "&DepreciationPermanentDifferences", AmountDistributionText);
	
	// Depreciation_CF
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.CostPermanentDifference, 0) + ISNULL(FACost.CostTargetFinancing, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) * (CAST(TTFATableGrouped.CostInAccounting AS NUMBER (25, 12)) / CAST(ISNULL(FACost.CostPermanentDifference, 0) + ISNULL(FACost.CostTargetFinancing, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.FixedAssetDepreciationTargetFinancing, 0) 
		|END", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&Depreciation_CF", AmountDistributionText);
	
	// Depreciation_NUCF
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.CostInTaxAccounting, 0) + ISNULL(FACost.CostTargetFinancingTA, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) * (CAST(TTFATableGrouped.CostInTaxAccounting AS NUMBER (25, 12)) / CAST(ISNULL(FACost.CostInTaxAccounting, 0) + ISNULL(FACost.CostTargetFinancingTA, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.DepreciationTaxAccountingTargetFinancing, 0) 
		|END", 
		"FATable.CostInTaxAccounting", 
		"TTCoefficients.CostOfPreviousLinesIsTA", 
		"TTFATableGrouped.CostInTaxAccounting");
	QueryText = StrReplace(QueryText, "&Depreciation_NUCF", AmountDistributionText);
	
	// Depreciation_PRCF
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.CostPermanentDifference, 0) + ISNULL(FACost.CostTargetFinancingPD, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD, 0) * (CAST(TTFATableGrouped.CostInTaxAccounting AS NUMBER (25, 12)) / CAST(ISNULL(FACost.CostPermanentDifference, 0) + ISNULL(FACost.CostTargetFinancingPD, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.DepreciationTargetFinancingPD, 0) 
		|END", 
		"FATable.CostPermanentDifference", 
		"TTCoefficients.CostOfPreviousLinesIsPD", 
		"TTFATableGrouped.CostPermanentDifference");
	QueryText = StrReplace(QueryText, "&Depreciation_PRCF", AmountDistributionText);
	
	// RevaluationReserveForManDepreciation
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.Cost, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.DepreciationRevaluationReserve, 0) * (CAST(TTFATableGrouped.CostInManagementAccounting AS NUMBER (25, 12)) / CAST(ISNULL(FACost.Cost, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.DepreciationRevaluationReserve, 0) 
		|END", 
		"FATable.CostInManagementAccounting", 
		"TTCoefficients.CostOfPreviousLinesMA", 
		"TTFATableGrouped.CostInManagementAccounting");
	QueryText = StrReplace(QueryText, "&RevaluationReserveForManDepreciation", AmountDistributionText);
	
	// DepreciationRevaluationReserveLocal
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0) <> 0
		|					THEN ISNULL(FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal, 0) * (CAST(TTFATableGrouped.CostInAccounting AS NUMBER (25, 12)) / CAST(ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0) AS NUMBER (25, 12)))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(FixedAssetsDepreciationCharge.DepreciationRevaluationReserveLocal, 0) 
		|END", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC",
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&DepreciationRevaluationReserveLocal", AmountDistributionText);

	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTAllocationOfImpairment(QueryTexts)

	TableName = "TTAllocationOfImpairment";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTIsListOfAllFA");
	QueryTextTableTTCoefficients(QueryTexts);
	QueryTextTableTTFATableGrouped(QueryTexts);
	
	QueryText = 
	"SELECT
	|	FATable.Ref                                AS Ref,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness          AS LineOfBusiness,
	|	ImpairmentFA.CGU                             AS CGU,
	|
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,
	|
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|	
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|	
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,
	|	
	|	FATable.RowID AS RowID
	|	
	|INTO TTAllocationOfImpairment
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = DocumentData.Ref
	|			AND ImpairmentFA.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = DocumentData.Ref
	|			AND FACost.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|		INNER JOIN TTCoefficients AS TTCoefficients
	|		ON TTCoefficients.Ref = FATable.Ref
	|			AND TTCoefficients.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation <> VALUE(Enum.BusinessTransactions.SplitSubAssetsComponentsOfDepreciation)
	|
	|UNION ALL
	|
	|SELECT
	|	FATable.Ref                                AS Ref,
	|	FATable.FixedAsset                      AS FixedAsset,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.LineOfBusiness          AS LineOfBusiness,
	|	ImpairmentFA.CGU                             AS CGU,
	|
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &ImpairmenMan
	|		ELSE 0
	|	END AS ImpairmenMan,	
	|
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &ImpairmentLocalAssets
	|		ELSE 0
	|	END AS ImpairmentLocalAssets,
	|
	|	CASE
	|		WHEN DocumentData.RecordInManAccounting AND TTFATableGrouped.CostInManagementAccounting <> 0
	|			THEN &LossFromImpairmentMgmt
	|		ELSE 0
	|	END AS LossFromImpairmentMgmt,
	|
	|	CASE
	|		WHEN DocumentData.RecordInLocalAccounting AND TTFATableGrouped.CostInAccounting <> 0
	|			THEN &LossFromImpairmentLocal
	|		ELSE 0
	|	END AS LossFromImpairmentLocal,	
	|	
	|	FATable.RowID AS RowID
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS TTUnitsDepreciationComponents
	|		ON TTUnitsDepreciationComponents.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_ImpairmentFA AS ImpairmentFA
	|		ON ImpairmentFA.Ref = TTUnitsDepreciationComponents.Ref
	|			AND ImpairmentFA.AccountingObject = TTUnitsDepreciationComponents.SubAssetComponent
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = DocumentData.Ref
	|			AND FACost.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
	|
	|		INNER JOIN TTCoefficients AS TTCoefficients
	|		ON TTCoefficients.Ref = FATable.Ref
	|			AND TTCoefficients.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TTFATableGrouped AS TTFATableGrouped
	|		ON TTFATableGrouped.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.CompleteSplitFixedAssets)
	|	AND (DocumentData.WriteOffNodes
	|		OR TTUnitsDepreciationComponents.SubAssetComponent.OSType = VALUE(Enum.FATypes.DepreciationComponent))
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	// ImpairmenMan
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.Cost, 0) <> 0
		|					THEN ISNULL(ImpairmentFA.ImpairmenMan, 0) * TTFATableGrouped.CostInManagementAccounting / ISNULL(FACost.Cost, 0)
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(ImpairmentFA.ImpairmenMan, 0) 
		|END", 
		"FATable.CostInManagementAccounting", 
		"TTCoefficients.CostOfPreviousLinesMA",
		"TTFATableGrouped.CostInManagementAccounting");
	QueryText = StrReplace(QueryText, "&ImpairmenMan", AmountDistributionText);
	
	// ImpairmentLocalAssets
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0) <> 0
		|					THEN ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) * TTFATableGrouped.CostInAccounting / (ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(ImpairmentFA.ImpairmentLocalAssets, 0) 
		|END", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&ImpairmentLocalAssets", AmountDistributionText);
	
	// LossFromImpairmentMgmt
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.Cost, 0) <> 0
		|					THEN ISNULL(ImpairmentFA.LossFromImpairmentMgmt, 0) * TTFATableGrouped.CostInManagementAccounting / ISNULL(FACost.Cost, 0)
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(ImpairmentFA.LossFromImpairmentMgmt, 0) 
		|END", 
		"FATable.CostInManagementAccounting", 
		"TTCoefficients.CostOfPreviousLinesMA",
		"TTFATableGrouped.CostInManagementAccounting");
	QueryText = StrReplace(QueryText, "&LossFromImpairmentMgmt", AmountDistributionText);
	
	// LossFromImpairmentLocal
	AmountDistributionText = TMCommonUse.AmountDistributionText(
		"CASE 
		|	WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.PartialFixedAssetsSplit) 
		|		THEN CASE 
		|				WHEN ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0) <> 0
		|					THEN ISNULL(ImpairmentFA.LossFromImpairmentLocal, 0) * TTFATableGrouped.CostInAccounting / (ISNULL(FACost.LocalCost, 0) + ISNULL(FACost.CostTargetFinancing, 0))
		|				ELSE 0 
		|		END
		|	ELSE ISNULL(ImpairmentFA.LossFromImpairmentLocal, 0) 
		|END", 
		"FATable.CostInAccounting", 
		"TTCoefficients.CostOfPreviousLinesOfAC", 
		"TTFATableGrouped.CostInAccounting");
	QueryText = StrReplace(QueryText, "&LossFromImpairmentLocal", AmountDistributionText);

	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTCoefficients(QueryTexts)
	
	TableName = "TTCoefficients";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	FATable.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|
	|	SUM(ISNULL(FATable_.CostInAccounting, 0)) AS CostOfPreviousLinesOfAC,
	|	SUM(ISNULL(FATable_.CostInTaxAccounting, 0)) AS CostOfPreviousLinesIsTA,
	|	SUM(ISNULL(FATable_.CostPermanentDifference, 0)) AS CostOfPreviousLinesIsPD,
	|	SUM(ISNULL(FATable_.CostTemporaryDifference, 0)) AS CostOfPreviousLinesOfTD,
	|	SUM(ISNULL(FATable_.CostInManagementAccounting, 0)) AS CostOfPreviousLinesMA
	|
	|INTO TTCoefficients
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		LEFT JOIN DocumentDataFATable AS FATable_
	|		ON FATable_.Ref = FATable.Ref
	|			AND FATable_.LineNumber < FATable.LineNumber
	|
	|GROUP BY
	|	FATable.Ref,
	|	FATable.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTFATableGrouped(QueryTexts)
	
	TableName = "TTFATableGrouped";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	FATable.Ref AS Ref,
	|	SUM(FATable.CostInAccounting) AS CostInAccounting,
	|	SUM(FATable.CostInTaxAccounting) AS CostInTaxAccounting,
	|	SUM(FATable.CostPermanentDifference) AS CostPermanentDifference,
	|	SUM(FATable.CostTemporaryDifference) AS CostTemporaryDifference,
	|	SUM(FATable.CostInManagementAccounting) AS CostInManagementAccounting,
	|	SUM(FATable.ResidualValueMan) AS ResidualValueMan,
	|	SUM(FATable.ResidualValueLocal) AS ResidualValueLocal
	|
	|INTO TTFATableGrouped
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|GROUP BY
	|	FATable.Ref
	|
	|INDEX BY
	|	Ref
	|";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return SplitFixedAssetsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return SplitFixedAssetsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	

EndProcedure

Function GetDataForPrintedFormOS4(ObjectsArray) Export

	Return SplitFixedAssetsLocalization.GetDataForPrintedFormOS4(ObjectsArray);

EndFunction
 
#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	#Region ReflectionOfDepreciationExpenses
	
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
	
	#EndRegion
	
	Return ArticleSelectionAndAnalyticsOptions;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
