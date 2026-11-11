#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

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
	
	ReflectionParameters.ManResources.Add("ExciseAmountInCurrencyMgmt");
	ReflectionParameters.LocalResources.Add("ExciseAmountInCurrencyLocal");
	
	ReflectionParameters.DebitCondition = "FALSE";
	ReflectionParameters.ConditionCredit = "TRUE";
	
	ReflectionParameters.TypeOfAccountingData = Enums.AccountingDataTypes.Products;
	ReflectionParameters.StructureOfAnalytics = Common.CopyRecursive(
		DataSourcesCached.AnalyticsStructureByTypeOfAccountingData(ReflectionParameters.TypeOfAccountingData));
	ReflectionParameters.StructureOfAnalytics.Products.DataPath = "Products";
	ReflectionParameters.StructureOfAnalytics.Warehouse.Insert("Value", Undefined);
	ReflectionParameters.StructureOfAnalytics.InventoryOwnerAttribute.Insert("Value", Undefined);
	IdentifyIndicators(ReflectionParameters);
	
	If RegisterMetadata = Undefined Then
		RegisterMetadata = CreateRecordSet().Metadata();
	EndIf;
	
	FinancialAccountingByBalanceSheetRegisterData.FillReflectionParametersByRegisterMetadata(ReflectionParameters, RegisterMetadata);
	
	Return ReflectionParameters;
	
EndFunction

// Defines register metrics.
//
//
// Parameters:
//  Properties - Structure - containing the keys of the properties of Indicators, properties of Resources.
//
// Returns:
//  Map - The key is the name of the indicator.
//                 Value - the structure of the properties of the indicator.
//
Function Indicators(Properties) Export

	Indicators = New Map;
	
	PropertiesOfIndicators = Properties.PropertiesOfIndicators;
	ResourceProperties = Properties.ResourceProperties;
	
	ArrayOfResources = New Array;
	ArrayOfResources.Add(New Structure(ResourceProperties, "ExciseAmountInCurrencyMgmt", "CurrencyOfMan"));
	ArrayOfResources.Add(New Structure(ResourceProperties, "ExciseAmountInCurrencyLocal", "ComplCurrency"));
	Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount, New Structure(PropertiesOfIndicators, ArrayOfResources));

	Return Indicators;
	
EndFunction

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
	
	
	TypesOfRegistrarsReflectionOfDocumentsInInternationalAccounting = Metadata.InformationRegisters.DocumentPostingInFinancialAccounting.StandardAttributes.Recorder.Type;
	DataTable = InformationRegisters.JobsOfBackdateAdditionalDocumentPosting.TaskGenerationTable();
	
	For Each CurrentTypeOfTask In KindsOfTasks Do
	
		
		If CurrentTypeOfTask = Catalogs.BackdateJobKinds.RecordInFinancialAccounting Then
			TableOfDocumentsToBeReflected = InformationRegisters.DocumentPostingInFinancialAccounting.TableOfDocumentsToBeReflectedInInternationalAccounting();
			For Each CurrentData In DataForRegisteringTasks Do
				If TypesOfRegistrarsReflectionOfDocumentsInInternationalAccounting.ContainsType(TypeOf(CurrentData.Document)) Then
					NewRow = TableOfDocumentsToBeReflected.Add();
					FillPropertyValues(NewRow, CurrentData);
					NewRow.DateRecord = BegOfDay(CurrentData.TaskPeriod);
					NewRow.Period = BegOfDay(CurrentData.TaskPeriod);
				EndIf;
			EndDo;
			TableOfDocumentsToBeReflected.GroupBy("Document, Organization, DateRecord, Period");
			Return TableOfDocumentsToBeReflected;
		EndIf;
		If CurrentTypeOfTask <> Catalogs.BackdateJobKinds.RecordExciseRegisterRecords Then
			For Each CurrentData In DataForRegisteringTasks Do
				NewRow = DataTable.Add();
				FillPropertyValues(NewRow, CurrentData);
				NewRow.JobKind = CurrentTypeOfTask;
			EndDo;
		EndIf;
		
		CommonClientServer.SupplementTable(DataForRegisteringTasks, DataTable);
		
	EndDo;
	
	Return DataTable;

EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// Defines register indicators
//
// Parameters:
//  ReflectionParameters - See ParametersForReflectingRegisteredRecordsInFinancialAccounting
//
Procedure IdentifyIndicators(ReflectionParameters)
	
	// Excise Tax Amount
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("ExciseAmountInCurrencyMgmt");
	IndicatorReflectionParameters.LocalResources.Add("ExciseAmountInCurrencyLocal");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditExpenseAmount, IndicatorReflectionParameters);
	
	IndicatorReflectionParameters = Enums.IndicatorsOfAnalyticalRegisters.IndicatorReflectionParameters();
	IndicatorReflectionParameters.ManResources.Add("ExciseAmountInCurrencyMgmt");
	IndicatorReflectionParameters.LocalResources.Add("0");
	IndicatorReflectionParameters.ResourcesQuantity.Add("0");
	ReflectionParameters.Indicators.Insert(Enums.IndicatorsOfAnalyticalRegisters.AdditionalExpensesAmountExcludingVAT, IndicatorReflectionParameters);
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.RegisterRecordsByExcises.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.48";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e0ca9ea7-01a0-4ba0-888a-ba5aac55c97f");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.RegisterRecordsByExcises.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	Comment = NStr("ru = 'Удаляет записи в регстре ""Движения по акцизам"" для непроведенных документов';
					|vi = 'Deletes records in the ""Register records by excises"" register for unposted documents';
					|en = 'Deletes records in the ""Register records by excises"" register for unposted documents'; fa = 'Deletes records in the ""Register records by excises"" register for unposted documents';
					|it = 'Deletes records in the ""Register records by excises"" register for unposted documents';
					|pl = 'Deletes records in the ""Register records by excises"" register for unposted documents';
					|tr = 'Kaydedilmemiş belgeler için ""Özel tüketim vergisi kayıtları"" kayıt tablosundaki kayıtları siler'");
	
	Handler.Comment = Comment;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.InventoryConsumption.FullName());
	ItemsToRead.Add(Metadata.Documents.IntercompanyGoodsReturn.FullName());
	ItemsToRead.Add(Metadata.Documents.ReturnOfGoodsFromCustomer.FullName());
	ItemsToRead.Add(Metadata.Documents.SaleAdjustment.FullName());
	ItemsToRead.Add(Metadata.Documents.CustomerInvoiceIntercompany.FullName());
	ItemsToRead.Add(Metadata.Documents.CustomerInvoice.FullName());
	ItemsToRead.Add(Metadata.Documents.WriteOffOfGoodsShortages.FullName());
	
	ItemsToRead.Add(Metadata.Documents.ReversingEntry.FullName());
	ItemsToRead.Add(Metadata.Documents.CCDImport.FullName());
	ItemsToRead.Add(Metadata.Documents.ApplicationForImportationOfGoods.FullName());
	
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.RegisterRecordsByExcises.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.RegisterRecordsByExcises.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName	= Metadata.AccumulationRegisters.RegisterRecordsByExcises.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query();
	Query.Text = "SELECT
		|	RegisterOfRegisteredRecordsOfExciseTaxes.Recorder
		|FROM AccumulationRegister.RegisterRecordsByExcises AS RegisterOfRegisteredRecordsOfExciseTaxes
		|WHERE
		|	NOT RegisterOfRegisteredRecordsOfExciseTaxes.Recorder.Posted";
		
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

// An update handler.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	RegisterMetadata = Metadata.AccumulationRegisters.RegisterRecordsByExcises;
	FullRegisterName = RegisterMetadata.FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	For Each DataString1 In UpdatedData Do
		Recorder = DataString1.Recorder;
		
		ExceptionReason = "";
		Recommendation = "";
		
		ListOfDescriptions = New Array;
		ListOfDescriptions.Add(NStr("ru = 'Не удалось обработать набор записей регистра накопления ""Движения по акцизам"":';
									|vi = 'Cannot process the ""Register records by excises"" accumulation register record set:';
									|en = 'Cannot process the ""Register records by excises"" accumulation register record set:'; fa = 'Cannot process the ""Register records by excises"" accumulation register record set:';
									|it = 'Cannot process the ""Register records by excises"" accumulation register record set:';
									|pl = 'Cannot process the ""Register records by excises"" accumulation register record set:';
									|tr = '""Özel tüketim vergisi kayıtları"" kayıt tablosundaki kayıt kümesi aşağıdaki nedenle işlenemedi:'"));
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.RegisterRecordsByExcises.RecordSet");
			LockItem.SetValue("Recorder", Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
				
			ExceptionReason = "BadData";
			Recommendation = NStr("ru = 'Перепроведите документ вручную.';
									|vi = 'Repost the document manually.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Repost the document manually.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			RecordSet = AccumulationRegisters.RegisterRecordsByExcises.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Recorder);
			RecordSet.Read();
			RecordSet.Clear();
			ExceptionReason = "Record";
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Recorder);
			
			If ExceptionReason = "BadData" Then
				
				InfobaseUpdate.FileIssueWithData(Recorder, Recommendation, Parameters);
				
			ElsIf ExceptionReason = "Record" Then
				
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
	
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndIf