#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates the request text for generating movements in the "Assets and liabilities" register.
// 
// Parameters:
// 	ThereAreTTLotsOfOtherExpenses - Boolean
// Returns:
// 	String - 
//
Function QueryTextTableOtherAssetsLiabilities(ThereAreTTLotsOfOtherExpenses = True) Export
	
	QueryText = "
	// Reflection of the decrease in liabilities of the source organization.
	|SELECT
	|	Rows.Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	Rows.Organization AS Organization,
	|	Rows.Department AS Department,
	|	Rows.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	Rows.Organization AS Dimension,
	|	SUM(Rows.Sum) AS Sum
	|FROM
	|	TTOtherExpenses_ AS Rows
	|WHERE
	|	Rows.CompanyRecipient <> Rows.Organization
	|GROUP BY
	|	Rows.Period,
	|	Rows.Organization,
	|	Rows.Department,
	|	Rows.LineOfBusiness
	|
	// Reflection of the increase in liabilities of the recipient organization.
	|UNION ALL
	|SELECT
	|	Rows.Period AS Period,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	Rows.CompanyRecipient AS Organization,
	|	Rows.Department AS Department,
	|	Rows.LineOfBusiness AS LineOfBusiness,
	|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
	|	Rows.CompanyRecipient AS Dimension,
	|	SUM(Rows.Sum) AS Sum
	|FROM
	|	TTOtherExpenses_ AS Rows
	|WHERE
	|	Rows.CompanyRecipient <> Rows.Organization
	|GROUP BY
	|	Rows.Period,
	|	Rows.CompanyRecipient,
	|	Rows.Department,
	|	Rows.LineOfBusiness
	|";
	If ThereAreTTLotsOfOtherExpenses Then
		QueryText = QueryText + "UNION ALL" + "
		// Reflection of the decrease in liabilities of the source organization.
		|SELECT
		|	Rows.Period AS Period,
		|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
		|	Rows.Organization AS Organization,
		|	Rows.Department AS Department,
		|	Rows.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
		|	Rows.Organization AS Dimension,
		|	SUM(Rows.Cost) AS Sum
		|FROM
		|	TTLotsOfOtherExpenses AS Rows
		|WHERE
		|	Rows.CompanyRecipient <> Rows.Organization
		|GROUP BY
		|	Rows.Period,
		|	Rows.Organization,
		|	Rows.Department,
		|	Rows.LineOfBusiness
		|
		// Reflection of the increase in liabilities of the recipient organization.
		|UNION ALL
		|SELECT
		|	Rows.Period AS Period,
		|	VALUE(AccumulationRecordType.Expense) AS RecordType,
		|	Rows.CompanyRecipient AS Organization,
		|	Rows.Department AS Department,
		|	Rows.LineOfBusiness AS LineOfBusiness,
		|	VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss) AS AssetRef,
		|	Rows.CompanyRecipient AS Dimension,
		|	SUM(Rows.Cost) AS Sum
		|FROM
		|	TTLotsOfOtherExpenses AS Rows
		|WHERE
		|	Rows.CompanyRecipient <> Rows.Organization
		|GROUP BY
		|	Rows.Period,
		|	Rows.CompanyRecipient,
		|	Rows.Department,
		|	Rows.LineOfBusiness
		|";
	EndIf;
	Return QueryText;
	
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
	|	ValueAllowed(Organization)";

EndProcedure

