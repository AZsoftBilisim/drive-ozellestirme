
#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - FixedStructure - document properties (See DocumentsPosting.DocumentProperties)
//                                      .
//
// Returns:
//  Structure - parameters of the accounting mechanism (See DocumentsPosting.ParametersOfAccountingMechanism)
//              .
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords);
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.OtherAssetsLiabilities);
		
		If GetFunctionalOption("UseBalanceSheetStatement")
			And Not ProductionManagement.BatchFormationOfStagesIsPerformed(Document)
			And TypeOf(Document) <> Type("DocumentObject.InventoryCostCalculation") Then
			
			Parameters.ThereAreDerivedMotions = True;
			
		EndIf;
		
	EndIf;
	
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords);
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			QueryTextOfCancellationOfRegisteredRecordsForOtherAssetsLiabilities(RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	RegisterMetadata = Metadata.AccumulationRegisters.OtherAssetsLiabilities;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		AdditionalTermsAndConditions = "
		|	NOT RegisterData.CalculationOfCost
		|	AND RegisterData.Source = VALUE(Enum.SourcesOfBalanceSheetStatement.EmptyRef)
		|";		
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata,
				MetadataOfDocument,
				AdditionalTermsAndConditions));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

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
	
	MatchingQueryTexts.Insert("ChangesTableOtherAssetsAndLiabilitiesRecords", 
		AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.RequestTextMonitoringBanDate(Query));
	
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements on the slave registers of financial documents.
//
// Parameters:
//   TablesForRegisteredRecords - Structure - document data tables
//   RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//   Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "OtherAssetsAndLiabilitiesRecords");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "OtherAssetsLiabilities");
		
EndProcedure

// Forms the text of the requests for control changes, the recorded movements of the registers.
//
// Parameters:
//  Query - Query - a query that stores the parameters used in the query list
//  QueryTexts - ValueList - list of query texts and their names.
//  Document - DocumentObject - a recordable document.
//
Procedure InitializeChangeControlData(Query, QueryTexts, Document) Export
	
	Return; // empty handler
	
EndProcedure

// Displays messages to the user if there are errors in monitoring changes to recorded register movements.
//
// Parameters:
//  ControlResults - Structure - table with the results of the control changes
//  Document - DocumentObject - recordable document
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReportChangeControlResults(ControlResults, Document, Cancel) Export
	
	Return; // empty handler
	
EndProcedure

// Occurs before writing the registers the document.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure BeforeRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	Return; // empty handler
	
EndProcedure

// Occurs after execution of the write registers of the instrument.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  TempTablesManager - TempTablesManager - temporary table Manager
//      used for storing register change control tables
//  Cancel - Boolean - indicates that the document was rejected.
//
Procedure AfterRecordingDocumentRegisteredRecords(Document, TempTablesManager, Cancel) Export
	
	If Document.AdditionalProperties.DocumentsPosting.Property("NotUseBalanceSheetStatement")
	 Or Document.RegisterRecords.Find("OtherAssetsLiabilities") = Undefined Then
		Return;
	EndIf;
	
	Queue = "JobsToRecordInOtherAssetsLiabilities";
	
	DeferredJobs.AddTasksToQueue(
		Queue,
		New Structure("Document", Document.Ref),,
		DocumentsPosting.TaskQueueTable(Document, Queue));
	
EndProcedure

#EndRegion

#Region NonOperationalInterrogation

// Records the task for the background holding of the register "Register Recorded Other assets and liabilities".
//
// Parameters:
//  Document - DocumentObject - a recordable document.
//
Procedure CreateTaskForNonOperationalDocumentExecution(Document) Export
	
	If Not GetFunctionalOption("UseExcisableGoods") Then
		Return;
	EndIf;
	
	DocumentType = TypeOf(Document);
	DocumentRef = Undefined;
	
	If DocumentType = Type("DocumentObject.WriteOffOfGoodsShortages")
		Or DocumentType = Type("DocumentObject.InventoryConsumption") Then
		DocumentRef = Document.Ref;
	ElsIf DocumentType = Type("DocumentObject.ReversingEntry") Then
		TypeOfDocumentBeingCancelled = TypeOf(Document.ReversedDocument);
		If TypeOfDocumentBeingCancelled = Type("DocumentRef.WriteOffOfGoodsShortages")
			Or TypeOfDocumentBeingCancelled = Type("DocumentRef.InventoryConsumption") Then
			DocumentRef = Document.Ref;
		EndIf
	EndIf;
	
	If DocumentRef <> Undefined Then
		
		Query = New Query;
		Query.SetParameter("Ref", DocumentRef);

		Query.Text = "SELECT
		|	DocumentData.Ref AS Document,
		|	DocumentData.Date AS TaskPeriod,
		|	DocumentData.Organization AS Organization,
		|	VALUE(Catalog.BackdateJobKinds.RecordOfAssetsAndLiabilitiesRegisterRecords) AS JobKind
		|FROM
		|	&Document AS DocumentData
		|WHERE
		|	DocumentData.Ref = &Ref";
		
		Query.Text = StrReplace(Query.Text, "&Document", "Document." + Document.Metadata().Name); // @query-part
		
		DataForRegisteringTasks = Query.Execute().Unload();
		
		TempTablesManager = Undefined;
		
		Source = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet();
		RegisterMetadata = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords;
		RegisterManager = Common.ObjectManagerByFullName(RegisterMetadata.FullName());
		
		ArrayOfViews = New Array;
		ArrayOfViews.Add(Catalogs.BackdateJobKinds.RecordOfAssetsAndLiabilitiesRegisterRecords);
		
		InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.CreateJobs(RegisterManager, ArrayOfViews, Source,
		TempTablesManager, DataForRegisteringTasks);
			
	EndIf;
	
EndProcedure

// Records the amount of excise tax in the register "Movements of Other assets and liabilities".
//
// Parameters:
//	DocumentRef - DocumentRef - a link to the document for which other assets and liabilities should be recorded.
//
Procedure WriteDownOtherAssetsLiabilities(DocumentRef) Export
	
	DocumentPosted = Common.ObjectAttributeValue(DocumentRef, "Posted");
	
	If DocumentPosted = Undefined Or DocumentPosted = False Then
		Return;
	EndIf;
	
	RecordSet = Undefined;
	DocumentType = TypeOf(DocumentRef);
	
	If DocumentType <> Type("DocumentRef.ReversingEntry") Then
		
		ManagerOfDocument = Common.ObjectManagerByRef(DocumentRef);
		Result = ManagerOfDocument.GetDataOnOtherAssetsLiabilities(DocumentRef);
		
		RecordSet = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet();
		RecordSet.AdditionalProperties.Insert("DeferredPosting");
		RecordSet.AdditionalProperties.Insert("ControlTables");
		RecordSet.AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
		RecordSet.Filter.Recorder.Set(DocumentRef);
		Selection = Result.Select();
		While Selection.Next() Do
			FillPropertyValues(RecordSet.Add(), Selection);
		EndDo;
		
	EndIf;
	
	If DocumentType = Type("DocumentRef.WriteOffOfGoodsShortages")
		Or DocumentType = Type("DocumentRef.InventoryConsumption") Then
		
		DocumentAttributes = Common.ObjectAttributesValues(DocumentRef, "Patch, ReversedDocument");
		
		If DocumentAttributes.Patch Then
			RegisterRecordsForStorno(DocumentRef, DocumentAttributes.ReversedDocument, RecordSet);
		EndIf;
		
	ElsIf DocumentType = Type("DocumentRef.ReversingEntry") Then
		
		ReversedDocument = Common.ObjectAttributeValue(DocumentRef, "ReversedDocument");
		DocumentType = TypeOf(ReversedDocument);
		
		If DocumentType = Type("DocumentRef.WriteOffOfGoodsShortages")
			Or DocumentType = Type("DocumentRef.InventoryConsumption") Then
			
			RecordSet = AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.CreateRecordSet();
			RecordSet.AdditionalProperties.Insert("DeferredPosting");
			RecordSet.AdditionalProperties.Insert("ControlTables");
			RecordSet.AdditionalProperties.Insert("TempTablesManager", New TempTablesManager);
			RecordSet.Filter.Recorder.Set(DocumentRef);
			
			RegisterRecordsForStorno(DocumentRef, ReversedDocument, RecordSet);
			
		EndIf;
		
	EndIf;
	
	If RecordSet <> Undefined Then
		RecordSet.Write();
		CheckBanDateInChangesTable(RecordSet);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

