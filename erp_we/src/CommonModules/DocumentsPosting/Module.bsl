#Region Public

#Region MethodsForAccountingMechanism

// Function-constructor of parameters of the accounting mechanism.
//
// Returns:
//  Structure - with properties:
//     * IndependentRegisters - Array of MetadataObjectInformationRegister -
//     * SubordinateRegisters - Array of MetadataObjectInformationRegister -
//                           - Array of MetadataObjectAccumulationRegister -
//                           - Array of MetadataObjectAccountingRegister -
//                           - Array of MetadataObjectCalculationRegister  - a list of registers subordinate to the registrar, which are recorded by the accounting mechanism.
//     * ControlRegistersOfChanges - Array of MetadataObjectInformationRegister -
//                                    - Array of MetadataObjectAccumulationRegister -
//                                    - Array of MetadataObjectAccountingRegister -
//                                    - Array of MetadataObjectCalculationRegister - a list of registers subordinate to the registrar
//                                                                                 for which changes need to be monitored.
//     * TaskControlRegisters - Array of MetadataObjectInformationRegister -
//                                  - Array of MetadataObjectAccumulationRegister -
//                                  - Array of MetadataObjectAccountingRegister -
//                                  - Array of MetadataObjectCalculationRegister - the list of registers subordinate to the registrar,
//                                                                               according to which it is necessary to form tasks.
//     * ControlRegistersBanDate - Array of MetadataObjectInformationRegister -
//                                  - Array of MetadataObjectAccumulationRegister -
//                                  - Array of MetadataObjectAccountingRegister -
//                                  - Array of MetadataObjectCalculationRegister - a list of registers for which it is necessary to check the date
//                                                                              of prohibition of changes using the table of changes.
//     * ThereAreDerivedMotions - Boolean - secondary movements are formed using data from already recorded registers
//                                          made by other mechanisms, among other things.
//     * CompletingTasksInNonOperationalQueue - Boolean - The tasks of the non-operational queue of the accounting mechanism can 
//                                                       be processed directly in the transaction of the document.
//
Function ParametersOfAccountingMechanism() Export
	
	Parameters = New Structure;
	Parameters.Insert("IndependentRegisters",            New Array);
	Parameters.Insert("SubordinateRegisters",            New Array);
	Parameters.Insert("ControlRegistersOfChanges",   New Array);
	Parameters.Insert("TaskControlRegisters",     New Array);
	Parameters.Insert("ThereAreDerivedMotions",        False);
	Parameters.Insert("ControlRegistersBanDate", New Array);
	Parameters.Insert("CompletingTasksInNonOperationalQueue", False);
	
	Return Parameters;
	
EndFunction

// The function returns the document's accounting mechanisms.
//
// Parameters:
//  Document - DocumentManager - Manager of the document for which you want to get accounting mechanisms. 
//  
// Returns:
//  Array of String- contains the document's accounting mechanisms.
//
Function DocumentAccountingMechanisms(Document) Export 
	
	DocumentMechanisms = New Array;
	Document.RegisterAccountingMechanisms(DocumentMechanisms);
	
	Return DocumentMechanisms;
		
EndFunction

// Loads data for writing to a set of document movement records in the specified case.
//
// Parameters:
//  TablesForRegisteredRecords - Structure - a list of tables for movements containing a data table for the specified register,
//      with columns corresponding to the register fields and a name in the format "table" + register Name.
//  RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//  RegisterName - String - the name of the register whose data you want to load.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, RegisterName) Export
	
	MotionTableName = "Table" + RegisterName;
	
	If TablesForRegisteredRecords.Property(MotionTableName)
		And ValueIsFilled(TablesForRegisteredRecords[MotionTableName]) Then
		
		RegisterRecords[RegisterName].Write = True;
		RegisterRecords[RegisterName].Load(TablesForRegisteredRecords[MotionTableName]);
		
	EndIf;
	
EndProcedure

////////////////////////////////////////////
// Called from change control procedures

// Checks whether there are records for the specified control table.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TableName - String - name of the control table.
//
// Returns:
//  Boolean - True if there are changes to the specified control table.
//
Function ThereAreRecordsInTable(Document, TableName) Export
	
	ControlTables = Document.AdditionalProperties.DocumentsPosting.ControlTables;
	Return ControlTables.Property(TableName) And ControlTables[TableName].ThereAreRecordsInTable;
	
EndFunction

/////////////////////////////////////////
// Called from a set of register entries

// Checks whether it is necessary to monitor changes in movements by register.
//
// Parameters:
//  AdditionalRecordsetProperties - Structure - additional properties of the recordset.
//
// Returns:
//  Boolean - True, if there is a need to perform control of movement changes.
//
Function MonitorChanges(AdditionalRecordsetProperties) Export
	
	ThisIsIBConvolution = AdditionalRecordsetProperties.Property("InformationSecurityConvolution") 
		And AdditionalRecordsetProperties.InformationSecurityConvolution;
	
	Return AdditionalRecordsetProperties.Property("ControlTables")
		And AdditionalRecordsetProperties.Property("TempTablesManager")
		And Not ThisIsIBConvolution;
		
EndFunction

// Checks whether it is necessary to calculate the result of changes in movements by register.
//
// Parameters:
//  AdditionalRecordsetProperties - Structure - additional properties of the recordset.
//
// Returns:
//  Boolean - True, if there is a need to calculate the result of changes in movements.
//
Function CalculateChanges_(AdditionalRecordsetProperties) Export
	
	Return Not ValueIsFilled(SessionParameters.UpdateHandlerParameters.ExecutionMode)
		And AdditionalRecordsetProperties.Property("CalculateChanges_")
		And AdditionalRecordsetProperties.CalculateChanges_;
	
EndFunction

// Checks whether the register of the recordable recordset belongs to the change control registers.
//
// Parameters:
//  AdditionalRecordsetProperties - Structure - additional properties of the recordset.
//
// Returns:
//  Boolean - True if the register of the recordable recordset is a control change register.
//
Function ThisIsControlRegisterOfChanges(AdditionalRecordsetProperties) Export
	
	Return AdditionalRecordsetProperties.Property("ThisIsControlRegisterOfChanges")
		And AdditionalRecordsetProperties.ThisIsControlRegisterOfChanges;
	
EndFunction

// Registers the change control table for later use.
//
// Parameters:
//  AdditionalRecordsetProperties - Structure - additional properties of the recordset
//  TableName - String - name of the control table
//  ThereAreRecordsInTable - Boolean - indicates whether there are records in the table
//  Parameters - Arbitrary - passed table parameters.
//
Procedure RegisterControlTable(AdditionalRecordsetProperties, TableName, ThereAreRecordsInTable,
	Parameters = Undefined) Export
	
	AdditionalRecordsetProperties.ControlTables.Insert(TableName,
		New Structure("ThereAreRecordsInTable, Parameters", ThereAreRecordsInTable, Parameters));
	
EndProcedure

// Registers the change control table for later use.
//
// Parameters:
//  AdditionalDocumentProperties - Structure - Additional Document Properties
//  TableName - String - name of the control table
//  ThereAreRecordsInTable - Boolean - indicates whether there are records in the table
//  Parameters - Arbitrary - passed table parameters.
//
Procedure RegisterDocumentControlTable(AdditionalDocumentProperties, TableName, ThereAreRecordsInTable,
	Parameters = Undefined) Export
	
	AdditionalDocumentProperties.DocumentsPosting.ControlTables.Insert(TableName,
		New Structure("ThereAreRecordsInTable, Parameters", ThereAreRecordsInTable, Parameters));
	
EndProcedure

#EndRegion

#Region DocumentEvents

// Initializes in the document handler, before Writing (), the properties that are necessary for the document execution.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  WriteMode - DocumentWriteMode - the current mode of the document
//  PostingMode - DocumentPostingMode - the current mode of the document.
//
Procedure BeforeWritingDocument(Document, WriteMode, PostingMode) Export
	
	If Document.Posted And WriteMode = DocumentWriteMode.Posting Then
		PostingMode = DocumentPostingMode.Regular;
	EndIf;
	
	Document.AdditionalProperties.Insert("DocumentsPosting", New Structure);
	
	DocumentProperties = New FixedStructure("IsNew, WriteMode, PostingMode, Posted, Date",
		Document.IsNew(),
		WriteMode,
		PostingMode,
		Document.Posted,
		Document.Date);
	
	Document.AdditionalProperties.DocumentsPosting.Insert("DocumentProperties", DocumentProperties);
	Document.AdditionalProperties.DocumentsPosting.Insert("ControlTables", New Structure);
	
	Document.AdditionalProperties.DocumentsPosting.Insert(
		"TaskQueueTable",
		DeferredJobs.InitializeTaskTable());
	
	// The key of the structure of the "properties of movement mechanisms" should be the name of the accounting mechanism.
	// Initialization of the value should take place in the mechanism manager module.
	Document.AdditionalProperties.DocumentsPosting.Insert("PropertiesOfRegisteredRecordsOfMechanisms",New Structure);
	
EndProcedure

// Generates Records() of movement in the document handler for independent registers defined in accounting documents.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the recording was rejected.
//
Procedure OnWriteDocument(Document, Cancel) Export
	
	If DocumentProperties(Document).WriteMode = DocumentWriteMode.Write Then
		WriteDocument(Document, Cancel);
	ElsIf DocumentProperties(Document).WriteMode = DocumentWriteMode.UndoPosting Then
		WriteDocument(Document, Cancel);
		PostDocument(Document, Cancel, Undefined);	
	EndIf;
		
EndProcedure

// Generates in the document handler the processing of traffic flow () for registers defined in accounting documents.
//
// Parameters:
//	Document - DocumentObject - a recordable document.
//	Cancel - Boolean - indicates that the recording was rejected.
//	AddlParameters - See DocumentsPosting.AdditionalParametersDocumentDataForPosting.
//
Procedure DocumentProcessing_(Document, Cancel, AddlParameters = Undefined) Export
	
	If DocumentProperties(Document).WriteMode = DocumentWriteMode.Posting Then
		PostDocument(Document, Cancel, AddlParameters);
	EndIf;
	
EndProcedure

// Clears the document handler for processing the deletion of traffic () in subordinate registers.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Cancel - Boolean -  indicates that the recording was rejected.
//
Procedure ProcessingOfDocumentDeletion(Document, Cancel) Export
	
	Return;
	
EndProcedure

#EndRegion

#Region ConductingMechanismsThroughOperations

// Defines the need to create a table for movements that is necessary for conducting a document by register.
//
// Parameters:
//  RegisterName - String - name of the register in the configuration
//  Registers - Structure, String, Undefined - a list of register names that require table formation
//      . if the list is omitted, it always returns True.
//
// Returns:
//  Boolean - True if it is required to form the specified table.
//
Function RequiresTableForRegisteredRecords(RegisterName, Registers) Export
	
	If ValueIsFilled(Registers) Then
		If TypeOf(Registers) = Type("String") Then
			RegistersList = New Structure(Registers);
		Else
			RegistersList = Registers;
		EndIf;
		
		Return RegistersList.Property(RegisterName);
	Else
		Return True
	EndIf;
	
EndFunction

// Checks whether the request text for generating the specified table is present in the list of package requests.
//
// Parameters:
//  TableName - String - name of the table to check for
//  QueryTexts - ValueList of String- a query package where the values are the query texts
//      and the views are the names of the tables being generated.
//  TempTablesManager - TempTablesManager, Undefined -
//
// Returns:
//  Boolean - True if the table query text is in the package query list.
//
Function ThereIsQueryTable(TableName, QueryTexts, TempTablesManager = Undefined) Export
	
	If QueryTexts = Undefined And TempTablesManager = Undefined Then
		Return True;
	EndIf;
	
	If TempTablesManager <> Undefined
	   And TempTablesManager.Tables.Find(TableName) <> Undefined Then
		Return True;
	EndIf;
	
	If QueryTexts <> Undefined Then
		
		For Each QueryText In QueryTexts Do
			If Lower(QueryText.Presentation) = Lower(TableName) Then
				Return True;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return False;
	
EndFunction

// Deletes temporary tables that are already in the temporary table manager from the Query Text.
// 
// Parameters:
//  QueryTexts           - See ThereIsQueryTable.QueryTexts
//  TempTablesManager - See ThereIsQueryTable.TempTablesManager
//
Procedure DeleteCreationOfTemporaryTablesFromQueryText(QueryTexts, TempTablesManager) Export
	
	If QueryTexts = Undefined Or TempTablesManager = Undefined Then
		Return;
	EndIf;
	
	TemporaryTable = TempTablesManager.Tables;
	
	IndexOf = QueryTexts.Count() - 1;
	While IndexOf > -1 Do
		
		QueryText = QueryTexts[IndexOf];
		If TemporaryTable.Find(QueryText.Presentation) <> Undefined Then
			QueryTexts.Delete(QueryText);	
		EndIf;
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
EndProcedure