// End StandardSubsystems.AccessManagement

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

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.OtherAssetsLiabilities.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.27.48";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e8ea5d4b-ae61-ea32-a34e-ce03ce438a26");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.OtherAssetsLiabilities.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("ru = 'Обновление регистра ""Прочие активы и пассивы"":';
								|vi = 'Update the ""Other assets and liabilities"" register:';
								|en = 'Update the ""Other assets and liabilities"" register:'; fa = 'Update the ""Other assets and liabilities"" register:';
								|it = 'Update the ""Other assets and liabilities"" register:';
								|pl = 'Update the ""Other assets and liabilities"" register:';
								|tr = '""Diğer varlıklar ve yükümlülükler"" kayıt tablosunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("ru = '- Заменяет статью ""Доходы текущего периода"" на ""Прибыли и убытки"" в движениях регистра ""Активы и пассивы"" незаблокированных периодов.';
								|vi = '-  Replaces the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records of unlocked periods.';
								|en = '-  Replaces the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records of unlocked periods.'; fa = '-  Replaces the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records of unlocked periods.';
								|it = '-  Replaces the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records of unlocked periods.';
								|pl = '-  Replaces the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records of unlocked periods.';
								|tr = 'Kilitsiz dönemlere ait ""Varlıklar ve yükümlülükler"" kayıt tablosu kayıtlarındaki ""Mevcut dönem gelirleri"" kalemini ""Kâr - zarar"" kalemi ile değiştirir.'"));
	ListOfDescriptions.Add(NStr("ru = '- Удаляет движения по непроведенным документам с акцизами незаблокированных периодов.';
								|vi = '- Deletes records for unposted documents with excises in unlocked periods.';
								|en = '- Deletes records for unposted documents with excises in unlocked periods.'; fa = '- Deletes records for unposted documents with excises in unlocked periods.';
								|it = '- Deletes records for unposted documents with excises in unlocked periods.';
								|pl = '- Deletes records for unposted documents with excises in unlocked periods.';
								|tr = '- Kilitsiz dönemlere ait kaydedilmemiş belgelerdeki özel tüketim vergisi kayıtlarını siler'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.OtherAssetsLiabilities.FullName());
	ItemsToRead.Add(Metadata.Documents.InventoryConsumption.FullName());
	ItemsToRead.Add(Metadata.Documents.WriteOffOfGoodsShortages.FullName());
	ItemsToRead.Add(Metadata.Documents.ReversingEntry.FullName());
	
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.OtherAssetsLiabilities.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.OtherAssetsLiabilities.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.OtherAssetsLiabilities";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Parameters.Insert("IDOfUnusedFinRecord", DocumentsPosting.IDOfUnusedFinRecord());
	Query.Text = "
	|SELECT DISTINCT
	|	RegisterRecords.Recorder AS Ref
	|FROM
	|	AccumulationRegister.OtherAssetsLiabilities AS RegisterRecords
	|	LEFT JOIN InformationRegister.SetUpLockFromChanges AS Block
	|	ON Block.Organization = RegisterRecords.Organization
	|WHERE
	|	RegisterRecords.AssetRef = VALUE(ChartOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodIncome)
	|	AND RegisterRecords.Active
	|	AND ISNULL(ENDOFPERIOD(Block.LockUntil, MONTH), DATETIME(1,1,1)) < RegisterRecords.Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RegisterRecords.Recorder AS Ref
	|FROM
	|	AccumulationRegister.OtherAssetsLiabilities AS RegisterRecords
	|	LEFT JOIN InformationRegister.SetUpLockFromChanges AS Block
	|	ON Block.Organization = RegisterRecords.Organization
	|	INNER JOIN Document.InventoryConsumption AS DocumentInventoryConsumption
	|		ON DocumentInventoryConsumption.Ref = RegisterRecords.Recorder
	|		AND NOT DocumentInventoryConsumption.Posted
	|WHERE
	|	RegisterRecords.Active
	|	AND ISNULL(ENDOFPERIOD(Block.LockUntil, MONTH), DATETIME(1,1,1)) < RegisterRecords.Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RegisterRecords.Recorder AS Ref
	|FROM
	|	AccumulationRegister.OtherAssetsLiabilities AS RegisterRecords
	|	LEFT JOIN InformationRegister.SetUpLockFromChanges AS Block
	|	ON Block.Organization = RegisterRecords.Organization
	|	INNER JOIN Document.WriteOffOfGoodsShortages AS DocumentWriteOffOfGoodsShortages
	|		ON DocumentWriteOffOfGoodsShortages.Ref = RegisterRecords.Recorder
	|		AND NOT DocumentWriteOffOfGoodsShortages.Posted
	|WHERE
	|	RegisterRecords.Active
	|	AND ISNULL(ENDOFPERIOD(Block.LockUntil, MONTH), DATETIME(1,1,1)) < RegisterRecords.Period
	|
	|UNION
	|
	|SELECT DISTINCT
	|	RegisterRecords.Recorder AS Ref
	|FROM
	|	AccumulationRegister.OtherAssetsLiabilities AS RegisterRecords
	|	LEFT JOIN InformationRegister.SetUpLockFromChanges AS Block
	|	ON Block.Organization = RegisterRecords.Organization
	|	INNER JOIN Document.ReversingEntry AS DocumentReversingEntry
	|		ON DocumentReversingEntry.Ref = RegisterRecords.Recorder
	|		AND NOT DocumentReversingEntry.Posted
	|WHERE
	|	RegisterRecords.Active
	|	AND ISNULL(ENDOFPERIOD(Block.LockUntil, MONTH), DATETIME(1,1,1)) < RegisterRecords.Period
	|";
	
	Recorders = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export

	FullRegisterName = "AccumulationRegister.OtherAssetsLiabilities";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	Recorders = UpdatedData.UnloadColumn("Recorder");
	
	Query = New Query;
	Query.SetParameter("Recorders", Recorders);
	Query.Text = "SELECT DISTINCT
	|	RegisterRecords.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.OtherAssetsLiabilities AS RegisterRecords
	|WHERE
	|	RegisterRecords.Recorder IN (&Recorders)
	|";

	SamplingLogger = Query.Execute().Select(QueryResultIteration.ByGroups);
	While SamplingLogger.Next() Do
		
		Recorder = SamplingLogger.Recorder;
		ExceptionReason = "";
		Recommendation = "";
	
		ListOfDescriptions = New Array;
		ListOfDescriptions.Add(NStr("ru = 'Не удалось выполнить замену статьи ""Доходы текущего периода"" на ""Прибыли и убытки"" в движениях регистра ""Активы и пассивы"" .';
									|vi = 'Cannot replace the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records.';
									|en = 'Cannot replace the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records.'; fa = 'Cannot replace the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records.';
									|it = 'Cannot replace the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records.';
									|pl = 'Cannot replace the ""Current period income"" item with ""Profit and loss"" in the ""Assets and liabilities"" register records.';
									|tr = '""Varlıklar ve yükümlülükler"" kaydı hareketlerinde ""cari dönem gelirleri"" kaleminin ""Kârlar ve zararlar"" ile değiştirilmesi işlemi gerçekleştirilemedi.'"));
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.OtherAssetsLiabilities.RecordSet");
			LockItem.SetValue("Recorder", Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
				
			ExceptionReason = "BadData";
			Recommendation = NStr("vi = 'Hãy kết chuyển lại chứng từ một cách thủ công.';
									|ru = 'Перепроведите документ вручную.';
									|en = 'Repost the document manually.'; fa = 'Repost the document manually.';
									|it = 'Перепроведите документ вручную.';
									|pl = 'Repost the document manually.';
									|tr = 'Belgeyi manuel olarak yeniden kaydedin.'");
			
			RecordSet = AccumulationRegisters.OtherAssetsLiabilities.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Recorder);
			RecordSet.Read();
			DocumentType = TypeOf(Recorder);
			
			If (DocumentType = Type("DocumentRef.InventoryConsumption")
				Or DocumentType = Type("DocumentRef.WriteOffOfGoodsShortages")
				Or DocumentType = Type("DocumentRef.ReversingEntry"))
				And Not Common.ObjectAttributeValue(Recorder, "Posted") = True Then
					RecordSet.Clear();
			EndIf;

			For Each Record In RecordSet Do
				If Record.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.ManBalanceCurrentPeriodIncome Then

					Record.AssetRef = ChartsOfCharacteristicTypes.AssetLiabilityItems.ProfitAndLoss;
				
				EndIf;
			EndDo;
			
			ExceptionReason = "Record";
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			TheStructureOfTheSearch = New Structure("Recorder", Recorder);
			Rows = UpdatedData.FindRows(TheStructureOfTheSearch);
			If Rows.Count() > 0 Then
				TMCommonUse.DeleteTableRows(UpdatedData, Rows);
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
	
	If UpdatedData.Count() > 0 Then 
		For Each String In UpdatedData Do 
			RecordSet = AccumulationRegisters.OtherAssetsLiabilities.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(String.Recorder);
			
			InfobaseUpdate.MarkProcessingCompletion(RecordSet);
		EndDo;
	EndIf;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, "AccumulationRegister.OtherAssetsLiabilities");

EndProcedure

#EndRegion

#EndRegion

#EndIf
