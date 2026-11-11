#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns the new stage number.
//
// Parameters:
//   BillOfMaterials - CatalogRef.BillsOfMaterials - specification.
//
// Returns:
//   Number        - The new stage number.
//
Function NewStageNumber(BillOfMaterials) Export

	If BillOfMaterials.IsEmpty() Then
		
		Return 1;
		
	EndIf;
	
	Query = New Query(
	"SELECT TOP 1
	|	ProductionStages.StageNumber AS StageNumber
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.Owner = &BillOfMaterials
	|	AND NOT ProductionStages.DeletionMark
	|
	|ORDER BY
	|	StageNumber DESC");
	
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	Result = Query.Execute();
	
	If Result.IsEmpty() Then
		
		Return 1;
		
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();

	Return Selection.StageNumber + 1;

EndFunction

// Returns a list of predecessors
// Stages must belong to the same specification.
//
// Parameters:
//  ReferencesArrray - Array of CatalogRef.ProductionStages - stage.
// 
// Returns:
//   - Map - the correspondence of the predecessors.
//
Function Predecessors(ReferencesArrray) Export
	
	Query = New Query("
		|SELECT
		|	ProductionStages.Ref               AS Stage,
		|	ProductionStages.StageNumber           AS StageNumber,
		|	ProductionStages.NextStageNo AS NextStageNo
		|FROM
		|	Catalog.ProductionStages AS ProductionStages
		|WHERE
		|	ProductionStages.Owner IN (
		|		SELECT TOP 1
		|			T.Owner
		|		FROM
		|			Catalog.ProductionStages AS T
		|		WHERE
		|			T.Ref IN (&ReferencesArrray)
		|	)
		|	AND NOT ProductionStages.DeletionMark");
	
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	StepsTable = Query.Execute().Unload();
	StepsTable.Indexes.Add("NextStageNo");
	
	Predecessors = New Map;
	
	For Each Ref In ReferencesArrray Do
		
		Predecessors.Insert(Ref, New Array);
		
		Filter = New Structure("Stage", Ref); 
		
		CalculationStages = StepsTable.FindRows(Filter);
		
		While CalculationStages.Count() > 0 Do
			
			CurrentRow = CalculationStages[0];
			
			Filter = New Structure("NextStageNo", CurrentRow.StageNumber);
			
			For Each FoundRow In StepsTable.FindRows(Filter) Do
				
				PredecessorsOfArray = Predecessors[Ref]; // Array
				PredecessorsOfArray.Add(FoundRow.Stage);
				
				CalculationStages.Add(FoundRow);
				
			EndDo;
			
			CalculationStages.Delete(0);
			
		EndDo;
		
	EndDo;
	
	Return Predecessors;
	
EndFunction

// Returns the main unit of measurement for the stage time.
//
// Returns:
//   EnumRef.TimeMeasureUnits - the basic unit of measurement of stage time.
//
Function BasicUnitOfTime() Export

	Return Enums.TimeMeasureUnits.Minute;

EndFunction

// Returns the basic unit of measurement for buffer time.
//
// Returns:
//   EnumRef.TimeMeasureUnits - the basic unit of buffer time measurement.
//
Function BasicBufferTimeUnit() Export

	Return Enums.TimeMeasureUnits.Day;

EndFunction

// Returns the basic unit of time for the duration of the UBBV stage.
//
// Returns:
//   EnumRef.TimeMeasureUnits - the basic unit of measurement of the time of the UBB stage.
//
Function TheBasicUnitOfTimeForTheDurationOfTheUBBWStage() Export
	
	Return Enums.TimeMeasureUnits.Day;
	
EndFunction

// Fills in the list of types of work centers based on the selected route map
//
// Parameters:
//  Data_Stage	- FormDataStructure - An object containing stage data.
//
Procedure FillInWorkCenterKindsUsingAnOperationsSheet(Data_Stage) Export

	Data_Stage.WorkCenterTypes.Clear();
	Data_Stage.AlternateWorkCenterTypes.Clear();
	Data_Stage.OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Sequentially;
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager; //temporary tables are reused
	
	QueryTextStageList = "
	|SELECT
	|	&RouteSheet AS RouteSheet
	|INTO StageList";
	
	Query.SetParameter("RouteSheet", Data_Stage.RouteSheet);
	Query.SetParameter("Department",   Data_Stage.Department);
	
	TypesOfWorkCentersForWhichYouNeedToPlanWork(
				Query, 
				QueryTextStageList, 
				Data_Stage);
	
	Query.TempTablesManager.Close();
	
	// Fill in the buffer values
	RouteMapBuffers = Common.ObjectAttributesValues(
		Data_Stage.RouteSheet, 
		"PreliminaryBuffer,FollowUpBuffer,UnitOfMeasureOfPreliminaryBuffer,UnitOfMeasureOfFollowUpBuffer");
	FillPropertyValues(Data_Stage, RouteMapBuffers);
	
	If Data_Stage.UnitOfMeasureOfPreliminaryBuffer.IsEmpty() Then
		Data_Stage.UnitOfMeasureOfPreliminaryBuffer = BasicBufferTimeUnit();
	EndIf; 
	If Data_Stage.UnitOfMeasureOfFollowUpBuffer.IsEmpty() Then
		Data_Stage.UnitOfMeasureOfFollowUpBuffer = BasicBufferTimeUnit();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Procedure TypesOfWorkCentersForWhichYouNeedToPlanWork(Query, QueryTextStageList, Data_Stage)

	IndexOfQueryResult = 0;
	QueryText = "";
	
	ListOfTypesOfWorkCenters = Data_Stage.WorkCenterTypes;
	
	If QueryTextStageList <> Undefined Then
		IndexOfQueryResult = 1;
		QueryText = QueryTextStageList 
				+ "
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|"
	EndIf; 
	QueryText = QueryText
			+ "SELECT
			|	StageList.RouteSheet AS RouteSheet,
			|	COUNT(CatOperations.OperationNumber) = COUNT(DISTINCT CatOperations.OperationNumber) AS Sequentially
			|INTO OperationsSheetList
			|FROM
			|	StageList AS StageList
			|		INNER JOIN Catalog.ManufacturingOperations AS CatOperations
			|		ON (CatOperations.Owner = StageList.RouteSheet)
			|			AND (NOT CatOperations.DeletionMark)
			|			AND (NOT CatOperations.ContainsNestedRoute)
			|			AND (CASE
			|				WHEN CatOperations.WorkCenter REFS Catalog.WorkCenterTypes
			|					THEN CAST(CatOperations.WorkCenter AS Catalog.WorkCenterTypes).UseAvailabilityAccordingToSchedule
			|				WHEN CatOperations.WorkCenter REFS Catalog.WorkCenters
			|					THEN CAST(CatOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.UseAvailabilityAccordingToSchedule
			|				ELSE FALSE
			|			END)
			|
			|GROUP BY
			|	StageList.RouteSheet
			|
			|INDEX BY
			|	RouteSheet
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			// 1. Types of work centers for which you need to plan work
			|SELECT 
			|	NestedQuery.WorkCenterType        AS WorkCenterType,
			|	NestedQuery.SetupSettings           AS SetupSettings,
			|	NestedQuery.TimePerPieceUnitOfMeasure        AS UnitOfMeasure,
			|	SUM(NestedQuery.TimePerPiece)      AS OperationTime,
			|	SUM(NestedQuery.Load)          AS Load,
			|	MIN(NestedQuery.Sequentially) AS Sequentially
			|
			|FROM
			|	(SELECT
			|		CASE
			|			WHEN CatOperations.WorkCenter REFS Catalog.WorkCenterTypes
			|				THEN CatOperations.WorkCenter
			|			ELSE CAST(CatOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType
			|		END                                             AS WorkCenterType,
			|		CatOperations.SetupSettings                        AS SetupSettings,
			|		CatOperations.Load                              AS Load,
			|		OperationsSheetList.Sequentially              AS Sequentially,
			|		&TextDetailsForCalculatingOperationExecutionTime
			|	FROM
			|		OperationsSheetList AS OperationsSheetList
			|			INNER JOIN Catalog.ManufacturingOperations AS CatOperations
			|			ON (CatOperations.Owner = OperationsSheetList.RouteSheet)
			|				AND (NOT CatOperations.ContainsNestedRoute)
			|				AND (CASE 
			|						WHEN CatOperations.WorkCenter REFS Catalog.WorkCenterTypes
			|							THEN CAST(CatOperations.WorkCenter AS Catalog.WorkCenterTypes).UseAvailabilityAccordingToSchedule
			|						WHEN CatOperations.WorkCenter REFS Catalog.WorkCenters
			|							THEN CAST(CatOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.UseAvailabilityAccordingToSchedule
			|						ELSE FALSE
			|					END)
			|	WHERE NOT CatOperations.DeletionMark
			|			AND CASE
			|				WHEN CatOperations.WorkCenter REFS Catalog.WorkCenterTypes
			|					THEN CAST(CatOperations.WorkCenter AS Catalog.WorkCenterTypes).Department
			|				ELSE CAST(CatOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.Department
			|			END = &Department) AS NestedQuery
			|
			|GROUP BY
			|	NestedQuery.WorkCenterType,
			|	NestedQuery.SetupSettings,
			|	NestedQuery.TimePerPieceUnitOfMeasure
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP StageList
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	CatOperations.NestedRoute AS RouteSheet
			|INTO StageList
			|FROM
			|	OperationsSheetList AS OperationsSheetList
			|		INNER JOIN Catalog.ManufacturingOperations AS CatOperations
			|		ON (CatOperations.Owner = OperationsSheetList.RouteSheet)
			|			AND CatOperations.ContainsNestedRoute
			| WHERE NOT CatOperations.DeletionMark
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|DROP OperationsSheetList";
	
	QueryText = StrReplace(
		QueryText,
		"&TextDetailsForCalculatingOperationExecutionTime",
		Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation("CatOperations"));
	
	Query.Text = QueryText;
	
	Result = Query.ExecuteBatch();
	// Result[1] - Types of work centers for which work needs to be planned
	
	If Result[1 + IndexOfQueryResult].IsEmpty() Then
		Return;
	EndIf; 
	
	// Fill in the output items
	Selection = Result[1 + IndexOfQueryResult].Select();
	
	While Selection.Next() Do
		TheStructureOfTheSearch = New Structure("WorkCenterType,SetupSettings", Selection.WorkCenterType, Selection.SetupSettings);
		StringsList = ListOfTypesOfWorkCenters.FindRows(TheStructureOfTheSearch);
		If StringsList.Count() = 0 Then
			RowViewRC = ListOfTypesOfWorkCenters.Add();
			RowViewRC.ConnectionKey         = New UUID;
			RowViewRC.WorkCenterType = Selection.WorkCenterType;
			RowViewRC.SetupSettings    = Selection.SetupSettings;
			RowViewRC.UnitOfMeasure  = Selection.UnitOfMeasure;
			ProductionProcessEditorClientServer.WhenEnteringNewLineOfTypesOfWorkCenters(RowViewRC, False);
		Else
			RowViewRC = StringsList[0];
		EndIf;
		
		If Data_Stage.OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Sequentially Then
			If Selection.Sequentially Then
				
				If Selection.UnitOfMeasure = RowViewRC.UnitOfMeasure Then
					OperationTime = Selection.OperationTime;
				Else
					OperationTime = ProductionPlanningClientServer.GetTimeInUnit(
																ProductionPlanningClientServer.GetTimeInSeconds(
																			Selection.OperationTime,
																			Selection.UnitOfMeasure),
																RowViewRC.UnitOfMeasure);
				EndIf;
				RowViewRC.OperationTime = RowViewRC.OperationTime + Data_Stage.RouteSheetFactor * OperationTime;
				RowViewRC.Load    = RowViewRC.Load + Data_Stage.RouteSheetFactor * Selection.Load;
				
			Else
				Data_Stage.OperatingProcedureOfWorkCenterTypes = Enums.OperatingProcedureOfWorkCenterTypes.Simultaneously;
				For Each String In ListOfTypesOfWorkCenters Do
					String.OperationTime = 0;
					String.Load    = 0;
				EndDo;
			EndIf;
		EndIf;
		
	EndDo;
	
	TypesOfWorkCentersForWhichYouNeedToPlanWork(Query, Undefined, Data_Stage);

EndProcedure

Function ListOfStagesForWhichSimultaneouslyProducedQuantityIsSpecified(BillOfMaterials) Export
	
	Query = New Query(
	"SELECT
	|	T.Ref
	|FROM
	|	Catalog.ProductionStages AS T
	|WHERE
	|	T.Owner = &Ref
	|	AND NOT T.DeletionMark
	|	AND T.PlanOperationsOfWorkCenterTypes
	|	AND T.QuantityOfProductUnitsLotsProducedSimultaneously > 0
	|	AND T.QuantityOfProductUnitsLotsProducedSimultaneously <> 1
	|");
	Query.SetParameter("Ref", BillOfMaterials);
	
	Return Query.Execute().Unload().UnloadColumn(0);
	
EndFunction

Procedure ClearPropsSimultaneouslyProducedQuantity(BillOfMaterials, ResultAddress = Undefined) Export
	
	FillValue = Metadata.Catalogs.ProductionStages.Attributes.QuantityOfProductUnitsLotsProducedSimultaneously.FillValue;
	
	StageList = ListOfStagesForWhichSimultaneouslyProducedQuantityIsSpecified(BillOfMaterials);
	
	For Each LinkToStage In StageList Do

		BeginTransaction();
		Try
	
			StageObject = LinkToStage.GetObject();
			StageObject.Lock();
			
			StageObject.QuantityOfProductUnitsLotsProducedSimultaneously = FillValue;
			
			StageObject.DataExchange.Load = True;
			StageObject.Write();
			
			CommitTransaction();
	
		Except
			
			RollbackTransaction();
			
			EventName = NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất';
							|ru = 'Ресурсная спецификация';
							|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
							|it = 'Specifica di risorse';
							|pl = 'Specyfikacja';
							|tr = 'Ürün reçetesi'", Common.DefaultLanguageCode());
			
			MessageText = NStr("vi = 'Không thể điều chỉnh các công đoạn của danh sách bảng kê chi tiết các nguồn lực sản xuất do: %Cause%';
								|ru = 'Не удалось скорректировать этапы ресурсной спецификации по причине: %Cause%';
								|en = 'Cannot correct the bill of materials stages. Reason: %Cause%'; fa = 'Cannot correct the bill of materials stages. Reason: %Cause%';
								|it = 'Non è stato possibile correggere le fasi delle specifiche delle risorse a causa di: %Cause%';
								|pl = 'Korygowanie etapów specyfikacji zasobów nie powiodło się z powodu: %Cause%';
								|tr = 'Ürün reçetesi aşamalarının düzeltilememe nedeni: %Cause%'");
			MessageText = StrReplace(MessageText, "%Cause%", DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				EventName,
				EventLogLevel.Warning,
				,
				BillOfMaterials,
				MessageText);
			
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure CheckComplianceOfSelectionByProperties(BillOfMaterials, ListOfAllAvailableProperties, ReportStageName, Cancel) Export
	
	Query = New Query(
	"SELECT
	|	Table.Ref                         AS Ref,
	|	Table.Ref.Description            AS RefPresentation,
	|	""WorkCenterTypes""                 AS TSName,
	|	Table.WorkCenterType.Description AS WorkCenterTypePresentation
	|FROM
	|	Catalog.ProductionStages.WorkCenterTypes AS Table
	|		INNER JOIN Catalog.ProductionStages.SelectionByProperties AS SelectionByProperties
	|		ON Table.Ref = SelectionByProperties.Ref
	|			AND Table.ConnectionKey = SelectionByProperties.ConnectionKey
	|			AND NOT (SelectionByProperties.Property IN (&ListOfAllAvailableProperties))
	|WHERE
	|	Table.Ref.Owner = &BillOfMaterials
	|	AND NOT Table.Ref.DeletionMark
	|
	|UNION
	|
	|SELECT
	|	Table.Ref,
	|	Table.Ref.Description,
	|	""AlternateWorkCenterTypes"",
	|	Table.WorkCenterType.Description
	|FROM
	|	Catalog.ProductionStages.AlternateWorkCenterTypes AS Table
	|		INNER JOIN Catalog.ProductionStages.SelectionByProperties AS SelectionByProperties
	|		ON Table.Ref = SelectionByProperties.Ref
	|			AND Table.ConnectionKey = SelectionByProperties.ConnectionKey
	|			AND NOT (SelectionByProperties.Property IN (&ListOfAllAvailableProperties))
	|WHERE
	|	Table.Ref.Owner = &BillOfMaterials
	|	AND NOT Table.Ref.DeletionMark");
	
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	Query.SetParameter("ListOfAllAvailableProperties", ListOfAllAvailableProperties);
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do
			
			If ReportStageName Then
				
				MessageTemplate = NStr("vi = 'Thuộc tính không chính xác được chỉ định trong cài đặt sử dụng, xem dạng trung tâm công việc ""%1"" (%2).';
										|ru = 'В настройках использования указаны неверные свойства, см. вид рабочего центра ""%1"" (%2).';
										|en = 'Invalid properties are specified in usage settings, see work center type ""%1"" (%2).'; fa = 'Invalid properties are specified in usage settings, see work center type ""%1"" (%2).';
										|it = 'Proprietà non valide sono specificate nelle impostazioni di utilizzo, vedere il tipo del centro di lavoro ""%1"" (%2).';
										|pl = 'W ustawieniach używania są wskazane nieprawidłowe właściwości, patrz rodzaj centrum wykonania pracy ""%1"" (%2).';
										|tr = 'Kullanım ayarlarında yanlış özellikler belirtildi, bk. ""%1"" (%2) iş merkezi türü.'");
				MessageText = StrTemplate(MessageTemplate, Selection.WorkCenterTypePresentation, Selection.RefPresentation);
				
			Else
				
				MessageTemplate = NStr("vi = 'Thuộc tính không chính xác được chỉ định trong cài đặt sử dụng, xem dạng trung tâm công việc ""%1"".';
										|ru = 'В настройках использования указаны неверные свойства, см. вид рабочего центра ""%1"".';
										|en = 'Invalid properties are specified in usage settings, see work center type ""%1"".'; fa = 'Invalid properties are specified in usage settings, see work center type ""%1"".';
										|it = 'Proprietà non valide sono specificate nelle impostazioni di utilizzo, vedere il tipo del centro di lavoro ""%1"".';
										|pl = 'W ustawieniach użycia są wskazane nieprawidłowe właściwości, patrz rodzaj centrum w3ykonania pracy ""%1"".';
										|tr = 'Kullanım ayarlarında yanlış özellikler belirtildi, bk. ""%1"" iş merkezi türü.'");
				MessageText = StrTemplate(MessageTemplate, Selection.WorkCenterTypePresentation);
				
			EndIf;
			
			CommonClientServer.MessageToUser(
				MessageText,
				Selection.Ref,
				"WorkCenterTypes",
				, 
				Cancel);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckQuantityCalculationAlgorithm(BillOfMaterials, DescriptionOfSources, ReportStageName, Cancel) Export
	
	Query = New Query(
	"SELECT
	|	Table.Ref                         AS Ref,
	|	Table.Ref.Description            AS RefPresentation,
	|	""WorkCenterTypes""                 AS TSName,
	|	Table.WorkCenterType.Description AS WorkCenterTypePresentation,
	|	Table.LineNumber                    AS LineNumber,
	|	Table.QuantityCalculationAlgorithm      AS QuantityCalculationAlgorithm
	|FROM
	|	Catalog.ProductionStages.WorkCenterTypes AS Table
	|WHERE
	|	Table.Ref.Owner = &BillOfMaterials
	|	AND CAST(Table.QuantityCalculationAlgorithm AS STRING(100)) <> """"
	|	AND NOT Table.Ref.DeletionMark
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref,
	|	Table.Ref.Description,
	|	""AlternateWorkCenterTypes"",
	|	Table.WorkCenterType.Description,
	|	Table.LineNumber,
	|	Table.QuantityCalculationAlgorithm
	|FROM
	|	Catalog.ProductionStages.AlternateWorkCenterTypes AS Table
	|WHERE
	|	Table.Ref.Owner = &BillOfMaterials
	|	AND CAST(Table.QuantityCalculationAlgorithm AS STRING(100)) <> """"
	|	AND NOT Table.Ref.DeletionMark
	|");
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return;
	EndIf;
	
	LinesToCheck = QueryResult.Unload();
	LinesToCheck.Indexes.Add("Ref,TSName");
	
	CheckAlgorithmForCalculatingOperatingTimeOfVRC(LinesToCheck, DescriptionOfSources, ReportStageName, Cancel);
	
EndProcedure

Procedure CheckAlgorithmForCalculatingOperatingTimeOfVRC(LinesToCheck, DescriptionOfSources, ReportStageName, Cancel) Export 
	
	Content = New Array;
	Content.Add(New Structure("TSName,Presentation", "WorkCenterTypes"));
	Content.Add(New Structure("TSName,Presentation", "AlternateWorkCenterTypes"));
	CheckParameters = New Structure("Content,OutputMessages,ClearNotFound", Content, False, False);
	
	StageList = TMCommonUse.UnloadColumnValues(LinesToCheck, "Ref");
	
	For Each Ref In StageList Do
		
		VerificationObject = New Structure;
		
		Table = LinesToCheck.Copy(New Structure("Ref,TSName", Ref, "WorkCenterTypes"));
		VerificationObject.Insert("WorkCenterTypes", Table);
		
		Table = LinesToCheck.Copy(New Structure("Ref,TSName", Ref, "AlternateWorkCenterTypes"));
		VerificationObject.Insert("AlternateWorkCenterTypes", Table);
		
		CheckResult = ProductDataManagement.CheckClearQuantityCalculationAlgorithm(VerificationObject, DescriptionOfSources, CheckParameters, Cancel);
		
		For Each Item In Content Do
			
			For Each LineNumber In CheckResult[Item.TSName] Do
				
				CheckTable = VerificationObject[Item.TSName]; // See DescriptionOfTypesOfWorkCentersConstructor
				CheckString = CheckTable.Find(LineNumber, "LineNumber");
				
				If ReportStageName Then
					Template = NStr("vi = 'Thuật toán tính số lượng có chứa các toán hạng không hợp lệ, xem dạng nguồn lực sản xuất ""%1"" (%2)';
									|ru = 'Алгоритм расчета количества содержит недоступные операнды, см. вид рабочего центра ""%1"" (%2)';
									|en = 'Quantity calculation algorithm contains unavailable operands. See the ""%1"" work center type (%2)'; fa = 'Quantity calculation algorithm contains unavailable operands. See the ""%1"" work center type (%2)';
									|it = 'L''algoritmo per il calcolo della quantità contiene operandi inaccessibili, vedere il tipo di centro di lavoro ""%1"" (%2)';
									|pl = 'Algorytm rozliczania ilości zawiera niedopuszczalne operandy, zob. rodzaj centrum wykonania pracy ""%1"" (%2)';
									|tr = 'Miktar hesaplama algoritması mevcut olmayan işlenenleri içermektedir, bk. ""%1"" (%2) iş merkezi türü'");
					MessageText = StrTemplate(Template, CheckString.WorkCenterTypePresentation, CheckString.RefPresentation);
				Else
					Template = NStr("vi = 'Thuật toán tính số lượng có chứa các toán hạng không hợp lệ, xem dạng nguồn lực sản xuất ""%1""';
									|ru = 'Алгоритм расчета количества содержит недоступные операнды, см. вид рабочего центра ""%1""';
									|en = 'Quantity calculation algorithm contains unavailable operands, see the ""%1"" work center type'; fa = 'Quantity calculation algorithm contains unavailable operands, see the ""%1"" work center type';
									|it = 'L''algoritmo per il calcolo della quantità contiene operandi inaccessibili, vedere il tipo di centro di lavoro ""%1""';
									|pl = 'Algorytm rozliczania ilości zawiera niedopuszczalne operandy, zob. rodzaj centrum wykonania pracy ""%1""';
									|tr = 'Miktar hesaplama algoritması mevcut olmayan işlenenleri içermektedir, bk. ""%1"" iş merkezi türü'");
					MessageText = StrTemplate(Template, CheckString.WorkCenterTypePresentation);
				EndIf;
				
				CommonClientServer.MessageToUser(
					MessageText,
					Ref,
					,
					,
					Cancel);
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Constructor of the table describing types of work centers
// 
// Returns:
// 	ValueTable - Description Table:
// 		 * Ref - CatalogRef.ProductionStages - link to the stage
// 		 * RefPresentation - String - stage presentation
// 		 * Description - String - name of the work center
// 		 * LineNumber - Number - the line number table
// 		 * QuantityCalculationAlgorithm - String - calculation algorithm
//
Function DescriptionOfTypesOfWorkCentersConstructor() Export
	
	Result = New ValueTable;
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf
