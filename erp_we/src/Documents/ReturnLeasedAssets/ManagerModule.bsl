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
	
	ReturnLeasedAssetsLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
	
	If TypeOf(Document) = Type("DocumentObject.ReturnLeasedAssets") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then

		FillInInitializationParameters(Query, DocumentRef, AddlParameters);
		
		QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers);
		QueryTextTableLeasedAsset(QueryTexts, Registers);
				
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		
		ReturnLeasedAssetsLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
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
	QueryTextTableInitialFixedAssetsInformation(QueryTexts, Undefined);
	QueryTextTableFACost(QueryTexts);
	
	MovementTables = DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts);
	
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
	
	
	
EndProcedure

// Adds a command to create the document "disposal of leased assets".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.ReturnLeasedAssets) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReturnLeasedAssets.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReturnLeasedAssets);
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
	
	FullDocumentName = "Document.ReturnLeasedAssets";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
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
	
	Query.SetParameter("EndOfDay", New Boundary(EndOfDay(Attributes.Period),BoundaryType.Including));
	Query.SetParameter("Boundary", New Boundary(BegOfMonth(Attributes.Period), BoundaryType.Excluding));
	Query.SetParameter("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4(Attributes.Period));
	
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
	|	Document.ReturnLeasedAssets AS DocumentsList
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
	|	DocumentData.Date AS Period,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeletionMark,
	|	DocumentData.Posted,
	|	DocumentData.Comment,
	|	DocumentData.EmployeeResponsible,
	|	DocumentData.Organization,
	|	DocumentData.Counterparty,
	|	DocumentData.Contract
	|
	|INTO DocumentDataDetails
	|
	|FROM
	|	Document.ReturnLeasedAssets AS DocumentData
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
	|	DocumentTable.FixedAsset AS FixedAsset
	|
	|INTO DocumentDataFATable
	|
	|FROM
	|	Document.ReturnLeasedAssets.FA AS DocumentTable
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
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.ReturnLeasedAssets"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Xuất đi TSCĐ đi thuê ';
															|ru = 'Выбытие арендованных ОС';
															|en = 'Return leased assets'; fa = 'Return leased assets';
															|it = 'Selezionare cespiti affittati';
															|pl = 'Wycofanie wynajmowanych środków trwałych';
															|tr = 'Kiralanan sabit kıymetlerin iadesi'"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.ReturnLeasedAssets);
	ValuesOfHoldingParameters.Insert("BusinessTransactionSetting", Catalogs.BusinessTransactionsSettings.ReturnLeasedAssets);

	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf; 
	
	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure QueryTextTableInitialFixedAssetsInformation(QueryTexts, Registers)

	RegisterName = "InitialFixedAssetsInformation";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	NonCurrentAssetsInternal.QueryTextTableTTInitialInformationFA(QueryTexts);
	
	QueryText = ReturnLeasedAssetsLocalization.QueryTextTableInitialFixedAssetsInformation();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	DocumentData.Ref        AS Recorder,
		|	DocumentData.Period        AS Period,
		|	DocumentData.Organization   AS Organization,
		|	FATable.FixedAsset    AS FixedAsset,
		|
		|	InitialFixedAssetsInformation.AccountingProcedureMA AS AccountingProcedureMA,
		|	InitialFixedAssetsInformation.CommissioningDateAC AS CommissioningDateAC,
		|	InitialFixedAssetsInformation.CommissioningDateMA AS CommissioningDateMA,
		|	InitialFixedAssetsInformation.CommissioningDocumentMA AS CommissioningDocumentMA,
		|	DocumentData.Ref AS DeregistrationDocumentMA
		|
		|FROM
		|	DocumentDataDetails AS DocumentData
		|
		|		INNER JOIN DocumentDataFATable AS FATable
		|		ON FATable.Ref = DocumentData.Ref
		|
		|		LEFT JOIN TTInitialInformationFA AS InitialFixedAssetsInformation
		|		ON InitialFixedAssetsInformation.Ref = FATable.Ref
		|			AND InitialFixedAssetsInformation.FixedAsset = FATable.FixedAsset
		|";
		
	EndIf;
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

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
	|	&BusinessOperation                  AS BusinessOperation,
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
	|	Document.ReturnLeasedAssets AS DocumentData
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
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
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Date,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Posted                AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	TRUE                                  AS RecordInLocalAccounting,
	|	FALSE                                    AS RecordInManAccounting,
	|	FATable.FixedAsset              AS FixedAsset
	|
	|FROM
	|	Document.ReturnLeasedAssets AS DocumentData
	|
	|		LEFT JOIN Document.ReturnLeasedAssets.FA AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure QueryTextTableLeasedAsset(QueryTexts, Registers)
	
	RegisterName = "LeasedAsset";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	QueryText =
	"SELECT
	|	DocumentData.Ref        AS Recorder,
	|	DocumentData.Period        AS Period,
	|	FATable.FixedAsset    AS FixedAsset,
	|	DocumentData.Organization   AS Organization,
	|	DocumentData.Counterparty    AS Counterparty,
	|	DocumentData.Contract       AS Contract,
	|	VALUE(Enum.FixedAssetsStates.TakenOffBooks) AS State
	|
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

Procedure QueryTextTableFACost(QueryTexts)

	RegisterName = "FACost";
	
	NonCurrentAssetsInternal.QueryTextTableTTFAAccountingParameters(QueryTexts);
	
	QueryText =
	"SELECT
	|	VALUE(AccumulationRecordType.Expense)  AS RecordType,
	|	DocumentData.Ref                  AS Recorder,
	|	DocumentData.Period                  AS Period,
	|	DocumentData.Organization             AS Organization,
	|	FATable.FixedAsset              AS FixedAsset,
	|	AccountingParameters.FixedAssetsLocation          AS Department,
	|	AccountingParameters.FinancialAccountingGroup   AS FinancialAccountingGroup,
	|	AccountingParameters.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.Counterparty              AS Counterparty,
	|	FACost.SecurityDepositValue          AS SecurityDepositValue,
	|	&BusinessOperation                  AS BusinessOperation,
	|	
	|	FATable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting AS BusinessTransactionSetting
	|	
	|FROM
	|	DocumentDataDetails AS DocumentData
	|
	|		INNER JOIN DocumentDataFATable AS FATable
	|		ON FATable.Ref = DocumentData.Ref
	|
	|		INNER JOIN TTFAAccountingParameters AS AccountingParameters
	|		ON AccountingParameters.Ref = FATable.Ref
	|			AND AccountingParameters.FixedAsset = FATable.FixedAsset
	|
	|		LEFT JOIN TT_CostOfVNA AS FACost
	|		ON FACost.Ref = FATable.Ref
	|			AND FACost.AccountingObject = FATable.FixedAsset
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
EndProcedure

#EndRegion

#Region ConductingLocalAccounting

Function TextOfReflectionInLocalAccounting() Export
	
	Return ReturnLeasedAssetsLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables that are required for reflection in regulated accounting.
//
// Returns:
// 	String - 
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	Return ReturnLeasedAssetsLocalization.RequestTextTTReflectedInLocalAccounting();
	
EndFunction

#EndRegion

#Region Print

Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

#EndRegion

#Region Other

// Fills in the document for the counterparty
// 
// Parameters:
// 	Object - DocumentObject.ReturnLeasedAssets - 
// Returns:
// 	String, Undefined - 
Function FillInReceivedRentFromCounterparty(Object) Export
	
	If Not ValueIsFilled(Object.Counterparty) Then
		Return Undefined;
	EndIf;
	
	Object.FA.Clear();
	
	QueryText = 
	"SELECT
	|	LeasedAsset.FixedAsset AS FixedAsset,
	|	LeasedAsset.Counterparty AS Counterparty,
	|	LeasedAsset.Contract AS Contract
	|INTO TTLeasedFA
	|FROM
	|	InformationRegister.LeasedAsset.SliceLast(&Date, Recorder <> &Ref) AS LeasedAsset
	|WHERE
	|	LeasedAsset.State = VALUE(Enum.FixedAssetsStates.EnteredInOffBalanceAccounting)
	|	AND LeasedAsset.Counterparty = &Counterparty
	|	AND (LeasedAsset.Contract = &Contract
	|		OR &Contract = VALUE(Catalog.CounterpartyContracts.EmptyRef))
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LeasedAsset.FixedAsset,
	|	FALocation.Organization,
	|	LeasedAsset.Counterparty,
	|	LeasedAsset.Contract
	|FROM
	|	TTLeasedFA AS LeasedAsset
	|		LEFT JOIN InformationRegister.FALocation.SliceLast(
	|			&Date, 
	|			Recorder <> &Ref
	|				AND CorrectionDate = DATETIME(1,1,1)
	|				AND FixedAsset IN
	|					(SELECT
	|						LeasedAsset.FixedAsset
	|					FROM
	|						TTLeasedFA AS LeasedAsset)) AS FALocation
	|		ON FALocation.FixedAsset = LeasedAsset.FixedAsset
	|WHERE
	|	(FALocation.Organization = &Organization
	|		OR &Organization = VALUE(Catalog.Companies.EmptyRef))
	|
	|ORDER BY
	|	LeasedAsset.FixedAsset.Presentation,
	|	LeasedAsset.FixedAsset.AssetID";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Counterparty", Object.Counterparty);
	Query.SetParameter("Contract", Object.Contract);
	Query.SetParameter("Date", ?(ValueIsFilled(Object.Date), Object.Date, CurrentSessionDate()));
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		
		If Not ValueIsFilled(Object.Organization) Then
			Object.Organization = Selection.Organization;
		EndIf;
		If Not ValueIsFilled(Object.Contract) Then
			Object.Contract = Selection.Contract;
		EndIf;
		
		If Object.Organization <> Selection.Organization
			Or Object.Contract <> Selection.Contract Then
			Continue;
		EndIf;
		
		RowData = Object.FA.Add();
		RowData.FixedAsset = Selection.FixedAsset;

	EndDo;
	
	If Object.FA.Count() = 0 Then
		MessageText = NStr("vi = 'Chưa tiếp nhận tài sản cố định từ người cho thuê ""%1""';
							|ru = 'От арендодателя ""%1"" не поступали основные средства';
							|en = 'No fixed assets were received from the lessor ""%1""'; fa = 'No fixed assets were received from the lessor ""%1""';
							|it = 'Non sono state ricevute le immobilizzazioni dal locatore ""%1""';
							|pl = 'Od wynajemcy ""%1"" nie wpływało środków trwałych';
							|tr = '""%1"" kiraya vereninden sabit kıymetler alınmadı'");
		MessageText = StrTemplate(MessageText, String(Object.Contract));
		Return MessageText;
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
