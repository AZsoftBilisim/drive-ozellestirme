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
	DocumentMechanisms.Add("RMManagement");
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
	
	If TypeOf(Document) = Type("DocumentObject.AssetActivityRecord") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		AssetActivityRecords(QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableFixedAssetsDocuments(Query, QueryTexts, Registers);
		AssetRelevancePeriods(QueryTexts, Registers);
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
	
	
	
EndProcedure

// Adds a command of creation of the document "Register of practices".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTableRow - added command
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.AssetActivityRecord) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.AssetActivityRecord.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.AssetActivityRecord);
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

// Checks the table of workings of registration documents and sets the values of workings.
//
// Parameters:
// 		Object - FormDataStructure, DocumentObject.AssetActivityRecord, DocumentObject.SetRunningTimeValues - Document calling for verification
// 		Table - TabularSection of LineOfATabularSection - Document table for verification with columns:
// 		              * Asset - CatalogRef.Assets, CatalogRef.SubAssets - 
// 		              * RunningTimeValue - CatalogRef.RunningTimeValues - 
// 		Cancel - Boolean - Return parameter that indicates whether there were errors during the check.
//
Procedure CheckingTableOfDevelopments(Object, Table, Cancel = False) Export
	
	// Checking duplicate strings
	
	Query = New Query(
		"SELECT
		|	(CAST(Data.LineNumber AS NUMBER)) - 1 AS RowIndex,
		|	Data.Asset AS Asset,
		|	Data.RunningTimeValue AS RunningTimeValue
		|INTO TabularSectionData
		|FROM
		|	&Data AS Data
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	TabularSectionData1.RowIndex AS RowIndex
		|FROM
		|	TabularSectionData AS TabularSectionData1
		|		INNER JOIN TabularSectionData AS TabularSectionData2
		|		ON TabularSectionData1.Asset = TabularSectionData2.Asset
		|			AND TabularSectionData1.RunningTimeValue = TabularSectionData2.RunningTimeValue
		|			AND TabularSectionData1.RowIndex <> TabularSectionData2.RowIndex");
	
	Query.SetParameter("Data", Table.Unload());
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	Selection = Result.Select();
	
	ErrorTemplate = NStr("vi = 'Chỉ tiêu sản lượng ""%RunningTimeValue%"" cho ""%ObjectOrNode%"" trong dòng %LineNumber% được lặp lại trong các hàng khác của phần bảng';
						|ru = 'Показатель наработки ""%RunningTimeValue%"" для ""%ObjectOrNode%"" в строке %LineNumber% повторяется в других строках табличной части';
						|en = 'Asset activity measure ""%RunningTimeValue%"" for ""%ObjectOrNode%"" in row %LineNumber% is duplicated in other rows'; fa = 'Asset activity measure ""%RunningTimeValue%"" for ""%ObjectOrNode%"" in row %LineNumber% is duplicated in other rows';
						|it = 'Indice di sviluppo ""%RunningTimeValue%"" per ""%ObjectOrNode%"" nella riga %LineNumber% è ripetuto nelle altre parti della tabella';
						|pl = 'Wskaźnik średniego czasu pracy ""%RunningTimeValue%"" dla ""%ObjectOrNode%"" w wierszu %LineNumber% powtarza się w innych wierszach części tabelarycznej';
						|tr = '%LineNumber%Satır Numarası% satırındaki ""%ObjectOrNode%"" için ""%RunningTimeValue%"" varlık faaliyet ölçümü tablo bölümünün diğer satırlarında tekrarlanmaktadır'");
	
	While Selection.Next() Do
		
		TableRow = Table[Selection.RowIndex];
		ErrorText = StrReplace(ErrorTemplate, "%RunningTimeValue%", TableRow.RunningTimeValue);
		ErrorText = StrReplace(ErrorText, "%ObjectOrNode%", TableRow.Asset);
		ErrorText = StrReplace(ErrorText, "%LineNumber%", TableRow.LineNumber);
		
		CommonClientServer.MessageToUser(
			ErrorText,
			Object,
			CommonClientServer.PathToTabularSection("RunningTime", TableRow.LineNumber, "RunningTimeValue"),,
			Cancel);
		
	EndDo;
	
EndProcedure

#Region InterfaceImplementation

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
	
	FullDocumentName = "Document.AssetActivityRecord";
	
	ParameterValues = ValuesOfHoldingParameters();
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	
	RequestHasSource = True;
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "";
		RequestHasSource = False;
		
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
	
	If RegisterName = "DocumentsRegistry" Then
		
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
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Date            AS Period,
	|	DocumentData.Number           AS Number,
	|	DocumentData.Organization     AS Organization,
	|	DocumentData.Department   AS Department,
	|	DocumentData.EmployeeResponsible   AS EmployeeResponsible,
	|	DocumentData.Comment     AS Comment,
	|	DocumentData.Posted        AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark
	|FROM
	|	Document.AssetActivityRecord AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
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
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)

	ValuesOfHoldingParameters = New Structure;
	
	ValuesOfHoldingParameters.Insert("UseNodes", GetFunctionalOption("UseSubAssets"));
	ValuesOfHoldingParameters.Insert("MetadataIdentifier", Common.MetadataObjectID("Document.AssetActivityRecord"));
	ValuesOfHoldingParameters.Insert("DocumentName_1", NStr("vi = 'Đăng ký sản lượng';
															|ru = 'Регистрация наработок';
															|en = 'Asset activity registration'; fa = 'Asset activity registration';
															|it = 'Registrazione dei tempi senza guasti';
															|pl = 'Rejestracja średniego czasu pracy';
															|tr = 'Kazançların kaydı'"));
	ValuesOfHoldingParameters.Insert("BusinessOperation", Enums.BusinessTransactions.AssetActivityRecord);
	
	If Attributes <> Undefined Then
		ValuesOfHoldingParameters.Insert("NumberForPrinting", ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number));
	EndIf;

	Return ValuesOfHoldingParameters;
	
EndFunction

Procedure AssetActivityRecords(QueryTexts, Registers)
	
	RegisterName = "AssetActivityRecords";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Text =
	"SELECT
	|	&Period AS Period,
	|	RunningTime.Asset AS Asset,
	|	RunningTime.RunningTimeValue AS RunningTimeValue,
	|	RunningTime.Value AS Value,
	|	RunningTime.AverageDailyValue AS AverageDailyValue,
	|	FALSE AS CorrectiveEntry
	|FROM
	|	Document.AssetActivityRecord.RunningTime AS RunningTime
	|WHERE
	|	RunningTime.Ref = &Ref
	|
	|UNION ALL
	|
	|SELECT
	|	&Period,
	|	ISNULL(Nodes.Ref, Objects.Ref),
	|	RunningTime.RunningTimeValue,
	|	RunningTime.Value,
	|	RunningTime.AverageDailyValue,
	|	FALSE
	|FROM
	|	Document.AssetActivityRecord.EstimatedRunningTimeValues AS RunningTime
	|		LEFT JOIN Catalog.Assets AS Objects
	|		ON RunningTime.Asset = Objects.Ref
	|		LEFT JOIN Catalog.SubAssets AS Nodes
	|		ON RunningTime.Asset = Nodes.Ref
	|			AND (&UseNodes)
	|WHERE
	|	RunningTime.Ref = &Ref
	|";
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

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
	|	&BusinessOperation                  AS BusinessOperation,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
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
	|	&Posted                               AS Posted,
	|	&BusinessOperation                  AS BusinessOperation,
	|	&MetadataIdentifier                AS RefType,
	|	&Organization                            AS Organization,
	|	&Department                          AS Department,
	|	FALSE                                    AS RecordInLocalAccounting,
	|	TRUE                                  AS RecordInManAccounting,
	|	FATable.Asset            AS FixedAsset
	|FROM
	|	Document.AssetActivityRecord AS DocumentData
	|		LEFT JOIN Document.AssetActivityRecord.RunningTime AS FATable
	|		ON DocumentData.Ref = FATable.Ref
	|			AND FATable.Asset REFS Catalog.Assets
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AssetRelevancePeriods(QueryTexts, Registers)
	
	RegisterName = "AssetRelevancePeriods";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return;
	EndIf;
	
	Text = 
	"SELECT DISTINCT
	|	&Period AS Period,
	|	CASE
	|		WHEN RunningTime.Asset REFS Catalog.Assets
	|			THEN RunningTime.Asset
	|		ELSE RunningTime.Asset.Owner
	|	END AS Asset
	|FROM
	|	Document.AssetActivityRecord.RunningTime AS RunningTime
	|WHERE
	|	RunningTime.Ref = &Ref
	|
	|UNION
	|
	|SELECT DISTINCT
	|	&Period,
	|	CASE
	|		WHEN RunningTime.Asset REFS Catalog.Assets
	|			THEN RunningTime.Asset
	|		ELSE RunningTime.Asset.Owner
	|	END
	|FROM
	|	Document.AssetActivityRecord.EstimatedRunningTimeValues AS RunningTime
	|WHERE
	|	RunningTime.Ref = &Ref";
	
	If Not GetFunctionalOption("EnterpriseManagement") Then
		Text = StrReplace(Text, "CASE
		|		WHEN RunningTime.Asset REFS Catalog.Assets
		|			THEN RunningTime.Asset
		|		ELSE RunningTime.Asset.Owner
		|	END", "RunningTime.Asset");
	EndIf;
	
	QueryTexts.Add(Text, RegisterName);
	
EndProcedure

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
