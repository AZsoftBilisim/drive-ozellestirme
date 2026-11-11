#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// The record contains the Attributes of the division of stages.
// 
// Parameters:
//  Record - InformationRegisterRecord.TechnologicalProcessesOfProductionStages
// 
// Returns:
//  Boolean
Function RecordContainsProcessLimitations(Record) Export
	
	Return ValueIsFilled(Record.FirstOperationID)
		Or ValueIsFilled(Record.LastOperationID)
		Or ValueIsFilled(Record.CanceledLastOperation);
	
EndFunction

// The record contains the process parameters.
// 
// Parameters:
//  Record - InformationRegisterRecord.TechnologicalProcessesOfProductionStages
// 
// Returns:
//  Boolean
Function RecordContainsParametersOfTechnologicalProcess(Record) Export
	
	Return ValueIsFilled(Record.TechnologicalProcessType)
		Or ValueIsFilled(Record.TechnologicalProcess)
		Or ValueIsFilled(Record.TechnologicalProcessFactor);
	
EndFunction

// Records the parameters of the technical process of the stage
// 
// Parameters:
//  Stage - DocumentRef.ProductionStage2_2
//  TechProcessParameters - See ProductionProcessEditorClientServer.ProcessParametersConstructor
//  SaveTechnologicalProcessLimitations - Boolean - Determines the need to maintain the restrictions established by the division of the party
Procedure RecordProcessParameters(Stage, TechProcessParameters, SaveTechnologicalProcessLimitations = True) Export
	
	PresenceOfRecordIsMandatory = Not TechProcessParameters.TechnologicalProcessType = Enums.TechnologicalProcessTypesOfStage.Standard
		Or TypeOf(TechProcessParameters.TechnologicalProcess) = Type("CatalogRef.RouteSheets")
				And ValueIsFilled(TechProcessParameters.TechnologicalProcess);
	
	Set = CreateRecordSet();
	Set.Filter.Stage.Set(Stage);
	
	If SaveTechnologicalProcessLimitations Then
		Set.Read();
	EndIf;
	
	If PresenceOfRecordIsMandatory
		And Set.Count() = 0 Then
		Set.Add();
	ElsIf Not PresenceOfRecordIsMandatory
		And Set.Count() > 0
		And Not RecordContainsProcessLimitations(Set[0]) Then
		Set.Clear();
	EndIf;
	
	If Set.Count() > 0 Then
		Set[0].Stage = Stage;
		FillPropertyValues(Set[0], TechProcessParameters);
	EndIf;
	
	Set.Write();
	
EndProcedure

// Constructor of the process constraint structure.
// 
// Returns:
//  Structure - From:
// * FirstOperationID - Number - restriction on the left
// * LastOperationID - Number - restriction on the right
// * CanceledLastOperation - Number - shortening the last Operation
Function LimitationsOfConstructorProcess() Export
	
	Result = New Structure;
	
	Result.Insert("FirstOperationID", 0);
	Result.Insert("LastOperationID", 0);
	Result.Insert("CanceledLastOperation", 0);
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.TechnologicalProcessesOfProductionStages.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.23.7";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("833b3f93-3d12-5ef3-805a-fa4f9f10a11a");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.TechnologicalProcessesOfProductionStages.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền mục tin chia lô hàng và quy trình công nghệ của các công đoạn với sơ đồ lộ trình.';
							|ru = 'Заполняет реквизиты деления партии и технологические процессы этапов с маршрутными картами.';
							|en = 'Fills the attributes of lot division and the technological processes of the stages with route sheets.'; fa = 'Fills the attributes of lot division and the technological processes of the stages with route sheets.';
							|it = 'Fills the attributes of lot division and the technological processes of the stages with route sheets.';
							|pl = 'Fills the attributes of lot division and the technological processes of the stages with route sheets.';
							|tr = 'Lot bölünmesinin özniteliklerini ve aşamaların teknolojik süreçlerini rotalarıyla doldurur.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.InformationRegisters.AttributesOfProductionStageDivision.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.TechnologicalProcessesOfProductionStages.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.TechnologicalProcessesOfProductionStages.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.QueueOfProductionOperations.FullName());
	ToLock.Add(Metadata.InformationRegisters.TechnologicalProcessesOfProductionStages.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();

	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "InformationRegisters.QueueOfProductionOperations.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "Before";
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.TechnologicalProcessesOfProductionStages";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Stage.Date DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Stage");
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	
	QueryText = "
	|SELECT DISTINCT
	|	NestedQuery.Stage AS Stage
	|FROM
	|(
	|	SELECT
	|		DivisionAttributes.Stage AS Stage
	|	FROM
	|		InformationRegister.AttributesOfProductionStageDivision AS DivisionAttributes
	|	WHERE
	|		DivisionAttributes.Stage.Posted
	|		AND NOT TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcesses
	|			WHERE
	|				DivisionAttributes.Stage = TechnicalProcesses.Stage
	|			)
	|
	|	UNION ALL
	|
	|	SELECT
	|		Table.Ref AS Stage
	|	FROM
	|		Document.ProductionStage2_2 AS Table
	|	WHERE
	|		Table.Posted
	|		AND Table.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated)
	|		AND NOT Table.DeleteRouteSheet = VALUE(Catalog.RouteSheets.EmptyRef)
	|		AND (NOT Table.DeleteRouteSheet = Table.Stage.RouteSheet
	|			OR NOT Table.DeleteRouteSheetFactor = Table.Stage.RouteSheetFactor
	|						* Table.NumberOfPackagesPlan
	|						* ISNULL(&PackagingFactor, 1) / 
	|						CASE
	|							WHEN Table.QuantityPerReleaseLotUnit > 0
	|								THEN Table.QuantityPerReleaseLotUnit
	|							ELSE 1
	|						END)
	|		AND NOT TRUE IN (
	|			SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcesses
	|			WHERE
	|				Table.Ref = TechnicalProcesses.Stage
	|			)
	|
	|) AS NestedQuery
	|";
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Table.PackagePlan",
		"Table.ProductionLot.MainProductProducts");
		
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactor",
		QueryTextPackagingFactor);
		
	Query = New Query;
	Query.Text = QueryText;
	
	InfobaseUpdate.MarkForProcessing(
		Parameters,
		Query.Execute().Unload(),
		AdditionalParameters);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - parameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.TechnologicalProcessesOfProductionStages";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	Stages = New Array;
	For Each Selection In UpdatedData Do
		Stages.Add(Selection.Stage);
	EndDo;
	
	QueryText = "
	|SELECT
	|	DocumentAttributes.Ref                                 AS Stage,
	|	DocumentAttributes.DeleteRouteSheet                 AS RouteSheetOfDocument,
	|	DocumentAttributes.DeleteRouteSheetFactor      AS CoefficientOfDocumentSRouteMap,
	|	DivisionAttributes.DeleteFirstOperationID       AS FirstOperationID,
	|	DivisionAttributes.DeleteLastOperationID    AS LastOperationID,
	|	DivisionAttributes.DeleteCanceledLastOperation         AS CanceledLastOperation,
	|	DocumentAttributes.Stage.RouteSheet                   AS RouteSheetOfStageBillOfMaterials,
	|	DocumentAttributes.Stage.RouteSheetFactor
	|		* DocumentAttributes.NumberOfPackagesPlan
	|		* ISNULL(&PackagingFactor, 1) / 
	|			CASE
	|				WHEN DocumentAttributes.QuantityPerReleaseLotUnit > 0
	|					THEN DocumentAttributes.QuantityPerReleaseLotUnit
	|				ELSE 1
	|			END                                             AS CoefficientOfRouteMapOfStageBillOfMaterials,
	|	&TechProcessParameters
	|FROM
	|	Document.ProductionStage2_2 AS DocumentAttributes
	|
	|		LEFT JOIN InformationRegister.AttributesOfProductionStageDivision AS DivisionAttributes
	|		ON DocumentAttributes.Ref = DivisionAttributes.Stage
	|
	|		LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|		ON FALSE
	|
	|WHERE
	|	DocumentAttributes.Ref IN (&Stages)
	|";
	
	QueryText = StrReplace(QueryText,
		"&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage());
		
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"DocumentAttributes.PackagePlan",
		"DocumentAttributes.ProductionLot.MainProductProducts");
		
	QueryText = StrReplace(
		QueryText,
		"&PackagingFactor",
		QueryTextPackagingFactor);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Stages", Stages);
	
	AttributesValues = Query.Execute().Unload();
	AttributesValues.Indexes.Add("Stage");
	
	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			LockItem = Block.Add(FullRegisterName);
			LockItem.SetValue("Stage", Selection.Stage);
			LockItem.Mode = DataLockMode.Exclusive;
			Block.Lock();
			
			RecordSet = InformationRegisters.TechnologicalProcessesOfProductionStages.CreateRecordSet();
			RecordSet.Filter.Stage.Set(Selection.Stage);
			
			SetIsChanged = False;
			
			AttributesValueString = AttributesValues.Find(Selection.Stage, "Stage");
			
			If RecordContainsProcessLimitations(AttributesValueString) Then
			
				RegisterRecord = RecordSet.Add();
				FillPropertyValues(RegisterRecord, AttributesValueString);
				
				SetIsChanged = True;
			
			EndIf;
			
			If ValueIsFilled(AttributesValueString.RouteSheetOfDocument) Then
				
				RegisterRecord = ?(RecordSet.Count() > 0, RecordSet[0], RecordSet.Add());
				RegisterRecord.Stage = Selection.Stage;
				RegisterRecord.TechnologicalProcess = AttributesValueString.RouteSheetOfDocument;
				RegisterRecord.TechnologicalProcessFactor = AttributesValueString.CoefficientOfDocumentSRouteMap;
				RegisterRecord.TechnologicalProcessType = ?(
					AttributesValueString.RouteSheetOfDocument = AttributesValueString.RouteSheetOfStageBillOfMaterials
						And AttributesValueString.CoefficientOfDocumentSRouteMap = AttributesValueString.CoefficientOfRouteMapOfStageBillOfMaterials,
					Enums.TechnologicalProcessTypesOfStage.Standard,
					Enums.TechnologicalProcessTypesOfStage.AlternateType);
				
				SetIsChanged = True;
				
			EndIf;
			
			If SetIsChanged Then
				InfobaseUpdate.WriteRecordSet(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = 
				StrTemplate(
					NStr("vi = 'Không thể ghi lại dữ liệu vào biểu ghi ""Quy trình công nghệ của công đoạn sản xuất"" theo công đoạn ""%1"", do: %2';
						|ru = 'Не удалось записать данные в регистр ""Технологические процессы этапов производства"" по этапу ""%1"", по причине: %2';
						|en = 'Cannot save data to the ""Technological processes of production stages"" register for the ""%1"" stage due to: %2'; fa = 'Cannot save data to the ""Technological processes of production stages"" register for the ""%1"" stage due to: %2';
						|it = 'Cannot save data to the ""Technological processes of production stages"" register for the ""%1"" stage due to: %2';
						|pl = 'Cannot save data to the ""Technological processes of production stages"" register for the ""%1"" stage due to: %2';
						|tr = '""%1"" aşamasına göre ""Üretim aşamalarının teknolojik süreçleri"" kaydına şu nedenden dolayı veriler kaydedilemedi: %2 '"),
					Selection.Stage,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(), 
				EventLogLevel.Warning,
				Metadata.InformationRegisters.QueueOfProductionOperations, 
				, 
				MessageText);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(
		Parameters.Queue,
		FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf