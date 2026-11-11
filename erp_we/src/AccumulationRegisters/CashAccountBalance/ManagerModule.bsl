#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Collects the structure from the request texts for further verification of the ban date.
// 
// Parameters:
// 	Query - Query - Request to check the date of the ban, you can set the parameters
// Returns:
// 	Structure - See MonthEndTransactionsServer.InitializeStructureOfQueryTexts
Function RequestTextMonitoringBanDate(Query) Export
	RegisterName = Metadata.AccumulationRegisters.CashAccountBalance.Name;
	NameOfChangeTable = "ChangesTableCashAccountBalance"; 
	StructureOfQueryTexts_ = DocumentsPosting.RequestTextTemplateBanDateControl(Query, 
		RegisterName, 
		NameOfChangeTable, 
		"FinancialOutline");
	Return StructureOfQueryTexts_

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(CashAccount)
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
	
	ReflectionParameters.DataPathConfigurationObject = "CashAccount.FinancialAccountingGroup";
	ReflectionParameters.DataPathAccountingLocation = "CashAccount";
	ReflectionParameters.PathToDataLineOfBusiness = "CashAccount.LineOfBusiness";
	ReflectionParameters.PathToDataDivision = "CashAccount.Department";
	ReflectionParameters.DataPathCurrency = "CashAccount.CashCurrency";
	ReflectionParameters.ManResources.Add("SumMan");
	ReflectionParameters.LocalResources.Add("SumCompl");
	ReflectionParameters.ShaftResources.Add("Sum");
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Cash;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.Cash.DataPath = "CashAccount";
	ReflectionParameters.StructureOfAnalytics.CashType.Insert("Value", Enums.CashTypes.CashPayment);
	ReflectionParameters.StructureOfAnalytics.ProductCostElement.Insert("Value", Catalogs.ProductCostElements.EmptyRef());
	ReflectionParameters.StructureOfAnalytics.PaymentDivision.DataPath = "Department";
	
	ReflectionParameters.DataPathDopSettingUpHouseholdOfOperation = StrReplace(
		"CASE
		|		WHEN DataSourceAlias.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion)
		|			THEN VALUE(Catalog.BusinessTransactionsSettings.CashReceiptFromCurrencyConversion)
		|		ELSE DataSourceAlias.BusinessTransactionSetting
		|	END",
		"DataSourceAlias",
		ReflectionParameters.DataSourceAlias);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

#EndRegion

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

#Region Internal

#Region InfobaseUpdate

// Fills in information about update handlers.
// 
// Parameters:
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable.
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.CashAccountBalance.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.23.19";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("6d6669d9-63e2-41f3-baf6-4d846d7010a7");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.CashAccountBalance.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment =
		NStr("vi = 'Điền mục tin ""Bộ phận"" trong biểu ghi tích lũy ""Vốn bằng tiền (tiền gửi)"".';
			|ru = 'Заполнение реквизита ""Подразделение"" в регистре накопления ""Денежные средства (наличные)"".';
			|en = 'Fill the ""Business unit"" attribute in the ""Cash"" accumulation register.'; fa = 'Fill the ""Business unit"" attribute in the ""Cash"" accumulation register.';
			|it = 'Fill the ""Business unit"" attribute in the ""Cash"" accumulation register.';
			|pl = 'Fill the ""Business unit"" attribute in the ""Cash"" accumulation register.';
			|tr = '""Nakit (kasa hesabı) birikim kaydında ""Departman"" özniteliğinin doldurulması.'");
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.CashAccountBalance.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.CashAccountBalance.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters; // See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters
	FullNamesOfObjects = New Array;
	FullNamesOfObjects.Add(Metadata.Documents.CashAccountReceiptNote.FullName());
	FullNamesOfObjects.Add(Metadata.Documents.CashVoucher.FullName());
	SelectionParameters.FullNamesOfObjects = StrConcat(FullNamesOfObjects, ",");
	SelectionParameters.FullRegistersNames = Metadata.AccumulationRegisters.CashAccountBalance.FullName();
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsRegisterRecords = True;
	AdditionalParameters.FullRegisterName = SelectionParameters.FullRegistersNames;
	
	Query = New Query;
	Query.Text = 
		"SELECT DISTINCT
		|	RegisterRegisteredRecords_.Recorder AS Recorder
		|FROM
		|	AccumulationRegister.CashAccountBalance AS RegisterRegisteredRecords_
		|WHERE
		|	RegisterRegisteredRecords_.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|	AND RegisterRegisteredRecords_.Recorder REFS Document.CashAccountReceiptNote
		|	AND RegisterRegisteredRecords_.BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer), VALUE(Enum.BusinessTransactions.RefundFromVendor))
		|	AND RegisterRegisteredRecords_.FinRecordID <> """"
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.CashAccountReceiptNote.ARAPDetails AS PaymentDecryptionTable
		|			WHERE
		|				RegisterRegisteredRecords_.Recorder = PaymentDecryptionTable.Ref
		|				AND RegisterRegisteredRecords_.FinRecordID = PaymentDecryptionTable.RowID
		|				AND ISNULL(PaymentDecryptionTable.ARAPObject.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) <> VALUE(Catalog.BusinessStructure.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	RegisterRegisteredRecords_.Recorder
		|FROM
		|	AccumulationRegister.CashAccountBalance AS RegisterRegisteredRecords_
		|WHERE
		|	RegisterRegisteredRecords_.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|	AND RegisterRegisteredRecords_.Recorder REFS Document.CashAccountReceiptNote
		|	AND RegisterRegisteredRecords_.BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment), VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits), VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty))
		|	AND RegisterRegisteredRecords_.FinRecordID <> """"
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.CashAccountReceiptNote.ARAPDetails AS PaymentDecryptionTable
		|			WHERE
		|				RegisterRegisteredRecords_.Recorder = PaymentDecryptionTable.Ref
		|				AND RegisterRegisteredRecords_.FinRecordID = PaymentDecryptionTable.RowID
		|				AND ISNULL(PaymentDecryptionTable.LoanDepositContract.Department, VALUE(Catalog.BusinessStructure.EmptyRef)) <> VALUE(Catalog.BusinessStructure.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	RegisterRegisteredRecords_.Recorder
		|FROM
		|	AccumulationRegister.CashAccountBalance AS RegisterRegisteredRecords_
		|WHERE
		|	RegisterRegisteredRecords_.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|	AND RegisterRegisteredRecords_.Recorder REFS Document.CashAccountReceiptNote
		|	AND RegisterRegisteredRecords_.BusinessOperation IN (VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder), VALUE(Enum.BusinessTransactions.LoanRepaymentByEmployee), VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister), VALUE(Enum.BusinessTransactions.CashReceiptFromBank), VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion))
		|	AND CAST(RegisterRegisteredRecords_.Recorder AS Document.CashAccountReceiptNote).Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	RegisterRegisteredRecords_.Recorder
		|FROM
		|	AccumulationRegister.CashAccountBalance AS RegisterRegisteredRecords_
		|WHERE
		|	RegisterRegisteredRecords_.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|	AND RegisterRegisteredRecords_.Recorder REFS Document.CashAccountReceiptNote
		|	AND RegisterRegisteredRecords_.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashReceipt)
		|	AND RegisterRegisteredRecords_.FinRecordID <> """"
		|	AND TRUE IN
		|			(SELECT TOP 1
		|				TRUE
		|			FROM
		|				Document.CashAccountReceiptNote.ARAPDetails AS PaymentDecryptionTable
		|			WHERE
		|				RegisterRegisteredRecords_.Recorder = PaymentDecryptionTable.Ref
		|				AND RegisterRegisteredRecords_.FinRecordID = PaymentDecryptionTable.RowID
		|				AND PaymentDecryptionTable.Department <> VALUE(Catalog.BusinessStructure.EmptyRef))
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	RegisterRegisteredRecords_.Recorder
		|FROM
		|	AccumulationRegister.CashAccountBalance AS RegisterRegisteredRecords_
		|WHERE
		|	RegisterRegisteredRecords_.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|	AND RegisterRegisteredRecords_.Recorder REFS Document.CashAccountReceiptNote
		|	AND RegisterRegisteredRecords_.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
		|	AND RegisterRegisteredRecords_.CashAccount.Department <> VALUE(Catalog.BusinessStructure.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	RegisterRegisteredRecords_.Recorder
		|FROM
		|	AccumulationRegister.CashAccountBalance AS RegisterRegisteredRecords_
		|WHERE
		|	RegisterRegisteredRecords_.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
		|	AND RegisterRegisteredRecords_.Recorder REFS Document.CashVoucher
		|	AND CAST(RegisterRegisteredRecords_.Recorder AS Document.CashVoucher).Department <> VALUE(Catalog.BusinessStructure.EmptyRef)";
	
	InfobaseUpdate.MarkForProcessing(
		Parameters, Query.Execute().Unload().UnloadColumn("Recorder"), AdditionalParameters);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - Handler Parameters:
//   * SubsystemVersionAtStartUpdates - String - the version of the subsystem.
//   * HandlerName - String - name of the handler.
//   * UpdatedData - Structure
//   * ProcessingCompleted - Boolean, Undefined - indicates End of processing.
//   * Queue - Number - the queue.
//   * ExecutionProgress - Structure:
//     ** TotalObjectCount - Number - total objects processed.
//     ** ProcessedObjectsCount1 - Number - processed objects.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.AccumulationRegisters.CashAccountBalance.FullName();
	RegisterName = Metadata.AccumulationRegisters.CashAccountBalance.Name;
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsRegisterRecords = True;
	AdditionalParameters.FullRegisterName = FullRegisterName;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể điền mục tin ""Bộ phận"" trong biểu ghi tích lũy ""Vốn bằng tiền (tiền gửi)"".';
								|ru = 'Не удалось заполнить реквизит ""Подразделение"" в регистре накопления ""Денежные средства (наличные)"".';
								|en = 'Cannot fill the ""Business unit"" attribute in the ""Cash"" accumulation register.'; fa = 'Cannot fill the ""Business unit"" attribute in the ""Cash"" accumulation register.';
								|it = 'Cannot fill the ""Business unit"" attribute in the ""Cash"" accumulation register.';
								|pl = 'Cannot fill the ""Business unit"" attribute in the ""Cash"" accumulation register.';
								|tr = '""Nakit (kasa hesabı) birikim kaydında ""Departman"" özniteliği doldurulamadı.'"));
		
	QueryTextCashAccountReceiptNote = 
	"SELECT
	|	Document.Ref AS Ref,
	|	Document.Patch AS Patch,
	|	Document.ReversedDocument AS ReversedDocument,
	|	UNDEFINED AS FinRecordID,
	|	Document.Department AS Department
	|FROM
	|	Document.CashAccountReceiptNote AS Document
	|WHERE
	|	Document.Ref = &Ref
	|	AND Document.BusinessOperation IN (
	|	VALUE(Enum.BusinessTransactions.CashReturnByAdvanceHolder),
	|	VALUE(Enum.BusinessTransactions.LoanRepaymentByEmployee),
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCashRegister),
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
	|	VALUE(Enum.BusinessTransactions.CashReceiptFromCurrencyConversion),
	|	VALUE(Enum.BusinessTransactions.CurrencyConversion))
	|
	|UNION ALL
	|
	|SELECT
	|	Document.Ref AS Ref,
	|	Document.Patch AS Patch,
	|	Document.ReversedDocument AS ReversedDocument,
	|	UNDEFINED AS FinRecordID,
	|	Document.CashAccount.Department AS Department
	|FROM
	|	Document.CashAccountReceiptNote AS Document
	|WHERE
	|	Document.Ref = &Ref
	|	AND Document.BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromAnotherCashAccount)
	|
	|UNION ALL
	|SELECT
	|	Document.Ref AS Ref,
	|	Document.Patch AS Patch,
	|	Document.ReversedDocument AS ReversedDocument,
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	PaymentDecryptionTable.ARAPObject.Department AS Department
	|FROM
	|	Document.CashAccountReceiptNote AS Document
	|	INNER JOIN Document.CashAccountReceiptNote.ARAPDetails AS PaymentDecryptionTable
	|	ON Document.Ref = PaymentDecryptionTable.Ref
	|WHERE
	|	Document.Ref = &Ref
	|	AND Document.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer),
	|		VALUE(Enum.BusinessTransactions.RefundFromVendor))
	|
	|UNION ALL
	|
	|SELECT
	|	Document.Ref AS Ref,
	|	Document.Patch AS Patch,
	|	Document.ReversedDocument AS ReversedDocument,
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	PaymentDecryptionTable.LoanDepositContract.Department AS Department
	|FROM
	|	Document.CashAccountReceiptNote AS Document
	|	INNER JOIN Document.CashAccountReceiptNote.ARAPDetails AS PaymentDecryptionTable
	|	ON Document.Ref = PaymentDecryptionTable.Ref
	|WHERE
	|	Document.Ref = &Ref
	|	AND Document.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromLoansRepayment),
	|		VALUE(Enum.BusinessTransactions.CashReceiptUnderDeposits),
	|		VALUE(Enum.BusinessTransactions.CashReceiptBorrowingsProvidedToCounterparty))
	|
	|UNION ALL
	|
	|SELECT
	|	Document.Ref AS Ref,
	|	Document.Patch AS Patch,
	|	Document.ReversedDocument AS ReversedDocument,
	|	PaymentDecryptionTable.RowID AS FinRecordID,
	|	PaymentDecryptionTable.Department AS Department
	|FROM
	|	Document.CashAccountReceiptNote AS Document
	|	INNER JOIN Document.CashAccountReceiptNote.ARAPDetails AS PaymentDecryptionTable
	|	ON Document.Ref = PaymentDecryptionTable.Ref
	|WHERE
	|	Document.Ref = &Ref
	|	AND Document.BusinessOperation = VALUE(Enum.BusinessTransactions.OtherCashReceipt)";
	
	QueryTextCashVoucher = 
	"SELECT
	|	Document.Ref AS Ref,
	|	Document.Patch AS Patch,
	|	Document.ReversedDocument AS ReversedDocument,
	|	UNDEFINED AS FinRecordID,
	|	Document.Department AS Department
	|FROM
	|	Document.CashVoucher AS Document
	|WHERE
	|	Document.Ref = &Ref";
	
	For Each TableRow In UpdatedData Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullRegisterName + ".RecordSet");
			LockItem.SetValue("Recorder", TableRow.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			LockItem = Block.Add(TableRow.Recorder.Metadata().FullName());
			LockItem.SetValue("Ref", TableRow.Recorder);
			LockItem.Mode = DataLockMode.Shared;
			
			Block.Lock();
				
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Kết chuyển lại chứng từ thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			RecordSet = AccumulationRegisters.CashAccountBalance.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(TableRow.Recorder);
			RecordSet.Read();
			RecordsTable = RecordSet.Unload();
			RecordsTable.Indexes.Add("FinRecordID");
			RecordTableHasBeenChanged = False;
			
			TypeOfRegistrar = TypeOf(TableRow.Recorder);
			If TypeOfRegistrar = Type("DocumentRef.CashAccountReceiptNote") Then
				QueryText = QueryTextCashAccountReceiptNote;
			ElsIf TypeOfRegistrar = Type("DocumentRef.CashVoucher") Then
				QueryText = QueryTextCashVoucher;
			EndIf;
			
			// Fill in the division in the movements Storno = A lie
			Query = New Query(QueryText);
			Query.SetParameter("Ref", TableRow.Recorder);
			
			//@skip-warning
			Selection = Query.Execute().Select();
			IsPatch = False;
			ReversedDocument = Undefined;
			While Selection.Next() Do
				If Not IsPatch And Selection.Patch Then
					IsPatch = True;
					ReversedDocument = Selection.ReversedDocument;
				EndIf;
				FillInDivisionInRecordsTable(RecordsTable, RecordTableHasBeenChanged, Selection);
			EndDo;
			
			If IsPatch Then
				// Fill in the division in the movements Storno = True
				Query.SetParameter("Ref", ReversedDocument);
				//@skip-warning
				Selection = Query.Execute().Select();
				While Selection.Next() Do
					FillInDivisionInRecordsTable(RecordsTable, RecordTableHasBeenChanged, Selection, True);
				EndDo;
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If RecordTableHasBeenChanged Then
				RecordSet.Load(RecordsTable);
				InfobaseUpdate.WriteRecordSet(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), TableRow.Recorder);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					TableRow.Recorder, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
	
	EndDo;
	
	InfobaseUpdateTM.RecordBadData(ExceptionsWhenUpdating, ObjectsProcessed, Parameters, AdditionalParameters);
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
	
EndProcedure

Procedure FillInDivisionInRecordsTable(RecordsTable, RecordTableHasBeenChanged, Selection, ReversingEntry = False)
	
	TheStructureOfTheSearch = New Structure("ReversingEntry", ReversingEntry);
	If Selection.FinRecordID <> Undefined Then
		TheStructureOfTheSearch.Insert("FinRecordID", Selection.FinRecordID);
	EndIf;
	
	RowsOfRecordTable = RecordsTable.FindRows(TheStructureOfTheSearch);
	For Each TableRow In RowsOfRecordTable Do
		If Not ValueIsFilled(TableRow.Department) And ValueIsFilled(Selection.Department) Then
			TableRow.Department = Selection.Department;
			RecordTableHasBeenChanged = True;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
