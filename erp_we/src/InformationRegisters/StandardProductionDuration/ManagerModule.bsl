#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Calculates the standard production duration
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Tasks for the duration of production", there are also service columns:
//             * ObjectOfARAP          - CatalogRef.BillsOfMaterials, CatalogRef.BusinessStructure, CatalogRef.Calendars -
//             * DeleteJobNumber    - Number -
//             * RecordID    - UUID -
//             * NotUsedRegistrationDay - Number  -
//             * CompleteCalculation           - Boolean -
//             * CalculateDaysBeforeEnd  - Boolean -
//             * AddedOn         - Date -
//             * RecordDate             - Date   -
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
Procedure PerformTheCalculation(Jobs, IdsOfUnprocessedRecords, AdditionalProperties = Undefined) Export
	
	TimeMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement("InformationRegister.StandardProductionDuration.ManagerModule.Calculate");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Jobs.ObjectOfARAP       AS ObjectOfARAP,
	|	Jobs.CompleteCalculation        AS CompleteCalculation,
	|	Jobs.RecordID AS RecordID,
	|	Jobs.RecordDate          AS RecordDate
	|INTO Jobs
	|FROM
	|	&Jobs AS Jobs
	|
	|INDEX BY
	|	ObjectOfARAP
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Jobs.ObjectOfARAP       AS ObjectOfARAP,
	|	Jobs.CompleteCalculation        AS CompleteCalculation,
	|	Jobs.RecordID AS RecordID,
	|	Jobs.RecordDate          AS RecordDate,
	|
	|	PRESENTATION(Jobs.ObjectOfARAP) AS ObjectOfARAPPresentation
	|
	|FROM
	|	Jobs AS Jobs
	|
	|ORDER BY
	|	RecordDate,
	|	ObjectOfARAP
	|
	|TOTALS
	|	MAX(CompleteCalculation)        AS CompleteCalculation,
	|	MAX(RecordID) AS RecordID,
	|	MIN(RecordDate)           AS RecordDate
	|BY
	|	ObjectOfARAP
	|";
	
	Query.SetParameter("Jobs", Jobs);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	ObjectTypes_ = New Array;
	ObjectTypes_.Add(Type("CatalogRef.BillsOfMaterials"));
	ObjectTypes_.Add(Type("CatalogRef.BusinessStructure"));
	ObjectTypes_.Add(Type("CatalogRef.Calendars"));
	
	AdditionalData = New Structure;
	AdditionalData.Insert("TableOfDependentObjects", New ValueTable);
	AdditionalData.TableOfDependentObjects.Columns.Add("DependentObject", New TypeDescription(ObjectTypes_));
	AdditionalData.TableOfDependentObjects.Columns.Add("CompleteCalculation",    New TypeDescription("Boolean"));
	AdditionalData.TableOfDependentObjects.Indexes.Add("DependentObject");
	
	ErrorFields = Undefined;
	
	Selection = QueryResult.Select(QueryResultIteration.ByGroups);
	While Selection.Next() Do
		
		ObjectOfARAP = Selection.ObjectOfARAP;
		CompleteCalculation  = Selection.CompleteCalculation;
		
		ErrorText   = "";
		
		Calculate(ObjectOfARAP, CompleteCalculation, AdditionalData, ErrorText);
		
		If ValueIsFilled(ErrorText) Then
			
			If ErrorFields = Undefined Then
				ErrorFields = New Structure;
				ErrorFields.Insert("ObjectOfARAPPresentation", "ObjectOfARAP");
				ErrorFields.Insert("CompleteCalculation");
			EndIf;
			
			ErrorText = DeferredJobs.ExecutionErrorText(ErrorFields, Selection, ErrorText);
			
			IDsSelection = Selection.Select();
			While IDsSelection.Next() Do
				IdsOfUnprocessedRecords.Insert(IDsSelection.RecordID, ErrorText);
			EndDo;
			
		EndIf;
		
	EndDo;
	
	TableOfDependentObjects = AdditionalData.TableOfDependentObjects;
	If TableOfDependentObjects.Count() > 0 Then
		
		For Each TableRow In TableOfDependentObjects Do
			
			DependentObject = TableRow.DependentObject;
			CompleteCalculation    = TableRow.CompleteCalculation;
			
			Calculate(DependentObject, CompleteCalculation, AdditionalData);

		EndDo;
		
	EndIf;
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(TimeMeasurement, 1);
	