// Prepares final document reflection requests for the mechanism's accounting registers based on
//  - templates for reflecting operations in registers
//  - requests for getting document data.
// Completes the request for document reflecting the final texts of the queries reflected in the registers.
//
// Parameters:
//  Query - Query - Request for document reflection. Parameters are set in it.
//  QueryTexts - ValueList of String - List of document reflection request texts.
//  ReflectionTemplateTexts - Structure of KeyAndValue- The texts of the request templates are reflected in the accounting registers:
//     * Key - String - register name.
//     * Value - String - The text of the request template.
//  TextsOfDocumentDataRequests - Structure of KeyAndValue- - Request texts for data sampling from documents:
//     * Key - String - Name of the table required for reflection.
//     * Value - String - The text of the data selection request.
//  TemporaryTableTemplateTexts - Structure of KeyAndValue- - Texts of initialization queries for additional temporary tables to reflect:
//     * Key - String - name of the temporary table.
//     * Value - String - The text of the request to initialize an additional temporary table.
//
Procedure AddDocumentReflectionRequest(Query, QueryTexts, ReflectionTemplateTexts, TextsOfDocumentDataRequests, TemporaryTableTemplateTexts = Undefined) Export
	
	If ReflectionTemplateTexts.Count() = 0 Then
		Return;
	EndIf;
	
	HashOfQueryTexts = HashSumOfQueryTexts(ReflectionTemplateTexts, TextsOfDocumentDataRequests, TemporaryTableTemplateTexts);
	SavedQueryTexts = ExecutionRequestTextsFromCache(HashOfQueryTexts);
	If SavedQueryTexts <> Undefined Then
		AddTextsOfEventRequestsToPackage(QueryTexts, SavedQueryTexts);
		Return;
	EndIf;
	
	ResultOfAssemblingQueryTexts = TextsOfRequestsForHolding();
	TemporaryTable = New Array();
	
	// We will check and prepare data sampling requests from documents.
	For Each KeyAndValue In TextsOfDocumentDataRequests Do
		
		QueryText = KeyAndValue.Value;
		
		If StrFind(QueryText, "//") <> 0 Then
			Raise StrTemplate(NStr("vi = 'Nội dung truy vấn ""%1"" không có diễn giải';
									|ru = 'Текст запроса ""%1"" не должен содержать комментариев';
									|en = 'Text of the ""%1"" query cannot contain comments'; fa = 'Text of the ""%1"" query cannot contain comments';
									|it = 'Il testo della richiesta ""%1"" non deve contenere commenti';
									|pl = 'Tekst zapytania ""%1"" nie powinien zawierać uwag';
									|tr = '""%1"" istek metni yorum içermemelidir'"), KeyAndValue.Key);
		EndIf;
		
		If KeywordPosition("GROUP", QueryText) <> Undefined Then
			Raise StrTemplate(NStr("vi = 'Nội dung truy vấn ""%1"" không được chứa GOM NHÓM';
									|ru = 'Текст запроса ""%1"" не должен содержать конструкцию СГРУППИРОВАТЬ';
									|en = 'Text of the ""%1"" query cannot contain GROUP clause'; fa = 'Text of the ""%1"" query cannot contain GROUP clause';
									|it = 'Il testo della richiesta ""%1"" non deve contenere RAGGRUPPARE';
									|pl = 'Tekst zapytania ""%1"" nie powinien zawierać konstrukcji GRUPOWAĆ';
									|tr = '""%1"" sorgu metni GRUPLA yapısı içermemelidir'"), KeyAndValue.Key);
		EndIf;
		
		If KeywordPosition("DISTINCT", QueryText) <> Undefined Then
			Raise StrTemplate(NStr("vi = 'Nội dung truy vấn ""%1"" không được chứa cấu trúc KHÁC';
									|ru = 'Текст запроса ""%1"" не должен содержать конструкцию РАЗЛИЧНЫЕ';
									|en = 'Text of the ""%1"" query cannot contain VARIOUS clause'; fa = 'Text of the ""%1"" query cannot contain VARIOUS clause';
									|it = 'Il testo della richiesta ""%1"" non deve contenere DIFFERENTI';
									|pl = 'Tekst zapytania ""%1"" nie powinien zawierać konstrukcji RÓŻNE';
									|tr = '""%1"" sorgu metni FARKLI yapısı içermemelidir'"), KeyAndValue.Key);
		EndIf;
		
		If KeywordPosition("ORDER", QueryText) <> Undefined Then
			Raise StrTemplate(NStr("vi = 'Nội dung truy vấn ""%1"" không được chứa cấu trúc SẮP XẾP';
									|ru = 'Текст запроса ""%1"" не должен содержать конструкцию УПОРЯДОЧИТЬ';
									|en = 'Text of the ""%1"" query cannot contain SORT clause'; fa = 'Text of the ""%1"" query cannot contain SORT clause';
									|it = 'Il testo della richiesta ""%1"" non deve contenere RIASSESTARE';
									|pl = 'Tekst zapytania ""%1"" nie powinien zawierać konstrukcji UPORZĄDKOWAĆ';
									|tr = '""%1"" sorgu metni DÜZENLE yapısı içermemelidir'"), KeyAndValue.Key);
		EndIf;
		
		If KeywordPosition("UNION", QueryText) <> Undefined Then
			// Let's put the result of the union in a temporary table.
			TempTableName = KeyAndValue.Key;
			
			TemporaryTableCreationText =
			"SELECT
			|	*
			|INTO TempTable
			|FROM
			|	&NestedQuery AS NestedQuery
			|";
			TemporaryTableCreationText = StrReplace(TemporaryTableCreationText, "INTO TempTable", StrTemplate("INTO %1", TempTableName));
			TemporaryTableCreationText = StrReplace(TemporaryTableCreationText, "&NestedQuery", "(" + KeyAndValue.Value + ")");
			
			ResultOfAssemblingQueryTexts.TextsForCreatingTemporaryTables.Add(
				TemporaryTableCreationText,
				TempTableName,
				True);
			TemporaryTable.Add(TempTableName);
			TextsOfDocumentDataRequests[KeyAndValue.Key] = "";
		Else
			TextsOfDocumentDataRequests[KeyAndValue.Key] = ParseRequestText(KeyAndValue.Value);
		EndIf;
	EndDo;
	
	// We will prepare the request texts for additional temporary tables.
	If TemporaryTableTemplateTexts <> Undefined Then
		For Each KeyAndValue In TemporaryTableTemplateTexts Do
			TempTableName = KeyAndValue.Key;
			QueryText = KeyAndValue.Value;
			PrepareRequestTextForDocument(QueryText, TextsOfDocumentDataRequests);
			InsertRoomIntoTemporaryTable(QueryText, TempTableName);
			
			ResultOfAssemblingQueryTexts.TextsForCreatingTemporaryTables.Add(
				QueryText,
				TempTableName,
				True);
		EndDo;
	EndIf;
	
	// We will prepare the texts of requests to reflect operations in registers.
	For Each KeyAndValue In ReflectionTemplateTexts Do
		RegisterName = KeyAndValue.Key;
		ReflectionText = KeyAndValue.Value;
		
		PerformFullMatchReplacement(ReflectionText, "UNION", "$");
		FragmentsOfReflectionText = StrSplit(ReflectionText, "$");
		IndexOf = 0;
		For Each FragmentOfUnion In FragmentsOfReflectionText Do 
			PrepareRequestTextForDocument(FragmentsOfReflectionText[IndexOf], TextsOfDocumentDataRequests, TemporaryTableTemplateTexts);
			IndexOf = IndexOf + 1;
		EndDo;
		ReflectionText = StrConcat(FragmentsOfReflectionText, "UNION");
		
		ResultOfAssemblingQueryTexts.TextsOfEventByRegister.Add(
				ReflectionText,
				RegisterName);
	EndDo;
	
	SaveTextsOfEventRequestsToCache(HashOfQueryTexts, ResultOfAssemblingQueryTexts);
	AddTextsOfEventRequestsToPackage(QueryTexts, ResultOfAssemblingQueryTexts);

EndProcedure

// Builds a request to reflect a specific document for a mechanism operation.
//
// Parameters:
//  ReflectionTemplateText - String - The text of the query and reflection operation.
//  TextsOfDocumentDataRequests - Structure of KeyAndValue - Request texts for document data selection:
//     * Key - String - Name of the table required for reflection.
//     * Value - String, Structure - Text of the request to fetch data from the document.
//          The value can be either an UN-parsed query text (a String type value) or
//          a query text parsed into a structure using parsetext Query ().
//  TemporaryTableQueryTexts_ - Structure of KeyAndValue - Texts of queries of temporary tables for conducting:
//     * Key - String - name of the temporary table.
//     * Value - String - Text of the table creation request.
//
Procedure PrepareRequestTextForDocument(ReflectionTemplateText, TextsOfDocumentDataRequests, TemporaryTableQueryTexts_ = Undefined) Export
	
	For Each QueryTextDocument_ In TextsOfDocumentDataRequests Do
		
		If StrFind(ReflectionTemplateText, QueryTextDocument_.Key) = 0 Then
			Continue;
		EndIf;
		
		DataTableName = QueryTextDocument_.Key;
		QueryTextdata_ = QueryTextDocument_.Value;
		
		If Not ValueIsFilled(QueryTextdata_) Then
			ReflectionTemplateText = ReflectionQueryWithDataSelectionFromTemporaryTable(ReflectionTemplateText, DataTableName);
		Else
			ReflectionTemplateText = RequestReflectionWithSelectionOfDataFromDocument(ReflectionTemplateText, DataTableName, QueryTextdata_);
		EndIf;
		
	EndDo;
	
	If StrFind(ReflectionTemplateText, "#") > 0 And TemporaryTableQueryTexts_ <> Undefined Then
		// Created temporary tables can also be used as data source tables.
		For Each KeyAndValue In TemporaryTableQueryTexts_ Do
			ReflectionTemplateText = ReflectionQueryWithDataSelectionFromTemporaryTable(ReflectionTemplateText, KeyAndValue.Key);
		EndDo;
	EndIf;

EndProcedure

// Initializes the document data to be processed.
//
// Parameters:
//	Query - Query - a query that stores the parameters used in the query list.
//	QueryTexts - ValueList of String - list of query texts and their names.
//	AddlParameters - See DocumentsPosting.AdditionalParametersDocumentDataForPosting
//
// Returns:
//	Structure of KeyAndValue - Tables Of Conduct:
//			* Key - String - table name
//			* Value - ValueTable - Data table of the event
//	List of values From String - a list of values containing the query texts and their names.
//						Returned if the 'Get Request texts' property of the Dopparameters parameter
//						is set to True.
//
Function InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If AddlParameters.GetQueryTexts Then
		DocumentDataForPosting = QueryTexts;
	Else
		DocumentDataForPosting = InitializeTablesForRegisteredRecords(Query,
																			QueryTexts,
																			AddlParameters.OnlyMarkedOnes);
	EndIf;
	
	Return DocumentDataForPosting;
	
EndFunction

// Returns the document data initialization parameters used in the execution mechanisms.
//
// Returns:
//	Structure - a structure with the following keys:
//		* OnlyMarkedOnes - Boolean - Flag indicating that only
//		                              the search tables that have a mark
//		                              in the list of query texts should be retrieved. The default value is False.
//		* GetQueryTexts - Boolean - Flag indicating that only
//		                                   the texts of the document request should be received. The default value is False.
//		* TempTablesManager - TempTablesManager -
//		                          - Undefined - A temporary table manager containing tables
//		                                           used to initialize document data
//		                                           during the accounting process. The default Value Is Undefined.
//		* AdditionalProperties - Undefined - Additional document properties used to
//		                                          initialize document data during the accounting process.
//		                                          The default value is Undefined.
//
Function AdditionalParametersDocumentDataForPosting() Export
	
	Result = New Structure;
	Result.Insert("OnlyMarkedOnes",			False);
	Result.Insert("GetQueryTexts",		False);
	Result.Insert("TempTablesManager",	Undefined);
	Result.Insert("AdditionalProperties",	Undefined);
	
	Return Result;
	
EndFunction

// Selects recorders for which the movements recorded in the register differ from those generated by the request
// of the tracking mechanism.
//
// Parameters:
//	QueriesTexts - ValueList of String - List of request texts for document reflection in the register in accounting and table names. 
//	FullRegisterName - String - The full name of the register, as specified in the query language (for example, accumulation Register.Tourinclude)
//	FullDocumentName - String - The full name of the document, as specified in the query language (for example, Document.Purchasing goods and services).
//	CommonTemporaryTables - Array of String - temporary tables used in all selections of the query package.
//	AdditionalSummationFields - String - if there are numeric Attributes in the register, you can separate them by commas to account for discrepancies in such Attributes as in resources.
//	AdditionalSelectionsOfRegisterEntries - String - selection for register entries, if the holding forms only a part of the entries under the registrar.
//                                                 The selection is passed as part of the request. Alias of the register table "Register table".
//                                                 For example: "Register tables.Field 1 = 0".
//
// Returns:
//	Array of DocumentRef - links to documents for which you need to reformulate movements by register.
//
Function CallLoggers(QueriesTexts, FullRegisterName, FullDocumentName,
			CommonTemporaryTables = Undefined, AdditionalSummationFields = "", AdditionalSelectionsOfRegisterEntries = "TRUE") Export
	
	PartsOfRegisterName	= StrSplit(FullRegisterName, ".", False);
	RegisterType_			= PartsOfRegisterName[0];
	
	If RegisterType_ = "AccumulationRegister" Then
		
		RegisterMetadata = Metadata.FindByFullName(FullRegisterName);
		
	Else
		ExceptionText = NStr("vi = 'Hàm này chưa hỗ trợ làm việc với các thanh ghi loại %RegisterType_%.';
							|ru = 'Функция пока не поддерживает работу с регистрами типа %RegisterType_%.';
							|en = 'Function does not support operations with registers of type %RegisterType_%.'; fa = 'Function does not support operations with registers of type %RegisterType_%.';
							|it = 'La funzione non supporta ancora i registri di tipo %RegisterType_%.';
							|pl = 'Funkcja na razie nie obsługuje pracę z rejestrami typu %RegisterType_%.';
							|tr = 'İşlev henüz %RegisterType_% tipindeki kayıtlarla çalışmayı desteklenmiyor.'");
		ExceptionText = StrReplace(ExceptionText, "%RegisterType_%", RegisterType_);
		
		Raise ExceptionText;
	EndIf;
	
	TextsTT		= New Array;
	QueryTexts	= New Array;
	QueryPackages	= New Map;
	
	If CommonTemporaryTables <> Undefined Then
		
		For Each SelectionText In CommonTemporaryTables Do
			
			TextsTT.Add(SelectionText);
			
		EndDo;
		
	EndIf;
	
	For Each QueryText In QueriesTexts Do
		
		SelectionText = QueryText.Value;
		
		If KeywordPosition("DROP", SelectionText) <> Undefined Then //@query-part
			Continue;
		Else
			
			PackageIndex	= QueryTexts.Count();
			TTNames			= QueryPackages.Get(PackageIndex);
			
			If KeywordPosition("INTO", SelectionText) <> Undefined Then //@query-part
				
				CurSNameIsTT = QueryText.Presentation;
				
				If TTNames = Undefined Then
					QueryPackages.Insert(PackageIndex, New Structure(CurSNameIsTT));
				Else
					SearchStringTemplate = "%1 AS"; //@query-part
					
					For Each TTName In TTNames Do
						SearchString	= StrTemplate(SearchStringTemplate, TTName.Key);
						NewNameTT		= TTName.Key + "_" + PackageIndex;
						
						SelectionText = StrReplace(SelectionText, SearchString, NewNameTT);
					EndDo;
					
					TTNames.Insert(CurSNameIsTT);
					QueryPackages.Insert(PackageIndex, TTNames);
				EndIf;
				
				SearchStringTemplate	= "INTO %1"; //@query-part
				SearchString		= StrTemplate(SearchStringTemplate, CurSNameIsTT);
				NewNameTT			= "INTO " + CurSNameIsTT + "_" + PackageIndex; //@query-part
				
				SelectionText = StrReplace(SelectionText, SearchString, NewNameTT);
				
				TextsTT.Add(SelectionText);
				
			Else
				
				If TTNames <> Undefined Then
					SearchStringTemplate = "%1 AS"; //@query-part
					
					For Each TTName In TTNames Do
						SearchString	= StrTemplate(SearchStringTemplate, TTName.Key);
						NewNameTT		= TTName.Key + "_" + PackageIndex;
						
						SelectionText = StrReplace(SelectionText, SearchString, NewNameTT + " AS "); //@query-part
					EndDo;
				EndIf;
				
				QueryTexts.Add(SelectionText);
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	TheSeparatorQueries	= Common.QueryBatchSeparator();
	RequestSchemaText	= StrConcat(QueryTexts, TheSeparatorQueries);
	
	QuerySchema = New QuerySchema;
	QuerySchema.SetQueryText(RequestSchemaText);
	
	QueryBatch = QuerySchema.QueryBatch;
	
	StandardAttributes = New Array;
	
	If RegisterType_ = "AccumulationRegister" Then
		StandardAttributes.Add("RecordType");
		StandardAttributes.Add("Recorder");
		StandardAttributes.Add("Period");
	EndIf;
	
	CompositionOfRegisterFields = New Array;
	CompositionOfRegisterFields.Add("Dimensions");
	CompositionOfRegisterFields.Add("Resources");
	CompositionOfRegisterFields.Add("Attributes");
	
	ParameterValues = New Structure;
	
	For Each QueryPackage In QueryBatch Do
		
		ColumnIndex = 0;
		
		PackageColumns	= QueryPackage.Columns;
		PackageOperators	= QueryPackage.Operators;
		
		For Each StandardAttribute In StandardAttributes Do
			
			PackageColumn = PackageColumns.Find(StandardAttribute);
			
			If PackageColumn <> Undefined Then
				PackageColumns.MoveTo(PackageColumn, ColumnIndex);
			EndIf;
			
			ColumnIndex = ColumnIndex + 1;
			
		EndDo;
		
		For Each RegisterFields In CompositionOfRegisterFields Do
			
			For Each RegisterField In RegisterMetadata[RegisterFields] Do
				
				FieldName			= RegisterField.Name;
				PackageColumn	= PackageColumns.Find(FieldName);
				
				If PackageColumn = Undefined Then
					
					If RegisterFields = "Resources"
						And RegisterType_ = "AccumulationRegister" Then
						
						Simple = "0";
						
					Else
						Simple = "&EmptyValue" + FieldName;
						
						ParameterValues.Insert("EmptyValue" + FieldName, RegisterField.Type.AdjustValue());
					EndIf;
					
					For Each PackageOperator In PackageOperators Do
						PackageOperator.SelectedFields.Add(Simple);
					EndDo;
					
					PackageColumn = PackageColumns.Get(PackageColumns.Count() - 1);
					PackageColumn.Alias = FieldName;
					
				EndIf;
				
				PackageColumns.MoveTo(PackageColumn, ColumnIndex);
				
				ColumnIndex = ColumnIndex + 1;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
	NewLineText = Chars.LF + Chars.Tab;
	
	RegisterSelectionFields				= New Array;
	SummingQuerySelectionFields	= New Array;
	DimensionsOfSummingQuery	= New Array;
	SummingQueryConditions		= New Array;
	
	RegisterSampleFieldTemplate				= "RegisterTable.%1";
	SummingRequestFieldTemplate			= "NestedQuery.%1 AS %1";
	GroupingTemplateForSummingQuery	= "NestedQuery.%1";
	SummingQueryConditionTemplate		= "OR SUM(NestedQuery.%1) <> 0";
	
	If RegisterType_ = "AccumulationRegister" Then
		RegisterFetchResourceTemplate		= "-RegisterTable.%1";
		SummingRequestResourceTemplate	= "SUM(NestedQuery.%1) AS %1";
	Else
		RegisterFetchResourceTemplate		= RegisterSampleFieldTemplate;
		SummingRequestResourceTemplate	= SummingRequestFieldTemplate;
	EndIf;
	
	For Each StandardAttribute In StandardAttributes Do
		RegisterSelectionField				= StrTemplate(RegisterSampleFieldTemplate,				StandardAttribute);
		SummingQuerySelectionField	= StrTemplate(SummingRequestFieldTemplate,			StandardAttribute);
		GroupingSummingQuery	= StrTemplate(GroupingTemplateForSummingQuery,	StandardAttribute);
		
		RegisterSelectionFields.Add(RegisterSelectionField);
		SummingQuerySelectionFields.Add(SummingQuerySelectionField);
		DimensionsOfSummingQuery.Add(GroupingSummingQuery);
	EndDo;
	
	For Each RegisterFields In CompositionOfRegisterFields Do
		
		For Each RegisterField In RegisterMetadata[RegisterFields] Do
			
			FieldName = RegisterField.Name;
			
			If (RegisterFields = "Resources" Or StrFind(AdditionalSummationFields, FieldName) > 0)
				And RegisterType_ = "AccumulationRegister" Then
				
				RegisterSelectionField				= StrTemplate(RegisterFetchResourceTemplate,		FieldName);
				SummingQuerySelectionField	= StrTemplate(SummingRequestResourceTemplate,	FieldName);
				SummingRequestCondition		= StrTemplate(SummingQueryConditionTemplate,	FieldName);
				
				SummingQueryConditions.Add(SummingRequestCondition);
				
			Else
				
				RegisterSelectionField				= StrTemplate(RegisterSampleFieldTemplate,				FieldName);
				SummingQuerySelectionField	= StrTemplate(SummingRequestFieldTemplate,			FieldName);
				GroupingSummingQuery	= StrTemplate(GroupingTemplateForSummingQuery,	FieldName);
				
				DimensionsOfSummingQuery.Add(GroupingSummingQuery);
				
			EndIf;
			
			RegisterSelectionFields.Add(RegisterSelectionField);
			SummingQuerySelectionFields.Add(SummingQuerySelectionField);
			
		EndDo;
		
	EndDo;
	
	FieldSeparator = "," + NewLineText;
	
	TextOfCaseSelectionFields					= StrConcat(RegisterSelectionFields,				FieldSeparator);
	TextOfFieldsInSummationQuerySelection		= StrConcat(SummingQuerySelectionFields,	FieldSeparator);
	TextOfGroupingFieldsInSummationRequest	= StrConcat(DimensionsOfSummingQuery,	FieldSeparator);
	TextOfSummationRequestConditionFields		= StrConcat(SummingQueryConditions,		NewLineText);
	
	TextOfMotionGenerationRequest = QuerySchema.GetQueryText();
	TextOfMotionGenerationRequest = StrReplace(TextOfMotionGenerationRequest,
													TheSeparatorQueries,
													TMCommonUse.QuerySeparatorInJoin());
	
	QueryTextTT = StrConcat(TextsTT, TheSeparatorQueries);
	
	CaseTextTemplate = 
	"SELECT
	|	&SelectionFields1
	|FROM
	|	&DataSource AS RegisterTable
	|WHERE
	|	VALUETYPE(RegisterTable.Recorder) IN (&TypeDescription)
	|	AND (&AdditionalSelectionsOfRegisterEntries)
	|";
	
	RegisterRequestText = StrReplace(CaseTextTemplate, "&SelectionFields1", TextOfCaseSelectionFields);
	RegisterRequestText = StrReplace(RegisterRequestText, "&DataSource", FullRegisterName);
	RegisterRequestText = StrReplace(RegisterRequestText, "&AdditionalSelectionsOfRegisterEntries", AdditionalSelectionsOfRegisterEntries);
		
	QueryText = QueryTextTT + ?(Not IsBlankString(QueryTextTT), TheSeparatorQueries, "") +
	"SELECT DISTINCT
	|	&IncorrectMovementRecorder AS Recorder
	|INTO WrongRegisteredRecords
	|FROM
	|	(SELECT
	|		&SetOfFieldsSummarizing
	|	FROM
	|		(SELECT &SourceRequestTextFormationOfRegisteredRecords
	|
	|		UNION ALL
	|
	|		SELECT &RegisterRequestText) AS NestedQuery
	|
	|	GROUP BY
	|		&SetOfDimensionFields
	|
	|	HAVING
	|		&ConditionHaving
	|
	|	) AS WrongRegisteredRecords  
	|INDEX BY 
	|	Recorder
	|;
	|
	|/////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsRegistry.CorrectedDocument AS CorrectedDocument
	|INTO CorrectedDocuments
	|FROM
	|	WrongRegisteredRecords AS WrongRegisteredRecords
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry 
	|	ON
	|		WrongRegisteredRecords.Recorder = DocumentsRegistry.ReversedDocument
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	NOT DocumentsRegistry.Ref IS NULL
	|	AND DocumentsRegistry.CorrectedDocument <> UNDEFINED
	|
	|INDEX BY
	|	CorrectedDocument
	|;
	|
	|SELECT
	|	WrongRegisteredRecords.Recorder AS Recorder
	|FROM
	|	WrongRegisteredRecords AS WrongRegisteredRecords
	|
	|UNION
	|
	|SELECT
	|	DocumentsRegistry.Ref AS Recorder
	|FROM
	|	CorrectedDocuments AS CorrectedDocuments
	|	LEFT JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry 
	|	ON
	|		CorrectedDocuments.CorrectedDocument = DocumentsRegistry.CorrectedDocument
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|WHERE
	|	NOT DocumentsRegistry.Ref IS NULL
	|";
	
	QueryText = StrReplace(QueryText, "&IncorrectMovementRecorder", "WrongRegisteredRecords.Recorder");
	QueryText = StrReplace(QueryText, "&SetOfFieldsSummarizing", TextOfFieldsInSummationQuerySelection);
	QueryText = StrReplace(QueryText, "SELECT &SourceRequestTextFormationOfRegisteredRecords", TextOfMotionGenerationRequest);
	QueryText = StrReplace(QueryText, "SELECT &RegisterRequestText", RegisterRequestText);
	QueryText = StrReplace(QueryText, "&ConditionHaving", "FALSE " + Chars.LF + TextOfSummationRequestConditionFields);
	QueryText = StrReplace(QueryText, "&SetOfDimensionFields", TextOfGroupingFieldsInSummationRequest);
	
	ReplacementString = "Ref.Posted";
	QueryText = StrReplace(QueryText, "Ref IN (&Ref)",	ReplacementString);
	QueryText = StrReplace(QueryText, "Ref IN(&Ref)",	ReplacementString);
	
	Query = New Query;
	Query.Text = QueryText;
	
	TextDocumentLinkTemplate = "DocumentRef.%1";
	DocumentName = StrSplit(FullDocumentName, ".")[1];
	TextDocumentLink = StrTemplate(TextDocumentLinkTemplate, DocumentName);
	
	DescriptionOfDataSourceTypes_ = New Array();
	DescriptionOfDataSourceTypes_.Add(Type(TextDocumentLink));
	
	Query.SetParameter("TypeDescription", DescriptionOfDataSourceTypes_);
	
	For Each Parameter In ParameterValues Do
		Query.SetParameter(Parameter.Key, Parameter.Value);
	EndDo;
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	
	Return Recorders;
	
EndFunction

#EndRegion

#Region AuxiliaryFunctions

// Returns a list of properties of the document being processed.
//
// Parameters:
//  Document - DocumentObject - the document to get properties from.
//
// Returns:
//  FixedStructure - with properties:
//     * IsNew - Boolean - True - the document was not recorded in the database before recording, False-the document was already recorded
//     * Posted - Boolean - The truth of the document before recording has already been performed; False - the document has not been conducted
//     * WriteMode - DocumentWriteMode - the current recording mode of the document
//     * PostingMode - DocumentPostingMode - the current mode of the document
//     * Date - Date - document date.
//
Function DocumentProperties(Val Document) Export
	
	Return Document.AdditionalProperties.DocumentsPosting.DocumentProperties;
	
EndFunction

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef - link to the document that you want to get the data
//  Registers - String, Structure - a comma-separated list of register names to get tables for;
//      If the list is omitted, all available data tables in the document are retrieved.
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure of KeyAndValue - Where:
//  	* Key - String - Name of the event table
//  	* Value - ValueTable - Table Of Conduct
//
Function DocumentDataForPosting(Document, Registers = Undefined, AddlParameters = Undefined) Export
	
	ManagerOfDocument = Documents[Document.Metadata().Name];
	DocumentsPostingLocalization.ReassignDocumentDataAcquisitionModule(ManagerOfDocument);
	
	Return ManagerOfDocument.DocumentDataForPosting(Document,
		?(TypeOf(Registers) = Type("String"), New Structure(Registers), Registers),
		?(AddlParameters <> Undefined, AddlParameters, AdditionalParametersDocumentDataForPosting()));
	
EndFunction

// Deletes all records in the database from the document movement record sets for the specified registers.
//
// Parameters:
//  Document - DocumentObject - the document for which you want to delete movements.
//  Registers - String - a list of register names separated by commas, the movement of which is necessary to remove;
//      If the list is omitted, document movements in all registers will be deleted.
//
Procedure ClearDocumentRegisteredRecords(Document, Registers = Undefined) Export
	
	Properties = DocumentProperties(Document);
	If Not Properties.IsNew Then
		If Not ValueIsFilled(Registers) Then
			WritableRegisters = PrepareRecordSetsForMotionRegistration(Document, Properties, Undefined);
			Document.RegisterRecords.Write();
			MarkExecutionOfProcessingOfUpdateOfSubordinateRegisters(WritableRegisters, Document);
		Else
			For Each RegisterName In StrSplit(Registers, ", ", False) Do
				RecordSet = Document.RegisterRecords[TrimAll(RegisterName)];
				RecordSet.Clear();
				RecordSet.AdditionalProperties.Insert("DocumentProperties", Properties);
				RecordSet.Write(True);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

// Adds an additional table for movements in the register of the accounting mechanism.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TableName - String - name of the table for movements
//  Table - ValueTable - table for movements.
//
Procedure AddDocumentDataTable(Document, TableName, Table) Export
	
	If Not Document.AdditionalProperties.DocumentsPosting.Property("AdditionalDocumentDataTables") Then
		Document.AdditionalProperties.DocumentsPosting.Insert("AdditionalDocumentDataTables", New Structure);
	EndIf;
	
	Document.AdditionalProperties.DocumentsPosting.AdditionalDocumentDataTables.Insert(TableName, Table);
	
EndProcedure

// Checks if there is an additional document data table.
//
// Parameters:
//  Document   - See AddDocumentDataTable.Document
//  TableName - See AddDocumentDataTable.TableName
//
// Returns:
//  Boolean - True if there is an additional table.
//
Function ThereIsAdditionalTable(Document, TableName) Export
	
	PropertyHoldingDocuments                 = Undefined;
	PropertyAdditionalDocumentDataTables = Undefined;
	
	Return Document.AdditionalProperties.Property("DocumentsPosting", PropertyHoldingDocuments)
			And PropertyHoldingDocuments.Property(
				"AdditionalDocumentDataTables", PropertyAdditionalDocumentDataTables)
			And PropertyAdditionalDocumentDataTables.Property(TableName);
	
EndFunction

// Returns the temporary table Manager used for storing register change control tables.
//
// Parameters:
//  Document - DocumentObject - a document that contains a temporary table Manager.
//
// Returns:
//  TempTablesManager - temporary table manager.
//
Function ManagerOfTemporaryControlTables(Val Document) Export
	
	If Not Document.AdditionalProperties.DocumentsPosting.Property("ManagerOfTemporaryControlTables") Then
		Document.AdditionalProperties.DocumentsPosting.Insert(
			"ManagerOfTemporaryControlTables", New TempTablesManager);
	EndIf;
	
	Return Document.AdditionalProperties.DocumentsPosting.ManagerOfTemporaryControlTables;
	
EndFunction

// Initialisere additional properties of the register to perform the change control of movements on the register.
//
// Parameters:
//  RegisterRegisteredRecords_ - AccumulationRegisterRecordSet, InformationRegisterRecordSet - collection of register entries
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables
//  CalculateChanges_ - Boolean - flag indicating the result of changes in movements by register.
//  ThisIsControlRegisterOfChanges - Boolean - indicates that the change register will be recorded.
//                                 - Undefined - if the register assignment is not analyzed during recording.
//  ThisIsControlRegisterOfDatesOfBan - Boolean - a sign indicating that the register of the prohibition date mechanism will be recorded.
//                                  - Undefined - if the register assignment is not analyzed during recording.
//  ThisIsTaskControlRegister - Boolean - a flag indicating that the task register will be recorded.
//                               - Undefined - if the register assignment is not analyzed during recording.
//
Procedure SetAdditionalRegisterProperties(RegisterRegisteredRecords_, Document,
	TempTablesManager = Undefined, CalculateChanges_ = False, ThisIsControlRegisterOfChanges = Undefined,
	ThisIsControlRegisterOfDatesOfBan = Undefined, ThisIsTaskControlRegister = Undefined) Export
	
	RegisterRegisteredRecords_.AdditionalProperties.Insert("DocumentProperties", DocumentProperties(Document));
	If TempTablesManager <> Undefined Then
		SetAdditionalPropertiesForControl(
			RegisterRegisteredRecords_,
			Document,
			TempTablesManager,
			CalculateChanges_,
			ThisIsControlRegisterOfChanges,
			ThisIsControlRegisterOfDatesOfBan,
			ThisIsTaskControlRegister);
	EndIf;
	
EndProcedure

// Records the movement of the document, performing control changes on the registers.
//
//	Parameters:
//		Document - DocumentObject - recordable document
//		Cancel - Boolean - flag for refusing to write
//		Changes - Boolean - flag indicating the result of changes in movements by registers
//		Jobs - Boolean - flag indicating that tasks should be formed based on movements in registers.
//
Procedure RecordRegisteredRecordsWithControl(Document, Cancel, Changes, Jobs) Export
	
	Properties = DocumentProperties(Document);
	ManagerOfDocument = Documents[Document.Metadata().Name];
	DocumentsPostingLocalization.ReassignDocumentDataAcquisitionModule(ManagerOfDocument);
	
	If TypeOf(Document) = Type("DocumentObject.ReversingEntry") Then
 		DocumentMechanisms = AccountingMechanismsStorno(Document);
	Else
		DocumentMechanisms    = DocumentAccountingMechanisms(ManagerOfDocument);
	EndIf;
	ConfigurationMechanisms = ConfigurationAccountingMechanisms();
	
	Mechanisms            = New ValueList;
	For Each Mechanism In DocumentMechanisms Do
		MechanismModule = Common.CommonModule(ConfigurationMechanisms[Mechanism]);
		
		MechanismParameters = MechanismModule.ParametersForHoldingDocument(Document, Properties); // See conducting documents.Parameters of the accounting mechanism -  
		MechanismParameters.Insert("MechanismModule", MechanismModule);
		
		Mechanisms.Add(MechanismParameters, Mechanism);
	EndDo;
	Mechanisms.SortByPresentation();
	
	MonthEndTransactionsServer.InitializeGeneratedTasksSessionParameter(Document);
	
	TempTablesManager = ManagerOfTemporaryControlTables(Document);
	
	For Each Mechanism In Mechanisms Do
		If Changes Then
			For Each Register In Mechanism.Value.ControlRegistersOfChanges Do
				RegisterRegisteredRecords_ = Document.RegisterRecords.Find(Register.Name);
				If RegisterRegisteredRecords_ <> Undefined And RegisterRegisteredRecords_.Write Then
					RegisterRegisteredRecords_.AdditionalProperties.Insert("DocumentProperties", Properties);
					SetAdditionalPropertiesForControl(
						RegisterRegisteredRecords_,
						Document,
						TempTablesManager,
						True,
						True,
						False,
						False);
				EndIf;
			EndDo;
			For Each Register In Mechanism.Value.ControlRegistersBanDate Do
				RegisterRegisteredRecords_ = Document.RegisterRecords.Find(Register.Name);
				If RegisterRegisteredRecords_ <> Undefined And RegisterRegisteredRecords_.Write Then
					RegisterRegisteredRecords_.AdditionalProperties.Insert("DocumentProperties", Properties);
					SetAdditionalPropertiesForControl(
						RegisterRegisteredRecords_,
						Document,
						TempTablesManager,
						True,
						False,
						True,
						False);
				EndIf;
			EndDo;
		EndIf;
		If Jobs Then
			For Each Register In Mechanism.Value.TaskControlRegisters Do
				RegisterRegisteredRecords_ = Document.RegisterRecords.Find(Register.Name);
				If RegisterRegisteredRecords_ <> Undefined And RegisterRegisteredRecords_.Write Then
					RegisterRegisteredRecords_.AdditionalProperties.Insert("DocumentProperties", Properties);
					SetAdditionalPropertiesForControl(
						RegisterRegisteredRecords_,
						Document,
						TempTablesManager,
						True,
						False,
						False,
						True);
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	ProcessDocumentBeforeRecording(Mechanisms, Document, TempTablesManager, Cancel);
	Document.RegisterRecords.Write();
	
	ProcessDocumentAfterRecordingRegisteredRecords(Mechanisms, Document, TempTablesManager, Cancel);
	CheckBanDateInChangesTable(Mechanisms, Document, TempTablesManager, Cancel);	
	If Changes Then
		PerformControlOfResultsOf(Mechanisms, Document, TempTablesManager, Cancel);
	EndIf;
	If Jobs And Not Cancel Then
		CreateTasksForDeferredRegisteredRecords(Document, TempTablesManager);
	EndIf;
	
	MonthEndTransactionsServer.CheckGeneratedTasksWhenConductingDocument(Document, Cancel);
	
EndProcedure

// Creates a data structure that replaces the document object, suitable for initializing additional properties of registers
// when monitoring changes in movements by registers and creating tasks for deferred movements.
//
// Parameters:
//  Ref - DocumentRef - link to the document
//  Date - Date - document date.
//
// Returns:
//  Structure - Properties:
//     * Ref - DocumentRef - link to the document
//     * Date - Date - Document date
//     * AdditionalProperties - Structure
//
Function DocumentEmulation(Ref, Date) Export
	
	Document = New Structure("Ref, Date, AdditionalProperties",
		Ref, Date, New Structure);
	
	Document.AdditionalProperties.Insert("DocumentsPosting", New Structure);
	
	DocumentProperties = New FixedStructure("IsNew, WriteMode, PostingMode, ThisIsRecheck, Date",
		False,
		DocumentWriteMode.Posting,
		DocumentPostingMode.Regular,
		True,
		Document.Date);
	
	Document.AdditionalProperties.DocumentsPosting.Insert("DocumentProperties", DocumentProperties);
	Document.AdditionalProperties.DocumentsPosting.Insert("ControlTables", New Structure);
	
	Document.AdditionalProperties.DocumentsPosting.Insert(
		"TaskQueueTable",
		DeferredJobs.InitializeTaskTable());
	
	// The key of the structure of the "properties of movement mechanisms" should be the name of the accounting mechanism.
	// Initialization of the value should take place in the mechanism manager module.
	Document.AdditionalProperties.DocumentsPosting.Insert("PropertiesOfRegisteredRecordsOfMechanisms", New Structure);
	
	Return Document;
	
EndFunction

// Creates jobs on the pending motion on the basis of the performed movements for the registers.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  		 - Structure - See DocumentEmulation()
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables.
//  Run - Boolean - indicates whether queue tasks are running.
//                       The default is TRUE.
//
Procedure CreateTasksForDeferredRegisteredRecords(Document, TempTablesManager, Run = True) Export
	
	ARAPAccountingServer.ReflectTasksForDistributionOfSettlementsWithCustomers(Document, TempTablesManager);
	ARAPAccountingServer.ReflectTasksForDistributionOfSettlementsWithSuppliers(Document, TempTablesManager);
	StockAllocationRecords.ReflectInventoryAllocationTasks(Document, TempTablesManager);
	
	ThereAreCustomersARAP = False;
	ThereAreVendorsARAP = False;
	If ExchangePlans.MasterNode() = Undefined And Constants.UpdateARAPAccountingWhilePostingDocuments.Get()
		And Not Constants.NewOnlineARAPAccounting.Get() Then
		If (TempTablesManager.Tables.Find("SettlementsWithCustomersChanges") <> Undefined
			Or TempTablesManager.Tables.Find("SettlementsWithClientsAccordingToDocumentsTasksForSettlementsWithClients") <> Undefined) Then
			ThereAreCustomersARAP = True;
		EndIf;
		If (TempTablesManager.Tables.Find("VendorsARAPAccountingChanges") <> Undefined
			Or TempTablesManager.Tables.Find("SettlementsWithSuppliersAccordingToDocumentsOfTaskForSettlementsWithSuppliers") <> Undefined) Then
			ThereAreVendorsARAP = True;
		EndIf;
		
		If ThereAreCustomersARAP And ThereAreVendorsARAP Then
			ARAPAllocationServerCall.DistributeCalculationsByBackgroundJob();
		ElsIf ThereAreCustomersARAP Then
			ARAPAllocationServerCall.DistributeCalculationsByBackgroundJob(Undefined, Undefined, "CustomersARAPAccounting");
		ElsIf ThereAreVendorsARAP Then
			ARAPAllocationServerCall.DistributeCalculationsByBackgroundJob(Undefined, Undefined, "VendorsARAPAccounting");
		EndIf;
	EndIf;
	
	BatchAccountingServer.ReflectCostCalculationTasks(Document, TempTablesManager);
	MonthEndTransactionsServer.ReflectTasksByEndOfMonth(Document, TempTablesManager);
	VATAccountingERP.ReflectEntriesInRegisterTasksForGeneratingVATRegisteredRecords(Document, TempTablesManager);
	DocumentsStates.ReflectDocumentStates(Document, TempTablesManager, Run);
	TablesData = OldStructureTableData(Document, TempTablesManager);
	NonCurrentAssets.GenerateTaskRegisterEntries(Document, TablesData);
	OrderStructureDocumentPosting.CreateTasksForCalculatingStructureOfOrderDistributionOfInventoryWhenWritingDocument(Document, TempTablesManager);
	DocumentsPostingLocalization.CreateTasksForDeferredRegisteredRecords(Document, TempTablesManager);
	
EndProcedure

// Converts the document change control tables to the data structure used in the previous version of the document,
// which is suitable for calling the formation of deferred movement tasks for non-current assets.
// (See NonCurrentAssets.GenerateTaskRegisterEntries)
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - A temporary table manager used to store tables for monitoring changes in registers.
//
// Returns:
//  Structure -
//
Function OldStructureTableData(Document, TempTablesManager) Export
	
	TablesData = New Structure;
	TablesData.Insert("TempTablesManager", TempTablesManager);
	
	For Each Table In Document.AdditionalProperties.DocumentsPosting.ControlTables Do
		TablesData.Insert(Table.Key, Table.Value.ThereAreRecordsInTable);
	EndDo;
	
	Return TablesData;
	
EndFunction

// Generates the request body for the reversal of entries on the register of accumulation.
// For numeric resources and numeric details, the register generates entries with a minus sign.
// 
// Parameters:
// 	RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register for reversal.
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the accumulation register for reversal.
// 	
// 	AdditionalTermsAndConditions - String - Text of the conditions for selecting register entries for reversal for the WHERE section.
// Returns:
// 	String - The text of the reversing request.
Function TextOfReversingRequest(RegisterMetadata, MetadataOfDocument, AdditionalTermsAndConditions = "") Export
	
	QueryTemplate = "SELECT
	|	DocumentsStorno.Ref  AS Recorder,
	|	DocumentsStorno.Date AS Period,
	|	&SelectionFields1,
	|	TRUE AS ReversingEntry
	|FROM
	|	&RegisterName AS RegisterData
	|	INNER JOIN
	|		&DocumentName AS DocumentsStorno
	|	ON
	|		RegisterData.Recorder = DocumentsStorno.ReversedDocument
	|		AND DocumentsStorno.Ref IN (&Ref)
	|WHERE
	|	NOT RegisterData.ReversingEntry 
	|	AND &AddConditions";
	
	ArrayOfSelectionFields = New Array;
	
	Exceptions = New Array;
	Exceptions.Add("Recorder");
	Exceptions.Add("Period");
	Exceptions.Add("ReversingEntry");
	Exceptions.Add("LineNumber");
	Exceptions.Add("Active");

	AddSampleFieldsForReversingRequest(RegisterMetadata.StandardAttributes, 
		ArrayOfSelectionFields,
		Exceptions);
	AddSampleFieldsForReversingRequest(RegisterMetadata.Dimensions, 
		ArrayOfSelectionFields,
		Exceptions);
	AddSampleFieldsForReversingRequest(RegisterMetadata.Resources, 
		ArrayOfSelectionFields,
		Exceptions,
		True);
	AddSampleFieldsForReversingRequest(RegisterMetadata.Attributes, 
		ArrayOfSelectionFields,
		Exceptions,
		True);
		
	SelectionFieldText= StrConcat(ArrayOfSelectionFields,"," + Chars.LF);
	
	QueryText = StrReplace(QueryTemplate, "&SelectionFields1", SelectionFieldText);
	QueryText = StrReplace(QueryText, "&RegisterName", RegisterMetadata.FullName());
	QueryText = StrReplace(QueryText, "&DocumentName", MetadataOfDocument.FullName());
	QueryText = StrReplace(QueryText, 
		"&AddConditions",
		?(ValueIsFilled(AdditionalTermsAndConditions), AdditionalTermsAndConditions, "TRUE"));
	Return QueryText;
	
EndFunction

// Collects a template structure from the query texts in the table of changes for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// 	RegisterName - String - 
// 	NameOfChangeTable - String -
// 	SectionName - String -
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextTemplateBanDateControl(Query, RegisterName, NameOfChangeTable, SectionName) Export
	QueryText =
	"SELECT
	|	Table.Period AS Period,
	|	Table.Organization AS Organization,
	|	&RegisterName AS RegisterName,
	|	&Section AS SectionClosingDates
	|FROM
	|	&NameOfChangeTable AS Table
	|";
	
	ParameterNameRegisterName = "RegisterName" + RegisterName;
	NameOfSectionParameter = "Section" + RegisterName;
	
	QueryText = StrReplace(QueryText,"&RegisterName", "&" + ParameterNameRegisterName);
	QueryText = StrReplace(QueryText,"&Section", "&" + NameOfSectionParameter);
	QueryText = StrReplace(QueryText,"&NameOfChangeTable", NameOfChangeTable);
	
	Query.SetParameter(ParameterNameRegisterName, RegisterName);
	Query.SetParameter(NameOfSectionParameter, SectionName);
	
	StructureOfQueryTexts_ = MonthEndTransactionsServer.InitializeStructureOfQueryTexts(QueryText);
	
	Return StructureOfQueryTexts_

EndFunction

// Returns the value of the financial record ID for the accumulation register movement,
// which should not be taken into account when generating transactions based on register data
//
// Returns:
// 	String - id value
//
Function IDOfUnusedFinRecord() Export
	
	Return String(CommonClientServer.BlankUUID());
	
EndFunction

// Called before recording a set of Accumulation register records - saves movements generated on a deferred basis.
// Such movements have the Attributes of the source view.
// When the document is rechecked, these movements are added to the set of movements generated by the document itself.
//
// Parameters:
//	RecordSet - AccumulationRegisterRecordSet - the property is an Object of the recordset module.
//	Replacing - Boolean, ReplacementMode - set recording mode (pre-Recording event parameter).
//	SourceKind - Array of EnumRef.MovementSourcesKinds - Source of movements
//	ExcludeBTSettings - Array of CatalogRef.BusinessTransactionsSettings - Do not save movements with the specified setting.
//
Procedure SaveRegisteredRecordsGeneratedOnDeferredBasis(RecordSet, Replacing, SourceKind, ExcludeBTSettings = Undefined) Export
	
	If TypeOf(Replacing) = Type("Boolean") Then
		RecordReplacementMode = ?(Replacing, ReplacementMode.Replace, ReplacementMode.Append);
	Else
		RecordReplacementMode = Replacing;
	EndIf;
	
	If RecordReplacementMode = ReplacementMode.Merge Then
		ErrorText = StrTemplate(NStr("vi = 'Trong thủ tục, không hỗ trợ chế độ ghi ""%1""';
									|ru = 'В процедуре не поддерживается режим записи ""%1""';
									|en = 'The ""%1"" record mode is not supported in this procedure'; fa = 'The ""%1"" record mode is not supported in this procedure';
									|it = 'The ""%1"" record mode is not supported in this procedure';
									|pl = 'The ""%1"" record mode is not supported in this procedure';
									|tr = 'Bu prosedürde ""%1"" kayıt modu desteklenmiyor'"), RecordReplacementMode);
		Raise ErrorText;
	EndIf;
	
	If Not ValueIsFilled(SourceKind)
		Or RecordReplacementMode = ReplacementMode.Append
		Or RecordReplacementMode = ReplacementMode.Update
		Or RecordReplacementMode = ReplacementMode.Delete Then
		Return;
	EndIf;
	
	If Not RecordSet.AdditionalProperties.Property("DocumentProperties")
		Or RecordSet.AdditionalProperties.DocumentProperties.WriteMode = DocumentWriteMode.UndoPosting Then
		Return;
	EndIf;
	
	If RecordSet.AdditionalProperties.Property("FormationOfManagementBalance") Then
		Return; // movements formed for Man.balance contain all movements
	EndIf;
	
	RegisterMetadata = RecordSet.Metadata();
	
	If RegisterMetadata.Attributes.Find("SourceKind") = Undefined Then
		Return;
	EndIf;
	
	FieldsOfMainRegisterTable = New Array;
	
	PartOfRequest = "AS"; //@query-part
	
	For Each MetadataDetails In RegisterMetadata.Dimensions Do
		FieldsOfMainRegisterTable.Add(?(FieldsOfMainRegisterTable.Count() <> 0, ",", "") + "Table." + MetadataDetails.Name + " " + PartOfRequest + " " + MetadataDetails.Name);
	EndDo;
	For Each MetadataDetails In RegisterMetadata.Resources Do
		FieldsOfMainRegisterTable.Add(", Table." + MetadataDetails.Name + " " + PartOfRequest + " " + MetadataDetails.Name);
	EndDo;
	For Each MetadataDetails In RegisterMetadata.Attributes Do
		FieldsOfMainRegisterTable.Add(", Table." + MetadataDetails.Name + " " + PartOfRequest + " " + MetadataDetails.Name);
	EndDo;
	
	FieldsOfMainRegisterTable = StrConcat(FieldsOfMainRegisterTable, Chars.LF);

	QueryText = 
	"SELECT
	|	Table.Period AS Period,
	|	Table.RecordType AS RecordType,
	|	Table.LineNumber AS LineNumber,
	|	Table.Active AS Active,
	|	&RegisterFields
	|FROM
	|	&RegisterName AS Table
	|
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND Table.SourceKind IN (&SourceKind)
	|	AND NOT Table.BusinessTransactionSetting IN (&ExcludeBTSettings)
	|";
	
	QueryText = StrReplace(QueryText, "&RegisterFields", FieldsOfMainRegisterTable);
	QueryText = StrReplace(QueryText, "&RegisterName", RegisterMetadata.FullName());

	Query = New Query(QueryText);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Recorder", RecordSet.Filter.Recorder.Value);
	Query.SetParameter("SourceKind", SourceKind);
	Query.SetParameter("ExcludeBTSettings", ?(ExcludeBTSettings <> Undefined, ExcludeBTSettings, New Array));
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		NewRow = RecordSet.Add();
		FillPropertyValues(NewRow, Selection);
	EndDo;
	
EndProcedure

// Performs general Operations when filling in initialization parameters
// 
// Parameters:
//  Query - Query -
//  DocumentRef - DocumentRef - Document
//  AddlParameters - Structure - Additional parameters
Procedure FillInInitializationParameters(Query, DocumentRef, AddlParameters) Export
	
	Query.SetParameter("Ref", DocumentRef);

	If Query.TempTablesManager = Undefined Then
		
		TempTablesManager = Undefined;
		
		If AddlParameters <> Undefined
			And AddlParameters.Property("TempTablesManager", TempTablesManager) Then
			
			TempTablesManager = ?(TempTablesManager = Undefined, New TempTablesManager, TempTablesManager);
			
		Else
			TempTablesManager = New TempTablesManager;
		EndIf;
		
		Query.TempTablesManager = TempTablesManager;
	
	EndIf;

EndProcedure

// Returns the task queue table for the document being processed.
//
// Parameters:
//  Document - DocumentObject - the document for which you need to get a job queue table.
//  Queue  - String, Undefined - name of the task queue information register.
//                                    Undefined by default.
//
// Returns:
//  See DeferredJobs.InitializeTaskTable
//
Function TaskQueueTable(Document, Queue = Undefined) Export
	
	Table = Document.AdditionalProperties.DocumentsPosting.TaskQueueTable;
	
	If ValueIsFilled(Queue) Then
		DeferredJobs.CheckAddTaskTable(Queue, Table);
	EndIf;
	
	Return Table;
	
EndFunction

// Sets query parameters based on the selection from the query result
// 
// Parameters:
//  RequestReceiver - Query - to which you need to add parameters from the selection.
//  SamplingSource - QueryResultSelection - source for setting parameters. Where the column name is the parameter
//  												name and the value is the parameter value.
//  ExcludedFields - String - The names of the selection columns, separated by commas, which do not need to be set
//													as parameters.
Procedure SetQueryParametersBySelection(RequestReceiver, SamplingSource, Val ExcludedFields = "") Export

	ExcludedFields = New Structure(ExcludedFields);

	For Each Column In SamplingSource.Owner().Columns Do
		
		ParameterName = Column.Name;
		
		If ExcludedFields.Property(ParameterName) Then
			Continue;
		EndIf;
		
		RequestReceiver.SetParameter(ParameterName, SamplingSource[ParameterName]);
		
	EndDo;

EndProcedure

#EndRegion

// Adds the texts of movement reversal requests to the General request for a correction document.
// 
// Parameters:
// 	Query - Query - Request for holding
// 	QueryTexts - ValueList of String - List of request texts for conducting the document
// 	Registers - Array of String - Names of registers that are used for conducting the search
// 	MetadataOfDocument - MetadataObjectDocument - Metadata object of the document that is being held
//
Procedure AddRequestsStornow(Query, QueryTexts, Registers, MetadataOfDocument) Export
	
	QueryTextCorrections =
	"SELECT TOP 1
	|	Documents.Ref AS Ref
	|FROM
	|	&DocumentName AS Documents
	|WHERE
	|	Documents.Ref IN (&Ref)
	|	AND Documents.Patch
	|";
	
	QueryTextCorrections = StrReplace(QueryTextCorrections, "&DocumentName", "Document." + MetadataOfDocument.Name);
	
	If Query.Parameters.Property("Patch") And Not Query.Parameters.Patch Then
		
		Return;
		
	ElsIf Not Query.Parameters.Property("Patch") And Query.Parameters.Property("Ref") Then
		
		RequestForCorrection = New Query;
		RequestForCorrection.Text = QueryTextCorrections;
		RequestForCorrection.SetParameter("Ref", Query.Parameters.Ref);
		
		If RequestForCorrection.Execute().IsEmpty() Then
			Return;
		EndIf;
	EndIf;
	
	ManagerOfDocument = Documents[MetadataOfDocument.Name];
	AccountingMechanisms = DocumentAccountingMechanisms(ManagerOfDocument);
	ConfigurationMechanisms = ConfigurationAccountingMechanisms();
	
	For Each Mechanism In AccountingMechanisms Do
		
		MechanismModule = Common.CommonModule(ConfigurationMechanisms[Mechanism]);
		TextsOfCancellationRequests = MechanismModule.TextsOfCancellationRequests(MetadataOfDocument);
		For Each KeyAndValue In TextsOfCancellationRequests Do
			MetadataObjectRegister = Metadata.FindByFullName(KeyAndValue.Key);
			If RequiresTableForRegisteredRecords(MetadataObjectRegister.Name, Registers)
					And MetadataOfDocument.RegisterRecords.Contains(MetadataObjectRegister) Then
				QueryTexts.Add(KeyAndValue.Value, MetadataObjectRegister.Name);
			EndIf;
		EndDo;
	EndDo;
	
	DocumentCorrection.AddRequestTexts(Query, QueryTexts, Registers, MetadataOfDocument);
	
EndProcedure

#EndRegion

#Region Private

// Returns an array of names of the accounting mechanisms that are used for conducting transactions
// 
// Returns:
// 	Array of String - 
Function NamesOfConfigurationAccountingMechanisms() Export
	
	ConfigurationMechanisms = ConfigurationAccountingMechanisms();
	Result = New Array;
	
	For Each KeyAndValue In ConfigurationMechanisms Do
		Result.Add(KeyAndValue.Key);
	EndDo;
	
	Return Result;
	
EndFunction

// Describes the accounting mechanisms used in the configuration.
//
// Returns:
// 	Structure of KeyAndValue - Where:
// 			* Key - String - Mechanism Name
// 			* Value - String - Name of the manager module
Function ConfigurationAccountingMechanisms() Export
	
	ConfigurationMechanisms = New Structure;
	
	ConfigurationMechanisms.Insert("AddressWarehouse", "WarehousesServer");
	ConfigurationMechanisms.Insert("Budgeting", "BudgetingServer");
	ConfigurationMechanisms.Insert("ARAPAccounting", "ARAPAccountingPosting");
	ConfigurationMechanisms.Insert("InternalInventoryTransfers", "InternalInventoryTransfers");
	ConfigurationMechanisms.Insert("AvailabilityOfWorkCenters", "AccountingOfWorkCenterAvailability");
	ConfigurationMechanisms.Insert("Purchases", "Purchases");
	ConfigurationMechanisms.Insert("ControlOfBudgetingLimits", "LimitsByBudgetingDataServer");
	ConfigurationMechanisms.Insert("FinancialAccounting", "FinancialAccountingPostingServer");
	ConfigurationMechanisms.Insert("IntangibleAssets", "IntangibleAssetsServer");
	ConfigurationMechanisms.Insert("Nsiproduction", "ProductDataManagement");
	ConfigurationMechanisms.Insert("Supply", "StockAllocationRecords");
	ConfigurationMechanisms.Insert("CirculatingRegistersOfManagementAccounting", "ManagementAccountingPostingServer");
	ConfigurationMechanisms.Insert("OperationalAccountingOfGoodsOfOrganizations", "InventoriesServer");
	ConfigurationMechanisms.Insert("FixedAssets", "FixedAssetsServer");
	ConfigurationMechanisms.Insert("TransferToRecycling", "ProcessingByThirdParties");
	ConfigurationMechanisms.Insert("HandoverForSafekeeping", "HandoverForSafekeeping");
	ConfigurationMechanisms.Insert("InventoryPlanning", "Planning");
	ConfigurationMechanisms.Insert("PlanningCashControl", "CashFlowLimitsServer");
	ConfigurationMechanisms.Insert("GiftCertificates", "GiftCertificatesServer");
	ConfigurationMechanisms.Insert("AcceptanceForProcessing", "TollingScheme");
	ConfigurationMechanisms.Insert("ReceivingForSafekeeping", "ReceivingForSafekeeping");
	ConfigurationMechanisms.Insert("Sales", "Sales");
	ConfigurationMechanisms.Insert("PreparationOfReportsToPurchasingCommittee", "AccumulationRegisters.GoodsAndServicesToRegisterPurchasingReportsToConsignor");
	ConfigurationMechanisms.Insert("Production", "ProductionServer");
	ConfigurationMechanisms.Insert("Rebates", "RebatesServer");
	ConfigurationMechanisms.Insert("GoodsDelivery", "GoodsDelivery");
	ConfigurationMechanisms.Insert("OrderStructure", "OrderStructureDocumentPosting");
	ConfigurationMechanisms.Insert("AdvanceHoldersARAPAccounting_", "AccumulationRegisters.AdvanceHolderCash");
	ConfigurationMechanisms.Insert("DocumentsRegistry", "InformationRegisters.DocumentsRegistry");
	ConfigurationMechanisms.Insert("DocumentCorrection", "DocumentCorrection");
	ConfigurationMechanisms.Insert("LossAllowance", "AccrualAndWriteOffOfBadDebtAlowancesServer");
	ConfigurationMechanisms.Insert("FutureExpenseCommitments", "FutureExpenseCommitments");
	ConfigurationMechanisms.Insert("RequestStatesForQualityControl", "InformationRegisters.RequestStatesForQualityControl");
	ConfigurationMechanisms.Insert("CostAndBatchAccounting", "BatchAccountingServer");
	ConfigurationMechanisms.Insert("SerialAccounting", "AccumulationRegisters.GoodsBatchMovement");
	ConfigurationMechanisms.Insert("DocumentAmountsInAccountingCurrency", "InformationRegisters.DocumentAmountsInAccountingCurrency");
	ConfigurationMechanisms.Insert("ProductRangeManagement", "ProductRangeServer");
	ConfigurationMechanisms.Insert("RMManagement", "RMManagement");
	ConfigurationMechanisms.Insert("CashManagement", "CashServer");
	ConfigurationMechanisms.Insert("AccountingOfIncomeExpenses", "IncomeAndExpensesServer");
	ConfigurationMechanisms.Insert("ImportAccounting", "ImportAccounting");
	ConfigurationMechanisms.Insert("VATAccounting", "VATAccountingERP");
	ConfigurationMechanisms.Insert("WIPAccounting", "WIPAccounting");
	ConfigurationMechanisms.Insert("AccountingForOtherAssetsLiabilities", "OtherAssetsLiabilitiesServer");
	ConfigurationMechanisms.Insert("AccountingOfWorks", "AccumulationRegisters.MaterialsAndWorksInProduction");
	ConfigurationMechanisms.Insert("FinancialInstruments", "AccumulationRegisters.FinancialInstrumentsARAP");
	ConfigurationMechanisms.Insert("FinancialResult", "AccumulationRegisters.FinancialResults");
	ConfigurationMechanisms.Insert("PricesAndDiscounts", "PriceManagementSystem");
	ConfigurationMechanisms.Insert("ImpairmentFA", "ImpairmentFAServer");
	ConfigurationMechanisms.Insert("InventoryInOperation", "InventoryInOperationServer");
	
	//++ WE    
	ConfigurationMechanisms.Insert("PersonnelAccountingHR", "HRRecordkeepingPostingPayrollAndHumanResourcesServer"); 
	ConfigurationMechanisms.Insert("PayrollAccountingHR", "PayrollAccountingPostingPayrollAndHumanResourcesServer");
	// --WE
	DocumentsPostingLocalization.SupplementConfigurationAccountingMechanisms(ConfigurationMechanisms);
	
	Return ConfigurationMechanisms;
	
EndFunction

Procedure WriteDocument(Document, Cancel)
	
	SetPrivilegedMode(True);
	
	Properties = DocumentProperties(Document);
	ManagerOfDocument = Documents[Document.Metadata().Name];
	DocumentsPostingLocalization.ReassignDocumentDataAcquisitionModule(ManagerOfDocument);
	
	If TypeOf(Document) = Type("DocumentObject.ReversingEntry") Then
		DocumentMechanisms = AccountingMechanismsStorno(Document);
	Else
		DocumentMechanisms    = DocumentAccountingMechanisms(ManagerOfDocument);
	EndIf;
	ConfigurationMechanisms = ConfigurationAccountingMechanisms();
	
	MovableRegisters    = New Structure;
	Mechanisms           = New ValueList;
	For Each Mechanism In DocumentMechanisms Do
		MechanismModule = Common.CommonModule(ConfigurationMechanisms[Mechanism]);
		
		MechanismParameters = MechanismModule.ParametersForHoldingDocument(Document, Properties); // See conducting documents.Parameters of the accounting mechanism - 
		MechanismParameters.Insert("MechanismModule", MechanismModule);
		
		For Each Register In MechanismParameters.IndependentRegisters Do
			MovableRegisters.Insert(Register.Name);
		EndDo;
		
		Mechanisms.Add(MechanismParameters, Mechanism);
	EndDo;
	Mechanisms.SortByPresentation();
	
	TablesForRegisteredRecords = TablesForRegisteredRecords(Document, ManagerOfDocument, MovableRegisters, Undefined);
	
	TempTablesManager = Undefined;
	
	RecordRegisteredRecordsOfIndependentRegisters(Mechanisms, Document, TablesForRegisteredRecords, TempTablesManager, Cancel);
	
EndProcedure

Procedure PostDocument(Document, Cancel, AddlParameters)
	
	SetPrivilegedMode(True); 

	Properties = DocumentProperties(Document);
	ManagerOfDocument = Documents[Document.Metadata().Name];
	DocumentsPostingLocalization.ReassignDocumentDataAcquisitionModule(ManagerOfDocument);
	
	If TypeOf(Document) = Type("DocumentObject.ReversingEntry") Then
		DocumentMechanisms = AccountingMechanismsStorno(Document);
	Else
		DocumentMechanisms    = DocumentAccountingMechanisms(ManagerOfDocument);
	EndIf;
	ConfigurationMechanisms = ConfigurationAccountingMechanisms();
	
	MonthEndTransactionsServer.InitializeGeneratedTasksSessionParameter(Document);
	
	RegistersToRegister = New Array;
	MovableRegisters     = New Structure;
	Mechanisms            = New ValueList;
	For Each Mechanism In DocumentMechanisms Do
		MechanismModule = Common.CommonModule(ConfigurationMechanisms[Mechanism]);
		
		MechanismParameters = MechanismModule.ParametersForHoldingDocument(Document, Properties); // See DocumentsPosting.ParametersOfAccountingMechanism
		MechanismParameters.Insert("MechanismModule", MechanismModule);
		
		If Properties.WriteMode = DocumentWriteMode.Posting Then
			CommonClientServer.SupplementArray(RegistersToRegister, MechanismParameters.SubordinateRegisters);
			
			For Each Register In MechanismParameters.SubordinateRegisters Do
				MovableRegisters.Insert(Register.Name);
			EndDo;
			
			For Each Register In MechanismParameters.IndependentRegisters Do
				MovableRegisters.Insert(Register.Name);
			EndDo;
			
		EndIf;
		
		Mechanisms.Add(MechanismParameters, Mechanism);
	EndDo;
	Mechanisms.SortByPresentation();
	
	WritableRegisters = PrepareRecordSetsForMotionRegistration(Document, Properties, RegistersToRegister);
	
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		TablesForRegisteredRecords = TablesForRegisteredRecords(Document, ManagerOfDocument, MovableRegisters, AddlParameters);
		ReflectRegisteredRecordsOfSubordinateRegisters(Mechanisms, Document, TablesForRegisteredRecords, Cancel);
	EndIf;
	
	TempTablesManager = ManagerOfTemporaryControlTables(Document);
	SetAdditionalPropertiesOfControlRegisters(Mechanisms, Document, TempTablesManager);
	
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		RecordRegisteredRecordsOfIndependentRegisters(Mechanisms, Document, TablesForRegisteredRecords, TempTablesManager, Cancel);
	EndIf;
	
	ProcessDocumentBeforeRecording(Mechanisms, Document, TempTablesManager, Cancel);

	Document.RegisterRecords.Write();
	
	ProcessDocumentAfterRecordingRegisteredRecords(Mechanisms, Document, TempTablesManager, Cancel);
	CheckBanDateInChangesTable(Mechanisms, Document, TempTablesManager, Cancel);
	PerformControlOfResultsOf(Mechanisms, Document, TempTablesManager, Cancel);
	
	If Not Cancel Then
		CreateTasksForDeferredRegisteredRecords(Document, TempTablesManager, False);
		MarkExecutionOfProcessingOfUpdateOfSubordinateRegisters(WritableRegisters, Document);
	EndIf;
	
	MonthEndTransactionsServer.CheckGeneratedTasksWhenConductingDocument(Document, Cancel);
	
	StartExecutionOfOperationalQueueTasks(Document, Cancel);
	CheckToCompleteTasksInNonOperationalQueue(Mechanisms, Document, Cancel);
	
	TempTablesManager.Close();
	
EndProcedure

// Generates tables for movements based on the passed parameters and the list of requests.
//
// Parameters:
//	Query - Query - a query that stores the parameters used in the query list.
//	QueryTexts - ValueList of String - list of query texts and their names.
//	OnlyMarkedOnes - Boolean - "True" indicates that only tables that are
//	                            marked in the list of query texts are returned.
//
// Returns:
//	Structure - the structure in which the resulting tables are placed.
//
Function InitializeTablesForRegisteredRecords(Query, QueryTexts, OnlyMarkedOnes)
	
	For Each QueryText In QueryTexts Do
		
		TableName = QueryText.Presentation;
		
		If Not IsBlankString(TableName) Then
			
			If OnlyMarkedOnes And Not QueryText.Check Then
				TableName = "";
			ElsIf Not StrStartsWith(TableName, "Table") Then
				// Tables for conducting should start with "Table".
				TableName = "Table" + TableName;
			EndIf;
			
			QueryText.Presentation = TableName;
			
		EndIf;
		
	EndDo;
	
	Return UploadQueryPostResults(Query, QueryTexts);
	
EndFunction

Function UploadQueryPostResults(Query, QueryTexts) Export
	
	Tables = New Structure;
	
	ResultTraversal = QueryResultIteration.Linear;
	
	Results = TMCommonUse.ExecuteBatchOfRequests(Query, QueryTexts);
	
	If Results <> Undefined Then
		
		// Putting query results in tables.
		ResultIndex = -1;
		For Each QueryText In QueryTexts Do
			TableName = QueryText.Presentation;
			Subqueries = StrSplit(TrimAll(QueryText.Value), ";", False);
			// Unloading the result of the last request of the package.
			ResultIndex = ResultIndex + Subqueries.Count(); 
			If Not IsBlankString(TableName) Then // table name
				Result = Results[ResultIndex];
				If Result <> Undefined Then
					QueryTable = Result.Unload(ResultTraversal);
					If Tables.Property(QueryText.Presentation) Then
						MergeQueryResultTables(QueryTable, Tables[TableName]);
					Else
						Tables.Insert(TableName, QueryTable);
					EndIf;
				EndIf;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return Tables;
	
EndFunction

// Adds rows from the source table to the receiver table with a preliminary check:
// - column types
// - column composition
// If necessary, it makes adjustments to the receiver table.
// Parameters:
//  SourceTable1 - ValueTable -
//  DestinationTable - ValueTable -
//
Procedure MergeQueryResultTables(SourceTable1, DestinationTable)
	
	ColumnsForCombiningTypes = New Structure();
	ColumnsToAdd_ = New Structure();
	For Each SourceColumn1 In SourceTable1.Columns Do
		DestinationColumn = DestinationTable.Columns.Find(SourceColumn1.Name);
		If DestinationColumn <> Undefined Then
			
			SourceColumnTypes = SourceColumn1.ValueType.Types();
			MissingTypes_ = New Array;
			
			// Let's check for the types included in the description of the source in the receiver.
			// If there are none, we will combine the type descriptions and recreate the columns of the table.
			For Each SourceColumnType In SourceColumnTypes Do
				If Not DestinationColumn.ValueType.ContainsType(SourceColumnType) Then
					MissingTypes_.Add(SourceColumnType);
				EndIf;
			EndDo;
			
			// Let's compare the qualifiers of primitive source and receiver types.
			// If the qualifiers in the description of the source types are "more general", then let's take them.
			ChangeNumberQualifiers = False;
			NumberQualifiers = DestinationColumn.ValueType.NumberQualifiers;
			If SourceColumn1.ValueType.ContainsType(Type("Number")) And DestinationColumn.ValueType.ContainsType(Type("Number")) Then
				SourceNumberQualifiers = SourceColumn1.ValueType.NumberQualifiers;  
				If SourceNumberQualifiers.Digits > NumberQualifiers.Digits Then
					Digits = SourceNumberQualifiers.Digits;
					ChangeNumberQualifiers = True;
				Else
					Digits = NumberQualifiers.Digits;
				EndIf;
				If SourceNumberQualifiers.FractionDigits > NumberQualifiers.FractionDigits Then
					FractionDigits = SourceNumberQualifiers.FractionDigits;
					ChangeNumberQualifiers = True;
				Else
					FractionDigits = NumberQualifiers.FractionDigits;
				EndIf;
				If SourceNumberQualifiers.AllowedSign <> NumberQualifiers.AllowedSign Then
					Character = AllowedSign.Any;
					ChangeNumberQualifiers = True;
				Else
					Character = NumberQualifiers.AllowedSign;
				EndIf;
				If ChangeNumberQualifiers Then
					NumberQualifiers = New NumberQualifiers(Digits, FractionDigits, Character);
				EndIf;
			EndIf;
			
			ChangeStringQualifiers = False;
			StringQualifiers = DestinationColumn.ValueType.StringQualifiers;
			If SourceColumn1.ValueType.ContainsType(Type("String")) 
				 And DestinationColumn.ValueType.ContainsType(Type("String")) Then
				SourceStringQualifiers = SourceColumn1.ValueType.StringQualifiers;
				If StringQualifiers.Length <> 0 And SourceStringQualifiers.Length > StringQualifiers.Length Then
					ChangeStringQualifiers = True;
					StringQualifiers = New StringQualifiers(SourceStringQualifiers.Length);
				EndIf; 
			EndIf;
			
			ChangeDateQualifiers = False;
			DateQualifiers = DestinationColumn.ValueType.DateQualifiers;
			If SourceColumn1.ValueType.ContainsType(Type("Date")) 
				 And DestinationColumn.ValueType.ContainsType(Type("Date")) Then
				SourceDateQualifiers = SourceColumn1.ValueType.DateQualifiers;
				If SourceDateQualifiers.DateFractions <> DateQualifiers.DateFractions Then
					ChangeDateQualifiers = True;
					DateQualifiers = New DateQualifiers(DateFractions.DateTime);
				EndIf; 
			EndIf;
			
			ChangeBinaryDataQualifiers = False;
			BinaryDataQualifiers = DestinationColumn.ValueType.BinaryDataQualifiers;
			If SourceColumn1.ValueType.ContainsType(Type("BinaryData")) 
				 And DestinationColumn.ValueType.ContainsType(Type("BinaryData")) Then
				SourceBinaryDataQualifiers = SourceColumn1.ValueType.BinaryDataQualifiers;
				If BinaryDataQualifiers.Length <> 0 And SourceBinaryDataQualifiers.Length > BinaryDataQualifiers.Length Then
					ChangeBinaryDataQualifiers = True;
					BinaryDataQualifiers = New BinaryDataQualifiers(SourceBinaryDataQualifiers.Length);
				EndIf; 
			EndIf;
			
			If MissingTypes_.Count() > 0
				Or ChangeNumberQualifiers 
				Or ChangeStringQualifiers 
				Or ChangeDateQualifiers
				Or ChangeBinaryDataQualifiers Then
				
				ArrayOfTypesUnion = DestinationColumn.ValueType.Types();
				CommonClientServer.SupplementArray(ArrayOfTypesUnion, MissingTypes_);
				
				DescriptionOfTypesUnion = New TypeDescription(ArrayOfTypesUnion, 
															   NumberQualifiers, 
															   StringQualifiers, 
															   DateQualifiers, 
															   BinaryDataQualifiers);
				ColumnsForCombiningTypes.Insert(DestinationColumn.Name, DescriptionOfTypesUnion);
			EndIf;
		Else
			ColumnsToAdd_.Insert(SourceColumn1.Name, SourceColumn1.ValueType)
		EndIf;
	EndDo;
	
	For Each Column In ColumnsForCombiningTypes Do
		ValuesInColumn = DestinationTable.UnloadColumn(Column.Key);
		DestinationTable.Columns.Delete(Column.Key);
		DestinationTable.Columns.Add(Column.Key, Column.Value);
		DestinationTable.LoadColumn(ValuesInColumn, Column.Key);
	EndDo;
	
	For Each Column In ColumnsToAdd_ Do
		DestinationTable.Columns.Add(Column.Key, Column.Value);
	EndDo;
	
	CommonClientServer.SupplementTable(SourceTable1, DestinationTable);
	
EndProcedure

Procedure AddSampleFieldsForReversingRequest(Attributes, ArrayOfSelectionFields, Exceptions, InvertNumeric = False) Export
	
	Template = "RegisterData.%1 AS %2";
	PatternNegativeNumber = "- " + Template;
	
	For Each Attribute In Attributes Do
		If Exceptions.Find(Attribute.Name) = Undefined Then
			If InvertNumeric And Attribute.Type.ContainsType(Type("Number")) Then
				ArrayOfSelectionFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
					PatternNegativeNumber,
					Attribute.Name,
					Attribute.Name));
			Else
				ArrayOfSelectionFields.Add(StringFunctionsClientServer.SubstituteParametersToString(
					Template,
					Attribute.Name,
					Attribute.Name));
			EndIf;
		EndIf;
	EndDo;
EndProcedure

Procedure StartExecutionOfOperationalQueueTasks(Document, Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	TaskQueueTable = TaskQueueTable(Document);
	
	RowsCount = TaskQueueTable.Count();
	If RowsCount = 0 Then
		Return;
	EndIf;
	
	IndexOf = RowsCount - 1;
	While IndexOf > -1 Do
		
		If TaskQueueTable[IndexOf].Jobs.Count() = 0 Then
			TaskQueueTable.Delete(IndexOf);
		EndIf;
		
		IndexOf = IndexOf - 1;
		
	EndDo;
	
	If TaskQueueTable.Count() = 0 Then
		Return;
	EndIf;
	
	DeferredJobs.Run(TaskQueueTable);
	
EndProcedure

// The conditions are checked in the accounting mechanism and the execution 
// of non-operational queue tasks in the document transaction is started.
// 
// Parameters:
//  Mechanisms - ValueList of See DocumentsPosting.ParametersOfAccountingMechanism
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - flag for refusing to write
Procedure CheckToCompleteTasksInNonOperationalQueue(Mechanisms, Document, Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	For Each Mechanism In Mechanisms Do
		If Mechanism.Value.CompletingTasksInNonOperationalQueue Then
			Mechanism.Value.MechanismModule.CheckToCompleteTasksInNonOperationalQueue(Document);
		EndIf;
	EndDo;
	
EndProcedure

Function AccountingMechanismsStorno(Document)
	
	// We will get a list of mechanisms from the document being reversed
	ManagerOfDocumentBeingCanceled = Common.ObjectManagerByRef(Document.ReversedDocument);
	DocumentMechanisms    = DocumentAccountingMechanisms(ManagerOfDocumentBeingCanceled);
	If DocumentMechanisms.Find("DocumentCorrection") = Undefined Then
		DocumentMechanisms.Add("DocumentCorrection");
	EndIf;
	
	Return DocumentMechanisms;
	
EndFunction

#Region StagesOfImplementation_

// LongDesc
// 
// Parameters:
// 	Document - DocumentObject - LongDesc
// 	Properties - See DocumentsPosting.DocumentProperties
// 	Registers - Array of MetadataObjectAccumulationRegister -
// 	         - Array of MetadataObjectInformationRegister -
// 	         - Array of MetadataObjectAccountingRegister -
//
// Returns:
//  Array of String - Names of registers to be written
Function PrepareRecordSetsForMotionRegistration(Document, Properties, Registers = Undefined)
	
	RegisterNamesToWrite = New Array;
	
	If ValueIsFilled(Registers) Then
		RegistersForProcessing = New Array;
		RecordSetsForProcessing = New Array;
		
		RegisterRecords = Document.Metadata().RegisterRecords;
		For Each Register In Registers Do
			If RegisterRecords.Contains(Register) Then
				RegistersForProcessing.Add(Register);
				RecordSetsForProcessing.Add(Document.RegisterRecords[Register.Name]);
			EndIf;
		EndDo;
	Else
		RegistersForProcessing = Document.Metadata().RegisterRecords;
		RecordSetsForProcessing = Document.RegisterRecords;
	EndIf;
	
	For Each RecordSet In RecordSetsForProcessing Do
		
		// Let's clear the record sets from "old records" (the situation is possible only in a thick client)
		If ValueIsFilled(RecordSet) And Not RecordSet.Write Then
			RecordSet.Clear();
		EndIf;
		
		// Let's go through the properties of the document
		RecordSet.AdditionalProperties.Insert("DocumentProperties", Properties);
		
		// Let's go through the properties of Registered Recorded mechanisms.
		If Document.AdditionalProperties.Property("DocumentsPosting")
			And Document.AdditionalProperties.DocumentsPosting.Property("PropertiesOfRegisteredRecordsOfMechanisms") Then
			RecordSet.AdditionalProperties.Insert("PropertiesOfRegisteredRecordsOfMechanisms",
				Document.AdditionalProperties.DocumentsPosting.PropertiesOfRegisteredRecordsOfMechanisms);
		EndIf;
	EndDo;
	
	// Let's raise the record flag for the sets for which the document has movements
	If Not Properties.IsNew Then
		
		ArrayOfRegisterNames = GetUsedRegisters(Document.Ref, RegistersForProcessing);
		
		For Each RegisterName In ArrayOfRegisterNames Do
			Document.RegisterRecords[RegisterName].Write = True;
			RegisterNamesToWrite.Add(RegisterName);
		EndDo;
		
	EndIf;
	
	Return RegisterNamesToWrite;
	
EndFunction

Function GetUsedRegisters(Recorder, RegistersList)
	
	Query = New Query;
	Query.SetParameter("Recorder", Recorder);
	
	Result = New Array;
	MaximumTablesInQuery = 256;
	TablesCounter = 0;
	RegistersLeft = RegistersList.Count();
	
	QueryTexts = New Array;
	QueryTemplate =
	"SELECT TOP 1
	|	""&RegisterName"" AS RegisterName
	|FROM
	|	&Table
	|WHERE
	|	Recorder = &Recorder";
	
	For Each Register In RegistersList Do
		
		QueryText = StrReplace(QueryTemplate, "&RegisterName", Register.Name);
		QueryText = StrReplace(QueryText, "&Table", Register.FullName());
		
		QueryTexts.Add(QueryText);
		
		TablesCounter = TablesCounter + 1;
		RegistersLeft = RegistersLeft - 1;
		
		If TablesCounter = MaximumTablesInQuery Or RegistersLeft = 0 And TablesCounter <> 0 Then
			
			Query.Text  = StrConcat(QueryTexts, TMCommonUse.QuerySeparatorInJoin());
			TablesCounter = 0;
			QueryTexts.Clear();
			
			CommonClientServer.SupplementArray(Result, Query.Execute().Unload().UnloadColumn("RegisterName"));
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function TablesForRegisteredRecords(Document, ManagerOfDocument, MovableRegisters, AddlParameters)
	
	If ValueIsFilled(MovableRegisters) Then
		
		If AddlParameters = Undefined Then
			AddlParameters = AdditionalParametersDocumentDataForPosting();
		EndIf;
		
		TablesForRegisteredRecords = ManagerOfDocument.DocumentDataForPosting(Document, MovableRegisters, AddlParameters);

		If Document.AdditionalProperties.DocumentsPosting.Property("AdditionalDocumentDataTables") Then
			For Each Table In Document.AdditionalProperties.DocumentsPosting.AdditionalDocumentDataTables Do
				If TablesForRegisteredRecords.Property(Table.Key) Then
					Raise StrTemplate(NStr("vi = 'Giao điểm của tên của các bảng dữ liệu tài liệu: ""%1"".';
											|ru = 'Пересечение имен таблиц данных документа: ""%1"".';
											|en = 'Intersection of the document data table names: ""%1"".'; fa = 'Intersection of the document data table names: ""%1"".';
											|it = 'Incrociare i nomi delle tabelle dei dati del documento: ""%1"".';
											|pl = 'Krzyżowanie się nazw tabel danych dokumentu: ""%1"".';
											|tr = 'Belge veri tablosu adlarının kesişimi: ""%1"".'"), Table.Key);
				Else
					TablesForRegisteredRecords.Insert(Table.Key, Table.Value);
				EndIf;
			EndDo;
		EndIf;
		
		Return TablesForRegisteredRecords;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Procedure ReflectRegisteredRecordsOfSubordinateRegisters(Mechanisms, Document, TablesForRegisteredRecords, Cancel)
	
	If DocumentProperties(Document).WriteMode = DocumentWriteMode.Posting And ValueIsFilled(TablesForRegisteredRecords) Then
		For Each Mechanism In Mechanisms Do
			Mechanism.Value.MechanismModule.ReflectRegisteredRecords(TablesForRegisteredRecords, Document.RegisterRecords, Cancel);
		EndDo;
	EndIf;
	
EndProcedure

Procedure SetAdditionalPropertiesOfControlRegisters(Mechanisms, Document, TempTablesManager)
	
	For Each Mechanism In Mechanisms Do
		For Each Register In Mechanism.Value.TaskControlRegisters Do
			RegisterRegisteredRecords_ = Document.RegisterRecords.Find(Register.Name);
			If RegisterRegisteredRecords_ <> Undefined And RegisterRegisteredRecords_.Write Then
				SetAdditionalPropertiesForControl(
					RegisterRegisteredRecords_,
					Document,
					TempTablesManager,
					True,
					False,
					False,
					True);
			EndIf;
		EndDo;
		For Each Register In Mechanism.Value.ControlRegistersOfChanges Do
			RegisterRegisteredRecords_ = Document.RegisterRecords.Find(Register.Name);
			If RegisterRegisteredRecords_ <> Undefined And RegisterRegisteredRecords_.Write Then
				SetAdditionalPropertiesForControl(
					RegisterRegisteredRecords_,
					Document,
					TempTablesManager,
					True,
					True,
					False,
					False);
			EndIf;
		EndDo;
		For Each Register In Mechanism.Value.ControlRegistersBanDate Do
			RegisterRegisteredRecords_ = Document.RegisterRecords.Find(Register.Name);
			If RegisterRegisteredRecords_ <> Undefined And RegisterRegisteredRecords_.Write Then
				SetAdditionalPropertiesForControl(
					RegisterRegisteredRecords_,
					Document,
					TempTablesManager,
					True,
					False,
					True,
					False);
				DisableVerificationOfDateWhenChangesWereBanned(RegisterRegisteredRecords_);
			EndIf;
		EndDo;	
	EndDo;
	
EndProcedure

Procedure SetAdditionalPropertiesForControl(RegisterRegisteredRecords_, Document, TempTablesManager, CalculateChanges_,
			ThisIsControlRegisterOfChanges, ThisIsControlRegisterOfDatesOfBan, ThisIsTaskControlRegister)
	
	AddRegisterProperties = RegisterRegisteredRecords_.AdditionalProperties;
	AddRegisterProperties.Insert("TempTablesManager", TempTablesManager);
	AddRegisterProperties.Insert("ControlTables", Document.AdditionalProperties.DocumentsPosting.ControlTables);
	AddRegisterProperties.Insert("RecorderDate", Document.Date);
	AddRegisterProperties.Insert("CalculateChanges_", CalculateChanges_);
	If ThisIsControlRegisterOfChanges <> Undefined Then
		AddRegisterProperties.Insert("ThisIsControlRegisterOfChanges", ThisIsControlRegisterOfChanges);
	EndIf;
	If ThisIsControlRegisterOfDatesOfBan <> Undefined Then
		AddRegisterProperties.Insert("ThisIsControlRegisterOfDatesOfBan", ThisIsControlRegisterOfDatesOfBan);
	EndIf;
	If ThisIsTaskControlRegister <> Undefined Then
		AddRegisterProperties.Insert("ThisIsTaskControlRegister", ThisIsTaskControlRegister);
	EndIf;
	
EndProcedure

Procedure DisableVerificationOfDateWhenChangesWereBanned(RegisterRegisteredRecords_)
	
	AddRegisterProperties = RegisterRegisteredRecords_.AdditionalProperties;
	AddRegisterProperties.Insert("SkipPeriodClosingCheck", True);
	
EndProcedure

Procedure ProcessDocumentBeforeRecording(Mechanisms, Document, TempTablesManager, Cancel);
	
	For Each Mechanism In Mechanisms Do
		If Mechanism.Value.ThereAreDerivedMotions Then
			Mechanism.Value.MechanismModule.BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckBanDateInChangesTable(Mechanisms, Document, TempTablesManager, Cancel) Export
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	
	QueryTemplate = "
	|SELECT
	|	MIN(Table.Period) AS Period,
	|	Table.Organization AS Organization,
	|	Table.RegisterName AS RegisterName,
	|	Table.SectionClosingDates AS SectionClosingDates
	|FROM
	|	&DataCollection AS Table
	|GROUP BY
	|	Table.Organization,
	|	Table.SectionClosingDates,
	|	Table.RegisterName
	|;
	|";
	
	TheTextOfASubquery = "";
	TempTablesQueryText = "";
	TemporaryTableNames = "";
	
	AddControlRequestText(
		Query,
		TheTextOfASubquery,
		TempTablesQueryText,
		TemporaryTableNames,
		Mechanisms);
	
	TextDestroyW = MonthEndTransactionsServer.TemporaryTableDestructionQueryTest(TemporaryTableNames);
	
	If ValueIsFilled(TheTextOfASubquery) Then // there is at least one control register.
		Query.Text = TempTablesQueryText
			+ StrReplace(QueryTemplate, "&DataCollection", "(" + TheTextOfASubquery + ")")
			+ TextDestroyW;
			
		Selection = Query.Execute().Select();
		
		While Selection.Next() Do
			DataToCheck = PeriodClosingDates.DataToCheckTemplate();
			
			NewRow = DataToCheck.Add();
			NewRow.Date   = BegOfDay(Selection.Period);
			NewRow.Object = Selection.Organization;
			NewRow.Section = Selection.SectionClosingDates;
			
			ErrorDescription = NStr("vi = 'Dữ liệu thay đổi nằm trong kỳ đã đóng.';
									|ru = 'Изменяемые данные находятся в закрытом периоде.';
									|en = 'The data being changed is in closed period.'; fa = 'The data being changed is in closed period.';
									|it = 'Dati da modificare sono in un periodo chiuso.';
									|pl = 'Zmieniane dane znajdują się w zamkniętym okresie.';
									|tr = 'Değiştirilen veriler kapalı bir dönemdedir.'");
			RegisterRecords = Document.RegisterRecords[Selection.RegisterName];
			If RegisterRecords.AdditionalProperties.Property("CheckingDateWhenChangesWereBanned") 
					And Not RegisterRecords.AdditionalProperties.CheckingDateWhenChangesWereBanned Then
				Continue
			EndIf;
			If RegisterRecords.AdditionalProperties.Property("SkipPeriodClosingCheck") 
					And RegisterRecords.AdditionalProperties.SkipPeriodClosingCheck Then
				Continue
			EndIf;
			If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, 
					New Structure("NewVersion, Data", True, Document.RegisterRecords[Selection.RegisterName]),
					ErrorDescription) Then
				Common.MessageToUser(ErrorDescription, ,,,Cancel);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

// Supplements the Query Text of the ban date control mechanism.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 	QueryText - String - a string with the request text.
// 	TempTablesQueryText - String - a string containing the text of a temporary table query.
// 	TemporaryTableNames - String - array of names of temporary tables to be created for later destruction.
// 	Mechanisms - ValueList of See ParametersOfAccountingMechanism - list of mechanisms.
Procedure AddControlRequestText(Query, QueryText, TempTablesQueryText, TemporaryTableNames, Mechanisms)
	For Each Mechanism In Mechanisms Do
		
		If Not ValueIsFilled(Mechanism.Value.ControlRegistersBanDate) Then
			Continue;
		EndIf;
		
		MatchingRequests = Mechanism.Value.MechanismModule.QueryTextsMonitoringBanDateBasedOnChangesTable(Query);
		
		For Each MapItem In MatchingRequests Do
			MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
				MapItem.Value,
				Query.TempTablesManager.Tables,
				QueryText,
				TempTablesQueryText,
				TemporaryTableNames);
		EndDo;
	EndDo;
EndProcedure


// Records movements in an independent data register.
// 
// Parameters:
// 	Mechanisms - ValueList of See DocumentsPosting.ParametersOfAccountingMechanism
// 	Document - DocumentObject - 
// 	TablesForRegisteredRecords - Structure -
// 	TempTablesManager - TempTablesManager -
// 	Cancel - Boolean -
Procedure RecordRegisteredRecordsOfIndependentRegisters(Mechanisms, Document, TablesForRegisteredRecords, TempTablesManager, Cancel)
	
	If ValueIsFilled(TablesForRegisteredRecords) Then
		For Each Mechanism In Mechanisms Do
			If ValueIsFilled(Mechanism.Value.IndependentRegisters) Then
				Mechanism.Value.MechanismModule.WriteData(TablesForRegisteredRecords, Document.Ref, TempTablesManager, Cancel);
			EndIf;
		EndDo;
	EndIf;
	
EndProcedure

Procedure ProcessDocumentAfterRecordingRegisteredRecords(Mechanisms, Document, TempTablesManager, Cancel);
	
	For Each Mechanism In Mechanisms Do
		If Mechanism.Value.ThereAreDerivedMotions Then
			Mechanism.Value.MechanismModule.AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel);
		EndIf;
	EndDo;
	
	SetPrivilegedMode(True);
	BackdateJobQueue.UncheckCompletedWithErrorBasedOnDocuments(
		CommonClientServer.ValueInArray(Document.Ref));
	SetPrivilegedMode(False);
	
EndProcedure

Procedure PerformControlOfResultsOf(Mechanisms, Document, TempTablesManager, Cancel)
	
	If ValueIsFilled(SessionParameters.UpdateHandlerParameters.ExecutionMode) Then
		Return;
	EndIf;
	
	Query        = New Query;
	QueryTexts = New ValueList;
	Query.TempTablesManager = TempTablesManager;
	
	For Each Mechanism In Mechanisms Do
		
		If Not ValueIsFilled(Mechanism.Value.ControlRegistersOfChanges) Then
			Continue;
		EndIf;
		
		Mechanism.Value.MechanismModule.InitializeChangeControlData(Query, QueryTexts, Document);
		
	EndDo;
	
	If QueryTexts.Count() = 0 Then
		Return;
	EndIf;
	
	ControlResults = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts,, True);
	
	For Each Mechanism In Mechanisms Do
		
		If Not ValueIsFilled(Mechanism.Value.ControlRegistersOfChanges) Then
			Continue;
		EndIf;
		
		Mechanism.Value.MechanismModule.ReportChangeControlResults(ControlResults, Document, Cancel);
		
	EndDo;
	
	If Cancel Then
		
		If DocumentProperties(Document).WriteMode = DocumentWriteMode.Posting Then
			MessageText = NStr("vi = 'Chưa kết chuyển %1';
								|ru = 'Проведение не выполнено %1';
								|en = 'Posting is not executed %1'; fa = 'Posting is not executed %1';
								|it = 'Registrazione non completata %1';
								|pl = 'Zatwierdzenie nie zostało wykonane %1';
								|tr = 'Kaydetme gerçekleştirilmedi %1'");
		Else
			MessageText = NStr("vi = 'Hủy bỏ không thành công %1';
								|ru = 'Отмена проведения не выполнена %1';
								|en = 'Posting was not canceled %1'; fa = 'Posting was not canceled %1';
								|it = 'Annullamento della registrazione non completato %1';
								|pl = 'Anulowanie zatwierdzenia nie zostało wykonane %1';
								|tr = 'İptal kaydı gerçekleştirilemedi %1'");
		EndIf;
		
		Common.MessageToUser(StrTemplate(MessageText, String(Document)), Document);
		
	EndIf;
	
EndProcedure

Procedure MarkExecutionOfProcessingOfUpdateOfSubordinateRegisters(RegisterNames, Document)

	If InfobaseUpdate.DeferredUpdateCompleted() Then
		Return;
	EndIf;
	
	ExchangePlan = Metadata.ExchangePlans.InfobaseUpdate;
	
	For Each RegisterName In RegisterNames Do
		RecordSet = Document.RegisterRecords[RegisterName];
		If ExchangePlan.Content.Contains(RecordSet.Metadata()) Then
			InfobaseUpdateTM.MarkInteractiveProcessing(RecordSet);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region ConductingMechanismsThroughOperations

Function HashSumOfQueryTexts(ReflectionTemplateTexts, TextsOfDocumentDataRequests, TemporaryTableTemplateTexts)
	
	Hashing = New DataHashing(HashFunction.MD5);
	For Each KeyAndValue In ReflectionTemplateTexts Do 
		Hashing.Append(KeyAndValue.Value);
	EndDo;
	For Each KeyAndValue In TextsOfDocumentDataRequests Do 
		Hashing.Append(KeyAndValue.Value);
	EndDo;
	If TemporaryTableTemplateTexts <> Undefined Then
		For Each KeyAndValue In TemporaryTableTemplateTexts Do 
			Hashing.Append(KeyAndValue.Value);
		EndDo;
	EndIf;
	Return String(Hashing.HashSum);
	
EndFunction

Function ExecutionRequestTextsFromCache(HashSum)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	QueryTextCache.QueriesTexts AS QueriesTexts
	|FROM
	|	InformationRegister.QueryTextCache  AS QueryTextCache 	
	|WHERE
	|	QueryTextCache.HashSum = &HashSum 
	|";
	
	Query.SetParameter("HashSum", HashSum); 
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.QueriesTexts.Get();	
	EndIf;
	
	Return Undefined;
	
EndFunction

Procedure SaveTextsOfEventRequestsToCache(HashSum, QueriesTexts)
	
	SetPrivilegedMode(True);
	Record = InformationRegisters.QueryTextCache.CreateRecordManager();
	Record.HashSum = HashSum;
	Record.QueriesTexts =  New ValueStorage(QueriesTexts);
	Record.Write();
	
EndProcedure

Function TextsOfRequestsForHolding()
	
	RequestForHolding = New Structure();
	RequestForHolding.Insert("TextsForCreatingTemporaryTables", New ValueList);
	RequestForHolding.Insert("TextsOfEventByRegister", New ValueList);
	
	Return RequestForHolding;
	
EndFunction

Procedure AddTextsOfEventRequestsToPackage(QueriesTexts, RequestsForHolding)
	
	For Each ListItem In RequestsForHolding.TextsForCreatingTemporaryTables Do
		QueriesTexts.Add(ListItem.Value, ListItem.Presentation, ListItem.Check);	
	EndDo;

	For Each ListItem In RequestsForHolding.TextsOfEventByRegister Do
		QueriesTexts.Add(ListItem.Value, ListItem.Presentation, ListItem.Check);	
	EndDo;
		
	For Each ListItem In RequestsForHolding.TextsForCreatingTemporaryTables Do
		If KeywordPosition("ADD", ListItem.Value) <> Undefined Then //@Query-part
			Continue;
		EndIf;
		DeleteText_ = StrTemplate("DROP %1", ListItem.Presentation);
		QueriesTexts.Add(DeleteText_);
	EndDo;
	
EndProcedure


Procedure InsertRoomIntoTemporaryTable(QueryText, Val TempTableName)
	
	If KeywordPosition("INTO", QueryText) <> Undefined Then //@Query-part
		Return;
	EndIf;
	If KeywordPosition("ADD", QueryText) <> Undefined Then //@Query-part
		Return;
	EndIf;
	
	ReplacementString = StrTemplate("INTO %1 
		                     |FROM", TempTableName); //@Query-part
	// You need to insert it only in the first fragment of the union
	ArrayOfAssociations = StringFunctionsClientServer.SplitStringIntoSubstringsArray(QueryText, "UNION"); //@Query-part
	PerformFullMatchReplacement(ArrayOfAssociations[0], "FROM", ReplacementString, True); //@Query-part
	QueryText = StrConcat(ArrayOfAssociations,  "UNION"); //@Query-part
	
EndProcedure

Procedure PerformFullMatchReplacement(Text, Val SearchString, Val ReplacementString, OnlyFirst_1 = False)
	
	If OnlyFirst_1 Then
		ReplaceFirstOneWithFullMatch(Text, SearchString, ReplacementString);
		Return;
	EndIf;
	
	If StrStartsWith(SearchString, "#") Then
		RegularExpression = "\B\%1\b";
	Else
		RegularExpression = "\b%1\b";
	EndIf;                         
	RegularExpression = StrTemplate(RegularExpression, SearchString); 
	Text = StrReplaceByRegularExpression(Text, RegularExpression, ReplacementString);
	
EndProcedure

Procedure ReplaceFirstOneWithFullMatch(Text, Val SearchString, Val ReplacementString)
	
	SourceText = Text;
	Text = "";
	
	TextLength = StrLen(SourceText);
	SearchStringLength = StrLen(SearchString);
	
	SearchStringPosition = 1;
	
	While SearchStringPosition <> 0 Do
		
		SearchStringPosition = StrFind(SourceText, SearchString);
		If SearchStringPosition = 0 Then
			Continue;
		EndIf;
		
		PerformReplacement = True;
		If SearchStringPosition > 1 Then
			PreviousChar = Mid(SourceText, SearchStringPosition -1 , 1);
			If Not ServiceSymbol(PreviousChar) Then
				PerformReplacement = False;
			EndIf;
		EndIf;
		
		If PerformReplacement Then
			If SearchStringPosition < TextLength Then
				NextChar = Mid(SourceText, SearchStringPosition + SearchStringLength, 1);
				If Not ServiceSymbol(NextChar) Then
					PerformReplacement = False;
				EndIf;
			EndIf;
		EndIf;
		
		If PerformReplacement Then	
			Text = Text + Left(SourceText, SearchStringPosition - 1) + ReplacementString;
			SourceText = Mid(SourceText, SearchStringPosition + SearchStringLength, TextLength);
			TextLength = TextLength - SearchStringPosition + 1 - SearchStringLength;
			SearchStringPosition = 0;
			Continue;
		Else
			Text = Text + Left(SourceText, SearchStringPosition - 1) + SearchString;
			SourceText = Mid(SourceText, SearchStringPosition + SearchStringLength, TextLength);
			TextLength = TextLength - SearchStringPosition + 1 - SearchStringLength;
		EndIf;
		
	EndDo;
	
	Text = Text + SourceText; 
	
EndProcedure

Function ParseRequestText(Val QueryText)
	
	Result = New Structure;
	
	PositionSELECT = KeywordPosition("SELECT", QueryText); //@Query-part
	PositionFrom_      = KeywordPosition("FROM", QueryText); //@Query-part
	PositionWHERE     = KeywordPosition("WHERE", QueryText); //@Query-part
	
	SampleSymbols = PositionFrom_.StartPosition - PositionSELECT.EndPosition;
	SelectionText = Mid(QueryText, PositionSELECT.EndPosition, SampleSymbols); 
	StructureOfSelectionFields = StructureOfSelectionFields(SelectionText);
	
	If PositionWHERE = Undefined Then
		
		TableSymbols = StrLen(QueryText) - PositionFrom_.EndPosition;
		TableText = TrimAll(Right(QueryText, TableSymbols));
		TextSelection_ = "";
		
	Else
		
		TableSymbols = PositionWHERE.StartPosition - PositionFrom_.EndPosition;
		TableText = TrimAll(Mid(QueryText, PositionFrom_.EndPosition, TableSymbols));
		
		SpecialSelection =  StrLen(QueryText) - PositionWHERE.EndPosition;
		TextSelection_ = TrimAll(Right(QueryText, SpecialSelection));
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("SelectionFields1", StructureOfSelectionFields);
	Result.Insert("Tables", TableText);
	Result.Insert("Filter", TextSelection_);
	
	Return Result;
	
EndFunction

Function ReflectionQueryWithDataSelectionFromTemporaryTable(Val TextReflectionPattern, Val DataTableName)
	
	TextReflectionRequest = TextReflectionPattern;
	
	PartsOfSearchString = New Array;
	PartsOfSearchString.Add("#");
	PartsOfSearchString.Add(DataTableName);
	SearchString = StrConcat(PartsOfSearchString);
	
	TextReflectionRequest = StrReplace(TextReflectionPattern, SearchString, DataTableName);
	
	Return TextReflectionRequest;
	
EndFunction

Function RequestReflectionWithSelectionOfDataFromDocument(Val TextReflectionPattern, Val DataTableName, Val QueryTextdata_)
	
	TextReflectionRequest = TextReflectionPattern;
	
	If StrFind(TextReflectionRequest, "#" + DataTableName, SearchDirection.FromEnd) = 0 Then
		// The query does not require fetching from the data table.
		Return TextReflectionRequest;
	EndIf;
	
	If TypeOf(QueryTextdata_) = Type("String") Then
		ResultOfQueryTextParsing = ParseRequestText(QueryTextdata_);
	Else
		ResultOfQueryTextParsing = QueryTextdata_;
	EndIf;
	
	PerformSubstitutionsInSelectSection(TextReflectionRequest, DataTableName, ResultOfQueryTextParsing);
	PerformSubstitutionsInSectionFrom(TextReflectionRequest, DataTableName, ResultOfQueryTextParsing);
	CombineSelectionsIntoSectionsWhere(TextReflectionRequest, DataTableName, ResultOfQueryTextParsing);
	
	Return TextReflectionRequest;
	
EndFunction

Procedure PerformSubstitutionsInSectionFrom(QueryText, DataTableName, ResultOfParsingDataRequestText)
	
	SearchString = StrTemplate("#%1 AS %1", DataTableName);
	ReplacementString = StrTemplate("%1 //#%2", ResultOfParsingDataRequestText.Tables, DataTableName);
	PerformFullMatchReplacement(QueryText, SearchString, ReplacementString);
	
EndProcedure

Procedure PerformSubstitutionsInSelectSection(QueryText, DataTableName, ResultOfParsingDataRequestText)
	
	For Each SelectionField In ResultOfParsingDataRequestText.SelectionFields1 Do
		SearchString = StrTemplate("%1.%2", DataTableName, SelectionField.Key); 
		PerformFullMatchReplacement(QueryText, SearchString, SelectionField.Value);
	EndDo;
	
EndProcedure

Procedure CombineSelectionsIntoSectionsWhere(TextReflectionRequest, DataTableName, ResultOfParsingDataRequestText)
	
	SelectingDocumentDataRequest = ResultOfParsingDataRequestText.Filter; 
	If Not ValueIsFilled(SelectingDocumentDataRequest) Then
		Return;
	EndIf;
	
	ArrayOfPacketFragments = StrSplit(TextReflectionRequest, ";");
	MaximumPackageIndex = ArrayOfPacketFragments.Count() - 1;
	For PackageIndex = 0 To MaximumPackageIndex Do 
		
		ArrayOfUnionFragments = StringFunctionsClientServer.SplitStringIntoSubstringsArray(ArrayOfPacketFragments[PackageIndex], "UNION"); //@Query-part
		
		// There are two possible scenarios for inserting a selection
		// 1. Combining with the existing selection. If there is already a selection in the request, then we take it in "()" and insert an additional one. selection with "And".
		// 2. Adding selection. If there is no selection in the request, then we insert it together with "WHERE".
		// The insertion location is determined by the keyword preceding the selection.
		// If the keyword is not found, then the selection is inserted at the end of the query.
		Keywords = New Array;
		Keywords.Add("GROUP"); //@Query-part
		Keywords.Add("ORDER"); //@Query-part
		Keywords.Add("TOTALS"); //@Query-part
		
		MaximumIndex = ArrayOfUnionFragments.Count() - 1; 
		For UnionIndex = 0 To MaximumIndex Do
			
			If StrFind(ArrayOfUnionFragments[UnionIndex], "#" + DataTableName) = 0 Then
				// In the merge fragment, the selection from the current data table is not performed.
				Continue;
			EndIf;
			
			PositionWHERE = KeywordPosition("WHERE", ArrayOfUnionFragments[UnionIndex]); //@Query-part
			
			KeywordBeforeSelection = Undefined;
			For Each Keyword In Keywords Do
				KeywordPosition = KeywordPosition(Keyword, ArrayOfUnionFragments[UnionIndex]);
				If KeywordPosition <> Undefined Then
					KeywordBeforeSelection = Keyword;
					Break;
				EndIf;
			EndDo;
			
			If PositionWHERE = Undefined Then
				If KeywordBeforeSelection = Undefined Then
					FilterTemplate = 
					   "WHERE
					   |	%1
					   |";
					TextSelection_ = StrTemplate(FilterTemplate, SelectingDocumentDataRequest);
					ArrayOfUnionFragments[UnionIndex] = ArrayOfUnionFragments[UnionIndex] + "
					   |" + TextSelection_;
				Else
					FilterTemplate = 
					   "WHERE
					   |	%1
					   |%2";
					TextSelection_ = StrTemplate(FilterTemplate, SelectingDocumentDataRequest, KeywordBeforeSelection);
					PerformFullMatchReplacement(ArrayOfUnionFragments[UnionIndex],
														KeywordBeforeSelection,
														TextSelection_,
														True);
				EndIf;
			Else
				If KeywordBeforeSelection = Undefined Then
					FilterTemplate = 
					   "WHERE
					   |	(%1) 
					   |	AND (";
					TextSelection_ = StrTemplate(FilterTemplate, SelectingDocumentDataRequest);
					PerformFullMatchReplacement(ArrayOfUnionFragments[UnionIndex],
														"WHERE",
														TextSelection_,
														True); 
					ArrayOfUnionFragments[UnionIndex] = ArrayOfUnionFragments[UnionIndex] + ")";
				Else
					FilterTemplate = 
					   "WHERE
					   |	(%1) 
					   |	AND (";
					TextSelection_ = StrTemplate(FilterTemplate, SelectingDocumentDataRequest);
					PerformFullMatchReplacement(ArrayOfUnionFragments[UnionIndex],
														"WHERE",
														TextSelection_,
														True); //@Query-part-1 
									
					KeywordReplacementText = StrTemplate(") %1", KeywordBeforeSelection);
					PerformFullMatchReplacement(ArrayOfUnionFragments[UnionIndex],
														KeywordBeforeSelection,
														KeywordReplacementText,
														True);

				EndIf;
			EndIf;
		EndDo;
		
		ArrayOfPacketFragments[PackageIndex] = StrConcat(ArrayOfUnionFragments, "UNION"); //@Query-part
		
	EndDo;
	
	TextReflectionRequest = StrConcat(ArrayOfPacketFragments, ";");
	
EndProcedure

Function StructureOfSelectionFields(SelectionText)
	
	StructureOfSelectionFields = New Structure;
	SampleSubstringsForAnalysis = StrSplit(SelectionText, ",", False);
    WordLengthAS = StrLen("AS"); //@query-part
	
	// Convert an array of sample substrings separated by "," into an array of sample expressions.
	SelectionSubstring = "";
	For Each Substring In SampleSubstringsForAnalysis Do
		
		SelectionSubstring = SelectionSubstring + ?(SelectionSubstring = "", "", ",") + Substring;	
		
		NumberOfOpeningsClosuresOfBrackets = StrOccurrenceCount(SelectionSubstring, "(") - StrOccurrenceCount(SelectionSubstring, ")");
		NumberOfDoubleQuotes = StrOccurrenceCount(SelectionSubstring, """");
		
		If NumberOfOpeningsClosuresOfBrackets = 0 And NumberOfDoubleQuotes%2 = 0 Then
			
			PositionAS = StrFind(SelectionSubstring, "AS", SearchDirection.FromEnd); //@query-part
			If PositionAS = 0 Then
				Raise NStr("vi = 'Tên ảo phải được chỉ định cho tất cả các trường lựa chọn.';
							|ru = 'Для всех полей выборки должен быть задан псевдоним';
							|en = 'All selection fields should have an alias'; fa = 'All selection fields should have an alias';
							|it = 'Deve essere fornito uno pseudonimo a tutti i campi';
							|pl = 'Wszystkie przykładowe pola muszą mieć aliasy';
							|tr = 'Tüm örnek alanlarının bir takma adı olmalıdır'");
			EndIf;  
			
			Expression = StrTemplate("(%1)", TrimAll(Left(SelectionSubstring, PositionAS - 1)));
			Alias = TrimAll(Right(SelectionSubstring, StrLen(SelectionSubstring) - (PositionAS + WordLengthAS)));
			StructureOfSelectionFields.Insert(Alias, Expression);
			
			SelectionSubstring = "";
			
		EndIf;
		
	EndDo;
	
	Return StructureOfSelectionFields;
	
EndFunction

Function KeywordPosition(Keyword, QueryText, Val StartingSearchPosition = 1)
	
	RegularExpression = StrTemplate("\b%1\b", Keyword);
	SearchResult = StrFindByRegularExpression(QueryText, RegularExpression,,StartingSearchPosition);
	
	If SearchResult.StartIndex <> 0 Then
		Return New Structure(
						"StartPosition, EndPosition", 
						SearchResult.StartIndex, 
						SearchResult.StartIndex + SearchResult.Length);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function ServiceSymbol(Char)
	
	If Char = " "
		Or Char = "
					|"
		Or Char = "."
		Or Char = "	"
		Or Char = ","
		Or Char = ")"
		Or Char = "("
		Or Char = "-"
		Or Char = "+"
		Or Char = "/"
		Or Char = "*"
		Or Char = "" Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

#EndRegion

#Region RestoringDocumentRegisteredRecords

// Initializes the structure of the event parameters.
// 
// Parameters:
//  DataSource - Query, Undefined - Data source
//  DecodingErrorCodes - Map - Decoding error codes
//  TemporaryTableNamePartialHolding - String - Name of the temporary table partial holding
//  TemporaryTableNameFullName - String - Temporary table name full name
// 
// Returns:
//  Structure - Initialize Motion Recovery Parameters:
// * TemporaryTableNamePartialHolding - String -
// * TemporaryTableNameFullName - String -
// * TextOfAdditionalDataPreparationRequest - String -
// * ReasonForReplaying - String -
// * AdditionalFields - Undefined -
// * OnlyLogErrors - Boolean -
// * OnlyRecheck - Boolean -
// * MonthEndClosingOperations - Undefined -
// * CalculationPeriod - Undefined -
// * Importance - Undefined -
// * LogErrors - Boolean -
// * EventLogEventName - String -
// * CalledFromCostCalculation - Boolean -
// * RegisterRecordedOnlyInCurrentPeriod - Boolean -
// * DocumentsForFullImplementation - ValueTable -:
// ** Ref - DocumentRef - 
// ** Organization - CatalogRef.Companies -
// ** ErrorCode - Number -
Function InitializeMotionRecoveryParameters(DataSource, DecodingErrorCodes,
			TemporaryTableNamePartialHolding = "", TemporaryTableNameFullName = "") Export
	
	ParametersOfTheEvent = New Structure;
	ParametersOfTheEvent.Insert("DataSource", 							DataSource);
	ParametersOfTheEvent.Insert("DecodingErrorCodes", 					DecodingErrorCodes);
	ParametersOfTheEvent.Insert("TemporaryTableNamePartialHolding",	TemporaryTableNamePartialHolding);
	ParametersOfTheEvent.Insert("TemporaryTableNameFullName",     TemporaryTableNameFullName);
	
	ParametersOfTheEvent.Insert("TextOfAdditionalDataPreparationRequest", "");
	
	ParametersOfTheEvent.Insert("ReasonForReplaying", 				"");
	ParametersOfTheEvent.Insert("AdditionalFields", 					Undefined);
	ParametersOfTheEvent.Insert("OnlyLogErrors", 			False); // without double-checking
	ParametersOfTheEvent.Insert("OnlyRecheck", 				False); // without error registration
	ParametersOfTheEvent.Insert("MonthEndClosingOperations", 				Undefined);
	ParametersOfTheEvent.Insert("CalculationPeriod", 						Undefined);
	ParametersOfTheEvent.Insert("Importance", 							Undefined);
	ParametersOfTheEvent.Insert("LogErrors",	True);
	ParametersOfTheEvent.Insert("EventLogEventName", 		"");
	
	// Service parameters
	ParametersOfTheEvent.Insert("CalledFromCostCalculation", 	False);
	ParametersOfTheEvent.Insert("RegisterRecordedOnlyInCurrentPeriod", 		False); // for documents that have Registered Records in several periods
	
	DocumentsForFullImplementation = New ValueTable;
	DocumentsForFullImplementation.Columns.Add("Ref",		New TypeDescription(Documents.AllRefsType()));
	DocumentsForFullImplementation.Columns.Add("Organization",	New TypeDescription("CatalogRef.Companies"));
	DocumentsForFullImplementation.Columns.Add("ErrorCode", 	New TypeDescription("Number"));
	
	ParametersOfTheEvent.Insert("DocumentsForFullImplementation", DocumentsForFullImplementation); // documents that could not be held in a separate register
	
	Return ParametersOfTheEvent;
	
EndFunction

// It will re-send documents to several accumulation registers.
//
// Parameters:
//	ParametersOfTheEvent - See InitializeMotionRecoveryParameters
//
// Returns:
//  Structure -
//
Function RestoreDocumentRegisteredRecords(ParametersOfTheEvent) Export
	
	ResultOfCarryingOut = New Structure;
	ResultOfCarryingOut.Insert("FormationTime", 	New Array);
	ResultOfCarryingOut.Insert("ModifiedRegisters",  New Structure);
	ResultOfCarryingOut.Insert("NumberOfDocuments", 0);
	ResultOfCarryingOut.Insert("ExecutedSuccessfully",    False);
	ResultOfCarryingOut.Insert("ConductErrors",    New Array);
	ResultOfCarryingOut.Insert("DecodingErrors",   New Array);
	
	RequestExecutionStarts = CurrentUniversalDateInMilliseconds();
	
	#Region CreatingDocumentTable
	
	Query = ParametersOfTheEvent.DataSource; // Query
	Query.SetParameter("TypesOfServiceDocuments", TypesOfServiceDocumentsWithoutRechecking());
	
	RequestSourceText = Query.Text;
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query);
	
	Query.Execute();
	
	ExistingTT = CostCalculationAppliedAlgorithms.GetListOfExistingTemporaryTables(Query, ExistingTT)
		 + ?(ValueIsFilled(ParametersOfTheEvent.TemporaryTableNameFullName), "," + ParametersOfTheEvent.TemporaryTableNameFullName, "");
		
	#EndRegion
	
	#Region TableOfPointsInTime
	
	If Not CostCalculationAppliedAlgorithms.TemporaryTableExists(Query, "TTPointsInTime") Then
		
		NewRequestText = "";
		QueryTemplate = "
		|SELECT DISTINCT
		|	T.Ref
		|INTO TTRecordersSummary
		|FROM
		|	TempTableName AS T";
		
		If ValueIsFilled(ParametersOfTheEvent.TemporaryTableNamePartialHolding) Then
			
			NewRequestText = StrReplace(QueryTemplate, "TempTableName", ParametersOfTheEvent.TemporaryTableNamePartialHolding);
			
		EndIf;
		
		If ValueIsFilled(ParametersOfTheEvent.TemporaryTableNameFullName)
		 And CostCalculationAppliedAlgorithms.TemporaryTableExists(Query, ParametersOfTheEvent.TemporaryTableNameFullName) Then // The table can be generated later, in the text in addition to the data preparation query
			
			If Not ValueIsFilled(ParametersOfTheEvent.TemporaryTableNamePartialHolding) Then
				
				NewRequestText = StrReplace(QueryTemplate, "TempTableName", ParametersOfTheEvent.TemporaryTableNameFullName);
				
			Else
				
				NewRequestText = NewRequestText + "
					|
					|UNION
					|" 
					+ StrReplace(
						StrReplace(QueryTemplate, "INTO TTRecordersSummary", ""),
						"TempTableName",
						ParametersOfTheEvent.TemporaryTableNameFullName);
				
			EndIf;
			
		EndIf;
		
		Query.Text = NewRequestText;
		Query.Execute();
		
		CostCalculationAppliedAlgorithms.GenerateTableOfPointsInTime(Query, "TTRecordersSummary", "Ref"); // creates a moment in time
		
	EndIf;
	
	#EndRegion
	
	#Region AdjustingDataForProcessing
	
	If ValueIsFilled(ParametersOfTheEvent.TextOfAdditionalDataPreparationRequest) Then
		
		Query.Text = ParametersOfTheEvent.TextOfAdditionalDataPreparationRequest;
		Query.Execute();
		
	EndIf;
	
	#EndRegion
	
	ResultOfCarryingOut.FormationTime.Add(New Structure("BeginTime, EndTime", RequestExecutionStarts, CurrentUniversalDateInMilliseconds()));
	
	ThereAreDocumentsForPartialImplementation = False;
	ThereAreDocumentsForFullImplementation    = False;
	TemporaryTableNameFullName  = ParametersOfTheEvent.TemporaryTableNameFullName;
	
	SizeOfReplayTable = 0
		+ ?(ValueIsFilled(ParametersOfTheEvent.TemporaryTableNamePartialHolding),
			CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, ParametersOfTheEvent.TemporaryTableNamePartialHolding), 0)
		+ ?(ValueIsFilled(TemporaryTableNameFullName),
			CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, TemporaryTableNameFullName), 0);
	
	#Region RestoringOfRegisteredRecords
	
	If Not ParametersOfTheEvent.OnlyLogErrors Then
		
		#Region PartialRecoveryOfRegisteredRecords
		
		If ValueIsFilled(ParametersOfTheEvent.TemporaryTableNamePartialHolding) Then
			
			NewRequestText =
			"SELECT DISTINCT
			|	T.RegisterName 				 AS RegisterName,
			|	T.Ref 	  				 AS Ref,
			|	T.Organization  				 AS Organization,
			|	T.ErrorCode   				 AS ErrorCode,
			|	PointsInTime.PointInTime AS PointInTime
			|FROM
			|	TempTableName AS T
			|	LEFT JOIN TTPointsInTime AS PointsInTime
			|		ON T.Ref = PointsInTime.Ref
			|WHERE
			|	NOT (VALUETYPE(T.Ref) IN (&TypesOfServiceDocuments))
			|
			|ORDER BY
			|	RegisterName,
			|	PointInTime
			|
			|TOTALS BY
			|	RegisterName";
			
			NewRequestText = StrReplace(NewRequestText, "TempTableName", ParametersOfTheEvent.TemporaryTableNamePartialHolding);
			
			Query.Text = NewRequestText;
			
			QueryResult = Query.Execute();
			
			ThereAreDocumentsForPartialImplementation = Not QueryResult.IsEmpty();
			
		EndIf;
		
		If ThereAreDocumentsForPartialImplementation Then
			
			// Incorrect movements were detected.
			FetchingRegisters = QueryResult.Select(QueryResultIteration.ByGroups);
			
			While FetchingRegisters.Next() Do
				
				// Let's double-check documents with incorrect movements in the current register.
				SamplingLoggers = FetchingRegisters.Select();
				
				ResultOfCarryingOut.ModifiedRegisters.Insert(TrimAll(FetchingRegisters.RegisterName), SamplingLoggers.Count());
				
				ConductErrors = RecheckDocumentsOnAccumulationRegister(ParametersOfTheEvent, SamplingLoggers, TrimAll(FetchingRegisters.RegisterName));
				
				CommonClientServer.SupplementArray(ResultOfCarryingOut.ConductErrors, ConductErrors, False);
				
			EndDo;
				
		EndIf;
		
		#EndRegion
		
		#Region FullRecoveryOfRegisteredRecords
		
		If ValueIsFilled(TemporaryTableNameFullName)
		 Or ValueIsFilled(ParametersOfTheEvent.DocumentsForFullImplementation) Then
		 
			If ValueIsFilled(ParametersOfTheEvent.DocumentsForFullImplementation) Then
				
				ListOfFields = "%1" + "Ref" + ",%1" + "Organization" + ",%1" + "ErrorCode";
				
				If ValueIsFilled(TemporaryTableNameFullName) Then
					
					// Let's add the table of documents for the full implementation.
					CostCalculationAppliedAlgorithms.MergeValueTableAndTemporaryTable(
						Query,
						TemporaryTableNameFullName,
						ParametersOfTheEvent.DocumentsForFullImplementation,
						ListOfFields,
						ListOfFields,
						"");
					
				Else
					
					TemporaryTableNameFullName = "TTRecordersForFullConduct";
					
					// Let's create a table of documents for the full implementation.
					CostCalculationAppliedAlgorithms.PutTableOfValuesInTemporaryTable(
						Query,
						TemporaryTableNameFullName,
						ParametersOfTheEvent.DocumentsForFullImplementation,
						ListOfFields);
					
				EndIf;
				
			EndIf;
			
	 	EndIf;
	 	
		If ValueIsFilled(TemporaryTableNameFullName) Then
			
			NewRequestText =
			"SELECT DISTINCT
			|	T.Ref 	  				 AS Ref,
			|	T.Organization  				 AS Organization,
			|	T.ErrorCode   				 AS ErrorCode,
			|	PointsInTime.PointInTime AS PointInTime
			|FROM
			|	TempTableName AS T
			|	LEFT JOIN TTPointsInTime AS PointsInTime
			|		ON T.Ref = PointsInTime.Ref
			|WHERE
			|	NOT (VALUETYPE(T.Ref) IN (&TypesOfServiceDocuments))
			|
			|ORDER BY
			|	PointInTime";
			
			NewRequestText = StrReplace(NewRequestText, "TempTableName", TemporaryTableNameFullName);
			
			Query.Text = NewRequestText;
			
			QueryResult = Query.Execute();
			
			ThereAreDocumentsForFullImplementation = Not QueryResult.IsEmpty();
			
		EndIf;
		
		If ThereAreDocumentsForFullImplementation Then
			
			// Let's double-check documents with incorrect movements in the current register.
			SamplingLoggers = QueryResult.Select();
			
			ResultOfCarryingOut.NumberOfDocuments = SamplingLoggers.Count();
			
			ConductErrors = RecheckDocumentsInFull(ParametersOfTheEvent, SamplingLoggers);
			
			CommonClientServer.SupplementArray(ResultOfCarryingOut.ConductErrors, ConductErrors, False);
			
		EndIf;
		
		#EndRegion
		
		#Region ReshapingDocumentTable
		
		If (ThereAreDocumentsForPartialImplementation Or ThereAreDocumentsForFullImplementation)
		 And Not ParametersOfTheEvent.OnlyRecheck Then
			
			// We will re-analyze the movements after rechecking the documents - we expect that there should be no mistakes now.
			// We include official documents in the result - their errors should also be reported.
			CostCalculationAppliedAlgorithms.DestroyTemporaryTables(Query, ExistingTT);
			
			RequestExecutionStarts = CurrentUniversalDateInMilliseconds();
			
			Query.Text = RequestSourceText;
			
			Query.Execute();
			
			If ValueIsFilled(ParametersOfTheEvent.TextOfAdditionalDataPreparationRequest) Then
				
				Query.Text = ParametersOfTheEvent.TextOfAdditionalDataPreparationRequest;
				Query.Execute();
				
			EndIf;
			
			ResultOfCarryingOut.FormationTime.Add(New Structure("BeginTime, EndTime", RequestExecutionStarts, CurrentUniversalDateInMilliseconds()));
			
			SizeOfReplayTable = 0
				+ ?(ValueIsFilled(ParametersOfTheEvent.TemporaryTableNamePartialHolding),
					CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, ParametersOfTheEvent.TemporaryTableNamePartialHolding), 0)
				+ ?(ValueIsFilled(TemporaryTableNameFullName),
					CostCalculationAppliedAlgorithms.TemporaryTableSize(Query, TemporaryTableNameFullName), 0);
			
			ResultOfCarryingOut.ExecutedSuccessfully = (SizeOfReplayTable = 0);
			
		EndIf;
		
		#EndRegion
		
	EndIf;
	
	#EndRegion
	
	#Region ErrorLogging_
	
	If Not ParametersOfTheEvent.OnlyRecheck And SizeOfReplayTable > 0 Then
		
	 	// Incorrect movements remained. Let's collect detailed information about errors in document movements.
		QueryTextTemplate2 =
		"SELECT
		|	&AdditionalFields,
		|	T.RegisterName 				 AS RegisterName,
		|	T.Ref 	  				 AS Ref,
		|	T.Organization  				 AS Organization,
		|	ISNULL(PointsInTime.PointInTime, UNDEFINED) AS PointInTime,
		|	T.ErrorCode   				 AS ErrorCode
		|FROM
		|	TempTableName AS T
		|	LEFT JOIN TTPointsInTime AS PointsInTime
		|		ON T.Ref = PointsInTime.Ref
		|	LEFT JOIN Document.RegisterAdjustment AS AdjustingEntries
		|		ON T.Ref = AdjustingEntries.Ref
		|WHERE
		|	AdjustingEntries.Ref IS NULL
		|	OR AdjustingEntries.Operation IN
		|		(VALUE(Enum.RegisterAdjustmentOperations.EmptyRef),
		|		 VALUE(Enum.RegisterAdjustmentOperations.ManualAdjustment))
		|";
		
		Query.Text = "";
		
		If ValueIsFilled(ParametersOfTheEvent.TemporaryTableNamePartialHolding) Then
			Query.Text = StrReplace(QueryTextTemplate2, "TempTableName", ParametersOfTheEvent.TemporaryTableNamePartialHolding);
		EndIf;
		
		If ValueIsFilled(ParametersOfTheEvent.TemporaryTableNameFullName) Then
			
			If ValueIsFilled(Query.Text) Then
				Query.Text = Query.Text + "
				|
				|UNION ALL
				|
				|";
			EndIf;
			
			Query.Text = Query.Text
				+ StrReplace(
					StrReplace(QueryTextTemplate2, "T.RegisterName", """"""),
					"TempTableName", ParametersOfTheEvent.TemporaryTableNameFullName);
			
		EndIf;
		
		Query.Text = Query.Text + "
		|
		|ORDER BY
		|	ErrorCode,
		|	PointInTime,
		|	RegisterName
		|
		|TOTALS BY
		|	ErrorCode";
		
		TextOfAdditionalFields_ = "";
		
		If ParametersOfTheEvent.AdditionalFields <> Undefined Then
			For Each Field In ParametersOfTheEvent.AdditionalFields Do
				TextOfAdditionalFields_ = TextOfAdditionalFields_ + "T." + Field.Key + ", ";
			EndDo;
		EndIf;
		
		Query.Text = StrReplace(Query.Text, "&AdditionalFields,", TextOfAdditionalFields_);
		
		SamplingErrorCodes = Query.Execute().Select(QueryResultIteration.ByGroups);
		
		While SamplingErrorCodes.Next() Do
			
			ErrorText = ParametersOfTheEvent.DecodingErrorCodes[SamplingErrorCodes.ErrorCode];
			
			If Not ValueIsFilled(ErrorText) Then
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Số %1, không có mô tả';
						|ru = '№%1, описание отсутствует';
						|en = 'No.%1, no description'; fa = 'No.%1, no description';
						|it = '№%1, descrizione mancante';
						|pl = 'Nr%1, opis nie jest dostępny';
						|tr = '№%1, ayrıntılar mevcut değil'", Common.DefaultLanguageCode()),
					SamplingErrorCodes.ErrorCode);
			EndIf;
			
			DecodingError = New Array;
			
			Selection = SamplingErrorCodes.Select();
			
			While Selection.Next() Do
				
				TextOfAdditionalFields_ = "";
				
				If ParametersOfTheEvent.AdditionalFields <> Undefined Then
					For Each Field In ParametersOfTheEvent.AdditionalFields Do
						If ValueIsFilled(Selection[Field.Key]) Then
							TextOfAdditionalFields_ = TextOfAdditionalFields_
								+ StringFunctionsClientServer.SubstituteParametersToString(", %1 ""%2""", Field.Value, Selection[Field.Key]);
						EndIf;
					EndDo;
				EndIf;
				
				If ValueIsFilled(TrimAll(Selection.RegisterName)) Then
					ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 (%2), doanh nghiệp ""%3"", biểu ghi ""%4""%5';
							|ru = '%1 (%2), организация ""%3"", регистр ""%4""%5';
							|en = '%1 (%2), company ""%3"", register ""%4""%5'; fa = '%1 (%2), company ""%3"", register ""%4""%5';
							|it = '%1 (%2), organizzazione ""%3"", registro ""%4""%5';
							|pl = '%1 (%2), firma ""%3"", rejestr ""%4""%5';
							|tr = '%1 (%2), iş yeri ""%3"", sicil ""%4""%5'", Common.DefaultLanguageCode()),
						TrimAll(Selection.Ref),
						GetURL(Selection.Ref),
						TrimAll(Selection.Organization),
						TrimAll(Selection.RegisterName),
						TextOfAdditionalFields_);
				Else
					ProtocolText_ = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("vi = '%1 (%2), doanh nghiệp ""%3""%4';
							|ru = '%1 (%2), организация ""%3""%4';
							|en = '%1 (%2), the ""%3"" company %4'; fa = '%1 (%2), the ""%3"" company %4';
							|it = '%1 (%2), azienda ""%3""%4';
							|pl = '%1 (%2), firma ""%3""%4';
							|tr = '%1 (%2), iş yeri ""%3""%4'", Common.DefaultLanguageCode()),
						TrimAll(Selection.Ref),
						GetURL(Selection.Ref),
						TrimAll(Selection.Organization),
						TextOfAdditionalFields_);
				EndIf;
				
				DecodingError.Add(ProtocolText_);
				
				If ValueIsFilled(ParametersOfTheEvent.MonthEndClosingOperations) Then
					
					RegisterIssueInClosingMonth(
						ParametersOfTheEvent,
						Selection.Organization,
						NStr("vi = 'Không thể sửa lỗi trong các bản ghi kết chuyển chứng từ';
							|ru = 'Не удалось исправить проблемы в движениях документов';
							|en = 'Cannot fix the issues in the document records'; fa = 'Cannot fix the issues in the document records';
							|it = 'Non è stato possibile correggere i problemi nei movimenti dei documenti';
							|pl = 'Nie udało się poprawić problemy w ruchach dokumentów';
							|tr = 'Belge kayıtlarında sorunlar düzeltilemedi'", Common.DefaultLanguageCode()),
						ErrorText + ":" + Chars.LF + ProtocolText_,
						Selection.Ref);
					
				EndIf;
					
			EndDo;
			
			ResultOfCarryingOut.DecodingErrors.Add(
				New Structure("ErrorType, MoreDetails", ErrorText, DecodingError));
			
		EndDo;
		
	Else
		
		ResultOfCarryingOut.ExecutedSuccessfully = (SizeOfReplayTable = 0);
		
	EndIf;
	
	#EndRegion
	
	Query.Text = RequestSourceText;
	
	CostCalculationAppliedAlgorithms.DestroyTemporaryTables(
		Query,
		CostCalculationUniversalAlgorithms.ConnectLines(
			ParametersOfTheEvent.TemporaryTableNamePartialHolding,
			ParametersOfTheEvent.TemporaryTableNameFullName,
			"TTRecordersSummary, TTPointsInTime, TTRecordersForFullConduct"));
	
	Return ResultOfCarryingOut;
	
EndFunction

// Retransmit documents for one accumulation register.
//
// Parameters:
//	ParametersOfTheEvent - See InitializeMotionRecoveryParameters
//	SelectionOfDocuments - QueryResultSelection - the query selection must contain the Link field
//	AccumulationRegisterName - String - name of the accumulation register to re-check the documents for.
//
// Returns:
//	Array of String - Conduct Errors
//
Function RecheckDocumentsOnAccumulationRegister(ParametersOfTheEvent, SelectionOfDocuments, AccumulationRegisterName) Export
	
	ConductErrors = New Array;
	
	If SelectionOfDocuments.Count() = 0 Then
		Return ConductErrors;
	EndIf;
	
	ProcessedDocuments = New Map;
	
	RegistersWithClearing = RegistersForPreClearingWhenReconnecting();
	
	RecordSet = AccumulationRegisters[AccumulationRegisterName].CreateRecordSet();
	RecordSet.AdditionalProperties.Insert(CostCalculationAppliedAlgorithms.NameOfObjectSServiceAdditionalProperty(), True);
	RecordSet.AdditionalProperties.Insert("RecorderDate", ParametersOfTheEvent.CalculationPeriod);
	RecordSet.AdditionalProperties.Insert("DoNotSaveCalculatedRegisteredRecords", True);
	
	// We will create a request to save the Registered Records of the document in past periods.
	// Other mechanics of Registering Recorded movements will not be called.
	Query = New Query;
	Query.SetParameter("BeginOfPeriod", ParametersOfTheEvent.CalculationPeriod);
	Query.SetParameter("EndOfPeriod",  EndOfMonth(ParametersOfTheEvent.CalculationPeriod));
	
	Query.Text =
	"SELECT
	|	*
	|FROM
	|	AccumulationRegisterName AS T
	|WHERE
	|	T.Recorder = &Recorder
	|	AND T.Period < &BeginOfPeriod";
	
	Query.Text = StrReplace(Query.Text, "AccumulationRegisterName", "AccumulationRegister." + AccumulationRegisterName);
	
	While SelectionOfDocuments.Next() Do
		
		Recorder = SelectionOfDocuments.Ref;
		
		If ProcessedDocuments.Get(Recorder) <> Undefined Then
			Continue; // one document has movements across several organizations, you do not need to re-send it
		EndIf;
		
		SetAdditionalRegisterProperties(
			RecordSet,
			DocumentEmulation(
				Recorder,
				ParametersOfTheEvent.CalculationPeriod));
	
		AddlParameters = AdditionalParametersDocumentDataForPosting();
		
		If ParametersOfTheEvent.RegisterRecordedOnlyInCurrentPeriod Then
			
			AddlParameters.AdditionalProperties = New Structure;
			AddlParameters.AdditionalProperties.Insert(
				"PeriodOfRewritingRegisteredRecords",
				ParametersOfTheEvent.CalculationPeriod);
			
		EndIf;
		
		BeginTransaction();
		
		Try
			
			If DocumentsPostingLocalization.RecheckDocumentsOnAccumulationRegister(Recorder) Then
				// The implementation was carried out in the localization module.
			Else
				
				Block = New DataLock;
				LockItem = Block.Add("AccumulationRegister." + AccumulationRegisterName + ".RecordSet");
				LockItem.SetValue("Recorder", Recorder);
				Block.Lock();
				
				PeriodEndClosingDatesTM.DisableVerificationOfDateWhenChangesWereBanned(RecordSet);
				
				RecordSet.Filter.Recorder.Set(Recorder);
				RecordSet.Clear();
				
				If RegistersWithClearing.Property(AccumulationRegisterName) Then
					
					RecordSet.Write = True;
					RecordSet.Write(True);
					
				EndIf;
				
				TablesForRegisteredRecords = DocumentDataForPosting(Recorder, AccumulationRegisterName, AddlParameters);
				
				// If the document does not have the necessary table of movements, it means that the document no longer generates movements
				// according to the specified register. Previously formed movements will be cleared.
				CurrentTable = Undefined; //ValueTable
				TablesForRegisteredRecords.Property("Table" + AccumulationRegisterName, CurrentTable);
				
				If ValueIsFilled(CurrentTable) Then
					
					If CurrentTable.Columns.Find("Period") <> Undefined Then // Registered Recorded as a sample
						
						// We will add to the set the primary Registered Records of the document in the Cur and subsequent periods.
						For Each MovementTableRow In TablesForRegisteredRecords["Table" + AccumulationRegisterName] Do
							
							If BegOfMonth(MovementTableRow.Period) >= ParametersOfTheEvent.CalculationPeriod Then
								FillPropertyValues(RecordSet.Add(), MovementTableRow);
							EndIf;
							
						EndDo;
						
					Else
						
						// Movements in the time table - we will recheck the entire document.
						NewRow = ParametersOfTheEvent.DocumentsForFullImplementation.Add();
						NewRow.Ref 		= Recorder;
						NewRow.Organization = SelectionOfDocuments.Organization;
						NewRow.ErrorCode 	= SelectionOfDocuments.ErrorCode;
						
					EndIf;
					
				EndIf;
				
				// We will add all the RegisteredRecords of the document in previous periods from the information security.
				Query.SetParameter("Recorder", Recorder);
				MotionSampling = Query.Execute().Select();
				
				While MotionSampling.Next() Do
					FillPropertyValues(RecordSet.Add(), MotionSampling);
				EndDo;
				
				RecordSet.Write = True;
				RecordSet.Write(True);
				RecordSet.Clear();
				
			EndIf;
			
			ProcessedDocuments.Insert(Recorder, SelectionOfDocuments.Organization);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý chứng từ ""%1"" (%2)do nguyên nhân:
					|		%3';
					|ru = 'Не удалось обработать документ ""%1"" (%2)по причине:
					|		%3';
					|en = 'Cannot process the document ""%1"" (%2). Reason:
					|		%3'; fa = 'Cannot process the document ""%1"" (%2). Reason:
					|		%3';
					|it = 'Non è stato possibile elaborare il documento ""%1"" (%2)a causa di:
					|		%3';
					|pl = 'Nie udało się przetworzyć dokumentu ""%1"" (%2) z powodu:
					|		%3';
					|tr = '
					|		%3 nedeniyle ""%1"" (%2) belgesi işlenemedi'", Common.DefaultLanguageCode()),
				Recorder,
				GetURL(Recorder),
				DetailErrorDescription(ErrorInfo()));
				
			ConductErrors.Add(MessageText);
			
			If ParametersOfTheEvent.LogErrors Then
				
				WriteLogEvent(
					ParametersOfTheEvent.EventLogEventName, 
					EventLogLevel.Error,
					Recorder.Metadata(),
					Recorder,
					MessageText);
				
			EndIf;
			
			If ValueIsFilled(ParametersOfTheEvent.MonthEndClosingOperations) Then
				
				RegisterIssueInClosingMonth(
					ParametersOfTheEvent,
					SelectionOfDocuments.Organization,
					NStr("vi = 'Không thể khắc phục sự cố trong bản ghi kết chuyển của chứng từ';
						|ru = 'Не удалось исправить проблемы в движениях документов';
						|en = 'Cannot fix the issues in the document records'; fa = 'Cannot fix the issues in the document records';
						|it = 'Non è stato possibile correggere i problemi nei movimenti dei documenti';
						|pl = 'Nie udało się poprawić problemy w ruchach dokumentów';
						|tr = 'Belge kayıtlarında sorunlar düzeltilemedi'", Common.DefaultLanguageCode()),
					MessageText,
					Recorder);
				
			EndIf;
			
			RecordSet.Clear();
			
		EndTry;
			
	EndDo;
	
	Return ConductErrors;
	
EndFunction

// Resubmits the documents in full.
//
// Parameters:
//	ParametersOfTheEvent - See InitializeMotionRecoveryParameters
//	SelectionOfDocuments - QueryResultSelection - the query selection must contain the Link field
//
// Returns:
//	Array -
//
Function RecheckDocumentsInFull(ParametersOfTheEvent, SelectionOfDocuments) Export
	
	ConductErrors = New Array;
	
	If SelectionOfDocuments.Count() = 0 Then
		Return ConductErrors;
	EndIf;
	
	ProcessedDocuments = New Map;
	RegistersWithClearing = RegistersForPreClearingWhenReconnecting();
	
	While SelectionOfDocuments.Next() Do
		
		Recorder = SelectionOfDocuments.Ref;
		
		If ProcessedDocuments.Get(Recorder) <> Undefined Then
			Continue; // one document has movements across several organizations, you do not need to re-send it
		EndIf;
		
		BeginTransaction();
		
		Try
			
			MetaRegisteredRecords = Recorder.Metadata().RegisterRecords;
			
			For Each KeyAndValue In RegistersWithClearing Do
				
				If MetaRegisteredRecords.Contains(Metadata.AccumulationRegisters[KeyAndValue.Key]) Then
					
					RecordSet = AccumulationRegisters[KeyAndValue.Key].CreateRecordSet();
					RecordSet.AdditionalProperties.Insert("DoNotSaveCalculatedRegisteredRecords", True);

					RecordSet.Filter.Recorder.Set(Recorder);
								
					RecordSet.Write = True;
					RecordSet.Write(True);
					
				EndIf;
				
			EndDo;
				
			DocumentForConducting = Recorder.GetObject();
			
			If ParametersOfTheEvent.CalledFromCostCalculation Then
				
				CostCalculationAppliedAlgorithms.SetAttributeForPerformingCalculationOfBatchesAndCost(DocumentForConducting);
				DocumentForConducting.AdditionalProperties.Insert(InventoriesServer.NameOfAdditionalPropertyForRefillingInventoryViews(), True);
				
				If ParametersOfTheEvent.RegisterRecordedOnlyInCurrentPeriod Then
					
					DocumentForConducting.AdditionalProperties.Insert(
						"PeriodOfRewritingRegisteredRecords",
						ParametersOfTheEvent.CalculationPeriod);
					
				EndIf;
				
			EndIf;
			
			ArrayOfMessagesBeforeEvent = GetUserMessages(False);
			
			DocumentForConducting.Write(DocumentWriteMode.Posting);
			
			ProcessedDocuments.Insert(Recorder, SelectionOfDocuments.Organization);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể xử lý chứng từ ""%1"" (%2)do nguyên nhân:
					|		%3';
					|ru = 'Не удалось обработать документ ""%1"" (%2)по причине:
					|		%3';
					|en = 'Cannot process the document ""%1"" (%2). Reason:
					|		%3'; fa = 'Cannot process the document ""%1"" (%2). Reason:
					|		%3';
					|it = 'Non è stato possibile elaborare il documento ""%1"" (%2)a causa di:
					|		%3';
					|pl = 'Nie udało się przetworzyć dokumentu ""%1"" (%2) z powodu:
					|		%3';
					|tr = '
					|		%3 nedeniyle ""%1"" (%2) belgesi işlenemedi'", Common.DefaultLanguageCode()),
				Recorder,
				GetURL(Recorder),
				DetailErrorDescription(ErrorInfo()));
				
			ArrayOfMessagesAfterEvent = GetUserMessages(False);
			
			For MessageNo = ArrayOfMessagesBeforeEvent.Count() + 1 To ArrayOfMessagesAfterEvent.Count() Do
				// If problems were diagnosed during the procedure, because of which the document was not carried out,
				// then we will add the text of messages about these problems to the protocol.
				MessageText = MessageText + Chars.LF + TrimAll(ArrayOfMessagesAfterEvent[MessageNo-1].Text);
			EndDo;
			
			ConductErrors.Add(MessageText);
			
			If ParametersOfTheEvent.LogErrors Then
				
				WriteLogEvent(
					ParametersOfTheEvent.EventLogEventName, 
					EventLogLevel.Error,
					Recorder.Metadata(),
					Recorder,
					MessageText);
				
			EndIf;
			
			If ValueIsFilled(ParametersOfTheEvent.MonthEndClosingOperations) Then
				
				RegisterIssueInClosingMonth(
					ParametersOfTheEvent,
					SelectionOfDocuments.Organization,
					NStr("vi = 'Không thể sửa lỗi trong các bản ghi kết chuyển chứng từ';
						|ru = 'Не удалось исправить проблемы в движениях документов';
						|en = 'Cannot fix the issues in the document records'; fa = 'Cannot fix the issues in the document records';
						|it = 'Non è stato possibile correggere i problemi nei movimenti dei documenti';
						|pl = 'Nie udało się poprawić problemy w ruchach dokumentów';
						|tr = 'Belge kayıtlarında sorunlar düzeltilemedi'", Common.DefaultLanguageCode()),
					MessageText,
					Recorder);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Return ConductErrors;
	
EndFunction

Procedure RegisterIssueInClosingMonth(ParametersOfTheEvent, Organization, IssueText, ClarificationText, Object)
	
	RegistrationParameters = MonthEndTransactionsServer.InitializeParametersForRegisteringCalculationProblem(
		ParametersOfTheEvent.MonthEndClosingOperations,
		Organization,
		ParametersOfTheEvent.CalculationPeriod);
	
	If Not ValueIsFilled(IssueText) Then
		IssueText = NStr("vi = 'Trong quá trình tính toán, các lỗi đã được chẩn đoán';
						|ru = 'При выполнении расчета были диагностированы ошибки';
						|en = 'Errors were found when calculating'; fa = 'Errors were found when calculating';
						|it = 'Durante l''esecuzione del conto sono stati diagnosticati degli errori';
						|pl = 'Podczas wykonywania obliczeń zostały zdiagnozowane błędy';
						|tr = 'Mutabakat gerçekleştirilmesi sırasında hatalar teşhis edildi'", Common.DefaultLanguageCode());
	EndIf;
	
	FullTextOfProblem = IssueText + " " + NStr("vi = 'theo doanh nghiệp ""%1"" trong kỳ ""%2""';
												|ru = 'по организации ""%1"" за период ""%2""';
												|en = 'of the ""%1"" company for the ""%2"" period'; fa = 'of the ""%1"" company for the ""%2"" period';
												|it = 'nell''organizzazione ""%1"" per il periodo ""%2""';
												|pl = 'wg firmy ""%1"" za okres ""%2""';
												|tr = '""%2"" dönem içerisinde ""%1"" iş yeri'", Common.DefaultLanguageCode());
	
	MonthEndTransactionsServer.RegisterCalculationExecutionProblem(
		RegistrationParameters,
		FullTextOfProblem,
		ParametersOfTheEvent.Importance,
		ClarificationText,
		Object);
	
EndProcedure


// Returns types of service documents without holding.
//
// Returns:
//	Array of Type - 
//
Function TypesOfServiceDocumentsWithoutRechecking() Export
	
	TypesOfServiceDocuments = New Array;
	
	TypesOfServiceDocuments.Add(Type("DocumentRef.RegisterAdjustment"));
	TypesOfServiceDocuments.Add(Type("DocumentRef.InventoryCostCalculation"));
	TypesOfServiceDocuments.Add(Type("DocumentRef.ARAPAccountingRecorder"));
	
	Return TypesOfServiceDocuments;
	
EndFunction

// Returns register names for pre-cleaning before running the document.
// Clearing is necessary in the case when it is necessary to restore the movement of the "related" registers, while the data of the "main" register is not changed.
// For example, to restore the movements of the register calculation of the clients and the delays according to the data of the register calculation of the clients.
//
// Returns:
//	Structure - register names
//
Function RegistersForPreClearingWhenReconnecting()
	
	Result = New Structure;
	Result.Insert(Metadata.AccumulationRegisters.CustomersARAPAccounting.Name);
	Result.Insert(Metadata.AccumulationRegisters.VendorsARAPAccounting.Name);
	
	Return Result;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "DocumentsPosting.ProcessDataForMigrationToNewVersion";
	Handler.Version = "*";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("f82bd3b9-6546-42a6-a1e7-2b09d915a495");
	Handler.Multithreaded = False;
	Handler.UpdateDataFillingProcedure = "DocumentsPosting.RegisterDataToProcessForMigrationToNewVersion";
	Handler.Comment = NStr("vi = 'Xóa cache truy vấn kết chuyển chứng từ.';
							|ru = 'Очищает кэш запросов проведения документов.';
							|en = 'Clears the cache of document posting queries.'; fa = 'Clears the cache of document posting queries.';
							|it = 'Clears the cache of document posting queries.';
							|pl = 'Clears the cache of document posting queries.';
							|tr = 'Belge kaydı sorgularının önbelleğini temizler.'");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.QueryTextCache.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Registers data for processing when switching to a new version.
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Return; // registration is not required.
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	RecordSet = InformationRegisters.QueryTextCache.CreateRecordSet();
	RecordSet.Write();
	Parameters.ProcessingCompleted = True;
	
EndProcedure

#EndRegion

#EndRegion
