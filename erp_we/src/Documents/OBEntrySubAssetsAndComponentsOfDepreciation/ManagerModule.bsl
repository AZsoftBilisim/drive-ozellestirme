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
	DocumentMechanisms.Add("ImpairmentFA");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation") Then
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
		
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers);
		QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers);
		QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers);
		QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers);
		QueryTextTableFACost(QueryTexts, Registers);
		QueryTextTableFixedAssetsDepreciationCharge(QueryTexts, Registers);
		QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers);
		QueryTextTableCGUComposition(QueryTexts, Registers);
		QueryTextTableImpairmentFA(QueryTexts, Registers);
		QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers);
		OBEntrySubAssetsAndComponentsOfDepreciationLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

#EndRegion

#Region Commands

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

EndProcedure

#EndRegion

#Region FillingInAccordingToOperationalAccountingData

// Returns a table of values for filling in the balance entry document with data obtained from operational accounting data.
// 
// Parameters:
// 	Date - Date - The date on which balances are generated.
// 	BusinessOperation - EnumRef.BusinessTransactions - Business transaction for which balances are selected
// 	Companies - Array - Array containing elements of the reference Link type.Organizations for which balances are selected.
// 	AdditionalSelection - Structure - Structure containing the key and value of the additional selection.
// 	ParametersForFillingBalances - Structure - A structure that contains additional parameters that are necessary for filling in balances.
// 	
// Returns:
// 	ValueTable, Undefined - If there is data for this business operation, a table of values with fill values is returned for it.
//
Function BalancesByTypeOfOperation(Date, BusinessOperation, Companies, AdditionalSelection = Undefined, ParametersForFillingBalances = Undefined) Export
	
	Result = OBEntrySubAssetsAndComponentsOfDepreciationLocalization.BalancesByTypeOfOperation(
					Date, 
					Companies, 
					AdditionalSelection, 
					ParametersForFillingBalances);

	Return Result;
			
EndFunction

// Returns an array that contains the names of fields that need to be changed to generate a new document for entering balances.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - A business transaction for which key fields are defined.
// Returns:
// 	Array - An array containing field names.
//
Function KeyFieldsOfLocalAccountingByTypeOfOperation(BusinessOperation = Undefined) Export
	
	KeyAttributes = New Array;
	KeyAttributes.Add("Organization");
	KeyAttributes.Add("FixedAssetsLocation");
	
	Return KeyAttributes;
		
EndFunction

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
//  Settings - Structure - subsystem settings.
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

// 
// Parameters:
//  ObjectOrStringData - LineOfATabularSection - 
//  AuxiliaryAttributes - Structure - 
//  ItemDetailsParameters - Array of Structure -
// 
// Returns:
//  String - 
Function FillInDetailsDependingOnProperties(ObjectOrStringData, AuxiliaryAttributes, ItemDetailsParameters) Export

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
		
		If Action = "Clear"
			And (AttributeParameters.AttributeName = "CurrentcCostFinAcc"
				Or AttributeParameters.AttributeName = "CurrentcCostManAcc"
				Or AttributeParameters.AttributeName = "InitialCostLocalAccounting"
				Or AttributeParameters.AttributeName = "InitialCostMA"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationAccounting"
				Or AttributeParameters.AttributeName = "AccumulatedDepreciationManagementAccounting") Then
			
			ObjectOrStringData[AttributeParameters.AttributeName] = 0;
			ChangedBankingDetails.Add(AttributeParameters.AttributeName);
		EndIf;
		
		If AttributeParameters.AttributeName = "AccountingProcedureAC" Then
		
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				Enums.FARepaymentProcedure.DepreciationAccrual, 
				Undefined,
				ChangedBankingDetails);
		
		ElsIf AttributeParameters.AttributeName = "AccountingProcedureMA" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				Enums.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization,
				Undefined,
				ChangedBankingDetails);

		ElsIf AttributeParameters.AttributeName = "DepreciationAccrualAccounting" 
			Or AttributeParameters.AttributeName = "DepreciationAccrualManagementAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				True,
				False,
				ChangedBankingDetails);
				
		ElsIf AttributeParameters.AttributeName = "DepreciationMethodAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				Enums.AccrualMethodOfFixedAssetsDepreciation.Linear,
				Undefined,
				ChangedBankingDetails);
	
		ElsIf AttributeParameters.AttributeName = "DepreciationAccrualMethodManagementAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				Enums.AccrualMethodOfFixedAssetsDepreciation.Linear,
				Undefined,
				ChangedBankingDetails);

		ElsIf AttributeParameters.AttributeName = "UsefulLifeAccounting"
			Or AttributeParameters.AttributeName = "UsefulLifeManagementAccounting" Then
			
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				ObjectOrStringData.UsefulLifeAccounting,
				0,
				ChangedBankingDetails);

		ElsIf AttributeParameters.AttributeName = "AccelerationFactorAccounting"
			Or AttributeParameters.AttributeName = "AccelerationFactorManagementAccounting" Then
		
			NonCurrentAssetsInternal.FillClearBankingDetails(
				ObjectOrStringData,
				AttributeParameters.AttributeName, 
				Action, 
				1,
				0,
				ChangedBankingDetails);
				
		EndIf;
		
		OBEntrySubAssetsAndComponentsOfDepreciationLocalization.FillInDetailsDependingOnProperties(
			ObjectOrStringData, AuxiliaryAttributes, AttributeParameters, Action, ChangedBankingDetails);
			
	EndDo; 
	
	Return StrConcat(ChangedBankingDetails, ",");
	
EndFunction

// Auxiliary details.
// 
// Parameters:
//  Object - DocumentObject.OBEntrySubAssetsAndComponentsOfDepreciation -
//  ThisIsStringData - Boolean -
// 
// Returns:
//  FixedStructure - 
Function AuxiliaryAttributes(Object, ThisIsStringData) Export

	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("PostInFinancialAndTaxAccounting", Object.PostInFinancialAndTaxAccounting);
	AuxiliaryAttributes.Insert("RecordInOperationalAccounting", Object.RecordInOperationalAccounting);
	AuxiliaryAttributes.Insert("RecordInMA", Object.RecordInMA);
	AuxiliaryAttributes.Insert("PostInAccounting", Object.RecordInLocalAccounting);
	AuxiliaryAttributes.Insert("RecordInTA", False);
	AuxiliaryAttributes.Insert("Organization", Object.Organization);
	AuxiliaryAttributes.Insert("BusinessOperation", Enums.BusinessTransactions.OBEntrySubAssetsAndComponentsOfDepreciation);
	AuxiliaryAttributes.Insert("Date", Object.Date);
	AuxiliaryAttributes.Insert("AccountingStartDate", '000101010000');
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	AuxiliaryAttributes.Insert("UseLocal", LocalAccntingServer.ReglRecordsAreMaintained(Object.Date));
	AuxiliaryAttributes.Insert("AccountingPolicyForFixedAssets", AccountingPoliciesTaxSettingsCached.AccountingPolicyForFixedAssets(Object.Organization, ?(Object.Date <> '000101010000', EndOfMonth(Object.Date), CurrentSessionDate())));
	AuxiliaryAttributes.Insert("UseSeparateFAAccountingByTaxation", GetFunctionalOption("UseSeparateFAAccountingByTaxation"));
	AuxiliaryAttributes.Insert("LeaseAccountingAccordingToFSB25_2018IsUsed", LeasedAssetAccounting.LeaseAccountingAccordingToFSB25_2018IsUsed(Object.Organization, Object.Date));
	AuxiliaryAttributes.Insert("UseFixedAssetImpairment", GetFunctionalOption("UseFixedAssetImpairment"));
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", CurrencyOfMan = ComplCurrency);
	
	AuxiliaryAttributes.Insert(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, ?(Object.Date <> '000101010000', EndOfMonth(Object.Date), CurrentSessionDate())));
	
	AuxiliaryAttributes.Insert("UUAccountingIsAvailable", Object.RecordInManAccounting);
	AuxiliaryAttributes.Insert("BUAccountingIsAvailable", Object.RecordInLocalAccounting And AuxiliaryAttributes.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("AccountingIsAvailableWELL", False);
		
	OBEntrySubAssetsAndComponentsOfDepreciationLocalization.AddAuxiliaryDetails(Object, ThisIsStringData, AuxiliaryAttributes);
	
	AuxiliaryAttributes = New FixedStructure(AuxiliaryAttributes);
	
	Return AuxiliaryAttributes;
	
EndFunction

Procedure FillInDefaultValues(RowData, Object) Export
	
	If Not ValueIsFilled(RowData.FinancialAccountingGroup) Then
		RowData.FinancialAccountingGroup = Catalogs.NonCurrentAssetsAccountingGroups.DefaultValue(
												Enums.KindsOfNonCurrentAssets.FixedAsset);
	EndIf;
	
EndProcedure

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
	
	FullDocumentName = "Document.OBEntrySubAssetsAndComponentsOfDepreciation";
	
	ParameterValues = ValuesOfHoldingParameters();
	
	RequestHasSource = True;
	RedefiningParameterCalculation = New Structure;
	
	QueryText = Undefined;
	SynonymForDocumentTable = Undefined;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
				
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
				
	EndIf;
				
	If QueryText = Undefined Then
		
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of query text for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of query text for generating records of register %RegisterName% is not implemented.';
							|it = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = 'Belge %FullDocumentName%''de, kayıt %RegisterName%''ye göre hareket oluşumu isteğinin metninin uyarlanmasını uygulamamıştır'");
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

	GetDocumentData(Query);
	
	QueryText =
	"SELECT
	|	DocumentData.Ref                               AS Ref,
	|	DocumentData.Date                                 AS Period,
	|	DocumentData.Number                                AS Number,
	|	DocumentData.Organization                          AS Organization,
	|	DocumentData.FixedAssetsLocation                      AS FixedAssetsLocation,
	|	DocumentData.EmployeeResponsible                        AS EmployeeResponsible,
	|	DocumentData.Comment                          AS Comment,
	|	DocumentData.Posted                             AS Posted,
	|	DocumentData.DeletionMark                      AS DeletionMark,
	|	DocumentData.RecordInLocalAccounting                   AS RecordInLocalAccounting,
	|	DocumentData.RecordInManAccounting                    AS RecordInManAccounting,
	|	DocumentData.PostInFinancialAndTaxAccounting                       AS PostInFinancialAndTaxAccounting,
	|	DocumentData.RecordInOperationalAccounting            AS RecordInOperationalAccounting,
	|	DocumentData.RecordInMA                          AS RecordInMA
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Query.Text = QueryText;
	Query.SetParameter("Ref", DocumentRef);
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

Procedure GetDocumentData(Query)
	
	ListOfRequests = New Array;
	
	#Region DocumentDataDetails
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Organization.ParentCompany AS ParentCompany
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
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
	|	DocumentTable.FixedAsset AS FixedAsset,
	|	DocumentTable.FixedAssetOwner AS FixedAssetOwner,
	|	DocumentTable.FixedAsset AS AccountingObject
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref = &Ref
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.OBEntrySubAssetsAndComponentsOfDepreciation"));
	ValuesOfHoldingParameters.Insert("AccountingStartDate", NonCurrentAssetsLocalization.StartDateOfCapitalAssetsAccounting24());
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Nhập số dư bộ phận và thành phần khấu hao';
															|ru = 'Ввод остатков узлов, компонентов амортизации';
															|en = 'OB entry: sub-assets and components of depreciation'; fa = 'ورود مانده افتتاحیه: دارایی‌های فرعی و اجزای استهلاک';
															|it = 'Ввод остатков узлов, компонентов амортизации';
															|pl = 'OB entry: sub-assets and components of depreciation';
															|tr = 'Bakiye girişi: alt varlıklar ve amortisman bileşenleri'"));
	ValuesOfHoldingParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.OBEntrySubAssetsAndComponentsOfDepreciation);
	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.OBEntrySubAssetsAndComponentsOfDepreciation);
	
	If Attributes <> Undefined Then
		
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		
		ValuesOfHoldingParameters.Insert(
			"FALocalAccountingIsConductedIndependently", 
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Attributes.Organization, Attributes.Period));
		
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
	|	&Ref                                 AS Ref,
	|	&Period                                 AS IBDocumentDate,
	|	&Number                                  AS IBDocumentNumber,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&FixedAssetsLocation                        AS Department,
	|	UNDEFINED                            AS Counterparty,
	|	&EmployeeResponsible                          AS EmployeeResponsible,
	|	&Comment                            AS Comment,
	|	&Posted                               AS Posted,
	|	&DeletionMark                        AS DeletionMark,
	|	FALSE                                    AS AdditionalRecord,
	|	&Period                                 AS SourceDocumentDate,
	|	&NumberForPrinting                          AS SourceDocumentNumber,
	|	FALSE                                    AS ReverseTransactionCorrection,
	|	UNDEFINED                            AS ReversedDocument,
	|	UNDEFINED                            AS CorrectedDocument,
	|	&Period                                 AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers)
	
	RegisterName = "FixedAssetsDocuments";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	ISNULL(FATable.LineNumber-1, 0)    AS RecNo,
	|	&Ref                                 AS Ref,
	|	&Period                                 AS Date,
	|	&Organization                            AS Organization,
	|	&FixedAssetsLocation                        AS Department,
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&RecordInLocalAccounting                     AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting,
	|	FATable.FixedAsset              AS FixedAsset
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation AS DocumentData
	|
	|		LEFT JOIN Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = OBEntrySubAssetsAndComponentsOfDepreciationLocalization.QueryTextTableInitialFixedAssetsInformation(QueryTexts);
	
	If QueryText = Undefined Then
		
		NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
			
		QueryText =
		"SELECT
		|	&Ref                         AS Recorder,
		|	&Period                         AS Period,
		|	FATable.FixedAsset      AS FixedAsset,
		|	&Organization                    AS Organization,
		|
		|	CASE 
		|		WHEN &RecordInLocalAccounting 
		|			THEN FATable.DateOfRecognitionAccounting 
		|		ELSE ISNULL(TTInitialInformationFA.CommissioningDateAC, DATETIME(1, 1, 1))
		|	END                           AS CommissioningDateAC,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting 
		|			THEN FATable.DateOfRecognitionManagementAccounting 
		|		ELSE ISNULL(TTInitialInformationFA.CommissioningDateMA, DATETIME(1, 1, 1))
		|	END                           AS CommissioningDateMA,
		|
		|	CASE
		|		WHEN &RecordInLocalAccounting
		|			THEN &Ref 
		|		ELSE ISNULL(TTInitialInformationFA.CommissioningDocumentAC, UNDEFINED)
		|	END                           AS CommissioningDocumentAC,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting
		|			THEN &Ref 
		|		ELSE ISNULL(TTInitialInformationFA.CommissioningDocumentMA, UNDEFINED)
		|	END                           AS CommissioningDocumentMA,
		|
		|	CASE 
		|		WHEN &RecordInLocalAccounting 
		|			THEN FATable.DepreciationMethodAccounting 
		|		ELSE ISNULL(TTInitialInformationFA.DepreciationMethodAccounting, UNDEFINED)
		|	END                           AS DepreciationMethodAccounting,
		|
		|	CASE 
		|		WHEN &RecordInLocalAccounting 
		|			THEN FATable.AccountingProcedureAC 
		|		ELSE ISNULL(TTInitialInformationFA.AccountingProcedureAC, UNDEFINED)
		|	END                           AS AccountingProcedureAC,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting 
		|			THEN FATable.AccountingProcedureMA 
		|		ELSE ISNULL(TTInitialInformationFA.AccountingProcedureMA, UNDEFINED)
		|	END                           AS AccountingProcedureMA,
		|
		|	CASE 
		|		WHEN &RecordInLocalAccounting 
		|			THEN FATable.InitialCostLocalAccounting 
		|		ELSE ISNULL(TTInitialInformationFA.InitialCostLocalAccounting, 0)
		|	END AS InitialCostLocalAccounting,
		|
		|	CASE 
		|		WHEN &RecordInManAccounting 
		|			THEN FATable.InitialCostMA 
		|		ELSE ISNULL(TTInitialInformationFA.InitialCostMA, 0)
		|	END AS InitialCostMA
		|
		|FROM
		|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
		|
		|		LEFT JOIN TTInitialInformationFA AS TTInitialInformationFA
		|		ON TTInitialInformationFA.FixedAsset = FATable.FixedAsset
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                         AS Recorder,
		|	&Period                         AS Period,
		|	FATable.FixedAsset      AS FixedAsset,
		|	&Organization                    AS Organization,
		|
		|	FATable.DateOfRecognitionManagementAccounting  AS CommissioningDateAC,
		|	FATable.DateOfRecognitionManagementAccounting  AS CommissioningDateMA,
		|
		|	&Ref                         AS CommissioningDocumentAC,
		|	&Ref                         AS CommissioningDocumentMA,
		|
		|	FATable.DepreciationAccrualMethodManagementAccounting AS DepreciationMethodAccounting,
		|
		|	CASE FATable.AccountingProcedureMA
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.NotAccrueDepreciationOrAmortization)
		|			THEN VALUE(Enum.FARepaymentProcedure.CostIsNotRedeemable)
		|		WHEN VALUE(Enum.FixedAssetValueRegistrationProcedure.DepreciationIsAccrued)
		|			THEN VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued)
		|	END AS AccountingProcedureAC,
		|
		|	FATable.AccountingProcedureMA        AS AccountingProcedureMA,
		|
		|	FATable.InitialCostLocalAccounting AS InitialCostLocalAccounting,
		|	FATable.InitialCostMA AS InitialCostMA
		|
		|FROM
		|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &RecordInOperationalAccounting
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;

	QueryTextTableTTTableOfOwners(QueryTexts);
	
	NonCurrentAssets.QueryTextSliceOfLastRegisters(
		"FALocation", "TTLocationOfOwners", "TTTableOfOwners", QueryTexts);
		
	QueryText = 
	"SELECT
	|	&Ref                       AS Recorder,
	|	&Period                       AS Period,
	|	&Organization                  AS Organization,
	|	FATable.FixedAsset    AS FixedAsset,
	|	OwnerInformation.FinanciallyLiablePerson         AS FinanciallyLiablePerson,
	|
	|	&FixedAssetsLocation              AS FixedAssetsLocation,
	|
	|	OwnerInformation.LocationAddress AS LocationAddress,
	|	OwnerInformation.LocationAddressValue AS LocationAddressValue,
	|	OwnerInformation.Leaseholder AS Leaseholder,
	|	OwnerInformation.LeaseholderBusinessUnit AS LeaseholderBusinessUnit,
	|	OwnerInformation.LeaseholderEmployeeInCharge AS LeaseholderEmployeeInCharge,
	|
	|	&RecordInLocalAccounting           AS RecordInLocalAccounting,
	|	&RecordInManAccounting            AS RecordInManAccounting
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
	|
	|		LEFT JOIN TTLocationOfOwners AS OwnerInformation
	|		ON OwnerInformation.Ref = FATable.Ref 
	|			AND OwnerInformation.FixedAsset = FATable.FixedAssetOwner 
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                 AS Recorder,
	|	&Period                                 AS Period,
	|	&Organization                            AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	FATable.FinancialAccountingGroup        AS FinancialAccountingGroup,
	|	FATable.LineOfBusiness       AS LineOfBusiness,
	|	FATable.RunningTimeValue           AS RunningTimeValue,
	|	FATable.EstimatedRunningTime                AS EstimatedRunningTime,
	|	&RecordInLocalAccounting                     AS RecordInLocalAccounting,
	|	&RecordInManAccounting                      AS RecordInManAccounting
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableAccountingProcedureForOSBU(QueryTexts, Registers)

	RegisterName = "AccountingProcedureForOSBU";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryTextTableTTTableOfOwners(QueryTexts);

	QueryText = OBEntrySubAssetsAndComponentsOfDepreciationLocalization.QueryTextTableAccountingProcedureForOSBU(QueryTexts);
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	FATable.FixedAsset                       AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|	FATable.DepreciationAccrualAccounting                 AS DepreciationAccrualAccounting,
		|	FATable.ExpenseRecordMethodAC              AS ExpenseRecordMethodAC,
		|	FATable.ExpenseItemAccounting                       AS ExpenseItemAccounting,
		|	FATable.ExpensesDimensionAccounting                    AS ExpensesDimensionAccounting,
		|	FATable.DepartmentACC                        AS DepartmentACC,
		|	FATable.LineOfBusinessBookkeeping              AS LineOfBusinessBookkeeping
		|
		|FROM
		|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &RecordInLocalAccounting
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Period                                          AS Period,
		|	&Organization                                     AS Organization,
		|	FATable.FixedAsset                       AS FixedAsset,
		|	VALUE(Enum.FixedAssetsStates.Recognized_) AS BUState,
		|	FATable.DepreciationAccrualManagementAccounting                 AS DepreciationAccrualAccounting,
		|	FATable.MethodForReflectingMaExpenses              AS ExpenseRecordMethodAC,
		|	FATable.ExpenseItemManagementAccounting                       AS ExpenseItemAccounting,
		|	FATable.ExpensesDimensionManagementAccounting                    AS ExpensesDimensionAccounting,
		|	FATable.BusinessUnitManagementAccounting                        AS DepartmentACC,
		|	FATable.LineOfBusinessManagementAccounting              AS LineOfBusinessBookkeeping
		|
		|FROM
		|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &RecordInLocalAccounting
		|	AND &RecordInOperationalAccounting
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFixedAssetsAccountingProcedureManagementAccounting(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedureManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                          AS Recorder,
	|	&Period                                          AS Period,
	|	&Organization                                     AS Organization,
	|	FATable.FixedAsset                       AS FixedAsset,
	|	VALUE(Enum.FixedAssetsStates.Recognized_) AS State,
	|	FATable.DepreciationAccrualManagementAccounting                 AS AccrueDepreciationOrAmortization,
	|
	|	CASE 
	|		WHEN FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOrAmortization)
	|				AND FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.AccrueDepreciationOnRecognition)
	|				AND FATable.AccountingProcedureMA <> VALUE(Enum.FixedAssetValueRegistrationProcedure.DoNotTakeIntoAccountIncludeInExpenses)
	|			
	|			THEN VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|
	|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND &RecordInManAccounting
	|				AND &RecordInLocalAccounting
	|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN FATable.ExpenseRecordMethodAC
	|
	|		ELSE FATable.MethodForReflectingMaExpenses 
	|
	|	END AS ExpensesPostingMethod,
	|
	|	CASE 
	|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND &RecordInManAccounting
	|				AND &RecordInLocalAccounting
	|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN FATable.ExpenseItemAccounting
	|
	|		ELSE FATable.ExpenseItemManagementAccounting 
	|
	|	END AS ExpenseItem,
	|
	|	CASE 
	|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND &RecordInManAccounting
	|				AND &RecordInLocalAccounting
	|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN FATable.ExpensesDimensionAccounting
	|
	|		ELSE FATable.ExpensesDimensionManagementAccounting
	| 
	|	END AS DimensionOfExpenses,
	|
	|	CASE 
	|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND &RecordInManAccounting
	|				AND &RecordInLocalAccounting
	|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN FATable.DepartmentACC
	|
	|		ELSE FATable.BusinessUnitManagementAccounting
	| 
	|	END AS Department,
	|
	|	CASE 
	|		WHEN FATable.ExpenseItemManagementAccounting = VALUE(ChartOfCharacteristicTypes.ExpenseItems.EmptyRef)
	|				AND &RecordInManAccounting
	|				AND &RecordInLocalAccounting
	|				AND (FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationAccrual)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.AccrueDepreciationOnRecognition)
	|					OR FATable.AccountingProcedureAC = VALUE(Enum.FARepaymentProcedure.DepreciationIsAccrued))
	|
	|			THEN FATable.LineOfBusinessBookkeeping
	|
	|		ELSE FATable.LineOfBusinessManagementAccounting
	| 
	|	END AS LineOfBusiness,
	|
	|	FALSE AS TransferExpensesToAnotherCompany,
	|	UNDEFINED AS CompanyRecipientOfExpenses
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInManAccounting
	|	AND &RecordInOperationalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableOSBUDepreciationParameters(QueryTexts, Registers)
	
	RegisterName = "OSBUDepreciationParameters";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = OBEntrySubAssetsAndComponentsOfDepreciationLocalization.QueryTextTableOSBUDepreciationParameters();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	&Ref                               AS Recorder,
		|	&Period                               AS Period,
		|	&Organization                          AS Organization,
		|	FATable.FixedAsset            AS FixedAsset,
		|
		|	FATable.UsefulLifeAccounting         AS UsefulLifeMonthsAC,
		|	FATable.AccelerationFactorAccounting      AS AccelerationFactor,
		|	FATable.ResidualValueLocal AS ResidualValueMan,
		|	FATable.EstimatedRunningTime              AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|	FATable.UsefulLifeAccounting         AS UsefulLifeForCalculatingDepreciationMonth,
		|	FATable.DateOfRecognitionAccounting        AS LastChangeDate
		|
		|FROM
		|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &FALocalAccountingIsConductedIndependently
		|	AND &RecordInLocalAccounting
		|	AND &RecordInOperationalAccounting
		|
		|UNION ALL
		|
		|SELECT
		|	&Ref                               AS Recorder,
		|	&Period                               AS Period,
		|	&Organization                          AS Organization,
		|	FATable.FixedAsset            AS FixedAsset,
		|
		|	FATable.UsefulLifeManagementAccounting         AS UsefulLifeMonthsAC,
		|	FATable.AccelerationFactorManagementAccounting      AS AccelerationFactor,
		|	FATable.ResidualValueLocal AS ResidualValueMan,
		|	FATable.EstimatedRunningTime              AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
		|	FATable.UsefulLifeManagementAccounting         AS UsefulLifeForCalculatingDepreciationMonth,
		|	FATable.DateOfRecognitionManagementAccounting        AS LastChangeDate
		|
		|FROM
		|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND NOT &FALocalAccountingIsConductedIndependently
		|	AND &RecordInLocalAccounting
		|	AND &RecordInOperationalAccounting
		|
		|";
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetDepreciationParametersManagementAccounting(QueryTexts, Registers)
	
	RegisterName = "FixedAssetDepreciationParametersManagementAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                                      AS Recorder,
	|	&Period                                      AS Period,
	|	FATable.DateOfRecognitionManagementAccounting               AS LastChangeDate,
	|	&Organization                                 AS Organization,
	|	FATable.FixedAsset                   AS FixedAsset,
	|	FATable.UsefulLifeManagementAccounting                AS UsefulLifeMonths,
	|	FATable.UsefulLifeManagementAccounting                AS UsefulLifeForCalculatingDepreciationMonth,
	|	FATable.EstimatedRunningTime                     AS VolumeOfProductsWorksForCalculatingDepreciationInPhysicalUnits,
	|	FATable.AccelerationFactorManagementAccounting             AS AccelerationFactor,
	|	FATable.DepreciationAccrualMethodManagementAccounting       AS DepreciationMethod,
	|	FATable.ResidualValueMan            AS ResidualValueMan,
	|	FATable.ResidualValueLocal        AS ResidualValueLocal,
	|
	|	FATable.CurrentcCostManAcc                 AS CostUsedToCalculateDepreciationManag,
	|	FATable.CurrentcCostFinAcc                 AS CostUsedToCalculateDepreciationLocal
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInManAccounting
	|	AND &RecordInOperationalAccounting
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = OBEntrySubAssetsAndComponentsOfDepreciationLocalization.QueryTextTableFACost();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Receipt)       AS RecordType,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	&FixedAssetsLocation                             AS Department,
		|	FATable.FixedAsset                   AS FixedAsset,
		|	FATable.FinancialAccountingGroup             AS FinancialAccountingGroup,
		|	FATable.LineOfBusiness            AS LineOfBusiness,
		|
		|	&RecordInLocalAccounting                          AS RecordInLocalAccounting,
		|	&RecordInManAccounting                           AS RecordInManAccounting,
		|
		|	FATable.CurrentcCostManAcc                 AS Cost,
		|	FATable.CurrentcCostFinAcc                 AS LocalCost,
		|
		|	FATable.RowID AS FinRecordID,
		|	VALUE(Enum.BusinessTransactions.OBEntryFixedAssetsCosts)  AS BusinessOperation,
		|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryFixedAssetsCosts) AS BusinessTransactionSetting
		|
		|FROM
		|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|	AND (FATable.CurrentcCostManAcc <> 0
		|		OR FATable.CurrentcCostFinAcc <> 0)
		|";
	
	EndIf; 
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFixedAssetsDepreciationCharge(QueryTexts, Registers)

	RegisterName = "FixedAssetsDepreciationCharge";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText = OBEntrySubAssetsAndComponentsOfDepreciationLocalization.QueryTextTableFixedAssetsDepreciationCharge();
	
	If QueryText = Undefined Then
	
		QueryText =
		"SELECT
		|	VALUE(AccumulationRecordType.Expense)       AS RecordType,
		|	&Ref                                      AS Recorder,
		|	&Period                                      AS Period,
		|	&Organization                                 AS Organization,
		|	&FixedAssetsLocation                             AS Department,
		|	FATable.FixedAsset                   AS FixedAsset,
		|	FATable.FinancialAccountingGroup             AS FinancialAccountingGroup,
		|	FATable.LineOfBusiness            AS LineOfBusiness,
		|	VALUE(Enum.BusinessTransactions.OBEntryFixedAssetDepreciationCharge)  AS BusinessOperation,
		|	FATable.AccumulatedDepreciationManagementAccounting           AS Depreciation,
		|	FATable.AccumulatedDepreciationAccounting           AS DepreciationLocal,
		|	FATable.RowID                AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.OBEntryFixedAssetDepreciationCharge) AS BusinessTransactionSetting
		|
		|FROM
		|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
		|
		|WHERE
		|	FATable.Ref = &Ref
		|	AND &RecordInOperationalAccounting
		|	AND (FATable.AccumulatedDepreciationManagementAccounting <> 0
		|		OR FATable.AccumulatedDepreciationAccounting <> 0)
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableCGUComposition(QueryTexts, Registers)
	
	RegisterName = "CGUComposition";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	FATable.Ref               AS Recorder,
	|	FATable.Ref.Date          AS Period,
	|	FATable.Ref.Organization   AS Organization,
	|	FATable.FixedAsset     AS NonCurrentAsset,
	|	FATable.CGU                 AS CGU
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND FATable.CGU <> VALUE(Catalog.CashGeneratingUnits.EmptyRef)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableImpairmentFA(QueryTexts, Registers)
	
	RegisterName = "ImpairmentFA";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	FATable.Ref                       AS Recorder,
	|	FATable.Ref.Date                  AS Period,
	|	FATable.Ref.Organization           AS Organization,
	|	FATable.FixedAsset             AS NonCurrentAsset,
	|	FATable.CGU                         AS CGU,
	|	&FixedAssetsLocation                       AS Department,
	|	FATable.LineOfBusiness      AS LineOfBusiness,
	|	FATable.FinancialAccountingGroup       AS FinancialAccountingGroup,
	|	FATable.ImpairmentAC                AS ImpairmentLocalAssets,
	|	FATable.ImpairmentMA                AS ImpairmenMan,
	|	FATable.RowID          AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.EnterBalanceOfFAImpairment) AS BusinessTransactionSetting
	|
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting
	|	AND (FATable.ImpairmentAC <> 0
	|		OR FATable.ImpairmentMA <> 0)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableSubAssetsComponentsOfDepreciation(QueryTexts, Registers)
	
	RegisterName = "SubAssetsComponentsOfDepreciation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref AS Recorder,
	|	&Period AS Period,
	|	FATable.FixedAsset AS SubAssetComponent,
	|	FATable.FixedAssetOwner AS FixedAsset
	|FROM
	|	Document.OBEntrySubAssetsAndComponentsOfDepreciation.FA AS FATable
	|
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &RecordInOperationalAccounting";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Function QueryTextTableDocumentPostingInFinancialAccounting(QueryTexts, Registers)
	
	RegisterName = "DocumentPostingInFinancialAccounting";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                        AS Period,
	|	&Organization                   AS Organization,
	|	BEGINOFPERIOD(&Period, DAY)   AS DateRecord,
	|	&BusinessOperation         AS BusinessOperation
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableTTTableOfOwners(QueryTexts)
	
	TableName = "TTTableOfOwners";
	
	If DocumentsPosting.ThereIsQueryTable(TableName, QueryTexts) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Period AS Period,
	|	DocumentData.Organization AS Organization,
	|	FATable.FixedAssetOwner AS FixedAsset
	|
	|INTO TTTableOfOwners
	|
	|FROM
	|	DocumentDataFATable AS FATable
	|	
	|		INNER JOIN DocumentDataDetails AS DocumentData
	|		ON DocumentData.Ref = FATable.Ref
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|";
	
	QueryTexts.Add(QueryText, TableName);
	
