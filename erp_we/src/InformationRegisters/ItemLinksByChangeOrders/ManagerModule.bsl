#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InfobaseUpdate

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.ItemLinksByChangeOrders.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.84";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("23dde64f-3131-4a6e-920b-a872353e5a0d");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.ItemLinksByChangeOrders.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("ru = 'Полный расчет связей материалов и аналогов в планировании.';
							|vi = 'Complete calculation of links between materials and substitutes in planning.';
							|en = 'Complete calculation of links between materials and substitutes in planning.'; fa = 'Complete calculation of links between materials and substitutes in planning.';
							|it = 'Complete calculation of links between materials and substitutes in planning.';
							|pl = 'Complete calculation of links between materials and substitutes in planning.';
							|tr = 'Planlamada malzeme ve ikame bağlantılarının tam hesaplaması.'");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Procedure = "InformationRegisters.AlternativeMaterials.ProcessDataForMigrationToNewVersion";
	Priority.Order = "After";
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.EngineeringChangeOrder.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.AlternativeMaterials.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.ItemLinksByChangeOrders.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.ItemLinksByChangeOrders.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Registration of data for processing.
//
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "InformationRegister.ItemLinksByChangeOrders";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	AdditionalParameters.Insert("FullRegisterName",             FullRegisterName);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Ref.ReplacementOption AS ReplacementOption,
	|	DocumentData.Ref.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
	|	SUM(DocumentData.QuantityOfMaterials) AS QuantityOfMaterials,
	|	SUM(DocumentData.NumberOfAnalogues) AS NumberOfAnalogues
	|INTO ReplacementPermissionData
	|FROM
	|	(SELECT
	|		PermissionToReplaceMaterialsMaterials.Ref AS Ref,
	|		SUM(1) AS QuantityOfMaterials,
	|		0 AS NumberOfAnalogues
	|	FROM
	|		Document.EngineeringChangeOrder.UsedMaterials AS PermissionToReplaceMaterialsMaterials
	|	
	|	GROUP BY
	|		PermissionToReplaceMaterialsMaterials.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		EngineeringChangeOrderSubstitutes.Ref,
	|		0,
	|		SUM(1)
	|	FROM
	|		Document.EngineeringChangeOrder.Substitutes AS EngineeringChangeOrderSubstitutes
	|	
	|	GROUP BY
	|		EngineeringChangeOrderSubstitutes.Ref) AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Ref.ReplacementOption,
	|	DocumentData.Ref.UseItForAutocorrectInOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPermissionData.Ref AS Ref,
	|	ReplacementPermissionData.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrdersInDocument,
	|	CASE
	|		WHEN ReplacementPermissionData.ReplacementOption = VALUE(Enum.SubstituteReplacementOption.SubstituteList)
	|			THEN TRUE
	|		WHEN ReplacementPermissionData.ReplacementOption = VALUE(Enum.SubstituteReplacementOption.SetToSet)
	|			THEN ReplacementPermissionData.QuantityOfMaterials = 1
	|					AND ReplacementPermissionData.NumberOfAnalogues = 1
	|		ELSE FALSE
	|	END AS UseItForAutocorrectInInstallationOrders
	|INTO TableApplicationInOrders
	|FROM
	|	ReplacementPermissionData AS ReplacementPermissionData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	VALUE(Catalog.Products.EmptyRef) AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic
	|FROM
	|	InformationRegister.AlternativeMaterials AS Table
	|WHERE
	|	&DynamicStructureOfProductionOrders
	|	AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					TableApplicationInOrders AS TableApplicationInOrders
	|				WHERE
	|					TableApplicationInOrders.Ref = Table.Recorder
	|					AND TableApplicationInOrders.UseItForAutocorrectInInstallationOrders)
	|	AND NOT TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					InformationRegister.ItemLinksByChangeOrders AS LinkTable
	|				WHERE
	|					LinkTable.Products = Table.Products
	|					AND LinkTable.Characteristic = Table.Characteristic)
	|";
	
	Query.SetParameter(
		"DynamicStructureOfProductionOrders",
		GetFunctionalOption("DynamicStructureOfProductionOrders"));	
	
	Data = Query.Execute().Unload();
	
	InfobaseUpdate.MarkForProcessing(Parameters, Data, AdditionalParameters);
	
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
	
	FullRegisterName = "InformationRegister.ItemLinksByChangeOrders";
	
	If Not InfobaseUpdate.DataProcessingCompleted(Undefined, "InformationRegister.AlternativeMaterials") Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName             = FullRegisterName;
	
	BeginTransaction();
	
	Try
		
		InformationRegisters.ItemLinksByChangeOrders.RunFullCalculation();
		
		InfobaseUpdate.MarkProcessingCompletion(UpdatedData, AdditionalParameters);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		ErrorTemplate = NStr("ru = 'Не удалось выполнить полный расчет связей материалов и аналогов в планировании:
								   |
								   |%1';
								   |vi = 'Cannot perform a complete calculation of links between materials and substitutes in planning:
								   |
								   |%1';
								   |en = 'Cannot perform a complete calculation of links between materials and substitutes in planning:
								   |
								   |%1'; fa = 'Cannot perform a complete calculation of links between materials and substitutes in planning:
								   |
								   |%1';
								   |it = 'Cannot perform a complete calculation of links between materials and substitutes in planning:
								   |
								   |%1';
								   |pl = 'Cannot perform a complete calculation of links between materials and substitutes in planning:
								   |
								   |%1';
								   |tr = 'Planlamada malzeme ve ikame bağlantılarının tam hesaplaması gerçekleştirilemedi: 
								   |
								   |%1'");
		
		ErrorText = StrTemplate(ErrorTemplate, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
		WriteLogEvent(
			InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Warning,
			Metadata.InformationRegisters.ItemLinksByChangeOrders,,
			ErrorText);
		
	EndTry;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(
										Parameters.Queue,
										FullRegisterName);
	
EndProcedure

#EndRegion

// Launches a full calculation of the relationships of materials and analogues in planning.
//
Procedure RunFullCalculation() Export
	
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Table.Recorder     AS Resolution,
	|	Table.ReplacementPriority AS ReplacementPriority,
	|	Table.Products    AS Products,
	|	Table.Characteristic  AS Characteristic
	|INTO TableOfNewEntries
	|FROM
	|	InformationRegister.AlternativeMaterials AS Table
	|WHERE
	|	Table.ProductsRole IN (
	|					VALUE(Enum.SubstituteRoles.Material),
	|					VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
	|	AND Table.UseItForAutocorrectInOrders
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Recorder     AS Resolution,
	|	Table.ReplacementPriority AS ReplacementPriority,
	|	Table.Products    AS Products,
	|	Table.Characteristic  AS Characteristic
	|FROM
	|	InformationRegister.AlternativeMaterials AS Table
	|WHERE
	|	Table.ProductsRole = VALUE(Enum.SubstituteRoles.Substitute)
	|	AND Table.UseItForAutocorrectInOrders
	|	AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.AlternativeMaterials AS TableOfMaterials
	|			WHERE
	|				TableOfMaterials.Recorder        = Table.Recorder
	|				AND TableOfMaterials.Products     = Table.Products
	|				AND TableOfMaterials.Characteristic   = Table.Characteristic
	|				AND TableOfMaterials.ProductsRole = VALUE(Enum.SubstituteRoles.Material))
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	VALUE(Document.EngineeringChangeOrder.EmptyRef) AS Resolution,
	|	VALUE(Enum.RulesOfReplacingWithSubstitutes.EmptyRef)   AS ReplacementPriority,
	|	TableOfOldRecords.Products                            AS Products,
	|	TableOfOldRecords.Characteristic                          AS Characteristic,
	|	TRUE                                                       AS OldRecord
	|FROM
	|	InformationRegister.ItemLinksByChangeOrders AS TableOfOldRecords
	|WHERE
	|	NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				TableOfNewEntries AS TableOfNewEntries
	|			WHERE
	|				TableOfNewEntries.Products    = TableOfOldRecords.Products
	|				AND TableOfNewEntries.Characteristic = TableOfOldRecords.Characteristic)
	|
	|UNION ALL
	|
	|SELECT
	|	TableOfNewEntries.Resolution       AS Resolution,
	|	TableOfNewEntries.ReplacementPriority  AS ReplacementPriority,
	|	TableOfNewEntries.Products   AS Products,
	|	TableOfNewEntries.Characteristic AS Characteristic,
	|	FALSE                               AS OldRecord
	|FROM
	|	TableOfNewEntries AS TableOfNewEntries
	|
	|ORDER BY
	|	Resolution
	|TOTALS BY
	|	Resolution
	|";
	
	Result = Query.Execute();
	
	Queue        = "JobsForCalculatingItemLinksByChangeOrders";
	TaskTable = DeferredJobs.InitializeTaskTable(Queue);
	RecordsTable = TaskTable[0].Jobs.CopyColumns();
	
	SelectionOfDocument = Result.Select(QueryResultIteration.ByGroups);
	While SelectionOfDocument.Next() Do
		
		RecordsTable.Clear();
		
		Timestamp1 = CurrentUniversalDateInMilliseconds();
		
		Selection = SelectionOfDocument.Select();
		While Selection.Next() Do
			
			TableRow = RecordsTable.Add();
			FillPropertyValues(TableRow, Selection);
			TableRow.Timestamp1 = Timestamp1;
			
		EndDo;
		
		DeferredJobs.AddTasksToQueue(Queue, RecordsTable,, TaskTable);
		
	EndDo;
	
	If TaskTable[0].Jobs.Count() > 0 Then
		DeferredJobs.Run(TaskTable);
	EndIf;
	
EndProcedure

// Launches a full calculation of the relationships of materials and analogues in planning in the background.
//
Procedure RunFullCalculationInBackground() Export
	
	Parameters = TimeConsumingOperations.ProcedureExecutionParameters();
	Parameters.BackgroundJobDescription = NStr("ru = 'Полный расчет связей материалов и аналогов в планировании';
												|vi = 'Complete calculation of links between materials and substitutes in planning';
												|en = 'Complete calculation of links between materials and substitutes in planning'; fa = 'Complete calculation of links between materials and substitutes in planning';
												|it = 'Complete calculation of links between materials and substitutes in planning';
												|pl = 'Complete calculation of links between materials and substitutes in planning';
												|tr = 'Planlamada malzeme ve ikame bağlantılarının tam hesaplaması'");
	Parameters.RunInBackground              = True;
	Parameters.WaitCompletion           = 0;
	
	TimeConsumingOperations.ExecuteProcedure(
		Parameters,
		"InformationRegisters.ItemLinksByChangeOrders.RunFullCalculation");
	
EndProcedure

#EndRegion

#Region Internal

// Calculates the connections of materials and analogues in planning.
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Assignments of accounts with nomenclature permissions for replacement", there are also service columns:
//             * Resolution             - DocumentRef.EngineeringChangeOrder -
//             * Products         - CatalogRef.Products -
//             * Characteristic       - CatalogRef.ItemsCharacteristics -
//             * Timestamp1       - Number -
//             * OldRecord         - Boolean -
//             * RecordID  - UUID -
//             * RecordDate           - Date   -
//             * JobID - UUID - Service_
//             * TaskDate_          - Date                    - Service_
//  IdsOfUnprocessedRecords - Map of UUID - The key is the identifier 
//                                                                                   of the failed (giving an error during
//                                                                                   execution) entries
//                                                                                   of the Job queue information register
//                                                                                   (measurement
//                                                                                   of the record identifier of the Job queue information register),
//                                                                                  the value is the Presentation of the error.
//  AdditionalProperties - Undefined, Structure - additional task completion properties.
//
Procedure CalculateRelationshipOfMaterialsAndAnaloguesInPlanning(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export
	
	QueryText =
	"SELECT
	|	Jobs.Resolution        AS Resolution,
	|	Jobs.Products      AS Products,
	|	Jobs.Characteristic    AS Characteristic,
	|	Jobs.Timestamp1    AS Timestamp1,
	|	Jobs.OldRecord      AS OldRecord
	|INTO Jobs
	|FROM
	|	&Jobs AS Jobs
	|
	|INDEX BY
	|
	|Resolution,
	|OldRecord
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Jobs.Resolution AS Resolution,
	|	CASE
	|		WHEN MIN(CASE
	|						WHEN Jobs.OldRecord
	|							THEN Jobs.Timestamp1
	|						ELSE 99999999999999
	|					END) > MIN(Jobs.Timestamp1)
	|			THEN -1
	|		ELSE MIN(CASE
	|						WHEN Jobs.OldRecord
	|							THEN Jobs.Timestamp1
	|						ELSE 99999999999999
	|					END)
	|	END AS TimestampOfOldRecords,
	|	CASE
	|		WHEN MAX(CASE
	|							WHEN Jobs.OldRecord
	|								THEN 0
	|							ELSE Jobs.Timestamp1
	|					END) < MAX(Jobs.Timestamp1)
	|			THEN -1
	|		ELSE MAX(CASE
	|							WHEN Jobs.OldRecord
	|								THEN 0
	|							ELSE Jobs.Timestamp1
	|					END)
	|	END AS TimestampOfNewEntries
	|INTO TimeStampTable
	|FROM
	|	Jobs AS Jobs
	|GROUP BY
	|	Jobs.Resolution
	|
	|INDEX BY
	|	Resolution
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Resolution AS Resolution,
	|	MIN(CASE
	|				WHEN Table.OldRecord
	|					THEN Table.Timestamp1
	|				ELSE 99999999999999
	|			END) AS TimestampOfOldRecords
	|INTO TableOfTimestampsOfOtherTasks
	|FROM
	|	InformationRegister.JobsForCalculatingItemLinksByChangeOrders AS Table
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			Jobs AS Jobs
	|		WHERE
	|			Jobs.Products     = Table.Products
	|			AND Jobs.Characteristic = Table.Characteristic)
	|	AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				Jobs AS Jobs
	|			WHERE
	|				Jobs.Resolution = Table.Resolution)
	|GROUP BY
	|	Table.Resolution
	|
	|HAVING
	|	MIN(CASE
	|				WHEN Table.OldRecord
	|					THEN Table.Timestamp1
	|				ELSE 99999999999999
	|			END) <= MIN(Table.Timestamp1)
	|
	|INDEX BY
	|	Resolution,
	|	TimestampOfOldRecords
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Jobs.Resolution       AS Resolution,
	|	Jobs.Products   AS Products,
	|	Jobs.Characteristic AS Characteristic,
	|	Jobs.Timestamp1 AS Timestamp1,
	|	Jobs.OldRecord   AS OldRecord
	|INTO RecordsTable
	|FROM
	|	TimeStampTable AS TimeStampTable
	|		INNER JOIN Jobs AS Jobs
	|		ON TimeStampTable.Resolution                    = Jobs.Resolution
	|		AND TimeStampTable.TimestampOfOldRecords = Jobs.Timestamp1
	|		AND Jobs.OldRecord
	|
	|UNION ALL
	|
	|SELECT
	|	Jobs.Resolution       AS Resolution,
	|	Jobs.Products   AS Products,
	|	Jobs.Characteristic AS Characteristic,
	|	Jobs.Timestamp1 AS Timestamp1,
	|	Jobs.OldRecord   AS OldRecord
	|FROM
	|	TimeStampTable AS TimeStampTable
	|		INNER JOIN Jobs AS Jobs
	|		ON TimeStampTable.Resolution                   = Jobs.Resolution
	|		AND TimeStampTable.TimestampOfNewEntries = Jobs.Timestamp1
	|		AND NOT Jobs.OldRecord
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GroupsTable.Products   AS Products,
	|	GroupsTable.Characteristic AS Characteristic,
	|	GroupsTable.Id  AS Id
	|INTO TableOfExistingGroups
	|FROM
	|	InformationRegister.ItemLinksByChangeOrders AS GroupsTable
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.ItemLinksByChangeOrders AS Table
	|		WHERE
	|			Table.Id = GroupsTable.Id
	|			AND TRUE IN
	|				(SELECT TOP 1
	|					TRUE
	|				FROM
	|					RecordsTable AS RecordsTable
	|				WHERE
	|					RecordsTable.Products     = Table.Products
	|					AND RecordsTable.Characteristic = Table.Characteristic))
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Resolution       AS Resolution,
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic
	|FROM
	|	RecordsTable AS Table
	|WHERE
	|	NOT Table.OldRecord
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Resolution       AS Resolution,
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic
	|FROM
	|	TableOfTimestampsOfOtherTasks AS TableOfTimestampsOfOtherTasks
	|		INNER JOIN InformationRegister.JobsForCalculatingItemLinksByChangeOrders AS Table
	|		ON TableOfTimestampsOfOtherTasks.Resolution                    = Table.Resolution
	|		AND TableOfTimestampsOfOtherTasks.TimestampOfOldRecords = Table.Timestamp1
	|		AND Table.OldRecord
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	Table.Recorder    AS Resolution,
	|	Table.Products   AS Products,
	|	Table.Characteristic AS Characteristic
	|FROM
	|	InformationRegister.AlternativeMaterials AS Table
	|WHERE
	|	Table.ReplacementPriority IN (
	|					VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials),
	|					VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute))
	|	AND Table.UseItForAutocorrectInOrders
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|			WHERE
	|				AlternativeMaterials.Recorder = Table.Recorder
	|				AND NOT TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							RecordsTable AS RecordsTable
	|						WHERE
	|							RecordsTable.Resolution = AlternativeMaterials.Recorder)
	|				AND NOT TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.JobsForCalculatingItemLinksByChangeOrders AS Jobs
	|						WHERE
	|							Jobs.Resolution = AlternativeMaterials.Recorder)
	|				AND (TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							RecordsTable AS RecordsTable
	|						WHERE
	|							RecordsTable.Products     = AlternativeMaterials.Products
	|							AND RecordsTable.Characteristic = AlternativeMaterials.Characteristic)
	|					OR TRUE IN
	|							(SELECT TOP 1
	|								TRUE
	|							FROM
	|								TableOfExistingGroups AS TableOfExistingGroups
	|							WHERE
	|								TableOfExistingGroups.Products     = AlternativeMaterials.Products
	|								AND TableOfExistingGroups.Characteristic = AlternativeMaterials.Characteristic)))
	|
	|ORDER BY
	|	Resolution
	|";
	
	SetPrivilegedMode(True);
	
	Try
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		
		Query.Text = QueryText;
		
		Query.SetParameter("Jobs", Jobs);
		
		Result = Query.Execute();
		
		TemporaryTable = Query.TempTablesManager.Tables;
		
		RecordsTable = Result.Unload();
		
		TableOfExistingGroups = TemporaryTable["TableOfExistingGroups"].GetData().Unload();
		TableOfExistingGroups.Indexes.Add("Products, Characteristic, Id");
		TableOfExistingGroups.Indexes.Add("Products, Characteristic");
		TableOfExistingGroups.Indexes.Add("Id");
		
		BufferTable = New ValueTable;
		BufferTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		BufferTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		BufferTable.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		BufferTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		
		GroupsTable = TableOfExistingGroups.CopyColumns();
		GroupsTable.Indexes.Add("Products, Characteristic");
		GroupsTable.Indexes.Add("Id");
		
		SelectionItemID = New Structure("Products, Characteristic, Id");
		FilterProducts              = New Structure("Products, Characteristic");
		FilterId             = New Structure("Id");
		
		CurrentDocument            = Undefined;
		CurrentGroupId = Undefined;
		
		IdsOfRelatedGroups = New Array;
		
		For Each RowOfRecordTable In RecordsTable Do
			
			If CurrentDocument <> RowOfRecordTable.Resolution Then
				
				If IdsOfRelatedGroups.Count() > 1 Then
					
					UBound = IdsOfRelatedGroups.UBound();
					
					GroupID = IdsOfRelatedGroups[UBound];
					
					IndexOf = 0;
					While IndexOf < UBound Do
						
						FilterId.Id = IdsOfRelatedGroups[IndexOf];
						
						FoundGroupRows = GroupsTable.FindRows(FilterId);
						For Each GroupsTableRow In FoundGroupRows Do
							GroupsTableRow.Id = GroupID;
						EndDo;
						
						IndexOf = IndexOf + 1;
						
					EndDo;
					
				EndIf;
				
				IdsOfRelatedGroups.Clear();
				
				CurrentDocument            = RowOfRecordTable.Resolution;
				CurrentGroupId = New UUID;
				
			EndIf;
			
			FillPropertyValues(FilterProducts, RowOfRecordTable);
			
			FoundRowsInGroupTable = GroupsTable.FindRows(FilterProducts);
			If FoundRowsInGroupTable.Count() = 0 Then
				
				GroupsTableRow = GroupsTable.Add();
				FillPropertyValues(GroupsTableRow, FilterProducts);
				GroupsTableRow.Id = CurrentGroupId;
				
			Else
				CurrentGroupId = FoundRowsInGroupTable[0].Id;
			EndIf;
			
			If IdsOfRelatedGroups.Find(CurrentGroupId) = Undefined Then
				IdsOfRelatedGroups.Add(CurrentGroupId);
			EndIf;
			
		EndDo;
		
		If IdsOfRelatedGroups.Count() > 1 Then
			
			UBound = IdsOfRelatedGroups.UBound();
			
			GroupID = IdsOfRelatedGroups[UBound];
			
			IndexOf = 0;
			While IndexOf < UBound Do
				
				FilterId.Id = IdsOfRelatedGroups[IndexOf];
				
				FoundGroupRows = GroupsTable.FindRows(FilterId);
				For Each GroupsTableRow In FoundGroupRows Do
					GroupsTableRow.Id = GroupID;
				EndDo;
				
				IndexOf = IndexOf + 1;
				
			EndDo;
			
		EndIf;
		
		If GroupsTable.Count() > 0 And TableOfExistingGroups.Count() > 0 Then
			
			GroupsIDs = CommonClientServer.CollapseArray(
									GroupsTable.UnloadColumn("Id"));
			
			IdsOfExistingGroups = TableOfExistingGroups.Copy(, "Id");
			IdsOfExistingGroups.GroupBy("Id");
			IdsOfExistingGroups.Columns.Add("RowsCount", Common.TypeDescriptionNumber(10));
			IdsOfExistingGroups.Indexes.Add("Id");
			
			For Each GroupID In GroupsIDs Do
				
				FilterId.Id = GroupID;
				
				FoundRowsInGroupTable = GroupsTable.FindRows(FilterId);
				NumberOfRowsOfNewGroup  = FoundRowsInGroupTable.Count();
				
				For Each IdOfExistingGroup In IdsOfExistingGroups Do
					
					SelectionItemID.Id = IdOfExistingGroup.Id;
					
					RowsCount = IdOfExistingGroup.RowsCount;
					
					If Not ValueIsFilled(RowsCount) Then
						
						FilterId.Id = IdOfExistingGroup.Id;
						
						IdOfExistingGroup.RowsCount =
							TableOfExistingGroups.FindRows(FilterId).Count();
							
						RowsCount = IdOfExistingGroup.RowsCount;
						
					EndIf;
					
					If RowsCount <> NumberOfRowsOfNewGroup Then
						Continue;
					EndIf;
					
					NumberOfMatches = 0;
					
					For Each GroupsTableRow In FoundRowsInGroupTable Do
						
						FillPropertyValues(SelectionItemID, GroupsTableRow,, "Id");
						
						If TableOfExistingGroups.FindRows(SelectionItemID).Count() = 0 Then
							Break;
						EndIf;
						
						NumberOfMatches = NumberOfMatches + 1;
						
					EndDo;
					
					If RowsCount <> NumberOfMatches Then
						Continue;
					EndIf;
					
					For Each GroupsTableRow In FoundRowsInGroupTable Do
						GroupsTable.Delete(GroupsTableRow);
					EndDo;
					
					FillPropertyValues(FilterId, SelectionItemID);
					
					FoundRowsInTableOfExistingGroups = TableOfExistingGroups.FindRows(FilterId);
					For Each TableRowOfExistingGroups In FoundRowsInTableOfExistingGroups Do
						TableOfExistingGroups.Delete(TableRowOfExistingGroups);
					EndDo;
					
					IdsOfExistingGroups.Delete(IdOfExistingGroup);
					
					Break;
					
				EndDo;
				
				If IdsOfExistingGroups.Count() = 0 Then
					Break;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		EmptyWarehouse = Catalogs.Warehouses.EmptyRef();
		EmptyAssignment = Catalogs.Assignments.EmptyRef();
		ProcessedGroupsArray = New Array;
		
		For Each TableRowOfExistingGroups In TableOfExistingGroups Do
			
			FillPropertyValues(FilterProducts, TableRowOfExistingGroups);
			
			FoundRowsInGroupTable = GroupsTable.FindRows(FilterProducts);
			If FoundRowsInGroupTable.Count() = 0 Then
				RowsInGroupTable = Undefined;
				Id      = Undefined;
			Else
				RowsInGroupTable = FoundRowsInGroupTable[0];
				Id      = RowsInGroupTable.Id;
			EndIf;
			
			RecordSet = InformationRegisters.ItemLinksByChangeOrders.CreateRecordSet();
			RecordSet.Filter.Products.Set(TableRowOfExistingGroups.Products);
			RecordSet.Filter.Characteristic.Set(TableRowOfExistingGroups.Characteristic);
			
			If ValueIsFilled(Id) Then
				
				SetRecord = RecordSet.Add();
				FillPropertyValues(SetRecord, TableRowOfExistingGroups,, "Id");
				SetRecord.Id = Id;
				
				GroupsTable.Delete(RowsInGroupTable);
				
				If ProcessedGroupsArray.Find(Id) = Undefined Then
					
					StringBuffer = BufferTable.Add();
					StringBuffer.Products = TableRowOfExistingGroups.Products;
					StringBuffer.Characteristic = TableRowOfExistingGroups.Characteristic;
					StringBuffer.Warehouse = EmptyWarehouse;
					StringBuffer.Purpose = EmptyAssignment;
					
					ProcessedGroupsArray.Add(Id);
				
				EndIf;
				
			Else
				
				StringBuffer = BufferTable.Add();
				StringBuffer.Products = TableRowOfExistingGroups.Products;
				StringBuffer.Characteristic = TableRowOfExistingGroups.Characteristic;
				StringBuffer.Warehouse = EmptyWarehouse;
				StringBuffer.Purpose = EmptyAssignment;
				
			EndIf;
			
			RecordSet.Write();
			
		EndDo;
		
		For Each RowsInGroupTable In GroupsTable Do
			
			RecordSet = InformationRegisters.ItemLinksByChangeOrders.CreateRecordSet();
			RecordSet.Filter.Products.Set(RowsInGroupTable.Products);
			RecordSet.Filter.Characteristic.Set(RowsInGroupTable.Characteristic);
			
			SetRecord = RecordSet.Add();
			FillPropertyValues(SetRecord, RowsInGroupTable);
			
			RecordSet.Write();
			
			If ProcessedGroupsArray.Find(Id) = Undefined Then
				
				StringBuffer = BufferTable.Add();
				StringBuffer.Products = RowsInGroupTable.Products;
				StringBuffer.Characteristic = RowsInGroupTable.Characteristic;
				StringBuffer.Warehouse = EmptyWarehouse;
				StringBuffer.Purpose = EmptyAssignment;
				ProcessedGroupsArray.Add(Id);
			
			EndIf;
			
		EndDo;
		
		If BufferTable.Count() > 0 Then
		
			InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(BufferTable);
		
		EndIf;
		
	Except
		
		ExceptionText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		
		WriteLogEvent(
			DeferredJobs.EventName(),
			EventLogLevel.Error,
			Metadata.InformationRegisters.ItemLinksByChangeOrders,,
			ExceptionText);
		
		ErrorFields = New Structure;
		ErrorFields.Insert("Resolution");
		ErrorFields.Insert("Products");
		ErrorFields.Insert("Characteristic");
		ErrorFields.Insert("Timestamp1");
		ErrorFields.Insert("OldRecord");
		
		For Each TableRow In Jobs Do
			
			IdsOfUnprocessedRecords.Insert(
				TableRow.RecordID,
				DeferredJobs.ExecutionErrorText(ErrorFields, TableRow, ExceptionText));
			
		EndDo;
		
	EndTry;
	
EndProcedure

#EndRegion

#EndIf