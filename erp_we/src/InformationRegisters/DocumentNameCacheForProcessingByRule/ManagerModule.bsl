#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.DocumentNameCacheForProcessingByRule.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.58";
	Handler.ExecutionMode = "Deferred";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Id = New UUID("cbb2625b-7ee1-49e7-abf0-a925b2ed389d");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.DocumentNameCacheForProcessingByRule.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	Handler.Comment = NStr("vi = 'Điền chiều đo ""Dạng chứng từ"":';
							|ru = 'Заполнение измерения ""Вид документа"":';
							|en = 'Fill in the ""Document kind"" dimension: '; fa = 'Fill in the ""Document kind"" dimension: ';
							|it = 'Fill in the ""Document kind"" dimension: ';
							|pl = 'Fill in the ""Document kind"" dimension: ';
							|tr = '""Belge türü"" boyutunun doldurulması:'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule.FullName();
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = FullRegisterName;

	Query = New Query;
	Query.Text = 
	"SELECT
	|	RegisterData.Rule AS Rule,
	|	RegisterData.DeleteDocumentKindName AS DeleteDocumentKindName
	|FROM
	|	InformationRegister.DocumentNameCacheForProcessingByRule AS RegisterData
	|WHERE
	|	RegisterData.DeleteDocumentKindName <> """"
	|	AND RegisterData.DocumentKind = VALUE(Catalog.MetadataObjectIDs.EmptyRef)";
	
	ResultTable1 = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, ResultTable1, AdditionalParameters);
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	ObjectMetadata = Metadata.InformationRegisters.DocumentNameCacheForProcessingByRule;
	FullObjectName  = ObjectMetadata.FullName();
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName) Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	MaximumNumberOfAnalysts = BudgetingClientServer.MaximumNumberOfAnalysts();
	
	For Each RegisterRecord In UpdatedData Do
		
		RecordSet = InformationRegisters.DocumentNameCacheForProcessingByRule.CreateRecordSet();
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = "Block";
			Block = New DataLock;
			LockItem = Block.Add(FullObjectName);
			
			For Each DimensionItem In UpdatedData.Columns Do
				If DimensionItem.Name = "DocumentKind" Then
					Continue;
				EndIf;
				LockItem.SetValue(DimensionItem.Name, RegisterRecord[DimensionItem.Name]);
				RecordSet.Filter[DimensionItem.Name].Set(RegisterRecord[DimensionItem.Name]);
			EndDo;
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();

			ExceptionReason = "BadData";
			RecordSet.Read();
			Counter = 0;
			While Counter < RecordSet.Count() Do
				Record = RecordSet[Counter];
				FullDocumentName = StringFunctionsClientServer.SubstituteParametersToString("Document.%1", Record.DeleteDocumentKindName);
				DocumentKind = Common.MetadataObjectID(FullDocumentName, False);
				If DocumentKind = Null Then
					RecordSet.Delete(Counter);
				Else
					Record.DocumentKind = DocumentKind;
					Counter = Counter + 1;
				EndIf;
			EndDo;
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			If ExceptionReason = "BadData" Then
				InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), RegisterRecord.DeleteDocumentKindName);
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
				InfobaseUpdate.FileIssueWithData(RegisterRecord.DeleteDocumentKindName,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
		FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf