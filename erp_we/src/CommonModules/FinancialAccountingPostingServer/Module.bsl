////////////////////////////////////////////////////////////////////////////////
//  Procedures and functions used in the reflection of documents
//  in international accounting.
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		If Not GetFunctionalOption("UseFinancialAccounting")
			Or Document.AdditionalProperties.Property("DoNotRegisterForReflectionInInternationalAccounting")
				And Document.AdditionalProperties.DoNotRegisterForReflectionInInternationalAccounting Then
			Return Parameters;
		EndIf;
		
		TypesOfDocumentsWithDirectFormationOfTransactions = FinancialAccountingUponDocumentData.TypesOfDocumentsToReflect();
		If TypesOfDocumentsWithDirectFormationOfTransactions[TypeOf(Document.Ref)] <> Undefined Then
			Parameters.SubordinateRegisters.Add(Metadata.AccountingRegisters.International);
			Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.DocumentPostingInFinancialAccounting);
		EndIf;
		
		Parameters.ThereAreDerivedMotions = True;
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	DocumentRegisterRecords = MetadataOfDocument.RegisterRecords;

	QueriesTexts = New Map();
	
	RegisterMetadata = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueryText =
		"SELECT DISTINCT
		|	DocumentsStorno.Ref  AS Recorder,
		|	DocumentsStorno.Date AS Period,
		|	DocumentPostingInFinancialAccounting.ChartOfAccounts AS ChartOfAccounts,
		|	DocumentPostingInFinancialAccounting.Organization AS Organization,
		|	BEGINOFPERIOD(DocumentsStorno.Date, DAY) AS DateRecord,
		|	UNDEFINED AS BusinessOperation
		|FROM
		|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
		|	INNER JOIN
		|		&DocumentName AS DocumentsStorno
		|	ON
		|		DocumentPostingInFinancialAccounting.Recorder = DocumentsStorno.ReversedDocument
		|		AND DocumentsStorno.Ref IN (&Ref)
		|";
		QueryText = StrReplace(QueryText, "&DocumentName", MetadataOfDocument.FullName());
		
		QueriesTexts.Insert(RegisterMetadata.FullName(), QueryText);
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of the international registration.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Or Not GetFunctionalOption("UseFinancialAccounting") Then
		Return;
	EndIf;
	
	TableNameInternational = "Table" + "International";
	
	If TablesForRegisteredRecords.Property(TableNameInternational) Then // no delayed movements
		
		If ValueIsFilled(TablesForRegisteredRecords[TableNameInternational]) Then
			
			RegisterRecords.International.Write = True;
			RegisterRecords.International.Load(TablesForRegisteredRecords[TableNameInternational]);
			
		EndIf;
		
	Else // let's go through the data tables for subsequent reflection after recording the movements of the document
		
		If GetFunctionalOption("GenerateFinancialAccountingEntriesByLocalAccountingData") Then
			
			TableName = "Table" + "ReflectionOfDocumentsInLocalAccounting";
			
			If TablesForRegisteredRecords.Property(TableName) Then
				RegisterRecords.DocumentPostingInFinancialAccounting.AdditionalProperties.Insert(
					TableName,
					TablesForRegisteredRecords[TableName]);
			EndIf;
			
			If TablesForRegisteredRecords.Property("TableOfSelectiveRegistrationForReflection") Then
				RegisterRecords.DocumentPostingInFinancialAccounting.AdditionalProperties.Insert(
					"TableOfSelectiveRegistrationForReflectionInternationalAccounting",
					TablesForRegisteredRecords.TableOfSelectiveRegistrationForReflection);
			EndIf;
		EndIf;
		
		TableName = "Table" + "DocumentPostingInFinancialAccounting";
		
		If GetFunctionalOption("ConfigurePostingsForBusinessTransactions")
			And TablesForRegisteredRecords.Property(TableName) Then
				RegisterRecords.DocumentPostingInFinancialAccounting.AdditionalProperties.Insert(
					TableName,
					TablesForRegisteredRecords[TableName]);
		EndIf;
		
		If TablesForRegisteredRecords.Property("TableOfSelectiveRegistrationForReflectionInternationalAccounting") Then
			RegisterRecords.DocumentPostingInFinancialAccounting.AdditionalProperties.Insert(
				"TableOfSelectiveRegistrationForReflectionInternationalAccounting",
				TablesForRegisteredRecords.TableOfSelectiveRegistrationForReflectionInternationalAccounting);
		EndIf;
		
	EndIf;
	
EndProcedure

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - a temporary table Manager
//                                                      that is used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return; // empty handler
	
EndProcedure

// Occurs after execution of the write registers of the instrument.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - a temporary table Manager
//                                                      that is used for storing register change control tables.
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	AbilityToReflect(Document, Document.AdditionalProperties, Document.RegisterRecords, Cancel);
	
EndProcedure

#EndRegion

#Region RegistrationOfDocumentsForReflectionInInternationalAccounting

// Returns the documents to the reflection in international accounting for defined periods of reflection
//
// Parameters:
// 	DocumentsToBeReflected -   ValueTable, 
// 							Time table Manager - a table of documents to be returned to reflection, 
// 													  or a temporary table Manager that has a document table to Reflect
// 													  The table should have the columns Document, Organization, and Datareferences. 
//
Procedure ReturnDocumentsToReflection(DocumentsToBeReflected) Export
	
	If Not GetFunctionalOption("UseFinancialAccounting") Then
		Return;
	EndIf;
	
	KeyOperation = "FinancialAccounting.ReturningDocumentsToReflection";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	DocumentsCount = 0;
	
	TempTablesManager = InitializeManagerToReturnToReflection(DocumentsToBeReflected);
	
	If TempTablesManager <> Undefined Then
		Filter = New Structure("Recorder", Undefined);
		While True Do
			
			DataToBeReflected = DataToReturnToAccounting(TempTablesManager, Filter);
			
			SelectionByDocuments = DataToBeReflected.Recorders;
			If SelectionByDocuments.Count() = 0 Then
				Break;
			EndIf;
			
			RegisterData = DataToBeReflected.RegisterData;
			While SelectionByDocuments.Next() Do
				Filter.Recorder = SelectionByDocuments.Recorder;
				RecordSet = InformationRegisters.DocumentPostingInFinancialAccounting.CreateRecordSet(); // InformationRegisterRecordSet - 
				RecordSet.Filter.Recorder.Set(SelectionByDocuments.Recorder);
				FoundRows = RegisterData.Copy(Filter);
				If FoundRows <> Undefined Then
					For Each NewData In FoundRows Do
						NewRecord = RecordSet.Add();
						FillPropertyValues(NewRecord, NewData);
					EndDo;
				EndIf;
				RecordSet.Write();
			EndDo;
			DocumentsCount = DocumentsCount + SelectionByDocuments.Count();
		EndDo;
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DocumentsCount);
	
EndProcedure

// The constructor function of the selective registration table for reflection.
//
// Returns:
//  ValueTable - table with columns:
//     * Organization - CatalogRef.Companies - Organization
//     * DateRecord - Date - date of reflection.
//
Function TableOfSelectiveRegistrationForReflection() Export
	
	Table = New ValueTable;
	Table.Columns.Add("Organization",     New TypeDescription("CatalogRef.Companies"));
	Table.Columns.Add("DateRecord",   New TypeDescription("Date"));
	
	Return Table;
	
EndFunction

// Generates movements in the register of document reectioninternational Accounting, clears irrelevant entries in international accounting.
// For documents reflected in international accounting according to the data of turnover registers and regl. accounting's.
//
// Parameters:
//  Object - DocumentObject, Structure - document to be registered for reflection.
//  AdditionalProperties - Structure - additional document properties initialized during document execution.
//  RegisterRecords - RegisterRecordsCollection - sets of register entries that are recorded by the document.
//                                 At the time the method is called, all sets must be written.
//  Cancel - Boolean - a sign of refusal to conduct.
//
Procedure AbilityToReflect(Object, AdditionalProperties, RegisterRecords, Cancel = False) Export
	
	If Cancel Or Not GetFunctionalOption("UseFinancialAccounting") Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("DoNotRegisterForReflectionInInternationalAccounting") 
		 And AdditionalProperties.DoNotRegisterForReflectionInInternationalAccounting Then
		Return;
	EndIf;
	
	If TypeOf(RegisterRecords) = Type("Structure") Then
		
		If Not Object.Property("Date") Then
			DocumentDate = Common.ObjectAttributeValue(Object.Ref, "Date");
			Object.Insert("Date", DocumentDate);
		EndIf;
		
		If Not RegisterRecords.Property("International") Then
			International = AccountingRegisters.International.CreateRecordSet();
			International.Filter.Recorder.Set(Object.Ref);
			RegisterRecords.Insert("International", International);
		EndIf;
		
		If Not RegisterRecords.Property("DocumentPostingInFinancialAccounting") Then
			DocumentPostingInFinancialAccounting = InformationRegisters.DocumentPostingInFinancialAccounting.CreateRecordSet();
			DocumentPostingInFinancialAccounting.Filter.Recorder.Set(Object.Ref);
			RegisterRecords.Insert("DocumentPostingInFinancialAccounting", DocumentPostingInFinancialAccounting);
		EndIf;
		
	EndIf;
	
	RegisteredRecordsInternational = RegisterRecords.International;
	RegisteredRecordsInternational.AdditionalProperties.Insert("DoNotPerformAdditionalTransactionProcessing", True);
	
	ReflectionOfDocumentsInInternationalAccounting = RegisterRecords.DocumentPostingInFinancialAccounting;
	
	RegistrationTable = New ValueTable;
	RegistrationTable.Columns.Add("Period",        New TypeDescription("Date"));
	RegistrationTable.Columns.Add("Organization",   New TypeDescription("CatalogRef.Companies"));
	RegistrationTable.Columns.Add("DateRecord", New TypeDescription("Date",,, New DateQualifiers(DateFractions.Date)));
	RegistrationTable.Columns.Add("BusinessOperation", New TypeDescription("EnumRef.BusinessTransactions"));
	
	SelectiveRegistration = False;
	SampleRegistrationTable = TableOfSelectiveRegistrationForReflection();
	If ReflectionOfDocumentsInInternationalAccounting.AdditionalProperties.Property("TableOfSelectiveRegistrationForReflectionInternationalAccounting") Then
		SelectiveRegistration = True;
		CommonClientServer.SupplementTable(
			ReflectionOfDocumentsInInternationalAccounting.AdditionalProperties.TableOfSelectiveRegistrationForReflectionInternationalAccounting,
			SampleRegistrationTable);
	EndIf;
	
	FinancialAccountingUponOperationalAccountingData.AddRegistrationTablesToReflection(
		Object, ReflectionOfDocumentsInInternationalAccounting.AdditionalProperties, RegistrationTable);
	FinancialAccountingByFinancialRegisterData.AddRegistrationTablesToReflection(
		Object, ReflectionOfDocumentsInInternationalAccounting.AdditionalProperties, RegistrationTable);
	FinancialAccountingUponLocalAccounting.AddRegistrationTablesToReflection(
		Object, AdditionalProperties, ReflectionOfDocumentsInInternationalAccounting.AdditionalProperties, RegistrationTable);
	FinancialAccountingUponDocumentData.AddRegistrationTablesToReflection(
		Object, ReflectionOfDocumentsInInternationalAccounting.AdditionalProperties, RegistrationTable);
	
	RegistrationTable.FillValues(Object.Date, "Period");
	RegistrationTable.GroupBy("Period, Organization, DateRecord, BusinessOperation");
	
	AddTransactionGenerationAndStatusSettings(RegistrationTable, Object.Ref);
	
	If Not SelectiveRegistration Then
		If RegistrationTable.Count() > 0 Then
			RegistrationTable.Sort("Period, DateRecord");
			ReflectionOfDocumentsInInternationalAccounting.Load(RegistrationTable);
			ReflectionOfDocumentsInInternationalAccounting.Write = True;
		Else
			ReflectionOfDocumentsInInternationalAccounting.Read();
			If ReflectionOfDocumentsInInternationalAccounting.Count() > 0 Then
				ReflectionOfDocumentsInInternationalAccounting.Clear();
				ReflectionOfDocumentsInInternationalAccounting.Write = True;
			EndIf;
		EndIf;
		Return;
	EndIf;
	
	#Region TextOfRequestForNewRegistrationStatuses
	RequestTextForNewStatuses =
	"SELECT DISTINCT
	|	DataTable.Period          AS Period,
	|	DataTable.ChartOfAccounts      AS ChartOfAccounts,
	|	DataTable.Organization     AS Organization,
	|	DataTable.DateRecord   AS DateRecord,
	|	DataTable.PostingGenerationSetting AS PostingGenerationSetting
	|INTO IsNewRegistration
	|FROM
	|	&TableData_ AS DataTable
	|
	|INDEX BY
	|	ChartOfAccounts,
	|	Organization,
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SampleRegistrationTable.Organization   AS Organization,
	|	SampleRegistrationTable.DateRecord AS DateRecord
	|INTO SelectiveRegistration
	|FROM
	|	&SampleRegistrationTable AS SampleRegistrationTable
	|
	|INDEX BY
	|	Organization,
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentReflection.Period          AS Period,
	|	DocumentReflection.ChartOfAccounts      AS ChartOfAccounts,
	|	DocumentReflection.Organization     AS Organization,
	|	CASE WHEN DocumentReflection.DateRecord = DATETIME(1,1,1)
	|		THEN BEGINOFPERIOD(DocumentReflection.Period, DAY)
	|		ELSE DocumentReflection.DateRecord
	|	END AS DateRecord,
	|	DocumentReflection.Status          AS Status,
	|	DocumentReflection.PostingGenerationSetting AS PostingGenerationSetting,
	|	DocumentReflection.Comment     AS Comment
	|INTO CurrentRegistration
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|WHERE
	|	DocumentReflection.Recorder = &Ref
	|	AND DocumentReflection.PostingGenerationSetting <> VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef)
	|
	|INDEX BY
	|	ChartOfAccounts,
	|	Organization,
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	IsNewRegistration.Period AS Period,
	|	IsNewRegistration.ChartOfAccounts AS ChartOfAccounts,
	|	IsNewRegistration.Organization AS Organization,
	|	IsNewRegistration.DateRecord AS DateRecord,
	|	CASE
	|		WHEN SelectiveRegistration.DateRecord IS NULL AND NOT CurrentRegistration.Status IS NULL
	|			THEN CurrentRegistration.Status
	|		WHEN ISNULL(CurrentRegistration.Status, UNDEFINED) IN (&ManuallyPostedToAccounting, &ForManualPostingInAccounting)
	|			THEN &ForManualPostingInAccounting
	|		ELSE
	|			&ForPostingInAccounting
	|	END AS Status,
	|	CASE
	|		WHEN SelectiveRegistration.DateRecord IS NULL
	|			THEN CurrentRegistration.Comment
	|		WHEN ISNULL(CurrentRegistration.Status, UNDEFINED) IN (&ManuallyPostedToAccounting, &ForManualPostingInAccounting)
	|			THEN CurrentRegistration.Comment
	|		ELSE """"
	|	END AS Comment,
	|	IsNewRegistration.PostingGenerationSetting AS PostingGenerationSetting
	|INTO NewStatuses
	|FROM
	|	IsNewRegistration AS IsNewRegistration
	|	LEFT JOIN 
	|		CurrentRegistration AS CurrentRegistration
	|	ON 
	|		IsNewRegistration.ChartOfAccounts = CurrentRegistration.ChartOfAccounts
	|		AND IsNewRegistration.Organization = CurrentRegistration.Organization
	|		AND IsNewRegistration.DateRecord = CurrentRegistration.DateRecord
	|	
	|	LEFT JOIN 
	|		SelectiveRegistration AS SelectiveRegistration
	|	ON 
	|		IsNewRegistration.Organization = SelectiveRegistration.Organization	
	|		AND IsNewRegistration.DateRecord = SelectiveRegistration.DateRecord
	|
	|INDEX BY
	|	ChartOfAccounts,
	|	Organization,
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ChartOfAccounts AS ChartOfAccounts,
	|	Table.Organization AS Organization,
	|	Table.DateRecord AS DateRecord
	|INTO StatusChanges
	|FROM
	|	(SELECT
	|		Table.ChartOfAccounts AS ChartOfAccounts,
	|		Table.DateRecord AS DateRecord,
	|		Table.Organization AS Organization,
	|		CASE
	|			WHEN Table.Status = &ForPostingInAccounting
	|				THEN 1
	|			WHEN Table.Status = &PostedToAccounting
	|				THEN 2
	|		END AS Status
	|	FROM
	|		NewStatuses AS Table
	|	WHERE
	|		Table.Status IN (&ForPostingInAccounting, &PostedToAccounting)
	|		
	|	UNION ALL
	|	
	|	SELECT
	|		Table.ChartOfAccounts AS ChartOfAccounts,
	|		Table.DateRecord,
	|		Table.Organization,
	|		CASE
	|			WHEN Table.Status = &ForPostingInAccounting
	|				THEN -1
	|			WHEN Table.Status = &PostedToAccounting
	|				THEN -2
	|		END
	|	FROM
	|		CurrentRegistration AS Table
	|
	|	WHERE
	|		Table.Status IN (&ForPostingInAccounting, &PostedToAccounting)) AS Table
	|
	|GROUP BY
	|	Table.ChartOfAccounts,
	|	Table.DateRecord,
	|	Table.Organization
	|
	|HAVING
	|	SUM(Table.Status) <> 0
	|
	|INDEX BY
	|	ChartOfAccounts,
	|	Organization,
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewStatuses.Period          AS Period,
	|	NewStatuses.ChartOfAccounts      AS ChartOfAccounts,
	|	NewStatuses.Organization     AS Organization,
	|	NewStatuses.DateRecord   AS DateRecord,
	|	NewStatuses.Status          AS Status,
	|	NewStatuses.PostingGenerationSetting AS PostingGenerationSetting,
	|	NewStatuses.Comment     AS Comment
	|FROM
	|	NewStatuses AS NewStatuses
	|
	|ORDER BY
	|	Period,
	|	Organization,
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	International.Period                                       AS Period,
	|	International.ChartOfAccounts                                   AS ChartOfAccounts,
	|	International.Organization                                  AS Organization,
	|	
	|	International.DepartmentDr                              AS DepartmentDr,
	|	International.AccountDr                                       AS AccountDr,
	|	ISNULL(International.ExtDimensionTypeDr1, &EmptyViewOfExtdimension) AS ExtDimensionTypeDr1,
	|	ISNULL(International.ExtDimensionDr1, UNDEFINED)          AS ExtDimensionDr1,
	|	ISNULL(International.ExtDimensionTypeDr2, &EmptyViewOfExtdimension) AS ExtDimensionTypeDr2,
	|	ISNULL(International.ExtDimensionDr2, UNDEFINED)          AS ExtDimensionDr2,
	|	ISNULL(International.ExtDimensionTypeDr3, &EmptyViewOfExtdimension) AS ExtDimensionTypeDr3,
	|	ISNULL(International.ExtDimensionDr3, UNDEFINED)          AS ExtDimensionDr3,
	|	International.CurrencyDr                                     AS CurrencyDr,
	|	International.CurrencyAmountDr                              AS CurrencyAmountDr,
	|	International.CountDr                                 AS CountDr,
	|	
	|	International.DepartmentCr                              AS DepartmentCr,
	|	International.AccountCr                                       AS AccountCr,
	|	ISNULL(International.ExtDimensionTypeCr1, &EmptyViewOfExtdimension) AS ExtDimensionTypeCr1,
	|	ISNULL(International.ExtDimensionCr1, UNDEFINED)          AS ExtDimensionCr1,
	|	ISNULL(International.ExtDimensionTypeCr2, &EmptyViewOfExtdimension) AS ExtDimensionTypeCr2,
	|	ISNULL(International.ExtDimensionCr2, UNDEFINED)          AS ExtDimensionCr2,
	|	ISNULL(International.ExtDimensionTypeCr3, &EmptyViewOfExtdimension) AS ExtDimensionTypeCr3,
	|	ISNULL(International.ExtDimensionCr3, UNDEFINED)          AS ExtDimensionCr3,
	|	International.CurrencyCr                                     AS CurrencyCr,
	|	International.CurrencyAmountCr                              AS CurrencyAmountCr,
	|	International.CountCr                                 AS CountCr,
	|	
	|	International.Sum                                        AS Sum,
	|	International.PresentationAmount                           AS PresentationAmount,
	|	
	|	International.Content                                   AS Content,
	|	International.PostingTemplate                               AS PostingTemplate,
	|	International.PostingType                                  AS PostingType
	|FROM
	|	AccountingRegister.International.RecordsWithExtDimensions(,,Recorder = &Ref,,) AS International
	|	LEFT JOIN
	|		StatusChanges AS StatusChanges
	|	ON
	|		International.ChartOfAccounts = StatusChanges.ChartOfAccounts
	|		AND International.Organization = StatusChanges.Organization
	|		AND BEGINOFPERIOD(International.Period, DAY) = StatusChanges.DateRecord
	|WHERE
	|	StatusChanges.Organization IS NULL";
	#EndRegion
	
	Query = New Query(RequestTextForNewStatuses);
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("TableData_",     RegistrationTable);
	Query.SetParameter("Ref",            Object.Ref);
	Query.SetParameter("EmptyViewOfExtdimension", ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef());
	
	Query.SetParameter("PostedToAccounting",      Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting);
	Query.SetParameter("ForPostingInAccounting",    Enums.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting);
	Query.SetParameter("ManuallyPostedToAccounting",   Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting);
	Query.SetParameter("ForManualPostingInAccounting", Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting);
	
	Query.SetParameter("SampleRegistrationTable", SampleRegistrationTable);
	
	Result = Query.ExecuteBatch();
	Count = Result.Count();
	
	International = Result[Count - 1].Unload();
	RegisteredRecordsInternational.Load(International);
	RegisteredRecordsInternational.Write = True;
	
	TableRegistration = Result[Count - 2].Unload();
	ReflectionOfDocumentsInInternationalAccounting.Load(TableRegistration);
	ReflectionOfDocumentsInInternationalAccounting.Write = True;
	
	ClearRegisteredRecords = TableRegistration.Count() = 0;// the document was distributed
	If TypeOf(RegisterRecords) = Type("Structure") Then
		If RegisteredRecordsInternational.Count() > 0 Or ClearRegisteredRecords Then
			RegisteredRecordsInternational.Write();
		EndIf;
		If ReflectionOfDocumentsInInternationalAccounting.Count() > 0 Or ClearRegisteredRecords Then
			ReflectionOfDocumentsInInternationalAccounting.Write();
		EndIf;
	EndIf;
	
EndProcedure

// Registers and documents of payments to be reflected in international accounting.
//
// Parameters:
//	CalculationTable - ValueTable - Table of changes in settlements with partners:
//	                      * Recorder - DocumentRef - Document-motion recorder
//	                      * Period - Date - Period of movements
//	                      * AccountingDimensionByPartners - CatalogRef.DimensionKeysOfAccountingByPartners - Accounting Analytics.
//
Procedure RegisterDocumentsOfSettlementsWithPartnersForReflectionInInternationalAccounting(CalculationTable) Export

	If Not GetFunctionalOption("UseFinancialAccounting") Then
		Return;
	EndIf;

	Query = New Query;
	ArrayOfRequestTexts = New Array;
	If TypeOf(CalculationTable) = Type("ValueTable") Then
		If CalculationTable.Count() = 0 Then
			Return;
		EndIf;
		QueryText = 
		"SELECT DISTINCT
		|	DocumentsToBeReflected.Recorder AS Recorder,
		|	DocumentsToBeReflected.AccountingDimensionByPartners AS AccountingDimensionByPartners,
		|	DocumentsToBeReflected.Period AS Period
		|INTO CalculationsToBeReflectedInAccounting
		|FROM
		|	&DocumentsToBeReflected AS DocumentsToBeReflected
		|WHERE
		|	DocumentsToBeReflected.Recorder <> UNDEFINED
		|
		|INDEX BY
		|	AccountingDimensionByPartners";
		Query.SetParameter("DocumentsToBeReflected", CalculationTable);
		Query.TempTablesManager = New TempTablesManager;
		ArrayOfRequestTexts.Add(QueryText);
	Else
		Query.TempTablesManager = CalculationTable;
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentsTable.Period AS Period,
	|	DocumentsTable.DateRecord AS DateRecord,
	|	DocumentsTable.Recorder AS Document,
	|	DocumentsTable.Organization AS Organization
	|INTO DocumentsToBeReflected
	|FROM
	|	(SELECT DISTINCT
	|		DocumentsTable.Period AS Period,
	|		DocumentsTable.Period AS DateRecord,
	|		DocumentsTable.Recorder AS Recorder,
	|		Dimension.Organization AS Organization
	|	FROM
	|		CalculationsToBeReflectedInAccounting AS DocumentsTable
	|			INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON DocumentsTable.AccountingDimensionByPartners = Dimension.DimensionKey
	|	WHERE
	|		VALUETYPE(DocumentsTable.Recorder) <> TYPE(Document.ARAPAccountingRecorder)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		ARAPAccountingRecorder.Date AS Period,
	|		DocumentsTable.Period AS DateRecord,
	|		DocumentsTable.Recorder AS Recorder,
	|		Dimension.Organization AS Organization
	|	FROM
	|		CalculationsToBeReflectedInAccounting AS DocumentsTable
	|			INNER JOIN Document.ARAPAccountingRecorder AS ARAPAccountingRecorder
	|			ON DocumentsTable.Recorder = ARAPAccountingRecorder.Ref
	|
	|			INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON DocumentsTable.AccountingDimensionByPartners = Dimension.DimensionKey
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		DocumentsTable.Period,
	|		DocumentsTable.Period,
	|		DocumentsTable.Recorder,
	|		Dimension.Counterparty
	|	FROM
	|		CalculationsToBeReflectedInAccounting AS DocumentsTable
	|			INNER JOIN InformationRegister.AccountingDimensionByPartners AS Dimension
	|			ON DocumentsTable.AccountingDimensionByPartners = Dimension.DimensionKey
	|	WHERE
	|		Dimension.Partner = VALUE(Catalog.Partners.OurEnterprise)
	|		AND VALUETYPE(DocumentsTable.Recorder) IN (
	|			TYPE(Document.IntercompanyGoodsReturn),
	|			TYPE(Document.CommissionReportIntercompany),
	|			TYPE(Document.CommissionWriteOffReportIntercompany),
	|			TYPE(Document.CustomerInvoiceIntercompany))
	|
	|	) AS DocumentsTable
	|
	|GROUP BY
	|	DocumentsTable.Period,
	|	DocumentsTable.DateRecord,
	|	DocumentsTable.Recorder,
	|	DocumentsTable.Organization
	|
	|INDEX BY
	|	Period,
	|	Document,
	|	Organization,
	|	DateRecord";
	
	ArrayOfRequestTexts.Add(QueryText);
	Query.Text = StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
	Query.ExecuteBatch();
	
	ReturnDocumentsToReflection(Query.TempTablesManager);
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, "DocumentsToBeReflected");
	
EndProcedure

// Records movements in the register of document reflectationinternational accounting, clears irrelevant records in international Accounting.
// Is called from an offline shared modules VAT.
//
// Parameters:
// 	TempTablesManager - TempTablesManager - temporary table Manager that has tables
// 		Current registration table and selective registration Table.
// 		Tables should have the columns Document, Organization, and Datareferences.
// 	ProcessedItemsCount - Number - Parameter to return the number of documents returned to reflection.
//
Procedure ReturnDocumentsToReflectionSelectivelyInBatches(TempTablesManager, ProcessedItemsCount = Undefined) Export

	If Not GetFunctionalOption("UseFinancialAccounting") Then
	 	Return;
	EndIf;

	GetTransactionGenerationSettingsAndStatus(TempTablesManager);
	
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;

	#Region QueryText
	Query.Text =
	"SELECT DISTINCT
	|	CurRegistrationTable.Document AS Document
	|INTO OnlyDocumentsForReflection
	|FROM
	|	CurRegistrationTable AS CurRegistrationTable
	|;
	| 
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CurRegistrationTable.Period AS Period,
	|	CurRegistrationTable.Document AS Document,
	|	CurRegistrationTable.ChartOfAccounts AS ChartOfAccounts,
	|	CurRegistrationTable.Organization AS Organization,
	|	CurRegistrationTable.DateRecord AS DateRecord,
	|	AuxProperties.PostingGenerationSetting AS PostingGenerationSetting,
	|	AuxProperties.Status AS Status
	|INTO CurRegistrationTableCollapsed
	|FROM
	|	CurRegistrationTable AS CurRegistrationTable
	|	INNER JOIN ConfiguringTransactionGenerationAndStatus AS AuxProperties
	|	ON 
	|		CurRegistrationTable.ChartOfAccounts = AuxProperties.ChartOfAccounts
	|		AND CurRegistrationTable.Organization = AuxProperties.Organization
	|		AND CurRegistrationTable.DateRecord = AuxProperties.DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SampleRegistrationTable.Document AS Document,
	|	SampleRegistrationTable.Organization AS Organization,
	|	SampleRegistrationTable.DateRecord AS DateRecord,
	|	AuxProperties.PostingGenerationSetting AS PostingGenerationSetting,
	|	AuxProperties.Status AS Status
	|INTO SampleRegistrationTableCollapsed
	|FROM
	|	SampleRegistrationTable AS SampleRegistrationTable
	|	INNER JOIN ConfiguringTransactionGenerationAndStatus AS AuxProperties
	|	ON SampleRegistrationTable.Organization = AuxProperties.Organization
	|		AND SampleRegistrationTable.DateRecord = AuxProperties.DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentReflection.Period AS Period,
	|	DocumentReflection.Recorder AS Document,
	|	DocumentReflection.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentReflection.Organization AS Organization,
	|	DocumentReflection.DateRecord AS DateRecord,
	|	DocumentReflection.Status AS Status,
	|	DocumentReflection.PostingGenerationSetting AS PostingGenerationSetting,
	|	DocumentReflection.Comment AS Comment
	|INTO CurStatuses
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|		INNER JOIN OnlyDocumentsForReflection AS OnlyDocumentsForReflection
	|		ON DocumentReflection.Recorder = OnlyDocumentsForReflection.Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SampleRegistrationTable.Document AS Document,
	|	MIN(SampleRegistrationTable.DateRecord) AS DateRecord
	|INTO StartOfSelectiveRegistrationChanges
	|FROM
	|	SampleRegistrationTableCollapsed AS SampleRegistrationTable
	|
	|GROUP BY
	|	SampleRegistrationTable.Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(CurStatuses.Period, CurRegistrationTable.Period) AS Period,
	|	CurRegistrationTable.Document AS Document,
	|	CurRegistrationTable.ChartOfAccounts AS ChartOfAccounts,
	|	CurRegistrationTable.Organization AS Organization,
	|	CurRegistrationTable.DateRecord AS DateRecord,
	|	CASE
	|		WHEN SampleRegistrationTable.DateRecord IS NULL
	|				AND NOT CurStatuses.Status IS NULL
	|			THEN CurStatuses.Status
	|		WHEN ISNULL(CurStatuses.Status, UNDEFINED) IN (&ManuallyPostedToAccounting, &ForManualPostingInAccounting)
	|			THEN &ForManualPostingInAccounting
	|		ELSE &ForPostingInAccounting
	|	END AS Status,
	|	CASE
	|		WHEN SampleRegistrationTable.DateRecord IS NULL
	|			THEN CurStatuses.Comment
	|		WHEN ISNULL(CurStatuses.Status, UNDEFINED) IN (&ManuallyPostedToAccounting, &ForManualPostingInAccounting)
	|			THEN CurStatuses.Comment
	|		ELSE """"
	|	END AS Comment,
	|	CurRegistrationTable.PostingGenerationSetting AS PostingGenerationSetting
	|INTO NewStatuses
	|FROM
	|	CurRegistrationTableCollapsed AS CurRegistrationTable
	|		LEFT JOIN CurStatuses AS CurStatuses
	|		ON CurRegistrationTable.Document = CurStatuses.Document
	|			AND CurRegistrationTable.ChartOfAccounts = CurStatuses.ChartOfAccounts
	|			AND CurRegistrationTable.Organization = CurStatuses.Organization
	|			AND CurRegistrationTable.DateRecord = CurStatuses.DateRecord
	|		LEFT JOIN SampleRegistrationTableCollapsed AS SampleRegistrationTable
	|		ON CurRegistrationTable.Document = SampleRegistrationTable.Document
	|			AND CurRegistrationTable.Organization = SampleRegistrationTable.Organization
	|			AND CurRegistrationTable.DateRecord = SampleRegistrationTable.DateRecord
	|WHERE
	|	SampleRegistrationTable.DateRecord IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Document AS Document,
	|	Table.ChartOfAccounts AS ChartOfAccounts,
	|	Table.Organization AS Organization,
	|	Table.DateRecord AS DateRecord
	|INTO StatusChanges
	|FROM
	|	(SELECT
	|		Table.Document AS Document,
	|		Table.ChartOfAccounts AS ChartOfAccounts,
	|		Table.DateRecord AS DateRecord,
	|		Table.Organization AS Organization,
	|		CASE
	|			WHEN Table.Status = &ForPostingInAccounting
	|				THEN 1
	|			WHEN Table.Status = &PostedToAccounting
	|				THEN 2
	|		END AS Status
	|	FROM
	|		NewStatuses AS Table
	|	WHERE
	|		Table.Status IN (&ForPostingInAccounting, &PostedToAccounting)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Document,
	|		Table.ChartOfAccounts AS ChartOfAccounts,
	|		Table.DateRecord,
	|		Table.Organization,
	|		CASE
	|			WHEN Table.Status = &ForPostingInAccounting
	|				THEN -1
	|			WHEN Table.Status = &PostedToAccounting
	|				THEN -2
	|		END
	|	FROM
	|		CurStatuses AS Table
	|	WHERE
	|		Table.Status IN (&ForPostingInAccounting, &PostedToAccounting)) AS Table
	|		LEFT JOIN StartOfSelectiveRegistrationChanges AS StartOfChanges
	|		ON Table.Document = StartOfChanges.Document
	|WHERE
	|	Table.DateRecord >= ISNULL(BEGINOFPERIOD(StartOfChanges.DateRecord, MONTH), DATETIME(1, 1, 1))
	|
	|GROUP BY
	|	Table.Document,
	|	Table.ChartOfAccounts,
	|	Table.DateRecord,
	|	Table.Organization
	|
	|HAVING
	|	SUM(Table.Status) <> 0
	|
	|INDEX BY
	|	Table.Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewStatuses.Period AS Period,
	|	NewStatuses.Document AS Document,
	|	NewStatuses.ChartOfAccounts AS ChartOfAccounts,
	|	NewStatuses.Organization AS Organization,
	|	NewStatuses.DateRecord AS DateRecord,
	|	NewStatuses.Status AS Status,
	|	NewStatuses.PostingGenerationSetting AS PostingGenerationSetting,
	|	NewStatuses.Comment AS Comment
	|FROM
	|	NewStatuses AS NewStatuses
    |
	|ORDER BY
	|	Period,
	|	Document,
	|	ChartOfAccounts,
	|	Organization,
	|	DateRecord
	|
	|TOTALS BY
	|	Document
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	International.Period AS Period,
	|	International.Recorder AS Recorder,
	|	International.ChartOfAccounts AS ChartOfAccounts,
	|	International.Organization AS Organization,
	|	International.DepartmentDr AS DepartmentDr,
	|	International.LineOfBusinessDr AS LineOfBusinessDr,
	|	International.AccountDr AS AccountDr,
	|	ISNULL(International.ExtDimensionTypeDr1, &EmptyViewOfExtdimension) AS ExtDimensionTypeDr1,
	|	ISNULL(International.ExtDimensionDr1, UNDEFINED) AS ExtDimensionDr1,
	|	ISNULL(International.ExtDimensionTypeDr2, &EmptyViewOfExtdimension) AS ExtDimensionTypeDr2,
	|	ISNULL(International.ExtDimensionDr2, UNDEFINED) AS ExtDimensionDr2,
	|	ISNULL(International.ExtDimensionTypeDr3, &EmptyViewOfExtdimension) AS ExtDimensionTypeDr3,
	|	ISNULL(International.ExtDimensionDr3, UNDEFINED) AS ExtDimensionDr3,
	|	International.CurrencyDr AS CurrencyDr,
	|	International.CurrencyAmountDr AS CurrencyAmountDr,
	|	International.DepartmentCr AS DepartmentCr,
	|	International.LineOfBusinessCr AS LineOfBusinessCr,
	|	International.AccountCr AS AccountCr,
	|	ISNULL(International.ExtDimensionTypeCr1, &EmptyViewOfExtdimension) AS ExtDimensionTypeCr1,
	|	ISNULL(International.ExtDimensionCr1, UNDEFINED) AS ExtDimensionCr1,
	|	ISNULL(International.ExtDimensionTypeCr2, &EmptyViewOfExtdimension) AS ExtDimensionTypeCr2,
	|	ISNULL(International.ExtDimensionCr2, UNDEFINED) AS ExtDimensionCr2,
	|	ISNULL(International.ExtDimensionTypeCr3, &EmptyViewOfExtdimension) AS ExtDimensionTypeCr3,
	|	ISNULL(International.ExtDimensionCr3, UNDEFINED) AS ExtDimensionCr3,
	|	International.CurrencyCr AS CurrencyCr,
	|	International.CurrencyAmountCr AS CurrencyAmountCr,
	|	International.Sum AS Sum,
	|	International.PresentationAmount AS PresentationAmount,
	|	International.Content AS Content
	|FROM
	|	AccountingRegister.International.RecordsWithExtDimensions(
	|			,
	|			,
	|			Recorder IN (SELECT T.Document FROM OnlyDocumentsForReflection AS T),
	|			,
	|		) AS International
	|		LEFT JOIN StatusChanges AS StatusChanges
	|		ON International.Recorder = StatusChanges.Document
	|			AND International.ChartOfAccounts = StatusChanges.ChartOfAccounts
	|			AND International.Organization = StatusChanges.Organization
	|			AND (BEGINOFPERIOD(International.Period, DAY) = StatusChanges.DateRecord)
	|WHERE
	|	StatusChanges.Organization IS NULL";
	#EndRegion

	Query.SetParameter("EmptyViewOfExtdimension",  ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef());

	Query.SetParameter("PostedToAccounting",      Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting);
	Query.SetParameter("ForPostingInAccounting",    Enums.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting);
	Query.SetParameter("ManuallyPostedToAccounting",   Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting);
	Query.SetParameter("ForManualPostingInAccounting", Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting);

	Result = Query.ExecuteBatch();
	Count = Result.Count();

	StatusChanges = Query.TempTablesManager.Tables.Get("StatusChanges").GetData().Unload();
	
	ResultIsInternational = Result[Count - 1]; // QueryResult - 
	International = ResultIsInternational.Unload();
	International.Indexes.Add("Recorder");
	
	ResultFromDocuments = Result[Count - 2]; // QueryResult -
	SelectionByDocuments = ResultFromDocuments.Select(QueryResultIteration.ByGroups);
	TypesOfDocumentsToReflect = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting.StandardAttributes.Recorder.Type;
	While SelectionByDocuments.Next() Do
		RegisteredRecordsInternational = AccountingRegisters.International.CreateRecordSet();
		RegisteredRecordsInternational.Filter.Recorder.Set(SelectionByDocuments.Document);
		RegisteredRecordsInternational.Write = True;

		InternationalByDocument = International.CopyColumns();
		FoundRows = International.FindRows(New Structure("Recorder", SelectionByDocuments.Document));
		For Each FoundRow In FoundRows Do
			NewRow = InternationalByDocument.Add();
			FillPropertyValues(NewRow, FoundRow);
		EndDo;

		RegisteredRecordsInternational.Load(InternationalByDocument);
		RegisteredRecordsInternational.Write();

		HasChanges = Not StatusChanges.Find(SelectionByDocuments.Document, "Document") = Undefined;
		If TypesOfDocumentsToReflect.ContainsType(TypeOf(SelectionByDocuments.Document)) And HasChanges Then
			RecordSet = InformationRegisters.DocumentPostingInFinancialAccounting.CreateRecordSet();
			RecordSet.AdditionalProperties.Insert("CheckingDateWhenChangesWereBanned", False);
			RecordSet.Filter.Recorder.Set(SelectionByDocuments.Document);

			Selection = SelectionByDocuments.Select();
			While Selection.Next() Do
				NewRecord = RecordSet.Add();
				FillPropertyValues(NewRecord, Selection);
			EndDo;

			RecordSet.Write();
			If TypeOf(ProcessedItemsCount) = Type("Number") Then
				ProcessedItemsCount = ProcessedItemsCount + 1;
			EndIf;
		EndIf;
	EndDo;

	ListOfTablesToDestroy = 
		"CurRegistrationTableCollapsed,
		|SampleRegistrationTableCollapsed,
		|OnlyDocumentsForReflection,
		|StartOfSelectiveRegistrationChanges,
		|ConfiguringTransactionGenerationAndStatus,
		|CurStatuses,
		|NewStatuses,
		|StatusChanges";
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, ListOfTablesToDestroy);

EndProcedure

#EndRegion

#Region GeneratePostings

// Returns the parameters of the reflection in international accounting
// 
// Returns:
// 	Structure - Reflection Parameters:
// 		* Documents - DocumentRef, Array of DocumentRef - Selection by specific documents, if Undefined, then everything.
// 		* Companies - CatalogRef.Companies, Array of CatalogRef.Companies - Selection by organization. If Undefined, that's it.
// 		* EndDate - Date - Selection of documents to be reflected by date. By default, all documents.
// 		* ToRecordTransactions - Boolean - Record transactions resulting from reflection.
// 		* PerformRecalculations - Boolean - To perform offline operations prior to the formation transactions.
// 		* CheckREFLECTIONStatus - Boolean - perform reflection for documents with certain Status values in the register of reflection of documents in international accounting.
// 		* AccountPlansWithCorrespondence - Array of CatalogRef.FinancialAccountingChartsOfAccounts - Account plans with correspondence support
// 		* AccountPlansWithoutCorrespondence - Array of CatalogRef.FinancialAccountingChartsOfAccounts - Account plans without correspondence support
// 		* ForecastParameters - See ForecastParametersOfReflectionInInternationalAccounting.
// 		* TransactionsToGoToBackground - Number - The number of generated transactions, starting from which reflection is performed in the background task during interactive startup.
// 		* MinimumServingSize - Number - The number of generated transactions, starting from which the reflection is performed in several streams, if possible.
// 		* ThreadsCount - Number - The number of document reflection sessions running simultaneously.
// 		* AttemptsNumber - Number - The number of attempts to process one portion of documents.
// 		* UsingCurTotals - Boolean - Saves THE State of Cur totals usage in accounting registers before being reflected in multithreaded mode.
// 		* MaximumPeriodOfTotals - Date - Saves the maximum stored period of totals in accounting registers before being reflected in multithreaded mode.
// 		* MinimumPeriodOfTotals - Date - Saves the minimum stored period of totals in accounting registers before being reflected in multithreaded mode.
// 		* RestoreStateOfResults - Boolean - Retains the NEED TO RESTORE THE State of THE totals of accounting registers after reflection in multithreaded mode.
// 
Function ReflectionParametersInInternationalAccounting() Export
	
	Parameters = New Structure;
	Parameters.Insert("Documents", Undefined);
	Parameters.Insert("Companies", Undefined);
	Parameters.Insert("EndDate", '00010101');
	Parameters.Insert("ToRecordTransactions", True);
	Parameters.Insert("PerformRecalculations", True);
	Parameters.Insert("CheckREFLECTIONStatus", True);
	Parameters.Insert("AccountPlansWithCorrespondence", New Array());
	Parameters.Insert("AccountPlansWithoutCorrespondence", New Array());
	Parameters.Insert("ForecastParameters", Undefined);
	Parameters.Insert("TransactionsToGoToBackground", 100);
	Parameters.Insert("MinimumServingSize", 2000);
	Parameters.Insert("ThreadsCount", NumberOfReflectionStreamsInInternationalAccounting());
	Parameters.Insert("AttemptsNumber", 3);
	Parameters.Insert("UsingCurTotals", False);
	Parameters.Insert("MaximumPeriodOfTotals", MaximumPeriodOfCalculatedAccountingTotals());
	Parameters.Insert("MinimumPeriodOfTotals", MinimumPeriodOfCalculatedAccountingResults());
	Parameters.Insert("RestoreStateOfResults", False);
	
	Return Parameters;
	
EndFunction

// Handler called by the routine task of reflecting documentsinternational Accounting.
//
Procedure ReflectInInternationalAccountingByRegulatoryTask() Export

	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.DocumentPostingInFinancialAccounting);
	If Not GetFunctionalOption("UseFinancialAccounting") Then
		Return;
	EndIf;
	
	ReflectionParameters = ReflectionParametersInInternationalAccounting();
	RecordInInternationalAccounting(ReflectionParameters);

EndProcedure

// Begins to reflect documents in international accounting in a long-term operation.
//
// Parameters:
//	ReflectionParametersInInternationalAccounting - See ReflectionParametersInInternationalAccounting
//	FormIdentifier - UUID - ID of the form that started displaying documents in accounting
//
// Returns:
//	See TimeConsumingOperations.ExecuteFunction
//
Function StartReflectionInInternationalAccounting(ReflectionParametersInInternationalAccounting, FormIdentifier) Export
	
	FunctionPerformed = "FinancialAccountingPostingServer.RecordInInternationalAccounting";
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(FormIdentifier);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
														|ru = 'Отражение документов в международном учете';
														|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
														|it = 'Visualizzazione dei documenti in contabilità internazionale';
														|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
														|tr = 'Finansal muhasebede belge kaydı'");
	
	If ReflectionParametersInInternationalAccounting.ForecastParameters = Undefined Then
		FillInForecastParameters(ReflectionParametersInInternationalAccounting);
	EndIf;
	
	NumberOfTransactions_ = ReflectionParametersInInternationalAccounting.ForecastParameters.NumberOfTransactions_;
	
	If NumberOfTransactions_ < ReflectionParametersInInternationalAccounting.TransactionsToGoToBackground Then
		ExecutionParameters.RunNotInBackground1 = True;
	EndIf;
	
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, FunctionPerformed, ReflectionParametersInInternationalAccounting);
	
EndFunction

// Reflects documents in international accounting.
//
// Parameters:
//	ReflectionParametersInInternationalAccounting - See ReflectionParametersInInternationalAccounting
//	IterationNumber - Number - Cur current repeat execution NUMBER
//
// Returns:
//	See TableOfTransactions
//
Function RecordInInternationalAccounting(ReflectionParametersInInternationalAccounting, Val IterationNumber = 0) Export
	
	IterationNumber = IterationNumber + 1;
	
	SetPrivilegedMode(True);
	
	If ReflectionParametersInInternationalAccounting.PerformRecalculations Then
		PerformOfflineCalculations(
			ReflectionParametersInInternationalAccounting.Companies,
			ReflectionParametersInInternationalAccounting.EndDate,
			ReflectionParametersInInternationalAccounting.Documents);
	EndIf;
	
	If IterationNumber = 1 Then
		MeasurementOfLongTermOperation = PerformanceMonitor.StartTimeConsumingOperationMeasurement("FinancialAccounting.RecordInFinancialAccounting");
	EndIf;
	
	If ReflectionParametersInInternationalAccounting.ForecastParameters = Undefined Then
		FillInForecastParameters(ReflectionParametersInInternationalAccounting);
	EndIf;
	
	BatchesCount = ReflectionParametersInInternationalAccounting.ForecastParameters.BatchesCount;
	
	If BatchesCount <= 1 Then
		ThreadsCount = 1;
	Else
		ThreadsCount = ReflectionParametersInInternationalAccounting.ThreadsCount;
	EndIf;
	
	If ThreadsCount > 1 Then
		PortionsOfDifferentTypes = BatchesCount >= ThreadsCount;
		ParametersForGeneratingTransactions = Undefined;
	Else
		PortionsOfDifferentTypes = False;
		ParametersForGeneratingTransactions = ParametersForGeneratingTransactions(ReflectionParametersInInternationalAccounting);
	EndIf;
	
	If IterationNumber = 1
	   And ItIsRecommendedToTurnOffRegisterTotals(ReflectionParametersInInternationalAccounting) Then
		TurnOffResultsOfInternationalRegisters(ReflectionParametersInInternationalAccounting);
	EndIf;
	
	TableOfTransactions = TableOfTransactions();
	FlowControlTable = FlowControlTable();
	PortionManagementTable = PortionManagementTable(ReflectionParametersInInternationalAccounting, PortionsOfDifferentTypes);
	
	BatchIndex = 0;
	
	While PortionManagementTable.Count() > 0 Do
		If BatchIndex >= PortionManagementTable.Count() Then
			BatchIndex = 0;
		EndIf;
		
		If PortionManagementTable.Count() < ThreadsCount Then
			PortionsOfDifferentTypes = False;
		EndIf;
		
		PortionParameters = PortionManagementTable[BatchIndex];
		
		If PortionsOfDifferentTypes And FlowControlTable.Find(PortionParameters.PortionNumber, "PortionNumber") <> Undefined Then
			BatchIndex = BatchIndex + 1;
			Continue;
		EndIf;
		
		If ThreadsCount = 1
		 Or PortionParameters.BatchesCount > 1
		 Or ValueIsFilled(ReflectionParametersInInternationalAccounting.Documents) Then
			DocumentsToBeReflectedInAccounting = DocumentsToBeReflectedInAccounting(
				ReflectionParametersInInternationalAccounting,
				ParametersForGeneratingTransactions,
				PortionParameters);
		Else
			SupplementParametersOfSinglePortion(PortionParameters);
		EndIf;
		
		If PortionParameters.LastBatch
		   And PortionParameters.InitialMomentOfTime = PortionParameters.EndPointOfTime Then
			PortionManagementTable.Delete(PortionParameters);
			Continue;
		EndIf;
		
		If ThreadsCount = 1 Then
			PortionOfTransactions = ReflectPortionOfDocumentsWithCurFLOW(
				DocumentsToBeReflectedInAccounting,
				ReflectionParametersInInternationalAccounting,
				ParametersForGeneratingTransactions);
			
			If Not ReflectionParametersInInternationalAccounting.ToRecordTransactions Then
				CommonClientServer.SupplementTable(PortionOfTransactions, TableOfTransactions);
			EndIf;
		Else
			StreamParameters = FlowControlTable.Add();
			FillPropertyValues(StreamParameters, PortionParameters);
			
			If TypeOf(ReflectionParametersInInternationalAccounting.Documents) = Type("Array") Then
				While DocumentsToBeReflectedInAccounting.Next() Do
					StreamParameters.Documents.Add(DocumentsToBeReflectedInAccounting.PointInTime.Ref);
				EndDo;
			EndIf;
			
			ThisIsLastPortion = PortionParameters.LastBatch And PortionManagementTable.Count() = 1;
			
			StartReflectingPortionsOfDocumentsWithNewStream(ReflectionParametersInInternationalAccounting,
				StreamParameters, ThisIsLastPortion);
			
			If ThisIsLastPortion Then
				If Not ReflectionParametersInInternationalAccounting.ToRecordTransactions Then
					PortionOfTransactions = GetFromTempStorage(StreamParameters.ResultAddress);
					CommonClientServer.SupplementTable(PortionOfTransactions, TableOfTransactions);
				EndIf;
				
				FlowControlTable.Delete(StreamParameters);
				WaitForExecutionCompletion = True;
			Else
				WaitForExecutionCompletion = FlowControlTable.Count() >= ThreadsCount;
			EndIf;
			
			If WaitForExecutionCompletion Then
				WaitFORReflectionStreamsTOEnd(ReflectionParametersInInternationalAccounting,
					FlowControlTable, TableOfTransactions, ThisIsLastPortion);
				BatchIndex = 0;
			ElsIf Not PortionParameters.LastBatch Then
				BatchIndex = BatchIndex + 1;
			EndIf;
		EndIf;
		
		If PortionParameters.LastBatch Then
			PortionManagementTable.Delete(PortionParameters);
		EndIf;
		
		If ParametersForGeneratingTransactions <> Undefined Then
			DestroyTemporaryTables(ParametersForGeneratingTransactions.TempTablesManager);
		EndIf;
	EndDo;
	
	If FlowControlTable.Count() > 0 Then
		WaitFORReflectionStreamsTOEnd(ReflectionParametersInInternationalAccounting,
			FlowControlTable, TableOfTransactions, True);
	EndIf;
	
	DocumentsCount = ReflectionParametersInInternationalAccounting.ForecastParameters.DocumentsCount;
	
	If ReflectionParametersInInternationalAccounting.CheckREFLECTIONStatus
	   And IterationNumber < ReflectionParametersInInternationalAccounting.AttemptsNumber Then
		FillInForecastParameters(ReflectionParametersInInternationalAccounting);
		If ReflectionParametersInInternationalAccounting.ForecastParameters.DocumentsCount > 0 Then
			PortionOfTransactions = RecordInInternationalAccounting(ReflectionParametersInInternationalAccounting, IterationNumber);
			If Not ReflectionParametersInInternationalAccounting.ToRecordTransactions Then
				CommonClientServer.SupplementTable(PortionOfTransactions, TableOfTransactions);
			EndIf;
		EndIf;
	EndIf;
	
	If IterationNumber = 1 Then
		If ReflectionParametersInInternationalAccounting.RestoreStateOfResults Then
			IncludeResultsOfInternationalRegisters(ReflectionParametersInInternationalAccounting);
		EndIf;
		
		PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementOfLongTermOperation, DocumentsCount);
	EndIf;
	
	Return TableOfTransactions;
	
EndFunction

// By the transaction table passed as a parameter, returns a table of transactions that meet the record conditions.
//
// Parameters:
//	DocumentTransactions - See TableOfTransactions
//	ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts, Array of CatalogRef.FinancialAccountingChartsOfAccounts - selection according to the chart of accounts
//	SelectAccordingToChartOfAccounts - Boolean - the need to perform the selection according to the chart of accounts
//
// Returns:
//	 See TableOfTransactions
//
Function RecordedTransactions(DocumentTransactions, ChartOfAccounts, Val SelectAccordingToChartOfAccounts = True) Export
	
	If Not SelectAccordingToChartOfAccounts Then
		RecordedTransactions = DocumentTransactions.Copy();
	Else
		If TypeOf(ChartOfAccounts) <> Type("Array") Then
			SelectionAccordingToChartOfAccounts = ChartOfAccounts;
		ElsIf ChartOfAccounts.Count() = 1 Then
			SelectionAccordingToChartOfAccounts = ChartOfAccounts[0];
		Else
			SelectionAccordingToChartOfAccounts = Undefined;
		EndIf;
		
		If ValueIsFilled(SelectionAccordingToChartOfAccounts) Then
			SelectAccordingToChartOfAccounts = False;
			RecordedTransactions = DocumentTransactions.Copy(New Structure("ChartOfAccounts", SelectionAccordingToChartOfAccounts));
		Else
			RecordedTransactions = DocumentTransactions.Copy();
		EndIf;
	EndIf;
	
	ExcludedTransactions_ = New Array;
	
	For Each AccountingEntry In RecordedTransactions Do
		If AccountingEntry.Status <> Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting
			And AccountingEntry.Status <> Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting
			And AccountingEntry.Status <> Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting Then
			ExcludedTransactions_.Add(AccountingEntry);
		ElsIf AccountingEntry.Status = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting
			And Not ValueIsFilled(AccountingEntry.AccountDr) 
			And Not ValueIsFilled(AccountingEntry.AccountCr) Then
			// An entry was added to mark the document processing, if there was no data for reflection on the document.
			ExcludedTransactions_.Add(AccountingEntry);
		ElsIf SelectAccordingToChartOfAccounts And ChartOfAccounts.Find(AccountingEntry.ChartOfAccounts) = Undefined Then
			ExcludedTransactions_.Add(AccountingEntry);
		EndIf;
	EndDo;
	
	For Each AccountingEntry In ExcludedTransactions_ Do
		RecordedTransactions.Delete(AccountingEntry);
	EndDo;
	
	Return RecordedTransactions;

EndFunction

// Checks the equality of the REFLECTION Status identifiers read at the time of the start of the formation of transactions
// and before recording the generated transactions. If the identifiers match, IT UPDATES THE Status
// Of THE document's reflection in INTERNATIONAL accounting and a comment based on THE Statuses Of generated transactions.
//
// Parameters:
//	Document - DocumentRef - link to the document.
//	Dimensions - ValueTable - A table of measurements for which the reflection Status needs to be updated. Table columns:
//			* ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Chart of accounts for status updates
//			* Organization - CatalogRef.Companies - Organization for status updates
//			* DateRecord - Date - Date of reflection, for which the status needs to be updated
//			* StatusID - UUID - The value of the identifier read at the time of the start of the formation of transactions
//	DocumentTransactions - ValueTable - A table of document transactions based on which the Status is updated. Table columns:
//			* Period - Date - Transaction period
//			* ChartOfAccounts - CatalogRef.FinancialAccountingChartsOfAccounts - Chart of accounts for marking the status
//			* Organization - CatalogRef.Companies - Organization for marking the status
//			* Status - EnumRef.StatusesOfPostingsInFinancialAccounting - Reflection status
//			* Comment - String - Comment on THE Reflection Status
//	To return the reflection of the document is a Boolean-Boolean way to return the reversing document to reflection.
//
// Returns:
//	Boolean - true if the identifiers of the reflection Statuses have not changed since the start of the formation of transactions
//		and the new values of the Statuses are recorded in the register of information reflection of documents in international accounting
//
Function UpdateDocumentReflectionStatus(Document, Dimensions, DocumentTransactions) Export
	
	DocumentReflectionRecords = InformationRegisters.DocumentPostingInFinancialAccounting.CreateRecordSet();
	DocumentReflectionRecords.Filter.Recorder.Set(Document);
	DocumentReflectionRecords.Read();
	
	StatusIDSMATCH = DocumentReflectionRecords.Count() >= Dimensions.Count();
	
	For Each Record In DocumentReflectionRecords Do
		Filter = New Structure("ChartOfAccounts, Organization, DateRecord",
			Record.ChartOfAccounts, Record.Organization, Record.DateRecord);
		CurCurrentMEASUREMENTS = Dimensions.FindRows(Filter);
		
		If CurCurrentMEASUREMENTS.Count() = 0 Then
			Continue;
		Else
			For Each CurMeasurement_ In CurCurrentMEASUREMENTS Do
				If CurMeasurement_.StatusID <> Record.StatusID Then
					StatusIDSMATCH = False;
				Else
					Dimensions.Delete(CurMeasurement_);
				EndIf;
			EndDo;
			If Not StatusIDSMATCH Then
				Break;
			EndIf;
		EndIf;
		
		Filter = New Structure("ChartOfAccounts, Organization", Record.ChartOfAccounts, Record.Organization);
		BusinessTransactionsCompany = DocumentTransactions.FindRows(Filter);
		
		If DocumentTransactions.Count() > 0 Then
			Status = Undefined;
			Comment = "";
			UniqueValues = New Map;
			
			For Each AccountingEntry In BusinessTransactionsCompany Do
				If Not ValueIsFilled(AccountingEntry.Period) Or BegOfDay(AccountingEntry.Period) = Record.DateRecord Then
					Status = FinancialAccountingServerCached.DetermineStatus(Status, AccountingEntry.Status);
					FillInComment(Comment, AccountingEntry, UniqueValues);
				EndIf;
			EndDo;
			
			If ValueIsFilled(Status) Then
				Record.Status = Status;
				Record.Comment = Comment;
			Else
				Record.Status = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting;
				Record.Comment = "";
			EndIf;
		Else
			Record.Status = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting;
			Record.Comment = "";
		EndIf;
	EndDo;
	
	StatusIDSMATCH = StatusIDSMATCH And Dimensions.Count() = 0;
	
	If StatusIDSMATCH Then
		DocumentReflectionRecords.Write();
	EndIf;
	
	Return StatusIDSMATCH;
	
EndFunction

