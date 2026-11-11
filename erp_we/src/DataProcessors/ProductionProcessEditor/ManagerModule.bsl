#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

#Region TimeConsumingOperations

Procedure RecordEditorDataInBackground(Parameters, StorageAddress) Export
	
	Result = RecordEditorData(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure CreateTypicalTechnicalProcessInBackground(Parameters, StorageAddress) Export
	
	Result = CreateTypicalTechnicalProcess(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Procedure GroupSubstitutionInBackground(Parameters, StorageAddress) Export
	
	Result = BulkReplacement(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region EditorIsIndividual

Function RecordEditorData(Parameters)
	
	Result = ProductionProcessEditorClientServer.ResultOfRecordingTechnicalProcessConstructor();
	
	Stage = Parameters.Stage;
	TechProcessParameters = Parameters.TechProcessParameters;
	
	Operations = InformationRegisters.QueueOfProductionOperations.OperationQueueConstructor();
	ProductionOperations = New Array;
	
	If TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_ Then
		For Each OperationData In Parameters.TransactionTable Do
			NewRow = Operations.Add();
			FillPropertyValues(NewRow, Parameters);
			FillPropertyValues(NewRow, OperationData);
			If ProductionProcessEditorClientServer.ThisOperationIsIndividual(OperationData) Then
				If ValueIsFilled(OperationData.ProductionOperation) Then
					StandardsLink = OperationData.ProductionOperation;
					StandardsObject = OperationData.ProductionOperation.GetObject();
				Else
					StandardsLink = Documents.ProductionOperation2_2.GetRef();
					StandardsObject = Documents.ProductionOperation2_2.CreateDocument();
					StandardsObject.SetNewObjectRef(StandardsLink);
				EndIf;
				If OperationData.Modified Then
					FillInDocumentOfStorageOfStandards(StandardsObject, OperationData, Parameters);
					ProductionOperations.Add(StandardsObject);
				EndIf;
				NewRow.ProductionOperation = StandardsLink;
			EndIf;
		EndDo;
		
		
	EndIf;
	DeleteProductionOperations = DocumentsToDelete(Operations, Parameters);
	
	BeginTransaction();
	Try
		
		DataLock = InformationRegisters.QueueOfProductionOperations.BlockingDataForQueueCalculation(Stage);
		LockItem = DataLock.Add("InformationRegister.TechnologicalProcessesOfProductionStages");
		LockItem.SetValue("Stage", Stage);
		LockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		If Parameters.Property("StageDataToUpdate") Then
			
			Result.ThereAreStageRecordingErrors = True;
			
			StageObject = Stage.GetObject();
			For Each KeyAndValue In Parameters.StageDataToUpdate Do
				StageObject[KeyAndValue.Key].Load(KeyAndValue.Value);
			EndDo;
			If StageObject.CheckFilling() Then
				StageObject.Write(DocumentWriteMode.Posting);
			Else
				Raise NStr("vi = 'Lỗi ghi lại công đoạn';
							|ru = 'Ошибка записи этапа';
							|en = 'An error occurred when saving the stage'; fa = 'An error occurred when saving the stage';
							|it = 'An error occurred when saving the stage';
							|pl = 'An error occurred when saving the stage';
							|tr = 'Aşamanın kayıt hatası'");
			EndIf;
			
			Result.ThereAreStageRecordingErrors = False;
			
		EndIf;
		
		Result.ThereAreErrorsInRecordingTechnicalProcess = True;
		
		InformationRegisters.TechnologicalProcessesOfProductionStages.RecordProcessParameters(
			Stage, TechProcessParameters, Parameters.SaveTechnologicalProcessLimitations);
		
		For Each ProductionOperation In ProductionOperations Do
			ProductionOperation.Write(
				?(ProductionOperation.DataExchange.Load, DocumentWriteMode.Write, DocumentWriteMode.Posting));
		EndDo;
		
		For Each ProductionOperation In DeleteProductionOperations Do
			ProductionOperation.SetDeletionMark(True);
		EndDo;
		
		If TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_ Then
			Set = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
			Set.Filter.Stage.Set(Stage);
			Set.Load(Operations);
			Set.Write();
		EndIf;
		
		InformationRegisters.QueueOfProductionOperations.AddTaskToQueueCalculation(Stage);
		
		Result.ThereAreErrorsInRecordingTechnicalProcess = False;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		FillInResultOfTechnicalProcessRecordInCaseOfError(Result, ErrorInfo());
		
		WriteLogEvent(EventLogEventName(),
			EventLogLevel.Error,,,Result.ErrorTextLR);
		
	EndTry;
	
	If IsBlankString(Result.BriefErrorDescription) Then
		InformationRegisters.ProductionStageStates.ReflectStateOfStages(Stage);
	EndIf;
	
	Return Result;
	
EndFunction

Function CreateTypicalTechnicalProcess(Parameters)
	
	Result = ProductionProcessEditorClientServer.ResultOfCreatingTypicalTechnicalProcessConstructor();
	Result.TechnologicalProcess = Catalogs.TechnologicalProcesses.GetRef();
	
	Object = Catalogs.TechnologicalProcesses.CreateItem();
	Object.Description = Parameters.PresentationStage;
	Object.Department = Parameters.Department;
	Object.ForFinishedProductsKind = Parameters.ProductKind;
	Object.Status = Enums.TechnologicalProcessStatuses.UnderDevelopment;
	Object.EmployeeResponsible = Users.CurrentUser();
	Object.SetNewObjectRef(Result.TechnologicalProcess);
	
	Operations = New Array();
	For Each OperationData In Parameters.TransactionTable Do
		OperationRef = Catalogs.ManufacturingOperations.GetRef();
		OperationObject = Catalogs.ManufacturingOperations.CreateItem();
		OperationObject.SetNewObjectRef(OperationRef);
		OperationObject.Owner = Result.TechnologicalProcess;
		FillPropertyValues(OperationObject, OperationData);
		ResourcesOfOperation = Parameters.ResourcesOfOperations.Get(OperationData.OperationID);
		If ResourcesOfOperation <> Undefined Then
			For Each TSName In StrSplit("MaterialsAndServices,LaborCosts", ",") Do
				If Not ResourcesOfOperation.Property(TSName) Then
					Continue;
				EndIf;
				For Each String In ResourcesOfOperation[TSName] Do
					Table = Object[TSName]; // TabularSection
					NewRow = Table.Add();
					FillPropertyValues(NewRow, String);
					NewRow.OperationEdit = OperationRef;
				EndDo;
			EndDo;
		EndIf;
		Operations.Add(OperationObject);
	EndDo;
	
	BeginTransaction();
	Try
		
		Object.Write();
		
		For Each OperationObject In Operations Do
			OperationObject.Write();
		EndDo;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		ErrorText = StrTemplate(NStr("vi = 'Không thể tạo quy trình công nghệ do: %1';
									|ru = 'Не удалось создать технологический процесс по причине: %1';
									|en = 'Cannot create a technological process. Reason: %1'; fa = 'Cannot create a technological process. Reason: %1';
									|it = 'Cannot create a technological process. Reason: %1';
									|pl = 'Cannot create a technological process. Reason: %1';
									|tr = 'Teknolojik sürecin oluşturulamama nedeni: %1'"),
			ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			
		WriteLogEvent(EventLogEventName(),
			EventLogLevel.Error,,,ErrorText);
			
		Result.HasErrors = True;
		Result.TechnologicalProcess = Undefined;
		
	EndTry;
	
	Return Result;
	
EndFunction

Procedure FillInDocumentOfStorageOfStandards(StandardsObject, OperationData, Parameters)
	
	If StandardsObject.IsNew() Then
		StandardsObject.Fill(Parameters.Stage);
		StandardsObject.Date   = CurrentSessionDate();
		StandardsObject.Department = Parameters.Department;
		StandardsObject.EmployeeResponsible = Users.CurrentUser();
	Else
		StandardsObject.DeletionMark = False;
	EndIf;
	
	If OperationData.ReadOnly Then
		
		FillPropertyValues(StandardsObject, OperationData, "OperationNumber,NextOperation");
		
	Else
		
		StandardsObject.Status = Enums.ProductionOperationStatuses.BeingGenerated;
		
		FillPropertyValues(StandardsObject, ProductionAccountingClientServer.StructureOfResultsConstructor());
		StandardsObject.Protocol.Clear();
		
		FillPropertyValues(StandardsObject, OperationData);
		StandardsObject.Comment = OperationData["LongDesc"];
		StandardsObject.Count  = OperationData["Required2"];
		
		ResourcesOfOperation = Parameters.ResourcesOfOperations.Get(OperationData.OperationID);
		If ResourcesOfOperation <> Undefined Then
			ResourcesMap = New Structure;
			ResourcesMap.Insert("ManufacturedProducts",  "ManufacturedProducts");
			ResourcesMap.Insert("MaterialsAndWorks", "MaterialsAndServices");
			ResourcesMap.Insert("LaborCosts",     "LaborCosts");
			For Each KeyAndValue In ResourcesMap Do
				Table = Undefined;
				If ResourcesOfOperation.Property(KeyAndValue.Value, Table) Then
					StandardsObject[KeyAndValue.Key].Load(Table);
				EndIf;
			EndDo;
		EndIf;
		
		Documents.ProductionOperation2_2.RecalculateExecutionTime(StandardsObject);
		
	EndIf;
	
	StandardsObject.IncludedInTechnologicalProcess = True;
	
	If Not StandardsObject.CheckFilling() Then
		StandardsObject.DataExchange.Load = True;
	EndIf;
	
	StandardsObject.SetGroupProcessingMode();
	StandardsObject.SetProductionProcessEditorMode();
	
EndProcedure

Function DocumentsToDelete(Operations, Parameters)
	
	QueryText = "
	|SELECT
	|	Operations.Ref AS ProductionOperation
	|FROM
	|	Document.ProductionOperation2_2 AS Operations
	|WHERE
	|	NOT Operations.BasedOnMasterData
	|	AND Operations.IncludedInTechnologicalProcess
	|	AND NOT Operations.DeletionMark
	|	AND Operations.Stage = &Stage";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stage", Parameters.Stage);
	
	Result = Query.Execute().Unload().UnloadColumn("ProductionOperation");
	Result = CommonClientServer.ArraysDifference(Result, Operations.UnloadColumn("ProductionOperation"));
	
	For IndexOf = 0 To Result.UBound() Do
		Result[IndexOf] = Result[IndexOf].GetObject();
		Result[IndexOf].SetGroupProcessingMode();
		Result[IndexOf].SetProductionProcessEditorMode();
	EndDo;
	
	Return Result;
	
EndFunction

// The name of the log event.
// 
// Returns:
//  String
Function EventLogEventName() Export
	
	Return NStr("vi = 'Bộ soạn quy trình sản xuất';
				|ru = 'Редактор производственного процесса';
				|en = 'Production process editor'; fa = 'ویرایشگر فرایند تولید';
				|it = 'Editor del processo di produzione';
				|pl = 'Edytor procesu produkcyjnego';
				|tr = 'Üretim süreci düzenleyicisi'");
	
EndFunction

#EndRegion

#Region GroupReplacement

Function BulkReplacement(Parameters)
	
	Result = New Structure;
	Result.Insert("Success",    New Array);
	Result.Insert("Unsuccessfully",   New Map);
	Result.Insert("HasErrors", False);
	
	MainProductData = Undefined;
	TechProcessParameters   = Parameters.TechProcessParameters;
	Individual_         = TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_;
	
	StageData_1 = Documents.ProductionStage2_2.DataForCalculatingOperationQueue(Parameters.Stages, False);
	OrderData_3 = OrderData_3(Parameters.Stages);
	
	For Each Stage In Parameters.Stages Do
		
		Data_Stage = StageData_1[Stage];
		
		QueryOptions = ProductionProcessEditor.RequestParametersResourceMappingProcessStage();
		
		QueryOptions.ProcessTechnologyResources = TableOfProcessResources(Parameters, Data_Stage, OrderData_3[Stage]);
		QueryOptions.Stage               = Data_Stage.Ref;
		QueryOptions.Department      = Data_Stage.Department;
		QueryOptions.ReferenceOrder       = Data_Stage.ReferenceOrder;
		QueryOptions.UseFinishedProducts = False;
		
		MappingTable = ProductionProcessEditor.ResourceComparisonTableProcessStage(QueryOptions);
		
		BeginTransaction();
		Try
			
			ResultStage = ProductionProcessEditorClientServer.ResultOfRecordingTechnicalProcessConstructor();
			
			ResultStage.ThereAreStageRecordingErrors = True;
			
			UpdateStage(Stage, MappingTable);
			
			ResultStage.ThereAreStageRecordingErrors = False;
			
			ResultStage.ThereAreErrorsInRecordingTechnicalProcess = True;
			
			TechProcessParameters.TechnologicalProcessFactor = Data_Stage.TechnologicalProcessFactor;
			InformationRegisters.TechnologicalProcessesOfProductionStages.RecordProcessParameters(Stage, TechProcessParameters, False);
		
			If Individual_ Then
				TransactionTable = Parameters.TablesOfOperations.Get(Stage);
				If TransactionTable = Undefined Then
					TransactionTable = Parameters.TablesOfOperations.Get(Documents.ProductionStage2_2.EmptyRef());
				EndIf;
				Set = InformationRegisters.QueueOfProductionOperations.CreateRecordSet();
				Set.Filter.Stage.Set(Stage);
				For Each OperationData In TransactionTable Do
					If Parameters.CurrentProcessTechnology = Data_Stage.BillOfMaterials Then
						If MainProductData = Undefined Then
							MainProductData = Catalogs.BillsOfMaterials.MainProductSpecificationData(
									Data_Stage.BillOfMaterials,
									Data_Stage.Products,
									Data_Stage.Characteristic);
						EndIf;
						ZoomRatio = OperationData.TechnologicalProcessFactor
								* Data_Stage.NumberOfPackagesPlan
								* Data_Stage.PackagingFactor
								/ MainProductData.Count;
					Else
						ZoomRatio = TechProcessParameters.TechnologicalProcessFactor;
					EndIf;
					Record = Set.Add();
					FillPropertyValues(Record, OperationData);
					Record.Stage = Stage;
					Record.Department = Data_Stage.Department;
					Record.ReferenceOrder  = Data_Stage.ReferenceOrder;
					Record.TechnologicalProcessFactor = ZoomRatio;
					Record.Required2 = OperationData.Count * ZoomRatio;
				EndDo;
				Set.Write();
			EndIf;
			
			InformationRegisters.QueueOfProductionOperations.AddTaskToQueueCalculation(Stage);
			
			ResultStage.ThereAreErrorsInRecordingTechnicalProcess = False;
			
			Result.Success.Add(Stage);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			FillInResultOfTechnicalProcessRecordInCaseOfError(ResultStage, ErrorInfo());
			
			WriteLogEvent(EventLogEventName(),
				EventLogLevel.Error,,,ResultStage.ErrorTextLR);
			
			Result.Unsuccessfully.Insert(Stage, ResultStage);
			
		EndTry;
	
	EndDo;
	
	If Result.Success.Count() > 0 Then
		
		RegistersToBeReflected = DocumentsStates.RegistersToReflectStateOfOrders();
		RegistersToBeReflected.ProductionStageStates = True;
		
		DocumentsStates.AddTasksToStateOfOrders(
			Undefined,
			Result.Success,
			"Action_Refresh_State_operations",
			RegistersToBeReflected);
		
	EndIf;
	
	Result.HasErrors = Result.Unsuccessfully.Count() > 0;
	Return Result;
	
EndFunction

Function GroupReplacementListOfResources(ToArray = False)
	
	Result = "MaterialsAndServices,LaborCosts";
	Return ?(ToArray, StrSplit(Result, ","), Result);
	
EndFunction

Function TableOfProcessResources(Parameters, Data_Stage, TheseOrders_)
	
	ResourceTable = ProductionProcessEditor.TableOfProcessResources();
	
	CurrentProcessData = Undefined;
	NewProcessData   = TechProcessData(Parameters.ProcessTechnologyIsNew, Data_Stage, TheseOrders_);
	
	If Parameters.TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Individual_ Then
		
		CurrentProcessData = TechProcessData(Parameters.CurrentProcessTechnology, Data_Stage, TheseOrders_);
		ApplySelectionToProcessData(Parameters.CurrentProcessTechnology, CurrentProcessData, "LaborCosts", , Parameters.InterruptIdOperation);
		ApplySelectionToProcessData(Parameters.ProcessTechnologyIsNew, NewProcessData, "LaborCosts", Parameters.OperationContinueId);
		
	EndIf;
	
	AddProcessDataToTable(ResourceTable, CurrentProcessData);
	AddProcessDataToTable(ResourceTable, NewProcessData);
	ProductionServer.CollapseValueTable(ResourceTable,,"Count");
	
	Return ResourceTable;
	
EndFunction

Function OrderData_3(Stages)
	
	Result = New Map;
	
	QueryText =
	"SELECT
	|	Stages.Ref                     AS Stage,
	|	Stages.ReferenceOrder.EarliestStartDate AS ProductionStart,
	|	Stages.ReferenceOrder.Department AS ProductionDispatcherBusinessUnit
	|FROM
	|	Document.ProductionStage2_2 AS Stages
	|WHERE
	|	Stages.Ref IN (&Stages)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stages", Stages);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		TheseOrders_ = New Structure("ProductionStart,ProductionDispatcherBusinessUnit");
		FillPropertyValues(TheseOrders_, Selection);
		Result.Insert(Selection.Stage, TheseOrders_);
	EndDo;
	
	Return Result;
	
EndFunction

Function TechProcessData(TechnologicalProcess, Data_Stage, TheseOrders_)
	
	Result = Undefined;
	
	ListOfData = GroupReplacementListOfResources()+",Operations";
	
	If TypeOf(TechnologicalProcess) = Type("CatalogRef.BillsOfMaterials") Then
		
		ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
		ItemData_3.Products = Data_Stage.Products;
		ItemData_3.Characteristic = Data_Stage.Characteristic;
		ItemData_3.BillOfMaterials = Data_Stage.TechnologicalProcess;
		ItemData_3.ProductionStart = TheseOrders_.ProductionStart;
		ItemData_3.ProductionDispatcherBusinessUnit = TheseOrders_.ProductionDispatcherBusinessUnit;
		ItemData_3.LineOfBusiness = Data_Stage.LineOfBusiness;
		ItemData_3.Count = Data_Stage.NumberOfPackagesPlan * Data_Stage.PackagingFactor;
		
		SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(ListOfData);
		SelectionParameters.OverridingReleasePartySetting.Use = True;
		SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
		SelectionParameters.CalculateScheduleProductionAttribute = False;
		
		Result = Catalogs.BillsOfMaterials.SpecificationDataByProducts(
			ItemData_3,
			SelectionParameters,
			New Structure("Stage", Data_Stage.BOMStage));
	
	ElsIf TypeOf(TechnologicalProcess) = Type("CatalogRef.TechnologicalProcesses") Then
		
		ItemData_3 = Catalogs.TechnologicalProcesses.ItemData_3();
		ItemData_3.Products = Data_Stage.Products;
		ItemData_3.Characteristic = Data_Stage.Characteristic;
		ItemData_3.BillOfMaterials = Data_Stage.BillOfMaterials;
		ItemData_3.ProductionStart = TheseOrders_.ProductionStart;
		ItemData_3.ProductionDispatcherBusinessUnit = TheseOrders_.ProductionDispatcherBusinessUnit;
		ItemData_3.LineOfBusiness = Data_Stage.LineOfBusiness;
		ItemData_3.Count = Data_Stage.NumberOfPackagesPlan * Data_Stage.PackagingFactor;
		
		SelectionParameters = Catalogs.TechnologicalProcesses.DataSamplingParameters(ListOfData);
		
		Result = Catalogs.TechnologicalProcesses.ProcessDataByNomenclature(
			TechnologicalProcess,
			Data_Stage.TechnologicalProcessFactor,
			ItemData_3,
			SelectionParameters);
		
	ElsIf TypeOf(TechnologicalProcess) = Type("CatalogRef.RouteSheets") Then
	
		Result = Catalogs.RouteSheets.RouteMapData(
			TechnologicalProcess,
			Data_Stage.TechnologicalProcessFactor,
			Undefined,
			Undefined,
			"UsedMaterials,LaborCosts,Operations");
		Result.Insert("MaterialsAndServices", Result.UsedMaterials);
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AddProcessDataToTable(ResourceTable, TechProcessData)
	
	If TechProcessData = Undefined Then
		Return;
	EndIf;
	
	For Each TSName In GroupReplacementListOfResources(True) Do
		
		For Each String In TechProcessData[TSName] Do
			NewRow = ResourceTable.Add();
			FillPropertyValues(NewRow, String);
			NewRow.TSName = TSName;
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure ApplySelectionToProcessData(TechnologicalProcess, TechProcessData, ListOfData, IdInitial = Undefined, DestinationIdentifier = Undefined)
	
	Used = (IdInitial = Undefined);
	
	For IndexOf = 0 To TechProcessData.Operations.Count() -1 Do
		
		OperationData = TechProcessData.Operations[IndexOf];
		
		If OperationData.OperationID = IdInitial Then
			Used = Not Used;
		EndIf;
		
		If Not Used Then
			
			For Each TSName In StrSplit(ListOfData, ",") Do
				
				RowsArray = New Array;
				
				If TypeOf(TechnologicalProcess) = Type("CatalogRef.BillsOfMaterials") Then
					For Each NSIString In TechProcessData[TSName] Do
						If Catalogs.BillsOfMaterials.DataLineOfBillOfMaterialsBelongsToOperation(OperationData, NSIString) Then
							RowsArray.Add(NSIString);
						EndIf;
					EndDo;
				Else
					RowsArray = TechProcessData[TSName].FindRows(New Structure("Operation", OperationData.Operation));
				EndIf;
			
				For Each String In RowsArray Do
					TechProcessData[TSName].Delete(String);
				EndDo;
			
			EndDo;
			
		EndIf;
		
		If OperationData.OperationID = DestinationIdentifier Then
			Used = Not Used;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure UpdateStage(Stage, MappingTable)
	
	If MappingTable.Find(True, "IsChanged") = Undefined Then
		Return;
	EndIf;
	
	StageObject                    = Undefined;
	ParametersForFillingAssignments = Undefined;
	CachedValues          = Undefined;
	
	For Each StringAction In MappingTable Do
		
		TSName = StringAction.TSName;
		StageTSName = ?(TSName = "MaterialsAndServices", "SupplyWithMaterialsAndWorks", TSName);
		SearchFields = ?(TSName = "MaterialsAndServices", "Products,Characteristic", "WorkKind");
		
		ProductionProcessEditorClientServer.FillInDefaultActionParameters(StringAction, StageTSName);
		
		If Not StringAction.Mark Then
			Continue;
		EndIf;
		
		If StageObject = Undefined Then
			StageObject = Stage.GetObject();
		EndIf;
		
		DocumentTable = StageObject[StageTSName]; // TabularSection
		
		TheStructureOfTheSearch1 = New Structure(SearchFields);
		TheStructureOfTheSearch2 = New Structure(SearchFields);
		FillPropertyValues(TheStructureOfTheSearch1, StringAction);
		
		ProcessLines = New Array;
		DeleteRows_    = New Array;
		
		If StringAction.Action = ProductionProcessEditorClientServer.ActionAdd() Then
			
			NewRow = DocumentTable.Add();
			FillPropertyValues(NewRow, StringAction);
			
			NewRow.Count    = StringAction.NumberOfTechnicalProcesses - StringAction.CountStage;
			NewRow.Department = StageObject.Department;
		
			If StageTSName = "SupplyWithMaterialsAndWorks" Then
				If ParametersForFillingAssignments = Undefined Then
					ParametersForFillingAssignments = ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
						StageObject, StageObject.ManufacturedProducts);
				EndIf;
				NewRow.SupplyAssignment = ParametersForFillingAssignments.AssignmentMaterials;
				If NewRow.WithAssignment Then
					NewRow.Purpose = ParametersForFillingAssignments.AssignmentMaterials;
				EndIf;
				If StringAction.ItemsType = Enums.ItemsTypes.Work_5 Then
					NewRow.SupplyOption = ?(NewRow.WithAssignment, Enums.SupplyOptions.ToSupply, Enums.SupplyOptions.NotRequired);
				Else
					NewRow.SupplyOption = Enums.SupplyOptions.ToSupply;
				EndIf;
			EndIf;
			
			ProcessLines.Add(NewRow);
		
		ElsIf StringAction.Action = ProductionProcessEditorClientServer.ZoomInAction() Then
			
			QuantityIncreaseTotal = StringAction.NumberOfTechnicalProcesses - StringAction.CountStage;
			
			For IndexOf = 0 To DocumentTable.Count() - 1 Do
				String = DocumentTable[IndexOf];
				FillPropertyValues(TheStructureOfTheSearch2, String);
				If Common.DataMatch(TheStructureOfTheSearch1, TheStructureOfTheSearch2)
					And ProductionProcessEditorClientServer.YouCanChangeStageString(StageTSName, String, StringAction.Action) Then
					String.Count = String.Count + QuantityIncreaseTotal;
					ProcessLines.Add(String);
				EndIf;
			EndDo;
			
		ElsIf StringAction.Action = ProductionProcessEditorClientServer.ReduceAction() Then
			
			QuantityReduceTotal = StringAction.CountStage - StringAction.NumberOfTechnicalProcesses;
			
			For IndexOf = 0 To DocumentTable.Count() - 1 Do
				String = DocumentTable[IndexOf];
				FillPropertyValues(TheStructureOfTheSearch2, String);
				If Common.DataMatch(TheStructureOfTheSearch1, TheStructureOfTheSearch2)
						And ProductionProcessEditorClientServer.YouCanChangeStageString(StageTSName, String, StringAction.Action) Then
					If QuantityReduceTotal > 0 Then
						ReduceNumber = Min(String.Count, QuantityReduceTotal);
						String.Count = String.Count - ReduceNumber;
						QuantityReduceTotal = QuantityReduceTotal - ReduceNumber;
						If String.Count > 0 Then
							ProcessLines.Add(String);
						Else
							DeleteRows_.Add(String);
						EndIf;
					EndIf;
				EndIf;
			EndDo;
		
		ElsIf StringAction.Action = ProductionProcessEditorClientServer.ActionDelete() Then
			
			CommonClientServer.SupplementArray(DeleteRows_, DocumentTable.FindRows(TheStructureOfTheSearch1));
		
		EndIf;
		
		If TSName = "MaterialsAndServices" Then
			StructureOfActions = New Structure;
			StructureOfActions.Insert("RecalculateNumberOfPackages");
			For Each LineOfATabularSection In ProcessLines Do
				BatchProcessingOfTablePartServer.ProcessTSString(LineOfATabularSection, StructureOfActions, CachedValues);
			EndDo;
		EndIf;
		
		For Each String In DeleteRows_ Do
			DocumentTable.Delete(String);
		EndDo;
		
	EndDo;
	
	If StageObject <> Undefined
		And StageObject.Modified() Then
		
		If StageObject.CheckFilling() Then
			StageObject.Write(DocumentWriteMode.Posting);
		Else
			Raise StrTemplate(NStr("vi = 'Lỗi ghi lại công đoạn %1';
									|ru = 'Ошибка записи этапа %1';
									|en = 'An error occurred when saving the ""%1"" stage'; fa = 'An error occurred when saving the ""%1"" stage';
									|it = 'An error occurred when saving the ""%1"" stage';
									|pl = 'An error occurred when saving the ""%1"" stage';
									|tr = '%1 aşamasının kayıt hatası'"), Stage);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Other

Procedure FillInResultOfTechnicalProcessRecordInCaseOfError(RecordingResult, ErrorInfo)
	
	RecordingResult.BriefErrorDescription = ErrorProcessing.BriefErrorDescription(ErrorInfo);
	RecordingResult.DetailErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo);
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(RecordingResult.BriefErrorDescription);
	For Each Message In GetUserMessages(False) Do
		ArrayOfTexts.Add(Message.Text);
	EndDo;
	ArrayOfTexts.Add(NStr("vi = 'Chi tiết xem trong nhật ký sự kiện.';
							|ru = 'Подробнее см. в журнале регистрации.';
							|en = 'For more information, see the event log.'; fa = 'For more information, see the event log.';
							|it = 'Per maggiori informazioni visualizzare il registro.';
							|pl = 'Więcej zob. w dzienniku rejestracji.';
							|tr = 'Daha fazla bilgi için olay günlüğüne bakın'"));
	RecordingResult.ErrorText = StrConcat(ArrayOfTexts, Chars.LF);
	
	ArrayOfTexts.Add("");
	ArrayOfTexts.Add(RecordingResult.DetailErrorDescription);
	ArrayOfTexts.Add(StrTemplate(NStr("vi = 'Lỗi ghi lại công đoạn: %1';
										|ru = 'Ошибки записи этапа: %1';
										|en = 'An error occurred when saving the stage: %1'; fa = 'An error occurred when saving the stage: %1';
										|it = 'An error occurred when saving the stage: %1';
										|pl = 'An error occurred when saving the stage: %1';
										|tr = 'Aşamanın kayıt hatası: %1'"), RecordingResult.ThereAreStageRecordingErrors));
	ArrayOfTexts.Add(StrTemplate(NStr("vi = 'Lỗi ghi lại quy trình kỹ thuật: %1';
										|ru = 'Ошибки записи техпроцесса: %1';
										|en = 'An error occurred when saving the technological process: %1'; fa = 'An error occurred when saving the technological process: %1';
										|it = 'An error occurred when saving the technological process: %1';
										|pl = 'An error occurred when saving the technological process: %1';
										|tr = 'Teknolojik sürecin kayıt hatası: %1'"), RecordingResult.ThereAreErrorsInRecordingTechnicalProcess));
	RecordingResult.ErrorTextLR = StrConcat(ArrayOfTexts, Chars.LF);
	
EndProcedure

// Data of the technological process coefficient.
// 
// Parameters:
//  TechnologicalProcess - CatalogRef.TechnologicalProcesses
//  MainProductData - See Catalogs.BillsOfMaterials.MainProductSpecificationData
//  Reduce - Boolean - Reduce The Fraction
// 
// Returns:
//  See ProductionServer.Fraction
Function DataOfTechnologicalProcessCoefficient(TechnologicalProcess, MainProductData, Reduce = False) Export
	
	Result = ProductionServer.Fraction(1, 1);
	
	AttributesValues = Common.ObjectAttributesValues(TechnologicalProcess,
		"NumeratorFactor,FactorDenominator,CalculateFactor");
		
	If AttributesValues.CalculateFactor Then
		
		Result.Numerator   = AttributesValues.NumeratorFactor;
		Result.Denominator = AttributesValues.FactorDenominator;
		
	ElsIf MainProductData.Count > 0 Then
		
		Result.Numerator   = 1;
		Result.Numerator = MainProductData.Count;
		
	EndIf;
	
	If Reduce Then
		ProductionServer.ReduceFraction(Result);
	EndIf;
	
	Return Result;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
// 
//  Returns:
//  See Catalogs.Assignments.AssignmentSelectionFormTemplate
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	#Region SupplyWithMaterialsAndWorks
	
	//
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "SupplyWithMaterialsAndWorks.SupplyAssignment");
	DestinationPattern.TermsOfUse_     = "&BusinessOperation = VALUE(Enum.BusinessTransactions.OwnProduction)";
	DestinationPattern.LineOfBusiness  = "&LineOfBusiness";
	If Not Users.RolesAvailable("SelectArbitraryAssignmentsInProductionStage") Then
		DestinationPattern.Ref = "&RefsFilterInSelectionOfAssignmentsForm";
	EndIf;
	DestinationPattern.ExcludeRefAssignment = False;
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Own);
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "SupplyWithMaterialsAndWorks.SupplyAssignment");
	DestinationPattern.TermsOfUse_     = "&BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing)";
	DestinationPattern.LineOfBusiness  = "&LineOfBusiness";
	DestinationPattern.Partner                  = "&Partner";
	DestinationPattern.Contract                  = "&Contract";
	If Not Users.RolesAvailable("SelectArbitraryAssignmentsInProductionStage") Then
		DestinationPattern.Ref = "&RefsFilterInSelectionOfAssignmentsForm";
	EndIf;
	DestinationPattern.ExcludeRefAssignment = False;
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.ProvidedMaterials22);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.ProvidedMaterialsForStage22);
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate, "SupplyWithMaterialsAndWorks.SupplyAssignment");
	DestinationPattern.TermsOfUse_     = "&BusinessOperation = VALUE(Enum.BusinessTransactions.TollManufacturing2_5)";
	DestinationPattern.LineOfBusiness  = "&LineOfBusiness";
	DestinationPattern.Partner                  = "&Partner";
	DestinationPattern.Contract                  = "&Contract";
	If Not Users.RolesAvailable("SelectArbitraryAssignmentsInProductionStage") Then
		DestinationPattern.Ref = "&RefsFilterInSelectionOfAssignmentsForm";
	EndIf;
	DestinationPattern.ExcludeRefAssignment = False;
	DestinationPattern.AssignmentTypes.Clear();
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.Giveaway2_5);
	DestinationPattern.AssignmentTypes.Add(Enums.AssignmentTypes.ProvidedMaterialsForStage22);
	
	//
	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "OrderFulfillment", False, "SupplyWithMaterialsAndWorks.SupplyAssignment");
	
	DescriptionOfColumns.DataPaths.Products     = "SupplyWithMaterialsAndWorks.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "SupplyWithMaterialsAndWorks.Characteristic";
	DescriptionOfColumns.DataPaths.Warehouse            = "SupplyWithMaterialsAndWorks.Warehouse";
	
	#EndRegion
	
	Return FormTemplate;
	
EndFunction

#EndRegion

#EndRegion

#EndIf