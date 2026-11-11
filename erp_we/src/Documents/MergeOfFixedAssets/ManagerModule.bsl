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
	
	MergeOfFixedAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.MergeOfFixedAssets") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		
		QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers);
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers);
		QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers);
		QueryTextTableFACost(Query, QueryTexts, Registers);
		QueryTextTableCGUComposition(Query, QueryTexts, Registers);
		NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		MergeOfFixedAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
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
	
	QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Undefined);
	QueryTextTableAccountingProcedureForOSBU(QueryTexts, Undefined);
	QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Undefined);
	QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Undefined);
	QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Undefined);
	
	QueryTextTableFACost(Query, QueryTexts, Undefined);
	QueryTextTableFixedAssetsDepreciationCharge(QueryTexts);
	QueryTextTableImpairmentFA(QueryTexts);
	QueryTextTableOtherIncome(QueryTexts, QueryTexts);
	QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Undefined);
	MergeOfFixedAssetsLocalization.TablesOfDeferredMotionFormation(Query, QueryTexts);
	
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
	
	MergeOfFixedAssetsLocalization.AddGenerationCommands(GenerationCommands, Parameters);

EndProcedure

// Adds a command to create a document "Merging the OS".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.MergeOfFixedAssets) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.MergeOfFixedAssets.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.MergeOfFixedAssets);
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
	
	MergeOfFixedAssetsLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	MergeOfFixedAssetsLocalization.AddPrintCommands(PrintCommands);

EndProcedure

#EndRegion

#Region InterfaceImplementation

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

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings	 - Structure - subsystem settings.
//
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

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

// Presentation of the details.
// 
// Parameters:
//  Organization - CatalogRef.Companies
// 
// Returns:
//  Map - Submission of Bank details
Function PresentationOfDetails(Organization) Export

	PresentationOfDetails = New Map;

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Organization);
	
	ComplCurrencyPresentation = "";
	If ValueIsFilled(ComplCurrency) Then
		ComplCurrencyPresentation = "(" + String(ComplCurrency) + ")";
	EndIf;
	
	ComplianceCAAccountingIsKept = NonCurrentAssetsInternal.ComplianceCAAccountingIsKept();
	
	If ComplianceCAAccountingIsKept Then
		
		PresentationOfDetails.Insert("ResidualValueMan", StrTemplate(NStr("vi = 'Giá trị thanh lý (%1)';
																			|ru = 'Ликвидационная стоимость (%1)';
																			|en = 'Residual value (%1)'; fa = 'Residual value (%1)';
																			|it = 'Costo di liquidazione (%1)';
																			|pl = 'Wartość likwidacyjna (%1)';
																			|tr = 'Artık değer (%1)'"), String(CurrencyOfMan)));
		
	Else
		
		If ComplCurrency = CurrencyOfMan Then
			PresentationOfDetails.Insert("ResidualValueMan", NStr("vi = 'Giá trị thanh lý';
																	|ru = 'Ликвидационная стоимость';
																	|en = 'Residual value'; fa = 'ارزش باقی‌مانده';
																	|it = 'Prezzo di liquidazione';
																	|pl = 'Wartość likwidacyjna';
																	|tr = 'Artık değer'"));
		Else
			PresentationOfDetails.Insert("ResidualValueMan", StrTemplate(NStr("vi = 'Giá trị thanh lý (%1)';
																				|ru = 'Ликвидационная стоимость (%1)';
																				|en = 'Residual value (%1)'; fa = 'Residual value (%1)';
																				|it = 'Costo di liquidazione (%1)';
																				|pl = 'Wartość likwidacyjna (%1)';
																				|tr = 'Artık değer (%1)'"), String(CurrencyOfMan)));
			PresentationOfDetails.Insert("ResidualValueLocal", TrimAll(StrTemplate(NStr("vi = 'Giá trị thanh lý %1';
																						|ru = 'Ликвидационная стоимость %1';
																						|en = 'Residual value %1'; fa = 'Residual value %1';
																						|it = 'Costo di liquidazione %1';
																						|pl = 'Wartość likwidacyjna %1';
																						|tr = 'Artık değer %1'"), ComplCurrencyPresentation)));
		EndIf;
		
	EndIf; 
	
	Return PresentationOfDetails;
	
EndFunction

// Returns the selection parameters of the OS.
// 
// Parameters:
// 	ProcedureParameters - Structure - 
// 	
// Returns:
// 	Structure - LongDesc:
//       * ParameterValues - Undefined, Structure -:
//           ** UsefulLifeManagementAccounting - Number - 
//           ** LineOfBusiness - CatalogRef.LinesOfBusiness -
//       * AvailableMaDepreciationParameters - Boolean -
//       * ACDepreciationParametersAreAvailable - Boolean -
//       * AccordingToMaOperatingTime - Boolean -
//       * AccordingToOperatingTimeOfAC - Boolean -
//       * FirstFAPresentation - String -
//       * ProblematicFA - Undefined -
//       * FirstFA - CatalogRef.Assets, Undefined -
//       * UsedByCF - Boolean -
Function ParametersForSelectingFixedAssets(ProcedureParameters) Export

	ParametersForSelectingFixedAssets = New Structure;
	ParametersForSelectingFixedAssets.Insert("ProblematicFA", Undefined);
	ParametersForSelectingFixedAssets.Insert("ParameterValues", Undefined);
	ParametersForSelectingFixedAssets.Insert("AccordingToMaOperatingTime", False);
	ParametersForSelectingFixedAssets.Insert("AccordingToOperatingTimeOfAC", False);
	ParametersForSelectingFixedAssets.Insert("AvailableMaDepreciationParameters", False);
	ParametersForSelectingFixedAssets.Insert("ACDepreciationParametersAreAvailable", False);
	ParametersForSelectingFixedAssets.Insert("UsedByCF", False);
	ParametersForSelectingFixedAssets.Insert("FirstFA", ?(ProcedureParameters.ListOfFA.Count() <> 0, ProcedureParameters.ListOfFA[0], Undefined));
	ParametersForSelectingFixedAssets.Insert("FirstFAPresentation", "");
	
	If ProcedureParameters.BusinessOperation = Enums.BusinessTransactions.MergeOfFixedAssets
			And ProcedureParameters.ListOfFA.Count() = 0 
		Or ProcedureParameters.BusinessOperation = Enums.BusinessTransactions.AttachingToExistingFixedAsset
			And Not ValueIsFilled(ProcedureParameters.FixedAsset)
			And ProcedureParameters.ListOfFA.Count() = 0 Then
		Return ParametersForSelectingFixedAssets;
	EndIf;
	
	QueryText = MergeOfFixedAssetsLocalization.RequestTextForFAVerification();
	
	If QueryText = Undefined Then
		
		QueryText = 
		"SELECT
		|	FALocation.FixedAsset AS FixedAsset,
		|	FALocation.Organization AS Organization,
		|	FALocation.FixedAssetsLocation AS FixedAssetsLocation
		|INTO FALocation
		|FROM
		|	InformationRegister.FALocation.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND FixedAsset IN (&ListOfAllFA)) AS FALocation
		|
		|INDEX BY
		|	FixedAsset,
		|	Organization
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	InitialFixedAssetsInformation.FixedAsset AS FixedAsset,
		|	InitialFixedAssetsInformation.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	InitialFixedAssetsInformation.AccountingProcedureAC AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA
		|INTO InitialFixedAssetsInformation
		|FROM
		|	InformationRegister.InitialFixedAssetsInformation.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND (FixedAsset, Organization) IN
		|					(SELECT
		|						FALocation.FixedAsset,
		|						FALocation.Organization
		|					FROM
		|						FALocation
		|					WHERE
		|						FALocation.FixedAsset = &FirstFA)) AS InitialFixedAssetsInformation
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FixedAssetDepreciationParametersManagementAccounting.FixedAsset AS FixedAsset,
		|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths AS UsefulLifeMonths,
		|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod AS DepreciationMethod
		|INTO FixedAssetDepreciationParametersManagementAccounting
		|FROM
		|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND (FixedAsset, Organization) IN
		|					(SELECT
		|						FALocation.FixedAsset,
		|						FALocation.Organization
		|					FROM
		|						FALocation)) AS FixedAssetDepreciationParametersManagementAccounting
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OSBUDepreciationParameters.FixedAsset AS FixedAsset,
		|	OSBUDepreciationParameters.UsefulLifeMonthsAC AS UsefulLifeMonthsAC,
		|	OSBUDepreciationParameters.UsefulLifeMonthsTA AS UsefulLifeMonthsTA
		|INTO OSBUDepreciationParameters
		|FROM
		|	InformationRegister.OSBUDepreciationParameters.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND (FixedAsset, Organization) IN
		|					(SELECT
		|						FALocation.FixedAsset,
		|						FALocation.Organization
		|					FROM
		|						FALocation)) AS OSBUDepreciationParameters
		|WHERE
		|	&RecordInLocalAccounting
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
		|	FixedAssetsAccountingProcedure.LineOfBusiness AS LineOfBusiness
		|INTO FixedAssetsAccountingProcedure
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND FixedAsset IN (&ListOfAllFA)) AS FixedAssetsAccountingProcedure
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FixedAssetsAccountingProcedureManagementAccounting.FixedAsset AS FixedAsset,
		|	FixedAssetsAccountingProcedureManagementAccounting.State AS State,
		|	FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization AS DepreciationAccrualManagementAccounting
		|INTO FixedAssetsAccountingProcedureManagementAccounting
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND (FixedAsset, Organization) IN
		|					(SELECT
		|						FALocation.FixedAsset,
		|						FALocation.Organization
		|					FROM
		|						FALocation)) AS FixedAssetsAccountingProcedureManagementAccounting
		|WHERE
		|	&RecordInManAccounting
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AccountingProcedureForOSBU.FixedAsset AS FixedAsset,
		|	AccountingProcedureForOSBU.BUState AS BUState,
		|	AccountingProcedureForOSBU.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
		|	AccountingProcedureForOSBU.DepreciationAccrualTaxAccounting AS DepreciationAccrualTaxAccounting
		|INTO AccountingProcedureForOSBU
		|FROM
		|	InformationRegister.AccountingProcedureForOSBU.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND CorrectionDate = DATETIME(1,1,1)
		|				AND (FixedAsset, Organization) IN
		|					(SELECT
		|						FALocation.FixedAsset,
		|						FALocation.Organization
		|					FROM
		|						FALocation)) AS AccountingProcedureForOSBU
		|WHERE
		|	&RecordInLocalAccounting
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	LeasedAsset.FixedAsset AS FixedAsset,
		|	LeasedAsset.Contract AS Contract
		|INTO LeasedAsset
		|FROM
		|	InformationRegister.LeasedAsset.SliceLast(
		|			&Date,
		|			Recorder <> &Ref
		|				AND FixedAsset IN
		|					(SELECT
		|						FALocation.FixedAsset
		|					FROM
		|						FALocation)) AS LeasedAsset
		|WHERE
		|	LeasedAsset.State IN (
		|		VALUE(Enum.FixedAssetsStates.LeaseContractsSigned),
		|		VALUE(Enum.FixedAssetsStates.InLease))
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|			THEN ISNULL(AccountingProcedureForFirstFA.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) 
		|		ELSE ISNULL(AccountingProcedureNewFA.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) 
		|	END AS LineOfBusiness,
		|
		|	ISNULL(FirstFA.Presentation, """") AS FirstFAPresentation,
		|
		|	CASE
		|		WHEN &Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN &Department
		|		ELSE ISNULL(FALocation.FixedAssetsLocation, UNDEFINED) 
		|	END AS FixedAssetsLocation,
		|
		|	CASE
		|		WHEN &Organization <> VALUE(Catalog.Companies.EmptyRef)
		|			THEN &Organization
		|		ELSE ISNULL(FALocation.Organization, UNDEFINED) 
		|	END AS Organization,
		|
		|	ISNULL(DepreciationParametersOfFirstOsuu.UsefulLifeMonths, 0) AS UsefulLifeManagementAccounting,
		|	ISNULL(DepreciationParametersOfFirstOSBU.UsefulLifeMonthsAC, 0) AS UsefulLifeAccounting,
		|	ISNULL(DepreciationParametersOfFirstOsuu.DepreciationMethod, 0) AS DepreciationAccrualMethodManagementAccounting,
		|	ISNULL(InitialFixedAssetsInformation.DepreciationMethodAccounting, UNDEFINED) AS DepreciationMethodAccounting,
		|	ISNULL(InitialFixedAssetsInformation.AccountingProcedureMA, UNDEFINED) AS AccountingProcedureMA,
		|	ISNULL(InitialFixedAssetsInformation.AccountingProcedureAC, UNDEFINED) AS AccountingProcedureAC,
		|
		|	ISNULL(OrderOfAccountingOfOSUOfFirstOS.DepreciationAccrualManagementAccounting, 0) AS DepreciationAccrualManagementAccounting,
		|	ISNULL(AccountingProcedureForFirstOSB.DepreciationAccrualAccounting, 0) AS DepreciationAccrualAccounting,
		|
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|			THEN ISNULL(AccountingProcedureForFirstOSB.BUState, UNDEFINED) 
		|		ELSE ISNULL(AccountingProcedureForOSBUNewOS.BUState, UNDEFINED) 
		|	END AS BUState,
		|
		|	CASE
		|		WHEN &BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|			THEN ISNULL(OrderOfAccountingOfOSUOfFirstOS.State, UNDEFINED) 
		|		ELSE ISNULL(AccountingProcedureForNewOS.State, UNDEFINED) 
		|	END AS StateOfTheUU
		|
		|INTO ParameterValues
		|FROM
		|	Catalog.Assets AS NewFA
		|
		|		LEFT JOIN Catalog.Assets AS FirstFA
		|		ON (FirstFA.Ref = &FirstFA)
		|
		|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS DepreciationParametersOfFirstOsuu
		|		ON (DepreciationParametersOfFirstOsuu.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN OSBUDepreciationParameters AS DepreciationParametersOfFirstOSBU
		|		ON (DepreciationParametersOfFirstOSBU.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
		|		ON (InitialFixedAssetsInformation.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN FALocation AS FALocation
		|		ON (FALocation.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN FixedAssetsAccountingProcedure AS AccountingProcedureNewFA
		|		ON (AccountingProcedureNewFA.FixedAsset = NewFA.Ref)
		|
		|		LEFT JOIN FixedAssetsAccountingProcedure AS AccountingProcedureForFirstFA
		|		ON (AccountingProcedureForFirstFA.FixedAsset = &FirstFA)
		|
		|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForFirstOSB
		|		ON (AccountingProcedureForFirstOSB.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS OrderOfAccountingOfOSUOfFirstOS
		|		ON (OrderOfAccountingOfOSUOfFirstOS.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBUNewOS
		|		ON (AccountingProcedureForOSBUNewOS.FixedAsset = NewFA.Ref)
		|
		|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS AccountingProcedureForNewOS
		|		ON (AccountingProcedureForNewOS.FixedAsset = NewFA.Ref)
		|
		|WHERE
		|	NewFA.Ref = &FixedAsset
		|
		|UNION ALL
		|
		|SELECT
		|	ISNULL(AccountingForFAErrors.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)),
		|	FirstFA.Presentation,
		|
		|	CASE
		|		WHEN &Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN &Department
		|		ELSE ISNULL(FALocation.FixedAssetsLocation, UNDEFINED) 
		|	END,
		|
		|	CASE
		|		WHEN &Organization <> VALUE(Catalog.Companies.EmptyRef)
		|			THEN &Organization
		|		ELSE ISNULL(FALocation.Organization, UNDEFINED) 
		|	END,
		|
		|	ISNULL(DepreciationParametersOfFirstOsuu.UsefulLifeMonths, 0),
		|	ISNULL(DepreciationParametersOfFirstOSBU.UsefulLifeMonthsAC, 0),
		|	ISNULL(DepreciationParametersOfFirstOsuu.DepreciationMethod, UNDEFINED),
		|	ISNULL(InitialFixedAssetsInformation.DepreciationMethodAccounting, UNDEFINED),
		|	ISNULL(InitialFixedAssetsInformation.AccountingProcedureMA, UNDEFINED),
		|	ISNULL(InitialFixedAssetsInformation.AccountingProcedureAC, UNDEFINED),
		|	ISNULL(OrderOfAccountingOfOSUOfFirstOS.DepreciationAccrualManagementAccounting, 0) AS DepreciationAccrualManagementAccounting,
		|	ISNULL(AccountingProcedureForFirstOSB.DepreciationAccrualAccounting, 0) AS DepreciationAccrualAccounting,
		|	ISNULL(AccountingProcedureForFirstOSB.BUState, UNDEFINED),
		|	ISNULL(OrderOfAccountingOfOSUOfFirstOS.State, UNDEFINED)
		|
		|FROM
		|	Catalog.Assets AS FirstFA
		|
		|		LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS DepreciationParametersOfFirstOsuu
		|		ON (DepreciationParametersOfFirstOsuu.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN OSBUDepreciationParameters AS DepreciationParametersOfFirstOSBU
		|		ON (DepreciationParametersOfFirstOSBU.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN InitialFixedAssetsInformation AS InitialFixedAssetsInformation
		|		ON (InitialFixedAssetsInformation.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN FALocation AS FALocation
		|		ON (FALocation.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN FixedAssetsAccountingProcedure AS AccountingForFAErrors
		|		ON (AccountingForFAErrors.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForFirstOSB
		|		ON (AccountingProcedureForFirstOSB.FixedAsset = FirstFA.Ref)
		|
		|		LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS OrderOfAccountingOfOSUOfFirstOS
		|		ON (OrderOfAccountingOfOSUOfFirstOS.FixedAsset = FirstFA.Ref)
		|
		|WHERE
		|	FirstFA.Ref = &FirstFA
		|	AND &FixedAsset = VALUE(Catalog.Assets.EmptyRef)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NodesComponents.SubAssetComponent,
		|	NodesComponents.FixedAsset
		|INTO NodesComponentsOfAllFA
		|FROM
		|	InformationRegister.SubAssetsComponentsOfDepreciation.SliceLast(&Date, SubAssetComponent IN(&ListOfAllFA)) AS NodesComponents
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	NodesComponentsOfTable.SubAssetComponent AS SubAssetComponent,
		|	TRUE AS FAOwnerDoesNotMatch
		|INTO ComponentNodeInconsistencies
		|FROM
		|	NodesComponentsOfAllFA AS NodesComponentsOfHeader
		|		INNER JOIN NodesComponentsOfAllFA AS NodesComponentsOfTable
		|		ON NodesComponentsOfHeader.FixedAsset <> NodesComponentsOfTable.FixedAsset
		|WHERE
		|	NodesComponentsOfHeader.SubAssetComponent = &FixedAsset
		|	AND NodesComponentsOfTable.SubAssetComponent IN (&ListOfFA)
		|
		|UNION ALL
		|
		|SELECT
		|	NodesComponentsOfTable.SubAssetComponent AS SubAssetComponent,
		|	TRUE AS FAOwnerDoesNotMatch
		|FROM
		|	NodesComponentsOfAllFA AS NodesComponentsOfTable
		|WHERE
		|	NodesComponentsOfTable.SubAssetComponent IN (&ListOfFA)
		|	AND NodesComponentsOfTable.FixedAsset <> &FixedAsset
		|	AND CAST(&FixedAsset AS Catalog.Assets).OSType IN
		|	(VALUE(Enum.FATypes.Asset), VALUE(Enum.FATypes.GroupFA))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ParameterValues.FirstFAPresentation AS FirstFAPresentation,
		|	ParameterValues.LineOfBusiness AS LineOfBusiness,
		|	ParameterValues.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
		|	ParameterValues.UsefulLifeAccounting AS UsefulLifeAccounting,
		|	ParameterValues.DepreciationAccrualMethodManagementAccounting AS DepreciationAccrualMethodManagementAccounting,
		|	ParameterValues.DepreciationMethodAccounting AS DepreciationMethodAccounting,
		|	ParameterValues.AccountingProcedureAC AS AccountingProcedureAC,
		|	ParameterValues.AccountingProcedureMA AS AccountingProcedureMA,
		|	ParameterValues.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
		|	ParameterValues.DepreciationAccrualManagementAccounting AS DepreciationAccrualManagementAccounting
		|FROM
		|	ParameterValues AS ParameterValues
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CheckResult.FixedAsset AS FixedAsset,
		|	CheckResult.FixedAssetPresentation AS FixedAssetPresentation,
		|	CheckResult.LineOfBusiness AS LineOfBusiness,
		|	CheckResult.LineOfBusiness.Presentation AS LineOfBusinessPresentation,
		|	CheckResult.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
		|
		|	CheckResult.MainDirectionOfActivity AS MainDirectionOfActivity,
		|	CheckResult.DifferentLocation AS DifferentLocation,
		|	CheckResult.TermOfUseOfMaDiffers AS TermOfUseOfMaDiffers,
		|	CheckResult.PeriodOfUseOfBUDiffers AS PeriodOfUseOfBUDiffers,
		|	CheckResult.FAOwnerDoesNotMatch AS FAOwnerDoesNotMatch,
		|	CheckResult.UnderLeaseAgreement AS UnderLeaseAgreement,
		|	CheckResult.NotAcceptedByUU AS NotAcceptedByUU,
		|	CheckResult.NotAcceptedBU AS NotAcceptedBU,
		|	CheckResult.AcceptedByUU AS AcceptedByUU,
		|	CheckResult.AcceptedBU AS AcceptedBU
		|
		|FROM
		|	(SELECT
		|		SourceFA.Ref AS FixedAsset,
		|		SourceFA.Presentation AS FixedAssetPresentation,
		|		ParameterValues.LineOfBusiness AS LineOfBusiness,
		|		ParameterValues.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
		|
		|		(&MergeOfSimilarFixedAssets
		|				AND &BusinessOperation = VALUE(Enum.BusinessTransactions.AttachingToExistingFixedAsset)
		|				AND ISNULL(AccountingProcedureSourceFA.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> ParameterValues.LineOfBusiness
		|			OR NOT &MergeOfSimilarFixedAssets
		|				AND ISNULL(AccountingProcedureSourceFA.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> ParameterValues.LineOfBusiness
		|				AND ISNULL(AccountingProcedureSourceFA.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)) <> VALUE(Catalog.LinesOfBusiness.EmptyRef)) AS MainDirectionOfActivity,
		|
		|		ISNULL(FALocation.Organization, UNDEFINED) <> ParameterValues.Organization
		|			OR ISNULL(FALocation.FixedAssetsLocation, UNDEFINED) <> ParameterValues.FixedAssetsLocation AS DifferentLocation,
		|
		|		&RecordInManAccounting
		|			AND ISNULL(FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths, 0) <> ParameterValues.UsefulLifeManagementAccounting
		|			AND NOT SourceFA.OSType IN (&TypesOfComponentNodes) AS TermOfUseOfMaDiffers,
		|
		|		&RecordInLocalAccounting
		|			AND ISNULL(OSBUDepreciationParameters.UsefulLifeMonthsAC, 0) <> ParameterValues.UsefulLifeAccounting
		|			AND NOT SourceFA.OSType IN (&TypesOfComponentNodes) AS PeriodOfUseOfBUDiffers,
		|
		|		ISNULL(ComponentNodeInconsistencies.FAOwnerDoesNotMatch, FALSE) AS FAOwnerDoesNotMatch,
		|
		|		CASE
		|			WHEN LeasedAsset.Contract REFS Catalog.LeaseContract
		|					AND ISNULL(LeasedAsset.Contract, VALUE(Catalog.LeaseContract.EmptyRef)) <> VALUE(Catalog.LeaseContract.EmptyRef)
		|				THEN TRUE
		|			ELSE FALSE
		|		END AS UnderLeaseAgreement,
		|
		|		&RecordInManAccounting
		|			AND ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) <> VALUE(Enum.FixedAssetsStates.Recognized_)
		|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets) AS NotAcceptedByUU,
		|
		|		&RecordInLocalAccounting
		|			AND ParameterValues.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			AND ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) <> VALUE(Enum.FixedAssetsStates.Recognized_)
		|			AND &BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets) AS NotAcceptedBU,
		|
		|		&RecordInManAccounting
		|			AND ParameterValues.StateOfTheUU <> VALUE(Enum.FixedAssetsStates.Recognized_)
		|			AND ISNULL(FixedAssetsAccountingProcedureManagementAccounting.State, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_) AS AcceptedByUU,
		|
		|		&RecordInLocalAccounting
		|			AND ParameterValues.BUState <> VALUE(Enum.FixedAssetsStates.Recognized_)
		|			AND ISNULL(AccountingProcedureForOSBU.BUState, UNDEFINED) = VALUE(Enum.FixedAssetsStates.Recognized_) AS AcceptedBU
		|
		|	FROM
		|		Catalog.Assets AS SourceFA
		|
		|			LEFT JOIN ParameterValues AS ParameterValues
		|			ON (TRUE)
		|
		|			LEFT JOIN OSBUDepreciationParameters AS OSBUDepreciationParameters
		|			ON (OSBUDepreciationParameters.FixedAsset = SourceFA.Ref)
		|
		|			LEFT JOIN FixedAssetDepreciationParametersManagementAccounting AS FixedAssetDepreciationParametersManagementAccounting
		|			ON (FixedAssetDepreciationParametersManagementAccounting.FixedAsset = SourceFA.Ref)
		|
		|			LEFT JOIN AccountingProcedureForOSBU AS AccountingProcedureForOSBU
		|			ON (AccountingProcedureForOSBU.FixedAsset = SourceFA.Ref)
		|
		|			LEFT JOIN FixedAssetsAccountingProcedureManagementAccounting AS FixedAssetsAccountingProcedureManagementAccounting
		|			ON (FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = SourceFA.Ref)
		|
		|			LEFT JOIN FALocation AS FALocation
		|			ON (FALocation.FixedAsset = SourceFA.Ref)
		|
		|			LEFT JOIN FixedAssetsAccountingProcedure AS AccountingProcedureSourceFA
		|			ON (AccountingProcedureSourceFA.FixedAsset = SourceFA.Ref)
		|
		|			LEFT JOIN LeasedAsset AS LeasedAsset
		|			ON (LeasedAsset.FixedAsset = SourceFA.Ref)
		|
		|			LEFT JOIN ComponentNodeInconsistencies AS ComponentNodeInconsistencies
		|			ON (ComponentNodeInconsistencies.SubAssetComponent = SourceFA.Ref)
		|	WHERE
		|		SourceFA.Ref IN(&ListOfFA)
		|
		|	) AS CheckResult
		|
		|WHERE
		|	(CheckResult.MainDirectionOfActivity
		|		OR CheckResult.DifferentLocation
		|		OR CheckResult.TermOfUseOfMaDiffers
		|		OR CheckResult.PeriodOfUseOfBUDiffers
		|		OR CheckResult.FAOwnerDoesNotMatch
		|		OR CheckResult.UnderLeaseAgreement
		|		OR CheckResult.NotAcceptedByUU
		|		OR CheckResult.NotAcceptedBU
		|		OR CheckResult.AcceptedByUU
		|		OR CheckResult.AcceptedBU)";
		
	EndIf; 
	
	Query = New Query(QueryText);
	Query.SetParameter("Date", ?(ProcedureParameters.Date <> '000101010000', ProcedureParameters.Date, CurrentSessionDate()));
	Query.SetParameter("ListOfFA", ProcedureParameters.ListOfFA);
	Query.SetParameter("Organization", ProcedureParameters.Organization);
	Query.SetParameter("Department", ProcedureParameters.FixedAssetsLocation);
	Query.SetParameter("MergeOfSimilarFixedAssets", ProcedureParameters.MergeOfSimilarFixedAssets);
	Query.SetParameter("Ref", ProcedureParameters.Ref);
	Query.SetParameter("FirstFA", ParametersForSelectingFixedAssets.FirstFA);
	Query.SetParameter("FixedAsset", ProcedureParameters.FixedAsset);
	Query.SetParameter("RecordInManAccounting", ProcedureParameters.RecordInManAccounting);
	Query.SetParameter("RecordInLocalAccounting", ProcedureParameters.RecordInLocalAccounting);
	Query.SetParameter("BusinessOperation", ProcedureParameters.BusinessOperation);
	
	ArrayOfFATypes = New Array;
	ArrayOfFATypes.Add(Enums.FATypes.Node);
	ArrayOfFATypes.Add(Enums.FATypes.DepreciationComponent);
	Query.SetParameter("TypesOfComponentNodes", ArrayOfFATypes);
	
	ListOfAllFA = CommonClientServer.CopyArray(ProcedureParameters.ListOfFA);
	If ValueIsFilled(ProcedureParameters.FixedAsset) Then
		ListOfAllFA.Add(ProcedureParameters.FixedAsset);
	EndIf; 
	Query.SetParameter("ListOfAllFA", ListOfAllFA);
	
	Result = Query.ExecuteBatch();
	Selection_Parameters = Result[Result.UBound()-1].Select();
	Selection_Parameters.Next();
	
	ProblematicFA = ?(Not Result[Result.UBound()].IsEmpty(), Result[Result.UBound()].Unload(), Undefined);
	ParametersForSelectingFixedAssets.Insert("ProblematicFA", ProblematicFA);
	
	ParametersForSelectingFixedAssets.Insert("FirstFAPresentation", Selection_Parameters.FirstFAPresentation);
	
	AccordingToMaOperatingTime = (Selection_Parameters.DepreciationAccrualMethodManagementAccounting = Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction);
	ParametersForSelectingFixedAssets.Insert("AccordingToMaOperatingTime", AccordingToMaOperatingTime);
	
	ParametersForSelectingFixedAssets.Insert("AvailableMaDepreciationParameters", Selection_Parameters.DepreciationAccrualManagementAccounting);
	ParametersForSelectingFixedAssets.Insert("ACDepreciationParametersAreAvailable", Selection_Parameters.DepreciationAccrualAccounting);
	
	ParameterValues = New Structure;
	ParameterValues.Insert("LineOfBusiness", Selection_Parameters.LineOfBusiness);
	ParameterValues.Insert("UsefulLifeManagementAccounting", Selection_Parameters.UsefulLifeManagementAccounting);
	ParameterValues.Insert("UsefulLifeAccounting", Selection_Parameters.UsefulLifeAccounting);
	ParameterValues.Insert("AccountingProcedureAC", Selection_Parameters.AccountingProcedureAC);
	ParametersForSelectingFixedAssets.Insert("ParameterValues", ParameterValues);
	
	MergeOfFixedAssetsLocalization.AddParametersForSelectingFixedAssets(Selection_Parameters, ParametersForSelectingFixedAssets);
	
	Return ParametersForSelectingFixedAssets;

EndFunction

#EndRegion

#Region Private

#Region Posting

Function FullObjectName()

	Return "Document.MergeOfFixedAssets";

EndFunction

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = FullObjectName();
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
	|	DocumentData.Number AS Number
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
	
	Query.SetParameter("BorderInFrontOfDocument", New Boundary(Attributes.Period, BoundaryType.Excluding));

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
	|	Document.MergeOfFixedAssets AS DocumentsList
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
	|	DocumentData.Ref AS Ref,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Period,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.LocationAddress AS LocationAddress,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.AccelerationFactorManagementAccounting AS AccelerationFactorManagementAccounting,
	|	DocumentData.ResidualValueMan AS ResidualValueMan,
	|	DocumentData.ResidualValueLocal AS ResidualValueLocal,
	|	DocumentData.Department AS Department,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationAccrualMethodManagementAccounting,
	|	DocumentData.FinanciallyLiablePerson AS FinanciallyLiablePerson,
	|	DocumentData.DepreciationMethodAccounting AS DepreciationMethodAccounting,
	|	DocumentData.DepreciationAccrualManagementAccounting AS DepreciationAccrualManagementAccounting,
	|	DocumentData.MergeOfSimilarFixedAssets AS MergeOfSimilarFixedAssets,
	|	DocumentData.EstimatedRunningTime AS EstimatedRunningTime,
	|	DocumentData.ResidualEstimatedRunningTime AS ResidualEstimatedRunningTime,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany,
	|	DocumentData.FixedAsset AS FixedAsset,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.RecordInLocalAccounting AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting AS RecordInManAccounting,
	|	DocumentData.RunningTimeValue AS RunningTimeValue,
	|	DocumentData.AccountingProcedureAC AS AccountingProcedureAC,
	|	DocumentData.AccountingProcedureMA AS AccountingProcedureMA,
	|	DocumentData.FixedAssetsEvent AS FixedAssetsEvent,
	|	DocumentData.ResidualUsefulLifeAccounting_ AS ResidualUsefulLifeAccounting_,
	|	DocumentData.ResidualUsefulLifeManagementAccounting_ AS ResidualUsefulLifeManagementAccounting_,
	|	DocumentData.UsefulLifeAccounting AS UsefulLifeAccounting,
	|	DocumentData.UsefulLifeManagementAccounting AS UsefulLifeManagementAccounting,
	|	DocumentData.ExpenseRecordMethodAC AS ExpenseRecordMethodAC,
	|	DocumentData.ExpenseItemAccounting AS ExpenseItemAccounting,
	|	DocumentData.ExpensesDimensionAccounting AS ExpensesDimensionAccounting,
	|	DocumentData.DepartmentACC AS DepartmentACC,
	|	DocumentData.LineOfBusinessBookkeeping AS LineOfBusinessBookkeeping,
	|	DocumentData.DepreciationAccrualAccounting AS DepreciationAccrualAccounting,
	|
	|	CASE WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			AND DocumentData.RecordInManAccounting
	|			AND DocumentData.RecordInLocalAccounting
	|		THEN DocumentData.ExpenseRecordMethodAC
	|		ELSE DocumentData.MethodForReflectingMaExpenses 
	|	END AS MethodForReflectingMaExpenses,
	|
	|	CASE WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			AND DocumentData.RecordInManAccounting
	|			AND DocumentData.RecordInLocalAccounting
	|		THEN DocumentData.ExpenseItemAccounting
	|		ELSE DocumentData.ExpenseItemManagementAccounting 
	|	END AS ExpenseItemManagementAccounting,
	|
	|	CASE WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			AND DocumentData.RecordInManAccounting
	|			AND DocumentData.RecordInLocalAccounting
	|		THEN DocumentData.ExpensesDimensionAccounting
	|		ELSE DocumentData.ExpensesDimensionManagementAccounting 
	|	END AS ExpensesDimensionManagementAccounting,
	|
	|	CASE WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			AND DocumentData.RecordInManAccounting
	|			AND DocumentData.RecordInLocalAccounting
	|		THEN DocumentData.DepartmentACC
	|		ELSE DocumentData.BusinessUnitManagementAccounting 
	|	END AS BusinessUnitManagementAccounting,
	|
	|	CASE WHEN DocumentData.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|			AND DocumentData.RecordInManAccounting
	|			AND DocumentData.RecordInLocalAccounting
	|		THEN DocumentData.LineOfBusinessBookkeeping
	|		ELSE DocumentData.LineOfBusinessManagementAccounting 
	|	END AS LineOfBusinessManagementAccounting,
	|
	|	DocumentData.AccelerationFactorAccounting AS AccelerationFactorAccounting,
	|	DocumentData.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueWearAsPerUFADR) AS AccrueDepreciation,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.CGU AS CGU,
	|	FATable.FixedAsset AS FirstFA,
	|	DocumentData.TransferExpensesToAnotherCompany AS TransferExpensesToAnotherCompany,
	|	DocumentData.CompanyRecipientOfExpenses AS CompanyRecipientOfExpenses,
	|	&CombiningOS_DocumentDetails
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.MergeOfFixedAssets AS DocumentData
	|
	|		LEFT JOIN Document.MergeOfFixedAssets.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|			AND FATable.LineNumber = 1
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
	MergeOfFixedAssetsLocalization.AddDocumentDetailsToRequestText(QueryText, "DocumentData");
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region DocumentDataFATable
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.LineNumber AS LineNumber
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.MergeOfFixedAssets.FA AS DocumentTable
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
	
	#Region DocumentDataTableTraceableGoods
	QueryText =
	"SELECT
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.FixedAsset AS AccountingObject,
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.CCDNumber AS CCDNumber,
	|	DocumentTable.FEACNCode AS FEACNCode,
	|	DocumentTable.QuantityByGBRN AS QuantityByGBRN
	|
	|INTO DocumentDataTableTraceableGoods
	|
	|FROM
	|	Document.MergeOfFixedAssets.TraceableGoods AS DocumentTable
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID(FullObjectName()));
	ValuesOfHoldingParameters.Insert("ArticleAP_OS", ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets);
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Hợp nhất TSCĐ';
															|ru = 'Объединение ОС';
															|en = 'Merge fixed assets'; fa = 'ادغام دارایی‌های ثابت';
															|it = 'Unione di capitali fissi';
															|pl = 'Połączenie ŚT';
															|tr = 'SV birleşmesi'"));
	
	ValuesOfHoldingParameters.Insert("SettingUpHO_Cost", Catalogs.BusinessTransactionsSettings.FixedAssetsCostParameterChange);
	ValuesOfHoldingParameters.Insert("SettingUpHO_Depreciation", Catalogs.BusinessTransactionsSettings.FixedAssetDepreciationParameterChange);
	ValuesOfHoldingParameters.Insert("SettingUpHO_ReclassificationOfFA", Catalogs.BusinessTransactionsSettings.ReclassificationOfFA);
	ValuesOfHoldingParameters.Insert("SettingUpHO_RecoveryOfImpairment", Catalogs.BusinessTransactionsSettings.ReversalOfFAImpairment);

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
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
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
	|	Document.MergeOfFixedAssets AS DocumentData
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
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting      AS RecordInTA,
	|	DocumentData.FixedAsset        AS FixedAsset
	|
	|FROM
	|	Document.MergeOfFixedAssets AS DocumentData
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
	|	DocumentData.FixedAssetsEvent               AS FixedAssetsEvent,
	|	&MetadataIdentifier                AS RefType,
	|	DocumentData.Posted                AS Posted,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting,
	|	DocumentData.RecordInLocalAccounting      AS RecordInTA,
	|	FATable.FixedAsset              AS FixedAsset
	|
	|FROM
	|	Document.MergeOfFixedAssets AS DocumentData
	|
	|		LEFT JOIN Document.MergeOfFixedAssets.FA AS FATable
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

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                       AS Recorder,
	|	DocumentData.Period                       AS Period,
	|	DocumentData.Organization                  AS Organization,
	|	DocumentData.FixedAsset             AS FixedAsset,
	|	DocumentData.FinanciallyLiablePerson                          AS FinanciallyLiablePerson,
	|	DocumentData.Department                AS FixedAssetsLocation,
	|	DocumentData.LocationAddress         AS LocationAddress,
	|	DocumentData.RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting            AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);

	ListOfRequests = New Array;
	
	#Region MergeOfSimilarFixedAssets
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.FixedAsset        AS FixedAsset,
	|	FixedAssetsAccountingProcedure.LineOfBusiness  AS LineOfBusiness,
	|	FixedAssetsAccountingProcedure.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	FixedAssetsAccountingProcedure.RunningTimeValue      AS RunningTimeValue,
	|	FixedAssetsAccountingProcedure.EstimatedRunningTime           AS EstimatedRunningTime,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FirstFA
	|
	|WHERE
	|	DocumentData.MergeOfSimilarFixedAssets
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	#Region CombiningFASystemsThatAreNotOfSameType
	QueryText =
	"SELECT
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.FixedAsset        AS FixedAsset,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|	DocumentData.RunningTimeValue     AS RunningTimeValue,
	|	DocumentData.EstimatedRunningTime          AS EstimatedRunningTime,
	|	DocumentData.RecordInLocalAccounting      AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting       AS RecordInManAccounting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	NOT DocumentData.MergeOfSimilarFixedAssets
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
	|";
	ListOfRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfRequests, TMCommonUse.QuerySeparatorInJoin());
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTueAccountingProcedureForOSBU(QueryTexts);
	
	QueryText = MergeOfFixedAssetsLocalization.QueryTextTableAccountingProcedureForOSBU();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
	
		ListOfMergeRequests = New Array;

		#Region AcceptanceForAccountingIsNotOfSameTypeLocalIndependent
		QueryText =
		"SELECT
		|	DocumentData.Ref                   AS Recorder,
		|	DocumentData.Period                   AS Period,
		|	DocumentData.Organization              AS Organization,
		|	DocumentData.FixedAsset         AS FixedAsset,
		|
		|	RegisterData.BUState               AS BUState,
		|
		|	CASE
		|		WHEN RegisterData.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			THEN DocumentData.DepreciationAccrualAccounting
		|		ELSE FALSE
		|	END AS DepreciationAccrualAccounting,
		|	
		|	CASE
		|		WHEN RegisterData.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			THEN DocumentData.ExpenseRecordMethodAC
		|		ELSE FALSE
		|	END AS ExpenseRecordMethodAC,
		|	
		|	CASE
		|		WHEN RegisterData.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			THEN DocumentData.ExpenseItemAccounting
		|		ELSE UNDEFINED
		|	END AS ExpenseItemAccounting,
		|	
		|	CASE
		|		WHEN RegisterData.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			THEN DocumentData.ExpensesDimensionAccounting
		|		ELSE UNDEFINED
		|	END AS ExpensesDimensionAccounting,
		|
		|	CASE
		|		WHEN RegisterData.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			THEN DocumentData.DepartmentACC
		|		ELSE UNDEFINED
		|	END AS DepartmentACC,
		|
		|	CASE
		|		WHEN RegisterData.BUState = VALUE(Enum.FixedAssetsStates.Recognized_)
		|			THEN DocumentData.LineOfBusinessBookkeeping
		|		ELSE UNDEFINED
		|	END AS LineOfBusinessBookkeeping,
		|
		|	UNDEFINED AS DepreciationRecordMethodLA,
		|	
		|	DocumentData.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS RegisterData
		|		ON RegisterData.Ref = DocumentData.Ref
		|			AND RegisterData.FixedAsset = DocumentData.FirstFA
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND NOT DocumentData.MergeOfSimilarFixedAssets
		|	AND DocumentData.RecordInLocalAccounting
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion
		
		#Region AcceptanceForAccountingIsNotSameLocalRules
		QueryText =
		"SELECT
		|	DocumentData.Ref                    AS Recorder,
		|	DocumentData.Period                    AS Period,
		|	DocumentData.Organization               AS Organization,
		|	DocumentData.FixedAsset          AS FixedAsset,
		|
		|	RegisterData.BUState                AS BUState,
		|
		|	DocumentData.DepreciationAccrualManagementAccounting    AS DepreciationAccrualAccounting,
		|	DocumentData.MethodForReflectingMaExpenses AS ExpenseRecordMethodAC,
		|	DocumentData.ExpenseItemManagementAccounting          AS ExpenseItemAccounting,
		|	DocumentData.ExpensesDimensionManagementAccounting       AS ExpensesDimensionAccounting,
		|	DocumentData.BusinessUnitManagementAccounting           AS DepartmentACC,
		|	DocumentData.LineOfBusinessManagementAccounting AS LineOfBusinessBookkeeping,
		|	UNDEFINED                              AS DepreciationRecordMethodLA,
		|	
		|	DocumentData.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
		|	DocumentData.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS RegisterData
		|		ON RegisterData.Ref = DocumentData.Ref
		|			AND RegisterData.FixedAsset = DocumentData.FirstFA
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND NOT DocumentData.MergeOfSimilarFixedAssets
		|	AND DocumentData.RecordInLocalAccounting
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion

		#Region AcceptanceForAccountingOfSameType
		QueryText =
		"SELECT
		|	DocumentData.Ref                      AS Recorder,
		|	DocumentData.Period                      AS Period,
		|	DocumentData.Organization                 AS Organization,
		|	DocumentData.FixedAsset            AS FixedAsset,
		|	RegisterData.BUState                  AS BUState,
		|	RegisterData.DepreciationAccrualAccounting       AS DepreciationAccrualAccounting,
		|	RegisterData.ExpenseRecordMethodAC    AS ExpenseRecordMethodAC,
		|	RegisterData.ExpenseItemAccounting             AS ExpenseItemAccounting,
		|	RegisterData.ExpensesDimensionAccounting          AS ExpensesDimensionAccounting,
		|	RegisterData.DepartmentACC              AS DepartmentACC,
		|	RegisterData.LineOfBusinessBookkeeping    AS LineOfBusinessBookkeeping,
		|	RegisterData.DepreciationRecordMethodLA AS DepreciationRecordMethodLA,
		|	RegisterData.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
		|	RegisterData.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TueAccountingProcedureForOSBU AS RegisterData
		|		ON RegisterData.Ref = DocumentData.Ref
		|			AND RegisterData.FixedAsset = DocumentData.FirstFA
		|
		|WHERE
		|	DocumentData.MergeOfSimilarFixedAssets
		|	AND DocumentData.RecordInLocalAccounting
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|";		
		ListOfMergeRequests.Add(QueryText);
		#EndRegion
		
		#Region Derecognition
		QueryText =
		"SELECT
		|	DocumentData.Ref                   AS Recorder,
		|	DocumentData.Period                   AS Period,
		|	DocumentData.Organization              AS Organization,
		|	FATable.FixedAsset               AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS BUState,
		|	FALSE                                     AS DepreciationAccrualAccounting,
		|	UNDEFINED                             AS ExpenseRecordMethodAC,
		|	UNDEFINED                             AS ExpenseItemAccounting,
		|	UNDEFINED                             AS ExpensesDimensionAccounting,
		|	UNDEFINED                             AS DepartmentACC,
		|	UNDEFINED                             AS LineOfBusinessBookkeeping,
		|	UNDEFINED                             AS DepreciationRecordMethodLA,
		|	FALSE                                     AS TransferExpensesToAnotherCompany,
		|	UNDEFINED                             AS CompanyRecipientOfExpenses
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion
		
		QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingProcedureForOsuu(QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region AcceptanceForAccountingIsNotOfSameType
	QueryText =
	"SELECT
	|	DocumentData.Ref                                  AS Recorder,
	|	DocumentData.Period                                  AS Period,
	|	DocumentData.Organization                             AS Organization,
	|	DocumentData.FixedAsset                        AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_)        AS State,
	|	DocumentData.DepreciationAccrualManagementAccounting                  AS AccrueDepreciationOrAmortization,
	|	UNDEFINED                                            AS DepreciationRecordMethod,
	|	DocumentData.MethodForReflectingMaExpenses               AS ExpensesPostingMethod,
	|	DocumentData.ExpenseItemManagementAccounting                        AS ExpenseItem,
	|	DocumentData.ExpensesDimensionManagementAccounting                     AS DimensionOfExpenses,
	|	DocumentData.BusinessUnitManagementAccounting                         AS Department,
	|	DocumentData.LineOfBusinessManagementAccounting               AS LineOfBusiness,
	|	DocumentData.TransferExpensesToAnotherCompany     AS TransferExpensesToAnotherCompany,
	|	DocumentData.CompanyRecipientOfExpenses           AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|WHERE
	|	NOT DocumentData.MergeOfSimilarFixedAssets
	|	AND DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region AcceptanceForAccountingOfSameType
	QueryText =
	"SELECT
	|	DocumentData.Ref                                  AS Recorder,
	|	DocumentData.Period                                  AS Period,
	|	DocumentData.Organization                             AS Organization,
	|	DocumentData.FixedAsset                        AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_)        AS State,
	|	FixedAssetsAccountingProcedureManagementAccounting.AccrueDepreciationOrAmortization                   AS AccrueDepreciationOrAmortization,
	|	FixedAssetsAccountingProcedureManagementAccounting.DepreciationRecordMethod             AS DepreciationRecordMethod,
	|	FixedAssetsAccountingProcedureManagementAccounting.ExpensesPostingMethod                AS ExpensesPostingMethod,
	|	FixedAssetsAccountingProcedureManagementAccounting.ExpenseItem                         AS ExpenseItem,
	|	FixedAssetsAccountingProcedureManagementAccounting.DimensionOfExpenses                      AS DimensionOfExpenses,
	|	FixedAssetsAccountingProcedureManagementAccounting.Department                          AS Department,
	|	FixedAssetsAccountingProcedureManagementAccounting.LineOfBusiness                AS LineOfBusiness,
	|	FixedAssetsAccountingProcedureManagementAccounting.TransferExpensesToAnotherCompany    AS TransferExpensesToAnotherCompany,
	|	FixedAssetsAccountingProcedureManagementAccounting.CompanyRecipientOfExpenses          AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTAccountingProcedureForOsuu AS FixedAssetsAccountingProcedureManagementAccounting
	|		ON FixedAssetsAccountingProcedureManagementAccounting.Ref = DocumentData.Ref
	|			AND FixedAssetsAccountingProcedureManagementAccounting.FixedAsset = DocumentData.FirstFA
	|
	|WHERE
	|	DocumentData.MergeOfSimilarFixedAssets
	|	AND DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region Derecognition
	QueryText =
	"SELECT
	|	DocumentData.Ref                                  AS Recorder,
	|	DocumentData.Period                                  AS Period,
	|	DocumentData.Organization                             AS Organization,
	|	FATable.FixedAsset                              AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks)          AS State,
	|	FALSE                                                    AS AccrueDepreciationOrAmortization,
	|	UNDEFINED                                            AS DepreciationRecordMethod,
	|	UNDEFINED                                            AS ExpensesPostingMethod,
	|	UNDEFINED                                            AS ExpenseItem,
	|	UNDEFINED                                            AS DimensionOfExpenses,
	|	UNDEFINED                                            AS Department,
	|	UNDEFINED                                            AS LineOfBusiness,
	|	FALSE                                                    AS TransferExpensesToAnotherCompany,
	|	UNDEFINED                                            AS CompanyRecipientOfExpenses
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(Query, QueryTexts, Registers)
	
	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTIsListOfAllFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableWDepreciationParametersOfOSBU(QueryTexts, "TTIsListOfAllFA");
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts, "TTIsListOfAllFA");
	NonCurrentAssetsInternal.QueryTextTableTTOperatingTimeOfObjectsOfOperation(QueryTexts, "TTIsListOfAllFA");
	QueryTextTTCostOfOriginalFA(Query, QueryTexts);
	QueryTextTTDepreciationOfOriginalFA(Query, QueryTexts);
	
	QueryText = MergeOfFixedAssetsLocalization.QueryTextTableOSBUDepreciationParameters();
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);

		ListOfMergeRequests = New Array;
		
		#Region AcceptanceForAccountingIsNotOfSameType
		QueryText =
		"SELECT
		|	DocumentData.Ref                         AS Recorder,
		|	DocumentData.Period                         AS Period,
		|	DocumentData.Period                         AS LastChangeDate,
		|	DocumentData.Organization                    AS Organization,
		|	DocumentData.FixedAsset               AS FixedAsset,
		|
		|	CASE
		|		WHEN ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|			THEN DocumentData.UsefulLifeAccounting
		|		ELSE DocumentData.UsefulLifeManagementAccounting
		|	END AS UsefulLifeMonthsAC,
		|
		|	CASE
		|		WHEN ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|			THEN DocumentData.AccelerationFactorAccounting
		|		ELSE DocumentData.AccelerationFactorManagementAccounting
		|	END AS AccelerationFactor,
		|
		|	DocumentData.ResidualValueLocal    AS ResidualValueMan,
		|	DocumentData.ResidualEstimatedRunningTime       AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	CASE
		|		WHEN ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|			THEN DocumentData.ResidualUsefulLifeAccounting_
		|		ELSE DocumentData.ResidualUsefulLifeManagementAccounting_
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	ISNULL(CostOfVNA.LocalCost, 0) 
		|		- ISNULL(DepreciationOfVNA.DepreciationLocal, 0) AS CostUsedToCalculateDepreciationManag
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTCostOfOriginalFA AS CostOfVNA
		|		ON CostOfVNA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTDepreciationOfOriginalFA AS DepreciationOfVNA
		|		ON DepreciationOfVNA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	NOT DocumentData.MergeOfSimilarFixedAssets
		|	AND DocumentData.RecordInLocalAccounting
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion
		
		#Region AcceptanceForAccountingOfSameType
		QueryText =
		"SELECT
		|	DocumentData.Ref                        AS Recorder,
		|	DocumentData.Period                        AS Period,
		|	DocumentData.Period                        AS LastChangeDate,
		|	DocumentData.Organization                   AS Organization,
		|	DocumentData.FixedAsset              AS FixedAsset,
		|	RegisterData.UsefulLifeMonthsAC   AS UsefulLifeMonthsAC,
		|	RegisterData.AccelerationFactor           AS AccelerationFactor,
		|	RegisterData.ResidualValueMan        AS ResidualValueMan,
		|	DocumentData.ResidualEstimatedRunningTime      AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	CASE
		|		WHEN ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|			THEN DocumentData.ResidualUsefulLifeAccounting_
		|		ELSE DocumentData.ResidualUsefulLifeManagementAccounting_
		|	END AS UsefulLifeForCalculatingDepreciationMonth,
		|
		|	ISNULL(CostOfVNA.LocalCost, 0) 
		|		- ISNULL(DepreciationOfVNA.DepreciationLocal, 0) AS CostUsedToCalculateDepreciationManag
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN WDepreciationParametersOfOSBU AS RegisterData
		|		ON RegisterData.Ref = DocumentData.Ref
		|			AND RegisterData.FixedAsset = DocumentData.FirstFA
		|
		|		LEFT JOIN TTCostOfOriginalFA AS CostOfVNA
		|		ON CostOfVNA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTDepreciationOfOriginalFA AS DepreciationOfVNA
		|		ON DepreciationOfVNA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.MergeOfSimilarFixedAssets
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.RecordInLocalAccounting
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion
		
		#Region AttachingToExistingFixedAsset
		QueryText =
		"SELECT
		|	DocumentData.Ref                        AS Recorder,
		|	DocumentData.Period                        AS Period,
		|	DocumentData.Period                        AS LastChangeDate,
		|	DocumentData.Organization                   AS Organization,
		|	DocumentData.FixedAsset              AS FixedAsset,
		|	RegisterData.UsefulLifeMonthsAC   AS UsefulLifeMonthsAC,
		|	RegisterData.AccelerationFactor           AS AccelerationFactor,
		|	RegisterData.ResidualValueMan        AS ResidualValueMan,
		|
		|	RegisterData.VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits
		|		- ISNULL(AssetActivityRecords.Value, 0) AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|
		|	RegisterData.UsefulLifeForCalculatingDepreciationMonth
		|		- DATEDIFF(ISNULL(RegisterData.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH) AS UsefulLifeForCalculatingDepreciationMonth,
		|
		// The residual value is used to calculate depreciation
		|	ISNULL(CostOfVNA.LocalCost, 0) 
		|		+ ISNULL(CostOfVNA.CostTargetFinancing, 0)
		|		- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
		|		- ISNULL(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing, 0)
		|		+ ISNULL(CostOfSourceFA.LocalCost, 0) 
		|		+ ISNULL(CostOfSourceFA.CostTargetFinancing, 0)
		|		- ISNULL(DepreciationOfOriginalFA.DepreciationLocal, 0)
		|		- ISNULL(DepreciationOfOriginalFA.FixedAssetDepreciationTargetFinancing, 0) AS CostUsedToCalculateDepreciationManag
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN WDepreciationParametersOfOSBU AS RegisterData
		|		ON RegisterData.Ref = DocumentData.Ref
		|			AND RegisterData.FixedAsset = DocumentData.FixedAsset
		|
		|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
		|		ON CostOfVNA.Ref = DocumentData.Ref
		|			AND CostOfVNA.AccountingObject = DocumentData.FixedAsset
		|
		|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
		|		ON DepreciationOfVNA.Ref = DocumentData.Ref
		|			AND DepreciationOfVNA.AccountingObject = DocumentData.FixedAsset
		|
		|		LEFT JOIN TTCostOfOriginalFA AS CostOfSourceFA
		|		ON CostOfSourceFA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTDepreciationOfOriginalFA AS DepreciationOfOriginalFA
		|		ON DepreciationOfOriginalFA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
		|		ON FixedAssetsAccountingProcedure.Ref = DocumentData.Ref
		|			AND FixedAssetsAccountingProcedure.FixedAsset = DocumentData.FixedAsset
		|
		|		LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
		|		ON AssetActivityRecords.Ref = FixedAssetsAccountingProcedure.Ref
		|			AND AssetActivityRecords.Asset = FixedAssetsAccountingProcedure.FixedAsset
		|			AND AssetActivityRecords.RunningTimeValue = FixedAssetsAccountingProcedure.RunningTimeValue
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.RecordInLocalAccounting
		|	AND ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AttachingToExistingFixedAsset)
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion
		
		QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryTextTableTTIsListOfAllFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTOsuuDepreciationParameters(QueryTexts, "TTIsListOfAllFA");
	QueryTextTTCostOfOriginalFA(Query, QueryTexts);
	QueryTextTTDepreciationOfOriginalFA(Query, QueryTexts);
	
	ListOfMergeRequests = New Array;
	
	#Region AcceptanceForAccountingIsNotOfSameType
	QueryText =
	"SELECT
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	DocumentData.Period                             AS LastChangeDate,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.FixedAsset                   AS FixedAsset,
	|	DocumentData.UsefulLifeManagementAccounting                AS UsefulLifeMonths,
	|	DocumentData.ResidualUsefulLifeManagementAccounting_      AS UsefulLifeForCalculatingDepreciationMonth,
	|	DocumentData.ResidualEstimatedRunningTime           AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	DocumentData.AccelerationFactorManagementAccounting             AS AccelerationFactor,
	|	DocumentData.DepreciationAccrualMethodManagementAccounting       AS DepreciationMethod,
	|
	|	DocumentData.ResidualValueMan            AS ResidualValueMan,
	|	DocumentData.ResidualValueLocal        AS ResidualValueLocal,
	|
	|	ISNULL(CostOfVNA.Cost, 0) 
	|		- ISNULL(DepreciationOfVNA.Depreciation, 0) AS CostUsedToCalculateDepreciationManag,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) - ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		LEFT JOIN TTCostOfOriginalFA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTDepreciationOfOriginalFA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentData.Ref
	|
	|WHERE
	|	NOT DocumentData.MergeOfSimilarFixedAssets
	|	AND DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region AcceptanceForAccountingOfSameType
	QueryText =
	"SELECT
	|	DocumentData.Ref                             AS Recorder,
	|	DocumentData.Period                             AS Period,
	|	DocumentData.Period                             AS LastChangeDate,
	|	DocumentData.Organization                        AS Organization,
	|	DocumentData.FixedAsset                   AS FixedAsset,
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths         AS UsefulLifeMonths,
	|	DocumentData.ResidualUsefulLifeManagementAccounting_      AS UsefulLifeForCalculatingDepreciationMonth,
	|	DocumentData.ResidualEstimatedRunningTime           AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor      AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod AS DepreciationMethod,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan AS ResidualValueMan,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal AS ResidualValueLocal,
	|
	|	ISNULL(CostOfVNA.Cost, 0) 
	|		- ISNULL(DepreciationOfVNA.Depreciation, 0) AS CostUsedToCalculateDepreciationManag,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) - ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = DocumentData.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = DocumentData.FirstFA
	|
	|		LEFT JOIN TTCostOfOriginalFA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTDepreciationOfOriginalFA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.MergeOfSimilarFixedAssets
	|	AND DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	#Region AttachingToExistingFixedAsset
	QueryText =
	"SELECT
	|	DocumentData.Ref                                 AS Recorder,
	|	DocumentData.Period                                 AS Period,
	|	DocumentData.Period                                 AS LastChangeDate,
	|	DocumentData.Organization                            AS Organization,
	|	DocumentData.FixedAsset                       AS FixedAsset,
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeMonths             AS UsefulLifeMonths,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|		- DATEDIFF(ISNULL(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, DocumentData.Period), DocumentData.Period, MONTH) AS UsefulLifeForCalculatingDepreciationMonth,
	|
	|	DocumentData.ResidualEstimatedRunningTime               AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.AccelerationFactor          AS AccelerationFactor,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod    AS DepreciationMethod,
	|
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueMan       AS ResidualValueMan,
	|	FixedAssetDepreciationParametersManagementAccounting.ResidualValueLocal   AS ResidualValueLocal,
	|
	|	ISNULL(CostOfVNA.Cost, 0) 
	|		- ISNULL(DepreciationOfVNA.Depreciation, 0)
	|		+ ISNULL(CostOfSourceFA.Cost, 0) 
	|		- ISNULL(DepreciationOfOriginalFA.Depreciation, 0) AS CostUsedToCalculateDepreciationManag,
	|
	|	CASE
	|		WHEN NOT &ComplianceCAAccountingIsKept
	|			THEN ISNULL(CostOfVNA.LocalCost, 0) 
	|					- ISNULL(DepreciationOfVNA.DepreciationLocal, 0)
	|					+ ISNULL(CostOfSourceFA.LocalCost, 0) 
	|					- ISNULL(DepreciationOfOriginalFA.DepreciationLocal, 0)
	|		ELSE 0
	|	END AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|		ON FixedAssetDepreciationParametersManagementAccounting.Ref = DocumentData.Ref
	|			AND FixedAssetDepreciationParametersManagementAccounting.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = DocumentData.Ref
	|			AND CostOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = DocumentData.Ref
	|			AND DepreciationOfVNA.AccountingObject = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTCostOfOriginalFA AS CostOfSourceFA
	|		ON CostOfSourceFA.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TTDepreciationOfOriginalFA AS DepreciationOfOriginalFA
	|		ON DepreciationOfOriginalFA.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.RecordInManAccounting
	|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AttachingToExistingFixedAsset)
	|";
	ListOfMergeRequests.Add(QueryText);
	#EndRegion
	
	QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());

	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTTCostOfOriginalFA(Query, QueryTexts);
	QueryTextTableTTIsListOfAllFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts, "TTIsListOfAllFA");
	
	QueryText = MergeOfFixedAssetsLocalization.QueryTextTableInitialFixedAssetsInformation(Query, QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTAccountingPolicyOfFinancialAccounting(QueryTexts);
		
		ListOfMergeRequests = New Array;
		
		#Region AcceptanceForAccountingIsNotOfSameTypeLocalIndependent
		QueryText =
		"SELECT
		|	DocumentData.Ref             AS Recorder,
		|	DocumentData.Period             AS Period,
		|	DocumentData.FixedAsset   AS FixedAsset,
		|	DocumentData.Organization        AS Organization,
		|
		|	CASE 
		|		WHEN InitialInformationOfFirstOS.CommissioningDateAC = DATETIME(1,1,1)
		|			THEN DATETIME(1,1,1)
		|		WHEN DocumentData.RecordInLocalAccounting 
		|			THEN DocumentData.Period 
		|		ELSE InitialFixedAssetsInformation.CommissioningDateAC
		|	END AS CommissioningDateAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN DocumentData.Period 
		|		ELSE InitialFixedAssetsInformation.CommissioningDateMA
		|	END AS CommissioningDateMA,
		|
		|	CASE 
		|		WHEN InitialInformationOfFirstOS.CommissioningDateAC = DATETIME(1,1,1)
		|			THEN UNDEFINED
		|		WHEN DocumentData.RecordInLocalAccounting 
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.CommissioningDocumentAC
		|	END AS CommissioningDocumentAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.CommissioningDocumentMA
		|	END AS CommissioningDocumentMA,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting 
		|			THEN DocumentData.DepreciationMethodAccounting 
		|		ELSE InitialFixedAssetsInformation.DepreciationMethodAccounting
		|	END AS DepreciationMethodAccounting,
		|
		|	UNDEFINED AS DeregistrationDocumentACC,
		|	UNDEFINED AS DeregistrationDocumentMA,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting 
		|			THEN DocumentData.AccountingProcedureAC 
		|		ELSE InitialFixedAssetsInformation.AccountingProcedureAC
		|	END AS AccountingProcedureAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN DocumentData.AccountingProcedureMA 
		|		ELSE InitialFixedAssetsInformation.AccountingProcedureMA
		|	END AS AccountingProcedureMA,
		|
		|	ISNULL(CostOfVNA.LocalCost, 0)     AS InitialCostLocalAccounting,
		|	ISNULL(CostOfVNA.Cost, 0)         AS InitialCostMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = DocumentData.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialInformationOfFirstOS
		|		ON InitialInformationOfFirstOS.Ref = DocumentData.Ref
		|			AND InitialInformationOfFirstOS.FixedAsset = DocumentData.FirstFA
		|
		|		LEFT JOIN TTCostOfOriginalFA AS CostOfVNA
		|		ON CostOfVNA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) = VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND NOT DocumentData.MergeOfSimilarFixedAssets
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion

		#Region AcceptanceForAccountingIsNotSameLocalRules
		QueryText =
		"SELECT
		|	DocumentData.Ref             AS Recorder,
		|	DocumentData.Period             AS Period,
		|	DocumentData.FixedAsset   AS FixedAsset,
		|	DocumentData.Organization        AS Organization,
		|
		|	DocumentData.Period AS CommissioningDateAC,
		|	DocumentData.Period AS CommissioningDateMA,
		|	DocumentData.Ref AS CommissioningDocumentAC,
		|	DocumentData.Ref AS CommissioningDocumentMA,
		|	DocumentData.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|
		|	UNDEFINED AS DeregistrationDocumentACC,
		|	UNDEFINED AS DeregistrationDocumentMA,
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
		|	ISNULL(CostOfVNA.LocalCost, 0)     AS InitialCostLocalAccounting,
		|	ISNULL(CostOfVNA.Cost, 0)         AS InitialCostMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = DocumentData.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialInformationOfFirstOS
		|		ON InitialInformationOfFirstOS.Ref = DocumentData.Ref
		|			AND InitialInformationOfFirstOS.FixedAsset = DocumentData.FirstFA
		|
		|		LEFT JOIN TTCostOfOriginalFA AS CostOfVNA
		|		ON CostOfVNA.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTAccountingPolicyOfFinancialAccounting AS TTAccountingPolicyOfFinancialAccounting
		|		ON TTAccountingPolicyOfFinancialAccounting.Ref = DocumentData.Ref
		|
		|WHERE
		|	ISNULL(TTAccountingPolicyOfFinancialAccounting.FixedAssetAccountingProcedureInLocalAccounting, UNDEFINED) <> VALUE(Enum.FixedAssetAccountingProcedureInLocalAccounting.Independent)
		|	AND NOT DocumentData.MergeOfSimilarFixedAssets
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion

		#Region AcceptanceForAccountingOfSameType
		QueryText =
		"SELECT
		|	DocumentData.Ref           AS Recorder,
		|	DocumentData.Period           AS Period,
		|	DocumentData.FixedAsset AS FixedAsset,
		|	DocumentData.Organization      AS Organization,
		|
		|	CASE 
		|		WHEN InitialInformationOfFirstOS.CommissioningDateAC = DATETIME(1,1,1)
		|			THEN DATETIME(1,1,1)
		|		WHEN DocumentData.RecordInLocalAccounting 
		|			THEN DocumentData.Period 
		|		ELSE InitialFixedAssetsInformation.CommissioningDateAC
		|	END AS CommissioningDateAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN DocumentData.Period 
		|		ELSE InitialFixedAssetsInformation.CommissioningDateMA
		|	END AS CommissioningDateMA,
		|
		|	CASE 
		|		WHEN InitialInformationOfFirstOS.CommissioningDateAC = DATETIME(1,1,1)
		|			THEN UNDEFINED
		|		WHEN DocumentData.RecordInLocalAccounting 
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.CommissioningDocumentAC
		|	END AS CommissioningDocumentAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.CommissioningDocumentMA
		|	END AS CommissioningDocumentMA,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting 
		|			THEN InitialInformationOfFirstOS.DepreciationMethodAccounting 
		|		ELSE InitialFixedAssetsInformation.DepreciationMethodAccounting
		|	END AS DepreciationMethodAccounting,
		|
		|	UNDEFINED AS DeregistrationDocumentACC,
		|	UNDEFINED AS DeregistrationDocumentMA,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInLocalAccounting 
		|			THEN InitialInformationOfFirstOS.AccountingProcedureAC 
		|		ELSE InitialFixedAssetsInformation.AccountingProcedureAC
		|	END AS AccountingProcedureAC,
		|
		|	CASE 
		|		WHEN DocumentData.RecordInManAccounting 
		|			THEN InitialInformationOfFirstOS.AccountingProcedureMA 
		|		ELSE InitialFixedAssetsInformation.AccountingProcedureMA
		|	END AS AccountingProcedureMA,
		|
		|	ISNULL(CostOfVNA.LocalCost, 0)     AS InitialCostLocalAccounting,
		|	ISNULL(CostOfVNA.Cost, 0)         AS InitialCostMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = DocumentData.FixedAsset
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialInformationOfFirstOS
		|		ON InitialInformationOfFirstOS.Ref = DocumentData.Ref
		|			AND InitialInformationOfFirstOS.FixedAsset = DocumentData.FirstFA
		|
		|		LEFT JOIN TTCostOfOriginalFA AS CostOfVNA
		|		ON CostOfVNA.Ref = DocumentData.Ref
		|
		|WHERE
		|	DocumentData.MergeOfSimilarFixedAssets
		|	AND DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.MergeOfFixedAssets)
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion

		#Region Derecognition
		QueryText =
		"SELECT
		|	DocumentData.Ref                                 AS Recorder,
		|	DocumentData.Period                                 AS Period,
		|	InitialFixedAssetsInformation.FixedAsset              AS FixedAsset,
		|	DocumentData.Organization                            AS Organization,
		|
		|	InitialFixedAssetsInformation.CommissioningDateAC      AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA      AS CommissioningDateMA,
		|
		|	InitialFixedAssetsInformation.CommissioningDocumentAC  AS CommissioningDocumentAC,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA  AS CommissioningDocumentMA,
		|	InitialFixedAssetsInformation.DepreciationMethodAccounting  AS DepreciationMethodAccounting,
		|
		|	CASE
		|		WHEN DocumentData.RecordInLocalAccounting
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentACC
		|
		|	END AS DeregistrationDocumentACC,
		|
		|	CASE
		|		WHEN DocumentData.RecordInManAccounting
		|			THEN DocumentData.Ref 
		|		ELSE InitialFixedAssetsInformation.DeregistrationDocumentMA
		|	END AS DeregistrationDocumentMA,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureAC                AS AccountingProcedureAC,
		|	InitialFixedAssetsInformation.AccountingProcedureMA                AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.InitialCostLocalAccounting     AS InitialCostLocalAccounting,
		|	InitialFixedAssetsInformation.InitialCostMA     AS InitialCostMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = DocumentData.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset <> DocumentData.FixedAsset
		|";
		ListOfMergeRequests.Add(QueryText);
		#EndRegion

		QueryText = StrConcat(ListOfMergeRequests, TMCommonUse.QuerySeparatorInJoin());
		
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFACost(Query, QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
	QueryTextTableTTFADetails(QueryTexts);
	
	QueryText =
	// Increase in value
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	DocumentData.Ref                        AS Recorder,
	|	DocumentData.Period                        AS Period,
	|	DocumentData.Organization                   AS Organization,
	|	DocumentData.Department                 AS Department,
	|
	|	TTFADetails.FinancialAccountingGroupOfRecipient AS FinancialAccountingGroup,
	|	TTFADetails.RecipientSLineOfBusiness AS LineOfBusiness,
	|	TTFADetails.RecipientSTenant              AS Leaseholder,
	|
	|	DocumentData.BusinessOperation         AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting            AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting             AS RecordInManAccounting,
	|	DocumentData.FixedAsset              AS FixedAsset,
	|	TTFADetails.VATTaxationOfRecipient     AS VATTaxation,
	|
	|	DocumentData.Department                 AS DebitBusinessUnit,
	|	TTFADetails.LineOfBusiness          AS CorLineOfBusiness,
	|	TTFADetails.FinancialAccountingGroup           AS CorFinancialAccountingGroup,
	|	TTFADetails.Leaseholder                        AS CorCounterparty,
	|	NOT TT_CostOfVNA.AccountingObject IS NULL      AS CostCalculation,
	|	0                                             AS PreliminaryCostMan,
	|	0                                             AS PreliminaryCostLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_CostOfVNA.Cost
	|		ELSE 0 
	|	END                                         AS Cost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.LocalCost
	|		ELSE 0 
	|	END                                         AS LocalCost,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostInTaxAccounting
	|		ELSE 0 
	|	END                                         AS CostInTaxAccounting,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostPermanentDifference
	|		ELSE 0 
	|	END                                         AS CostPermanentDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTemporaryDifference
	|		ELSE 0 
	|	END                                         AS CostTemporaryDifference,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTargetFinancing
	|		ELSE 0 
	|	END                                         AS CostTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTargetFinancingTA
	|		ELSE 0 
	|	END                                         AS CostTargetFinancingTA,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTargetFinancingPD
	|		ELSE 0 
	|	END                                         AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTargetFinancingTD
	|		ELSE 0 
	|	END                                         AS CostTargetFinancingTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.TAExpenseAmountOfInvestmentTaxDeduction
	|		ELSE 0 
	|	END                                         AS TAExpenseAmountOfInvestmentTaxDeduction,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_CostOfVNA.CostRevaluationReserve
	|		ELSE 0 
	|	END                                         AS CostRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END                                         AS CostRevaluationReserveLocal,
	|
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
	|	
	|	FATable.RowID                 AS FinRecordID,
	|	&SettingUpHO_Cost                        AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = FATable.Ref
	|			AND TT_CostOfVNA.AccountingObject = FATable.FixedAsset
	|
	|		INNER JOIN TTFADetails AS TTFADetails
	|		ON TTFADetails.Ref = FATable.Ref
	|			AND TTFADetails.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	FATable.Ref = DocumentData.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	DocumentData.Ref                        AS Recorder,
	|	DocumentData.Period                        AS Period,
	|	DocumentData.Organization                   AS Organization,
	|	DocumentData.Department                 AS Department,
	|	TTFADetails.FinancialAccountingGroupOfRecipient AS FinancialAccountingGroup,
	|	TTFADetails.RecipientSLineOfBusiness AS LineOfBusiness,
	|	TTFADetails.Leaseholder                        AS Leaseholder,
	|	DocumentData.BusinessOperation         AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting            AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting             AS RecordInManAccounting,
	|	DocumentData.FixedAsset              AS FixedAsset,
	|	TTFADetails.VATTaxationOfRecipient     AS VATTaxation,
	|
	|	DocumentData.Department                 AS DebitBusinessUnit,
	|	TTFADetails.LineOfBusiness          AS CorLineOfBusiness,
	|	TTFADetails.FinancialAccountingGroup           AS CorFinancialAccountingGroup,
	|	TTFADetails.RecipientSTenant              AS CorCounterparty,
	|	NOT TT_CostOfVNA.AccountingObject IS NULL      AS CostCalculation,
	|
	|	0                                             AS PreliminaryCostMan,
	|	0                                             AS PreliminaryCostLocal,
	|	0                                             AS Cost,
	|	0                                             AS LocalCost,
	|	0                                             AS CostInTaxAccounting,
	|	0                                             AS CostPermanentDifference,
	|	0                                             AS CostTemporaryDifference,
	|	0                                             AS CostTargetFinancing,
	|	0                                             AS CostTargetFinancingTA,
	|	0                                             AS CostTargetFinancingPD,
	|	0                                             AS CostTargetFinancingTD,
	|	0                                             AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                             AS CostRevaluationReserve,
	|	0                                             AS CostRevaluationReserveLocal,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_CostOfVNA.CostGainMA
	|		ELSE 0 
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostGainLocal
	|		ELSE 0 
	|	END AS CostGainLocal,
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
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = FATable.Ref
	|			AND TT_CostOfVNA.AccountingObject = FATable.FixedAsset
	|
	|		INNER JOIN TTFADetails AS TTFADetails
	|		ON TTFADetails.Ref = FATable.Ref
	|			AND TTFADetails.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND TT_CostOfVNA.CostGainMA <> 0
	|		OR DocumentData.RecordInLocalAccounting AND TT_CostOfVNA.CostGainLocal <> 0)
	|
	|UNION ALL
	|
	// Write-off of the original OS
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)        AS RecordType,
	|	DocumentData.Ref                        AS Recorder,
	|	DocumentData.Period                        AS Period,
	|	DocumentData.Organization                   AS Organization,
	|	DocumentData.Department                 AS Department,
	|	TTFADetails.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	TTFADetails.LineOfBusiness          AS LineOfBusiness,
	|	TTFADetails.Leaseholder                        AS Leaseholder,
	|	DocumentData.BusinessOperation         AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting            AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting             AS RecordInManAccounting,
	|	FATable.FixedAsset                    AS FixedAsset,
	|	TTFADetails.VATTaxationOfRecipient     AS VATTaxation,
	|
	|	DocumentData.Department                 AS DebitBusinessUnit,
	|	TTFADetails.RecipientSLineOfBusiness AS CorLineOfBusiness,
	|	TTFADetails.FinancialAccountingGroupOfRecipient AS CorFinancialAccountingGroup,
	|	TTFADetails.RecipientSTenant              AS CorCounterparty,
	|	NOT TT_CostOfVNA.AccountingObject IS NULL      AS CostCalculation,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_CostOfVNA.PreliminaryCostMan
	|		ELSE 0 
	|	END                                         AS PreliminaryCostMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.PreliminaryCostLocal
	|		ELSE 0 
	|	END                                         AS PreliminaryCostLocal,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_CostOfVNA.Cost
	|		ELSE 0 
	|	END                                         AS Cost,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.LocalCost
	|		ELSE 0 
	|	END                                         AS LocalCost,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostInTaxAccounting
	|		ELSE 0 
	|	END                                         AS CostInTaxAccounting,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostPermanentDifference
	|		ELSE 0 
	|	END                                         AS CostPermanentDifference,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTemporaryDifference
	|		ELSE 0 
	|	END                                         AS CostTemporaryDifference,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTargetFinancing
	|		ELSE 0 
	|	END                                         AS CostTargetFinancing,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTargetFinancingTA
	|		ELSE 0 
	|	END                                         AS CostTargetFinancingTA,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTargetFinancingPD
	|		ELSE 0 
	|	END                                         AS CostTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostTargetFinancingTD
	|		ELSE 0 
	|	END                                         AS CostTargetFinancingTD,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.TAExpenseAmountOfInvestmentTaxDeduction
	|		ELSE 0 
	|	END                                         AS TAExpenseAmountOfInvestmentTaxDeduction,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_CostOfVNA.CostRevaluationReserve
	|		ELSE 0 
	|	END                                         AS CostRevaluationReserve,
	|            
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostRevaluationReserveLocal
	|		ELSE 0 
	|	END                                         AS CostRevaluationReserveLocal,
	|
	|	0 AS CostGainMA,
	|	0 AS CostGainLocal,
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
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = FATable.Ref
	|			AND TT_CostOfVNA.AccountingObject = FATable.FixedAsset
	|
	|		INNER JOIN TTFADetails AS TTFADetails
	|		ON TTFADetails.Ref = FATable.Ref
	|			AND TTFADetails.FixedAsset = FATable.FixedAsset
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)        AS RecordType,
	|	DocumentData.Ref                        AS Recorder,
	|	DocumentData.Period                        AS Period,
	|	DocumentData.Organization                   AS Organization,
	|	DocumentData.Department                 AS Department,
	|	TTFADetails.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	TTFADetails.LineOfBusiness          AS LineOfBusiness,
	|	UNDEFINED                                  AS Leaseholder,
	|	DocumentData.BusinessOperation         AS BusinessOperation,
	|	DocumentData.RecordInLocalAccounting            AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting             AS RecordInManAccounting,
	|	FATable.FixedAsset                    AS FixedAsset,
	|	TTFADetails.VATTaxationOfRecipient     AS VATTaxation,
	|
	|	DocumentData.Department                 AS DebitBusinessUnit,
	|	TTFADetails.RecipientSLineOfBusiness AS CorLineOfBusiness,
	|	TTFADetails.FinancialAccountingGroupOfRecipient AS CorFinancialAccountingGroup,
	|	UNDEFINED                                  AS CorCounterparty,
	|	NOT TT_CostOfVNA.AccountingObject IS NULL      AS CostCalculation,
	|            
	|	0                                             AS PreliminaryCostMan,
	|	0                                             AS PreliminaryCostLocal,
	|	0                                             AS Cost,
	|	0                                             AS LocalCost,
	|	0                                             AS CostInTaxAccounting,
	|	0                                             AS CostPermanentDifference,
	|	0                                             AS CostTemporaryDifference,
	|	0                                             AS CostTargetFinancing,
	|	0                                             AS CostTargetFinancingTA,
	|	0                                             AS CostTargetFinancingPD,
	|	0                                             AS CostTargetFinancingTD,
	|	0                                             AS TAExpenseAmountOfInvestmentTaxDeduction,
	|	0                                             AS CostRevaluationReserve,
	|	0                                             AS CostRevaluationReserveLocal,
	|	
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_CostOfVNA.CostGainMA
	|		ELSE 0 
	|	END AS CostGainMA,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_CostOfVNA.CostGainLocal
	|		ELSE 0 
	|	END AS CostGainLocal,
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
	|		LEFT JOIN TT_CostOfVNA AS TT_CostOfVNA
	|		ON TT_CostOfVNA.Ref = FATable.Ref
	|			AND TT_CostOfVNA.AccountingObject = FATable.FixedAsset
	|
	|		INNER JOIN TTFADetails AS TTFADetails
	|		ON TTFADetails.Ref = FATable.Ref
	|			AND TTFADetails.FixedAsset = FATable.FixedAsset
	|
	|WHERE
	|	(DocumentData.RecordInManAccounting AND TT_CostOfVNA.CostGainMA <> 0
	|		OR DocumentData.RecordInLocalAccounting AND TT_CostOfVNA.CostGainLocal <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers)
	
	RegisterName = "SubAssetsComponentsOfDepreciation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	NodesComponents.SubAssetComponent AS SubAssetComponent,
	|	DocumentData.FixedAsset AS FixedAsset
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|		INNER JOIN TTUnitsDepreciationComponents AS NodesComponents
	|		ON FATable.Ref = NodesComponents.Ref
	|			AND FATable.FixedAsset = NodesComponents.FixedAsset
	|
	|WHERE
	|	FATable.FixedAsset.OSType IN (
	|		VALUE(Enum.FATypes.Asset),
	|		VALUE(Enum.FATypes.GroupFA),
	|		VALUE(Enum.FATypes.CapitalExpenditureInLeasedAssets))
	|";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryTextTableTTFADetails(QueryTexts);
	
	QueryText =
	// Transfer of depreciation from the original OS.
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Department                       AS Department,
	|	DocumentData.FixedAsset                    AS FixedAsset,
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
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.FixedAssetDepreciationTargetFinancing
	|		ELSE 0 
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing
	|		ELSE 0 
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationTargetFinancingPD
	|		ELSE 0 
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationOfTargetFinancingTD
	|		ELSE 0 
	|	END AS DepreciationOfTargetFinancingTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationRevaluationReserve
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationRevaluationReserveLocal
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	TTFADetails.FinancialAccountingGroupOfRecipient       AS FinancialAccountingGroup,
	|	TTFADetails.FinancialAccountingGroup                 AS CorFinancialAccountingGroup,
	|	TTFADetails.RecipientSLineOfBusiness      AS LineOfBusiness,
	|	TTFADetails.LineOfBusiness                AS CorLineOfBusiness,
	|	DocumentData.BusinessOperation               AS BusinessOperation,
	|
	|	CASE
	|		WHEN DocumentData.MergeOfSimilarFixedAssets
	|			THEN TT_DepreciationOfVNA.AccrueDepreciation
	|		ELSE DocumentData.AccrueDepreciation
	|	END AS AccrueDepreciation,
	|	
	|	FATable.RowID AS FinRecordID,
	|	&SettingUpHO_Depreciation AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|		ON TT_DepreciationOfVNA.Ref = DocumentData.Ref
	|			AND TT_DepreciationOfVNA.AccountingObject = FATable.FixedAsset
	|
	|		INNER JOIN TTFADetails AS TTFADetails
	|		ON TTFADetails.Ref = FATable.Ref
	|			AND TTFADetails.FixedAsset = FATable.FixedAsset
	|
	|UNION ALL
	|
	// Write-off of depreciation of the original OS.
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Department                       AS Department,
	|	FATable.FixedAsset                          AS FixedAsset,
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
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.FixedAssetDepreciationTargetFinancing
	|		ELSE 0 
	|	END AS FixedAssetDepreciationTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing
	|		ELSE 0 
	|	END AS DepreciationTaxAccountingTargetFinancing,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationTargetFinancingPD
	|		ELSE 0 
	|	END AS DepreciationTargetFinancingPD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationOfTargetFinancingTD
	|		ELSE 0 
	|	END AS DepreciationOfTargetFinancingTD,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationRevaluationReserve
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserve,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_DepreciationOfVNA.DepreciationRevaluationReserveLocal 
	|		ELSE 0 
	|	END AS DepreciationRevaluationReserveLocal,
	|
	|	TTFADetails.FinancialAccountingGroup                 AS FinancialAccountingGroup,
	|	TTFADetails.FinancialAccountingGroupOfRecipient       AS CorFinancialAccountingGroup,
	|	TTFADetails.LineOfBusiness                AS LineOfBusiness,
	|	TTFADetails.RecipientSLineOfBusiness      AS CorLineOfBusiness,
	|	DocumentData.BusinessOperation               AS BusinessOperation,
	|	TT_DepreciationOfVNA.AccrueDepreciation                    AS AccrueDepreciation,
	|	
	|	FATable.RowID                       AS FinRecordID,
	|	&SettingUpHO_Depreciation                            AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_DepreciationOfVNA AS TT_DepreciationOfVNA
	|		ON TT_DepreciationOfVNA.Ref = DocumentData.Ref
	|			AND TT_DepreciationOfVNA.AccountingObject = FATable.FixedAsset
	|
	|		INNER JOIN TTFADetails AS TTFADetails
	|		ON TTFADetails.Ref = FATable.Ref
	|			AND TTFADetails.FixedAsset = FATable.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableImpairmentFA(QueryTexts)

	RegisterName = "ImpairmentFA";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTUnitsDepreciationComponents(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTCompositionOfCGU(QueryTexts);
	
	QueryText =
	// Transfer of impairment from the original operating systems.
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Department                       AS Department,
	|	DocumentData.FixedAsset                    AS NonCurrentAsset,
	|	TT_ImpairmentFA.CGU                              AS CGU,
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
	|	DocumentData.FinancialAccountingGroup              AS FinancialAccountingGroup,
	|	DocumentData.LineOfBusiness             AS LineOfBusiness,
	|	DocumentData.BusinessOperation               AS BusinessOperation,
	|	
	|	FATable.RowID                       AS FinRecordID,
	|	&SettingUpHO_ReclassificationOfFA                      AS BusinessTransactionSetting
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = FATable.Ref
	|			AND TT_ImpairmentFA.AccountingObject = FATable.FixedAsset
	|	
	|		LEFT JOIN TTCompositionOfCGU AS TTCompositionOfCGU
	|		ON TTCompositionOfCGU.Ref = FATable.Ref
	|			AND TTCompositionOfCGU.NonCurrentAsset = FATable.FixedAsset
	|			
	|WHERE
	|	ISNULL(TTCompositionOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) = DocumentData.CGU
	|	AND NOT DocumentData.MergeOfSimilarFixedAssets
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Expense)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Department                       AS Department,
	|	DocumentData.FixedAsset                    AS NonCurrentAsset,
	|	TT_ImpairmentFA.CGU                              AS CGU,
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
	|	TTFAAccountingParameters.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness          AS LineOfBusiness,
	|	DocumentData.BusinessOperation               AS BusinessOperation,
	|	
	|	FATable.RowID                       AS FinRecordID,
	|	&SettingUpHO_ReclassificationOfFA                      AS BusinessTransactionSetting
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
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = FATable.Ref
	|			AND TT_ImpairmentFA.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTCompositionOfCGU AS TTCompositionOfCGU
	|		ON TTCompositionOfCGU.Ref = FATable.Ref
	|			AND TTCompositionOfCGU.NonCurrentAsset = FATable.FixedAsset
	|			
	|WHERE
	|	ISNULL(TTCompositionOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) = DocumentData.CGU
	|	AND DocumentData.MergeOfSimilarFixedAssets
	|
	|UNION ALL
	|
	// Write-off of the impairment of the original OS.
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Department                       AS Department,
	|	FATable.FixedAsset                          AS NonCurrentAsset,
	|	TT_ImpairmentFA.CGU                              AS CGU,
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
	|	TTFAAccountingParameters.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness          AS LineOfBusiness,
	|	DocumentData.BusinessOperation               AS BusinessOperation,
	|	
	|	FATable.RowID                       AS FinRecordID,
	|	&SettingUpHO_ReclassificationOfFA                      AS BusinessTransactionSetting
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
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = FATable.Ref
	|			AND TT_ImpairmentFA.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTCompositionOfCGU AS TTCompositionOfCGU
	|		ON TTCompositionOfCGU.Ref = FATable.Ref
	|			AND TTCompositionOfCGU.NonCurrentAsset = FATable.FixedAsset
	|			
	|WHERE
	|	ISNULL(TTCompositionOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) = DocumentData.CGU
	|
	|UNION ALL
	|
	// recovery of impairment when changing the CGU
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Department                       AS Department,
	|	FATable.FixedAsset                          AS NonCurrentAsset,
	|	TT_ImpairmentFA.CGU                              AS CGU,
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
	|	TTFAAccountingParameters.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness          AS LineOfBusiness,
	|	DocumentData.BusinessOperation               AS BusinessOperation,
	|	
	|	FATable.RowID                       AS FinRecordID,
	|	&SettingUpHO_RecoveryOfImpairment              AS BusinessTransactionSetting
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
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = FATable.Ref
	|			AND TT_ImpairmentFA.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTCompositionOfCGU AS TTCompositionOfCGU
	|		ON TTCompositionOfCGU.Ref = FATable.Ref
	|			AND TTCompositionOfCGU.NonCurrentAsset = FATable.FixedAsset
	|			
	|WHERE
	|	ISNULL(TTCompositionOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) <> DocumentData.CGU
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt)              AS RecordType,
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Department                       AS Department,
	|	NodesComponents.FixedAsset                     AS NonCurrentAsset,
	|	TT_ImpairmentFA.CGU                              AS CGU,
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
	|	TTFAAccountingParameters.FinancialAccountingGroup           AS FinancialAccountingGroup,
	|	TTFAAccountingParameters.LineOfBusiness          AS LineOfBusiness,
	|	DocumentData.BusinessOperation               AS BusinessOperation,
	|	
	|	NodesComponents.RowID                  AS FinRecordID,
	|	&SettingUpHO_RecoveryOfImpairment              AS BusinessTransactionSetting
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
	|		INNER JOIN TTUnitsDepreciationComponents AS NodesComponents
	|		ON NodesComponents.Ref = FATable.Ref
	|			AND NodesComponents.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = FATable.Ref
	|			AND TT_ImpairmentFA.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTCompositionOfCGU AS TTCompositionOfCGU
	|		ON TTCompositionOfCGU.Ref = FATable.Ref
	|			AND TTCompositionOfCGU.NonCurrentAsset = FATable.FixedAsset
	|			
	|WHERE
	|	ISNULL(TTCompositionOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) <> DocumentData.CGU
	|";
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOtherIncome(Query, QueryTexts)

	RegisterName = "OtherIncome";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTCompositionOfCGU(QueryTexts);
	QueryTextTTReflectionOfIncomeExpenses(QueryTexts);

	QueryText = 
	"SELECT
	|	DocumentData.Ref                              AS Recorder,
	|	DocumentData.Period                              AS Period,
	|	DocumentData.Organization                         AS Organization,
	|	DocumentData.Department                       AS Department,
	|	TTFAAccountingParameters.LineOfBusiness          AS LineOfBusiness,
	|	TTReflectionOfIncomeExpenses.IncomeItem            AS IncomeItem,
	|	TTReflectionOfIncomeExpenses.DimensionOfRevenue         AS DimensionOfRevenue,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_ImpairmentFA.ImpairmenMan
	|		ELSE 0 
	|	END                                               AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN TT_ImpairmentFA.ImpairmenMan
	|		ELSE 0 
	|	END                                               AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN TT_ImpairmentFA.ImpairmentLocalAssets
	|		ELSE 0 
	|	END                                               AS SumCompl,
	|
	|	FATable.RowID                       AS FinRecordID,
	|	&SettingUpHO_RecoveryOfImpairment              AS BusinessTransactionSetting
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
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = FATable.Ref
	|			AND TT_ImpairmentFA.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTCompositionOfCGU AS TTCompositionOfCGU
	|		ON TTCompositionOfCGU.Ref = FATable.Ref
	|			AND TTCompositionOfCGU.NonCurrentAsset = FATable.FixedAsset
	|		
	|		LEFT JOIN TTReflectionOfIncomeExpenses AS TTReflectionOfIncomeExpenses
	|		ON TTReflectionOfIncomeExpenses.Ref = FATable.Ref
	|			AND TTReflectionOfIncomeExpenses.NonCurrentAsset = FATable.FixedAsset
	|			
	|WHERE
	|	ISNULL(TTCompositionOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) <> DocumentData.CGU
	|";
	
	QueryTexts.Add(QueryText, RegisterName, False);
	
EndProcedure

Procedure QueryTextTableRecordsIncomeExpensesOtherAssetsLiabilities(QueryTexts)

	RegisterName = "RecordsIncomeExpensesOtherAssetsLiabilities";
	
	If DocumentsPosting.ThereIsQueryTable(RegisterName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts);
	QueryTextTTReflectionOfIncomeExpenses(QueryTexts);
	
	QueryText =
	"// Allocation Of Depreciation
	|SELECT
	|	VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange) AS BusinessOperation,
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	DocumentData.FixedAsset  AS AssetsLiabilitiesDimension,
	|	DocumentData.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization       AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN FixedAssetsDepreciationCharge.Depreciation
	|		ELSE 0 
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
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
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.MergeOfSimilarFixedAssets
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.BusinessTransactions.FixedAssetDepreciationParameterChange) AS BusinessOperation,
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	DocumentData.FixedAsset  AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	FATable.FixedAsset        AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization       AS CorCompany,
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
	|		INNER JOIN TTFAAccountingParameters AS TTFAAccountingParameters
	|		ON TTFAAccountingParameters.Ref = FATable.Ref
	|			AND TTFAAccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		INNER JOIN TT_DepreciationOfVNA AS FixedAssetsDepreciationCharge
	|		ON FixedAssetsDepreciationCharge.Ref = FATable.Ref
	|			AND FixedAssetsDepreciationCharge.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.MergeOfSimilarFixedAssets
	|
	|UNION ALL
	|
	|// Moving the cost
	|SELECT
	|	VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup  AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	DocumentData.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	DocumentData.FixedAsset  AS CorDimensionOfAssetsLiabilities,
	|	DocumentData.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization       AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN FACost.Cost
	|		ELSE 0 
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN FACost.Cost
	|		ELSE 0 
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN FACost.LocalCost + FACost.CostTargetFinancing
	|		ELSE 0 
	|	END AS SumCompl
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
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	NOT DocumentData.MergeOfSimilarFixedAssets
	|
	|UNION ALL
	|
	|SELECT
	|	VALUE(Enum.BusinessTransactions.FixedAssetsCostParameterChange) AS BusinessOperation,
	|	DocumentData.Ref            AS Recorder,
	|	DocumentData.Period            AS Period,
	|	DocumentData.Organization       AS Organization,
	|
	|	DocumentData.Department     AS Department,
	|	TTFAAccountingParameters.LineOfBusiness AS LineOfBusiness,
	|	&ArticleAP_OS                      AS AssetRef,
	|	UNDEFINED                      AS DimensionOfRevenue,
	|	UNDEFINED                      AS DimensionOfExpenses,
	|	FATable.FixedAsset        AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS FinancialAccountingGroup,
	|
	|	DocumentData.Department     AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness AS CorLineOfBusiness,
	|	&ArticleAP_OS                      AS CorItem,
	|	UNDEFINED                      AS CorIncomeDimension,
	|	UNDEFINED                      AS CorExpenditureDimension,
	|	DocumentData.FixedAsset  AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup AS CorFinancialAccountingGroup,
	|
	|	DocumentData.Organization       AS CorCompany,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN FACost.Cost
	|		ELSE 0 
	|	END AS Sum,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInManAccounting
	|			THEN FACost.Cost
	|		ELSE 0 
	|	END AS SumMan,
	|
	|	CASE 
	|		WHEN DocumentData.RecordInLocalAccounting
	|			THEN FACost.LocalCost + FACost.CostTargetFinancing
	|		ELSE 0 
	|	END AS SumCompl
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
	|		INNER JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|
	|WHERE
	|	DocumentData.MergeOfSimilarFixedAssets
	|
	|UNION ALL
	|
	|// Reclassification of impairment analysis
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ReclassificationOfFA) AS BusinessOperation,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|
	|	DocumentData.Department               AS Department,
	|	DocumentData.LineOfBusiness     AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets) AS AssetRef,
	|	UNDEFINED                                AS DimensionOfRevenue,
	|	UNDEFINED                                AS DimensionOfExpenses,
	|	TT_ImpairmentFA.AccountingObject               AS AssetsLiabilitiesDimension,
	|	DocumentData.FinancialAccountingGroup      AS FinancialAccountingGroup,
	|
	|	DocumentData.Department               AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets) AS CorItem,
	|	UNDEFINED                                AS CorIncomeDimension,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	TT_ImpairmentFA.AccountingObject               AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	TT_ImpairmentFA.Organization               AS CorCompany,
	|
	|	TT_ImpairmentFA.ImpairmenMan            AS Sum,
	|	TT_ImpairmentFA.ImpairmenMan            AS SumMan,
	|	TT_ImpairmentFA.ImpairmentLocalAssets           AS SumCompl
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
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = FATable.Ref
	|			AND TT_ImpairmentFA.AccountingObject = FATable.FixedAsset
	|
	|		LEFT JOIN TTCompositionOfCGU AS TTCompositionOfCGU
	|		ON TTCompositionOfCGU.Ref = FATable.Ref
	|			AND TTCompositionOfCGU.NonCurrentAsset = FATable.FixedAsset
	|			
	|WHERE
	|	ISNULL(TTCompositionOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) = DocumentData.CGU
	|
	|UNION ALL
	|
	|// Recovery of impairment upon retirement from the EGDS
	|SELECT
	|	VALUE(Enum.BusinessTransactions.ReversalOfFAImpairment) AS BusinessOperation,
	|	DocumentData.Ref                      AS Recorder,
	|	DocumentData.Period                      AS Period,
	|	DocumentData.Organization                 AS Organization,
	|
	|	DocumentData.Department               AS Department,
	|	TTFAAccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceFixedAssets) AS AssetRef,
	|	UNDEFINED                                AS DimensionOfRevenue,
	|	UNDEFINED                                AS DimensionOfExpenses,
	|	TT_ImpairmentFA.AccountingObject               AS AssetsLiabilitiesDimension,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|
	|	DocumentData.Department               AS DebitBusinessUnit,
	|	TTFAAccountingParameters.LineOfBusiness  AS CorLineOfBusiness,
	|	TTReflectionOfIncomeExpenses.IncomeItem    AS CorItem,
	|	TTReflectionOfIncomeExpenses.DimensionOfRevenue AS CorIncomeDimension,
	|	UNDEFINED                                AS CorExpenditureDimension,
	|	TT_ImpairmentFA.AccountingObject               AS CorDimensionOfAssetsLiabilities,
	|	TTFAAccountingParameters.FinancialAccountingGroup   AS CorFinancialAccountingGroup,
	|
	|	TT_ImpairmentFA.Organization               AS CorCompany,
	|
	|	TT_ImpairmentFA.ImpairmenMan            AS Sum,
	|	TT_ImpairmentFA.ImpairmenMan            AS SumMan,
	|	TT_ImpairmentFA.ImpairmentLocalAssets           AS SumCompl
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
	|		INNER JOIN TT_ImpairmentFA AS TT_ImpairmentFA
	|		ON TT_ImpairmentFA.Ref = FATable.Ref
	|			AND TT_ImpairmentFA.AccountingObject = FATable.FixedAsset
	|		
	|		LEFT JOIN TTReflectionOfIncomeExpenses AS TTReflectionOfIncomeExpenses
	|		ON TTReflectionOfIncomeExpenses.Ref = FATable.Ref
	|			AND TTReflectionOfIncomeExpenses.NonCurrentAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTCompositionOfCGU AS TTCompositionOfCGU
	|		ON TTCompositionOfCGU.Ref = FATable.Ref
	|			AND TTCompositionOfCGU.NonCurrentAsset = FATable.FixedAsset
	|			
	|WHERE
	|	ISNULL(TTCompositionOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) <> DocumentData.CGU
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableCGUComposition(Query, QueryTexts, Registers)

	RegisterName = "CGUComposition";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	MergeOfFixedAssets.FixedAsset AS FixedAsset
	|INTO ListOfAllDocumentFA
	|FROM
	|	Document.MergeOfFixedAssets AS MergeOfFixedAssets
	|WHERE
	|	MergeOfFixedAssets.Ref = &Ref
	|
	|UNION
	|
	|SELECT
	|	MergeOfFixedAssetsFA.FixedAsset
	|FROM
	|	Document.MergeOfFixedAssets.FA AS MergeOfFixedAssetsFA
	|WHERE
	|	MergeOfFixedAssetsFA.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CGUCompositionSliceLast.NonCurrentAsset AS NonCurrentAsset,
	|	CGUCompositionSliceLast.Organization AS Organization,
	|	CGUCompositionSliceLast.CGU AS CGU
	|INTO InitialStateOfCGU
	|FROM
	|	InformationRegister.CGUComposition.SliceLast(
	|			&BorderInFrontOfDocument,
	|			NonCurrentAsset IN
	|					(SELECT
	|						ListOfAllDocumentFA.FixedAsset
	|					FROM
	|						ListOfAllDocumentFA AS ListOfAllDocumentFA)
	|				AND Organization IN
	|					(SELECT TOP 1
	|						DocumentData.Organization AS Organization
	|					FROM
	|						DocumentDataDetails AS DocumentData)) AS CGUCompositionSliceLast
	|
	|INDEX BY
	|	NonCurrentAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentData.Ref AS Recorder,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.FixedAsset AS NonCurrentAsset,
	|	DocumentData.CGU AS CGU
	|FROM
	|	DocumentDataDetails AS DocumentData
	|		LEFT JOIN InitialStateOfCGU AS InitialStateOfCGU
	|		ON DocumentData.Organization = InitialStateOfCGU.Organization
	|			AND DocumentData.FixedAsset = InitialStateOfCGU.NonCurrentAsset
	|WHERE
	|	DocumentData.CGU <> ISNULL(InitialStateOfCGU.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef))";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTTCostOfOriginalFA(Query, QueryTexts) Export

	TableName = "TTCostOfOriginalFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextEmptyTableBNACost(Query, QueryTexts);
		
	QueryText = 
	"SELECT
	|	FATable.Ref                       AS Ref,
	|	SUM(CostOfVNA.Cost)          AS Cost,
	|	SUM(CostOfVNA.LocalCost)      AS LocalCost,
	|	SUM(CostOfVNA.CostInTaxAccounting)        AS CostInTaxAccounting,
	|	SUM(CostOfVNA.CostPermanentDifference)        AS CostPermanentDifference,
	|	SUM(CostOfVNA.CostTemporaryDifference)        AS CostTemporaryDifference,
	|	SUM(CostOfVNA.CostTargetFinancing)        AS CostTargetFinancing,
	|	SUM(CostOfVNA.CostTargetFinancingTA)      AS CostTargetFinancingTA,
	|	SUM(CostOfVNA.CostTargetFinancingPD)      AS CostTargetFinancingPD,
	|	SUM(CostOfVNA.CostTargetFinancingTD)      AS CostTargetFinancingTD
	|
	|INTO TTCostOfOriginalFA
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|
	|		INNER JOIN TT_CostOfVNA AS CostOfVNA
	|		ON CostOfVNA.Ref = FATable.Ref
	|			AND CostOfVNA.AccountingObject = FATable.FixedAsset
	|
	|GROUP BY
	|	FATable.Ref
	|
	|INDEX BY
	|	Ref
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTTDepreciationOfOriginalFA(Query, QueryTexts) Export

	TableName = "TTDepreciationOfOriginalFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextEmptyTableDepreciationVNA(Query, QueryTexts);
		
	QueryText = 
	"SELECT
	|	FATable.Ref                           AS Ref,
	|	SUM(DepreciationOfVNA.Depreciation)          AS Depreciation,
	|	SUM(DepreciationOfVNA.DepreciationLocal)      AS DepreciationLocal,
	|	SUM(DepreciationOfVNA.DepreciationInTaxAccounting)        AS DepreciationInTaxAccounting,
	|	SUM(DepreciationOfVNA.DepreciationPermanentDifferences)        AS DepreciationPermanentDifferences,
	|	SUM(DepreciationOfVNA.DepreciationTD)        AS DepreciationTD,
	|	SUM(DepreciationOfVNA.FixedAssetDepreciationTargetFinancing)        AS FixedAssetDepreciationTargetFinancing,
	|	SUM(DepreciationOfVNA.DepreciationTaxAccountingTargetFinancing)      AS DepreciationTaxAccountingTargetFinancing,
	|	SUM(DepreciationOfVNA.DepreciationTargetFinancingPD)      AS DepreciationTargetFinancingPD,
	|	SUM(DepreciationOfVNA.DepreciationOfTargetFinancingTD)      AS DepreciationOfTargetFinancingTD
	|INTO TTDepreciationOfOriginalFA
	|FROM
	|	DocumentDataFATable AS FATable
	|		INNER JOIN TT_DepreciationOfVNA AS DepreciationOfVNA
	|		ON DepreciationOfVNA.Ref = FATable.Ref
	|			AND DepreciationOfVNA.AccountingObject = FATable.FixedAsset
	|GROUP BY
	|	FATable.Ref";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

Procedure QueryTextTTReflectionOfIncomeExpenses(QueryTexts)

	TableName = "TTReflectionOfIncomeExpenses";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	CGUComposition.Organization AS Organization,
	|	DocumentData.Period AS DocumentDate,
	|	MAX(CGUComposition.Period) AS MaximumPeriod
	|INTO TTAllFAToSearchForCGU
	|FROM
	|	DocumentDataFATable AS FATable
	|		LEFT JOIN InformationRegister.CGUComposition AS CGUComposition
	|			INNER JOIN DocumentDataDetails AS DocumentData
	|			ON DocumentData.Organization = CGUComposition.Organization
	|			AND CGUComposition.Period <= DocumentData.Period
	|		ON FATable.FixedAsset = CGUComposition.NonCurrentAsset
	|GROUP BY
	|	FATable.FixedAsset,
	|	CGUComposition.Organization,
	|	DocumentData.Period
	|
	|INDEX BY
	|	Organization,
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAllFAToSearchForCGU.FixedAsset AS FixedAsset,
	|	TTAllFAToSearchForCGU.Organization AS Organization,
	|	TTAllFAToSearchForCGU.DocumentDate AS DocumentDate,
	|	ISNULL(CGUComposition.CGU, VALUE(Catalog.CashGeneratingUnits.EmptyRef)) AS CGU,
	|	ISNULL(TTAllFAToSearchForCGU.MaximumPeriod, TTAllFAToSearchForCGU.DocumentDate) AS DateOfLastChangeOfCGU
	|INTO TTAllAboutSiCGU
	|FROM
	|	TTAllFAToSearchForCGU AS TTAllFAToSearchForCGU
	|		LEFT JOIN InformationRegister.CGUComposition AS CGUComposition
	|		ON TTAllFAToSearchForCGU.Organization = CGUComposition.Organization
	|		AND TTAllFAToSearchForCGU.FixedAsset = CGUComposition.NonCurrentAsset
	|		AND TTAllFAToSearchForCGU.MaximumPeriod = CGUComposition.Period
	|
	|INDEX BY
	|	CGU,
	|	FixedAsset,
	|	DocumentDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAllAboutSiCGU.FixedAsset AS FixedAsset,
	|	TTAllAboutSiCGU.Organization AS Organization,
	|	TTAllAboutSiCGU.CGU AS CGU,
	|	TTAllAboutSiCGU.DateOfLastChangeOfCGU AS DateOfLastChangeOfCGU,
	|	ImpairmentFAFixedAssets.Ref.Date AS DateOfImpairment,
	|	ImpairmentFAFixedAssets.Ref AS ImpairmentDocument,
	|	1 AS SubqueryID
	|INTO TTAllImpairmentDocumentsForFA
	|FROM
	|	TTAllAboutSiCGU AS TTAllAboutSiCGU
	|		INNER JOIN Document.ImpairmentFA.FixedAssets AS ImpairmentFAFixedAssets
	|		ON TTAllAboutSiCGU.FixedAsset = ImpairmentFAFixedAssets.FixedAsset
	|		AND ImpairmentFAFixedAssets.Ref.Date <= TTAllAboutSiCGU.DocumentDate
	|		AND ImpairmentFAFixedAssets.Ref.Posted
	|WHERE
	|	TTAllAboutSiCGU.CGU = VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	TTAllAboutSiCGU.FixedAsset AS FixedAsset,
	|	TTAllAboutSiCGU.Organization AS Organization,
	|	TTAllAboutSiCGU.CGU AS CGU,
	|	TTAllAboutSiCGU.DateOfLastChangeOfCGU AS DateOfLastChangeOfCGU,
	|	ImpairmentOfVNAEGDS.Ref.Date AS Date,
	|	ImpairmentOfVNAEGDS.Ref AS Ref,
	|	2 AS SubqueryID
	|FROM
	|	TTAllAboutSiCGU AS TTAllAboutSiCGU
	|		INNER JOIN Document.ImpairmentFA.CashGeneratingUnits AS ImpairmentOfVNAEGDS
	|		ON TTAllAboutSiCGU.CGU = ImpairmentOfVNAEGDS.CGU
	|		AND ImpairmentOfVNAEGDS.Ref.Date <= TTAllAboutSiCGU.DocumentDate
	|		AND ImpairmentOfVNAEGDS.Ref.Posted
	|WHERE
	|	TTAllAboutSiCGU.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization,
	|	CGU,
	|	DateOfImpairment
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAllImpairmentDocumentsForFA.FixedAsset AS FixedAsset,
	|	TTAllImpairmentDocumentsForFA.Organization AS Organization,
	|	TTAllImpairmentDocumentsForFA.CGU AS CGU,
	|	MAX(TTAllImpairmentDocumentsForFA.DateOfImpairment) AS DateOfImpairment
	|INTO TTImpairmentDocumentFilter
	|FROM
	|	TTAllImpairmentDocumentsForFA AS TTAllImpairmentDocumentsForFA
	|GROUP BY
	|	TTAllImpairmentDocumentsForFA.FixedAsset,
	|	TTAllImpairmentDocumentsForFA.Organization,
	|	TTAllImpairmentDocumentsForFA.CGU
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization,
	|	CGU
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTAllImpairmentDocumentsForFA.FixedAsset AS FixedAsset,
	|	TTAllImpairmentDocumentsForFA.Organization AS Organization,
	|	TTAllImpairmentDocumentsForFA.ImpairmentDocument AS ImpairmentDocument
	|INTO TTSelectionOfImpairmentDocuments
	|FROM
	|	TTAllImpairmentDocumentsForFA AS TTAllImpairmentDocumentsForFA
	|		INNER JOIN TTImpairmentDocumentFilter AS TTImpairmentDocumentFilter
	|		ON TTImpairmentDocumentFilter.FixedAsset = TTAllImpairmentDocumentsForFA.FixedAsset
	|		AND TTImpairmentDocumentFilter.Organization = TTAllImpairmentDocumentsForFA.Organization
	|		AND TTImpairmentDocumentFilter.CGU = TTAllImpairmentDocumentsForFA.CGU
	|		AND TTImpairmentDocumentFilter.DateOfImpairment = TTAllImpairmentDocumentsForFA.DateOfImpairment
	|
	|INDEX BY
	|	ImpairmentDocument
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	TTSelectionOfImpairmentDocuments.FixedAsset AS NonCurrentAsset,
	|	ImpairmentFA.ExpenseItem AS ExpenseItem,
	|	ImpairmentFA.DimensionOfExpenses AS DimensionOfExpenses,
	|	ImpairmentFA.IncomeItem AS IncomeItem,
	|	ImpairmentFA.DimensionOfRevenue AS DimensionOfRevenue
	|INTO TTReflectionOfIncomeExpenses
	|FROM
	|	TTSelectionOfImpairmentDocuments AS TTSelectionOfImpairmentDocuments
	|		INNER JOIN Document.ImpairmentFA AS ImpairmentFA
	|		ON TTSelectionOfImpairmentDocuments.ImpairmentDocument = ImpairmentFA.Ref
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON TRUE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTAllFAToSearchForCGU;
	|DROP TTAllAboutSiCGU;
	|DROP TTAllImpairmentDocumentsForFA;
	|DROP TTImpairmentDocumentFilter;
	|DROP TTSelectionOfImpairmentDocuments";
	
	QueryTexts.Add(QueryText, TableName, False);
	
EndProcedure

Procedure QueryTextTableTTFADetails(QueryTexts)
	
	TableName = "TTFADetails";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTAccountingFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTLocationOfFA(QueryTexts);
	NonCurrentAssetsInternal.QueryTextTableTTVATTaxation(QueryTexts);
	
	QueryText =
	"SELECT
	|	FATable.Ref AS Ref,
	|	FATable.FixedAsset AS FixedAsset,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AttachingToExistingFixedAsset)
	|			THEN TTAccountingProcedureForRecipientSFA.FinancialAccountingGroup
	|		WHEN DocumentData.MergeOfSimilarFixedAssets
	|			THEN TTAccountingFA.FinancialAccountingGroup
	|		ELSE DocumentData.FinancialAccountingGroup
	|	END AS FinancialAccountingGroupOfRecipient,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AttachingToExistingFixedAsset)
	|			THEN TTAccountingProcedureForRecipientSFA.LineOfBusiness
	|		WHEN DocumentData.MergeOfSimilarFixedAssets
	|			THEN TTAccountingFA.LineOfBusiness
	|		ELSE DocumentData.LineOfBusiness
	|	END AS RecipientSLineOfBusiness,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AttachingToExistingFixedAsset)
	|			THEN TTVATTaxationOfRecipient.VATTaxation
	|		WHEN DocumentData.MergeOfSimilarFixedAssets
	|			THEN TTVATTaxation.VATTaxation
	|		ELSE DocumentData.VATTaxation
	|	END AS VATTaxationOfRecipient,
	|
	|	TTAccountingFA.LineOfBusiness AS LineOfBusiness,
	|	TTAccountingFA.FinancialAccountingGroup AS FinancialAccountingGroup,
	|	
	|	TTLocationOfFA.Leaseholder AS Leaseholder,
	|
	|	CASE
	|		WHEN DocumentData.BusinessOperation = VALUE(Enum.BusinessTransactions.AttachingToExistingFixedAsset)
	|			THEN TTLocationOfRecipient.Leaseholder
	|		ELSE TTLocationOfFA.Leaseholder
	|	END AS RecipientSTenant
	|
	|INTO TTFADetails
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTAccountingFA AS TTAccountingFA
	|		ON TTAccountingFA.Ref = FATable.Ref
	|			AND TTAccountingFA.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTAccountingFA AS TTAccountingProcedureForRecipientSFA
	|		ON TTAccountingProcedureForRecipientSFA.Ref = DocumentData.Ref
	|			AND TTAccountingProcedureForRecipientSFA.FixedAsset = DocumentData.FixedAsset
	|
	|		INNER JOIN TTLocationOfFA AS TTLocationOfFA
	|		ON TTLocationOfFA.Ref = FATable.Ref
	|			AND TTLocationOfFA.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTLocationOfFA AS TTLocationOfRecipient
	|		ON TTLocationOfRecipient.Ref = DocumentData.Ref
	|			AND TTLocationOfRecipient.FixedAsset = DocumentData.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxation
	|		ON TTVATTaxation.Ref = FATable.Ref
	|			AND TTVATTaxation.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TTVATTaxation AS TTVATTaxationOfRecipient
	|		ON TTVATTaxationOfRecipient.Ref = DocumentData.Ref
	|			AND TTVATTaxationOfRecipient.FixedAsset = DocumentData.FixedAsset
	|
	|INDEX BY
	|	Ref,
	|	FixedAsset";
	
	QueryTexts.Add(QueryText, TableName);

EndProcedure

Procedure QueryTextTableTTIsListOfAllFA(QueryTexts)

	TableName = "TTIsListOfAllFA";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;

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
	|FROM
	|	DocumentDataFATable AS FATable
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function RequestTextTTReflectedInLocalAccounting() Export

	Return MergeOfFixedAssetsLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

Function TextOfReflectionInLocalAccounting() Export

	Return MergeOfFixedAssetsLocalization.TextOfReflectionInLocalAccounting();

EndFunction

#EndRegion

#Region Print

Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	
	MergeOfFixedAssetsLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);

EndProcedure

Function GetDataForPrintedFormOS1(PrintParameters, ObjectsArray) Export

	Return MergeOfFixedAssetsLocalization.GetDataForPrintedFormOS1(ObjectsArray);

EndFunction

Function GetDataForPrintedFormOS4(ObjectsArray) Export

	Return MergeOfFixedAssetsLocalization.GetDataForPrintedFormOS4(ObjectsArray);

EndFunction
 
#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ArticleSelectionAndAnalyticsOptions = New Array;
	
	MergeOfFixedAssetsLocalization.AddOptionsForSelectingArticlesAndAnalytics(ArticleSelectionAndAnalyticsOptions);
	
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

#EndRegion

#EndRegion

#EndIf