EndProcedure

#EndRegion

#Region ConductingRegulatedAccounting

Function TextOfReflectionInLocalAccounting() Export

	Return OBEntrySubAssetsAndComponentsOfDepreciationLocalization.TextOfReflectionInLocalAccounting();

EndFunction

Function RequestTextTTReflectedInLocalAccounting() Export

	Return OBEntrySubAssetsAndComponentsOfDepreciationLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion

#Region Other

Function ItemsAndDimensionsSelectionParameters() Export
	
	ItemsAndDimensionsSelectionParameters = New Array;
	
	// ExpenseItemAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.FA";
	ChoiceParameters.AssetRef = "ExpenseItemAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	// ExpenseItemManagementAccounting
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.FA";
	ChoiceParameters.AssetRef = "ExpenseItemManagementAccounting";
	ChoiceParameters.AvailabilityByOperation = Undefined;
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "ExpensesDimensionManagementAccounting";
	
	ChoiceParameters.FormItems.AssetRef.Add("ExpenseItemManagementAccounting");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ExpensesDimensionManagementAccounting");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	
	Return ItemsAndDimensionsSelectionParameters;
	
EndFunction

Procedure UpdateDataInLinkedTable(TS, NewData, RowCode) Export
	
	SearchForStrings = New Structure("RowCode", RowCode);
	LinesToDelete = TS.FindRows(SearchForStrings);
	
	For Each TableRow In LinesToDelete Do
		TS.Delete(TableRow);
	EndDo;
	
	For Each TableRow In NewData Do
		NewRow = TS.Add();
		FillPropertyValues(NewRow, TableRow);
		NewRow.RowCode = RowCode;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
