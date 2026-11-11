#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region CreationOfStandardTechnologicalProcesses

Procedure ListOfSelectedRouteMapsInBackground(Parameters, StorageAddress) Export
	
	Result = RouteMapSelectionResult(
						Parameters.RouteMapSelectionOption,
						Parameters.CompositionSettings);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function RouteMapSelectionResult(RouteMapSelectionOption, CompositionSettings)
	
	Result = New Structure;
	Result.Insert("RouteSheets",           New Array);
	Result.Insert("RouteMapsQuantity", 0);
	
	Query = New Query;
	
	If RouteMapSelectionOption = RouteMapSelectionOptionAll() Then
		
		Query.Text = RequestTextRouteMapsAll();
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		Result.RouteMapsQuantity = Selection.Count;
		
	ElsIf RouteMapSelectionOption = OptionForSelectingRouteMapsReusable() Then
			
		Query.Text = RequestTextReusableRouteMaps();
		
		List = Query.Execute().Unload();
		
		Result.RouteSheets = List.UnloadColumn("RouteSheet");
		Result.RouteMapsQuantity = List.Count();
		
	ElsIf RouteMapSelectionOption = OptionForSelectingRouteMapsBySelection() Then
		
		Schema      = DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.GetTemplate("CustomFiltersLayoutTemplate");
		SchemaURL = PutToTempStorage(Schema);
		
		SettingsComposer = New DataCompositionSettingsComposer();
		SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
		If ValueIsFilled(CompositionSettings) Then
			SettingsComposer.LoadSettings(CompositionSettings);
		Else
			SettingsComposer.LoadSettings(Schema.DefaultSettings);
		EndIf;
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
		
		DataCompositionTemplateComposer = New DataCompositionTemplateComposer;
		DataCompositionTemplate = DataCompositionTemplateComposer.Execute(
			Schema,SettingsComposer.GetSettings(),,,,False);
		
		QueryText = DataCompositionTemplate.DataSets["DataSet1"].Query;
		QueryText = StrReplace(QueryText, "&RouteMapSelection", TextOfMainRouteMapSelection());
			
		Query.Text = QueryText;
		For Each LayoutParameter In DataCompositionTemplate.ParameterValues Do
			Query.SetParameter(LayoutParameter.Name, LayoutParameter.Value);
		EndDo;
		
		SetPrivilegedMode(True);
		List = Query.Execute().Unload();
		SetPrivilegedMode(False);
		
		Result.RouteSheets = List.UnloadColumn("RouteSheet");
		Result.RouteMapsQuantity = List.Count();
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CreateTypicalTechnologicalProcessesInBackground(Parameters, StorageAddress) Export
	
	Result = CreateTypicalTechnologicalProcesses(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function CreateTypicalTechnologicalProcesses(Parameters)
	
	QueryResults = SelectRouteMapDataForCreatingTechnicalProcesses(
		Parameters.RouteMapSelectionOption,
		Parameters.RouteSheets);
	NumberOfResults = QueryResults.Count();
	
	Result = New Structure;
	Result.Insert("HasErrors", False);
	Result.Insert("QuantityCreated", 0);
	
	StructureOfData      = New Structure("MaterialsAndServices,LaborCosts,SelectionByProperties,PropertyMapping");
	MatchingOperations = New Map();
	TheStructureOfTheSearch      = New Structure("RouteSheet");
	EmployeeResponsible        = Users.CurrentUser();
	
	Selection             = QueryResults[NumberOfResults-4].Select();
	TransactionTable     = QueryResults[NumberOfResults-3].Unload(); // ValueTable
	TableMaterials    = QueryResults[NumberOfResults-2].Unload(); // ValueTable
	TableLaborCosts = QueryResults[NumberOfResults-1].Unload(); // ValueTable
	
	TransactionTable.Indexes.Add("RouteSheet");
	TableMaterials.Indexes.Add("RouteSheet");
	TableLaborCosts.Indexes.Add("RouteSheet");
	
	StructureOfData.MaterialsAndServices = TableMaterials;
	StructureOfData.LaborCosts     = TableLaborCosts;
	
	BeginTransaction();
	
	Try
	
		While Selection.Next() Do
			
			TechnicalProcessObject = Catalogs.TechnologicalProcesses.CreateItem();
			
			FillPropertyValues(TechnicalProcessObject, Selection);
			TechnicalProcessObject.EmployeeResponsible = EmployeeResponsible;
			TechnicalProcessObject.Status = Enums.TechnologicalProcessStatuses.UnderDevelopment;
			TechnicalProcessObject.DataExchange.Load = True;
			TechnicalProcessObject.Write();
			
			If Not Selection.ContainsNestedRoute Then
				
				MatchingOperations.Clear();
				TheStructureOfTheSearch.RouteSheet = Selection.RouteSheet;
			
				MigrateOperationsTable(
					TransactionTable.FindRows(TheStructureOfTheSearch),
					TechnicalProcessObject.Ref,
					Undefined,
					MatchingOperations);
				
				StructureOfData.SelectionByProperties    = Selection.SelectionByProperties.Unload();
				StructureOfData.PropertyMapping = Selection.PropertyMapping.Unload();
				
				AddRouteMapItems(
					TechnicalProcessObject,
					StructureOfData,
					MatchingOperations,
					TheStructureOfTheSearch);
				
			Else
				
				AddRouteMapWithNestedRoutes(
					TechnicalProcessObject,
					Selection.RouteSheet);
				
			EndIf;
			
			If Selection.Status = Enums.StatusesOfRouteSheets.Valid Then
				TechnicalProcessObject.Status = Enums.TechnologicalProcessStatuses.Valid;
				If Not TechnicalProcessObject.CheckFilling() Then
					TechnicalProcessObject.Status = Enums.TechnologicalProcessStatuses.UnderDevelopment;
				EndIf;
			EndIf;
			TechnicalProcessObject.Basis = Selection.RouteSheet;
			TechnicalProcessObject.DataExchange.Load = False;
			TechnicalProcessObject.Write();
			
			Result.QuantityCreated = Result.QuantityCreated + 1;
			
		EndDo;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		Result.HasErrors = True;
		
		WriteLogEvent(
			EventCreationOfStandardTechnologicalProcesses(),
			EventLogLevel.Error,,
			Selection.RouteSheet,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Result;
	
EndFunction

Procedure AddRouteMapItems(TechnicalProcessObject, StructureOfData, MatchingOperations, TheStructureOfTheSearch)
	
	MatchingKeys = New Map();
	
	For Each TSName In StrSplit("MaterialsAndServices,LaborCosts",",") Do
		TabularSection = TechnicalProcessObject[TSName]; // TabularSection
		Table = StructureOfData[TSName].Copy(TheStructureOfTheSearch); // ValueTable
		Table.Sort("LineNumber");
		For RowIndex = 0 To Table.Count()-1 Do
			NewRow = TabularSection.Add();
			FillPropertyValues(NewRow, Table[RowIndex]);
			NewRow.ConnectionKey = New UUID;
			NewRow.OperationEdit = MatchingOperations.Get(Table[RowIndex].Operation);
			CheckClearQuantityCalculationAlgorithm(NewRow);
			MatchingKeys.Insert(Table[RowIndex].ConnectionKey, NewRow.ConnectionKey);
		EndDo;
	EndDo;
	
	For Each TSName In StrSplit("SelectionByProperties,PropertyMapping",",") Do
		TabularSection = TechnicalProcessObject[TSName]; // TabularSection
		Table = StructureOfData[TSName].Copy(TheStructureOfTheSearch); // ValueTable
		For RowIndex = 0 To Table.Count()-1 Do
			NewKey = MatchingKeys.Get(Table[RowIndex].ConnectionKey);
			If NewKey <> Undefined Then
				NewRow = TabularSection.Add();
				FillPropertyValues(NewRow, Table[RowIndex]);
				NewRow.ConnectionKey = NewKey;
			EndIf;
		EndDo;
	EndDo;
	
EndProcedure

Procedure AddRouteMapWithNestedRoutes(TechnicalProcessObject, RouteSheet)
	
	RouteMapData = RouteMapDataWithNestedRoutes(RouteSheet);
	
	OperationsMatchingTable = MigrateTableOfOperationsWithNestedRoutes(
		RouteMapData.Operations,
		TechnicalProcessObject.Ref,
		Undefined);
	
	TheStructureOfTheSearch = New Structure("Id");
	For IndexOf = 0 To OperationsMatchingTable.Count() - 1 Do
		
		FillPropertyValues(TheStructureOfTheSearch, OperationsMatchingTable[IndexOf]);
		
		AddRouteMapItems(
			TechnicalProcessObject,
			RouteMapData,
			OperationsMatchingTable[IndexOf].MatchingOperations,
			TheStructureOfTheSearch);
		
	EndDo;
	
EndProcedure

Function SelectRouteMapDataForCreatingTechnicalProcesses(RouteMapSelectionOption, RouteSheets)
	
	QueryOptions = RequestParametersRouteMapData();
	QueryOptions.FilterUsedMaterials = "UsedMaterials.Auxiliary";
	
	Query = New Query;
	
	If RouteMapSelectionOption = RouteMapSelectionOptionAll() Then
		
		QueryText = "
		|SELECT
		|	0                                                 AS Id,
		|	VALUE(Catalog.RouteSheets.EmptyRef) AS RouteSheet
		|
		|INTO TTRouteMaps
		|
		|;
		|";
		
		QueryOptions.JoinText = "TRUE";
		QueryOptions.FilterRouteSheets = TextOfMainRouteMapSelection();
		
	Else
	
		QueryText = "
		|SELECT
		|	0                      AS Id,
		|	RouteSheets.Ref AS RouteSheet
		|
		|INTO TTRouteMaps
		|FROM
		|	Catalog.RouteSheets AS RouteSheets
		|
		|WHERE
		|	RouteSheets.Ref IN (&List)
		|	AND &TextSelectionOfRouteMaps
		|;
		|";
		
		QueryText = StrReplace(QueryText, "&TextSelectionOfRouteMaps", TextOfMainRouteMapSelection());
		
		Query.SetParameter("List", RouteSheets);
		
	EndIf;
	
	Query.Text = QueryText + QueryTextRouteMapData_(QueryOptions);
	
	Return Query.ExecuteBatch();
	
EndFunction

#EndRegion

#Region MergingCatalogs

Procedure DeterminePresenceOfConflictsInBackground(Parameters, StorageAddress) Export
	
	PutToTempStorage(IdentifyConflicts(Parameters), StorageAddress);
	
EndProcedure

Function IdentifyConflicts(Parameters)
	
	GenerateReport = Parameters.GenerateReport;
	ConflictData = Undefined;
	
	Result = New Structure;
	Result.Insert("ThereAreConflicts", False);
	Result.Insert("GenerateReport", GenerateReport);
	
	QueryText = DataMatchingRequestText();
	
	TextSelectionOnlyConflicts = "
	|NOT RouteMapLines.LineNumber IS NULL
	|	AND SpecificationLines.LineNumber IS NULL";
	
	QueryText = StrReplace(QueryText, "&Filter1", TextSelectionOnlyConflicts);
	QueryText = StrReplace(QueryText, "&Filter2", TextSelectionOnlyConflicts);
	If GenerateReport Then
		QueryText = StrReplace(QueryText, "TOP 1", "");
	EndIf;
	
	QueryText = QueryText + "
	|;
	|
	|SELECT
	|	TTStages.BillOfMaterials           AS BillOfMaterials,
	|	TTStages.Stage                   AS Stage,
	|	TTStages.RouteSheet        AS RouteSheet,
	|	TTStages.TechnologicalProcess AS TechnologicalProcess
	|FROM
	|	TTStages AS TTStages
	|WHERE
	|	TTStages.ContainsNestedRoute
	|
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("MaterialsAndServices", "%MaterialsAndServices%");

	QueryResults = Query.ExecuteBatch();
	NumberOfResults = QueryResults.Count();
	
	ResultWithoutAttachments = QueryResults[NumberOfResults-2];
	ResultWithNested  = QueryResults[NumberOfResults-1];
	
	Result.ThereAreConflicts = Not ResultWithoutAttachments.IsEmpty();
	If GenerateReport Then
		ConflictData = ResultWithoutAttachments.Unload();
	EndIf;
	
	// Route maps with nested routes
	If Not ResultWithNested.IsEmpty()
		And (Not Result.ThereAreConflicts Or GenerateReport) Then
		
		Selection = ResultWithNested.Select();
		While Selection.Next() Do
			
			QueryResultNestedRoutes = DetectConflictsBasedOnNestedRoutes(
					Selection.BillOfMaterials,
					Selection.Stage,
					Selection.RouteSheet,
					Selection.TechnologicalProcess,
					GenerateReport);
					
			Result.ThereAreConflicts = Result.ThereAreConflicts Or Not QueryResultNestedRoutes.IsEmpty();
			If GenerateReport Then
				ConflictDataNestedRoutes = QueryResultNestedRoutes.Unload();
				For Each String In ConflictDataNestedRoutes Do
					FillPropertyValues(ConflictData.Add(), String);
				EndDo;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If GenerateReport Then
		
		Result.Insert("ConflictData", ConflictData);
		
	EndIf;
	
	Return Result;
	
EndFunction

Function DetectConflictsBasedOnNestedRoutes(BillOfMaterials, Stage, RouteSheet, TechnologicalProcess, GenerateReport)
	
	TextSelectionOnlyConflicts = "SpecificationLines.LineNumber IS NULL";
	
	QueryOptions = New Structure;
	QueryOptions.Insert("Filter1", TextSelectionOnlyConflicts);
	QueryOptions.Insert("Filter2", TextSelectionOnlyConflicts);
	If GenerateReport Then
		QueryOptions.Insert("All");
	EndIf;
	
	DataToMerge = DataForCombiningCatalogsWithNestedRoutes(
		BillOfMaterials,
		Stage,
		RouteSheet,
		TechnologicalProcess,
		QueryOptions);
	
	Return DataToMerge.ResultMatching;
	
EndFunction

Procedure CombiningCatalogsInBackground(Parameters, StorageAddress) Export
	
	Result = MergeCatalogs(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function MergeCatalogs(Parameters)
	
	Result = New Structure;
	Result.Insert("HasErrors",             False);
	Result.Insert("ProcessedSpecifications", 0);
	Result.Insert("RescheduledOperations",     0);
	Result.Insert("ConnectedTechnicalProcesses", 0);
	Result.Insert("StagesWereProcessed",       0);
	
	SpecificationsObjects   = New Map();
	MatchingOperations  = New Map();
	SearchStructureStage   = New Structure("Stage");
	
	DataToMerge   = DataForCombiningCatalogs();
	ResultMatching = DataToMerge.ResultMatching; // QueryResult
	SamplingMatching   = ResultMatching.Select(QueryResultIteration.ByGroups, "BillOfMaterials");
	TransactionTable        = DataToMerge.TransactionTable; // ValueTable
	
	BeginTransaction();
	
	Try
		
		// Having resources to match
		While SamplingMatching.Next() Do
			
			ObjectSpecification = SpecificationsObjects.Get(SamplingMatching.BillOfMaterials);
			
			SamplingStages = SamplingMatching.Select(QueryResultIteration.ByGroups, "Stage");
			While SamplingStages.Next() Do
				
				SearchStructureStage.Stage = SamplingStages.Stage;
				Operations = TransactionTable.FindRows(SearchStructureStage);
				
				If SamplingStages.ContainsNestedRoute Then
					
					MergeCatalogsWithNestedRoutes(SamplingStages, ObjectSpecification, Result);
					
				ElsIf ValueIsFilled(SamplingStages.TechnologicalProcess) And Not SamplingStages.ThereAreConflicts Then
					
					ConnectTechnologicalProcess(SamplingStages);
					
					SamplingResources = SamplingStages.Select();
					While SamplingResources.Next() Do
						
						DeleteSpecificationLine(SamplingResources, ObjectSpecification);
						
					EndDo;
					
					Result.ConnectedTechnicalProcesses = Result.ConnectedTechnicalProcesses + 1;
					
				Else
					
					MatchingOperations.Clear();
					
					Operations = TransactionTable.FindRows(SearchStructureStage);
					If Operations.Count() > 0 Then
						
						GetSpecificationObjectToProcess(SamplingStages.BillOfMaterials, ObjectSpecification);
						
						MigrateOperationsTable(
							Operations,
							SamplingStages.Stage,
							SamplingStages.BillOfMaterials,
							MatchingOperations,
							SamplingStages.RouteSheetFactor);
						
						SamplingResources = SamplingStages.Select();
						While SamplingResources.Next() Do
							BindSpecificationStringToOperation(SamplingResources, ObjectSpecification, MatchingOperations);
						EndDo;
						
						Result.RescheduledOperations = Result.RescheduledOperations + Operations.Count();
						
					EndIf;
					
				EndIf;
				
				For Each LineOperation In Operations Do
					TransactionTable.Delete(LineOperation);
				EndDo;
				
			EndDo;
			
			SpecificationsObjects.Insert(SamplingMatching.BillOfMaterials, ObjectSpecification);
			
		EndDo;
		
		StageDetails = "BillOfMaterials,Stage,RouteSheet,RouteSheetFactor,ContainsNestedRoute,TechnologicalProcess,TechnologicalProcessPresentation";
		
		// Having no resources to match
		LeftToProcess = TransactionTable.Copy();
		LeftToProcess.GroupBy(StageDetails);
		For Each String_Process In LeftToProcess Do
			
			ObjectSpecification = SpecificationsObjects.Get(String_Process.BillOfMaterials);
			
			SearchStructureStage.Stage = String_Process.Stage;
			
			If String_Process.ContainsNestedRoute Then
				
				MergeCatalogsWithNestedRoutes(String_Process, ObjectSpecification, Result);
				
			ElsIf ValueIsFilled(String_Process.TechnologicalProcess) Then
				
				ConnectTechnologicalProcess(String_Process);
				
				Result.ConnectedTechnicalProcesses = Result.ConnectedTechnicalProcesses + 1;
				
			Else
				
				Operations = TransactionTable.FindRows(SearchStructureStage);
				If Operations.Count() > 0 Then
					GetSpecificationObjectToProcess(String_Process.BillOfMaterials, ObjectSpecification);
					MigrateOperationsTable(
						Operations,
						String_Process.Stage,
						String_Process.BillOfMaterials,
						Undefined,
						String_Process.RouteSheetFactor);
					Result.RescheduledOperations = Result.RescheduledOperations + Operations.Count();
				EndIf;
				
			EndIf;
			
			SpecificationsObjects.Insert(String_Process.BillOfMaterials, ObjectSpecification);
			
		EndDo;
		
		For Each KeyAndValue In SpecificationsObjects Do
			ObjectSpecification = KeyAndValue.Value; // CatalogObject.BillsOfMaterials
			If ObjectSpecification <> Undefined Then
				ObjectSpecification.Write();
				Result.ProcessedSpecifications = Result.ProcessedSpecifications + 1;
			EndIf;
		EndDo;
		
		If Not Result.HasErrors Then
			FixTechnicalProcessOfStartedStages(Result);
			Constants.StoreOperationsInBillsOfMaterials.Set(True);
		EndIf;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		Result.HasErrors = True;
		
		WriteLogEvent(
			EventTransferringOperationsToResourceSpecifications(),
			EventLogLevel.Error,,
			SamplingMatching.BillOfMaterials,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Result;
	
EndFunction

Procedure MergeCatalogsWithNestedRoutes(RowData, ObjectSpecification, Counters)
	
	QueryOptions = New Structure;
	QueryOptions.Insert("All");
	QueryOptions.Insert("Filter1", "TRUE");
	QueryOptions.Insert("Filter2", "TRUE");
	
	DataToMerge = DataForCombiningCatalogsWithNestedRoutes(
		RowData.BillOfMaterials,
		RowData.Stage,
		RowData.RouteSheet,
		RowData.TechnologicalProcess,
		QueryOptions);
	
	TransactionTable      = DataToMerge.TransactionTable; // ValueTable
	TableMapping = DataToMerge.ResultMatching.Unload(); // ValueTable
	TableMapping.Indexes.Add("Id");
	
	ThereAreConflicts = TableMapping.Find(True, "ThereAreConflicts") <> Undefined;
	
	If ValueIsFilled(RowData.TechnologicalProcess) And Not ThereAreConflicts Then
		
		ConnectTechnologicalProcess(RowData);
		
		For Each String In TableMapping Do
			
			DeleteSpecificationLine(String, ObjectSpecification);
			
		EndDo;
		
		Counters.ConnectedTechnicalProcesses = Counters.ConnectedTechnicalProcesses + 1;
		
	Else
		
		OperationsMatchingTable =  MigrateTableOfOperationsWithNestedRoutes(
			TransactionTable, RowData.Stage, RowData.BillOfMaterials, RowData.RouteSheetFactor);
		
		TheStructureOfTheSearch = New Structure("Id");
		For IndexOf = 0 To OperationsMatchingTable.Count() - 1 Do
			
			FillPropertyValues(TheStructureOfTheSearch, OperationsMatchingTable[IndexOf]);
			
			FoundRows = TableMapping.FindRows(TheStructureOfTheSearch);
			For Each String In FoundRows Do
				
				BindSpecificationStringToOperation(
					String, ObjectSpecification, OperationsMatchingTable[IndexOf].MatchingOperations);
				
			EndDo;
			
		EndDo;
		
		Counters.RescheduledOperations = Counters.RescheduledOperations + TransactionTable.Count();
		
	EndIf;
	
EndProcedure

Function DataForCombiningCatalogs()
	
	QueryText = DataMatchingRequestText();
	
	FilterText11 = "
	|NOT RouteMapLines.LineNumber IS NULL
	|	AND (SpecificationLines.LineNumber IS NULL
	|		OR RouteMapLines.OperationEdit <> VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|		OR TTStages.TechnologicalProcess <> VALUE(Catalog.TechnologicalProcesses.EmptyRef)
	|			AND RouteMapLines.Auxiliary
	|		OR TTStages.ContainsNestedRoute)
	|";
	
	FilterText12 = "
	|NOT RouteMapLines.LineNumber IS NULL
	|	AND (SpecificationLines.LineNumber IS NULL
	|		OR RouteMapLines.OperationEdit <> VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|		OR TTStages.TechnologicalProcess <> VALUE(Catalog.TechnologicalProcesses.EmptyRef)
	|		OR TTStages.ContainsNestedRoute)
	|";
	
	QueryText = StrReplace(QueryText, "&Filter1", FilterText11);
	QueryText = StrReplace(QueryText, "&Filter2", FilterText12);
	QueryText = StrReplace(QueryText, "TOP 1", "");
	
	TextOfResults = "
	|
	|ORDER BY
	|	TSName,
	|	LineNumber
	|TOTALS
	|	MAX(RouteSheet),
	|	MAX(RouteSheetFactor),
	|	MAX(TechnologicalProcess),
	|	MAX(TechnologicalProcessPresentation),
	|	MAX(ThereAreConflicts),
	|	MAX(ContainsNestedRoute)
	|BY
	|	BillOfMaterials,
	|	Stage
	|";
	
	QueryText = QueryText + TextOfResults;
	QueryText = QueryText + "
	|
	|;
	|
	|SELECT
	|	TTStages.BillOfMaterials                                       AS BillOfMaterials,
	|	TTStages.Stage                                               AS Stage,
	|	CAST(Operations.Owner AS Catalog.RouteSheets) AS RouteSheet,
	|	TTStages.RouteSheetFactor                         AS RouteSheetFactor,
	|	TTStages.ContainsNestedRoute                           AS ContainsNestedRoute,
	|	TTStages.TechnologicalProcess                             AS TechnologicalProcess,
	|	TTStages.TechnologicalProcessPresentation                AS TechnologicalProcessPresentation,
	|	Operations.Ref                                            AS Operation,
	|	Operations.OperationNumber                                     AS OperationNumber,
	|	Operations.NextOperation                            AS NextOperation
	|FROM
	|	Catalog.ManufacturingOperations AS Operations
	|
	|		INNER JOIN TTStages AS TTStages
	|		ON CAST(Operations.Owner AS Catalog.RouteSheets) = TTStages.RouteSheet
	|
	|WHERE
	|	NOT Operations.DeletionMark
	|	AND CAST(Operations.Owner AS Catalog.RouteSheets).Status IN (
	|							VALUE(Enum.StatusesOfRouteSheets.Valid),
	|							VALUE(Enum.StatusesOfRouteSheets.UnderDevelopment))
	|
	|ORDER BY
	|	RouteSheet
	|
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("MaterialsAndServices", "%MaterialsAndServices%");
	
	QueryResults      = Query.ExecuteBatch();
	NumberOfResults  = QueryResults.Count();
	
	ResultMatching = QueryResults[NumberOfResults-2];
	TransactionTable        = QueryResults[NumberOfResults-1].Unload();
	TransactionTable.Indexes.Add("Stage");
	
	Return New Structure("ResultMatching, TransactionTable", ResultMatching, TransactionTable);
	
EndFunction

Function DataForCombiningCatalogsWithNestedRoutes(BillOfMaterials, Stage, RouteSheet, TechnologicalProcess, Parameters)
	
	Operations = Catalogs.RouteSheets.RouteMapData(
		RouteSheet, 1, Undefined, Undefined, "Operations").Operations;
		
	QueryText = "
	|SELECT DISTINCT
	|	T.ParentCommunicationKey AS Id,
	|	T.RouteSheet   AS RouteSheet
	|
	|INTO TTRouteMaps
	|FROM
	|	&TransactionTable AS T
	|
	|;
	|";
	
	QueryOptions = RequestParametersRouteMapData("FALSE","FALSE");
	QueryOptions.PlaceResult = True;
	
	QueryText = QueryText + QueryTextRouteMapData_(QueryOptions);
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager();
	Query.Text = QueryText;
	Query.SetParameter("TransactionTable", Operations);
	Query.Execute();
	
	QueryText = "
	|SELECT TOP 1
	|	
	|	RouteMapLines.Id             AS Id,
	|	&BillOfMaterials                                   AS BillOfMaterials,
	|	&Stage                                           AS Stage,
	|	&RouteSheet                                AS RouteSheet,
	|	ProductionStages.RouteSheetFactor    AS RouteSheetFactor,
	|	&TechnologicalProcess                         AS TechnologicalProcess,
	|	""MaterialsAndServices""                            AS TSName,
	|	RouteMapLines.Auxiliary           AS ExcludeFromSpecification,
	|	RouteMapLines.Operation                  AS Operation,
	|
	|	CASE
	|		WHEN &RouteSheet = RouteMapLines.RouteSheet
	|			THEN RouteMapLines.LineNumber
	|		ELSE 99999
	|	END                                           AS LineNumber,
	|	RouteMapLines.Products              AS Products,
	|	RouteMapLines.Characteristic            AS Characteristic,
	|	RouteMapLines.NumberOfPackages        AS Count,
	|	RouteMapLines.QuantityCalculationAlgorithm AS QuantityCalculationAlgorithm,
	|
	|	SpecificationLines.ConnectionKey                    AS SpecificationLineLinkKey,
	|	(SpecificationLines.LineNumber IS NULL)        AS ThereAreConflicts
	|
	|FROM
	|	TTMaterials AS RouteMapLines
	|
	|	LEFT JOIN Catalog.ProductionStages AS ProductionStages
	|	ON ProductionStages.Ref = &Stage
	|
	|	LEFT JOIN Catalog.BillsOfMaterials.MaterialsAndServices AS SpecificationLines
	|	ON &BillOfMaterials = SpecificationLines.Ref
	|		AND &Stage = SpecificationLines.Stage
	|		AND RouteMapLines.Products = SpecificationLines.Products
	|		AND RouteMapLines.Characteristic = SpecificationLines.Characteristic
	|		AND RouteMapLines.NumberOfPackages * ProductionStages.RouteSheetFactor = SpecificationLines.NumberOfPackages
	|		AND RouteMapLines.MethodOfProductsAutoselection = SpecificationLines.MethodOfProductsAutoselection
	|		AND RouteMapLines.MethodOfItemVariantAutoselection = SpecificationLines.MethodOfItemVariantAutoselection
	|		AND RouteMapLines.PropertyThatContainsProducts = SpecificationLines.PropertyThatContainsProducts
	|		AND CAST(RouteMapLines.QuantityCalculationAlgorithm AS STRING(1000)) = CAST(SpecificationLines.QuantityCalculationAlgorithm AS STRING(1000))
	|
	|WHERE
	|	&Filter1
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	
	|	RouteMapLines.Id,
	|	&BillOfMaterials,
	|	&Stage,
	|	&RouteSheet,
	|	ProductionStages.RouteSheetFactor,
	|	&TechnologicalProcess,
	|	""LaborCosts"",
	|	TRUE,
	|	RouteMapLines.Operation,
	|
	|	CASE
	|		WHEN &RouteSheet = RouteMapLines.RouteSheet
	|			THEN RouteMapLines.LineNumber
	|		ELSE 99999
	|	END,
	|	RouteMapLines.WorkKind,
	|	NULL,
	|	RouteMapLines.Count,
	|	RouteMapLines.QuantityCalculationAlgorithm,
	|
	|	SpecificationLines.ConnectionKey,
	|	(SpecificationLines.LineNumber IS NULL)
	|
	|FROM
	|	TTLaborCosts AS RouteMapLines
	|
	|	LEFT JOIN Catalog.ProductionStages AS ProductionStages
	|	ON ProductionStages.Ref = &Stage
	|
	|	LEFT JOIN Catalog.BillsOfMaterials.LaborCosts AS SpecificationLines
	|	ON &BillOfMaterials = SpecificationLines.Ref
	|		AND &Stage = SpecificationLines.Stage
	|		AND RouteMapLines.WorkKind = SpecificationLines.WorkKind
	|		AND RouteMapLines.Count * ProductionStages.RouteSheetFactor = SpecificationLines.Count
	|		AND CAST(RouteMapLines.QuantityCalculationAlgorithm AS STRING(1000)) = CAST(SpecificationLines.QuantityCalculationAlgorithm AS STRING(1000))
	|
	|WHERE
	|	&Filter2
	|
	|";
	
	QueryText = StrReplace(QueryText, "&Filter1", Parameters.Filter1);
	QueryText = StrReplace(QueryText, "&Filter2", Parameters.Filter2);
	
	If Parameters.Property("All") Then
		QueryText = StrReplace(QueryText, "TOP 1", "");
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("BillOfMaterials",           BillOfMaterials);
	Query.SetParameter("Stage",                   Stage);
	Query.SetParameter("RouteSheet",        RouteSheet);
	Query.SetParameter("TechnologicalProcess", TechnologicalProcess);
	
	ResultMatching = Query.Execute();
	
	Return New Structure("ResultMatching, TransactionTable", ResultMatching, Operations);
	
EndFunction

#EndRegion

#Region DisablingRouteMaps

Procedure DisablingUseOfRouteSheetsInBackground(Parameters, StorageAddress) Export
	
	Result = DisableUseOfRouteSheets(Parameters);
	
	PutToTempStorage(Result, StorageAddress);
	
EndProcedure

Function DisableUseOfRouteSheets(Parameters)
	
	Result = New Structure;
	Result.Insert("HasErrors",       False);
	Result.Insert("StagesWereProcessed", 0);
	
	BeginTransaction();
	
	Try
		
		Constants.UseTechnologicalProcesses.Set(True);
		Constants.UseRouteSheets.Set(False);
		
		If Not Constants.StoreOperationsInBillsOfMaterials.Get() Then
			FixTechnicalProcessOfStartedStages(Result);
			Constants.StoreOperationsInBillsOfMaterials.Set(True);
		EndIf;
		
		CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		Result.HasErrors = True;
		
		WriteLogEvent(
			RouteSheetUsageDeactivationEvent(),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return Result;
	
EndFunction

#EndRegion

#Region RouteMapData_

Function RouteMapDataWithNestedRoutes(RouteSheet, QueryOptions = Undefined)
	
	Result = New Structure;
	
	Operations = Catalogs.RouteSheets.RouteMapData(
		RouteSheet, 1, Undefined, Undefined, "Operations").Operations;
		
	QueryText = "
	|SELECT DISTINCT
	|	T.ParentCommunicationKey AS Id,
	|	T.RouteSheet   AS RouteSheet
	|
	|INTO TTRouteMaps
	|FROM
	|	&TransactionTable AS T
	|
	|;
	|";
	
	If QueryOptions = Undefined Then
		QueryOptions = RequestParametersRouteMapData(,"FALSE");
	EndIf;
	
	QueryText = QueryText + QueryTextRouteMapData_(QueryOptions);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("TransactionTable", Operations);
	
	QueryResults = Query.ExecuteBatch();
	NumberOfResults = QueryResults.Count();
	
	Selection = QueryResults[NumberOfResults-4].Select();
	While Selection.Next() Do
		For Each TableName In StrSplit("PropertyMapping,SelectionByProperties", ",") Do
			Table = Selection[TableName].Unload();
			If Not Result.Property(TableName) Then
				Result.Insert(TableName, Table.CopyColumns());
			EndIf;
			CommonClientServer.SupplementTable(Table, Result[TableName]);
		EndDo;
	EndDo;
	Result.Insert("MaterialsAndServices", QueryResults[NumberOfResults-2].Unload());
	Result.Insert("LaborCosts",     QueryResults[NumberOfResults-1].Unload());
	
	For Each KeyAndValue In Result Do
		Indexes = Result[KeyAndValue.Key].Indexes; // Array
		Indexes.Add("Id");
	EndDo;
	
	Result.Insert("Operations", Operations);
	
	Return Result;
	
EndFunction

#EndRegion

#Region QueriesTexts

Function RequestParametersRouteMapData(FilterRouteSheets = "TRUE", FilterOperations = "TRUE", FilterUsedMaterials = "TRUE")
	
	QueryOptions = New Structure;
	
	QueryOptions.Insert("FilterRouteSheets", FilterRouteSheets);
	QueryOptions.Insert("FilterOperations",        FilterOperations);
	QueryOptions.Insert("FilterUsedMaterials",       FilterUsedMaterials);
	
	QueryOptions.Insert("JoinText",      "");
	QueryOptions.Insert("PlaceResult",   False);
	
	Return QueryOptions;
	
EndFunction

Function QueryTextRouteMapData_(QueryOptions)
	
	QueryText = "
	|SELECT
	|	TTRouteMaps.Id            AS Id,
	|	RouteSheets.Ref                     AS RouteSheet,
	|	RouteSheets.Status                     AS Status,
	|	RouteSheets.Description               AS Description,
	|	RouteSheets.ForFinishedProductsKind             AS ForFinishedProductsKind,
	|	RouteSheets.Department              AS Department,
	|	RouteSheets.LongDesc                   AS LongDesc,
	|	RouteSheets.CalculateFactor    AS CalculateFactor,
	|	RouteSheets.NumeratorFactor       AS NumeratorFactor,
	|	RouteSheets.FactorDenominator     AS FactorDenominator,
	|
	|	RouteSheets.PropertyMapping.(
	|		TTRouteMaps.Id     AS Id,
	|		Ref                              AS RouteSheet,
	|		MaterialProperty                   AS MaterialProperty,
	|		ProductsProperty                   AS ProductsProperty,
	|		PropertyValue                    AS PropertyValue,
	|		ValueCalculationAlgorithm             AS ValueCalculationAlgorithm,
	|		ValueSelectionMethod               AS ValueSelectionMethod,
	|		ConnectionKey                           AS ConnectionKey
	|
	|	)                                       AS PropertyMapping,
	|
	|	RouteSheets.SelectionByProperties.(
	|		TTRouteMaps.Id     AS Id,
	|		Ref                              AS RouteSheet,
	|		ConnectionKey                           AS ConnectionKey,
	|		Property                            AS Property,
	|		Condition                             AS Condition,
	|		Value                            AS Value
	|
	|	)                                       AS SelectionByProperties,
	|
	|	TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			Catalog.ManufacturingOperations AS Operations
	|		WHERE
	|			Operations.Owner = RouteSheets.Ref
	|			AND Operations.ContainsNestedRoute
	|			AND NOT Operations.DeletionMark)  AS ContainsNestedRoute
	|
	|FROM
	|	Catalog.RouteSheets AS RouteSheets
	|
	|	INNER JOIN TTRouteMaps AS TTRouteMaps
	|		ON TTRouteMaps.RouteSheet = RouteSheets.Ref
	|
	|WHERE
	|	&FilterRouteSheets
	|
	|ORDER BY
	|	Id
	|
	|;
	|//////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	TTRouteMaps.Id                            AS Id,
	|	CAST(Operations.Owner AS Catalog.RouteSheets) AS RouteSheet,
	|	Operations.Ref                                            AS Operation,
	|	Operations.OperationNumber                                     AS OperationNumber,
	|	Operations.NextOperation                            AS NextOperation
	|FROM
	|	Catalog.ManufacturingOperations AS Operations
	|
	|	INNER JOIN TTRouteMaps AS TTRouteMaps
	|		ON TTRouteMaps.RouteSheet = Operations.Owner
	|
	|WHERE
	|	NOT Operations.DeletionMark
	|	AND &FilterOperations
	|
	|ORDER BY
	|	Id
	|
	|;
	|//////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	TTRouteMaps.Id            AS Id,
	|	UsedMaterials.Ref                           AS RouteSheet,
	|	UsedMaterials.LineNumber                      AS LineNumber,
	|	UsedMaterials.Products                     AS Products,
	|	UsedMaterials.Characteristic                   AS Characteristic,
	|	UsedMaterials.NumberOfPackages               AS NumberOfPackages,
	|	UsedMaterials.Package                         AS Package,
	|	UsedMaterials.ProductCostElement                AS ProductCostElement,
	|	UsedMaterials.MethodOfProductsAutoselection     AS MethodOfProductsAutoselection,
	|	UsedMaterials.MethodOfItemVariantAutoselection   AS MethodOfItemVariantAutoselection,
	|	UsedMaterials.PropertyThatContainsProducts   AS PropertyThatContainsProducts,
	|	UsedMaterials.QuantityCalculationAlgorithm        AS QuantityCalculationAlgorithm,
	|	UsedMaterials.MaterialApplication              AS MaterialApplication,
	|	UsedMaterials.Operation                         AS Operation,
	|	UsedMaterials.OperationEdit           AS OperationEdit,
	|	UsedMaterials.ConnectionKey                        AS ConnectionKey,
	|	UsedMaterials.ItemVariantAutoSelectionAlgorithm AS ItemVariantAutoSelectionAlgorithm,
	|	UsedMaterials.Auxiliary                  AS Auxiliary
	|
	|INTO TTMaterials
	|
	|FROM 
	|	Catalog.RouteSheets.MaterialsAndServices AS UsedMaterials
	|
	|	INNER JOIN TTRouteMaps AS TTRouteMaps
	|		ON TTRouteMaps.RouteSheet = UsedMaterials.Ref
	|
	|WHERE
	|	UsedMaterials.Ref.UseMaterials
	|	AND &FilterUsedMaterials
	|
	|;
	|//////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	TTRouteMaps.Id         AS Id,
	|	LaborCosts.Ref                     AS RouteSheet,
	|	LaborCosts.LineNumber                AS LineNumber,
	|	LaborCosts.WorkKind                   AS WorkKind,
	|	LaborCosts.Count                 AS Count,
	|	LaborCosts.ProductCostElement          AS ProductCostElement,
	|	LaborCosts.Operation                   AS Operation,
	|	LaborCosts.OperationEdit     AS OperationEdit,
	|	LaborCosts.WorkAssignment            AS WorkAssignment,
	|	LaborCosts.QuantityCalculationAlgorithm  AS QuantityCalculationAlgorithm,
	|	LaborCosts.ConnectionKey                  AS ConnectionKey
	|
	|INTO TTLaborCosts
	|
	|FROM
	|	Catalog.RouteSheets.LaborCosts AS LaborCosts
	|
	|	INNER JOIN TTRouteMaps AS TTRouteMaps
	|		ON TTRouteMaps.RouteSheet = LaborCosts.Ref
	|
	|WHERE
	|	LaborCosts.Ref.UseLaborCosts
	|
	|";
	
	QueryText = StrReplace(QueryText, "&FilterOperations",        QueryOptions.FilterOperations);
	QueryText = StrReplace(QueryText, "&FilterUsedMaterials",       QueryOptions.FilterUsedMaterials);
	QueryText = StrReplace(QueryText, "&FilterRouteSheets", QueryOptions.FilterRouteSheets);
	
	If Not IsBlankString(QueryOptions.JoinText) Then
		ArrayOfTexts = New Array;
		ArrayOfTexts.Add("TTRouteMaps.RouteSheet = RouteSheets.Ref");
		ArrayOfTexts.Add("TTRouteMaps.RouteSheet = Operations.Owner");
		ArrayOfTexts.Add("TTRouteMaps.RouteSheet = UsedMaterials.Ref");
		ArrayOfTexts.Add("TTRouteMaps.RouteSheet = LaborCosts.Ref");
		For Each Text In ArrayOfTexts Do
			QueryText = StrReplace(QueryText, Text, QueryOptions.JoinText);
		EndDo;
	EndIf;
	
	If Not QueryOptions.PlaceResult Then
		QueryText = StrReplace(QueryText, "INTO TTMaterials",    "");
		QueryText = StrReplace(QueryText, "INTO TTLaborCosts", "");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function TextOfMainRouteMapSelection(TableName = "RouteSheets") Export
	
	QueryText = 
	"MainTable.Status IN (
	|				VALUE(Enum.StatusesOfRouteSheets.Valid),
	|				VALUE(Enum.StatusesOfRouteSheets.UnderDevelopment))
	|	AND MainTable.UseOperations
	|	AND NOT TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.TechnologicalProcesses AS T
	|				WHERE
	|					T.Basis = MainTable.Ref
	|					AND NOT T.DeletionMark)
	|";
		
	QueryText = StrReplace(QueryText, "MainTable", TableName);
		
	Return QueryText;
	
EndFunction

Function RequestTextRouteMapsAll(OnlyQuantity = True)
	
	QueryText = "
	|SELECT DISTINCT
	|	&RouteSheet
	|FROM
	|	Catalog.RouteSheets AS RouteSheets
	|
	|WHERE
	|	&RouteMapSelection
	|";
	
	If OnlyQuantity Then
		QueryText = StrReplace(QueryText, "&RouteSheet", "COUNT(RouteSheets.Ref) AS Count");
	Else
		QueryText = StrReplace(QueryText, "&RouteSheet", "RouteSheets.Ref AS RouteSheet");
	EndIf;
	QueryText = StrReplace(QueryText, "&RouteMapSelection",TextOfMainRouteMapSelection());
	
	Return QueryText;
	
EndFunction

Function RequestTextReusableRouteMaps()
	
	QueryText = "
	|SELECT
	|	ProductionStages.RouteSheet AS RouteSheet
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|
	|WHERE
	|	ProductionStages.RouteSheet <> VALUE(Catalog.RouteSheets.EmptyRef)
	|	AND ProductionStages.Owner.Status = VALUE(Enum.BOMStatuses.Valid)
	|	AND NOT ProductionStages.DeletionMark
	|	AND &RouteMapSelection
	|
	|GROUP BY
	|	ProductionStages.RouteSheet
	|
	|HAVING
	|	COUNT(DISTINCT ProductionStages.Ref) > 1
	|
	|ORDER BY
	|	ProductionStages.RouteSheet.Code
	|
	|";
	QueryText = StrReplace(QueryText,
		"&RouteMapSelection",TextOfMainRouteMapSelection("ProductionStages.RouteSheet"));
	
	Return QueryText;
	
EndFunction

Function DataMatchingRequestText()
	
	QueryText = "
	|SELECT
	|	Stages.Owner                     AS BillOfMaterials,
	|	Stages.Ref                       AS Stage,
	|	Stages.RouteSheet              AS RouteSheet,
	|	Stages.RouteSheetFactor   AS RouteSheetFactor,
	|	TRUE IN (
	|		SELECT TOP  1
	|			TRUE
	|		FROM
	|			Catalog.BillsOfMaterials.MaterialsAndServices AS T
	|		WHERE
	|			T.Ref = Stages.Owner
	|			AND T.QuantityCalculationAlgorithm LIKE &MaterialsAndServices
	|
	|		UNION ALL
	|
	|		SELECT TOP  1
	|			TRUE
	|		FROM
	|			Catalog.BillsOfMaterials.LaborCosts AS T
	|		WHERE
	|			T.Ref = Stages.Owner
	|			AND T.QuantityCalculationAlgorithm LIKE &MaterialsAndServices)                   AS ThereAreReferencesToStringsInFormulas,
	|	TRUE IN (
	|		SELECT TOP  1
	|			TRUE
	|		FROM
	|			Catalog.ManufacturingOperations AS Operations
	|		WHERE
	|			Operations.Owner = Stages.RouteSheet
	|			AND Operations.ContainsNestedRoute
	|			AND NOT Operations.DeletionMark)                                                  AS ContainsNestedRoute,
	|	ISNULL(TechnicalProcesses.Ref, VALUE(Catalog.TechnologicalProcesses.EmptyRef)) AS TechnologicalProcess,
	|	ISNULL(TechnicalProcesses.Description,"""")                                                 AS TechnologicalProcessPresentation
	|
	|INTO TTStages
	|FROM
	|	Catalog.ProductionStages AS Stages
	|	
	|	LEFT JOIN Catalog.TechnologicalProcesses AS TechnicalProcesses
	|	ON Stages.RouteSheet = TechnicalProcesses.Basis
	|		AND TechnicalProcesses.Status = VALUE(Enum.TechnologicalProcessStatuses.Valid)
	|	
	|WHERE
	|	Stages.RouteSheet <> VALUE(Catalog.RouteSheets.EmptyRef)
	|	AND NOT Stages.DeletionMark
	|	AND NOT TRUE IN (
	|			SELECT TOP  1
	|				TRUE
	|			FROM
	|				Catalog.ManufacturingOperations AS T
	|			WHERE
	|				T.Owner = Stages.Ref AND NOT T.DeletionMark)
	|
	|INDEX BY
	|	RouteSheet
	|
	|;
	|
	|SELECT TOP 1
	|	TTStages.BillOfMaterials                               AS BillOfMaterials,
	|	TTStages.Stage                                       AS Stage,
	|	TTStages.RouteSheet                            AS RouteSheet,
	|	TTStages.RouteSheetFactor                 AS RouteSheetFactor,
	|	TTStages.TechnologicalProcess                     AS TechnologicalProcess,
	|	TTStages.TechnologicalProcessPresentation        AS TechnologicalProcessPresentation,
	|	TTStages.ContainsNestedRoute                   AS ContainsNestedRoute,
	|	""MaterialsAndServices""                               AS TSName,
	|	RouteMapLines.Auxiliary              AS ExcludeFromSpecification,
	|	RouteMapLines.OperationEdit       AS Operation,
	|	RouteMapLines.LineNumber                  AS LineNumber,
	|	RouteMapLines.Products                 AS Products,
	|	RouteMapLines.Characteristic               AS Characteristic,
	|	RouteMapLines.NumberOfPackages           AS Count,
	|	RouteMapLines.QuantityCalculationAlgorithm    AS QuantityCalculationAlgorithm,
	|	SpecificationLines.ConnectionKey                       AS SpecificationLineLinkKey,
	|	(NOT RouteMapLines.LineNumber IS NULL
	|		AND SpecificationLines.LineNumber IS NULL)
	|			OR TTStages.ThereAreReferencesToStringsInFormulas    AS ThereAreConflicts
	|	
	|FROM
	|	TTStages AS TTStages
	|		LEFT JOIN Catalog.RouteSheets.MaterialsAndServices AS RouteMapLines
	|			ON (TTStages.RouteSheet = RouteMapLines.Ref)
	|		LEFT JOIN Catalog.BillsOfMaterials.MaterialsAndServices AS SpecificationLines
	|			ON TTStages.BillOfMaterials = SpecificationLines.Ref
	|				AND TTStages.Stage = SpecificationLines.Stage
	|				AND RouteMapLines.Products = SpecificationLines.Products
	|				AND RouteMapLines.Characteristic = SpecificationLines.Characteristic
	|				AND RouteMapLines.NumberOfPackages * TTStages.RouteSheetFactor = SpecificationLines.NumberOfPackages
	|				AND RouteMapLines.MethodOfProductsAutoselection = SpecificationLines.MethodOfProductsAutoselection
	|				AND RouteMapLines.MethodOfItemVariantAutoselection = SpecificationLines.MethodOfItemVariantAutoselection
	|				AND RouteMapLines.PropertyThatContainsProducts = SpecificationLines.PropertyThatContainsProducts
	|				AND CAST(RouteMapLines.QuantityCalculationAlgorithm AS STRING(1000)) = CAST(SpecificationLines.QuantityCalculationAlgorithm AS STRING(1000))
	|
	|WHERE
	|	&Filter1
	|		
	|UNION ALL
	|
	|SELECT TOP 1
	|	TTStages.BillOfMaterials,
	|	TTStages.Stage,
	|	TTStages.RouteSheet,
	|	TTStages.RouteSheetFactor,
	|	TTStages.TechnologicalProcess,
	|	TTStages.TechnologicalProcessPresentation,
	|	TTStages.ContainsNestedRoute,
	|	""LaborCosts"",
	|	TRUE,
	|	RouteMapLines.OperationEdit,
	|	RouteMapLines.LineNumber,
	|	RouteMapLines.WorkKind,
	|	NULL,
	|	RouteMapLines.Count,
	|	RouteMapLines.QuantityCalculationAlgorithm,
	|	SpecificationLines.ConnectionKey,
	|	(NOT RouteMapLines.LineNumber IS NULL
	|		AND SpecificationLines.LineNumber IS NULL)
	|			OR TTStages.ThereAreReferencesToStringsInFormulas
	|	
	|FROM
	|	TTStages AS TTStages
	|		LEFT JOIN Catalog.RouteSheets.LaborCosts AS RouteMapLines
	|			ON (TTStages.RouteSheet = RouteMapLines.Ref)
	|		LEFT JOIN Catalog.BillsOfMaterials.LaborCosts AS SpecificationLines
	|			ON TTStages.BillOfMaterials = SpecificationLines.Ref
	|				AND TTStages.Stage = SpecificationLines.Stage
	|				AND RouteMapLines.WorkKind = SpecificationLines.WorkKind
	|				AND RouteMapLines.Count * TTStages.RouteSheetFactor = SpecificationLines.Count
	|				AND CAST(RouteMapLines.QuantityCalculationAlgorithm AS STRING(1000)) = CAST(SpecificationLines.QuantityCalculationAlgorithm AS STRING(1000))
	|
	|WHERE
	|	&Filter2
	|
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Procedure ConnectTechnologicalProcess(RowData)
	
	OperationObject = Catalogs.ManufacturingOperations.CreateItem();
	OperationObject.Fill(Undefined);
	OperationObject.Owner                            = RowData.Stage;
	OperationObject.BillOfMaterials                        = RowData.BillOfMaterials;
	OperationObject.Description                        = RowData.TechnologicalProcessPresentation;
	OperationObject.TechnologicalProcess              = RowData.TechnologicalProcess;
	OperationObject.TechnologicalProcessFactor = RowData.RouteSheetFactor;
	OperationObject.OperationNumber                       = 1;
	OperationObject.NextOperation              = 0;
	OperationObject.ContainsTechnologicalProcess      = True;
	OperationObject.DataExchange.Load               = True;
	OperationObject.Write();
	
EndProcedure

Procedure BindSpecificationStringToOperation(RowData, ObjectSpecification, MatchingOperations);
	
	If RowData.ThereAreConflicts Then
		Return;
	EndIf;
	
	Operation = MatchingOperations.Get(RowData.Operation);
	If Operation = Undefined Then
		Return;
	EndIf;
	
	GetSpecificationObjectToProcess(RowData.BillOfMaterials, ObjectSpecification);
	
	TabularSection = ObjectSpecification[RowData.TSName];
	
	String = TabularSection.Find(RowData.SpecificationLineLinkKey, "ConnectionKey");
	If String <> Undefined Then
		String.StageEditing     = RowData.Stage;
		String.OperationEdit = Operation;
	EndIf;
	
EndProcedure

Procedure DeleteSpecificationLine(RowData, ObjectSpecification)
	
	If Not RowData.ExcludeFromSpecification Then
		Return;
	EndIf;
	
	GetSpecificationObjectToProcess(RowData.BillOfMaterials, ObjectSpecification);
	
	TabularSection = ObjectSpecification[RowData.TSName];
	
	String = TabularSection.Find(RowData.SpecificationLineLinkKey, "ConnectionKey");
	If String <> Undefined Then
		
		TabularSection.Delete(String);
		
	EndIf;
	
EndProcedure

Procedure MigrateOperationsTable(Operations, Owner, BillOfMaterials, MatchingOperations = Undefined, ZoomRatio = 1)
	
	For IndexOf = 0 To Operations.Count() - 1 Do
		
		String = Operations[IndexOf];
		
		OperationObject = String.Operation.Copy(); // CatalogObject.ManufacturingOperations
		OperationObject.Owner               = Owner;
		OperationObject.BillOfMaterials           = BillOfMaterials;
		OperationObject.OperationNumber          = String.OperationNumber;
		OperationObject.NextOperation = String.NextOperation;
		OperationObject.Count             = OperationObject.Count * ZoomRatio;
		OperationObject.TimePerPiece           = OperationObject.TimePerPiece * ZoomRatio;
		OperationObject.Id          = IndexOf+1;
		OperationObject.DataExchange.Load  = True;
		OperationObject.Write();
		If MatchingOperations <> Undefined Then
			MatchingOperations.Insert(String.Operation, OperationObject.Ref);
		EndIf;
	EndDo;
	
EndProcedure

Function MigrateTableOfOperationsWithNestedRoutes(Operations, Owner, BillOfMaterials, ZoomRatio = 1)
	
	OperationsMatchingTable = New ValueTable;
	OperationsMatchingTable.Columns.Add("Id");
	OperationsMatchingTable.Columns.Add("RouteSheet");
	OperationsMatchingTable.Columns.Add("MatchingOperations");
	
	For IndexOf = 0 To Operations.Count() - 1 Do
		
		String = Operations[IndexOf];
		
		OperationObject = String.Operation.Copy(); // CatalogObject.ManufacturingOperations
		OperationObject.Owner               = Owner;
		OperationObject.BillOfMaterials           = BillOfMaterials;
		OperationObject.OperationNumber          = String.OperationNumber;
		OperationObject.NextOperation = String.NextOperation;
		OperationObject.Count             = OperationObject.Count * ZoomRatio;
		OperationObject.TimePerPiece           = OperationObject.TimePerPiece * ZoomRatio;
		OperationObject.Id          = IndexOf+1;
		OperationObject.DataExchange.Load  = True;
		OperationObject.Write();
		
		MapRow = OperationsMatchingTable.Find(String.ParentCommunicationKey, "Id");
		If MapRow = Undefined Then
			MapRow = OperationsMatchingTable.Add();
			MapRow.Id        = String.ParentCommunicationKey;
			MapRow.RouteSheet      = String.RouteSheet;
			MapRow.MatchingOperations = New Map;
		EndIf;
		
		MapRow.MatchingOperations.Insert(String.Operation, OperationObject.Ref);
		
	EndDo;
	
	Return OperationsMatchingTable;
	
EndFunction

Procedure CheckClearQuantityCalculationAlgorithm(RowData)
	
	If StrFind(RowData.QuantityCalculationAlgorithm, "[Operation") > 0
		Or StrFind(RowData.QuantityCalculationAlgorithm, "[ManufacturedProducts") > 0
		Or StrFind(RowData.QuantityCalculationAlgorithm, "[MaterialsAndServices") > 0 Then
		RowData.QuantityCalculationAlgorithm = "";
	EndIf;
	
EndProcedure

Procedure FixTechnicalProcessOfStartedStages(Counters)
	
	QueryText = "
	|SELECT
	|	DocumentAttributes.Ref AS Stage,
	|	&TechProcessParameters
	|FROM
	|	Document.ProductionStage2_2 AS DocumentAttributes
	|		LEFT JOIN InformationRegister.TechnologicalProcessesOfProductionStages AS TechnicalProcess
	|		ON DocumentAttributes.Ref = TechnicalProcess.Stage
	|WHERE
	|	DocumentAttributes.Posted
	|	AND DocumentAttributes.Stage.RouteSheet <> VALUE(Catalog.RouteSheets.EmptyRef)
	|	AND (
	|		(DocumentAttributes.Department.UseManufacturingExecutionSystem
	|			OR DocumentAttributes.Department.UseShiftTasks)
	|		AND DocumentAttributes.Status IN (
	|							VALUE(Enum.StatusesOfProductionStages2_2.ForCompletion),
	|							VALUE(Enum.StatusesOfProductionStages2_2.Initiated))
	|		OR (DocumentAttributes.Department.UseOperationManagement
	|		AND DocumentAttributes.Status = VALUE(Enum.StatusesOfProductionStages2_2.Initiated))
	|	)
	|	AND TechnicalProcess.Stage IS NULL";
	
	QueryText = StrReplace(QueryText,
		"&TechProcessParameters",
		ProductionProcessEditor.QueryTextParametersOfTechnicalProcessOfStage());
	
	Query = New Query;
	Query.Text = QueryText;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		TechProcessParameters = ProductionProcessEditorClientServer.ProcessParametersConstructor();
		FillPropertyValues(TechProcessParameters, Selection);
		
		InformationRegisters.TechnologicalProcessesOfProductionStages.RecordProcessParameters(Selection.Stage, TechProcessParameters);
		Counters.StagesWereProcessed = Counters.StagesWereProcessed + 1;
		
	EndDo;
	
EndProcedure

Function EventCreationOfStandardTechnologicalProcesses()
	
	Return StrTemplate("%1.%2",
			 NStr("vi = 'Danh mục sản xuất';
					|ru = 'НСИ производства';
					|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
					|it = 'Informazioni Normative e di Rferimento della produzione';
					|pl = 'Informacja normatywno-pomocnicza produkcji';
					|tr = 'Üretim master verisi'", Common.DefaultLanguageCode()),
			 NStr("vi = 'Tạo quy trình kỹ thuật mẫu.';
					|ru = 'Создание типовых технологических процессов.';
					|en = 'Generating standard technological processes.'; fa = 'Generating standard technological processes.';
					|it = 'Creazione di processi tecnologici standard.';
					|pl = 'Utworzenie typowych procesów technologicznych.';
					|tr = 'Standart teknolojik süreçlerin oluşturulması.'", Common.DefaultLanguageCode()));
	
EndFunction

Function EventTransferringOperationsToResourceSpecifications()
	
	Return StrTemplate("%1.%2",
			 NStr("vi = 'Danh mục sản xuất';
					|ru = 'НСИ производства';
					|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
					|it = 'Informazioni Normative e di Rferimento della produzione';
					|pl = 'Informacja normatywno-pomocnicza produkcji';
					|tr = 'Üretim master verisi'", Common.DefaultLanguageCode()),
			 NStr("vi = 'Chuyển đổi giao dịch sang bảng kê chi tiết nguồn lực.';
					|ru = 'Перенос операций в ресурсные спецификации.';
					|en = 'Transferring operations to bills of materials.'; fa = 'Transferring operations to bills of materials.';
					|it = 'Trasferimento di operazioni nelle specifiche delle risorse.';
					|pl = 'Przeniesienie operacji do specyfikacji zasobów.';
					|tr = 'İşlemlerin ürün reçetelerine aktarılması.'", Common.DefaultLanguageCode()));
	
EndFunction

Function RouteSheetUsageDeactivationEvent()
	
	Return StrTemplate("%1.%2",
			 NStr("vi = 'Danh mục sản xuất';
					|ru = 'НСИ производства';
					|en = 'Manufacturing master data'; fa = 'Manufacturing master data';
					|it = 'Informazioni Normative e di Rferimento della produzione';
					|pl = 'Informacja normatywno-pomocnicza produkcji';
					|tr = 'Üretim master verisi'", Common.DefaultLanguageCode()),
			 NStr("vi = 'Ngắt sử dụng thẻ quy trình.';
					|ru = 'Отключение использования маршрутных карт.';
					|en = 'Disable using route sheets.'; fa = 'Disable using route sheets.';
					|it = 'Disable using route sheets.';
					|pl = 'Disable using route sheets.';
					|tr = 'Rotalarının kullanımının devre dışı bırakılması.'", Common.DefaultLanguageCode()));
	
EndFunction

Function OptionForSelectingRouteMapsReusable()
	Return 1;
EndFunction

Function OptionForSelectingRouteMapsBySelection()
	Return 2;
EndFunction

Function RouteMapSelectionOptionAll()
	Return 0;
EndFunction

Procedure GetSpecificationObjectToProcess(BillOfMaterials, ObjectSpecification)
	
	If ObjectSpecification <> Undefined Then
		Return; // the object has already been received
	EndIf;
	
	ObjectSpecification = BillOfMaterials.GetObject();
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