EndProcedure

// Returns the production duration for the specification
//
// Parameters:
//  BillOfMaterials - CatalogRef.BillsOfMaterials, Array - specifications.
// 
// Returns:
//   - Structure, Map - duration of production.
//
Function GetDuration(BillOfMaterials) Export
	
	QueryText = RequestTextForProductionDurationAccordingToSpecification();
	
	Query = New Query(QueryText);
	Query.SetParameter("ReferencesArrray", ProductionServer.ArrayOfValues(BillOfMaterials));
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute();
	SetPrivilegedMode(False);
	
	If TypeOf(BillOfMaterials) <> Type("Array") Then
		
		Result = RegisterEntryDataStructure();
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			Selection.Next();
			FillPropertyValues(Result, Selection);
		EndIf;
		
	Else
		
		Result = New Map;
		If Not QueryResult.IsEmpty() Then
			Selection = QueryResult.Select();
			While Selection.Next() Do
				Data = RegisterEntryDataStructure();
				FillPropertyValues(Data, Selection);
				Result.Insert(Selection.BillOfMaterials, Data);
			EndDo;
		EndIf;
		
		For Each Item In BillOfMaterials Do
			If Result.Get(Item) <> Undefined Then
				Continue;
			EndIf;
			Data = RegisterEntryDataStructure();
			Result.Insert(Item, Data);
		EndDo;

	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

#Region CalculationOfDuration

