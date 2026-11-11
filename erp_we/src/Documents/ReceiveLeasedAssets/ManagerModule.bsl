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
	
	DocumentMechanisms.Add("FixedAssets");
	DocumentMechanisms.Add("DocumentsRegistry");
	
	ReceiveLeasedAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ReceiveLeasedAssets") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers);
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableFALocation(QueryTexts, Registers);
		QueryTextTableLeasedAsset(QueryTexts, Registers);
		QueryTextTableFACost(QueryTexts, Registers);
	
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
	
		ReceiveLeasedAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
	Return MovementTables;
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.ReturnLeasedAssets.AddGenerateCommand(GenerationCommands);
	Documents.FixedAssetCostAndDepreciationAdjustment.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the document "receipt of leased assets".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiveLeasedAssets) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReceiveLeasedAssets.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReceiveLeasedAssets);
		CreateBasedOnCommand.FunctionalOptions = "UseNonCurrentAssets2_2,UseNonCurrentAssets2_4";
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
	
EndProcedure

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

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.ReceiveLeasedAssets";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
		
	ElsIf RegisterName = "FixedAssetsDocuments" Then
		
		QueryText = QueryTextTableFixedAssetsDocuments(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	ElsIf RegisterName = "LeasedAsset" Then
		
		QueryText = QueryTextTableLeasedAsset(QueryTexts, RegisterName);
		SynonymForDocumentTable = "FATable";
		
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

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeletionMark,
	|	DocumentData.Posted,
	|	DocumentData.Comment,
	|	DocumentData.EmployeeResponsible,
	|	DocumentData.Organization,
	|	DocumentData.Department,
	|	DocumentData.FinanciallyLiablePerson,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract,
	|	DocumentData.GLAccount,
	|	DocumentData.FinancialAccountingGroup
	|FROM
	|	Document.ReceiveLeasedAssets AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("Boundary", New Boundary(BegOfMonth(Attributes.Period), BoundaryType.Excluding));
	
	ValuesOfHoldingParameters = ValuesOfHoldingParameters(Attributes);
	For Each KeyAndValue In ValuesOfHoldingParameters Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo; 
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ReceiveLeasedAssets"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.ReceiveLeasedAssets);
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Tiếp nhận TSCĐ cho thuê';
															|ru = 'Поступление арендованных ОС';
															|en = 'Receive leased assets'; fa = 'Receive leased assets';
															|it = 'Entrata di Immobilizzazioni locate';
															|pl = 'Wpływ wynajmowanych środków trwałych';
															|tr = 'Kiralanan varlıkların teslim alınması'"));
	ValuesOfHoldingParameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());

	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
		ValuesOfHoldingParameters.Insert("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Attributes.Period));
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
	|	&Counterparty                             AS Counterparty,
	|	&Contract                                AS Contract,
	|	&Department                          AS Department,
	|	&BusinessOperation                  AS BusinessOperation,
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
	
	QueryTexts.Add(QueryText, "TableDocumentRegistry", True);
	
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
	|	&Department                          AS Department,
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	FALSE                                    AS RecordInManAccounting,
	|	FATable.FixedAsset              AS FixedAsset
	|FROM
	|	Document.ReceiveLeasedAssets AS DocumentData
	|		LEFT JOIN Document.ReceiveLeasedAssets.FA AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, "TableFADocuments", True);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFixedAssetsAccountingProcedure(QueryTexts, Registers)

	RegisterName = "FixedAssetsAccountingProcedure";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                                 AS Period,
	|	&Organization                            AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	&FinancialAccountingGroup                 AS FinancialAccountingGroup,
	|	&GLAccount                              AS OffBalanceAccount,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	FALSE                                    AS RecordInManAccounting
	|FROM
	|	Document.ReceiveLeasedAssets.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)
	
	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                      AS Period,
	|	FATable.FixedAsset   AS FixedAsset,
	|	&Organization                 AS Organization,
	|	&Counterparty                  AS Counterparty,
	|	&Contract                     AS Contract,
	|	FATable.SecurityDepositValue AS InitialCostLocalAccounting,
	|	&Period                      AS CommissioningDateAC,
	|	&Ref                      AS CommissioningDocumentAC
	|FROM
	|	Document.ReceiveLeasedAssets.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName, True);
	
EndProcedure

Procedure QueryTextTableFALocation(QueryTexts, Registers)
	
	RegisterName = "FALocation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	&Ref                       AS Recorder,
	|	&Period                       AS Period,
	|	&Organization                  AS Organization,
	|	FATable.FixedAsset    AS FixedAsset,
	|	&FinanciallyLiablePerson                          AS FinanciallyLiablePerson,
	|	&Department                AS FixedAssetsLocation,
	|	UNDEFINED                  AS LocationAddress,
	|	TRUE                        AS RecordInLocalAccounting,
	|	FALSE                          AS RecordInManAccounting
	|FROM
	|	Document.ReceiveLeasedAssets.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Function QueryTextTableLeasedAsset(QueryTexts, Registers)
	
	RegisterName = "LeasedAsset";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	&Period                       AS Period,
	|	FATable.FixedAsset    AS FixedAsset,
	|	&Organization                  AS Organization,
	|	&Counterparty                   AS Counterparty,
	|	&Contract                      AS Contract,
	|	FATable.SecurityDepositValue  AS Cost,
	|	VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting) AS State
	|FROM
	|	Document.ReceiveLeasedAssets.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableFACost(QueryTexts, Registers)

	RegisterName = "FACost";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period                                AS Period,
	|	&Organization                           AS Organization,
	|	&Department                         AS Department,
	|	FATable.FixedAsset             AS FixedAsset,
	|	&FinancialAccountingGroup                AS FinancialAccountingGroup,
	|	FATable.SecurityDepositValue           AS SecurityDepositValue,
	|	TRUE                                 AS RecordInLocalAccounting,
	|	FALSE                                   AS RecordInManAccounting,
	|	VALUE(Enum.BusinessTransactions.ReceiveLeasedAssets) AS BusinessOperation,
	|	
	|	&IDOfUnusedFinRecord  AS FinRecordID,
	|	UNDEFINED                           AS BusinessTransactionSetting
	|	
	|FROM
	|	Document.ReceiveLeasedAssets.FA AS FATable
	|WHERE
	|	FATable.Ref = &Ref
	|	AND &VNAManagementIsUsed_2_4";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export
	
	Return ReceiveLeasedAssetsLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables that are required for reflection in regulated accounting.
// 
// Returns:
// 	String - Query text
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return ReceiveLeasedAssetsLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion

#Region Print

Procedure AddPrintCommands(PrintCommands) Export
	
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