#Region Posting

// The function returns the request text to reflect the offsetting between branches in the register of movementproproch active Arrays.
// Analog of transactions of the Dt 6X.XX type :: Kt 79.02, Dt 79.02 :: CT 6X. XX.
// Movements are formed based on data from a temporary table used for recording in the register of Movementcontragentcontragent
//
// Parameters:
//  ThereIsPRiTD - Boolean - Indicates whether the permanent and temporary difference fields should be added to the request
//
// Returns:
//	String - Query text
//
Function QueryTextSettlementWithBranches(ThereIsPRiTD = False, ThereIsObjectOfCalculations = False) Export
	
	QueryText = "
	|SELECT
	|	RecordsCounterpartyCounterparty.Period                     AS Period,
	|	RecordsCounterpartyCounterparty.Organization                AS Organization,
	|	CorObjectsOfCalculations.Department                        AS Department,
	|	RecordsCounterpartyCounterparty.CorLineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
	|	RecordsCounterpartyCounterparty.CorCounterparty              AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Debit)    AS DebitCredit,
	|
	|	RecordsCounterpartyCounterparty.SumCompl AS SumCompl,
	|	RecordsCounterpartyCounterparty.Sum     AS SumMan,
	|	RecordsCounterpartyCounterparty.Sum     AS AmountIncludingVAT,
	|	RecordsCounterpartyCounterparty.Sum     AS AmountExcludingVAT,
	|	&PermanentDifference,
	|	&CostTD,
	|
	|	&ARAPObject,
	|	ARAPObjects.UUID AS FinRecordID,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.CustomsPayment),
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentTransferBetweenBranchOffices)
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|				VALUE(Enum.BusinessTransactions.RefundFromVendor))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)
	|		ELSE BusinessTransactionsSettings.Ref
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON RecordsCounterpartyCounterparty.ARAPObject = ARAPObjects.Ref
	|	LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|		ON RecordsCounterpartyCounterparty.CorARAPObject = CorObjectsOfCalculations.Ref
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON RecordsCounterpartyCounterparty.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	RecordsCounterpartyCounterparty.Organization <> RecordsCounterpartyCounterparty.CorCounterparty
	|	AND RecordsCounterpartyCounterparty.Organization.ParentCompany = RecordsCounterpartyCounterparty.CorCounterparty.ParentCompany
	|	
	|UNION ALL
	|
	|SELECT
	|	RecordsCounterpartyCounterparty.Period                  AS Period,
	|	RecordsCounterpartyCounterparty.Organization             AS Organization,
	|	ARAPObjects.Department                        AS Department,
	|	RecordsCounterpartyCounterparty.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.BranchOfficeARAPAccounting) AS AssetRef,
	|	RecordsCounterpartyCounterparty.Counterparty              AS Dimension,
	|	VALUE(Catalog.OtherTransactionsGLAccountsSettings.EmptyRef) AS GLAccountSettings,
	|	VALUE(Enum.RecordKindsOfOtherAssetsAndLiabilities.Credit) AS DebitCredit,
	|
	|	RecordsCounterpartyCounterparty.SumCompl AS SumCompl,
	|	RecordsCounterpartyCounterparty.Sum     AS SumMan,
	|	RecordsCounterpartyCounterparty.Sum     AS AmountIncludingVAT,
	|	RecordsCounterpartyCounterparty.Sum     AS AmountExcludingVAT,
	|	&PermanentDifference,
	|	&CostTD,
	|
	|	&ARAPObject,
	|	CorObjectsOfCalculations.UUID AS FinRecordID,
	|	CASE
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.PaymentToVendor),
	|				VALUE(Enum.BusinessTransactions.CashPaymentToAnotherCompany),
	|				VALUE(Enum.BusinessTransactions.CustomsPayment),
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|				VALUE(Enum.BusinessTransactions.CashReceiptFromOtherCompany))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.PaymentTransferBetweenBranchOffices)
	|		WHEN &BusinessOperation IN (
	|				VALUE(Enum.BusinessTransactions.RefundToCustomer),
	|				VALUE(Enum.BusinessTransactions.RefundFromVendor))
	|			THEN VALUE(Catalog.BusinessTransactionsSettings.SettlementOfPrepayment)
	|		ELSE BusinessTransactionsSettings.Ref
	|	END AS BusinessTransactionSetting
	|FROM
	|	TTMovementCounterpartyCounterparty AS RecordsCounterpartyCounterparty
	|	LEFT JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON RecordsCounterpartyCounterparty.ARAPObject = ARAPObjects.Ref
	|	LEFT JOIN Catalog.ARAPObjects AS CorObjectsOfCalculations
	|		ON RecordsCounterpartyCounterparty.CorARAPObject = CorObjectsOfCalculations.Ref
	|	LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON RecordsCounterpartyCounterparty.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	RecordsCounterpartyCounterparty.Organization <> RecordsCounterpartyCounterparty.Counterparty
	|	AND RecordsCounterpartyCounterparty.Organization.ParentCompany = RecordsCounterpartyCounterparty.Counterparty.ParentCompany
	|";
	
	If ThereIsPRiTD Then
		FieldConstantDifference = "0 AS PermanentDifference,";
		TimeDifferenceField  = "0 AS CostTD,";
	Else
		FieldConstantDifference = "";
		TimeDifferenceField  = "";
	EndIf;
	
	If ThereIsObjectOfCalculations Then
		CalculationObjectField = "UNDEFINED AS ARAPObject,";
	Else
		CalculationObjectField = "";
	EndIf;

	QueryText = StrReplace(QueryText, "&PermanentDifference,", FieldConstantDifference);
	QueryText = StrReplace(QueryText, "&CostTD,",  TimeDifferenceField);
	QueryText = StrReplace(QueryText, "&ARAPObject,",    CalculationObjectField);

	Return QueryText;
	