Procedure Calculate(ObjectOfARAP, CompleteCalculation, AdditionalData, ErrorText = "")
	
	SetPrivilegedMode(True);
	
	HasErrors = False;
	HasChanges = False;
	
	// calculation of the standard duration of production
	
	CalculationAccordingToSpecification = ( TypeOf(ObjectOfARAP) = Type("CatalogRef.BillsOfMaterials") );
	If CalculationAccordingToSpecification Then
		
		BillOfMaterials = ObjectOfARAP;
		
		If CompleteCalculation Then
			
			HasErrors = HasErrors
						 Or Not InformationRegisters.StandardDurationOfProductionStages.Calculate(
																							BillOfMaterials,
																							ErrorText);
			
		EndIf;
		
		If Not HasErrors Then
			
			CalculationResult2 = CalculateDuration(BillOfMaterials);
			
			BeginTransaction();
			
			Try
				
				Block = New DataLock;
				
				LockItem = Block.Add("InformationRegister.StandardProductionDuration");
				LockItem.SetValue("BillOfMaterials", BillOfMaterials);
				
				Block.Lock();
				
				DurationBeforeChange = GetDuration(BillOfMaterials);
				
				HasChanges = Not DurationsAreEqual(CalculationResult2, DurationBeforeChange);
				If HasChanges Then
					RecordCalculationResult(BillOfMaterials, CalculationResult2);
				EndIf;
				
				CommitTransaction();
				
			Except
				
				RollbackTransaction();
				
				EventLogEvent = ProductionServer.EventCalculationOfNormativeDuration();
				
				ErrorText = StrTemplate(NStr("vi = 'Không thể xử lý: %1 do: %2';
											|ru = 'Не удалось обработать спецификацию: %1 по причине: %2';
											|en = 'Cannot process the BOM: %1. Reason: %2'; fa = 'Cannot process the BOM: %1. Reason: %2';
											|it = 'Non è stato possibile elaborare la specifica: %1 a causa di: %2';
											|pl = 'Nie udało się przetworzyć specyfikacji: %1 z powodu: %2';
											|tr = 'Ürün reçetesinin işlenemedi: %1 çünkü: %2'"),
											BillOfMaterials,
											ErrorProcessing.DetailErrorDescription(ErrorInfo()));
				
				WriteLogEvent(
					EventLogEvent,
					EventLogLevel.Error,
					BillOfMaterials.Metadata(),
					BillOfMaterials,
					ErrorText);
				
				HasErrors = True;
				HasChanges = False;
			
			EndTry;
			
		EndIf;
		
	EndIf;
	
	// adding dependent objects to the calculation queue
	
	If HasChanges Or Not CalculationAccordingToSpecification Then
		
		DurationOfDependent = New Map;
		
		DependentObjects = DependentCalculationObjects(ObjectOfARAP);
		
		If ValueIsFilled(DependentObjects) Then
			
			If CalculationAccordingToSpecification Then
				
				DurationOfDependent = GetDuration(DependentObjects);
				For Each KeyAndValue In DurationOfDependent Do
					If KeyAndValue.Value.Limit_  >  Max(CalculationResult2.PlannedProductionDurationDays,
																DurationBeforeChange.PlannedProductionDurationDays)
						And ( KeyAndValue.Value.Cached = CalculationResult2.Cached
							Or CalculationResult2.Cached = DurationBeforeChange.Cached ) Then
						DependentObjects.Delete(DependentObjects.Find(KeyAndValue.Key));
					EndIf;
				EndDo;
				
			EndIf;
			
			PerformControlOfCalculationLoop(ObjectOfARAP, DependentObjects, AdditionalData);
				
			FilterDependentObject = New Structure("DependentObject");
			
			For Each DependentObject In DependentObjects Do
				
				CompleteCalculation = Not CalculationAccordingToSpecification Or (DurationOfDependent[DependentObject] <> Undefined
															And DurationOfDependent[DependentObject].ContainsNestedBOMs);
				
				FilterDependentObject.DependentObject = DependentObject;
				
				FoundRows = AdditionalData.TableOfDependentObjects.FindRows(FilterDependentObject);
				If FoundRows.Count() = 0 Then
					
					TableRow = AdditionalData.TableOfDependentObjects.Add();
					TableRow.DependentObject = DependentObject;
					TableRow.CompleteCalculation    = CompleteCalculation;
					
				ElsIf CompleteCalculation Then
					
					TableRow = FoundRows[0];
					If Not TableRow.CompleteCalculation Then
						TableRow.CompleteCalculation = CompleteCalculation;
					EndIf;
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

Function RequestTextForProductionDurationAccordingToSpecification()
	
	QueryText = 
	"SELECT
	|	ProductionTime.BillOfMaterials AS BillOfMaterials,
	|
	|	ProductionTime.Duration             AS Duration,
	|	ProductionTime.PlannedProductionDurationDays     AS PlannedProductionDurationDays,
	|	ProductionTime.MaximumProductionDurationDays AS MaximumProductionDurationDays,
	|
	|	ProductionTime.Limit_                    AS Limit_,
	|	ProductionTime.ContainsNestedBOMs AS ContainsNestedBOMs,
	|
	|	ProductionTime.Cached AS Cached
	|FROM
	|	InformationRegister.StandardProductionDuration AS ProductionTime
	|WHERE
	|	ProductionTime.BillOfMaterials IN (&ReferencesArrray)";
	
	Return QueryText;
	
EndFunction

Function RequestTextCalculationOfRelatedSpecifications(Filter = Undefined)
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.Stage   AS Stage,
	|
	|	Table.BillOfMaterials   AS BillOfMaterials,
	|	Table.Alternative AS Alternative,
	|
	|	MAX(Table.IncomingSpecification)  AS IncomingSpecification,
	|	MAX(Table.OutgoingSpecification) AS OutgoingSpecification,
	|	MAX(Table.NestedSpecification) AS NestedSpecification
	|
	|INTO TTRelatedSpecifications
	|FROM
	|(
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.Stage AS Stage,
	|	Table.BillOfMaterials AS BillOfMaterials,
	|	FALSE AS Alternative,
	|	FALSE AS IncomingSpecification,
	|	TRUE AS OutgoingSpecification,
	|	FALSE AS NestedSpecification
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.ProcessByBOM
	|	AND Table.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref,
	|	Table.Stage,
	|	Table.BillOfMaterials,
	|	FALSE,
	|	FALSE,
	|	TRUE,
	|	FALSE
	|FROM
	|	Catalog.BillsOfMaterials.RecyclableWaste AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.ProcessByBOM
	|	AND Table.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref,
	|	Table.Stage,
	|	Table.SourceOfSemiFinishedProduct,
	|	Table.AlternateType,
	|	TRUE,
	|	FALSE,
	|	FALSE
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.ProducedInProcess
	|	AND Table.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials)
	|	AND Table.SourceOfSemiFinishedProduct <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref,
	|	Table.Stage,
	|	Table.BillOfMaterialsRM,
	|	Table.AlternateType,
	|	TRUE,
	|	FALSE,
	|	TRUE
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.ProducedInProcess
	|	AND Table.BillOfMaterialsRM <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref,
	|	Table.Stage,
	|	ProductsBOM.BillOfMaterials,
	|	Table.AlternateType,
	|	TRUE,
	|	FALSE,
	|	FALSE
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS Table
	|
	|		INNER JOIN InformationRegister.ProductsBOM AS ProductsBOM
	|		ON Table.Products.ProductKind = ProductsBOM.ProductKind
	|			AND ProductsBOM.Products IN (Table.Products, VALUE(Catalog.Products.EmptyRef))
	|			AND ProductsBOM.Characteristic IN (VALUE(Catalog.ItemsCharacteristics.EmptyRef), Table.Characteristic)
	|			AND ProductsBOM.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
	|			AND ProductsBOM.SideExit = FALSE
	|
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.Products <> VALUE(Catalog.Products.EmptyRef)
	|	AND Table.ProducedInProcess
	|	AND Table.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials)
	|	AND Table.SourceOfSemiFinishedProduct = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|) AS Table
	|
	|GROUP BY
	|	Table.Ref,
	|	Table.Stage,
	|	Table.BillOfMaterials,
	|	Table.Alternative
	|";
	
	If ValueIsFilled(Filter) Then
		
		If Filter.Property("BillOfMaterials") Then
			
			FilterText1 =
				""
				+ "Table.Ref In "
				+ "("
				+ Filter.BillOfMaterials
				+ ")";
				
			QueryText = StrReplace(QueryText, "Table.Ref = &BillOfMaterials", FilterText1);
			
		EndIf;
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextCalculationOfProductionDurationAccordingToSpecification()
	
	QueryText = RequestTextCalculationOfRelatedSpecifications()
						+ Common.QueryBatchSeparator();
		
	QueryText = QueryText +
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.Stage   AS Stage,
	|
	|	Table.BillOfMaterials   AS BillOfMaterials,
	|	Table.Alternative AS Alternative,
	|
	|	Table.IncomingSpecification  AS IncomingSpecification,
	|	Table.OutgoingSpecification AS OutgoingSpecification,
	|	Table.NestedSpecification AS NestedSpecification,
	|
	|	ISNULL(DurationOfSpecifications.PlannedProductionDurationDays, 0)     AS PlannedProductionDurationDays,
	|	ISNULL(DurationOfSpecifications.MaximumProductionDurationDays, 0) AS MaximumProductionDurationDays,
	|
	|	ISNULL(DurationOfSpecifications.Cached, FALSE) AS Cached
	|
	|INTO TTDurationOfSpecifications
	|FROM
	|	TTRelatedSpecifications AS Table
	|
	|		LEFT JOIN InformationRegister.StandardProductionDuration AS DurationOfSpecifications
	|		ON Table.BillOfMaterials = DurationOfSpecifications.BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////
	|
	|SELECT
	|
	|	Table.BillOfMaterials AS BillOfMaterials,
	|
	|	Table.Duration AS Duration,
	|	Table.PlannedProductionDurationDays AS PlannedProductionDurationDays,
	|	Table.MaximumProductionDurationDays AS MaximumProductionDurationDays,
	|
	|	Table.Limit_ AS Limit_,
	|	Table.ContainsNestedBOMs AS ContainsNestedBOMs,
	|
	|	Table.Cached AND
	|	 NOT TRUE IN
	|		(SELECT
	|			TRUE
	|		FROM
	|			Catalog.BillsOfMaterials AS BillsOfMaterials
	|		WHERE
	|			Table.BillOfMaterials = BillsOfMaterials.Ref
	|			AND ( BillsOfMaterials.EconomicReleaseLot <> 0
	|				OR BillsOfMaterials.MinimumReleaseLot <> 0
	|				OR BillsOfMaterials.ContainsResourcesParametrization
	|				OR BillsOfMaterials.ContainsNestedBOMs
	|				OR BillsOfMaterials.ContainsProbabilityCalculation
	|				OR BillsOfMaterials.ContainsAliquotStandardsOfWorkCenterTypes
	|				OR BillsOfMaterials.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ItemList)
	|				OR BillsOfMaterials.ProductionIssueByCustomPortions = FALSE )
	|	) AS Cached
	|
	|FROM (
	|
	|SELECT
	|	ManufacturingProcess.BillOfMaterials AS BillOfMaterials,
	|
	|	MAX(ManufacturingProcess.DaysBeforeEnd) AS Duration,
	|
	|	MAX(ManufacturingProcess.DaysBeforeEnd + CASE
	|			WHEN ISNULL(DurationOfSpecifications.IncomingSpecification AND NOT DurationOfSpecifications.Alternative, FALSE)
	|				THEN ISNULL(DurationOfSpecifications.PlannedProductionDurationDays, 0)
	|			ELSE 0
	|		END)
	|		+ CASE WHEN MAX(ISNULL(CASE
	|							WHEN DurationOfSpecifications.OutgoingSpecification AND NOT DurationOfSpecifications.Alternative
	|							THEN DurationOfSpecifications.PlannedProductionDurationDays
	|							ELSE 0
	|						END + ManufacturingProcess.DaysBeforeEnd + ManufacturingProcess.DaysFromBeginning, 0)) - MAX(ManufacturingProcess.DaysBeforeEnd) > 0
	|			THEN MAX(ISNULL(CASE
	|							WHEN DurationOfSpecifications.OutgoingSpecification AND NOT DurationOfSpecifications.Alternative
	|							THEN DurationOfSpecifications.PlannedProductionDurationDays
	|							ELSE 0
	|						END + ManufacturingProcess.DaysBeforeEnd + ManufacturingProcess.DaysFromBeginning, 0)) - MAX(ManufacturingProcess.DaysBeforeEnd)
	|		ELSE 0
	|	END
	|			AS PlannedProductionDurationDays,
	|
	|	MAX(ManufacturingProcess.DaysBeforeEndMax + CASE
	|			WHEN ISNULL(DurationOfSpecifications.IncomingSpecification, FALSE)
	|				THEN ISNULL(DurationOfSpecifications.MaximumProductionDurationDays, 0)
	|			ELSE 0
	|		END)
	|		+ CASE WHEN MAX(ISNULL(CASE
	|						WHEN DurationOfSpecifications.OutgoingSpecification
	|							THEN DurationOfSpecifications.MaximumProductionDurationDays
	|						ELSE 0
	|					END + ManufacturingProcess.DaysBeforeEndMax + ManufacturingProcess.DaysFromBeginningMax, 0)) - MAX(ManufacturingProcess.DaysBeforeEndMax) > 0
	|			THEN MAX(ISNULL(CASE
	|							WHEN DurationOfSpecifications.OutgoingSpecification
	|								THEN DurationOfSpecifications.MaximumProductionDurationDays
	|							ELSE 0
	|						END + ManufacturingProcess.DaysBeforeEndMax + ManufacturingProcess.DaysFromBeginningMax, 0)) - MAX(ManufacturingProcess.DaysBeforeEndMax)
	|		ELSE 0
	|	END
	|			AS MaximumProductionDurationDays,
	|
	|	CASE
	|		WHEN COUNT(DISTINCT ManufacturingProcess.Stage) > 1
	|			THEN 0
	|		ELSE MAX(ISNULL(CASE
	|						WHEN NOT DurationOfSpecifications.Alternative
	|							THEN DurationOfSpecifications.PlannedProductionDurationDays
	|						ELSE 0
	|					END, 0))
	|	END                                                                    AS Limit_,
	|	MAX(ISNULL(DurationOfSpecifications.NestedSpecification, FALSE)) AS ContainsNestedBOMs,
	|
	|	MIN(ISNULL(DurationOfSpecifications.Cached, TRUE)) AS Cached
	|
	|FROM
	|	InformationRegister.StandardDurationOfProductionStages AS ManufacturingProcess
	|
	|		LEFT JOIN TTDurationOfSpecifications AS DurationOfSpecifications
	|
	|			ON ManufacturingProcess.BillOfMaterials = DurationOfSpecifications.Ref
	|				AND ManufacturingProcess.Stage      = DurationOfSpecifications.Stage
	|WHERE
	|	ManufacturingProcess.BillOfMaterials = &BillOfMaterials
	|
	|GROUP BY
	|	ManufacturingProcess.BillOfMaterials
	|
	|) AS Table
	|";
	
	Return QueryText;
	
