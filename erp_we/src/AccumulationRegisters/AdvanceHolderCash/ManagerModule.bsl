#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.AccumulationRegisters.AdvanceHolderCash);
		
	EndIf;
	
	// Control
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		
		Parameters.TaskControlRegisters.Add(Metadata.AccumulationRegisters.AdvanceHolderCash);
		
	EndIf;
	// Control of the ban date
	If Properties.WriteMode <> DocumentWriteMode.Write Then
		Parameters.ControlRegistersBanDate.Add(Metadata.AccumulationRegisters.AdvanceHolderCash);
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
	
	RegisterMetadata = Metadata.AccumulationRegisters.AdvanceHolderCash;
	If DocumentRegisterRecords.Contains(RegisterMetadata) Then
		QueriesTexts.Insert(RegisterMetadata.FullName(),
			DocumentsPosting.TextOfReversingRequest(
				RegisterMetadata, MetadataOfDocument));
	EndIf;
	
	Return QueriesTexts;
	
EndFunction

// The procedure of formation of movements on the register.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AdvanceHolderCash");
	
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
	MatchingQueryTexts.Insert("ChangesTableAdvanceHolderCash", 
		AccumulationRegisters.AdvanceHolderCash.RequestTextMonitoringBanDate(Query));
	Return MatchingQueryTexts;
	
EndFunction

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.AdvanceHolderCash.Name;
	NameOfChangeTable = "ChangesTableAdvanceHolderCash"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

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
	|	ValueAllowed(AdvanceHolder)
	|	AND ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

// Fills in the parameters for reflecting register movements in financial accounting
//
// Parameters:
//  RegisterMetadata - MetadataObjectAccumulationRegister - Metadata of the accumulation register
//  RegistrationForReflection - Boolean - Flag for getting parameters to register for accounting
//
// Returns:
// 	See FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Function ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegisterMetadata = Undefined, RegistrationForReflection = False) Export
	
	ReflectionParameters = FinancialAccountingByBalanceSheetRegisterData.ParametersForReflectingRegisteredRecordsInFinancialAccounting(RegistrationForReflection);
	
	If RegistrationForReflection Then
		Return ReflectionParameters;
	EndIf;
	
	ReflectionParameters.DataPathAccountingLocation = "Department";
	ReflectionParameters.DataPathRowId = "FinRecordID";
	ReflectionParameters.PathToDataDivision = "Department";
	ReflectionParameters.DataPathCurrency = "Currency";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	ReflectionParameters.ShaftResources.Add("Sum");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Cash;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.Cash.DataPath = "AdvanceHolder";
	ReflectionParameters.StructureOfAnalytics.CashType.Insert("Value", Enums.CashTypes.AdvanceHolderSCash);
	ReflectionParameters.StructureOfAnalytics.ProductCostElement.Insert("Value", Catalogs.ProductCostElements.EmptyRef());
	ReflectionParameters.StructureOfAnalytics.PaymentDivision.Insert("Value", Catalogs.BusinessStructure.EmptyRef());
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

#EndRegion

//Performs the cleaning of the purpose of issuing funds to the accountable
//
// Parameters:
//	Parameters - Structure - wait handler parameters
//	UUID - UUID - id of the waiting handler.
//
Procedure ClearPurposeOfIssuingFundsToAccountable(Parameters, UUID) Export
	
	BeginTransaction();
	
	Try
		
		LockSet = False;	
		Block = New DataLock;
		LockItem = Block.Add("AccumulationRegister.AdvanceHolderCash");
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		LockSet = True;
			
		Query = New Query;
		Query.Text = 
		"SELECT DISTINCT
		|	AdvanceHolderCash.Recorder AS Recorder
		|FROM
		|	AccumulationRegister.AdvanceHolderCash AS AdvanceHolderCash
		|WHERE
		|	NOT AdvanceHolderCash.IssuancePurpose = VALUE(Catalog.CashFlowReportItems.EmptyRef)";
		
		Result = Query.Execute();
		If Result.IsEmpty() Then
			Return;
		EndIf;
		
		RecordSet = AccumulationRegisters.AdvanceHolderCash.CreateRecordSet();
		RecordSet.DataExchange.Load = True;
		Selection = Result.Select();
			
		While Selection.Next() Do
			
			RecordSet.Filter.Recorder.Value = Selection.Recorder;
			RecordSet.Read();
			
			For Each SetRecord In RecordSet Do
				SetRecord.IssuancePurpose = Catalogs.CashFlowReportItems.EmptyRef();
			EndDo;
			
			RecordSet.Write();
				
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
			
		WriteLogEvent(NStr("vi = 'Thực hiện xóa mục đích chi tiền mặt cho người nhận tạm ứng';
							|ru = 'Выполнение очистки цели выдачи денежных средств подотчетнику';
							|en = 'Cleaning the purpose of issuing cash to the advance holder'; fa = 'Cleaning the purpose of issuing cash to the advance holder';
							|it = 'Выполнение очистки цели выдачи денежных средств подотчетнику';
							|pl = 'Cleaning the purpose of issuing cash to the advance holder';
							|tr = 'Sorumlu kişiye nakit ödemesinin amacının gerçekleştirilmesi'"),
		        EventLogLevel.Error,
		        ,
		        ,
		        ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		If Not LockSet Then
			ExceptionText = NStr("vi = 'Không thể thực hiện giao dịch.
			|Cần khởi động ở chế độ độc quyền.';
			|ru = 'Не удалось выполнить операцию.
			|Необходимо запустить в монопольном режиме.';
			|en = 'The operation failed.
			|Run it in exclusive mode.'; fa = 'The operation failed.
			|Run it in exclusive mode.';
			|it = 'Не удалось выполнить операцию.
			|Необходимо запустить в монопольном режиме.';
			|pl = 'The operation failed.
			|Run it in exclusive mode.';
			|tr = 'İşlem gerçekleştirilemiyor.
			|Tek kutuplu modda çalıştırılması gerekiyor.'");
			Raise ExceptionText;
		EndIf;
		
	EndTry;
	
EndProcedure

#Region BackdateJobQueue

// Data for the formation of tasks for non-operational document verification.
// Called when writing a set of register entries.
// 
// Parameters:
//  RecordSet - AccumulationRegisterRecordSet, InformationRegisterRecordSet - A recordable set of source register records.
//  KindsOfTasks - Array of CatalogRef.BackdateJobKinds - List of types of tasks.
//                According to this list, new tasks must be registered according to the recorded register data.
//  TempTablesManager - Undefined, TempTablesManager - When specifying the MW, the data from the temporary tables will be used when creating new tasks.
//  DataForRegisteringTasks - Undefined, ValueTable - A table with data for registering new tasks.
// 
// Returns:
//  ValueTable - Data For The Formation Of Tasks For Non-Operational Document Verification:
// * Organization - CatalogRef.Companies - The organization for which the new task will be generated.
// * TaskPeriod  - Date - The task period. Coincides with the period of the recorded data in the register.
// * Document - DocumentRef - Link to the document for which the task will be registered.
// * JobKind - CatalogRef.BackdateJobKinds - Type of registered task.
//
Function DataForFormationOfTasksForNonOperationalDocumentVerification(RecordSet, KindsOfTasks,
	TempTablesManager = Undefined, DataForRegisteringTasks = Undefined) Export
	
	If Not DataForRegisteringTasks = Undefined Then
		Return DataForRegisteringTasks;
	EndIf;
	
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	Return DataTable;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