// Records the new status of the reflection in the accounting.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef - array of documents.
//  NewReflectionStatus - EnumRef.StatusesOfPostingsInFinancialAccounting - New reflection status.
//  OldReflectionStatuses - Array of EnumRef.StatusesOfPostingsInFinancialAccounting - Old reflection statuses.
Procedure RecordNewReflectionStatus(DocumentsArray, NewReflectionStatus, OldReflectionStatuses) Export
	
	DataLock = New DataLock();
	For Each DocumentRecorder In DocumentsArray Do
		LockItem = DataLock.Add("InformationRegister.DocumentPostingInFinancialAccounting.RecordSet");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Recorder", DocumentRecorder);
	EndDo;
	
	BeginTransaction();
	
	Try
		
		DataLock.Lock();
		
		Query = New Query;
		Query.Text = 
		"SELECT
		|	DocumentPostingInFinancialAccounting.Period,
		|	DocumentPostingInFinancialAccounting.Recorder,
		|	DocumentPostingInFinancialAccounting.ChartOfAccounts,
		|	DocumentPostingInFinancialAccounting.Organization,
		|	DocumentPostingInFinancialAccounting.DateRecord,
		|	CASE
		|		WHEN DocumentPostingInFinancialAccounting.Status IN (&OldReflectionStatuses)
		|			THEN &NewStatus
		|		ELSE DocumentPostingInFinancialAccounting.Status
		|	END AS Status,
		|	DocumentPostingInFinancialAccounting.PostingGenerationSetting,
		|	DocumentPostingInFinancialAccounting.Comment
		|FROM
		|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
		|WHERE
		|	DocumentPostingInFinancialAccounting.Recorder IN (&DocumentsArray)
		|TOTALS
		|BY
		|	Recorder";
		Query.SetParameter("DocumentsArray", DocumentsArray);
		Query.SetParameter("NewStatus", NewReflectionStatus);
		Query.SetParameter("OldReflectionStatuses", OldReflectionStatuses);
		
		SelectionOfDocuments = Query.Execute().Select(QueryResultIteration.ByGroups);
		
		RecordSet = InformationRegisters.DocumentPostingInFinancialAccounting.CreateRecordSet();
		
		While SelectionOfDocuments.Next() Do
			
			RecordSet.Clear();
			RecordSet.Filter.Recorder.Set(SelectionOfDocuments.Recorder);
			
			Selection = SelectionOfDocuments.Select();
			
			While Selection.Next() Do
				
				RecordingReflection = RecordSet.Add();
				FillPropertyValues(RecordingReflection, Selection);
			
			EndDo;
			
			RecordSet.Write();
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageTemplate = NStr("vi = 'Chưa thực hiện giao dịch thay đổi trạng thái phản ánh do nguyên nhân:
								|%1';
								|ru = 'Операция изменения статуса отражения не выполнена по причине:
								|%1';
								|en = 'Cannot change the recording status due to:
								|%1'; fa = 'Cannot change the recording status due to:
								|%1';
								|it = 'Operazione di modifica dello stato di riflessione non eseguita a causa di: 
								|%1';
								|pl = 'Operacja zmiany statusu odzwierciedlenia nie jest wykonana z powodu:
								|%1';
								|tr = 'Yansıtma durumunu değiştirme işlemi şu nedenle başarısız oldu:
								|%1'");
		Common.MessageToUser(StrTemplate(MessageTemplate, BriefErrorDescription(ErrorInfo())));
		WriteLogEvent(NStr("vi = 'Giao dịch chưa thực hiện';
							|ru = 'Операция не выполнена';
							|en = 'Transaction is not executed'; fa = 'معامله اجرا نشده است';
							|it = 'Operazione non eseguita';
							|pl = 'Operacja nie powiodła się';
							|tr = 'İşlem tamamlanmadı'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, StrTemplate(MessageTemplate, DetailErrorDescription(ErrorInfo())));
		
	EndTry;
	
EndProcedure

// Cancels the reflection of documents in accounting.
// 
// Parameters:
//  DocumentsArray - Array of DocumentRef - array of documents.
Procedure CancelReflectionOfDocumentsInAccounting(DocumentsArray) Export
	
	ReflectionStatuses = Enums.StatusesOfPostingsInFinancialAccounting;
	SelectionStatuses = CommonClientServer.ValueInArray(ReflectionStatuses.PostedToAccounting);
	SelectionStatuses.Add(ReflectionStatuses.ForManualPostingInAccounting);
	SelectionStatuses.Add(ReflectionStatuses.ManuallyPostedToAccounting);
	
	RecordNewReflectionStatus(DocumentsArray, ReflectionStatuses.ForPostingInAccounting, SelectionStatuses);
	
EndProcedure

// Returns the reversing documents to the reflection when the transactions of the cancelled documents are changed.
// 
// Parameters:
//  ParametersForGeneratingTransactions - See ParametersForGeneratingTransactions
//  Var_Documents - DocumentRef, Array of DocumentRef - documents that are being cancelled that have changed their transactions.
Procedure ReturnReverseDocumentsToReflection(ParametersForGeneratingTransactions = Undefined, Var_Documents = Undefined) Export
	
	ThereIsTableManager = ParametersForGeneratingTransactions <> Undefined;
	ThereAreDocuments_ = Var_Documents <> Undefined;
	
	If Not ThereIsTableManager And Not ThereAreDocuments_ Then
		Return;
	EndIf;
	
	Query = New Query();
	QueriesTexts = New Array();
	
	If ThereIsTableManager Then
		Query.TempTablesManager = ParametersForGeneratingTransactions.TempTablesManager;
		
		QueriesTexts.Add("
		|SELECT DISTINCT
		|	DocumentsToBeReflected.Recorder AS Recorder
		|INTO Recorders
		|FROM
		|	DocumentsToBeReflected AS DocumentsToBeReflected");
	EndIf;
	
	If ThereAreDocuments_ Then
		DocumentsArray = TMCommonUseClientServer.Array(Var_Documents);
		DocumentsTable = New ValueTable();
		DocumentTypes = New TypeDescription();
		
		For Each Document In DocumentsArray Do
			DocumentType = TypeOf(Document);
			If Not DocumentTypes.ContainsType(DocumentType) Then
				TypesToAdd = New Array();
				TypesToAdd.Add(DocumentType);
				DocumentTypes = New TypeDescription(DocumentTypes, TypesToAdd);
			EndIf;
			DocumentsTable.Add();
		EndDo;
		
		DocumentsTable.Columns.Add("Recorder", DocumentTypes);
		DocumentsTable.LoadColumn(DocumentsArray, "Recorder");
		Query.SetParameter("DocumentsTable", DocumentsTable);
		
		QueriesTexts.Add("
		|SELECT
		|	DocumentsTable.Recorder AS Recorder
		|INTO Recorders
		|FROM
		|	&DocumentsTable AS DocumentsTable");
		
		IndexOfText = QueriesTexts.UBound();
		If IndexOfText > 0 Then
			QueriesTexts[IndexOfText] = StrReplace(QueriesTexts[IndexOfText], "INTO Recorders", ""); //@Query-part
		EndIf;
	EndIf;
	
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	
	QueryText = QueryText + "
	|INDEX BY
	|	Recorder
	|;
	|
	|//////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentPostingInFinancialAccounting.Recorder   AS Recorder,
	|	DocumentPostingInFinancialAccounting.Period        AS Period,
	|	DocumentPostingInFinancialAccounting.ChartOfAccounts    AS ChartOfAccounts,
	|	DocumentPostingInFinancialAccounting.Organization   AS Organization,
	|	DocumentPostingInFinancialAccounting.DateRecord AS DateRecord,
	|	CASE
	|		WHEN DocumentPostingInFinancialAccounting.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting)
	|			THEN VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting)
	|		ELSE VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting)
	|	END AS Status,
	|	DocumentPostingInFinancialAccounting.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	
	|	INNER JOIN
	|		Recorders AS Recorders
	|	ON
	|		DocumentsRegistry.ReversedDocument = Recorders.Recorder
	|		AND DocumentsRegistry.ReverseTransactionCorrection
	|		AND DocumentsRegistry.Posted
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|	
	|	INNER JOIN
	|		InformationRegister.DocumentPostingInFinancialAccounting AS DocumentPostingInFinancialAccounting
	|	ON
	|		DocumentsRegistry.Ref = DocumentPostingInFinancialAccounting.Recorder
	|WHERE
	|	NOT (DocumentsRegistry.Ref) IN 
	|		(SELECT
	|			Recorders.Recorder
	|		FROM
	|			Recorders AS Recorders)
	|TOTALS BY
	|	Recorder
	|;
	|
	|//////////////////////////////////////////////////////////////////////
	|DROP Recorders";
	
	Query.Text = QueryText;
	SamplingLogger = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SamplingLogger.Next() Do
		RecordSet = InformationRegisters.DocumentPostingInFinancialAccounting.CreateRecordSet();
		RecordSet.Filter.Recorder.Set(SamplingLogger.Recorder);
		Selection = SamplingLogger.Select();
		While Selection.Next() Do
			Record = RecordSet.Add();
			FillPropertyValues(Record, Selection);
		EndDo;
		RecordSet.Write();
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

Procedure PerformOfflineCalculations(Val Companies = Undefined, Val EndDate = Undefined, Val Var_Documents = Undefined) Export
	
	If Not ValueIsFilled(EndDate) Then
		EndDate = EndOfMonth(CurrentSessionDate());
	EndIf;
	
	BegOfMonth = BegOfMonth(EndDate);
	EndOfMonth = EndOfMonth(EndDate);
	CalculationEnd = EndOfMonth(EndDate)+1;

	If GetFunctionalOption("NewOnlineARAPAccounting") Then
		
		If Var_Documents = Undefined Then
			
			Query = New Query();
			Query.SetParameter("EndDate", EndDate);
			
			QueryText = "
			|SELECT DISTINCT
			|	DocumentReflection.Recorder AS Recorder
			|FROM
			|	InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
			|WHERE
			|	DocumentReflection.Period <= &EndDate
			|	AND DocumentReflection.Status IN (
			|		VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting))
			|	AND &FilterByCompanies
			|";
			
			If ValueIsFilled(Companies) Then
				FilterByCompanies = "DocumentReflection.Organization IN (&Companies)";
				Query.SetParameter("Companies", Companies);
			Else
				FilterByCompanies = "TRUE";
			EndIf;
			
			QueryText = StrReplace(QueryText, "&FilterByCompanies", FilterByCompanies);
			
			Query.Text = QueryText;
			Result = Query.Execute();
			DocumentsForSettlement = Result.Unload().UnloadColumn("Recorder");
			
		Else
			DocumentsForSettlement = TMCommonUseClientServer.Array(Var_Documents);
		EndIf;
		
	Else
		
		If Var_Documents = Undefined Then
			
			If ValueIsFilled(EndDate) Then
				Var_130_CalculationEnd = EndOfMonth(EndDate)+1;
			Else
				Var_130_CalculationEnd = EndOfMonth(CurrentSessionDate())+1;
			EndIf;
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			If ValueIsFilled(Companies) Then
				CalculationAnalysts.Companies = TMCommonUseClientServer.Array(Companies);
			EndIf;
			ARAPAllocationServerCall.CalculateEverything(Var_130_CalculationEnd, CalculationAnalysts);
			
			Return;
			
		Else
			DocumentsForSettlement = TMCommonUseClientServer.Array(Var_Documents);
		EndIf;
		
		Query = New Query("
		|SELECT DISTINCT
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|FROM
		|	AccumulationRegister.VendorsARAPAccounting AS Calculations
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND Calculations.Recorder IN (&DocumentsToBeReflected)
		|	AND Calculations.Active
		|");
		
		Query.SetParameter("BeginOfPeriod", BegOfMonth);
		Query.SetParameter("PeriodEnding", EndOfMonth);
		Query.SetParameter("DocumentsToBeReflected", Var_Documents);
		SupplierAnalyticsArray = Query.Execute().Unload().UnloadColumn("AccountingDimensionByPartners");
		
		If SupplierAnalyticsArray.Count() > 0 Then
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = SupplierAnalyticsArray;
			ARAPAllocationServerCall.DistributeAllSettlementsWithSuppliers(CalculationEnd, CalculationAnalysts);
		EndIf;
		
		Query = New Query("
		|SELECT DISTINCT
		|	Calculations.AccountingDimensionByPartners AS AccountingDimensionByPartners
		|FROM
		|	AccumulationRegister.CustomersARAPAccounting AS Calculations
		|WHERE
		|	Calculations.Period BETWEEN &BeginOfPeriod AND &PeriodEnding
		|	AND Calculations.Recorder IN (&DocumentsToBeReflected)
		|	AND Calculations.Active
		|");
		
		Query.SetParameter("BeginOfPeriod", BegOfMonth);
		Query.SetParameter("PeriodEnding", EndOfMonth);
		Query.SetParameter("DocumentsToBeReflected", Var_Documents);
		ArrayOfCustomerAnalytics = Query.Execute().Unload().UnloadColumn("AccountingDimensionByPartners");
		
		If ArrayOfCustomerAnalytics.Count() > 0 Then
			CalculationAnalysts = ARAPAllocationServerCall.CalculationAnalysts();
			CalculationAnalysts.AccountingAnalyticsForPartners = ArrayOfCustomerAnalytics;
			ARAPAllocationServerCall.DistributeAllSettlementsWithCustomers(CalculationEnd, CalculationAnalysts);
		EndIf;
		
	EndIf;
	
	If DocumentsForSettlement.Count() > 0 Then
		ExecutionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForOfflineCalculations();
		ExecutionParameters.EndDate = EndDate;
		ExecutionParameters.DocumentsForSettlement = DocumentsForSettlement;
		ExecutionParameters.ThreadsCount = NumberOfReflectionStreamsInInternationalAccounting();
		ExecutionParameters.RecalculateSpeedRegisters = True;
		ExecutionParameters.JobKind = Catalogs.BackdateJobKinds.RecordInFinancialAccounting;
		FinancialAccountingByBalanceSheetRegisterData.PerformOfflineCalculations(ExecutionParameters);
	EndIf;
	
EndProcedure

// Returns the forecast parameters of reflection in international accounting in summary and by document types
// 
// Returns:
// 	Structure - Predictive reflection parameters:
// 		* DateOfFirstPosting - Date - the date of the earliest generated Entry
// 		* DocumentsCount - Number - The total number of reflected documents.
// 		* NumberOfTransactions_ - Number - the total number of Entries to be registered.
// 		* TransactionsPerServing - Number - the number of Entries generated in one stream.
// 		* BatchesCount - Number - The number of portions of documents.
// 		* ByDocumentType - Array of Structure - similar data on document types. Structure properties:
// 			** DocumentType - Type - Document type
// 			** DocumentsCount - Number - The total number of reflected documents of this type
// 			** NumberOfTransactions_ - Number - the total number of registered Entries for documents of this type
// 	
Function ForecastParametersOfReflectionInInternationalAccounting() Export
	
	ForecastParameters = New Structure();
	ForecastParameters.Insert("DateOfFirstPosting", MaximumPeriodOfCalculatedAccountingTotals() + 1);
	ForecastParameters.Insert("DocumentsCount", 0);
	ForecastParameters.Insert("NumberOfTransactions_", 0);
	ForecastParameters.Insert("TransactionsPerServing", 0);
	ForecastParameters.Insert("BatchesCount", 0);
	ForecastParameters.Insert("ByDocumentType", New Array());
	
	Return ForecastParameters;
	
EndFunction

Function TransactionsForRoutineOperations(OperationData) Export
	
	TableOfTransactions = TableOfTransactions();

	If Not GetFunctionalOption("FinancialAccountingEntriesBasedOnOperationalAccountingData")
	 Or Not GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		Return TableOfTransactions;
	EndIf;
	
	TempTablesManager = FinancialAccountingByFinancialRegisterData.DataOnReclassificationOfNonCurrentAssetsLiabilities(
		OperationData.Organization, OperationData.Date);
	
	If TempTablesManager.Tables.Count() = 0 Then
		Return TableOfTransactions;
	EndIf;
	
	QueriesTexts = New Array();
	
	QueriesTexts.Add("
	|SELECT
	|	BusinessAccountPlans.Period AS Period,
	|	BusinessAccountPlans.Organization AS Organization,
	|	BusinessAccountPlans.ChartOfAccounts AS ChartOfAccounts,
	|	BusinessAccountPlans.PostingGenerationSetting AS PostingGenerationSetting
	|INTO FinancialAccountingChartsOfAccountsForCompanies
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies.SliceLast(&DateOfTransaction,
	|		Organization = &Organization AND ChartOfAccounts = &ChartOfAccounts) AS BusinessAccountPlans
	|");
	
	QueriesTexts.Add("
	|SELECT
	|	&DateOfTransaction AS Period,
	|	BEGINOFPERIOD(&DateOfTransaction, DAY) AS DateRecord,
	|	&Recorder AS Recorder,
	|	BusinessAccountPlans.Organization AS Organization,
	|	BusinessAccountPlans.ChartOfAccounts AS ChartOfAccounts,
	|	BusinessAccountPlans.PostingGenerationSetting AS PostingGenerationSetting
	|INTO DocumentsToBeReflected
	|FROM
	|	FinancialAccountingChartsOfAccountsForCompanies AS BusinessAccountPlans
	|");
	
	FinancialAccountingByFinancialRegisterData.AddTextsOfRequestsForReclassificationOfNonCurrentAssetsLiabilities(
		QueriesTexts, TempTablesManager);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	QueriesTexts.Clear();
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Recorder", OperationData.Ref);
	Query.SetParameter("ChartOfAccounts", OperationData.ChartOfAccounts);
	Query.SetParameter("Organization", OperationData.Organization);
	Query.SetParameter("DateOfTransaction", OperationData.Date);
	Query.Execute();
	
	ReflectionParameters = ReflectionParametersInInternationalAccounting();
	ReflectionParameters.Companies = OperationData.Organization;
	ReflectionParameters.EndDate = EndOfMonth(OperationData.Date);
	ReflectionParameters.Documents = OperationData.Ref;
	ReflectionParameters.ToRecordTransactions = False;
	ReflectionParameters.PerformRecalculations = False;
	
	ParametersForGeneratingTransactions = ParametersForGeneratingTransactions(ReflectionParameters);
	ParametersForGeneratingTransactions.TempTablesManager = Query.TempTablesManager;
	
	FinancialAccountingByFinancialRegisterData.Reflect(ParametersForGeneratingTransactions, TableOfTransactions);
	
	RecalculateTableOfTransactionsAtRate(ParametersForGeneratingTransactions, TableOfTransactions);
	CollapseTransactionTable(ParametersForGeneratingTransactions, TableOfTransactions);
	DeleteTransactionsWithoutAmountsAndQuantities(ParametersForGeneratingTransactions, TableOfTransactions);
	RemoveInsignificantTransactions(ParametersForGeneratingTransactions, TableOfTransactions);
	
	Return TableOfTransactions;
	
EndFunction

Procedure FillInTransactionStatus(AccountingEntry, Status) Export

	AccountingEntry.Status = FinancialAccountingServerCached.DetermineStatus(AccountingEntry.Status, Status);

EndProcedure

// Parameters:
// 	AccountingEntry - Structure - Description of the Entry:
//   * ErrorsArray - Array of String - error text
// 	ErrorText - String - 
Procedure AddTransactionError(AccountingEntry, ErrorText) Export

	AccountingEntry.ErrorsArray.Add(ErrorText);

EndProcedure

// Parameters:
// 	TableOfTransactions - ValueTable - 
// 	AccountingEntry - Structure - 
Procedure AddTransactionToTransactionTable(TableOfTransactions, AccountingEntry) Export

	TableRow = TableOfTransactions.Add();
	FillPropertyValues(TableRow, AccountingEntry);
	
	FillInStatusInTransactionsTable(TableRow, AccountingEntry);
	
	FillInCommentInTransactionsTable(TableRow, AccountingEntry);

EndProcedure

// Parameters:
// 	DataCompositionSchema - DataCompositionSchema - 
// 	Setting - Structure - 
// Returns:
// 	String - 
Function ExpressionOfExtdimensionFillingBySetting(DataCompositionSchema, Setting) Export
	
	ExpressionOfCalculatedField = "Undefined";
	If Setting.FillInFromSource Then
		SettingExpression = Setting.Expression;
		If Find(SettingExpression, "AccountDr.") > 0 Then
			SettingExpression = StrReplace(SettingExpression, "AccountDr.", "");
		ElsIf Find(SettingExpression, "AccountCr.") > 0 Then
			SettingExpression = StrReplace(SettingExpression, "AccountCr.", "");
		ElsIf IsBlankString(SettingExpression) Then
			SettingExpression = "Undefined";
		EndIf;
		ExpressionOfCalculatedField = SettingExpression;
	Else
		ParameterName = "SpecifiedValue_" + StrReplace(String(New UUID), "-", "");
		Parameter = DataCompositionSchema.Parameters.Add();
		Parameter.Use = DataCompositionParameterUse.Always;
		Parameter.Name = ParameterName;
		Parameter.Value = Setting.SpecifiedValue;
		ExpressionOfCalculatedField = "&" + ParameterName;
	EndIf;
	
	Return ExpressionOfCalculatedField;
	
EndFunction

Function TypesOfNonreflectedDocuments() Export
	
	DocumentTypes = New Array();
	DocumentTypes.Add(Type("DocumentRef.RegisterAdjustment"));
	DocumentTypes.Add(Type("DocumentRef.TransactionFinancialAccounting"));
	DocumentTypes.Add(Type("DocumentRef.PeriodEndTransactionFinancialAccounting"));
	
	If GetFunctionalOption("FinancialAccountingEntriesBasedOnOperationalAccountingData")
		And GetFunctionalOption("SettingOfPostingByAccountingObjects") Then
		NamesOfUnusedDocuments = FinancialAccountingByBalanceSheetRegisterData.NamesOfUnusedDocuments();
		
		For Each DocumentName In NamesOfUnusedDocuments Do
			DocumentTypes.Add(Type(StrTemplate("DocumentRef.%1", DocumentName)));
		EndDo;
	EndIf;
	
	Return DocumentTypes;
	
EndFunction

// Returns General parameters for generating transactions
//
// Returns:
// 	Structure - Contains Parameters:
// 		* EntryStructure - See EntryStructure
// 		* ExtDimensionCount - Number - maximum number of sub-accounts of the chart of accounts International
// 		* BalanceMeasurements - Array of String - field names of the accounting Register International
// 		* UnbalancedMeasurements - Array of String - field names of the accounting Register International
// 		* BalanceSheetResources - Array of String - field names of the accounting Register International
// 		* UnbalancedResources - Array of String - field names of the accounting Register International
// 		* Attributes - Array of String - field names of the accounting Register International
// 		* InvertedFields - Array of String - field names of the accounting Register International
// 		* InvertedResources - Array of String - field names of the accounting Register International
// 		* CollapseTransactionTable - Boolean - indicates whether transactions need to be rolled up before recording
// 		* RemoveInsignificantTransactions - Boolean - indication of the need to delete transactions with the same Dt and Ct values
//
Function NewParametersForGeneratingTransactions() Export
	
	ParametersForGeneratingTransactions = New Structure;
	ParametersForGeneratingTransactions.Insert("EntryStructure", EntryStructure());
	ParametersForGeneratingTransactions.Insert("TempTablesManager", New TempTablesManager());
	
	RegisterFieldsDetails = AccountingRegisters.International.RegisterFieldsDetails();
	
	ParametersForGeneratingTransactions.Insert("ExtDimensionCount",    RegisterFieldsDetails.ExtDimensionCount);
	ParametersForGeneratingTransactions.Insert("BalanceMeasurements",   RegisterFieldsDetails.BalanceMeasurements);
	ParametersForGeneratingTransactions.Insert("UnbalancedMeasurements", RegisterFieldsDetails.UnbalancedMeasurements);
	ParametersForGeneratingTransactions.Insert("BalanceSheetResources",     RegisterFieldsDetails.BalanceSheetResources);
	ParametersForGeneratingTransactions.Insert("UnbalancedResources",   RegisterFieldsDetails.UnbalancedResources);
	ParametersForGeneratingTransactions.Insert("Attributes",             RegisterFieldsDetails.Attributes);
	
	ParametersForGeneratingTransactions.Insert("InvertedFields",    AccountingRegisters.International.InvertedFields(RegisterFieldsDetails));
	ParametersForGeneratingTransactions.Insert("InvertedResources", AccountingRegisters.International.InvertedResources(RegisterFieldsDetails));
	
	ParametersForGeneratingTransactions.Insert("CollapseTransactionTable", False);
	ParametersForGeneratingTransactions.Insert("RemoveInsignificantTransactions", False);
	
	Return ParametersForGeneratingTransactions;
	
EndFunction

// Parameters:
//  TableOfTransactions - See TableOfTransactions
//  TransactionsParameters - See NewParametersForGeneratingTransactions
//
Procedure DeleteCorrespondenceTransactions(TableOfTransactions, TransactionsParameters) Export
	
	TableOfTransactions.Columns.Add("RecordType", New TypeDescription("AccountingRecordType"));
	RowsCount = TableOfTransactions.Count();
	LinesToDelete = New Array();
	
	For IndexOf = 0 To RowsCount - 1 Do
		CurrentRow = TableOfTransactions[IndexOf];
		
		If ValueIsFilled(CurrentRow.AccountDr) Then
			CurrentRow.RecordType = AccountingRecordType.Debit;
		Else
			LinesToDelete.Add(CurrentRow);
		EndIf;
		
		If ValueIsFilled(CurrentRow.AccountCr) Then
			NewRow = TableOfTransactions.Add();
			FillPropertyValues(NewRow, CurrentRow);
			NewRow.RecordType = AccountingRecordType.Credit;
			
			For Each FieldName In TransactionsParameters.InvertedFields Do
				If FieldName = "ExtDimension" Or FieldName = "ExtDimensionType" Then
					For ExtDimensionNumber = 1 To TransactionsParameters.ExtDimensionCount Do
						NewRow[FieldName + "Dr" + ExtDimensionNumber] = CurrentRow[FieldName + "Cr" + ExtDimensionNumber];
					EndDo;
				Else
					NewRow[FieldName + "Dr"] = CurrentRow[FieldName + "Cr"];
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	For Each RowToDelete In LinesToDelete Do
		TableOfTransactions.Delete(RowToDelete);
	EndDo;
	
	For Each FieldName In TransactionsParameters.InvertedFields Do
		If FieldName = "ExtDimension" Or FieldName = "ExtDimensionType" Then
			For ExtDimensionNumber = 1 To TransactionsParameters.ExtDimensionCount Do
				TableOfTransactions.Columns.Delete(FieldName + "Cr" + ExtDimensionNumber);
				TableOfTransactions.Columns[FieldName + "Dr" + ExtDimensionNumber].Name = FieldName + ExtDimensionNumber;
			EndDo;
		Else
			TableOfTransactions.Columns.Delete(FieldName + "Cr");
			TableOfTransactions.Columns[FieldName + "Dr"].Name = FieldName;
		EndIf;
	EndDo;
	
	CollapseTableOfTransactionsWithoutCorrespondence(TransactionsParameters, TableOfTransactions);
	CollapseTurnoverOfTransactionsWithoutCorrespondence(TransactionsParameters, TableOfTransactions);
	DeleteTransactionsWithoutResourcesWithoutCorrespondence(TransactionsParameters, TableOfTransactions);
	
EndProcedure

#EndRegion

#Region Private

#Region GeneratePostings

// Returns General parameters for generating transactions
//
// Parameters:
// 	ReflectionParametersInInternationalAccounting - See ReflectionParametersInInternationalAccounting
// 	
// Returns:
// 	Structure - Contains Parameters:
// 		* EntryStructure - See NewParametersForGeneratingTransactions
// 		* TempTablesManager - TempTablesManager - 
Function ParametersForGeneratingTransactions(ReflectionParametersInInternationalAccounting) Export
	
	ParametersForGeneratingTransactions = NewParametersForGeneratingTransactions();
	
	FinancialAccountingUponOperationalAccountingData.AddParametersForGeneratingTransactions(ParametersForGeneratingTransactions);
	FinancialAccountingByFinancialRegisterData.AddParametersForGeneratingTransactions(ParametersForGeneratingTransactions);
	FinancialAccountingUponLocalAccounting.AddParametersForGeneratingTransactions(ParametersForGeneratingTransactions);
	
	Return ParametersForGeneratingTransactions;
	
EndFunction

Function NumberOfReflectionStreamsInInternationalAccounting()
	
	NumberOfThreadsWithSeparation = 1;
	NumberOfThreadsWithoutSeparation = 6;
	
	If Not MultithreadedReflectionIsPossible() Then
		ThreadsCount = 1;
	ElsIf Common.DataSeparationEnabled() Then
		ThreadsCount = NumberOfThreadsWithSeparation;
	Else
		ThreadsCount = NumberOfThreadsWithoutSeparation;
	EndIf;
	
	Return ThreadsCount;
	
EndFunction

Function MultithreadedReflectionIsPossible()
	
	SetPrivilegedMode(True);
	
	Return Not Common.DebugMode()
		And Not Common.FileInfobase()
		And AccountingRegisters.International.GetTotalsSplittingMode()
		And AccountingRegisters.InternationalWithoutCorrespondence.GetTotalsSplittingMode();
	
EndFunction

Function NumberOfTransactionsPerServing(ThreadsCount = 1)
	
	If ThreadsCount > 10 Then
		TransactionsPerServing = 2000;
	ElsIf ThreadsCount > 3 Then
		TransactionsPerServing = 3000;
	ElsIf ThreadsCount > 1 Then
		TransactionsPerServing = 4000;
	Else
		TransactionsPerServing = 10000;
	EndIf;
	
	Return TransactionsPerServing;
	
EndFunction

Procedure FillInForecastParameters(ReflectionParametersInInternationalAccounting)
	
	ForecastParameters = ForecastParametersOfReflectionInInternationalAccounting();
	
	MonthsOfStatistics = 1;
	NumberOfTransactionsWithoutStatistics = 10;
	CalculateForecastParameters = True;
	
	If ReflectionParametersInInternationalAccounting.CheckREFLECTIONStatus Then
	ElsIf ReflectionParametersInInternationalAccounting.Documents = Undefined Then
	ElsIf TypeOf(ReflectionParametersInInternationalAccounting.Documents) <> Type("Array")
		Or ReflectionParametersInInternationalAccounting.Documents.Count() = 1 Then
		ForecastParameters.DocumentsCount = 1;
		CalculateForecastParameters = False;
	EndIf;
	
	If CalculateForecastParameters Then
		Query = New Query();
		Query.Text = "
		|SELECT
		|	VALUETYPE(ReflectionOfDocumentsInAccounting.Recorder) AS TypeOfRegistrar,
		|	MIN(ReflectionOfDocumentsInAccounting.DateRecord) AS StartDate,
		|	COUNT(DISTINCT ReflectionOfDocumentsInAccounting.Recorder) AS DocumentsCount
		|FROM
		|	InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionOfDocumentsInAccounting
		|	LEFT JOIN DocumentVerificationOverridable AS DocumentVerificationOverridable
		|		ON ReflectionOfDocumentsInAccounting.Recorder = DocumentVerificationOverridable.Document
		|		 AND ReflectionOfDocumentsInAccounting.Organization = DocumentVerificationOverridable.Organization
		|		 AND &ReflectOnlyVerifiedDocumentsInAccounting
		|WHERE
		|	ReflectionOfDocumentsInAccounting.DateRecord <= &EndDate
		|	AND &FilterByDocuments
		|	AND &FilterByCompanies
		|	AND &SelectionByReflectionStatuses
		|	AND &DocumentVerified
		|GROUP BY
		|	VALUETYPE(ReflectionOfDocumentsInAccounting.Recorder)
		|TOTALS
		|	MIN(StartDate) AS StartDate,
		|	SUM(DocumentsCount) AS DocumentsCount
		|BY
		|	OVERALL
		|";
		
		DocumentVerificationServer.OverrideVerificationStatusInRequestTextTakingIntoAccountExceptions(Query.Text, "ReflectionOfDocumentsInAccounting.Recorder");
		SetSelectionOfDocumentsByReflectionParameters(Query, ReflectionParametersInInternationalAccounting);
		
		Result = Query.Execute();
		
		SampleDocumentsTotal = Result.Select(QueryResultIteration.ByGroups);
		SampleDocumentsTotal.Next();
		
		If ValueIsFilled(SampleDocumentsTotal.DocumentsCount) Then
			ForecastParameters.DateOfFirstPosting = SampleDocumentsTotal.StartDate;
			ForecastParameters.DocumentsCount = SampleDocumentsTotal.DocumentsCount;
			
			Query.SetParameter("StartDateOfStatistics", AddMonth(BegOfMonth(SampleDocumentsTotal.StartDate), -MonthsOfStatistics));
			Query.SetParameter("EndDateOfStatistics", BegOfMonth(SampleDocumentsTotal.StartDate) - 1);
			
			Query.Text = "
			|SELECT
			|	VALUETYPE(International.Recorder) AS TypeOfRegistrar,
			|	CAST(COUNT(International.Recorder) / COUNT(DISTINCT International.Recorder) AS NUMBER(31,2)) AS NumberOfTransactions_
			|INTO TransactionStatistics
			|FROM
			|	AccountingRegister.International AS International
			|WHERE
			|	International.Period BETWEEN &StartDateOfStatistics AND &EndDateOfStatistics
			|	AND &FilterByDocumentType
			|	AND &FilterByCompanies
			|GROUP BY
			|	VALUETYPE(International.Recorder)
			|	
			|UNION ALL
			|
			|SELECT
			|	VALUETYPE(International.Recorder) AS TypeOfRegistrar,
			|	CAST(COUNT(International.Recorder) / (2 * COUNT(DISTINCT International.Recorder)) AS NUMBER(31,2)) AS NumberOfTransactions_
			|FROM
			|	AccountingRegister.InternationalWithoutCorrespondence AS International
			|WHERE
			|	International.Period BETWEEN &StartDateOfStatistics AND &EndDateOfStatistics
			|	AND &FilterByDocumentType
			|	AND &FilterByCompanies
			|GROUP BY
			|	VALUETYPE(International.Recorder)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	TransactionStatistics.TypeOfRegistrar AS TypeOfRegistrar,
			|	SUM(TransactionStatistics.NumberOfTransactions_) AS NumberOfTransactions_
			|FROM
			|	TransactionStatistics AS TransactionStatistics
			|GROUP BY
			|	TransactionStatistics.TypeOfRegistrar
			|TOTALS
			|	CAST(AVG(NumberOfTransactions_) AS NUMBER(31,2)) AS NumberOfTransactions_
			|BY
			|	OVERALL
			|";
			
			DocumentsSelection = SampleDocumentsTotal.Select();
			
			If ReflectionParametersInInternationalAccounting.Documents <> Undefined Then
				TypesOfLoggers = New Array();
				While DocumentsSelection.Next() Do
					TypesOfLoggers.Add(DocumentsSelection.TypeOfRegistrar);
				EndDo;
				FilterByDocumentType = "VALUETYPE(International.Recorder) IN (&TypesOfLoggers)";
				Query.SetParameter("TypesOfLoggers", TypesOfLoggers);
			Else
				FilterByDocumentType = "TRUE";
			EndIf;
			
			If ValueIsFilled(ReflectionParametersInInternationalAccounting.Companies) Then
				FilterByCompanies = "International.Organization IN (&Companies)";
			Else
				FilterByCompanies = "TRUE";
			EndIf;
			
			Query.Text = StrReplace(Query.Text, "&FilterByDocumentType", FilterByDocumentType);
			Query.Text = StrReplace(Query.Text, "&FilterByCompanies", FilterByCompanies);
			
			Result = Query.Execute();
			
			TransactionSelectionTotal = Result.Select(QueryResultIteration.ByGroups);
			TransactionSelectionTotal.Next();
			
			TransactionSelection_ = TransactionSelectionTotal.Select();
			DocumentsSelection.Reset();
			
			While DocumentsSelection.Next() Do
				TransactionSelection_.Reset();
				TheStructureOfTheSearch = New Structure("TypeOfRegistrar", DocumentsSelection.TypeOfRegistrar);
				
				If TransactionSelection_.FindNext(TheStructureOfTheSearch) Then
					SpecificNumberOfTransactions = TransactionSelection_.NumberOfTransactions_;
				ElsIf ValueIsFilled(TransactionSelectionTotal.NumberOfTransactions_) Then
					SpecificNumberOfTransactions = TransactionSelectionTotal.NumberOfTransactions_;
				Else
					SpecificNumberOfTransactions = NumberOfTransactionsWithoutStatistics;
				EndIf;
				
				NumberOfTransactions_ = Round(SpecificNumberOfTransactions * DocumentsSelection.DocumentsCount, 0);
				ForecastParameters.NumberOfTransactions_ = ForecastParameters.NumberOfTransactions_ + NumberOfTransactions_;
				
				If ReflectionParametersInInternationalAccounting.ThreadsCount > 1 Then
					ParametersByDocument = New Structure("DocumentType,DocumentsCount,NumberOfTransactions_",
						DocumentsSelection.TypeOfRegistrar, DocumentsSelection.DocumentsCount, NumberOfTransactions_);
					ForecastParameters.ByDocumentType.Add(ParametersByDocument);
				EndIf;
			EndDo;
		EndIf;
	Else
		ForecastParameters.NumberOfTransactions_ = NumberOfTransactionsWithoutStatistics * ForecastParameters.DocumentsCount;
	EndIf;
	
	If ForecastParameters.DocumentsCount > 0 Then
		TransactionsPerServing = NumberOfTransactionsPerServing(ReflectionParametersInInternationalAccounting.ThreadsCount);
		
		If ReflectionParametersInInternationalAccounting.ThreadsCount = 1 Then
		ElsIf ForecastParameters.NumberOfTransactions_ >= TransactionsPerServing * ReflectionParametersInInternationalAccounting.ThreadsCount Then
		Else
			TransactionsPerServing = Round(ForecastParameters.NumberOfTransactions_ / ReflectionParametersInInternationalAccounting.ThreadsCount, 0);
			TransactionsPerServing = Max(TransactionsPerServing, ReflectionParametersInInternationalAccounting.MinimumServingSize);
		EndIf;
		
		ForecastParameters.TransactionsPerServing = TransactionsPerServing;
		ForecastParameters.BatchesCount = 1 + Int(ForecastParameters.NumberOfTransactions_ / TransactionsPerServing);
	EndIf;
	
	If ForecastParameters.BatchesCount <= 1 Then
		ForecastParameters.ByDocumentType.Clear();
	EndIf;
	
	ReflectionParametersInInternationalAccounting.ForecastParameters = ForecastParameters;
	
EndProcedure

Function MaximumPeriodOfCalculatedAccountingTotals()
	
	Return EndOfMonth(CurrentSessionDate());
	
EndFunction

Function MinimumPeriodOfCalculatedAccountingResults()
	
	Return '00010101';
	
EndFunction

Function ItIsRecommendedToTurnOffRegisterTotals(ReflectionParametersInInternationalAccounting)
	
	ForecastParameters = ReflectionParametersInInternationalAccounting.ForecastParameters;
	
	Return Not Common.FileInfobase()
		And ReflectionParametersInInternationalAccounting.ToRecordTransactions
		And ForecastParameters.DocumentsCount > 0
		And ForecastParameters.NumberOfTransactions_ >= ForecastParameters.TransactionsPerServing;
	
EndFunction

Procedure TurnOffResultsOfInternationalRegisters(ReflectionParametersInInternationalAccounting)
	
	NumberOfAttemptsToDisableTotals = ReflectionParametersInInternationalAccounting.AttemptsNumber * 2;
	AccountingRegistersMetadata = Metadata.AccountingRegisters;
	
	UsingCurTotals = AccountingRegisters.International.GetPresentTotalsUsing()
		Or AccountingRegisters.InternationalWithoutCorrespondence.GetPresentTotalsUsing();
	
	MinimumPeriodOfTotals = Max(AccountingRegisters.International.GetMinTotalsPeriod(),
		AccountingRegisters.InternationalWithoutCorrespondence.GetMinTotalsPeriod());
	
	MaximumPeriodOfTotals = Max(AccountingRegisters.International.GetTotalsPeriod(),
		AccountingRegisters.InternationalWithoutCorrespondence.GetTotalsPeriod());
	
	ReflectionParametersInInternationalAccounting.UsingCurTotals = UsingCurTotals;
	
	If MinimumPeriodOfTotals > ReflectionParametersInInternationalAccounting.MinimumPeriodOfTotals Then
		ReflectionParametersInInternationalAccounting.MinimumPeriodOfTotals = MinimumPeriodOfTotals;
	EndIf;
	
	If MaximumPeriodOfTotals > ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals Then
		ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals = MaximumPeriodOfTotals;
	ElsIf MaximumPeriodOfTotals < ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals Then
		ReflectionParametersInInternationalAccounting.RestoreStateOfResults = True;
	EndIf;
	
	If UsingCurTotals Then
		For AttemptNumber = 1 To NumberOfAttemptsToDisableTotals Do
			Try
				AccountingRegisters.International.SetPresentTotalsUsing(False);
				ReflectionParametersInInternationalAccounting.RestoreStateOfResults = True;
				Break;
			Except
				If AttemptNumber = NumberOfAttemptsToDisableTotals Then
					WriteLogEvent(
						NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						AccountingRegistersMetadata.International.Name,,
						NStr("vi = 'Đã vô hiệu hóa sử dụng tổng số hiện tại bị lỗi.';
							|ru = 'Выключение использования текущих итогов завершилось с ошибкой.';
							|en = 'An error occurred when disabling the current totals.'; fa = 'An error occurred when disabling the current totals.';
							|it = 'Выключение использования текущих итогов завершилось с ошибкой.';
							|pl = 'An error occurred when disabling the current totals.';
							|tr = 'Geçerli toplamların kullanımını kapatmak bir hatayla başarısız oldu.'")
							+ Chars.LF + DetailErrorDescription(ErrorInfo()));
				EndIf;
			EndTry;
		EndDo;
		
		For AttemptNumber = 1 To NumberOfAttemptsToDisableTotals Do
			Try
				AccountingRegisters.InternationalWithoutCorrespondence.SetPresentTotalsUsing(False);
				ReflectionParametersInInternationalAccounting.RestoreStateOfResults = True;
				Break;
			Except
				If AttemptNumber = NumberOfAttemptsToDisableTotals Then
					WriteLogEvent(
						NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						AccountingRegistersMetadata.InternationalWithoutCorrespondence.Name,,
						NStr("vi = 'Đã vô hiệu hóa sử dụng tổng số hiện tại bị lỗi.';
							|ru = 'Выключение использования текущих итогов завершилось с ошибкой.';
							|en = 'An error occurred when disabling the current totals.'; fa = 'An error occurred when disabling the current totals.';
							|it = 'Выключение использования текущих итогов завершилось с ошибкой.';
							|pl = 'An error occurred when disabling the current totals.';
							|tr = 'Geçerli toplamların kullanımını kapatmak bir hatayla başarısız oldu.'")
							+ Chars.LF + DetailErrorDescription(ErrorInfo()));
				EndIf;
			EndTry;
		EndDo;
	EndIf;
	
	DateOfFirstPosting = ReflectionParametersInInternationalAccounting.ForecastParameters.DateOfFirstPosting;
	BeginningOfShutdownPeriod = AddMonth(BegOfMonth(DateOfFirstPosting), -1);
	EndOfShutdownPeriod = EndOfMonth(BeginningOfShutdownPeriod);
	
	ChangeMinimumPeriodOfTotals = MinimumPeriodOfTotals > BeginningOfShutdownPeriod;
	ChangeMaximumPeriodOfTotals = MaximumPeriodOfTotals > EndOfShutdownPeriod;
	
	If ChangeMinimumPeriodOfTotals Or ChangeMaximumPeriodOfTotals Then
		For AttemptNumber = 1 To NumberOfAttemptsToDisableTotals Do
			Try
				If ChangeMinimumPeriodOfTotals And ChangeMaximumPeriodOfTotals Then
					AccountingRegisters.International.SetMinAndMaxTotalsPeriods(
						BeginningOfShutdownPeriod, EndOfShutdownPeriod);
				ElsIf ChangeMinimumPeriodOfTotals Then
					AccountingRegisters.International.SetMinTotalsPeriod(BeginningOfShutdownPeriod);
				ElsIf ChangeMaximumPeriodOfTotals Then
					AccountingRegisters.International.SetMaxTotalsPeriod(EndOfShutdownPeriod);
				EndIf;
				ReflectionParametersInInternationalAccounting.RestoreStateOfResults = True;
				Break;
			Except
				If AttemptNumber = NumberOfAttemptsToDisableTotals Then
					WriteLogEvent(
						NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						AccountingRegistersMetadata.International.Name,,
						NStr("vi = 'Đã dịch chuyển kỳ tổng số lưu lại trước khi phản ánh bị lỗi.';
							|ru = 'Сдвиг хранимых периодов итогов перед отражением завершился с ошибкой.';
							|en = 'An error occurred when shifting stored total periods before recording.'; fa = 'An error occurred when shifting stored total periods before recording.';
							|it = 'Сдвиг хранимых периодов итогов перед отражением завершился с ошибкой.';
							|pl = 'An error occurred when shifting stored total periods before recording.';
							|tr = 'Yansıma başarısız olmadan önce saklanan toplamların dönemlerin kayması.'")
							+ Chars.LF + DetailErrorDescription(ErrorInfo()));
				EndIf;
			EndTry;
		EndDo;
		
		For AttemptNumber = 1 To NumberOfAttemptsToDisableTotals Do
			Try
				If ChangeMinimumPeriodOfTotals And ChangeMaximumPeriodOfTotals Then
					AccountingRegisters.InternationalWithoutCorrespondence.SetMinAndMaxTotalsPeriods(
						BeginningOfShutdownPeriod, EndOfShutdownPeriod);
				ElsIf ChangeMinimumPeriodOfTotals Then
					AccountingRegisters.InternationalWithoutCorrespondence.SetMinTotalsPeriod(BeginningOfShutdownPeriod);
				ElsIf ChangeMaximumPeriodOfTotals Then
					AccountingRegisters.InternationalWithoutCorrespondence.SetMaxTotalsPeriod(EndOfShutdownPeriod);
				EndIf;
				ReflectionParametersInInternationalAccounting.RestoreStateOfResults = True;
				Break;
			Except
				If AttemptNumber = NumberOfAttemptsToDisableTotals Then
					WriteLogEvent(
						NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						AccountingRegistersMetadata.InternationalWithoutCorrespondence.Name,,
						NStr("vi = 'Đã dịch chuyển kỳ tổng số lưu lại trước khi phản ánh bị lỗi.';
							|ru = 'Сдвиг хранимых периодов итогов перед отражением завершился с ошибкой.';
							|en = 'An error occurred when shifting stored total periods before recording.'; fa = 'An error occurred when shifting stored total periods before recording.';
							|it = 'Сдвиг хранимых периодов итогов перед отражением завершился с ошибкой.';
							|pl = 'An error occurred when shifting stored total periods before recording.';
							|tr = 'Yansıma başarısız olmadan önce saklanan toplamların dönemlerin kayması.'")
							+ Chars.LF + DetailErrorDescription(ErrorInfo()));
				EndIf;
			EndTry;
		EndDo;
	EndIf;
	
EndProcedure

Procedure IncludeResultsOfInternationalRegisters(ReflectionParametersInInternationalAccounting)
	
	NumberOfAttemptsToRestoreTotals = ReflectionParametersInInternationalAccounting.AttemptsNumber * 2;
	AccountingRegistersMetadata = Metadata.AccountingRegisters;
	
	UsingCurTotals = AccountingRegisters.International.GetPresentTotalsUsing();
	
	If UsingCurTotals <> ReflectionParametersInInternationalAccounting.UsingCurTotals Then
		For AttemptNumber = 1 To NumberOfAttemptsToRestoreTotals Do
			Try
				AccountingRegisters.International.SetPresentTotalsUsing(
					ReflectionParametersInInternationalAccounting.UsingCurTotals);
				Break;
			Except
				If AttemptNumber = NumberOfAttemptsToRestoreTotals Then
					WriteLogEvent(
						NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						AccountingRegistersMetadata.International.Name,,
						NStr("vi = 'Đã bật sử dụng tổng số hiện tại bị lỗi.';
							|ru = 'Включение использования текущих итогов завершилось с ошибкой.';
							|en = 'An error occurred when enabling the current totals.'; fa = 'An error occurred when enabling the current totals.';
							|it = 'Включение использования текущих итогов завершилось с ошибкой.';
							|pl = 'An error occurred when enabling the current totals.';
							|tr = 'Geçerli toplamların kullanımını açmak bir hatayla başarısız oldu.'")
							+ Chars.LF + DetailErrorDescription(ErrorInfo()));
				EndIf;
			EndTry;
		EndDo;
	EndIf;
		
	UsingCurTotals = AccountingRegisters.InternationalWithoutCorrespondence.GetPresentTotalsUsing();
	
	If UsingCurTotals <> ReflectionParametersInInternationalAccounting.UsingCurTotals Then
		For AttemptNumber = 1 To NumberOfAttemptsToRestoreTotals Do
			Try
				AccountingRegisters.InternationalWithoutCorrespondence.SetPresentTotalsUsing(
					ReflectionParametersInInternationalAccounting.UsingCurTotals);
				Break;
			Except
				If AttemptNumber = NumberOfAttemptsToRestoreTotals Then
					WriteLogEvent(
						NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						AccountingRegistersMetadata.InternationalWithoutCorrespondence.Name,,
						NStr("vi = 'Đã bật sử dụng tổng số hiện tại bị lỗi.';
							|ru = 'Включение использования текущих итогов завершилось с ошибкой.';
							|en = 'An error occurred when enabling the current totals.'; fa = 'An error occurred when enabling the current totals.';
							|it = 'Включение использования текущих итогов завершилось с ошибкой.';
							|pl = 'An error occurred when enabling the current totals.';
							|tr = 'Geçerli toplamların kullanımını açmak bir hatayla başarısız oldu.'")
							+ Chars.LF + DetailErrorDescription(ErrorInfo()));
				EndIf;
			EndTry;
		EndDo;
	EndIf;
	
	MinimumPeriodOfTotals = AccountingRegisters.International.GetMinTotalsPeriod();
	MaximumPeriodOfTotals = AccountingRegisters.International.GetTotalsPeriod();
	
	ChangeMinimumPeriodOfTotals = MinimumPeriodOfTotals < ReflectionParametersInInternationalAccounting.MinimumPeriodOfTotals;
	ChangeMaximumPeriodOfTotals = MaximumPeriodOfTotals < ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals;
	
	If ChangeMinimumPeriodOfTotals Or ChangeMaximumPeriodOfTotals Then
		For AttemptNumber = 1 To NumberOfAttemptsToRestoreTotals Do
			Try
				If ChangeMinimumPeriodOfTotals And ChangeMaximumPeriodOfTotals Then
					AccountingRegisters.International.SetMinAndMaxTotalsPeriods(
						ReflectionParametersInInternationalAccounting.MinimumPeriodOfTotals,
						ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals);
				ElsIf ChangeMinimumPeriodOfTotals Then
					AccountingRegisters.International.SetMinTotalsPeriod(
						ReflectionParametersInInternationalAccounting.MinimumPeriodOfTotals);
				ElsIf ChangeMaximumPeriodOfTotals Then
					AccountingRegisters.International.SetMaxTotalsPeriod(
						ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals);
				EndIf;
				Break;
			Except
				If AttemptNumber = NumberOfAttemptsToRestoreTotals Then
					WriteLogEvent(
						NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						AccountingRegistersMetadata.International.Name,,
						NStr("vi = 'Đã khôi phục kỳ tổng số lưu lại sau khi phản ánh bị lỗi.';
							|ru = 'Восстановление хранимых периодов итогов после отражения завершилось с ошибкой.';
							|en = 'An error occurred when restoring stored total periods after recording.'; fa = 'An error occurred when restoring stored total periods after recording.';
							|it = 'Восстановление хранимых периодов итогов после отражения завершилось с ошибкой.';
							|pl = 'An error occurred when restoring stored total periods after recording.';
							|tr = 'Yansıma başarısız olduktan sonra saklanan toplam dönemlerin geri yüklenmesi.'")
							+ Chars.LF + DetailErrorDescription(ErrorInfo()));
				EndIf;
			EndTry;
		EndDo;
	EndIf;
	
	MinimumPeriodOfTotals = AccountingRegisters.InternationalWithoutCorrespondence.GetMinTotalsPeriod();
	MaximumPeriodOfTotals = AccountingRegisters.InternationalWithoutCorrespondence.GetTotalsPeriod();
	
	ChangeMinimumPeriodOfTotals = MinimumPeriodOfTotals < ReflectionParametersInInternationalAccounting.MinimumPeriodOfTotals;
	ChangeMaximumPeriodOfTotals = MaximumPeriodOfTotals < ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals;
	
	If ChangeMinimumPeriodOfTotals Or ChangeMaximumPeriodOfTotals Then
		For AttemptNumber = 1 To NumberOfAttemptsToRestoreTotals Do
			Try
				If ChangeMinimumPeriodOfTotals And ChangeMaximumPeriodOfTotals Then
					AccountingRegisters.InternationalWithoutCorrespondence.SetMinAndMaxTotalsPeriods(
						ReflectionParametersInInternationalAccounting.MinimumPeriodOfTotals,
						ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals);
				ElsIf ChangeMinimumPeriodOfTotals Then
					AccountingRegisters.InternationalWithoutCorrespondence.SetMinTotalsPeriod(
						ReflectionParametersInInternationalAccounting.MinimumPeriodOfTotals);
				ElsIf ChangeMaximumPeriodOfTotals Then
					AccountingRegisters.InternationalWithoutCorrespondence.SetMaxTotalsPeriod(
						ReflectionParametersInInternationalAccounting.MaximumPeriodOfTotals);
				EndIf;
				Break;
			Except
				If AttemptNumber = NumberOfAttemptsToRestoreTotals Then
					WriteLogEvent(
						NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
						EventLogLevel.Error,
						AccountingRegistersMetadata.InternationalWithoutCorrespondence.Name,,
						NStr("vi = 'Đã khôi phục kỳ tổng số lưu lại sau khi phản ánh bị lỗi.';
							|ru = 'Восстановление хранимых периодов итогов после отражения завершилось с ошибкой.';
							|en = 'An error occurred when restoring stored total periods after recording.'; fa = 'An error occurred when restoring stored total periods after recording.';
							|it = 'Восстановление хранимых периодов итогов после отражения завершилось с ошибкой.';
							|pl = 'An error occurred when restoring stored total periods after recording.';
							|tr = 'Yansıma başarısız olduktan sonra saklanan toplam dönemlerin geri yüklenmesi.'")
							+ Chars.LF + DetailErrorDescription(ErrorInfo()));
				EndIf;
			EndTry;
		EndDo;
	EndIf;
	
EndProcedure

Function PortionManagementTable(ReflectionParametersInInternationalAccounting, PortionsOfDifferentTypes)
	
	ControlTable = New ValueTable();
	ControlTable.Columns.Add("PortionNumber", Common.TypeDescriptionNumber(5, 0));
	ControlTable.Columns.Add("DocumentTypes", New TypeDescription("Array"));
	ControlTable.Columns.Add("DocumentsCount", Common.TypeDescriptionNumber(10, 0));
	ControlTable.Columns.Add("NumberOfTransactions_", Common.TypeDescriptionNumber(15, 0));
	ControlTable.Columns.Add("BatchesCount", Common.TypeDescriptionNumber(10, 0));
	ControlTable.Columns.Add("InitialMomentOfTime", New TypeDescription("PointInTime"));
	ControlTable.Columns.Add("EndPointOfTime", New TypeDescription("PointInTime"));
	ControlTable.Columns.Add("LastBatch", New TypeDescription("Boolean"));
	
	ForecastParameters = ReflectionParametersInInternationalAccounting.ForecastParameters;
	
	If ForecastParameters.DocumentsCount = 0 Then
	ElsIf PortionsOfDifferentTypes Then
		For Each TypeParameters In ForecastParameters.ByDocumentType Do
			AddNewRow = True;
			
			If TypeParameters.NumberOfTransactions_ < ForecastParameters.TransactionsPerServing Then
				For Each PortionParameters In ControlTable Do
					If (PortionParameters.NumberOfTransactions_ + TypeParameters.NumberOfTransactions_) <= ForecastParameters.TransactionsPerServing Then
						PortionParameters.DocumentsCount = PortionParameters.DocumentsCount + TypeParameters.DocumentsCount;
						PortionParameters.NumberOfTransactions_ = PortionParameters.NumberOfTransactions_ + TypeParameters.NumberOfTransactions_;
						PortionParameters.DocumentTypes.Add(TypeParameters.DocumentType);
						AddNewRow = False;
						Break;
					EndIf;
				EndDo;
			EndIf;
			
			If AddNewRow Then
				PortionParameters = ControlTable.Add();
				FillPropertyValues(PortionParameters, TypeParameters);
				PortionParameters.DocumentTypes.Add(TypeParameters.DocumentType);
				PortionParameters.BatchesCount = 1 + Int(PortionParameters.NumberOfTransactions_ / ForecastParameters.TransactionsPerServing);
			EndIf;
		EndDo;
		
		ControlTable.Sort("NumberOfTransactions_ DESC");
	Else
		PortionParameters = ControlTable.Add();
		FillPropertyValues(PortionParameters, ForecastParameters);
	EndIf;
	
	TMCommonUse.AddRowIDToTable(ControlTable, "PortionNumber");
	
	Return ControlTable;
	
EndFunction

Function FlowControlTable()
	
	ControlTable = New ValueTable();
	ControlTable.Columns.Add("PortionNumber", Common.TypeDescriptionNumber(5, 0));
	ControlTable.Columns.Add("InitialMomentOfTime", New TypeDescription("PointInTime"));
	ControlTable.Columns.Add("EndPointOfTime", New TypeDescription("PointInTime"));
	ControlTable.Columns.Add("DocumentTypes", New TypeDescription("Array"));
	ControlTable.Columns.Add("Documents", New TypeDescription("Array"));
	ControlTable.Columns.Add("Id", New TypeDescription("UUID"));
	ControlTable.Columns.Add("ResultAddress", Common.StringTypeDetails(100));
	ControlTable.Columns.Add("AttemptsNumber", Common.TypeDescriptionNumber(3, 0));
	
	Return ControlTable;
	
EndFunction

Function DocumentsToBeReflectedInAccounting(ReflectionParametersInInternationalAccounting, ParametersForGeneratingTransactions, PortionParameters)
	
	PortionFormation = TypeOf(PortionParameters) = Type("ValueTableRow");
	GeneratePostings = ParametersForGeneratingTransactions <> Undefined;
	
	Query = New Query();
	
	If GeneratePostings Then
		Query.TempTablesManager = ParametersForGeneratingTransactions.TempTablesManager;
	EndIf;
	
	Query.Text = "
	|SELECT TOP 1000
	|	ReflectionOfDocumentsInAccounting.PointInTime AS PointInTime,
	|	1 AS Count
	|INTO PointsInTime
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionOfDocumentsInAccounting
	|	LEFT JOIN DocumentVerificationOverridable AS DocumentVerificationOverridable
	|		ON ReflectionOfDocumentsInAccounting.Recorder = DocumentVerificationOverridable.Document
	|		 AND ReflectionOfDocumentsInAccounting.Organization = DocumentVerificationOverridable.Organization
	|		 AND &ReflectOnlyVerifiedDocumentsInAccounting
	|WHERE
	|	ReflectionOfDocumentsInAccounting.DateRecord <= &EndDate
	|	AND &SelectionByInitialMomentOfTime
	|	AND &EndTimeSelection
	|	AND &FilterByDocumentType
	|	AND &FilterByDocuments
	|	AND &FilterByCompanies
	|	AND &SelectionByReflectionStatuses
	|	AND &DocumentVerified
	|GROUP BY
	|	ReflectionOfDocumentsInAccounting.PointInTime";
	
	DocumentVerificationServer.OverrideVerificationStatusInRequestTextTakingIntoAccountExceptions(Query.Text, "ReflectionOfDocumentsInAccounting.Recorder");
	
	If PortionFormation Then
		Query.Text = Query.Text + "
		|ORDER BY
		|	ReflectionOfDocumentsInAccounting.PointInTime";
	EndIf;
	
	Query.Text = Query.Text + Common.QueryBatchSeparator();
	
	If GeneratePostings Then
		QueryText = "
		|SELECT
		|	ReflectionOfDocumentsInAccounting.Period AS Period,
		|	ReflectionOfDocumentsInAccounting.Recorder AS Recorder,
		|	ReflectionOfDocumentsInAccounting.ChartOfAccounts AS ChartOfAccounts,
		|	ReflectionOfDocumentsInAccounting.Organization AS Organization,
		|	ReflectionOfDocumentsInAccounting.DateRecord AS DateRecord,
		|	ReflectionOfDocumentsInAccounting.StatusID AS StatusID,
		|	MAX(FinancialAccountingChartsOfAccountsForCompanies.Period) AS PeriodForSettingUpTransactionGeneration
		|INTO DocumentsTable
		|FROM
		|	InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionOfDocumentsInAccounting
		|	INNER JOIN PointsInTime AS PointsInTime
		|		ON ReflectionOfDocumentsInAccounting.PointInTime = PointsInTime.PointInTime
		|	LEFT JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
		|		ON ReflectionOfDocumentsInAccounting.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
		|		 AND ReflectionOfDocumentsInAccounting.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
		|		 AND ReflectionOfDocumentsInAccounting.DateRecord >= FinancialAccountingChartsOfAccountsForCompanies.Period
		|	LEFT JOIN DocumentVerificationOverridable AS DocumentVerificationOverridable
		|		ON ReflectionOfDocumentsInAccounting.Recorder = DocumentVerificationOverridable.Document
		|		 AND ReflectionOfDocumentsInAccounting.Organization = DocumentVerificationOverridable.Organization
		|		 AND &ReflectOnlyVerifiedDocumentsInAccounting
		|WHERE
		|	ReflectionOfDocumentsInAccounting.DateRecord <= &EndDate
		|	AND &FilterByCompanies
		|	AND &SelectionByReflectionStatuses
		|	AND &DocumentVerified
		|GROUP BY
		|	ReflectionOfDocumentsInAccounting.Period,
		|	ReflectionOfDocumentsInAccounting.Recorder,
		|	ReflectionOfDocumentsInAccounting.ChartOfAccounts,
		|	ReflectionOfDocumentsInAccounting.Organization,
		|	ReflectionOfDocumentsInAccounting.DateRecord,
		|	ReflectionOfDocumentsInAccounting.StatusID
		|INDEX BY
		|	ChartOfAccounts,
		|	Organization,
		|	PeriodForSettingUpTransactionGeneration
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsTable.Period AS Period,
		|	DocumentsTable.Recorder AS Recorder,
		|	DocumentsTable.ChartOfAccounts AS ChartOfAccounts,
		|	DocumentsTable.Organization AS Organization,
		|	DocumentsTable.DateRecord AS DateRecord,
		|	DocumentsTable.StatusID AS StatusID,
		|	ISNULL(FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting, UNDEFINED) AS PostingGenerationSetting
		|INTO DocumentsToBeReflected
		|FROM
		|	DocumentsTable AS DocumentsTable
		|	LEFT JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
		|		ON DocumentsTable.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
		|		 AND DocumentsTable.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
		|		 AND DocumentsTable.PeriodForSettingUpTransactionGeneration = FinancialAccountingChartsOfAccountsForCompanies.Period
		|INDEX BY
		|	Recorder,
		|	ChartOfAccounts,
		|	Organization,
		|	DateRecord
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|DROP DocumentsTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
		|	DocumentsToBeReflected.ChartOfAccounts.TransactionsWithCorrespondence AS TransactionsWithCorrespondence,
		|	DocumentsToBeReflected.ChartOfAccounts.TransactionsWithoutCorrespondence AS TransactionsWithoutCorrespondence
		|FROM
		|	DocumentsToBeReflected AS DocumentsToBeReflected
		|GROUP BY
		|	DocumentsToBeReflected.ChartOfAccounts
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	AccountingRegister.International AS InternationalWithCorrespondence
		|WHERE
		|	TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			DocumentsToBeReflected AS DocumentsToBeReflected
		|		WHERE
		|			DocumentsToBeReflected.Recorder = InternationalWithCorrespondence.Recorder
		|			AND DocumentsToBeReflected.ChartOfAccounts = InternationalWithCorrespondence.ChartOfAccounts
		|			AND DocumentsToBeReflected.Organization = InternationalWithCorrespondence.Organization
		|			AND InternationalWithCorrespondence.ChartOfAccounts.TransactionsWithoutCorrespondence
		|		)
		|
		|UNION ALL
		|
		|SELECT TOP 1
		|	TRUE
		|FROM
		|	AccountingRegister.InternationalWithoutCorrespondence AS InternationalWithoutCorrespondence
		|WHERE
		|	TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			DocumentsToBeReflected AS DocumentsToBeReflected
		|		WHERE
		|			DocumentsToBeReflected.Recorder = InternationalWithoutCorrespondence.Recorder
		|			AND DocumentsToBeReflected.ChartOfAccounts = InternationalWithoutCorrespondence.ChartOfAccounts
		|			AND DocumentsToBeReflected.Organization = InternationalWithoutCorrespondence.Organization
		|			AND InternationalWithoutCorrespondence.ChartOfAccounts.TransactionsWithCorrespondence
		|		)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DocumentsToBeReflected.Recorder AS Recorder,
		|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
		|	DocumentsToBeReflected.Organization AS Organization,
		|	DocumentsToBeReflected.DateRecord AS DateRecord,
		|	DocumentsToBeReflected.StatusID AS StatusID
		|FROM
		|	DocumentsToBeReflected AS DocumentsToBeReflected
		|TOTALS
		|BY
		|	Recorder
		|;
		|////////////////////////////////////////////////////////////////////////////////";
		DocumentVerificationServer.OverrideVerificationStatusInRequestTextTakingIntoAccountExceptions(QueryText, "ReflectionOfDocumentsInAccounting.Recorder");
		Query.Text = Query.Text + QueryText;
	EndIf;
	
	If PortionFormation Then
		Query.Text = Query.Text + "
		|SELECT TOP 1111
		|	PointsInTime.PointInTime AS PointInTime
		|FROM
		|	PointsInTime AS PointsInTime
		|ORDER BY
		|	PointsInTime.PointInTime DESC
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	SUM(PointsInTime.Count) AS Count
		|FROM
		|	PointsInTime AS PointsInTime
		|HAVING
		|	SUM(PointsInTime.Count) = &DocumentsCount
		|;
		|////////////////////////////////////////////////////////////////////////////////";
	EndIf;

	Query.Text = Query.Text + "
	|DROP PointsInTime
	|";
	
	If PortionFormation Then
		If Not GeneratePostings And TypeOf(ReflectionParametersInInternationalAccounting.Documents) = Type("Array") Then
			Top1111 = "";
		Else
			Top1111 = "TOP 1";//@Query-part-1
		EndIf;
		Query.Text = StrReplace(Query.Text, "TOP 1111", Top1111);//@Query-part-1
		
		DocumentsPerServing = PortionParameters.DocumentsCount / PortionParameters.BatchesCount;
		RoundUpPortionTo = Min(10, Int(DocumentsPerServing / 10) + 1);
		DocumentsPerServing = RoundUpPortionTo * (Int(DocumentsPerServing / RoundUpPortionTo) + 1);
		
		Top1000 = "TOP " + Format(DocumentsPerServing, "NFD=0; NG=0");//@Query-part-1
		SelectionByInitialMomentOfTime = "ReflectionOfDocumentsInAccounting.PointInTime > &PointInTime";
		EndTimeSelection = "TRUE";
		
		Query.SetParameter("DocumentsCount", DocumentsPerServing);
		Query.SetParameter("PointInTime", PortionParameters.EndPointOfTime);
	ElsIf GeneratePostings Then
		Top1000 = "";
		SelectionByInitialMomentOfTime = "ReflectionOfDocumentsInAccounting.PointInTime > &InitialMomentOfTime";
		EndTimeSelection = "ReflectionOfDocumentsInAccounting.PointInTime <= &EndPointOfTime"; 
		
		Query.SetParameter("InitialMomentOfTime", PortionParameters.InitialMomentOfTime);
		Query.SetParameter("EndPointOfTime", PortionParameters.EndPointOfTime);
	EndIf;
	
	If PortionParameters.DocumentTypes.Count() > 0 Then
		FilterByDocumentType = "VALUETYPE(ReflectionOfDocumentsInAccounting.Recorder) IN (&DocumentTypes)";
		Query.SetParameter("DocumentTypes", PortionParameters.DocumentTypes);
	Else
		FilterByDocumentType = "TRUE";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "TOP 1000", Top1000);//@Query-part-1
	Query.Text = StrReplace(Query.Text, "&SelectionByInitialMomentOfTime", SelectionByInitialMomentOfTime);
	Query.Text = StrReplace(Query.Text, "&EndTimeSelection", EndTimeSelection);
	Query.Text = StrReplace(Query.Text, "&FilterByDocumentType", FilterByDocumentType);
	
	SetSelectionOfDocumentsByReflectionParameters(Query, ReflectionParametersInInternationalAccounting);
	
	Results = Query.ExecuteBatch();
	MaxIndex_ = Results.UBound();
	
	If PortionFormation Then
		ResultIsMomentInTime = Results[MaxIndex_ - 2];
		ResultIsFullPortion = Results[MaxIndex_ - 1];
		
		SamplingPointInTime = ResultIsMomentInTime.Select();
		If SamplingPointInTime.Next() Then
			EndPointOfTime = SamplingPointInTime.PointInTime;
		Else
			EndPointOfTime = PortionParameters.EndPointOfTime;
		EndIf;
		
		PortionParameters.InitialMomentOfTime = PortionParameters.EndPointOfTime;
		PortionParameters.EndPointOfTime = EndPointOfTime;
		PortionParameters.LastBatch = ResultIsFullPortion.IsEmpty();
		
		DocumentsToBeReflectedInAccounting = SamplingPointInTime;
		DocumentsToBeReflectedInAccounting.Reset();
		
		IndexOffset = 3;
	Else
		IndexOffset = 1;
	EndIf;
	
	If GeneratePostings Then
		ResultAccountPlans = Results[MaxIndex_ - IndexOffset - 2];
		ResultInvalidTransactions = Results[MaxIndex_ - IndexOffset - 1];
		ResultDocumentsToBeReflected = Results[MaxIndex_ - IndexOffset];
		
		ReflectionParametersInInternationalAccounting.AccountPlansWithCorrespondence.Clear();
		ReflectionParametersInInternationalAccounting.AccountPlansWithoutCorrespondence.Clear();
		
		SampleAccountPlans = ResultAccountPlans.Select();
		While SampleAccountPlans.Next() Do
			If SampleAccountPlans.TransactionsWithCorrespondence Then
				ReflectionParametersInInternationalAccounting.AccountPlansWithCorrespondence.Add(SampleAccountPlans.ChartOfAccounts);
			EndIf;
			If SampleAccountPlans.TransactionsWithoutCorrespondence Then
				ReflectionParametersInInternationalAccounting.AccountPlansWithoutCorrespondence.Add(SampleAccountPlans.ChartOfAccounts);
			EndIf;
		EndDo;
		
		If Not ResultInvalidTransactions.IsEmpty() Then
			If ReflectionParametersInInternationalAccounting.AccountPlansWithCorrespondence.Count() = 0 Then
				ReflectionParametersInInternationalAccounting.AccountPlansWithCorrespondence.Add(Catalogs.FinancialAccountingChartsOfAccounts.EmptyRef());
			EndIf;
			If ReflectionParametersInInternationalAccounting.AccountPlansWithoutCorrespondence.Count() = 0 Then
				ReflectionParametersInInternationalAccounting.AccountPlansWithoutCorrespondence.Add(Catalogs.FinancialAccountingChartsOfAccounts.EmptyRef());
			EndIf;
		EndIf;
		
		DocumentsToBeReflectedInAccounting = ResultDocumentsToBeReflected.Select(QueryResultIteration.ByGroups);
	EndIf;
	
	Return DocumentsToBeReflectedInAccounting;
	
EndFunction

Procedure SetSelectionOfDocumentsByReflectionParameters(Query, ReflectionParametersInInternationalAccounting)
	
	If ValueIsFilled(ReflectionParametersInInternationalAccounting.Documents) Then
		FilterByDocuments = "ReflectionOfDocumentsInAccounting.Recorder IN (&Documents)";
		Query.SetParameter("Documents", ReflectionParametersInInternationalAccounting.Documents);
	Else
		FilterByDocuments = "TRUE";
	EndIf;
	
	If ValueIsFilled(ReflectionParametersInInternationalAccounting.Companies) Then
		FilterByCompanies = "ReflectionOfDocumentsInAccounting.Organization IN (&Companies)";
		Query.SetParameter("Companies",  ReflectionParametersInInternationalAccounting.Companies);
	Else
		FilterByCompanies = "TRUE";
	EndIf;
	
	If ReflectionParametersInInternationalAccounting.CheckREFLECTIONStatus Then
		SelectionByReflectionStatuses = "ReflectionOfDocumentsInAccounting.Status IN (
			|	VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting),
			|	VALUE(Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined))";
	Else
		SelectionByReflectionStatuses = "TRUE";
	EndIf;
	
	If Not ValueIsFilled(ReflectionParametersInInternationalAccounting.Documents)
		And GetFunctionalOption("UseFinancialDocumentVerification")
		And GetFunctionalOption("ReflectOnlyVerifiedDocumentsInInternationalAccounting") Then
		DocumentVerified = "ISNULL(DocumentVerificationOverridable.CheckStatus, VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)) 
			|	= VALUE(Enum.StatusOfFinancialDocumentVerification.Verified)";
	Else
		DocumentVerified = "TRUE";
	EndIf;
	
	Query.Text = StrReplace(Query.Text, "&FilterByDocuments", FilterByDocuments);
	Query.Text = StrReplace(Query.Text, "&FilterByCompanies", FilterByCompanies);
	Query.Text = StrReplace(Query.Text, "&SelectionByReflectionStatuses", SelectionByReflectionStatuses);
	Query.Text = StrReplace(Query.Text, "&DocumentVerified", DocumentVerified);
	
	Query.SetParameter("ReflectOnlyVerifiedDocumentsInAccounting",
		GetFunctionalOption("ReflectOnlyVerifiedDocumentsInInternationalAccounting"));
	
	Query.SetParameter("EndDate", ?(
		ReflectionParametersInInternationalAccounting.EndDate <> '00010101',
		ReflectionParametersInInternationalAccounting.EndDate,
		'39991231235959'));
	
EndProcedure

Procedure SupplementParametersOfSinglePortion(PortionParameters)
	
	PortionParameters.EndPointOfTime = New PointInTime('39991231235959');
	PortionParameters.LastBatch = True;
	
EndProcedure

Function ReflectPortionOfDocumentsWithCurFLOW(DocumentsToBeReflectedInAccounting, ReflectionParametersInInternationalAccounting, ParametersForGeneratingTransactions)
	
	For AttemptNumber = 1 To ReflectionParametersInInternationalAccounting.AttemptsNumber Do
		Try
			TableOfTransactions = ReflectPortionOfDocuments(DocumentsToBeReflectedInAccounting, ReflectionParametersInInternationalAccounting, ParametersForGeneratingTransactions);
			Break;
		Except
			If AttemptNumber < ReflectionParametersInInternationalAccounting.AttemptsNumber Then
				DestroyTemporaryTables(ParametersForGeneratingTransactions.TempTablesManager, True);
			Else
				Raise;
			EndIf;
		EndTry;
	EndDo;
	
	Return TableOfTransactions;
	
EndFunction

Procedure StartReflectingPortionsOfDocumentsWithNewStream(ReflectionParametersInInternationalAccounting, StreamParameters, ThisIsLastPortion)
	
	ReflectionParameters = ReflectionParametersInInternationalAccounting();
	FillPropertyValues(ReflectionParameters, ReflectionParametersInInternationalAccounting,
		"Companies,EndDate,ToRecordTransactions,PerformRecalculations,CheckREFLECTIONStatus");
	
	If StreamParameters.Documents.Count() > 0 Then
		ReflectionParameters.Documents = StreamParameters.Documents;
	EndIf;
	
	PortionParameters = New Structure("InitialMomentOfTime,EndPointOfTime,DocumentTypes");
	FillPropertyValues(PortionParameters, StreamParameters);
	
	If Not ReflectionParametersInInternationalAccounting.ToRecordTransactions Then
		StorageAddress = PutToTempStorage(Undefined);
		StreamParameters.ResultAddress = StorageAddress;
	Else
		StorageAddress = "";
	EndIf;
	
	If ThisIsLastPortion Then
		For AttemptNumber = 1 To ReflectionParametersInInternationalAccounting.AttemptsNumber Do
			Try
				ReflectPortionOfDocumentsWithNewStream(ReflectionParameters, PortionParameters, StorageAddress);
				Break;
			Except
				If AttemptNumber = ReflectionParametersInInternationalAccounting.AttemptsNumber Then
					Raise;
				EndIf;
			EndTry;
		EndDo;
	Else
		MethodName = "FinancialAccountingPostingServer.ReflectPortionOfDocumentsWithNewStream";
		Description = NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
							|ru = 'Отражение документов в международном учете';
							|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
							|it = 'Visualizzazione dei documenti in contabilità internazionale';
							|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
							|tr = 'Finansal muhasebede belge kaydı'");
		
		ExecutionParameters = New Array();
		ExecutionParameters.Add(ReflectionParameters);
		ExecutionParameters.Add(PortionParameters);
		ExecutionParameters.Add(StorageAddress);
		
		NewJob = BackgroundJobs.Execute(MethodName, ExecutionParameters,, Description);
		StreamParameters.Id = NewJob.UUID;
		StreamParameters.AttemptsNumber = StreamParameters.AttemptsNumber + 1;
	EndIf;
	
EndProcedure

Procedure ReflectPortionOfDocumentsWithNewStream(ReflectionParametersInInternationalAccounting, PortionParameters, StorageAddress) Export
	
	SetPrivilegedMode(True);
	
	ParametersForGeneratingTransactions = ParametersForGeneratingTransactions(ReflectionParametersInInternationalAccounting);
	
	DocumentsToBeReflectedInAccounting = DocumentsToBeReflectedInAccounting(
		ReflectionParametersInInternationalAccounting,
		ParametersForGeneratingTransactions,
		PortionParameters);
	
	TableOfTransactions = ReflectPortionOfDocuments(DocumentsToBeReflectedInAccounting, ReflectionParametersInInternationalAccounting, ParametersForGeneratingTransactions);
	
	If Not ReflectionParametersInInternationalAccounting.ToRecordTransactions Then
		PutToTempStorage(TableOfTransactions, StorageAddress);
	EndIf;
	
EndProcedure

Function ReflectPortionOfDocuments(DocumentsToBeReflectedInAccounting, ReflectionParametersInInternationalAccounting, ParametersForGeneratingTransactions)
	
	TableOfTransactions = TableOfTransactions();
	
	FinancialAccountingUponOperationalAccountingData.Reflect(ParametersForGeneratingTransactions, TableOfTransactions);
	FinancialAccountingByFinancialRegisterData.Reflect(ParametersForGeneratingTransactions, TableOfTransactions);
	FinancialAccountingUponLocalAccounting.Reflect(ParametersForGeneratingTransactions, TableOfTransactions);
	FinancialAccountingUponDocumentData.Reflect(ParametersForGeneratingTransactions, TableOfTransactions);
	
	RecalculateTableOfTransactionsAtRate(ParametersForGeneratingTransactions, TableOfTransactions);
	CollapseTransactionTable(ParametersForGeneratingTransactions, TableOfTransactions);
	DeleteTransactionsWithoutAmountsAndQuantities(ParametersForGeneratingTransactions, TableOfTransactions);
	RemoveInsignificantTransactions(ParametersForGeneratingTransactions, TableOfTransactions);
	
	AddTransactionsReverse(ParametersForGeneratingTransactions, TableOfTransactions);
	AddEntriesByOtherCompaniesPeriods(ReflectionParametersInInternationalAccounting, ParametersForGeneratingTransactions, TableOfTransactions);
	
	If ReflectionParametersInInternationalAccounting.ToRecordTransactions Then
		DocumentsToBeReflectedInAccounting.Reset();
		RecordTransactions(TableOfTransactions,
			DocumentsToBeReflectedInAccounting,
			ReflectionParametersInInternationalAccounting,
			ParametersForGeneratingTransactions);
		ReturnReverseDocumentsToReflection(ParametersForGeneratingTransactions);
		TableOfTransactions.Clear();
	EndIf;
	
	Return TableOfTransactions;
	
EndFunction

Procedure WaitFORReflectionStreamsTOEnd(ReflectionParametersInInternationalAccounting,
	FlowControlTable, TableOfTransactions, EndOfAllThreads)
	
	Timeout = 60;
	ActiveTasks = New Array();
	EmergencyTasks = New Array();
	CompletedTasks = New Array();
	
	For Each StreamParameters In FlowControlTable Do
		BackgroundJob = BackgroundJobs.FindByUUID(StreamParameters.Id);
		If BackgroundJob = Undefined Then
			EmergencyTasks.Add(StreamParameters.Id);
		ElsIf BackgroundJob.State = BackgroundJobState.Active Then
			ActiveTasks.Add(BackgroundJob);
		ElsIf BackgroundJob.State = BackgroundJobState.Completed Then
			CompletedTasks.Add(StreamParameters.Id);
		Else
			EmergencyTasks.Add(StreamParameters.Id);
		EndIf;
	EndDo;
	
	While (CompletedTasks.Count() = 0 Or EndOfAllThreads) And ActiveTasks.Count() > 0 Do
		ActiveTasks = BackgroundJobs.WaitForExecutionCompletion(ActiveTasks, Timeout);
		JobsCount = ActiveTasks.Count();
		
		For JobNumber = 1 To JobsCount Do
			ReverseIndex = JobsCount - JobNumber;
			BackgroundJob = ActiveTasks[ReverseIndex];
			
			If BackgroundJob.State <> BackgroundJobState.Active Then
				If BackgroundJob.State = BackgroundJobState.Completed Then
					CompletedTasks.Add(BackgroundJob.UUID);
				Else
					EmergencyTasks.Add(BackgroundJob.UUID);
				EndIf;
				ActiveTasks.Delete(ReverseIndex);
			EndIf;
		EndDo;
	EndDo;
	
	For Each Completed_Task In CompletedTasks Do
		StreamParameters = FlowControlTable.Find(Completed_Task, "Id");
		If StreamParameters <> Undefined Then
			If Not ReflectionParametersInInternationalAccounting.ToRecordTransactions Then
				PortionOfTransactions = GetFromTempStorage(StreamParameters.ResultAddress);
				CommonClientServer.SupplementTable(PortionOfTransactions, TableOfTransactions);
			EndIf;
			FlowControlTable.Delete(StreamParameters);
		EndIf;
	EndDo;
	
	If EmergencyTasks.Count() > 0 Then
		MessageTexts_ = New Array();
		
		For Each EmergencyJob In EmergencyTasks Do
			StreamParameters = FlowControlTable.Find(EmergencyJob, "Id");
			
			If StreamParameters = Undefined Then
			ElsIf StreamParameters.AttemptsNumber < ReflectionParametersInInternationalAccounting.AttemptsNumber Then
				StartReflectingPortionsOfDocumentsWithNewStream(ReflectionParametersInInternationalAccounting, StreamParameters, False);
			Else
				BackgroundJob = BackgroundJobs.FindByUUID(EmergencyJob);
				If BackgroundJob = Undefined Then
					MessageText = StrTemplate(NStr("vi = 'Không tìm thấy nhiệm vụ nền có tên định danh %1.';
													|ru = 'Фоновое задание с идентификатором %1 не найдено.';
													|en = 'A background job with the %1 ID is not found.'; fa = 'A background job with the %1 ID is not found.';
													|it = 'Фоновое задание с идентификатором %1 не найдено.';
													|pl = 'A background job with the %1 ID is not found.';
													|tr = '%1 kimliğine sahip arka plan işi bulunamadı.'"), EmergencyJob);
				ElsIf BackgroundJob.State = BackgroundJobState.Canceled Then
					MessageText = StrTemplate(NStr("vi = 'Người quản trị đã hủy nhiệm vụ nền có tên định danh %1.';
													|ru = 'Фоновое задание с идентификатором %1 отменено администратором.';
													|en = 'The background job with the %1 ID is canceled by the administrator.'; fa = 'The background job with the %1 ID is canceled by the administrator.';
													|it = 'Фоновое задание с идентификатором %1 отменено администратором.';
													|pl = 'The background job with the %1 ID is canceled by the administrator.';
													|tr = '%1 kimliğine sahip arka plan işi yönetici tarafından iptal edildi'"), EmergencyJob);
				ElsIf BackgroundJob.State = BackgroundJobState.Failed Then
					MessageText = StrTemplate(NStr("vi = 'Đã kết thúc bất thường nhiệm vụ nền có tên định danh %1.';
													|ru = 'Фоновое задание с идентификатором %1 завершено аварийно.';
													|en = 'The background job with the %1 ID crashed.'; fa = 'The background job with the %1 ID crashed.';
													|it = 'Фоновое задание с идентификатором %1 завершено аварийно.';
													|pl = 'The background job with the %1 ID crashed.';
													|tr = '%1 kimliğine sahip arka plan işi arızalı tamamlandı'"), EmergencyJob)
						+ Chars.LF + BriefErrorDescription(BackgroundJob.ErrorInfo);
				Else
					MessageText = StrTemplate(NStr("vi = 'Chưa thực hiện nhiệm vụ nền có tên định danh %1.';
													|ru = 'Фоновое задание с идентификатором %1 не выполнено.';
													|en = 'The background job with the %1 ID is not performed.'; fa = 'The background job with the %1 ID is not performed.';
													|it = 'Фоновое задание с идентификатором %1 не выполнено.';
													|pl = 'The background job with the %1 ID is not performed.';
													|tr = '%1 kimliğine sahip arka plan işi yürütülmedi'"), EmergencyJob);
				EndIf;
				
				MessageTexts_.Add(MessageText);
				
				If BackgroundJob = Undefined Or BackgroundJob.ErrorInfo = Undefined Then
					ErrorPresentation = MessageText;
				Else
					ErrorPresentation = StrTemplate(NStr("vi = 'Đã kết thúc bất thường nhiệm vụ nền có tên định danh %1.';
														|ru = 'Фоновое задание с идентификатором %1 завершено аварийно.';
														|en = 'The background job with the %1 ID crashed.'; fa = 'The background job with the %1 ID crashed.';
														|it = 'Фоновое задание с идентификатором %1 завершено аварийно.';
														|pl = 'The background job with the %1 ID crashed.';
														|tr = '%1 kimliğine sahip arka plan işi arızalı tamamlandı'"), EmergencyJob)
						+ Chars.LF + DetailErrorDescription(BackgroundJob.ErrorInfo);
				EndIf;
				
				WriteLogEvent(
					NStr("vi = 'Phản ánh các chứng từ vào kế toán quốc tế';
						|ru = 'Отражение документов в международном учете';
						|en = 'Record documents in financial accounting'; fa = 'Record documents in financial accounting';
						|it = 'Visualizzazione dei documenti in contabilità internazionale';
						|pl = 'Odzwierciedlenie dokumentów w ewidencji międzynarodowej';
						|tr = 'Finansal muhasebede belge kaydı'", Common.DefaultLanguageCode()),
					EventLogLevel.Error,,,
					ErrorPresentation);
			EndIf;
		EndDo;
		
		If MessageTexts_.Count() > 0 Then
			MessageTexts_.Insert(0, NStr("vi = 'Đã kết thúc phản ánh chứng từ vào kế toán quốc tế bị lỗi.';
										|ru = 'Отражение документов в международном учете завершилось с ошибкой.';
										|en = 'An error occurred when recording documents in financial accounting.'; fa = 'An error occurred when recording documents in financial accounting.';
										|it = 'Отражение документов в международном учете завершилось с ошибкой.';
										|pl = 'An error occurred when recording documents in financial accounting.';
										|tr = 'Belgelerin uluslararası muhasebede yansıtılması hata ile tamamlandı.'"));
			MessageText = StrConcat(CommonClientServer.CollapseArray(MessageTexts_), Chars.LF);
			Raise MessageText;
		ElsIf CompletedTasks.Count() = 0 Or EndOfAllThreads Then
			WaitFORReflectionStreamsTOEnd(ReflectionParametersInInternationalAccounting,
				FlowControlTable, TableOfTransactions, EndOfAllThreads);
		EndIf;
	EndIf;
	
EndProcedure

Procedure DestroyTemporaryTables(TempTablesManager, EmergencyEnd = False)
	
	TemporaryTableNames = New Array();
	NameOfDocumentTable = "DocumentsToBeReflected";
	
	If EmergencyEnd Then
		For Each TempTable In TempTablesManager.Tables Do
			TableName = TempTable.FullName;
			If TableName <> NameOfDocumentTable Then
				TemporaryTableNames.Add(TableName);
			EndIf;
		EndDo;
	Else
		TemporaryTableNames.Add(NameOfDocumentTable);
	EndIf;
	
	If TemporaryTableNames.Count() > 0 Then
		QueryStrings = New Array();
		
		For Each TableName In TemporaryTableNames Do
			QueryStrings.Add("DROP " + TableName);
		EndDo;
		
		Query = New Query();
		Query.TempTablesManager = TempTablesManager;
		Query.Text = StrConcat(QueryStrings, Common.QueryBatchSeparator());
		
		Query.Execute();
	EndIf;
	
EndProcedure

Procedure RecordTransactions(TableOfTransactions, DocumentsToBeReflectedInAccounting, ReflectionParameters, TransactionsParameters)
	
	TableOfTransactions.Indexes.Add("Recorder");
	
	SelectByAccountPlans = ReflectionParameters.AccountPlansWithCorrespondence.Count() > 0
		And ReflectionParameters.AccountPlansWithoutCorrespondence.Count() > 0;
	
	RegisterDimensions = New ValueTable();
	RegisterDimensions.Columns.Add("ChartOfAccounts");
	RegisterDimensions.Columns.Add("Organization");
	RegisterDimensions.Columns.Add("DateRecord");
	RegisterDimensions.Columns.Add("StatusID");
	
	While DocumentsToBeReflectedInAccounting.Next() Do
		Recorder = DocumentsToBeReflectedInAccounting.Recorder;
		RegisterDimensions.Clear();
		
		SamplingByDimensions = DocumentsToBeReflectedInAccounting.Select();
		While SamplingByDimensions.Next() Do
			NewRow = RegisterDimensions.Add();
			FillPropertyValues(NewRow, SamplingByDimensions);
		EndDo;
		
		DocumentTransactions = TableOfTransactions.Copy(New Structure("Recorder", Recorder));
		
		BeginTransaction();
		
		Try
		
			DataLock = New DataLock;
			LockItem = DataLock.Add("InformationRegister.DocumentPostingInFinancialAccounting.RecordSet");
			LockItem.SetValue("Recorder", Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();
		
			If Not UpdateDocumentReflectionStatus(Recorder, RegisterDimensions, DocumentTransactions) Then
				RollbackTransaction();
				Continue;
			EndIf;
			
			If ReflectionParameters.AccountPlansWithCorrespondence.Count() > 0 Then
				RecordedTransactions = RecordedTransactions(DocumentTransactions,
					ReflectionParameters.AccountPlansWithCorrespondence, SelectByAccountPlans);
				RecordDocumentTransactions(Recorder, RecordedTransactions, TransactionsParameters);
			EndIf;
			
			If ReflectionParameters.AccountPlansWithoutCorrespondence.Count() > 0 Then
				RecordedTransactions = RecordedTransactions(DocumentTransactions,
					ReflectionParameters.AccountPlansWithoutCorrespondence, SelectByAccountPlans);
				RecordDocumentTransactions(Recorder, RecordedTransactions, TransactionsParameters, True);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = NStr("vi = 'Không thể tạo bút toán kế toán quốc tế do nguyên nhân';
								|ru = 'Не удалось сформировать проводки международного учета по причине';
								|en = 'Cannot generate financial accounting entries. Reason:'; fa = 'Cannot generate financial accounting entries. Reason:';
								|it = 'Impossibile generare transazioni contabili internazionali per un motivo';
								|pl = 'Nie udało się utworzyć zaksięgowania ewidencji międzynarodowej z powodu';
								|tr = 'Bu sebepten dolayı uluslararası muhasebe girişleri oluşturulamadı'") + ":"
				+ Chars.LF + "%1";
			MessageText = StrTemplate(MessageText, DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Error, , MessageText);
			
			Raise MessageText;
			
		EndTry;
	EndDo;
	
EndProcedure

Procedure RecordDocumentTransactions(Recorder, TableOfTransactions, TransactionsParameters, WithoutCorrespondence = False)
	
	If WithoutCorrespondence Then
		RecordSet = AccountingRegisters.InternationalWithoutCorrespondence.CreateRecordSet();
		DeleteCorrespondenceTransactions(TableOfTransactions, TransactionsParameters);
	Else
		RecordSet = AccountingRegisters.International.CreateRecordSet();
	EndIf;
	
	RecordSet.Filter.Recorder.Set(Recorder);
	RecordSet.AdditionalProperties.Insert("WriteEmptySet", True);
	
	TableOfTransactions.Sort("ChartOfAccounts, ReversingEntry Desc, Period, Organization");
	
	For Each AccountingEntry In TableOfTransactions Do
		NewRecord = RecordSet.Add();
		FillPropertyValues(NewRecord, AccountingEntry);
		
		If WithoutCorrespondence Then
			RecordSet.InstallExtdimension(NewRecord, AccountingEntry);
		Else
			RecordSet.InstallExtdimension(NewRecord, AccountingEntry, "Dr");
			RecordSet.InstallExtdimension(NewRecord, AccountingEntry, "Cr");
		EndIf;
	EndDo;
	
	RecordSet.Write();
	
EndProcedure

Procedure RecalculateTableOfTransactionsAtRate(ReflectionParameters, TableOfTransactions)
	
	QueryText = "
	|SELECT
	|	TableOfTransactions.Period AS Period,
	|	BEGINOFPERIOD(TableOfTransactions.Period, DAY) AS TransactionDate,
	|	TableOfTransactions.Organization AS Organization,
	|	TableOfTransactions.ChartOfAccounts AS ChartOfAccounts,
	|	&SampleTextForOtherColumns,
	|	CASE WHEN TableOfTransactions.Sum = UNDEFINED
	|		THEN 0
	|		ELSE TableOfTransactions.Sum
	|	END AS Sum,
	|	CASE WHEN TableOfTransactions.PresentationAmount = UNDEFINED
	|		THEN 0
	|		ELSE TableOfTransactions.PresentationAmount
	|	END AS PresentationAmount,
	|	TableOfTransactions.CurrencyOfStorageOfAmount AS CurrencyOfStorageOfAmount,
	|	TableOfTransactions.PresentationAmountStorageCurrency AS PresentationAmountStorageCurrency,
	|	TableOfTransactions.CurrencyFunctional AS CurrencyFunctional,
	|	TableOfTransactions.PresentationCurrency AS PresentationCurrency
	|INTO TableOfTransactions
	|FROM
	|	&TableOfTransactions AS TableOfTransactions
	|
	|INDEX BY
	|	Period,
	|	CurrencyOfStorageOfAmount,
	|	PresentationAmountStorageCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	TableOfTransactions.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	TableOfTransactions.TransactionDate AS TransactionDate,
	|	TableOfTransactions.CurrencyOfStorageOfAmount AS CurrencyOfStorageOfAmount,
	|	TableOfTransactions.PresentationAmountStorageCurrency AS PresentationAmountStorageCurrency,
	|	TableOfTransactions.CurrencyFunctional AS CurrencyFunctional,
	|	TableOfTransactions.PresentationCurrency AS PresentationCurrency
	|INTO Currencies
	|FROM
	|	TableOfTransactions AS TableOfTransactions
	|WHERE
	|	(TableOfTransactions.CurrencyOfStorageOfAmount <> TableOfTransactions.CurrencyFunctional
	|			OR TableOfTransactions.PresentationAmountStorageCurrency <> TableOfTransactions.PresentationCurrency)
	|
	|INDEX BY
	|	TransactionDate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExchangeRates.LocalAccountingCurrency AS BaseCurrency,
	|	ExchangeRates.TransactionDate AS TransactionDate,
	|	ExchangeRates.Currency AS Currency,
	|	MAX(ExchangeRates.RatePeriod) AS RatePeriod
	|INTO ExchangeRatePeriods
	|FROM
	|	(SELECT
	|		Currencies.LocalAccountingCurrency AS LocalAccountingCurrency,
	|		Currencies.TransactionDate AS TransactionDate,
	|		Currencies.CurrencyOfStorageOfAmount AS Currency,
	|		ExchangeRates.Period AS RatePeriod
	|	FROM
	|		Currencies AS Currencies
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			ON Currencies.TransactionDate >= ExchangeRates.Period
	|				AND ExchangeRates.Currency = Currencies.CurrencyOfStorageOfAmount
	|				AND ExchangeRates.BaseCurrency = Currencies.LocalAccountingCurrency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Currencies.LocalAccountingCurrency AS LocalAccountingCurrency,
	|		Currencies.TransactionDate,
	|		Currencies.PresentationAmountStorageCurrency,
	|		ExchangeRates.Period
	|	FROM
	|		Currencies AS Currencies
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			ON Currencies.TransactionDate >= ExchangeRates.Period
	|				AND ExchangeRates.Currency = Currencies.PresentationAmountStorageCurrency
	|				AND ExchangeRates.BaseCurrency = Currencies.LocalAccountingCurrency
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Currencies.LocalAccountingCurrency AS LocalAccountingCurrency,
	|		Currencies.TransactionDate,
	|		Currencies.CurrencyFunctional,
	|		ExchangeRates.Period
	|	FROM
	|		Currencies AS Currencies
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			ON Currencies.TransactionDate >= ExchangeRates.Period
	|				AND ExchangeRates.Currency = Currencies.CurrencyFunctional
	|				AND ExchangeRates.BaseCurrency = Currencies.LocalAccountingCurrency
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Currencies.LocalAccountingCurrency AS LocalAccountingCurrency,
	|		Currencies.TransactionDate,
	|		Currencies.PresentationCurrency,
	|		ExchangeRates.Period
	|	FROM
	|		Currencies AS Currencies
	|			INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|			ON Currencies.TransactionDate >= ExchangeRates.Period
	|				AND ExchangeRates.Currency = Currencies.PresentationCurrency
	|				AND ExchangeRates.BaseCurrency = Currencies.LocalAccountingCurrency) AS ExchangeRates
	|
	|GROUP BY
	|	ExchangeRates.TransactionDate,
	|	ExchangeRates.Currency,
	|	ExchangeRates.LocalAccountingCurrency
	|
	|INDEX BY
	|	TransactionDate,
	|	Currency,
	|	BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ExchangeRatePeriods.BaseCurrency AS BaseCurrency,
	|	ExchangeRatePeriods.TransactionDate AS TransactionDate,
	|	ExchangeRatePeriods.Currency AS Currency,
	|	ExchangeRates.CourseNumerator AS CourseNumerator,
	|	ExchangeRates.CourseDenominator AS CourseDenominator
	|INTO ExchangeRates
	|FROM
	|	ExchangeRatePeriods AS ExchangeRatePeriods
	|		INNER JOIN InformationRegister.RelativeExchangeRates AS ExchangeRates
	|		ON ExchangeRatePeriods.RatePeriod = ExchangeRates.Period
	|			AND ExchangeRatePeriods.Currency = ExchangeRates.Currency
	|			AND ExchangeRatePeriods.BaseCurrency = ExchangeRates.BaseCurrency
	|
	|INDEX BY
	|	TransactionDate,
	|	Currency,
	|	BaseCurrency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MIN(CurrenciesWithoutExchangeRates.TransactionDate) AS TransactionDate,
	|	CurrenciesWithoutExchangeRates.BaseCurrency AS BaseCurrency,
	|	CurrenciesWithoutExchangeRates.Currency AS Currency
	|FROM
	|	(SELECT
	|		Currencies.TransactionDate AS TransactionDate,
	|		Currencies.LocalAccountingCurrency AS BaseCurrency,
	|		Currencies.CurrencyFunctional	AS Currency	
	|	FROM
	|		Currencies AS Currencies
	|		LEFT JOIN 
	|			ExchangeRatePeriods AS ExchangeRatePeriods
	|		ON
	|			Currencies.TransactionDate = ExchangeRatePeriods.TransactionDate 
	|			AND Currencies.CurrencyFunctional = ExchangeRatePeriods.Currency
	|			AND Currencies.LocalAccountingCurrency = ExchangeRatePeriods.BaseCurrency
	|	WHERE
	|		ExchangeRatePeriods.RatePeriod IS NULL
	|		AND Currencies.LocalAccountingCurrency <> Currencies.CurrencyFunctional
	|
	|	UNION ALL
	|
	|	SELECT
	|		Currencies.TransactionDate AS TransactionDate,
	|		Currencies.LocalAccountingCurrency AS BaseCurrency,
	|		Currencies.PresentationCurrency AS Currency	
	|	FROM
	|		Currencies AS Currencies
	|		LEFT JOIN 
	|			ExchangeRatePeriods AS ExchangeRatePeriods
	|		ON
	|			Currencies.TransactionDate = ExchangeRatePeriods.TransactionDate 
	|			AND Currencies.PresentationCurrency = ExchangeRatePeriods.Currency
	|			AND Currencies.LocalAccountingCurrency = ExchangeRatePeriods.BaseCurrency
	|	WHERE
	|		ExchangeRatePeriods.RatePeriod IS NULL
	|		AND Currencies.LocalAccountingCurrency <> Currencies.PresentationCurrency
	|
	|	UNION ALL
	|
	|	SELECT
	|		Currencies.TransactionDate AS TransactionDate,
	|		Currencies.LocalAccountingCurrency AS BaseCurrency,
	|		Currencies.CurrencyOfStorageOfAmount AS Currency	
	|	FROM
	|		Currencies AS Currencies
	|		LEFT JOIN 
	|			ExchangeRatePeriods AS ExchangeRatePeriods
	|		ON
	|			Currencies.TransactionDate = ExchangeRatePeriods.TransactionDate 
	|			AND Currencies.CurrencyOfStorageOfAmount = ExchangeRatePeriods.Currency
	|			AND Currencies.LocalAccountingCurrency = ExchangeRatePeriods.BaseCurrency
	|	WHERE
	|		ExchangeRatePeriods.RatePeriod IS NULL
	|		AND Currencies.LocalAccountingCurrency <> Currencies.CurrencyOfStorageOfAmount
	|
	|	UNION ALL
	|	
	|	SELECT
	|		Currencies.TransactionDate AS TransactionDate,
	|		Currencies.LocalAccountingCurrency AS BaseCurrency,
	|		Currencies.PresentationAmountStorageCurrency AS Currency	
	|	FROM
	|		Currencies AS Currencies
	|		LEFT JOIN 
	|			ExchangeRatePeriods AS ExchangeRatePeriods
	|		ON
	|			Currencies.TransactionDate = ExchangeRatePeriods.TransactionDate 
	|			AND Currencies.PresentationAmountStorageCurrency = ExchangeRatePeriods.Currency
	|			AND Currencies.LocalAccountingCurrency = ExchangeRatePeriods.BaseCurrency
	|	WHERE
	|		ExchangeRatePeriods.RatePeriod IS NULL
	|		AND Currencies.LocalAccountingCurrency <> Currencies.PresentationAmountStorageCurrency) AS CurrenciesWithoutExchangeRates
	|GROUP BY
	|	CurrenciesWithoutExchangeRates.BaseCurrency,
	|	CurrenciesWithoutExchangeRates.Currency
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfTransactions.Period AS Period,
	|	TableOfTransactions.Organization,
	|	TableOfTransactions.ChartOfAccounts,
	|	&SampleTextForOtherColumns,
	|	CAST(TableOfTransactions.Sum 
	|		* (ISNULL(ExchangeRatesAndAmountsOfMoney.CourseNumerator, 1) * ISNULL(FunctionalCurrencyRates.CourseDenominator, 1))
	|		/ (ISNULL(ExchangeRatesAndAmountsOfMoney.CourseDenominator, 1) *  ISNULL(FunctionalCurrencyRates.CourseNumerator, 1))
	|	AS NUMBER(&LengthOfSum, &SumAccuracy)) AS Sum,
	|	CAST(TableOfTransactions.PresentationAmount 
	|		* (ISNULL(CurrencyRatesAndPresentationAmounts.CourseNumerator, 1) * ISNULL(PresentationCurrencyRates.CourseDenominator, 1))
	|		/ (ISNULL(CurrencyRatesAndPresentationAmounts.CourseDenominator, 1) *  ISNULL(PresentationCurrencyRates.CourseNumerator, 1))
	|	AS NUMBER(&LengthOfSum, &SumAccuracy)) AS PresentationAmount,
	|	TableOfTransactions.CurrencyOfStorageOfAmount,
	|	TableOfTransactions.PresentationAmountStorageCurrency,
	|	TableOfTransactions.CurrencyFunctional,
	|	TableOfTransactions.PresentationCurrency
	|FROM
	|	TableOfTransactions AS TableOfTransactions
	|		LEFT JOIN ExchangeRates AS ExchangeRatesAndAmountsOfMoney
	|		ON TableOfTransactions.TransactionDate = ExchangeRatesAndAmountsOfMoney.TransactionDate
	|			AND TableOfTransactions.CurrencyOfStorageOfAmount = ExchangeRatesAndAmountsOfMoney.Currency
	|			AND TableOfTransactions.Organization.LocalAccountingCurrency = ExchangeRatesAndAmountsOfMoney.BaseCurrency
	|		LEFT JOIN ExchangeRates AS CurrencyRatesAndPresentationAmounts
	|		ON TableOfTransactions.TransactionDate = CurrencyRatesAndPresentationAmounts.TransactionDate
	|			AND TableOfTransactions.PresentationAmountStorageCurrency = CurrencyRatesAndPresentationAmounts.Currency
	|			AND TableOfTransactions.Organization.LocalAccountingCurrency = CurrencyRatesAndPresentationAmounts.BaseCurrency
	|		LEFT JOIN ExchangeRates AS FunctionalCurrencyRates
	|		ON TableOfTransactions.TransactionDate = FunctionalCurrencyRates.TransactionDate
	|			AND TableOfTransactions.CurrencyFunctional = FunctionalCurrencyRates.Currency
	|			AND TableOfTransactions.Organization.LocalAccountingCurrency = FunctionalCurrencyRates.BaseCurrency
	|		LEFT JOIN ExchangeRates AS PresentationCurrencyRates
	|		ON TableOfTransactions.TransactionDate = PresentationCurrencyRates.TransactionDate
	|			AND TableOfTransactions.PresentationCurrency  = PresentationCurrencyRates.Currency
	|			AND TableOfTransactions.Organization.LocalAccountingCurrency = PresentationCurrencyRates.BaseCurrency
	|
	|ORDER BY
	|	TableOfTransactions.ChartOfAccounts,
	|	TableOfTransactions.Organization,
	|	TableOfTransactions.Period";
	
	MoneyAmountQualifiers = Metadata.DefinedTypes.MonetaryAmountPositiveNegative.Type.NumberQualifiers;
	QueryText = StrReplace(QueryText, "&LengthOfSum", MoneyAmountQualifiers.Digits);
	QueryText = StrReplace(QueryText, "&SumAccuracy", MoneyAmountQualifiers.FractionDigits);
	
	StructureOfExceptionColumns = New Structure("PointInTime, Period, Sum, PresentationAmount, Organization, ChartOfAccounts,
	                                             |CurrencyOfStorageOfAmount, PresentationAmountStorageCurrency,
	                                             |CurrencyFunctional, PresentationCurrency");
	ArrayOfSelectionFields = New Array;
	For Each Column In TableOfTransactions.Columns Do
		If StructureOfExceptionColumns.Property(Column.Name) Then
			Continue;
		EndIf;
		ArrayOfSelectionFields.Add(StrTemplate("TableOfTransactions.%1", Column.Name));
	EndDo;
	QueryText = StrReplace(QueryText, "&SampleTextForOtherColumns", StrConcat(ArrayOfSelectionFields, "," + Chars.LF));
	
	Query = New Query(QueryText);
	Query.SetParameter("TableOfTransactions", TableOfTransactions);
	QueryResults = Query.ExecuteBatch();
	
	ErrorsArray = New Array;
	CourseVerificationResult = QueryResults[QueryResults.Count() - 2].Select();
	While CourseVerificationResult.Next() Do
		MessageText = StrTemplate(
						NStr("vi = 'Chưa xác định tỷ giá hối đoái %1 theo tiền tệ %2 tại %3.';
							|ru = 'Не определен курс валюты %1 относительно валюты %2 на %3.';
							|en = 'The %1 exchange rate relative to the %2 currency for %3 is not defined.'; fa = 'The %1 exchange rate relative to the %2 currency for %3 is not defined.';
							|it = 'Il tasso di cambio della valuta %1 verso la valuta %2 al %3 non è definito.';
							|pl = 'Nie określono kursu waluty %1 w stosunku do waluty %2 na %3.';
							|tr = '%1 para biriminin %3''teki %2 para birimine göre döviz kuru belirlenmedi.'"),
						CourseVerificationResult.Currency,
						CourseVerificationResult.BaseCurrency,
						Format(CourseVerificationResult.TransactionDate, "DLF=D"));
		ErrorsArray.Add(MessageText);
	EndDo;
	If ErrorsArray.Count() Then
		Raise StrConcat(ErrorsArray, Chars.LF);
	EndIf;
	
	TableOfTransactions = QueryResults[QueryResults.Count() - 1].Unload();
	
EndProcedure

Procedure AddEntriesByOtherCompaniesPeriods(ReflectionParameters, ParametersForGeneratingTransactions, TableOfTransactions)
	
	QueryText = "
	|SELECT
	|	ReflectionOfDocumentsInAccounting.Recorder AS Recorder,
	|	ReflectionOfDocumentsInAccounting.ChartOfAccounts AS ChartOfAccounts,
	|	ReflectionOfDocumentsInAccounting.Organization AS Organization,
	|	ReflectionOfDocumentsInAccounting.DateRecord AS DateRecord,
	|	ReflectionOfDocumentsInAccounting.ChartOfAccounts.TransactionsWithCorrespondence AS TransactionsWithCorrespondence,
	|	ReflectionOfDocumentsInAccounting.ChartOfAccounts.TransactionsWithoutCorrespondence AS TransactionsWithoutCorrespondence
	|INTO MultipleReflectionDocuments
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionOfDocumentsInAccounting
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			DocumentsToBeReflected AS DocumentsToBeReflected
	|		WHERE
	|			DocumentsToBeReflected.Recorder = ReflectionOfDocumentsInAccounting.Recorder
	|		)
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			DocumentsToBeReflected AS DocumentsToBeReflected
	|		WHERE
	|			DocumentsToBeReflected.Recorder = ReflectionOfDocumentsInAccounting.Recorder
	|			AND DocumentsToBeReflected.ChartOfAccounts = ReflectionOfDocumentsInAccounting.ChartOfAccounts
	|			AND DocumentsToBeReflected.Organization = ReflectionOfDocumentsInAccounting.Organization
	|			AND DocumentsToBeReflected.DateRecord = ReflectionOfDocumentsInAccounting.DateRecord
	|		)
	|INDEX BY
	|	Recorder,
	|	ChartOfAccounts,
	|	Organization,
	|	DateRecord,
	|	TransactionsWithCorrespondence,
	|	TransactionsWithoutCorrespondence
	|";
	
	If ReflectionParameters.AccountPlansWithCorrespondence.Count() > 0 Then
		QueryText = QueryText + Common.QueryBatchSeparator() + "
		|SELECT
		|	Postings.Period AS Period,
		|	Postings.Recorder AS Recorder,
		|	Postings.LineNumber AS LineNumber,
		|	Postings.AccountDr AS AccountDr,
		|	Postings.AccountCr AS AccountCr,
		|	Postings.ChartOfAccounts AS ChartOfAccounts,
		|	Postings.Organization AS Organization,
		|	Postings.DepartmentDr AS DepartmentDr,
		|	Postings.DepartmentCr AS DepartmentCr,
		|	Postings.CurrencyDr AS CurrencyDr,
		|	Postings.CurrencyCr AS CurrencyCr,
		|	Postings.LineOfBusinessDr AS LineOfBusinessDr,
		|	Postings.LineOfBusinessCr AS LineOfBusinessCr,
		|	Postings.Sum AS Sum,
		|	Postings.PresentationAmount AS PresentationAmount,
		|	Postings.CurrencyAmountDr AS CurrencyAmountDr,
		|	Postings.CurrencyAmountCr AS CurrencyAmountCr,
		|	Postings.CountDr AS CountDr,
		|	Postings.CountCr AS CountCr,
		|	Postings.ExtDimensionDr1 AS ExtDimensionDr1,
		|	ISNULL(Postings.ExtDimensionTypeDr1, 
		|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr1,
		|	Postings.ExtDimensionDr2 AS ExtDimensionDr2,
		|	ISNULL(Postings.ExtDimensionTypeDr2, 
		|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr2,
		|	Postings.ExtDimensionDr3 AS ExtDimensionDr3,
		|	ISNULL(Postings.ExtDimensionTypeDr3, 
		|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr3,
		|	Postings.ExtDimensionCr1 AS ExtDimensionCr1,
		|	ISNULL(Postings.ExtDimensionTypeCr1, 
		|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr1,
		|	Postings.ExtDimensionCr2 AS ExtDimensionCr2,
		|	ISNULL(Postings.ExtDimensionTypeCr2, 
		|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr2,
		|	Postings.ExtDimensionCr3 AS ExtDimensionCr3,
		|	ISNULL(Postings.ExtDimensionTypeCr3, 
		|		VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr3,
		|	Postings.Content AS Content,
		|	Postings.PostingTemplate AS PostingTemplate,
		|	Postings.PostingType AS PostingType,
		|	Postings.AccountComplianceDr AS AccountComplianceDr,
		|	Postings.AccountComplianceCr AS AccountComplianceCr,
		|	Postings.EqualityOfTurnoverTotals AS EqualityOfTurnoverTotals,
		|	Postings.ReversingEntry AS ReversingEntry,
		|	Postings.FinRecordID AS FinRecordID,
		|	Postings.BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	AccountingRegister.International.RecordsWithExtDimensions(
		|		,
		|		,
		|		(Recorder, ChartOfAccounts, Organization) IN (
		|			SELECT
		|				DocumentsToBeReflected.Recorder,
		|				DocumentsToBeReflected.ChartOfAccounts,
		|				DocumentsToBeReflected.Organization
		|			FROM
		|				MultipleReflectionDocuments AS DocumentsToBeReflected
		|			WHERE
		|				DocumentsToBeReflected.TransactionsWithCorrespondence
		|		),
		|		,
		|	) AS Postings
		|WHERE
		|	TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			MultipleReflectionDocuments AS DocumentsToBeReflected
		|		WHERE
		|			
		|			DocumentsToBeReflected.Recorder = Postings.Recorder
		|			AND DocumentsToBeReflected.ChartOfAccounts = Postings.ChartOfAccounts
		|			AND DocumentsToBeReflected.Organization = Postings.Organization
		|			AND DocumentsToBeReflected.DateRecord = BEGINOFPERIOD(Postings.Period, DAY)
		|			AND DocumentsToBeReflected.TransactionsWithCorrespondence
		|		)
		|";
		
		If ReflectionParameters.AccountPlansWithoutCorrespondence.Count() > 0 Then
			QueryText = QueryText + "
			|UNION ALL
			|";
		EndIf;
	EndIf;
	
	If ReflectionParameters.AccountPlansWithoutCorrespondence.Count() > 0 Then
		If ReflectionParameters.AccountPlansWithCorrespondence.Count() = 0 Then
			QueryText = QueryText + Common.QueryBatchSeparator();
		EndIf;
		
		QueryText = QueryText + "
		|SELECT
		|	Postings.Period AS Period,
		|	Postings.Recorder AS Recorder,
		|	Postings.LineNumber AS LineNumber,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.Account
		|		ELSE VALUE(ChartOfAccounts.International.EmptyRef)
		|	END AS AccountDr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN VALUE(ChartOfAccounts.International.EmptyRef)
		|		ELSE Postings.Account
		|	END AS AccountCr,
		|	Postings.ChartOfAccounts AS ChartOfAccounts,
		|	Postings.Organization AS Organization,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.Department
		|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
		|	END AS DepartmentDr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
		|		ELSE Postings.Department
		|	END AS DepartmentCr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.Currency
		|		ELSE VALUE(Catalog.Currencies.EmptyRef)
		|	END AS CurrencyDr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN VALUE(Catalog.Currencies.EmptyRef)
		|		ELSE Postings.Currency
		|	END AS CurrencyCr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.LineOfBusiness
		|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|	END AS LineOfBusinessDr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
		|		ELSE Postings.LineOfBusiness
		|	END AS LineOfBusinessCr,
		|	Postings.Sum AS Sum,
		|	Postings.PresentationAmount AS PresentationAmount,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.CurrencyAmount
		|		ELSE 0
		|	END AS CurrencyAmountDr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN 0
		|		ELSE Postings.CurrencyAmount
		|	END AS CurrencyAmountCr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.Count
		|		ELSE 0
		|	END AS CountDr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN 0
		|		ELSE Postings.Count
		|	END AS CountCr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.ExtDimension1
		|		ELSE UNDEFINED
		|	END AS ExtDimensionDr1,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN ISNULL(Postings.ExtDimensionType1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
		|		ELSE VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
		|	END AS ExtDimensionTypeDr1,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.ExtDimension2
		|		ELSE UNDEFINED
		|	END AS ExtDimensionDr2,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN ISNULL(Postings.ExtDimensionType2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
		|		ELSE VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
		|	END AS ExtDimensionTypeDr2,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.ExtDimension3
		|		ELSE UNDEFINED
		|	END AS ExtDimensionDr3,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN ISNULL(Postings.ExtDimensionType3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
		|		ELSE VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
		|	END AS ExtDimensionTypeDr3,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN UNDEFINED
		|		ELSE Postings.ExtDimension1
		|	END AS ExtDimensionCr1,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
		|		ELSE ISNULL(Postings.ExtDimensionType1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
		|	END AS ExtDimensionTypeCr1,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN UNDEFINED
		|		ELSE Postings.ExtDimension2
		|	END AS ExtDimensionCr2,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
		|		ELSE ISNULL(Postings.ExtDimensionType2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
		|	END AS ExtDimensionTypeCr2,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN UNDEFINED
		|		ELSE Postings.ExtDimension3
		|	END AS ExtDimensionCr3,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
		|		ELSE ISNULL(Postings.ExtDimensionType3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
		|	END AS ExtDimensionTypeCr3,
		|	Postings.Content AS Content,
		|	Postings.PostingTemplate AS PostingTemplate,
		|	Postings.PostingType AS PostingType,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN Postings.AccountCompliance
		|		ELSE UNDEFINED
		|	END AS AccountComplianceDr,
		|	CASE
		|		WHEN Postings.RecordType = VALUE(AccountingRecordType.Debit)
		|			THEN UNDEFINED
		|		ELSE Postings.AccountCompliance
		|	END AS AccountComplianceCr,
		|	Postings.EqualityOfTurnoverTotals AS EqualityOfTurnoverTotals,
		|	Postings.ReversingEntry AS ReversingEntry,
		|	Postings.FinRecordID AS FinRecordID,
		|	Postings.BusinessTransactionSetting AS BusinessTransactionSetting
		|FROM
		|	AccountingRegister.InternationalWithoutCorrespondence.RecordsWithExtDimensions(
		|		,
		|		,
		|		(Recorder, ChartOfAccounts, Organization) IN (
		|			SELECT
		|				DocumentsToBeReflected.Recorder,
		|				DocumentsToBeReflected.ChartOfAccounts,
		|				DocumentsToBeReflected.Organization
		|			FROM
		|				MultipleReflectionDocuments AS DocumentsToBeReflected
		|			WHERE
		|				DocumentsToBeReflected.TransactionsWithoutCorrespondence
		|		),
		|		,
		|	) AS Postings
		|WHERE
		|	TRUE IN
		|		(SELECT TOP 1
		|			TRUE
		|		FROM
		|			MultipleReflectionDocuments AS DocumentsToBeReflected
		|		WHERE
		|			
		|			DocumentsToBeReflected.Recorder = Postings.Recorder
		|			AND DocumentsToBeReflected.ChartOfAccounts = Postings.ChartOfAccounts
		|			AND DocumentsToBeReflected.Organization = Postings.Organization
		|			AND DocumentsToBeReflected.DateRecord = BEGINOFPERIOD(Postings.Period, DAY)
		|			AND DocumentsToBeReflected.TransactionsWithoutCorrespondence
		|		)
		|";
	EndIf;
	
	QueryText = QueryText + Common.QueryBatchSeparator() + "
	|DROP MultipleReflectionDocuments
	|";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = ParametersForGeneratingTransactions.TempTablesManager;
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		AccountingEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
		FillPropertyValues(AccountingEntry, Selection);
		AddTransactionToTransactionTable(TableOfTransactions, AccountingEntry);
	EndDo;
	
EndProcedure

Procedure AddTransactionsReverse(ParametersForGeneratingTransactions, TableOfTransactions)
	
	Query = New Query;
	Query.TempTablesManager = ParametersForGeneratingTransactions.TempTablesManager;
	Query.Text = 
	"SELECT DISTINCT
	|	DocumentsToBeReflected.Period AS Period,
	|	DocumentsToBeReflected.Recorder AS Recorder,
	|	DocumentsToBeReflected.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsToBeReflected.Organization AS Organization,
	|	DocumentsRegistry.ReversedDocument AS ReversedDocument,
	|	DocumentsToBeReflected.ChartOfAccounts.TransactionsWithCorrespondence AS TransactionsWithCorrespondence,
	|	DocumentsToBeReflected.ChartOfAccounts.TransactionsWithoutCorrespondence AS TransactionsWithoutCorrespondence,
	|	NOT DocumentsToBeReflectedReversedDocument.Recorder IS NULL AS ReversedDocumentForReflection,
	|	CASE
	|		WHEN FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting IS NULL
	|			THEN FALSE
	|		WHEN FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting.MethodOfCancelingTransactions
	|			= VALUE(Enum.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ReplaceWithReverse
	|INTO DocumentsStorno
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|	INNER JOIN
	|		InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	ON 
	|		DocumentsToBeReflected.Recorder = DocumentsRegistry.Ref
	|		AND DocumentsRegistry.ReverseTransactionCorrection
	|		AND DocumentsRegistry.Posted
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|	
	|	LEFT JOIN
	|		DocumentsToBeReflected AS DocumentsToBeReflectedReversedDocument
	|	ON 
	|		DocumentsRegistry.ReversedDocument = DocumentsToBeReflectedReversedDocument.Recorder
	|		AND DocumentsToBeReflected.ChartOfAccounts = DocumentsToBeReflectedReversedDocument.ChartOfAccounts
	|		AND DocumentsToBeReflected.Organization = DocumentsToBeReflectedReversedDocument.Organization
	|
	|	LEFT JOIN
	|		InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	ON
	|		DocumentsToBeReflected.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
	|		AND DocumentsToBeReflected.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|WHERE
	|	BEGINOFPERIOD(DocumentsToBeReflected.Period, DAY) = DocumentsToBeReflected.DateRecord
	|	AND CASE
	|		WHEN FinancialAccountingChartsOfAccountsForCompanies.Period IS NULL
	|			THEN TRUE
	|		ELSE FinancialAccountingChartsOfAccountsForCompanies.Period IN
	|			(SELECT
	|				MAX(BusinessAccountPlans.Period)
	|			FROM
	|				InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS BusinessAccountPlans
	|			WHERE
	|				BusinessAccountPlans.ChartOfAccounts = DocumentsToBeReflected.ChartOfAccounts
	|				AND BusinessAccountPlans.Organization = DocumentsToBeReflected.Organization
	|				AND BusinessAccountPlans.Period <= DocumentsToBeReflected.DateRecord
	|			)
	|	END
	|
	|INDEX BY
	|	ReversedDocument,
	|	ChartOfAccounts,
	|	Organization,
	|	TransactionsWithCorrespondence,
	|	TransactionsWithoutCorrespondence,
	|	ReversedDocumentForReflection
	|;
	|
	|//////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentsStorno.Period AS Period,
	|	DocumentsStorno.Recorder AS Recorder,
	|	DocumentsStorno.ReplaceWithReverse AS ReplaceWithReverse,
	|	International.ChartOfAccounts AS ChartOfAccounts,
	|	International.Organization AS Organization,
	|	International.DepartmentDr AS DepartmentDr,
	|	International.CurrencyDr AS CurrencyDr,
	|	International.LineOfBusinessDr AS LineOfBusinessDr,
	|	International.AccountDr AS AccountDr,
	|	ISNULL(International.ExtDimensionTypeDr1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr1, 
	|	International.ExtDimensionDr1 AS ExtDimensionDr1,
	|	ISNULL(International.ExtDimensionTypeDr2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr2,
	|	International.ExtDimensionDr2 AS ExtDimensionDr2,
	|	ISNULL(International.ExtDimensionTypeDr3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeDr3,
	|	International.ExtDimensionDr3 AS ExtDimensionDr3,
	|	-ISNULL(International.CurrencyAmountDr, 0) AS CurrencyAmountDr,
	|	-ISNULL(International.CountDr, 0) AS CountDr,
	|	International.DepartmentCr AS DepartmentCr,
	|	International.CurrencyCr AS CurrencyCr,
	|	International.LineOfBusinessCr AS LineOfBusinessCr,
	|	International.AccountCr AS AccountCr,
	|	ISNULL(International.ExtDimensionTypeCr1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr1,
	|	International.ExtDimensionCr1 AS ExtDimensionCr1,
	|	ISNULL(International.ExtDimensionTypeCr2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr2,
	|	International.ExtDimensionCr2 AS ExtDimensionCr2,
	|	ISNULL(International.ExtDimensionTypeCr3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)) AS ExtDimensionTypeCr3,
	|	International.ExtDimensionCr3 AS ExtDimensionCr3,
	|	-ISNULL(International.CurrencyAmountCr, 0) AS CurrencyAmountCr,
	|	-ISNULL(International.CountCr, 0) AS CountCr,
	|	-International.Sum AS Sum,
	|	-International.PresentationAmount AS PresentationAmount,
	|	International.Content AS Content,
	|	International.PostingTemplate AS PostingTemplate,
	|	VALUE(Enum.PostingTypesFinancialAccounting.ReversingEntry) AS PostingType,
	|	International.AccountComplianceDr AS AccountComplianceDr,
	|	International.AccountComplianceCr AS AccountComplianceCr,
	|	International.EqualityOfTurnoverTotals AS EqualityOfTurnoverTotals,
	|	TRUE AS ReversingEntry,
	|	International.FinRecordID AS FinRecordID,
	|	International.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	AccountingRegister.International.RecordsWithExtDimensions(
	|		,
	|		,
	|		(Recorder, ChartOfAccounts, Organization) IN (
	|			SELECT
	|				DocumentsStorno.ReversedDocument,
	|				DocumentsStorno.ChartOfAccounts,
	|				DocumentsStorno.Organization
	|			FROM
	|				DocumentsStorno AS DocumentsStorno
	|			WHERE
	|				DocumentsStorno.TransactionsWithCorrespondence
	|				AND NOT DocumentsStorno.ReversedDocumentForReflection
	|		),
	|		,
	|	) AS International
	|	INNER JOIN
	|		DocumentsStorno AS DocumentsStorno
	|	ON
	|		International.Recorder = DocumentsStorno.ReversedDocument
	|		AND International.ChartOfAccounts = DocumentsStorno.ChartOfAccounts
	|		AND International.Organization = DocumentsStorno.Organization
	|		AND DocumentsStorno.TransactionsWithCorrespondence
	|		AND NOT DocumentsStorno.ReversedDocumentForReflection
	|WHERE
	|	NOT International.ReversingEntry
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentsStorno.Period AS Period,
	|	DocumentsStorno.Recorder AS Recorder,
	|	DocumentsStorno.ReplaceWithReverse AS ReplaceWithReverse,
	|	International.ChartOfAccounts AS ChartOfAccounts,
	|	International.Organization AS Organization,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.Department
	|		ELSE VALUE(Catalog.BusinessStructure.EmptyRef)
	|	END AS DepartmentDr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.Currency
	|		ELSE VALUE(Catalog.Currencies.EmptyRef)
	|	END AS CurrencyDr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.LineOfBusiness
	|		ELSE VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|	END AS LineOfBusinessDr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.Account
	|		ELSE VALUE(ChartOfAccounts.International.EmptyRef)
	|	END AS AccountDr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN ISNULL(International.ExtDimensionType1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
	|		ELSE VALUE (ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
	|	END AS ExtDimensionTypeDr1, 
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.ExtDimension1
	|		ELSE UNDEFINED
	|	END AS ExtDimensionDr1,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN ISNULL(International.ExtDimensionType2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
	|		ELSE VALUE (ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
	|	END AS ExtDimensionTypeDr2, 
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.ExtDimension2
	|		ELSE UNDEFINED
	|	END AS ExtDimensionDr2,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN ISNULL(International.ExtDimensionType3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
	|		ELSE VALUE (ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
	|	END AS ExtDimensionTypeDr3, 
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.ExtDimension3
	|		ELSE UNDEFINED
	|	END AS ExtDimensionDr3,
	|	-CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN ISNULL(International.CurrencyAmount, 0)
	|		ELSE 0
	|	END AS CurrencyAmountDr,
	|	-CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN ISNULL(International.Count, 0)
	|		ELSE 0
	|	END AS CountDr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN VALUE(Catalog.BusinessStructure.EmptyRef)
	|		ELSE International.Department
	|	END AS DepartmentCr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN VALUE(Catalog.Currencies.EmptyRef)
	|		ELSE International.Currency
	|	END AS CurrencyCr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|		ELSE International.LineOfBusiness
	|	END AS LineOfBusinessCr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN VALUE(ChartOfAccounts.International.EmptyRef)
	|		ELSE International.Account
	|	END AS AccountCr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN VALUE (ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
	|		ELSE ISNULL(International.ExtDimensionType1, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
	|	END AS ExtDimensionTypeCr1,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN UNDEFINED
	|		ELSE International.ExtDimension1
	|	END AS ExtDimensionCr1,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN VALUE (ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
	|		ELSE ISNULL(International.ExtDimensionType2, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
	|	END AS ExtDimensionTypeCr2,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN UNDEFINED
	|		ELSE International.ExtDimension2
	|	END AS ExtDimensionCr2,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN VALUE (ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef)
	|		ELSE ISNULL(International.ExtDimensionType3, VALUE(ChartOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef))
	|	END AS ExtDimensionTypeCr3,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN UNDEFINED
	|		ELSE International.ExtDimension3
	|	END AS ExtDimensionCr3,
	|	-CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN 0
	|		ELSE ISNULL(International.CurrencyAmount, 0)
	|	END AS CurrencyAmountCr,
	|	-CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN 0
	|		ELSE ISNULL(International.Count, 0)
	|	END AS CountCr,
	|	-International.Sum AS Sum,
	|	-International.PresentationAmount AS PresentationAmount,
	|	International.Content AS Content,
	|	International.PostingTemplate AS PostingTemplate,
	|	VALUE(Enum.PostingTypesFinancialAccounting.ReversingEntry) AS PostingType,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN International.AccountCompliance
	|		ELSE UNDEFINED
	|	END AS AccountComplianceDr,
	|	CASE
	|		WHEN International.RecordType = VALUE(AccountingRecordType.Debit)
	|			THEN UNDEFINED
	|		ELSE International.AccountCompliance
	|	END AS AccountComplianceCr,
	|	International.EqualityOfTurnoverTotals AS EqualityOfTurnoverTotals,
	|	TRUE AS ReversingEntry,
	|	International.FinRecordID AS FinRecordID,
	|	International.BusinessTransactionSetting AS BusinessTransactionSetting
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.RecordsWithExtDimensions(
	|		,
	|		,
	|		(Recorder, ChartOfAccounts, Organization) IN (
	|			SELECT
	|				DocumentsStorno.ReversedDocument,
	|				DocumentsStorno.ChartOfAccounts,
	|				DocumentsStorno.Organization
	|			FROM
	|				DocumentsStorno AS DocumentsStorno
	|			WHERE
	|				DocumentsStorno.TransactionsWithoutCorrespondence
	|				AND NOT DocumentsStorno.ReversedDocumentForReflection
	|		),
	|		,
	|	) AS International
	|	INNER JOIN
	|		DocumentsStorno AS DocumentsStorno
	|	ON
	|		International.Recorder = DocumentsStorno.ReversedDocument
	|		AND International.ChartOfAccounts = DocumentsStorno.ChartOfAccounts
	|		AND International.Organization = DocumentsStorno.Organization
	|		AND DocumentsStorno.TransactionsWithoutCorrespondence
	|		AND NOT DocumentsStorno.ReversedDocumentForReflection
	|WHERE
	|	NOT International.ReversingEntry
	|;
	|
	|///////////////////////////////////////////////////////
	|SELECT
	|	DocumentsStorno.Period AS Period,
	|	DocumentsStorno.Recorder AS Recorder,
	|	DocumentsStorno.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentsStorno.Organization AS Organization,
	|	DocumentsStorno.ReversedDocument AS ReversedDocument,
	|	DocumentsStorno.ReplaceWithReverse AS ReplaceWithReverse
	|FROM
	|	DocumentsStorno AS DocumentsStorno
	|WHERE
	|	DocumentsStorno.ReversedDocumentForReflection
	|;
	|
	|///////////////////////////////////////////////////////
	|DROP DocumentsStorno
	|";
	QueriesResult = Query.ExecuteBatch();
	
	ResultOfReverseEntries = QueriesResult[1];
	ResultReverseDocuments = QueriesResult[2];
	
	TableOfReversePostings = TableOfTransactions.CopyColumns();
	
	Selection = ResultOfReverseEntries.Select();
	While Selection.Next() Do
		NewEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
		FillPropertyValues(NewEntry, Selection);
		
		AccountingCurrenciesOnChartOfAccounts = FinancialAccountingServerCached.AccountingCurrencies(NewEntry.ChartOfAccounts, NewEntry.Organization);
		NewEntry.CurrencyFunctional = AccountingCurrenciesOnChartOfAccounts.Functional;
		NewEntry.PresentationCurrency = AccountingCurrenciesOnChartOfAccounts.Presentations;
			
		If Selection.ReplaceWithReverse Then
			AddTransactionToTransactionTable(TableOfReversePostings, NewEntry);
		Else
			AddTransactionToTransactionTable(TableOfTransactions, NewEntry);
		EndIf;
	EndDo;
	
	TheStructureOfTheSearch = New Structure("Recorder,ChartOfAccounts,Organization,ReversingEntry");
	TheStructureOfTheSearch.ReversingEntry = False;
	
	If Not ResultReverseDocuments.IsEmpty() Then
		TableOfTransactions.Indexes.Add("Recorder,ChartOfAccounts,Organization,ReversingEntry");
		
		Selection = ResultReverseDocuments.Select();
		While Selection.Next() Do
			TheStructureOfTheSearch.Recorder = Selection.ReversedDocument;
			TheStructureOfTheSearch.ChartOfAccounts = Selection.ChartOfAccounts;
			TheStructureOfTheSearch.Organization = Selection.Organization;
			
			ReversedTransactions = TableOfTransactions.FindRows(TheStructureOfTheSearch);
			
			For Each AccountingEntry In ReversedTransactions Do
				If AccountingEntry.Status <> Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting
				   And AccountingEntry.Status <> Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting Then
					Continue;
				EndIf;
				
				NewEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
				FillPropertyValues(NewEntry, AccountingEntry);
				NewEntry.Recorder = Selection.Recorder;
				NewEntry.Period = Selection.Period;
				NewEntry.ReversingEntry = True;                                                          
				NewEntry.PostingType = Enums.PostingTypesFinancialAccounting.ReversingEntry;
				If NewEntry.CountDr <> Undefined Then
					NewEntry.CountDr = -NewEntry.CountDr;
				EndIf;
				If NewEntry.CountCr <> Undefined Then
					NewEntry.CountCr = -NewEntry.CountCr;
				EndIf;
				If NewEntry.CurrencyAmountDr <> Undefined Then
					NewEntry.CurrencyAmountDr = -NewEntry.CurrencyAmountDr;
				EndIf;
				If NewEntry.CurrencyAmountCr <> Undefined Then
					NewEntry.CurrencyAmountCr = -NewEntry.CurrencyAmountCr;
				EndIf;
				If NewEntry.Sum <> Undefined Then
					NewEntry.Sum = -NewEntry.Sum;
				EndIf;
				If NewEntry.PresentationAmount <> Undefined Then
					NewEntry.PresentationAmount = -NewEntry.PresentationAmount;
				EndIf;
				
				If Selection.ReplaceWithReverse Then
					AddTransactionToTransactionTable(TableOfReversePostings, NewEntry);
				Else
					AddTransactionToTransactionTable(TableOfTransactions, NewEntry);
				EndIf;
			EndDo;
		EndDo;
	EndIf;
	
	If TableOfReversePostings.Count() > 0 Then
		SearchTable = TableOfReversePostings.Copy(, "Recorder,ChartOfAccounts,Organization");
		SearchTable.GroupBy("Recorder,ChartOfAccounts,Organization");
		
		If TableOfTransactions.Indexes.Count() = 0 Then
			TableOfTransactions.Indexes.Add("Recorder,ChartOfAccounts,Organization,ReversingEntry");
		EndIf;
		
		DeletedTransactions = New Array();
		
		For Each SearchString In SearchTable Do
			FillPropertyValues(TheStructureOfTheSearch, SearchString);
			CorrectivePostings = TableOfTransactions.FindRows(TheStructureOfTheSearch);
			
			For Each AccountingEntry In CorrectivePostings Do
				If AccountingEntry.Status <> Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting
				   And AccountingEntry.Status <> Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting Then
					Continue;
				EndIf;
				
				DeletedTransactions.Add(AccountingEntry);
				
				NewEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
				FillPropertyValues(NewEntry, AccountingEntry);
				AddTransactionToTransactionTable(TableOfReversePostings, NewEntry);
			EndDo;
		EndDo;
		
		For Each AccountingEntry In DeletedTransactions Do
			TableOfTransactions.Delete(AccountingEntry);
		EndDo;
		
		SearchTable = Undefined;
		AllDimensions = Common.CopyRecursive(ParametersForGeneratingTransactions.BalanceMeasurements);
		
		For Each DimensionName In ParametersForGeneratingTransactions.UnbalancedMeasurements Do
			AllDimensions.Add(DimensionName + "Dr");
			AllDimensions.Add(DimensionName + "Cr");
		EndDo;
		
		For ExtDimensionNumber = 1 To ParametersForGeneratingTransactions.ExtDimensionCount Do
			AllDimensions.Add("ExtDimensionDr" + ExtDimensionNumber);
			AllDimensions.Add("ExtDimensionCr" + ExtDimensionNumber);
		EndDo;
		
		For Each AccountingEntry In TableOfReversePostings Do
			For Each DimensionName In AllDimensions Do
				If Not ValueIsFilled(AccountingEntry[DimensionName]) Then
					AccountingEntry[DimensionName] = Undefined;
				EndIf;
			EndDo;
		EndDo;
		
		ConvolutionTable = TableOfReversePostings.Copy();
			
		For Each AccountingEntry In ConvolutionTable Do
			For Each AttributeName In ParametersForGeneratingTransactions.Attributes Do
				AccountingEntry[AttributeName] = Undefined;
			EndDo;
			
			AccountingEntry.Status = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting;
			AccountingEntry.PresentationAmountStorageCurrency = AccountingEntry.PresentationCurrency;
			AccountingEntry.CurrencyOfStorageOfAmount = AccountingEntry.CurrencyFunctional;
		EndDo;
		
		ValueOfCollapseTransactionTableParameter = ParametersForGeneratingTransactions.CollapseTransactionTable;
		ParametersForGeneratingTransactions.CollapseTransactionTable = True;
		
		CollapseTransactionTable(ParametersForGeneratingTransactions, ConvolutionTable);
		
		ParametersForGeneratingTransactions.CollapseTransactionTable = ValueOfCollapseTransactionTableParameter;

		AllDimensions.Add("Period");
		AllDimensions.Add("Recorder");
		AllDimensions.Add("ReversingEntry");
		AllDimensions.Add("AccountDr");
		AllDimensions.Add("AccountCr");
		
		TheStructureOfTheSearch = New Structure(StrConcat(AllDimensions, ","));
		TableOfReversePostings.Indexes.Add(StrConcat(AllDimensions, ","));
		
		For Each AccountingEntry In ConvolutionTable Do
			FillPropertyValues(TheStructureOfTheSearch, AccountingEntry);
			TheStructureOfTheSearch.ReversingEntry = False;
			OriginalPostings = TableOfReversePostings.FindRows(TheStructureOfTheSearch);
			
			If OriginalPostings.Count() = 0 Then
				TheStructureOfTheSearch.ReversingEntry = True;
				OriginalPostings = TableOfReversePostings.FindRows(TheStructureOfTheSearch);
			EndIf;
			
			If OriginalPostings.Count() > 0 Then
				OriginalEntry = OriginalPostings[0];
				For Each AttributeName In ParametersForGeneratingTransactions.Attributes Do
					AccountingEntry[AttributeName] = OriginalEntry[AttributeName];
				EndDo;
			EndIf;
			
			If (ValueIsFilled(AccountingEntry.Sum) And AccountingEntry.Sum < 0)
			 Or (ValueIsFilled(AccountingEntry.PresentationAmount) And AccountingEntry.PresentationAmount < 0) Then
				AccountingRegisters.International.InvertEntriy(
					AccountingEntry,
					ParametersForGeneratingTransactions.InvertedFields,
					ParametersForGeneratingTransactions.InvertedResources,
					ParametersForGeneratingTransactions.ExtDimensionCount);
				AccountingEntry.PostingType = Enums.PostingTypesFinancialAccounting.Reverse;
			EndIf;
			
			NewEntry = Common.CopyRecursive(ParametersForGeneratingTransactions.EntryStructure);
			FillPropertyValues(NewEntry, AccountingEntry);
			AddTransactionToTransactionTable(TableOfTransactions, NewEntry);
		EndDo;
	EndIf;
	
	TableOfTransactions.Indexes.Clear();
	
EndProcedure

Procedure FillInComment(Comment, AccountingEntry, UniqueValues)

	If UniqueValues[AccountingEntry.Comment] = Undefined Then
		Comment = ?(Not IsBlankString(Comment), Comment + Chars.LF, Comment);
		Comment = Comment + AccountingEntry.Comment;
		UniqueValues.Insert(AccountingEntry.Comment, True);
	EndIf;

EndProcedure

Procedure FillInStatusInTransactionsTable(TableRow, AccountingEntry)

	If ValueIsFilled(TableRow.Status) Then
		Return;
	EndIf;
	
	ErrorsCount = AccountingEntry.ErrorsArray.Count();
	If ErrorsCount > 0 Then
		TableRow.Status = AccountingEntry.Status;
	Else
		TableRow.Status = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting;
	EndIf;

EndProcedure

Procedure FillInCommentInTransactionsTable(TableRow, AccountingEntry)

	ErrorsArray = AccountingEntry.ErrorsArray;
	ErrorsCount = ErrorsArray.Count();
	If ErrorsCount > 0 Then
		
		If ValueIsFilled(AccountingEntry.PostingTemplate) Then
			TextTransactionTemplate = NStr("vi = 'Mẫu bút toán ""%PostingTemplate%""';
											|ru = 'Шаблон проводки ""%PostingTemplate%""';
											|en = 'Posting template ""%PostingTemplate%""'; fa = 'Posting template ""%PostingTemplate%""';
											|it = 'Modello di cablaggio ""%PostingTemplate%""';
											|pl = 'Wzór zaksięgowania ""%PostingTemplate%""';
											|tr = 'Giriş şablonu ""%PostingTemplate%""'") + Chars.LF;
			TextTransactionTemplate = StrReplace(TextTransactionTemplate, "%PostingTemplate%", AccountingEntry.PostingTemplate);
			TextNumberOfErrors = NStr("vi = 'Đã tìm thấy lỗi (%ErrorsCount%):';
										|ru = 'Обнаружены ошибки (%ErrorsCount%):';
										|en = 'Errors are detected (%ErrorsCount%):'; fa = 'Errors are detected (%ErrorsCount%):';
										|it = 'Errori rilevati (%ErrorsCount%):';
										|pl = 'Wykryto błędy (%ErrorsCount%):';
										|tr = 'Hatalar bulundu (%ErrorsCount%):'");
			TextNumberOfErrors = StrReplace(TextNumberOfErrors, "%ErrorsCount%", ErrorsCount);
			ErrorsDescription = TextTransactionTemplate + TextNumberOfErrors;
			For K = 1 To ErrorsCount Do
				ErrorDescription = NStr("vi = '%ErrorNumber%. %ErrorText%';
										|ru = '%ErrorNumber%. %ErrorText%';
										|en = '%ErrorNumber%. %ErrorText%'; fa = '%ErrorNumber%. %ErrorText%';
										|it = '%ErrorNumber%. %ErrorText%';
										|pl = '%ErrorNumber%. %ErrorText%';
										|tr = '%ErrorNumber%. %ErrorText%'");
				ErrorDescription = StrReplace(ErrorDescription, "%ErrorNumber%", K);
				ErrorDescription = StrReplace(ErrorDescription, "%ErrorText%", ErrorsArray[K - 1]);
				ErrorsDescription = ErrorsDescription + Chars.LF + ErrorDescription;
			EndDo;
		Else
			ErrorsDescription = StrConcat(AccountingEntry.ErrorsArray, Chars.LF);
		EndIf;
		
		TableRow.Comment = ErrorsDescription;
		
	EndIf;

EndProcedure

Function EntryStructure()

	AccountingEntry = New Structure;
	RecordSetStructure = AccountingRegisters.International.CreateRecordSet().UnloadColumns();
	For Each Column In RecordSetStructure.Columns Do
		If Column.Name <> "Active" Then
			AccountingEntry.Insert(Column.Name); 
		EndIf;
	EndDo;
	AccountingEntry.Insert("Status");
	AccountingEntry.Insert("PostingTemplate");
	AccountingEntry.Insert("ErrorsArray", New Array);
	AccountingEntry.Insert("PresentationAmountStorageCurrency");
	AccountingEntry.Insert("CurrencyOfStorageOfAmount");
	
	AccountingEntry.Insert("CurrencyFunctional");
	AccountingEntry.Insert("PresentationCurrency");

	Return AccountingEntry;

EndFunction

Function TableOfTransactions()

	TableOfTransactions = AccountingRegisters.International.CreateRecordSet().UnloadColumns();
	
	TableOfTransactions.Columns.Delete("Active");
	
	TableOfTransactions.Columns.Add("Status", New TypeDescription("EnumRef.StatusesOfPostingsInFinancialAccounting"));
	TableOfTransactions.Columns.Add("Comment", New TypeDescription("String"));
	
	TableOfTransactions.Columns.Add("CurrencyFunctional", New TypeDescription("CatalogRef.Currencies"));
	TableOfTransactions.Columns.Add("PresentationCurrency", New TypeDescription("CatalogRef.Currencies"));
	
	// Currencies are the sources of the source data for the presentation amount and the functional amount.
	TableOfTransactions.Columns.Add("PresentationAmountStorageCurrency", New TypeDescription("CatalogRef.Currencies"));
	TableOfTransactions.Columns.Add("CurrencyOfStorageOfAmount", New TypeDescription("CatalogRef.Currencies"));
	
	Return TableOfTransactions;
	
EndFunction

Procedure CollapseTransactionTable(ParametersForGeneratingTransactions, TableOfTransactions)
	
	If Not ParametersForGeneratingTransactions.CollapseTransactionTable Then
		Return;
	EndIf;
	
	RowFilter = New Structure();
	RowFilter.Insert("Status", Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting);
	
	LinesAreReflectedInAccounting = TableOfTransactions.FindRows(RowFilter);
	
	If LinesAreReflectedInAccounting.Count() = 0 Then
		Return;
	EndIf;
	
	GroupFields = New Array();
	GroupFields.Add("Period");
	GroupFields.Add("Recorder");
	GroupFields.Add("AccountDr");
	GroupFields.Add("AccountCr");
	GroupFields.Add("Status");
	GroupFields.Add("CurrencyFunctional");
	GroupFields.Add("PresentationCurrency");
	GroupFields.Add("PresentationAmountStorageCurrency");
	GroupFields.Add("CurrencyOfStorageOfAmount");
	
	For ExtDimensionNumber = 1 To ParametersForGeneratingTransactions.ExtDimensionCount Do
		GroupFields.Add("ExtDimensionTypeDr" + ExtDimensionNumber);
		GroupFields.Add("ExtDimensionTypeCr" + ExtDimensionNumber);
		GroupFields.Add("ExtDimensionDr" + ExtDimensionNumber);
		GroupFields.Add("ExtDimensionCr" + ExtDimensionNumber);
	EndDo;
	
	For Each DimensionName In ParametersForGeneratingTransactions.BalanceMeasurements Do
		GroupFields.Add(DimensionName);
	EndDo;
	
	For Each DimensionName In ParametersForGeneratingTransactions.UnbalancedMeasurements Do
		GroupFields.Add(DimensionName + "Dr");
		GroupFields.Add(DimensionName + "Cr");
	EndDo;
	
	For Each AttributeName In ParametersForGeneratingTransactions.Attributes Do
		GroupFields.Add(AttributeName);
	EndDo;
	
	SummationFields = Common.CopyRecursive(ParametersForGeneratingTransactions.BalanceSheetResources);
	
	For Each ResourceName In ParametersForGeneratingTransactions.UnbalancedResources Do
		SummationFields.Add(ResourceName + "Dr");
		SummationFields.Add(ResourceName + "Cr");
	EndDo;
	
	DimensionString = StrConcat(GroupFields, ",");
	SummationString = StrConcat(SummationFields, ",");
	
	TableIsReflectedInAccounting = TableOfTransactions.Copy(RowFilter);
	TableIsReflectedInAccounting.GroupBy(DimensionString, SummationString);
	
	If TableIsReflectedInAccounting.Count() <> LinesAreReflectedInAccounting.Count() Then
		For Each TransactionTableRow In LinesAreReflectedInAccounting Do
			TableOfTransactions.Delete(TransactionTableRow);
		EndDo;
		
		For Each CollapsedString In TableIsReflectedInAccounting Do
			FillPropertyValues(TableOfTransactions.Add(), CollapsedString);
		EndDo;
	EndIf;
	
EndProcedure

Procedure DeleteTransactionsWithoutAmountsAndQuantities(ParametersForGeneratingTransactions, TableOfTransactions)
	
	TransactionsToDelete = New Array;
	
	For Each AccountingEntry In TableOfTransactions Do
		If AccountingEntry.Status = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting
		 Or AccountingEntry.Status = Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting Then
			AllResourcesAreZero = True;
			
			For Each ResourceName In ParametersForGeneratingTransactions.BalanceSheetResources Do
				If AccountingEntry[ResourceName] <> 0 Then
					AllResourcesAreZero = False;
					Break;
				EndIf;
			EndDo;
			
			If Not AllResourcesAreZero Then
				Continue;
			EndIf;
			
			For Each ResourceName In ParametersForGeneratingTransactions.UnbalancedResources Do
				If AccountingEntry[ResourceName + "Dr"] <> 0 Or AccountingEntry[ResourceName + "Cr"] <> 0 Then
					AllResourcesAreZero = False;
					Break;
				EndIf;
			EndDo;
			
			If AllResourcesAreZero Then
				TransactionsToDelete.Add(AccountingEntry);
			EndIf;
		EndIf;
	EndDo;
	
	For Each AccountingEntry In TransactionsToDelete Do
		TableOfTransactions.Delete(AccountingEntry);
	EndDo;
	
EndProcedure

Procedure RemoveInsignificantTransactions(ParametersForGeneratingTransactions, TableOfTransactions)

	If Not ParametersForGeneratingTransactions.RemoveInsignificantTransactions Then
		Return;
	EndIf;
	
	TransactionFields = New Structure();
	TransactionFields.Insert("AccountDr", "AccountCr");
	
	For ExtDimensionNumber = 1 To ParametersForGeneratingTransactions.ExtDimensionCount Do
		TransactionFields.Insert("ExtDimensionDr" + ExtDimensionNumber, "ExtDimensionCr" + ExtDimensionNumber);
	EndDo;
	
	For Each DimensionName In ParametersForGeneratingTransactions.UnbalancedMeasurements Do
		TransactionFields.Insert(DimensionName + "Dr", DimensionName + "Cr");
	EndDo;
	
	For Each ResourceName In ParametersForGeneratingTransactions.UnbalancedResources Do
		TransactionFields.Insert(ResourceName + "Dr", ResourceName + "Cr");
	EndDo;
	
	DeletedTransactions = New Array();
	
	For Each TransactionTableRow In TableOfTransactions Do
		If TransactionTableRow.Status <> Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting Then
			Continue;
		EndIf;
		
		DrFieldsAreEqualToCrFields = True;
		For Each FieldName In TransactionFields Do
			If TransactionTableRow[FieldName.Key] <> TransactionTableRow[FieldName.Value] Then
				DrFieldsAreEqualToCrFields = False;
				Break;
			EndIf;
		EndDo;
		
		If DrFieldsAreEqualToCrFields Then
			DeletedTransactions.Add(TransactionTableRow);
		EndIf;
	EndDo;
	
	For Each TransactionTableRow In DeletedTransactions Do
		TableOfTransactions.Delete(TransactionTableRow);
	EndDo;
	
EndProcedure

Procedure CollapseTableOfTransactionsWithoutCorrespondence(ParametersForGeneratingTransactions, TableOfTransactions)
	
	RowFilter = New Structure();
	RowFilter.Insert("Status", Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting);
	
	LinesAreReflectedInAccounting = TableOfTransactions.FindRows(RowFilter);
	
	If LinesAreReflectedInAccounting.Count() = 0 Then
		Return;
	EndIf;
	
	GroupFields = New Array();
	GroupFields.Add("RecordType");
	GroupFields.Add("Period");
	GroupFields.Add("Recorder");
	GroupFields.Add("Account");
	GroupFields.Add("Status");
	
	For ExtDimensionNumber = 1 To ParametersForGeneratingTransactions.ExtDimensionCount Do
		GroupFields.Add("ExtDimensionType" + ExtDimensionNumber);
		GroupFields.Add("ExtDimension" + ExtDimensionNumber);
	EndDo;
	
	CommonClientServer.SupplementArray(GroupFields, ParametersForGeneratingTransactions.BalanceMeasurements);
	CommonClientServer.SupplementArray(GroupFields, ParametersForGeneratingTransactions.UnbalancedMeasurements);
	
	For Each AttributeName In ParametersForGeneratingTransactions.Attributes Do
		If AttributeName = "AccountComplianceDr" Then
		ElsIf AttributeName = "AccountComplianceCr" Then
			GroupFields.Add("AccountCompliance");
		Else
			GroupFields.Add(AttributeName);
		EndIf;
	EndDo;
	
	SummationFields = Common.CopyRecursive(ParametersForGeneratingTransactions.BalanceSheetResources);
	CommonClientServer.SupplementArray(SummationFields, ParametersForGeneratingTransactions.UnbalancedResources);
	
	DimensionString = StrConcat(GroupFields, ",");
	SummationString = StrConcat(SummationFields, ",");
	
	TableIsReflectedInAccounting = TableOfTransactions.Copy(RowFilter);
	TableIsReflectedInAccounting.GroupBy(DimensionString, SummationString);
	
	If TableIsReflectedInAccounting.Count() <> LinesAreReflectedInAccounting.Count() Then
		For Each TransactionTableRow In LinesAreReflectedInAccounting Do
			TableOfTransactions.Delete(TransactionTableRow);
		EndDo;
		
		For Each CollapsedString In TableIsReflectedInAccounting Do
			FillPropertyValues(TableOfTransactions.Add(), CollapsedString);
		EndDo;
	EndIf;
	
EndProcedure

Procedure CollapseTurnoverOfTransactionsWithoutCorrespondence(ParametersForGeneratingTransactions, TableOfTransactions)
	
	DimensionFields = New Array();
	DimensionFields.Add("Period");
	DimensionFields.Add("Account");
	
	For ExtDimensionNumber = 1 To ParametersForGeneratingTransactions.ExtDimensionCount Do
		DimensionFields.Add("ExtDimension" + ExtDimensionNumber);
	EndDo;
	
	CommonClientServer.SupplementArray(DimensionFields, ParametersForGeneratingTransactions.BalanceMeasurements);
	CommonClientServer.SupplementArray(DimensionFields, ParametersForGeneratingTransactions.UnbalancedMeasurements);
	
	DimensionFields.Add("ReversingEntry");
	DimensionFields.Add("PostingType");
	
	ResourceFields = Common.CopyRecursive(ParametersForGeneratingTransactions.BalanceSheetResources);
	CommonClientServer.SupplementArray(ResourceFields, ParametersForGeneratingTransactions.UnbalancedResources);
	
	SortFields = New Array();
	SortFields.Add("RecordType");
	CommonClientServer.SupplementArray(SortFields, ResourceFields); 
	
	TableOfTransactions.Sort(StrConcat(SortFields, ","));
	
	StagesOfAccountingForContentOfTransactions = New Array();
	StagesOfAccountingForContentOfTransactions.Add(True);
	StagesOfAccountingForContentOfTransactions.Add(False);
	StagesOfAccountingForSignOfTransactions = Common.CopyRecursive(StagesOfAccountingForContentOfTransactions);
	
	RowsCount = TableOfTransactions.Count();
	
	For Each ConsiderContent In StagesOfAccountingForContentOfTransactions Do
		If ConsiderContent Then
			DimensionFields.Add("Content");
		Else
			FieldIndex = DimensionFields.Find("Content");
			If FieldIndex <> Undefined Then
				DimensionFields.Delete(FieldIndex);
			EndIf;
		EndIf;
		
		ThereAreTurnoversOfOppositeSigns = False;
		
		For Each ConsiderSign In StagesOfAccountingForSignOfTransactions Do
			If Not ConsiderSign And Not ThereAreTurnoversOfOppositeSigns Then
				Break;
			EndIf;
			
			For Each DebitLine In TableOfTransactions Do
				If DebitLine.RecordType <> AccountingRecordType.Debit
				 Or DebitLine.Status <> Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting
				 Or AllResourcesAreZero(DebitLine, ResourceFields) Then
					Continue;
				EndIf;
				
				For IndexOf = 0 To RowsCount - 1 Do
					LineCredit = TableOfTransactions[IndexOf];
					
					If LineCredit.RecordType <> AccountingRecordType.Credit
					 Or LineCredit.Status <> Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting
					 Or AllResourcesAreZero(LineCredit, ResourceFields) Then
						Continue;
					EndIf;
					
					DrMeasurementsAreEqualToCrMeasurements = True;
					For Each FieldName In DimensionFields Do
						If DebitLine[FieldName] <> LineCredit[FieldName] Then
							DrMeasurementsAreEqualToCrMeasurements = False;
							Break;
						EndIf;
					EndDo;
					
					If Not DrMeasurementsAreEqualToCrMeasurements Then
						Continue;
					EndIf;
				
					If ConsiderSign Then
						SignOfDrRevolutionsIsEqualToSignOfCrRevolutions = True;
						For Each FieldName In ResourceFields Do
							If DebitLine[FieldName] < 0 And LineCredit[FieldName] >= 0
							 Or DebitLine[FieldName] >= 0 And LineCredit[FieldName] < 0 Then
								SignOfDrRevolutionsIsEqualToSignOfCrRevolutions = False;
								Break;
							EndIf;
						EndDo;
						
						If Not SignOfDrRevolutionsIsEqualToSignOfCrRevolutions Then
							ThereAreTurnoversOfOppositeSigns = True;
							Continue;
						EndIf;
					EndIf;
					
					If AllResourcesAreZero(DebitLine, ParametersForGeneratingTransactions.BalanceSheetResources)
					   And AllResourcesAreZero(LineCredit, ParametersForGeneratingTransactions.BalanceSheetResources) Then
						ControlResources = ParametersForGeneratingTransactions.UnbalancedResources;
					Else
						ControlResources = ParametersForGeneratingTransactions.BalanceSheetResources;
					EndIf;
					
					DrTurnoverIsMoreThanCrTurnover = True;
					
					For Each FieldName In ControlResources Do
						DrTurnoverModule = ?(DebitLine[FieldName] < 0, -DebitLine[FieldName], DebitLine[FieldName]);
						CrTurnoverModule = ?(LineCredit[FieldName] < 0, -LineCredit[FieldName], LineCredit[FieldName]);
						
						If DrTurnoverModule < CrTurnoverModule Then
							DrTurnoverIsMoreThanCrTurnover = False;
							Break;
						EndIf;
					EndDo;
					
					For Each FieldName In ResourceFields Do
						If DrTurnoverIsMoreThanCrTurnover Then
							DebitLine[FieldName] = DebitLine[FieldName] - LineCredit[FieldName];
							LineCredit[FieldName] = 0;
						Else
							LineCredit[FieldName] = LineCredit[FieldName] - DebitLine[FieldName];
							DebitLine[FieldName] = 0;
						EndIf;
					EndDo;
					
					If Not DrTurnoverIsMoreThanCrTurnover Then
						Break;
					EndIf;
				EndDo;
			EndDo;
		EndDo;
	EndDo;
	
EndProcedure

Procedure DeleteTransactionsWithoutResourcesWithoutCorrespondence(ParametersForGeneratingTransactions, TableOfTransactions)

	ResourceFields = Common.CopyRecursive(ParametersForGeneratingTransactions.BalanceSheetResources);
	CommonClientServer.SupplementArray(ResourceFields, ParametersForGeneratingTransactions.UnbalancedResources);
	
	DeletedTransactions = New Array();
	
	For Each TransactionTableRow In TableOfTransactions Do
		If TransactionTableRow.Status <> Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting Then
			Continue;
		EndIf;
		
		If AllResourcesAreZero(TransactionTableRow, ResourceFields) Then
			DeletedTransactions.Add(TransactionTableRow);
		EndIf;
	EndDo;
	
	For Each TransactionTableRow In DeletedTransactions Do
		TableOfTransactions.Delete(TransactionTableRow);
	EndDo;
	
EndProcedure

Function AllResourcesAreZero(AccountingEntry, ResourceFields)
	
	AllResourcesAreZero = True;
	
	For Each FieldName In ResourceFields Do
		If AccountingEntry[FieldName] <> 0 Then
			AllResourcesAreZero = False;
			Break;
		EndIf;
	EndDo;
	
	Return AllResourcesAreZero;
	
EndFunction

#EndRegion

#Region RegistrationOfDocumentsForReflectionInInternationalAccounting

Procedure AddTransactionGenerationAndStatusSettings(ReflectionTable, Recorder)
	
	Query = New Query(
	"SELECT DISTINCT
	|	ReflectionTable.Period          AS Period,
	|	ReflectionTable.Organization     AS Organization,
	|	ReflectionTable.DateRecord   AS DateRecord,
	|	ReflectionTable.BusinessOperation AS BusinessOperation
	|INTO TableData_
	|FROM
	|	&ReflectionTable AS ReflectionTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableData_.Period AS Period,
	|	FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts AS ChartOfAccounts,
	|	TableData_.Organization AS Organization,
	|	TableData_.DateRecord AS DateRecord,
	|	TableData_.BusinessOperation AS BusinessOperation,
	|	MAX(FinancialAccountingChartsOfAccountsForCompanies.Period) AS Month
	|INTO PeriodsOfTransactionGenerationSettings
	|FROM
	|	TableData_ AS TableData_
	|	INNER JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	ON TableData_.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|		AND TableData_.DateRecord >= FinancialAccountingChartsOfAccountsForCompanies.Period
	|
	|GROUP BY
	|	TableData_.Period,
	|	FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts,
	|	TableData_.Organization,
	|	TableData_.DateRecord,
	|	TableData_.BusinessOperation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	PeriodsOfTransactionGenerationSettings.Period AS Period,
	|	PeriodsOfTransactionGenerationSettings.ChartOfAccounts AS ChartOfAccounts,
	|	PeriodsOfTransactionGenerationSettings.Organization AS Organization,
	|	PeriodsOfTransactionGenerationSettings.DateRecord AS DateRecord,
	|	PeriodsOfTransactionGenerationSettings.BusinessOperation AS BusinessOperation,
	|	FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting AS PostingGenerationSetting
	|INTO SourceTable
	|FROM
	|	PeriodsOfTransactionGenerationSettings AS PeriodsOfTransactionGenerationSettings
	|	LEFT JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	ON	
	|		PeriodsOfTransactionGenerationSettings.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
	|		AND PeriodsOfTransactionGenerationSettings.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|		AND PeriodsOfTransactionGenerationSettings.Month = FinancialAccountingChartsOfAccountsForCompanies.Period
	|WHERE
	|	FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting <> VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReadyForReflection.Period AS Period,
	|	ReadyForReflection.ChartOfAccounts AS ChartOfAccounts,
	|	ReadyForReflection.Organization AS Organization,
	|	ReadyForReflection.DateRecord AS DateRecord,
	|	ReadyForReflection.PostingGenerationSetting AS PostingGenerationSetting,
	|	CASE
	|		WHEN ReadyForReflection.Status = 1 THEN
	|			VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting)
	|		ELSE
	|			VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting)
	|	END AS Status
	|FROM
	|	(SELECT
	|		SourceTable.Period AS Period,
	|		SourceTable.ChartOfAccounts AS ChartOfAccounts,
	|		SourceTable.Organization AS Organization,
	|		SourceTable.DateRecord AS DateRecord,
	|		SourceTable.PostingGenerationSetting AS PostingGenerationSetting,
	|		MIN (CASE
	|			WHEN DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting)
	|				OR DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting)
	|				THEN 1
	|			ELSE 2
	|		END) AS Status
	|	FROM
	|		SourceTable AS SourceTable
	|		LEFT JOIN
	|			InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|		ON
	|			SourceTable.ChartOfAccounts = DocumentReflection.ChartOfAccounts
	|			AND SourceTable.Organization = DocumentReflection.Organization
	|			AND DocumentReflection.Recorder = &Recorder
	|
	|	GROUP BY
	|		SourceTable.Period,
	|		SourceTable.ChartOfAccounts,
	|		SourceTable.Organization,
	|		SourceTable.DateRecord,
	|		SourceTable.PostingGenerationSetting
	|	) AS ReadyForReflection
	|");
	
	Query.SetParameter("ReflectionTable", ReflectionTable);
	Query.SetParameter("Recorder", Recorder);
	ReflectionTable = Query.Execute().Unload();
	
EndProcedure

Procedure GetTransactionGenerationSettingsAndStatus(TempTablesManager)
	
	Query = New Query(
	"SELECT DISTINCT
	|	NestedQuery.Document        AS Document,
	|	NestedQuery.Organization     AS Organization,
	|	NestedQuery.DateRecord   AS DateRecord,
	|	NestedQuery.BusinessOperation AS BusinessOperation
	|INTO TableData_
	|FROM
	|	(SELECT DISTINCT
	|		ReflectionTable.Document        AS Document,
	|		ReflectionTable.Organization     AS Organization,
	|		ReflectionTable.DateRecord   AS DateRecord,
	|		VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation
	|	FROM
	|		CurRegistrationTable AS ReflectionTable
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		ReflectionTable.Document        AS Document,
	|		ReflectionTable.Organization     AS Organization,
	|		ReflectionTable.DateRecord   AS DateRecord,
	|		VALUE(Enum.BusinessTransactions.EmptyRef) AS BusinessOperation
	|	FROM
	|		SampleRegistrationTable AS ReflectionTable
	|) AS NestedQuery
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableData_.Organization AS Organization,
	|	TableData_.DateRecord AS DateRecord,
	|	MAX(FinancialAccountingChartsOfAccountsForCompanies.Period) AS Month
	|INTO PeriodsForSettingUpTransactionGeneration
	|FROM
	|	TableData_ AS TableData_
	|	INNER JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	ON TableData_.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|		AND TableData_.DateRecord >= FinancialAccountingChartsOfAccountsForCompanies.Period
	|
	|GROUP BY
	|	TableData_.Organization,
	|	TableData_.DateRecord
	|
	|INDEX BY
	|	Organization,
	|	DateRecord,
	|	Month
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableData_.Document AS Document,
	|	FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts AS ChartOfAccounts,
	|	TableData_.Organization AS Organization,
	|	TableData_.DateRecord AS DateRecord,
	|	TableData_.BusinessOperation AS BusinessOperation,
	|	FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting AS PostingGenerationSetting
	|INTO SourceTable
	|FROM
	|	TableData_ AS TableData_
	|	LEFT JOIN PeriodsForSettingUpTransactionGeneration AS PeriodsForSettingUpTransactionGeneration
	|	ON TableData_.Organization = PeriodsForSettingUpTransactionGeneration.Organization
	|		AND TableData_.DateRecord = PeriodsForSettingUpTransactionGeneration.DateRecord
	|	LEFT JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	ON PeriodsForSettingUpTransactionGeneration.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|		AND PeriodsForSettingUpTransactionGeneration.Month = FinancialAccountingChartsOfAccountsForCompanies.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BusinessTransactionsSettings.BusinessOperation AS BusinessOperation,
	|	ReflectionRules.PostingGenerationSetting AS PostingGenerationSetting,
	|	MAX(PostingTemplates.ManualSpecificationOfEntry) AS ManualSpecificationOfEntry
	|INTO ReflectionRules
	|FROM
	|	Catalog.PostingTemplatesForFinancialAccounting AS PostingTemplates
	|	INNER JOIN
	|		Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|	ON
	|		PostingTemplates.Operation = BusinessTransactionsSettings.Ref
	|	LEFT JOIN
	|		InformationRegister.RulesOfPostingsInFinancialAccounting AS ReflectionRules
	|	ON
	|		PostingTemplates.Ref = ReflectionRules.PostingTemplate
	|GROUP BY
	|	BusinessTransactionsSettings.BusinessOperation,
	|	ReflectionRules.PostingGenerationSetting
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReadyForReflection.Document AS Document,
	|	ReadyForReflection.ChartOfAccounts AS ChartOfAccounts,
	|	ReadyForReflection.Organization AS Organization,
	|	ReadyForReflection.DateRecord AS DateRecord,
	|	ReadyForReflection.PostingGenerationSetting AS PostingGenerationSetting,
	|	CASE
	|		WHEN ReadyForReflection.Status = 1 THEN
	|			VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting)
	|		ELSE
	|			VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting)
	|	END AS Status
	|INTO ConfiguringTransactionGenerationAndStatus
	|FROM
	|	(SELECT
	|		SourceTable.Document AS Document,
	|		SourceTable.ChartOfAccounts AS ChartOfAccounts,
	|		SourceTable.Organization AS Organization,
	|		SourceTable.DateRecord AS DateRecord,
	|		SourceTable.PostingGenerationSetting AS PostingGenerationSetting,
	|		MIN (CASE
	|			WHEN DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting)
	|				OR DocumentReflection.Status = VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting)
	|				OR ReflectionRules.ManualSpecificationOfEntry
	|				THEN 1
	|			ELSE 2
	|		END) AS Status
	|	FROM
	|		SourceTable AS SourceTable
	|		LEFT JOIN
	|			ReflectionRules AS ReflectionRules
	|		ON
	|			SourceTable.PostingGenerationSetting = ReflectionRules.PostingGenerationSetting
	|			AND SourceTable.BusinessOperation = ReflectionRules.BusinessOperation
	|		LEFT JOIN
	|			InformationRegister.DocumentPostingInFinancialAccounting AS DocumentReflection
	|		ON
	|			SourceTable.Organization = DocumentReflection.Organization
	|			AND SourceTable.Document = DocumentReflection.Recorder
	|
	|	GROUP BY
	|		SourceTable.Document,
	|		SourceTable.ChartOfAccounts,
	|		SourceTable.Organization,
	|		SourceTable.DateRecord,
	|		SourceTable.PostingGenerationSetting
	|	) AS ReadyForReflection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TableData_;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP PeriodsForSettingUpTransactionGeneration;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP SourceTable;
	|////////////////////////////////////////////////////////////////////////////////
	|DROP ReflectionRules;
	|");
	
	Query.TempTablesManager = TempTablesManager;
	Query.Execute();
	
EndProcedure

Function InitializeManagerToReturnToReflection(DocumentsToBeReflected)
	
	TempTablesManager = New TempTablesManager;
	If TypeOf(DocumentsToBeReflected) = Type("ValueTable") Then
		If DocumentsToBeReflected.Count() = 0 Then
			Return Undefined;
		EndIf;
		Query = New Query(
		"SELECT DISTINCT
		|	DocumentsToBeReflected.Period AS Period,
		|	DocumentsToBeReflected.Document AS Document,
		|	DocumentsToBeReflected.Organization AS Organization,
		|	DocumentsToBeReflected.DateRecord AS DateRecord
		|INTO DocumentsToBeReflected
		|FROM
		|	&DocumentsToBeReflected AS DocumentsToBeReflected
		|
		|INDEX BY
		|	Document,
		|	Organization,
		|	DateRecord
		|;
		|/////////////////////////////////////////////////
		|");
		Query.SetParameter("DocumentsToBeReflected", DocumentsToBeReflected);
		Query.TempTablesManager = TempTablesManager;
		Query.Execute();
	Else
		TempTablesManager = DocumentsToBeReflected;
	EndIf;
	
	Return TempTablesManager;
	
EndFunction

Function DataToReturnToAccounting(DocumentsToBeReflected, Filter)

	#Region RequestTextTableOfReflectionOfDocumentsInInternationalAccounting
	QueryText = 
	"SELECT DISTINCT TOP 1000
	|	MIN(DocumentsToBeReflected.Period) AS Period,
	|	DocumentsToBeReflected.Document AS Recorder,
	|	DocumentsToBeReflected.Organization AS Organization,
	|	BEGINOFPERIOD(DocumentsToBeReflected.DateRecord, DAY) AS DateRecord
	|INTO RecordsForReflection
	|FROM
	|	DocumentsToBeReflected AS DocumentsToBeReflected
	|WHERE
	|	VALUETYPE(DocumentsToBeReflected.Document) <> TYPE(Document.RegisterAdjustment)
	|	AND (DocumentsToBeReflected.Document > &Recorder OR &Recorder = UNDEFINED)
	|GROUP BY
	|	DocumentsToBeReflected.Document,
	|	DocumentsToBeReflected.Organization,
	|	BEGINOFPERIOD(DocumentsToBeReflected.DateRecord, DAY)
	|
	|ORDER BY
	|	Recorder
	|	
	|INDEX BY
	|	Recorder,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RecordsForReflection.Recorder AS Recorder
	|INTO OnlyDocumentsForReflection
	|FROM
	|	RecordsForReflection AS RecordsForReflection
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	RegisterData.Period AS Period,
	|	RegisterData.Recorder AS Recorder,
	|	RegisterData.ChartOfAccounts AS ChartOfAccounts,
	|	RegisterData.Organization AS Organization,
	|	RegisterData.DateRecord AS DateRecord,
	|	RegisterData.Status,
	|	RegisterData.PostingGenerationSetting,
	|	RegisterData.Comment
	|INTO AllRegistrarRecords
	|FROM
	|	OnlyDocumentsForReflection AS DocumentsToBeReflected
	|		INNER JOIN InformationRegister.DocumentPostingInFinancialAccounting AS RegisterData
	|		ON DocumentsToBeReflected.Recorder = RegisterData.Recorder
	|
	|INDEX BY
	|	Recorder,
	|	Organization,
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	MIN(RegisterData.Period) AS Period,
	|	RegisterData.Recorder AS Recorder
	|INTO RegistrarPeriods
	|FROM
	|	AllRegistrarRecords AS RegisterData
	|GROUP BY
	|	RegisterData.Recorder
	|
	|INDEX BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|// If there was no registration, then you need to register.
	|SELECT
	|	ISNULL(RegisterData.Period, DocumentsToBeReflected.Period) AS Period,
	|	ISNULL(RegisterData.Recorder, DocumentsToBeReflected.Recorder) AS Recorder,
	|	ISNULL(RegisterData.ChartOfAccounts, UNDEFINED) AS ChartOfAccounts,
	|	ISNULL(RegisterData.Organization, DocumentsToBeReflected.Organization) AS Organization,
	|	ISNULL(RegisterData.DateRecord, DocumentsToBeReflected.DateRecord) AS DateRecord,
	|	ISNULL(RegisterData.Status, VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting)) AS Status,
	|	ISNULL(RegisterData.PostingGenerationSetting, UNDEFINED) AS PostingGenerationSetting,
	|	ISNULL(RegisterData.Comment, """") AS Comment
	|INTO TemporaryRegisterTable
	|FROM
	|	RecordsForReflection AS DocumentsToBeReflected
	|		LEFT JOIN InformationRegister.DocumentPostingInFinancialAccounting AS RegisterData
	|		ON DocumentsToBeReflected.Recorder = RegisterData.Recorder
	|		AND DocumentsToBeReflected.Organization = RegisterData.Organization
	|		AND BEGINOFPERIOD(DocumentsToBeReflected.DateRecord, DAY) = BEGINOFPERIOD(RegisterData.DateRecord, DAY)
	|
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization,
	|	DateRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	RegisterData.Organization AS Organization,
	|	BEGINOFPERIOD(RegisterData.DateRecord, MONTH) AS Period
	|INTO MonthOfReflection
	|FROM
	|	AllRegistrarRecords AS RegisterData
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RegisterData.Organization AS Organization,
	|	BEGINOFPERIOD(RegisterData.DateRecord, MONTH) AS Period
	|FROM
	|	TemporaryRegisterTable AS RegisterData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts AS ChartOfAccounts,
	|	FinancialAccountingChartsOfAccountsForCompanies.Organization AS Organization,
	|	MAX(FinancialAccountingChartsOfAccountsForCompanies.Period) AS Period,
	|	MonthOfReflection.Period AS RegistrationPeriod
	|INTO PeriodsForSettingUpTransactionGeneration
	|FROM
	|	MonthOfReflection AS MonthOfReflection
	|	INNER JOIN InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	ON MonthOfReflection.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|		AND MonthOfReflection.Period >= FinancialAccountingChartsOfAccountsForCompanies.Period
	|
	|GROUP BY
	|	FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts,
	|	FinancialAccountingChartsOfAccountsForCompanies.Organization,
	|	MonthOfReflection.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts AS ChartOfAccounts,
	|	FinancialAccountingChartsOfAccountsForCompanies.Organization AS Organization,
	|	PeriodsForSettingUpTransactionGeneration.RegistrationPeriod AS Period,
	|	FinancialAccountingChartsOfAccountsForCompanies.PostingGenerationSetting AS Setting
	|INTO FinancialAccountingChartsOfAccountsForCompanies
	|FROM
	|	InformationRegister.FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	INNER JOIN PeriodsForSettingUpTransactionGeneration
	|	ON FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts = PeriodsForSettingUpTransactionGeneration.ChartOfAccounts
	|		AND FinancialAccountingChartsOfAccountsForCompanies.Organization = PeriodsForSettingUpTransactionGeneration.Organization
	|		AND FinancialAccountingChartsOfAccountsForCompanies.Period = PeriodsForSettingUpTransactionGeneration.Period
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(RegistrarPeriods.Period, DocumentPostingInFinancialAccounting.Period) AS Period,
	|	DocumentPostingInFinancialAccounting.Recorder AS Recorder,
	|	ISNULL(FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts, DocumentPostingInFinancialAccounting.ChartOfAccounts) AS ChartOfAccounts,
	|	DocumentPostingInFinancialAccounting.Organization AS Organization,
	|	DocumentPostingInFinancialAccounting.DateRecord AS DateRecord,
	|	DocumentPostingInFinancialAccounting.Status,
	|	ISNULL(FinancialAccountingChartsOfAccountsForCompanies.Setting, DocumentPostingInFinancialAccounting.PostingGenerationSetting) AS PostingGenerationSetting,
	|	DocumentPostingInFinancialAccounting.Comment
	|INTO RegisterTable
	|FROM
	|	TemporaryRegisterTable AS DocumentPostingInFinancialAccounting
	|	LEFT JOIN FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	ON DocumentPostingInFinancialAccounting.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|		AND BEGINOFPERIOD(DocumentPostingInFinancialAccounting.DateRecord, MONTH) = BEGINOFPERIOD(FinancialAccountingChartsOfAccountsForCompanies.Period, MONTH)
	|		AND (CASE
	|			WHEN DocumentPostingInFinancialAccounting.ChartOfAccounts <> UNDEFINED
	|				THEN DocumentPostingInFinancialAccounting.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
	|			ELSE TRUE
	|		END)
	|	LEFT JOIN RegistrarPeriods AS RegistrarPeriods
	|	ON DocumentPostingInFinancialAccounting.Recorder = RegistrarPeriods.Recorder
	|WHERE
	|	NOT (FinancialAccountingChartsOfAccountsForCompanies.Setting IS NULL
	|		OR FinancialAccountingChartsOfAccountsForCompanies.Setting = VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef))
	|
	|INDEX BY
	|	Period,
	|	Recorder,
	|	Organization,
	|	DateRecord
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP MonthOfReflection;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP PeriodsForSettingUpTransactionGeneration;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP TemporaryRegisterTable;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP RegistrarPeriods;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentPostingInFinancialAccounting.Period AS Period,
	|	DocumentPostingInFinancialAccounting.Recorder AS Recorder,
	|	DocumentPostingInFinancialAccounting.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentPostingInFinancialAccounting.Organization AS Organization,
	|	DocumentPostingInFinancialAccounting.DateRecord AS DateRecord,
	|	DocumentPostingInFinancialAccounting.Status AS Status,
	|	DocumentPostingInFinancialAccounting.Comment AS Comment,
	|	DocumentPostingInFinancialAccounting.PostingGenerationSetting AS PostingGenerationSetting
	|INTO TTOtherLoggerEntries
	|FROM
	|	AllRegistrarRecords AS DocumentPostingInFinancialAccounting
	|	LEFT JOIN RecordsForReflection AS DocumentsToBeReflected
	|	ON DocumentsToBeReflected.Recorder = DocumentPostingInFinancialAccounting.Recorder
	|		AND DocumentsToBeReflected.Organization = DocumentPostingInFinancialAccounting.Organization
	|		AND BEGINOFPERIOD(DocumentsToBeReflected.DateRecord, DAY) = DocumentPostingInFinancialAccounting.DateRecord
	|	LEFT JOIN FinancialAccountingChartsOfAccountsForCompanies AS FinancialAccountingChartsOfAccountsForCompanies
	|	ON DocumentPostingInFinancialAccounting.ChartOfAccounts = FinancialAccountingChartsOfAccountsForCompanies.ChartOfAccounts
	|		AND DocumentPostingInFinancialAccounting.Organization = FinancialAccountingChartsOfAccountsForCompanies.Organization
	|		AND BEGINOFPERIOD(DocumentPostingInFinancialAccounting.DateRecord, MONTH) = FinancialAccountingChartsOfAccountsForCompanies.Period
	|WHERE
	|	DocumentsToBeReflected.Recorder IS NULL
	|	AND NOT (FinancialAccountingChartsOfAccountsForCompanies.Setting IS NULL
	|		OR FinancialAccountingChartsOfAccountsForCompanies.Setting = VALUE(Catalog.FinancialAccountingPostingGenerationSetting.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DocumentPostingInFinancialAccounting.Period         AS Period,
	|	DocumentPostingInFinancialAccounting.Recorder    AS Recorder,
	|	DocumentPostingInFinancialAccounting.ChartOfAccounts     AS ChartOfAccounts,
	|	DocumentPostingInFinancialAccounting.Organization    AS Organization,
	|	DocumentPostingInFinancialAccounting.DateRecord  AS DateRecord,
	|	CASE 
	|		WHEN NOT DocumentsToBeReflected.Organization IS NULL THEN
	|			CASE WHEN DocumentPostingInFinancialAccounting.Status IN (
	|					VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting),
	|					VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting))
	|				THEN VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting)
	|				ELSE VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting)
	|			END
	|		ELSE
	|			DocumentPostingInFinancialAccounting.Status
	|	END AS Status,
	|	CASE
	|		WHEN NOT DocumentsToBeReflected.Organization IS NULL THEN
	|			CASE WHEN DocumentPostingInFinancialAccounting.Status IN (
	|					VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting),
	|					VALUE(Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting))
	|				THEN DocumentPostingInFinancialAccounting.Comment
	|				ELSE """"
	|			END
	|		ELSE DocumentPostingInFinancialAccounting.Comment
	|	END AS Comment,
	|	DocumentPostingInFinancialAccounting.PostingGenerationSetting AS PostingGenerationSetting
	|INTO NewRegisterData
	|FROM
	|	RegisterTable AS DocumentPostingInFinancialAccounting
	|	LEFT JOIN
	|		RecordsForReflection AS DocumentsToBeReflected
	|	ON
	|		BEGINOFPERIOD(DocumentPostingInFinancialAccounting.Period, DAY) = BEGINOFPERIOD(DocumentsToBeReflected.Period, DAY)
	|		AND BEGINOFPERIOD(DocumentPostingInFinancialAccounting.DateRecord, DAY) = BEGINOFPERIOD(DocumentsToBeReflected.DateRecord, DAY)
	|		AND DocumentPostingInFinancialAccounting.Organization = DocumentsToBeReflected.Organization
	|		AND DocumentPostingInFinancialAccounting.Recorder = DocumentsToBeReflected.Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentPostingInFinancialAccounting.Period AS Period,
	|	DocumentPostingInFinancialAccounting.Recorder AS Recorder,
	|	DocumentPostingInFinancialAccounting.ChartOfAccounts AS ChartOfAccounts,
	|	DocumentPostingInFinancialAccounting.Organization AS Organization,
	|	DocumentPostingInFinancialAccounting.DateRecord AS DateRecord,
	|	DocumentPostingInFinancialAccounting.Status AS Status,
	|	DocumentPostingInFinancialAccounting.Comment AS Comment,
	|	DocumentPostingInFinancialAccounting.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	TTOtherLoggerEntries AS DocumentPostingInFinancialAccounting
	|
	|INDEX BY
	|	Period,
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NewRegisterData.Recorder AS Recorder
	|FROM
	|	NewRegisterData AS NewRegisterData
	|
	|ORDER BY
	|	Recorder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	NewRegisterData.Period AS Period,
	|	NewRegisterData.Recorder AS Recorder,
	|	NewRegisterData.ChartOfAccounts AS ChartOfAccounts,
	|	NewRegisterData.Organization AS Organization,
	|	NewRegisterData.DateRecord AS DateRecord,
	|	NewRegisterData.Status AS Status,
	|	NewRegisterData.Comment AS Comment,
	|	NewRegisterData.PostingGenerationSetting AS PostingGenerationSetting
	|FROM
	|	NewRegisterData AS NewRegisterData
	|
	|;
	|
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP RecordsForReflection;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP OnlyDocumentsForReflection;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP FinancialAccountingChartsOfAccountsForCompanies;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP NewRegisterData;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP RegisterTable;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP TTOtherLoggerEntries;
	|//////////////////////////////////////////////////////////////////////////////////
	|DROP AllRegistrarRecords;
	|";
	#EndRegion
	
	Query = New Query(QueryText);
	Query.TempTablesManager = DocumentsToBeReflected;
	Query.SetParameter("Recorder", Filter.Recorder);
	
	QueryResult = Query.ExecuteBatch();  
	
	RegisterData = QueryResult[16].Unload(); // ValueTable - 
	RegisterData.Indexes.Add("Recorder");
	
	Result = New Structure("Recorders, RegisterData");
	Result.Recorders = QueryResult[15].Select();
	Result.RegisterData = RegisterData;
	Return Result;
	
EndFunction

#EndRegion

// Returns a composite comment to the document
//
// Parameters:
// 	Document - DocumentRef - The document on which you need to get a comment
// 	Organization - CatalogRef.Companies, Array of CatalogRef.Companies - Additional selection, if you need to get a reflection comment on a specific organization
// Returns:
// 	 String - a composite comment to an unrecorded document.
//
Function SummaryCommentOnDocument(Document, Organization = Undefined) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Records.Comment AS Comment
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS Records
	|WHERE
	|	Records.Recorder = &Document
	|	AND (Records.Organization IN (&Organization )
	|		OR &AllCompanies)
	|";
	Query.SetParameter("Document",       Document);
	Query.SetParameter("Organization",    Organization);
	Query.SetParameter("AllCompanies", Not ValueIsFilled(Organization));
	
	Selection = Query.Execute().Select();
	Substrings = New Array;
	While Selection.Next() Do
		If Selection.Comment = "" Then
			Continue;
		EndIf;
		If Substrings.Find(Selection.Comment) <> Undefined Then
			Continue;
		EndIf;
		Substrings.Add(Selection.Comment);
	EndDo;
	
	Result = StrConcat(Substrings, Chars.LF);
	
	Return Result;
	
EndFunction

#EndRegion