EndFunction

Function CalculateDuration(BillOfMaterials)
	
	QueryText = RequestTextCalculationOfProductionDurationAccordingToSpecification();
	
	Query = New Query(QueryText);
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Result = RegisterEntryDataStructure();
		
	Else
		
		Result = RegisterEntryDataStructure();
		Selection = QueryResult.Select();
		Selection.Next();
		FillPropertyValues(Result, Selection);
	
	EndIf;
	
	Return Result;
	
EndFunction

Function RecordCalculationResult(BillOfMaterials, CalculationResult2, CallingFromUpdateHandler = False)
	
	Set = InformationRegisters.StandardProductionDuration.CreateRecordSet();
	
	Set.Filter.BillOfMaterials.Set(BillOfMaterials);
	
	NewRecord = Set.Add();
	
	FillPropertyValues(NewRecord, CalculationResult2);
	NewRecord.BillOfMaterials = BillOfMaterials;
	
	SetPrivilegedMode(True);
	
	If CallingFromUpdateHandler Then
		InfobaseUpdate.WriteData(Set);
	Else
		Set.Write(True);
	EndIf;
	
EndFunction

Procedure PerformControlOfCalculationLoop(ObjectOfARAP, DependentObjects, AdditionalData)
	
	If Not ValueIsFilled(DependentObjects) Then
		Return;
	EndIf;
	
	Count_ = Undefined;
	If Not AdditionalData.Property("LoopControlGraph", Count_) Then
		Count_ = ProductionManagement.Count_();
	EndIf;
	
	CalculationIsLooped = False;
	ErrorList   = New Array(2);
	
	VertexCalculationObject = ProductionManagement.GetVertexOfGraphFromLink(Count_, ObjectOfARAP);
	For Each DependentObject In DependentObjects Do
		If ObjectOfARAP = DependentObject Then
			CalculationIsLooped  = True;
			ErrorList[0] = ObjectOfARAP;
		Else
			ProductionManagement.AddAdjacentVertexToAdjacencyList(VertexCalculationObject, DependentObject);
			ProductionManagement.GetVertexOfGraphFromLink(Count_, DependentObject);
		EndIf;
	EndDo;
	
	CalculationIsLooped = CalculationIsLooped Or ProductionManagement.ThereAreCyclesInGraph(Count_, ErrorList[0], ErrorList[1]);
	If CalculationIsLooped Then
		
		BeginTransaction();
		Try
			
			For Each BillOfMaterials In ErrorList Do
				
				If Not ValueIsFilled(BillOfMaterials) Then
					Continue;
				EndIf;
				
				Block = New DataLock;
				Block.Add("InformationRegister.StandardProductionDuration").SetValue("BillOfMaterials", BillOfMaterials);
				Block.Lock();
				
				RecordCalculationResult(BillOfMaterials, RegisterEntryDataStructure(), True);
				
				IndexOf = DependentObjects.Find(BillOfMaterials);
				If IndexOf <> Undefined Then
					DependentObjects.Delete(IndexOf);
				EndIf;
				
				MessageText = StrTemplate(NStr("vi = 'Không thể tính thời lượng bảng kê chi tiết các nguồn lực sản xuất %1 do tính toán lặp.';
												|ru = 'Не удалось рассчитать длительность спецификации %1 из-за зацикливания расчета.';
												|en = 'Unable to calculate length of the bill of materials %1 due to looping of calculation.'; fa = 'Unable to calculate length of the bill of materials %1 due to looping of calculation.';
												|it = 'Non è stato possibile calcolare la durata della specifica %1 a causa del loop di calcolo.';
												|pl = 'Nie udało się obliczyć długotrwałość specyfikacji %1 z powodu pętli w obliczeniu.';
												|tr = 'Hesaplama döngüsünden dolayı %1 ürün reçetesinin süresi hesaplanamadı.'"),
					BillOfMaterials);
				
				WriteLogEvent(
					ProductionServer.EventCalculationOfNormativeDuration(),
					EventLogLevel.Error,
					BillOfMaterials.Metadata(),
					BillOfMaterials,
					MessageText);
				
			EndDo;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), ObjectOfARAP);
		EndTry;
	
	EndIf;
	
	AdditionalData.Insert("LoopControlGraph", Count_);
	
EndProcedure
#EndRegion

#Region DependentCalculationObjects

Function DependentCalculationObjects(ObjectOfARAP)
	
	If TypeOf(ObjectOfARAP) = Type("CatalogRef.BillsOfMaterials") Then
		
		Return Catalogs.BillsOfMaterials.DependentSpecifications(ObjectOfARAP);
		
	ElsIf TypeOf(ObjectOfARAP) = Type("CatalogRef.Calendars") Then
		
		Query = New Query(
			"SELECT
			|	BusinessStructure.Ref AS Ref
			|INTO TTUnits
			|FROM
			|	Catalog.BusinessStructure AS BusinessStructure
			|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
			|		ON TRUE
			|WHERE
			|	BusinessStructure.WorkScheduleSetupMethod =
			|		VALUE(Enum.MethodsOfConfiguringBusinessUnitWorkSchedule.MainEnterpriseCalendar)
			|	AND MainEnterpriseCalendar.Value = &ObjectOfARAP
			|
			|UNION ALL
			|
			|SELECT
			|	BusinessStructureWorkSchedules.Ref
			|FROM
			|	Catalog.BusinessStructure.WorkSchedules AS BusinessStructureWorkSchedules
			|WHERE
			|	BusinessStructureWorkSchedules.WorkScheduleCalendar = &ObjectOfARAP
			|
			|INDEX BY
			|	Ref
			|;
			|
			|////////////////////////////////////////////////////////////
			|
			|SELECT DISTINCT
			|	Table.Owner AS BillOfMaterials
			|FROM
			|	Catalog.ProductionStages AS Table
			|WHERE
			|	Table.Owner.Status = VALUE(Enum.BOMStatuses.Valid)
			|	AND NOT Table.DeletionMark
			|	AND NOT Table.Owner.DeletionMark
			|	AND TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			TTUnits AS T
			|		WHERE
			|			T.Ref = Table.Department)");
		Query.SetParameter("ObjectOfARAP", ObjectOfARAP);
		Return Query.Execute().Unload().UnloadColumn(0);
		
	ElsIf TypeOf(ObjectOfARAP) = Type("CatalogRef.BusinessStructure") Then
		
		Query = New Query(
			"SELECT DISTINCT
			|	Table.Owner AS BillOfMaterials
			|FROM
			|	Catalog.ProductionStages AS Table
			|WHERE
			|	Table.Owner.Status = VALUE(Enum.BOMStatuses.Valid)
			|	AND NOT Table.DeletionMark
			|	AND NOT Table.Owner.DeletionMark
			|	AND Table.Department = &ObjectOfARAP");
		Query.SetParameter("ObjectOfARAP", ObjectOfARAP);
		Return Query.Execute().Unload().UnloadColumn(0);
		
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion

#Region Other

Function RegisterEntryDataStructure()
	
	Result = New Structure;
	
	Result.Insert("Duration", 0);
	
	Result.Insert("PlannedProductionDurationDays", 0);
	Result.Insert("MaximumProductionDurationDays", 0);

	Result.Insert("Limit_", -1);
	Result.Insert("ContainsNestedBOMs", False);
	
	Result.Insert("Cached", False);
	
	Result.Insert("Version", Version());
	
	Return Result;
	
EndFunction

Function Version()
	
	Return "2.0";
	
EndFunction

Function DurationsAreEqual(Duration1, Duration2)
	
	For Each Property In Duration1 Do
		
		If Duration1[Property.Key] <> Duration2[Property.Key] Then
			Return False;
		EndIf;
		
	EndDo;
	Return True;
	
EndFunction

#EndRegion

#EndRegion

#EndIf