EndFunction

// Reflects other assets and liabilities.
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the dimensions, resources and Attributes of the Information register
//                              of the "Task recordingproachieactivities", there are also service columns:
//             * Document               - DocumentRef          - link to the document to be reflected
//             * RecordID    - UUID -
//             * RecordDate             - Date                    -
//             * JobID   - UUID - Service_
//             * TaskDate_            - Date                    - Service_
//  IdsOfUnprocessedRecords - Map of UUID - The key is the identifier 
//                                                                                   of the failed (giving an error during
//                                                                                   execution) entries
//                                                                                   of the Job queue information register
//                                                                                   (measurement
//                                                                                   of the record identifier of the Job queue information register),
//                                                                                  the value is the Presentation of the error.
//  AdditionalProperties - Undefined, Structure - additional task completion properties.
//
Procedure ReflectOtherAssetsAndLiabilities(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export	
	
	DocumentsArray = Common.UnloadColumn(Jobs, "Document", True);
	
	MetaOfRegister = Undefined;
	
	For Each Document In DocumentsArray Do
		
		Try
			
			ManagementAccountingPostingServer.UpdateRegisteredRecordsOfAssetsLiabilities(
				Document,
				Document.GetObject().RegisterRecords);
			
		Except
			
			If MetaOfRegister = Undefined Then
				
				MetaOfRegister = Metadata.InformationRegisters.JobsToRecordInOtherAssetsLiabilities;
				
				EventName   = DeferredJobs.EventName();
				
				ErrorFields   = New Structure("Document");
				DataOfError = New Structure("Document");
				
				Jobs.Indexes.Add("Document");
				
			EndIf;
			
			ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			WriteLogEvent(EventName, EventLogLevel.Error, MetaOfRegister,, ExceptionText);
			
			DataOfError.Document = Document;
			
			ErrorText = DeferredJobs.ExecutionErrorText(ErrorFields, DataOfError, ExceptionText);
			
			FoundRows = Jobs.FindRows(DataOfError);
			For Each FoundRow In FoundRows Do
				IdsOfUnprocessedRecords.Insert(FoundRow.RecordID, ErrorText);
			EndDo;
			
		EndTry;
		
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

Function QueryTextOfCancellationOfRegisteredRecordsForOtherAssetsLiabilities(RegisterMetadata, MetadataOfDocument)
	
	AdditionalTermsAndConditions = "
	|	NOT RegisterData.CalculationOfCost
	|";
	
	Return DocumentsPosting.TextOfReversingRequest(
			RegisterMetadata,
			MetadataOfDocument,
			AdditionalTermsAndConditions);
	
EndFunction

Procedure CheckBanDateInChangesTable(RecordSet)

	Query = New Query();
	Query.TempTablesManager = RecordSet.AdditionalProperties.TempTablesManager;
	
	Cancel = False;
	TheTextOfASubquery = "";
	TempTablesQueryText = "";
	TemporaryTableNames = "";

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

	Mechanism = "AccountingForOtherAssetsLiabilities";
	
	MechanismModule = Common.CommonModule(DocumentsPosting.ConfigurationAccountingMechanisms()[Mechanism]);
	
	MatchingRequests = MechanismModule.QueryTextsMonitoringBanDateBasedOnChangesTable(Query);
	
	For Each MapItem In MatchingRequests Do
		MonthEndTransactionsServer.AddTaskRequestText(MapItem.Key,
			MapItem.Value,
			Query.TempTablesManager.Tables,
			TheTextOfASubquery,
			TempTablesQueryText,
			TemporaryTableNames);
	EndDo;

	TextDestroyW = MonthEndTransactionsServer.TemporaryTableDestructionQueryTest(TemporaryTableNames);
	
	If ValueIsFilled(TheTextOfASubquery) Then
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
			If RecordSet.AdditionalProperties.Property("CheckingDateWhenChangesWereBanned") 
					And Not RecordSet.AdditionalProperties.CheckingDateWhenChangesWereBanned Then
				Continue
			EndIf;
			If RecordSet.AdditionalProperties.Property("SkipPeriodClosingCheck") 
					And RecordSet.AdditionalProperties.SkipPeriodClosingCheck Then
				Continue
			EndIf;
			If PeriodClosingDates.PeriodEndClosingFound(DataToCheck, 
					New Structure("NewVersion, Data", True, RecordSet),
					ErrorDescription) Then
				If Cancel Then
					Raise ErrorDescription;
				EndIf;
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure RegisterRecordsForStorno(DocumentRef, ReversedDocument, RecordSet)
	
	ManagerOfDocument = Common.ObjectManagerByRef(ReversedDocument);
	Result = ManagerOfDocument.GetDataOnOtherAssetsLiabilities(ReversedDocument);
	
	DataTableForStorno = New ValueTable;                                               
	For Each AttributeOfRegister In Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.StandardAttributes Do
		DataTableForStorno.Columns.Add(AttributeOfRegister.Name, AttributeOfRegister.Type);
	EndDo;
	For Each RegisterDimension In Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Dimensions Do
		DataTableForStorno.Columns.Add(RegisterDimension.Name, RegisterDimension.Type);
	EndDo;
	For Each AttributeOfRegister In Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Attributes Do
		DataTableForStorno.Columns.Add(AttributeOfRegister.Name, AttributeOfRegister.Type);
	EndDo;
	For Each RegisterResource In Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Resources Do
		DataTableForStorno.Columns.Add(RegisterResource.Name, RegisterResource.Type);
	EndDo;
	
	Selection = Result.Select();
	While Selection.Next() Do
		NewRow = DataTableForStorno.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.Recorder = ReversedDocument;
	EndDo;

	QueryTextForDataRetrieval =
	"SELECT
	|*
	|INTO TTMovementData
	|FROM &DataForStorno AS DataForStorno";

	RegisterMetadata = Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords;
	MetadataOfDocument = Metadata.FindByType(TypeOf(DocumentRef));

	QueryTextReversingEntry = QueryTextOfCancellationOfRegisteredRecordsForOtherAssetsLiabilities(RegisterMetadata, MetadataOfDocument); 
	QueryTextReversingEntry = StrReplace(QueryTextReversingEntry, "AccumulationRegister.OtherAssetsAndLiabilitiesRecords", "TTMovementData");

	Query = New Query;
	Query.Text = QueryTextForDataRetrieval
	+ Common.QueryBatchSeparator()
	+ QueryTextReversingEntry;
	Query.SetParameter("Ref", DocumentRef);
	Query.SetParameter("DataForStorno", DataTableForStorno);
	Selection = Query.Execute().Select();

	While Selection.Next() Do
		NewRow = RecordSet.Add();
		FillPropertyValues(NewRow, Selection);
	EndDo;
	
EndProcedure

#EndRegion
