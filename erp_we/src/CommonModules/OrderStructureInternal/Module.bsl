
#Region Internal

#Region ReplacingSpecifications

// Performs replacement of specifications in the structure of production orders
//
// Parameters:
//  Substitutions_3 - ValueTable - contains the structure of the replacement parameters:
//  	* ProductionOrder	 - DocumentRef.ProductionOrder2_2		 - production order
//  	* Products			 - CatalogRef.Products				 - Nomenclature.
//  	* Characteristic		 - CatalogRef.ItemsCharacteristics	 - Characteristics of the item.
//  	* Warehouse					 - CatalogRef.Warehouses						 - warehouse.
//  	* Purpose			 - CatalogRef.Assignments					 - purpose.
//  	* BillOfMaterials			 - CatalogRef.BillsOfMaterials		 - new specification.
//  MonitorValues - Boolean - a sign that it is necessary to check the correctness of the values being set.
// Returns:
//   Number - the number of replacements performed.
//
Function ReplaceSpecifications(Substitutions_3, MonitorValues = False) Export
	
	ReplacementsPerformed = 0;
	
	For Each Replacement In Substitutions_3 Do
		
		If MonitorValues And OrderStructureInternal.ReplacementOfSpecificationInOrderStructureIsAllowed(Replacement) Then
		
			Template = NStr("vi = 'Không hỗ trợ thay thế bảng kê chi tiết đối với bán thành phẩm (công việc) được sản xuất trong quy trình (%1, %2).';
							|ru = 'Не поддерживается замена спецификации для полуфабрикатов (работ) производимых в процессе (%1, %2).';
							|en = 'Replacement of the bill of materials for semi-finished products (works) manufactured throughout the process is not supported (%1, %2).'; fa = 'Replacement of the bill of materials for semi-finished products (works) manufactured throughout the process is not supported (%1, %2).';
							|it = 'Replacement of the bill of materials for semi-finished products (works) manufactured throughout the process is not supported (%1, %2).';
							|pl = 'Replacement of the bill of materials for semi-finished products (works) manufactured throughout the process is not supported (%1, %2).';
							|tr = 'Süreçte (%1, %2) üretilen yarı mamul ürünler (iş) için ürün reçetesi değişimi desteklenmemektedir.'");
			ErrorText = StrTemplate(Template, Replacement.ProductionOrder, ProductsClientServer.ProductPresentation(Replacement.Products, Replacement.Characteristic,,, Replacement.Purpose));
			Raise ErrorText;
		
		EndIf;
		
		ReplacementExecuted = InformationRegisters.CacheOfOrderStructureMasterData.ReplaceBOR(Replacement);
		
		If Not ReplacementExecuted Then
			Continue;
		EndIf;
		 
		ReplacementsPerformed = ReplacementsPerformed + 1;
		
	EndDo;
	
	Return ReplacementsPerformed;
	
EndFunction

// Checks the possibility of replacing the specification for the item.
//  - it is not allowed to replace specifications for semi-finished products produced in the process.
// 
// Parameters:
// 	RowData - Structure:
//  * ProductionOrder - DocumentRef.ProductionOrder2_2 - production order.
//  * Products - CatalogRef.Products - Nomenclature.
//  * Characteristic - CatalogRef.ItemsCharacteristics - characteristic.
//  * Warehouse - CatalogRef.Warehouses - warehouse.
//  * Purpose - CatalogRef.Assignments - purpose.
// Returns:
// 	Boolean - a sign that the specification can be replaced
Function ReplacementOfSpecificationInOrderStructureIsAllowed(RowData) Export
	
	Query = New Query();
	Query.Text = "
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|WHERE
	|	NSICache.BOMIsPredefined
	|		AND NSICache.Products        = &Products
	|		AND NSICache.Characteristic      = &Characteristic
	|		AND NSICache.Warehouse               = &Warehouse
	|		AND NSICache.Purpose          = &Purpose
	|		AND NSICache.ProductionOrder = &ProductionOrder
	|";
	Query.SetParameter("ProductionOrder", RowData.ProductionOrder);
	Query.SetParameter("Products", RowData.Products);
	Query.SetParameter("Characteristic", RowData.Characteristic);
	Query.SetParameter("Warehouse", RowData.Warehouse);
	Query.SetParameter("Purpose", RowData.Purpose);
	
	SetPrivilegedMode(True);
	
	Return Query.Execute().IsEmpty();
	
EndFunction

#EndRegion

#Region RoutineOperations

// Defines the following properties of routine tasks:
//  - dependence on functional options.
//  - the ability to run in different modes of the program.
//  - other parameters.
//
Procedure OnDefineScheduledJobSettings(Settings) Export
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.CalculateProductionOrderStructure;
	Setting.FunctionalOption = Metadata.FunctionalOptions.DynamicStructureOfProductionOrders;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.RollUpRecordOrderStructureRegister;
	Setting.FunctionalOption = Metadata.FunctionalOptions.DynamicStructureOfProductionOrders;
	
	Setting = Settings.Add();
	Setting.ScheduledJob = Metadata.ScheduledJobs.ClearLoadHistoryOfWorkCenterTypes;
	Setting.FunctionalOption = Metadata.FunctionalOptions.DynamicStructureOfProductionOrders;
	Setting.EnableOnEnableFunctionalOption = False;
	
EndProcedure

#Region StartingCalculationOfLocal

// Runs the calculation of the order structure.
Procedure StartLocalCalculation() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.CalculateProductionOrderStructure);
	
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		Return
	EndIf;
	
	CalculationParameters = OrderStructure.CalculationParameters();
	
	// The key of the background task generated by the routine task contains the "identifier" of the routine task
	//  as a result, additional verification and launch of a separate background task is required
	
	Query = New Query("
	|SELECT
	|	TRUE
	|WHERE
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.TasksOfBOMOrderStructureCalculation AS T)
	|	OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.BufferOfTasksOfBOMOrderStructureCalculation AS T)
	|	OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS T)
	|	OR TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS T)");
	
	HasJobs = Not Query.Execute().IsEmpty();
	
	If HasJobs Then
		OrderStructure.StartCalculation();
	EndIf;
	
	If StrFind(CalculationParameters.AdditionalParameters, "CalculationControl") > 0 Then
		CalculationControl();
	EndIf;
	
EndProcedure


Procedure SetLocalTaskSettingsCalculationOfOrderStructure(JobParameters)
	
	If Common.SeparatedDataUsageAvailable() Then
		
		Filter = New Structure();
		Filter.Insert("Metadata", Metadata.ScheduledJobs.CalculateProductionOrderStructure.Name);
		
		Jobs = ScheduledJobsServer.FindJobs(Filter);
		If Jobs.Count() <> 1 Then
			WriteLogEvent(
				OrderStructure.EventLogEventName(),
				EventLogLevel.Error,
				Metadata.ScheduledJobs.CalculateProductionOrderStructure,,
				NStr("vi = 'Không tìm thấy nhiệm vụ thường kỳ: Tính toán cấu trúc đơn hàng sản xuất';
					|ru = 'Не найдено регламентное задание: Расчет структуры заказов на производство';
					|en = 'A scheduled job is not found: Production order structure calculation'; fa = 'A scheduled job is not found: Production order structure calculation';
					|it = 'Non è stato trovato il compito regolamentato: Calcolo della struttura degli ordini di produzione';
					|pl = 'Nie znaleziono zadania reglamentowanego: Obliczenie struktury zleceń produkcyjnych';
					|tr = 'Programlı iş bulunamadı: Üretim emri yapısının hesaplanması'"));
			Return;
		EndIf;
		
		Job = Jobs[0];
		
		ScheduledJobsServer.ChangeJob(Job.UUID, JobParameters);
		
	EndIf;
	
EndProcedure

Function UseLocalTaskCalculationOfOrderStructure()

	Return Constants.DynamicStructureOfProductionOrders.Get();

EndFunction

Procedure SetUseOfLocalTaskRulesCalculationOfOrderStructure() Export
	
	JobParameters = New Structure;
	JobParameters.Insert("Use", UseLocalTaskCalculationOfOrderStructure());
	SetLocalTaskSettingsCalculationOfOrderStructure(JobParameters);
	
EndProcedure

Procedure SetScheduleForLocalTasksCalculationOfOrderStructure(JobSchedule) Export

	JobParameters = New Structure;
	JobParameters.Insert("Use", UseLocalTaskCalculationOfOrderStructure());
	JobParameters.Insert("Schedule", JobSchedule);
	SetLocalTaskSettingsCalculationOfOrderStructure(JobParameters);

EndProcedure

#EndRegion

#Region RegisterConvolution

// Runs the convolution of the storno-records in the data registers
// - "The structure of the order of the movement of nomeclature",
// - "Structure of the order labor costs".
// As a result, unnecessary register entries are deleted.
Procedure LocalRegisterConvolution() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.RollUpRecordOrderStructureRegister);
	
	If Not GetFunctionalOption("DynamicStructureOfProductionOrders") Then
		Return
	EndIf;
	
	RegisterConvolution();
	
EndProcedure

// Collapses the reverse entries in the data registers
// - "The structure of the order of the movement of nomeclature",
// - "Structure of the order labor costs".
Procedure RegisterConvolution() Export
	
	QueryTemplates = New Structure();
	
	Sets = New Array();
	Sets.Add(Metadata.InformationRegisters.OrderStructure.Name);
	Sets.Add(Metadata.InformationRegisters.OrderStructureLaborCosts.Name);
	
	QueryTemplate = "
	|SELECT
	|
	|	&Dimensions,
	|	&AmountOfResources
	|
	|INTO TTTotals
	|FROM
	|	RegisterName AS Table
	|
	|WHERE
	|	Table.KeySet = &KeySet
	|
	|	AND &Group
	|	AND &HAVING
	|	AND &IndexOf
	|
	|;
	|SELECT
	|
	|	&Dimensions,
	|	&Resources,
	|	&Attributes
	|
	|FROM
	|	TTTotals AS Table
	|	INNER JOIN RegisterName AS RegisterRecords
	|		ON &ConnectionCondition
	|			AND NOT RegisterRecords.AdditionalRecord
	|";
	
	For Each Set In Sets Do
		
		RegisterMetadata = OrderStructureCached.RegisterMetadataStructure(Set);
		
		QueryText = StrReplace(QueryTemplate, "RegisterName", "InformationRegister" + "." + Set);
		
		Substitutions = New Array();
		Template = "Table.%1 AS %1";
		
		For Each Field In RegisterMetadata.Dimensions Do
			Text = StrTemplate(Template, Field);
			Substitutions.Add(Text);
		EndDo;
		
		QueryText = StrReplace(QueryText, "&Dimensions", StrConcat(Substitutions, ","));
	
		Substitutions = New Array();
		Template = "Table.%1";
		
		For Each Field In RegisterMetadata.Dimensions Do
			Text = StrTemplate(Template, Field);
			Substitutions.Add(Text);
		EndDo;
		
		QueryText = StrReplace(QueryText, "AND &Group", "GROUP BY" + " " + StrConcat(Substitutions, ","));
		QueryText = StrReplace(QueryText, "AND &IndexOf", "INDEX BY" + " " + StrConcat(Substitutions, ","));
		
		Substitutions = New Array();
		Template = "SUM(Table.%1) AS %1";
		
		For Each Field In RegisterMetadata.Resources Do
			Text = StrTemplate(Template, Field);
			Substitutions.Add(Text);
		EndDo;
		
		QueryText = StrReplace(QueryText, "&AmountOfResources", StrConcat(Substitutions, ","));
		
		Substitutions = New Array();
		Template = "SUM(Table.%1) <> 0";
		
		For Each Field In RegisterMetadata.Resources Do
			Text = StrTemplate(Template, Field);
			Substitutions.Add(Text);
		EndDo;
		
		QueryText = StrReplace(QueryText, "AND &HAVING", "HAVING" + " " + StrConcat(Substitutions, " OR "));
		
		Substitutions = New Array();
		Template = "Table.%1 AS %1";
		
		For Each Field In RegisterMetadata.Resources Do
			Text = StrTemplate(Template, Field);
			Substitutions.Add(Text);
		EndDo;
		
		QueryText = StrReplace(QueryText, "&Resources", StrConcat(Substitutions, ","));
		
		Substitutions = New Array();
		Template = "RegisterRecords.%1 AS %1";
		
		For Each Field In RegisterMetadata.Attributes Do
			Text = StrTemplate(Template, Field);
			Substitutions.Add(Text);
		EndDo;
		
		QueryText = StrReplace(QueryText, "&Attributes", StrConcat(Substitutions, ","));
	
		Substitutions = New Array();
		Template = "Table.%1 = RegisterRecords.%1";
		
		For Each Field In RegisterMetadata.Dimensions Do
			Text = StrTemplate(Template, Field);
			Substitutions.Add(Text);
		EndDo;
		QueryText = StrReplace(QueryText, "&ConnectionCondition", StrConcat(Substitutions, " And "));
		
		QueryTemplates.Insert(Set, New Query(QueryText));
		
	EndDo;
	
	SetsProcessedEarlier = New Map;
	
	Query = New Query(
	"SELECT
	|
	|	Jobs.Separator         AS Separator,
	|	Jobs.SetID AS SetID,
	|
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructure AS DD
	|		WHERE
	|			DD.KeySet = Jobs.SetID
	|			AND DD.AdditionalRecord) AS ThereAreReverseProductRegisteredRecords,
	|
	|	TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureLaborCosts AS DD
	|		WHERE
	|			DD.KeySet = Jobs.SetID
	|			AND DD.AdditionalRecord) AS ThereAreAlsoLaborCosts
	|
	|FROM
	|	InformationRegister.TasksOfRecordStornoRollupInProductionSchedule AS Jobs
	|WHERE
	|	Jobs.Separator IN
	|		(SELECT DISTINCT TOP 100
	|			PortionOfCalculation.Separator
	|		FROM
	|			InformationRegister.TasksOfRecordStornoRollupInProductionSchedule AS PortionOfCalculation)
	|
	|ORDER BY
	|	Separator");
	
	Result = Query.Execute();
	
	While Not Result.IsEmpty() Do
		
		Selection = Result.Select();
		
		ThereAreRecordsInSelection = Selection.Next();
		
		While ThereAreRecordsInSelection Do
			
			CurSeparator = Selection.Separator;
			
			While ThereAreRecordsInSelection And CurSeparator = Selection.Separator Do
				
				NeedToCollapse = SetsProcessedEarlier.Get(Selection.SetID) = Undefined;
				
				If NeedToCollapse Then
				
					If Selection.ThereAreReverseProductRegisteredRecords Then
						CollapseRegisterInAttempt(Selection.SetID, QueryTemplates, Metadata.InformationRegisters.OrderStructure.Name);
					EndIf;
					
					If Selection.ThereAreAlsoLaborCosts Then
						CollapseRegisterInAttempt(Selection.SetID, QueryTemplates, Metadata.InformationRegisters.OrderStructureLaborCosts.Name);
					EndIf;
					
					SetsProcessedEarlier.Insert(Selection.SetID, True);
					
				EndIf;
				
				ThereAreRecordsInSelection = Selection.Next();
				
			EndDo;
			
			InformationRegisters.TasksOfRecordStornoRollupInProductionSchedule.DeleteTasks(CurSeparator);
			
		EndDo;
		
		SetsProcessedEarlier.Clear();
		
		Result = Query.Execute();
		
	EndDo;
	
EndProcedure

Procedure CollapseRegisterInAttempt(KeySet, QueryTemplates, RegisterName)
	
	Template = QueryTemplates[RegisterName];
	Template.SetParameter("KeySet", KeySet);
	
	ErrorCounter = 1;
	While True Do
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("InformationRegister" + "." + RegisterName);
			LockItem.SetValue("KeySet", KeySet);
			
			Block.Lock();
			
			RegisterRecords = Template.Execute().Unload();
			
			RecordSet = InformationRegisters[RegisterName].CreateRecordSet();
			RecordSet.Filter.KeySet.Set(KeySet);
			RecordSet.Load(RegisterRecords);
			RecordSet.Write(True);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			If ErrorCounter >= NumberOfWriteAttempts() Then
				ErrorText = DetailErrorDescription(ErrorInfo());
				Raise ErrorText;
			EndIf;
			
			ErrorCounter = ErrorCounter + 1;
			Continue;
			
		EndTry;
		
		Break;
		
	EndDo;
	
EndProcedure


Procedure SetLocalTaskSettingsRegisterConvolutionOrderStructure(JobParameters)
	
	If Common.SeparatedDataUsageAvailable() Then
		
		Filter = New Structure();
		Filter.Insert("Metadata", Metadata.ScheduledJobs.RollUpRecordOrderStructureRegister.Name);
		
		Jobs = ScheduledJobsServer.FindJobs(Filter);
		If Jobs.Count() <> 1 Then
			WriteLogEvent(
				OrderStructure.EventLogEventName(),
				EventLogLevel.Error,
				Metadata.ScheduledJobs.RollUpRecordOrderStructureRegister,,
				NStr("vi = 'Không tìm thấy nhiệm vụ thường kỳ: Đối chiếu đảo ngược các bản ghi trong biểu ghi cấu trúc đơn hàng sản xuất';
					|ru = 'Не найдено регламентное задание: Свертка сторно записей в регистрах структуры заказов на производство';
					|en = 'A scheduled job is not found: The storno record rollup in production order structure registers'; fa = 'A scheduled job is not found: The storno record rollup in production order structure registers';
					|it = 'Не найдено регламентное задание: Свертка сторно записей в регистрах структуры заказов на производство';
					|pl = 'Nie znaleziono zadania reglamentowanego: Konwolucja wpisów storno w rejestrach struktury zleceń produkcyjnych';
					|tr = 'Programlı iş bulunamadı: Üretim emri yapısı kayıtlarında ters kayıtların toplanması'"));
			Return;
		EndIf;
		
		Job = Jobs[0];
		
		ScheduledJobsServer.ChangeJob(Job.UUID, JobParameters);
		
	EndIf;
	
EndProcedure

Function UseLocalTaskRegisterConvolutionOrderStructure()

	Return Constants.DynamicStructureOfProductionOrders.Get() And OrderStructure.Service_Settings().CalculateChanges_;

EndFunction

Procedure SetUseOfLocalTaskRulesRegisterConvolutionOrderStructure() Export
	
	JobParameters = New Structure;
	JobParameters.Insert("Use", UseLocalTaskRegisterConvolutionOrderStructure());
	SetLocalTaskSettingsRegisterConvolutionOrderStructure(JobParameters);
	
EndProcedure

Procedure SetScheduleOfLocalTasksRegisterConvolutionOrderStructure(JobSchedule) Export

	JobParameters = New Structure;
	JobParameters.Insert("Use", UseLocalTaskRegisterConvolutionOrderStructure());
	JobParameters.Insert("Schedule", JobSchedule);
	SetLocalTaskSettingsRegisterConvolutionOrderStructure(JobParameters);

EndProcedure

#EndRegion

#Region ClearLoadHistoryOfWorkCenterTypes

Procedure ClearDownloadHistoryOfTypesOfWorkCentersRegulations() Export
	
	Common.OnStartExecuteScheduledJob(Metadata.ScheduledJobs.ClearLoadHistoryOfWorkCenterTypes);
	
	If Not UseLocalTaskClearingDownloadHistoryOfWorkCenterViews() Then
		Return
	EndIf;
	
	AccumulationRegisters.AvailabilityOfWorkCenterTypes.ClearDownloadHistoryOfWorkCenterViews();
	
EndProcedure

Procedure SetLocalTaskSettingsClearingLoadingHistoryOfWorkCenterViews(JobParameters)
	
	If Common.SeparatedDataUsageAvailable() Then
		
		Filter = New Structure();
		Filter.Insert("Metadata", Metadata.ScheduledJobs.ClearLoadHistoryOfWorkCenterTypes.Name);
		
		Jobs = ScheduledJobsServer.FindJobs(Filter);
		If Jobs.Count() <> 1 Then
			WriteLogEvent(
				NStr("vi = 'Mức độ khả dụng của dạng nguồn lực làm việc.Xóa lịch sử kết nhập';
					|ru = 'Доступность видов рабочих центров.Очистка истории загрузки';
					|en = 'Capacity of work center types.Clear load history'; fa = 'Capacity of work center types.Clear load history';
					|it = 'Доступность видов рабочих центров.Очистка истории загрузки';
					|pl = 'Capacity of work center types.Clear load history';
					|tr = 'İş merkezi türleri kapasitesi. İndirme geçmişinin temizlenmesi'", Common.DefaultLanguageCode()),
				EventLogLevel.Error,
				Metadata.ScheduledJobs.ClearLoadHistoryOfWorkCenterTypes,,
				NStr("vi = 'Chưa tìm thấy nhiệm vụ thường kỳ: Xóa lịch sử kết nhập dạng nguồn lực làm việc';
					|ru = 'Не найдено регламентное задание: Очистка истории загрузки видов рабочих центров';
					|en = 'The scheduled job is not found: Clear load history of work center types'; fa = 'The scheduled job is not found: Clear load history of work center types';
					|it = 'Не найдено регламентное задание: Очистка истории загрузки видов рабочих центров';
					|pl = 'The scheduled job is not found: Clear load history of work center types';
					|tr = 'Ham maddelerin alt yükleniciye transferinden sonraki tutarsızlık raporu'"));
			Return;
		EndIf;
		
		Job = Jobs[0];
		
		ScheduledJobsServer.ChangeJob(Job.UUID, JobParameters);
		
	EndIf;
	
EndProcedure

Function UseLocalTaskClearingDownloadHistoryOfWorkCenterViews()
	
	ConstantsSet = Constants.CreateSet("DynamicStructureOfProductionOrders, ProductionManagementMethod");
	ConstantsSet.Read();
	
	Return ConstantsSet.DynamicStructureOfProductionOrders And ProductionManagement.TheProductionScheduleIsUsed(ConstantsSet);

EndFunction

Procedure SetUseOfLocalTaskRulesClearingLoadingHistoryOfWorkCenterViews() Export
	
	JobParameters = New Structure;
	JobParameters.Insert("Use", UseLocalTaskClearingDownloadHistoryOfWorkCenterViews());
	SetLocalTaskSettingsClearingLoadingHistoryOfWorkCenterViews(JobParameters);
	
EndProcedure

#EndRegion

#EndRegion

#Region CalculationControl

Procedure CalculationControl() Export
	
	Query = New Query("
	|SELECT TOP 1000 DISTINCT
	|
	|	Products_1.Products   AS Products,
	|	Products_1.Characteristic AS Characteristic,
	|	Products_1.Warehouse          AS Warehouse,
	|	Products_1.Purpose     AS Purpose
	|
	|FROM
	|	InformationRegister.OrderStructure AS Products_1
	|WHERE
	|	NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS Jobs
	|		WHERE
	|			Jobs.Queue >= 0
	|			AND Jobs.Products = Products_1.Products
	|			AND Jobs.Characteristic = Products_1.Characteristic
	|			AND Jobs.Warehouse = Products_1.Warehouse
	|			AND Jobs.Purpose = Products_1.Purpose
	|
	|		UNION ALL
	|
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS TaskBuffer
	|		WHERE
	|			TaskBuffer.Queue >= 0
	|			AND TaskBuffer.Products = Products_1.Products
	|			AND TaskBuffer.Characteristic = Products_1.Characteristic
	|			AND TaskBuffer.Warehouse = Products_1.Warehouse
	|			AND TaskBuffer.Purpose = Products_1.Purpose)
	|
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.TasksOfBOMOrderStructureCalculation AS Jobs
	|		WHERE
	|			Jobs.ProductionOrder = Products_1.ProductionOrder
	|
	|		UNION ALL
	|
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.BufferOfTasksOfBOMOrderStructureCalculation AS TaskBuffer
	|		WHERE
	|			TaskBuffer.ProductionOrder = Products_1.ProductionOrder)
	|
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|		WHERE
	|			NSICache.Products = Products_1.Products
	|			AND NSICache.Characteristic = Products_1.Characteristic
	|			AND NSICache.Warehouse = Products_1.Warehouse
	|			AND NSICache.Purpose = Products_1.Purpose
	|			AND NSICache.ProductionOrder = Products_1.ProductionOrder
	|			AND NOT NSICache.ToPlan)
	|
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationProtocol AS Table
	|		WHERE
	|			Table.ProductionOrder = Products_1.ProductionOrder
	|			AND Table.ErrorType IN (
	|				VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError),
	|				VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenSelectingBOMs),
	|				VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenFillingTheBOMData))
	|
	|		UNION ALL
	|
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationProtocol AS Table
	|		WHERE
	|			Table.ErrorType IN
	|				(VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.InventoryAllocationError)))
	|
	|GROUP BY
	|	Products_1.Products,
	|	Products_1.Characteristic,
	|	Products_1.Warehouse,
	|	Products_1.Purpose,
	|	Products_1.ProductionOrder,
	|	Products_1.KeyProducts
	|
	|HAVING
	|	SUM(Products_1.ToSupply - Products_1.Replaced) <> SUM(Products_1.Scheduled)
	|									+ SUM(Products_1.AllocatedFromAvailableInventory)
	|									+ SUM(Products_1.AllocatedFromAvailableInventoryWithAssignment)
	|									+ SUM(Products_1.AllocatedInFreeProductionLots)
	|									+ SUM(Products_1.AllocatedInAssignedProductionLots)
	|");
	
	EventName = NStr("vi = 'Tính toán cấu trúc đơn hàng sản xuất. Kiểm soát tính toán';
					|ru = 'Расчет структуры заказа на производство. Контроль расчета';
					|en = 'Production order structure calculation. Calculation control'; fa = 'Production order structure calculation. Calculation control';
					|it = 'Calcolo della struttura dell''ordine di produzione. Controllo calcolo';
					|pl = 'Obliczenie struktury zlecenia produkcyjnego. Kontrola obliczenia';
					|tr = 'Üretim emri yapısının hesaplanması. Hesaplama kontrolü'", Common.DefaultLanguageCode());
	
	QueryResult = Query.Execute();
	ThereAreProblems = Not QueryResult.IsEmpty();
	
	If Not
		ThereAreProblems Then
		
		WriteLogEvent(EventName, EventLogLevel.Information,,, NStr("vi = 'Đã kiểm soát, không tìm thấy lỗi.';
																	|ru = 'Контроль выполнен, ошибок не обнаружено.';
																	|en = 'Control is completed. No errors are detected.'; fa = 'Control is completed. No errors are detected.';
																	|it = 'Controllo eseguito, non sono stati rilevati errori.';
																	|pl = 'Kontrola została wykonana, nie wykryto błędów.';
																	|tr = 'Kontrol tamamlandı, hata bulunamadı.'"));
		
	Else
		
		While ThereAreProblems Do
			
			ProblematicLines = QueryResult.Unload();
			
			InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(ProblematicLines);
			
			WriteLogEvent(EventName, EventLogLevel.Warning,,,  StrTemplate(NStr("vi = 'Đã kiểm soát và ghi nhận lỗi tìm thấy.';
																				|ru = 'Контроль выполнен, найденные ошибки зарегистрированы.';
																				|en = 'Control is completed. Detected errors are registered.'; fa = 'Control is completed. Detected errors are registered.';
																				|it = 'Controllo eseguito, sono stati trovati errori registrati.';
																				|pl = 'Kontrola została wykonana, znalezione błędy zostały zarejestrowane.';
																				|tr = 'Kontrol tamamlandı, bulunan hatalar kaydedildi.'")));
			
			QueryResult = Query.Execute();
			ThereAreProblems = Not QueryResult.IsEmpty();
			
		EndDo;
	
		OrderStructure.StartCalculation();
	
	EndIf;
	
EndProcedure

#EndRegion

#Region CompleteCalculation

Procedure PerformRecalculation(ActionParameters, ResultAddress) Export
	
	KeyOperation = "OrderStructureInternal.PerformRecalculation";
	CalculationStart = CurrentUniversalDateInMilliseconds();
	PortionSize = ActionParameters.PortionOfCalculation.Count();
	TimeMeasurement = PerformanceMonitor.StartTimeConsumingOperationMeasurement(KeyOperation);
	PerformRecalculationCalculationInsideTimeMeasurement(ActionParameters);
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(TimeMeasurement, PortionSize);
	CalculationResult2 = New Structure("Operation, PortionSize, Duration", KeyOperation, PortionSize, CurrentUniversalDateInMilliseconds() - CalculationStart);
	PutToTempStorage(CalculationResult2, ResultAddress);
	
EndProcedure

Procedure PerformRecalculationCalculationInsideTimeMeasurement(ActionParameters)
	
	SetPrivilegedMode(True);
	
	QueryTextLots = 
		"SELECT TOP 1000
		|	Lots.ProductionOrder AS ProductionOrder,
		|	Lots.KeySet           AS KeySet,
		|	Lots.KeyLot          AS KeyLot
		|
		|INTO Lots
		|FROM
		|	InformationRegister.OrderStructure AS Lots
		|WHERE
		|	Lots.ProductionOrder IN (&PortionOfCalculation)
		|
		|GROUP BY
		|	Lots.ProductionOrder,
		|	Lots.KeySet,
		|	Lots.KeyLot
		|
		|HAVING
		|	SUM(Lots.Scheduled) > 0
		|
		|ORDER BY
		|	Lots.ProductionOrder";
	
	QueryTextJobs = 
		"SELECT DISTINCT
		|	RegisterRecords.Products        AS Products,
		|	RegisterRecords.Characteristic      AS Characteristic,
		|	RegisterRecords.Warehouse               AS Warehouse,
		|	RegisterRecords.Purpose          AS Purpose,
		|	RegisterRecords.ProductionOrder AS ProductionOrder
		|FROM
		|	Lots AS Lots
		|		INNER JOIN InformationRegister.OrderStructure AS RegisterRecords
		|		ON Lots.KeySet = RegisterRecords.KeySet";
	
	QueriesTexts = New Array;
	QueriesTexts.Add(QueryTextLots);
	QueriesTexts.Add(QueryTextJobs);
	QueriesTexts.Add(
		"SELECT TOP 1
		|	TRUE
		|FROM
		|	InformationRegister.ScheduleOfProductionStages2_2 AS Schedule");
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	TempTablesManager = New TempTablesManager();
	
	Query = New Query();
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("PortionOfCalculation", ActionParameters.PortionOfCalculation);
	Query.Text = QueryText;
	QueryResult = Query.ExecuteBatchWithIntermediateData();
	
	BatchRequestResult = QueryResult[0];
	ResultOfTaskQuery = QueryResult[1];
	ThereIsSchedule = Not QueryResult[2].IsEmpty();
	
	QueriesTexts.Clear();
	QueriesTexts.Add("DROP Lots");
	QueriesTexts.Add(QueryTextLots);
	QueriesTexts.Add(QueryTextJobs);
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	While Not BatchRequestResult.IsEmpty() Do
		
		InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasksToNextQueue(ResultOfTaskQuery.Unload(), ActionParameters.Queue);
		
		If ThereIsSchedule Then
			InformationRegisters.ScheduleOfProductionStages2_2.ClearScheduleAndDownloadLotReference(TempTablesManager);
		EndIf;
		
		RemoveBatchesFromStructureBySetKeys(BatchRequestResult.Unload());
		
		QueryResult = Query.ExecuteBatchWithIntermediateData();
		BatchRequestResult = QueryResult[1];
		ResultOfTaskQuery = QueryResult[2];
		
	EndDo;
	
	Query.Text =
	"SELECT TOP 1000 DISTINCT
	|	NSICache.ProductionOrder AS ProductionOrder,
	|	NSICache.Separator         AS Separator
	|FROM
	|	InformationRegister.CacheOfOrderStructureMasterData AS NSICache
	|WHERE
	|	NSICache.ProductionOrder IN (&PortionOfCalculation)
	|
	|ORDER BY
	|	ProductionOrder";
	
	QueryResult = Query.Execute();
	
	While Not
		QueryResult.IsEmpty() Do
		
		InformationRegisters.CacheOfOrderStructureMasterData.DeleteCacheByKeys(QueryResult.Unload());
		
		QueryResult = Query.Execute();
		
	EndDo;
	
	InformationRegisters.OrderStructureCalculationProtocol.ClearProtocol(ActionParameters.PortionOfCalculation.UnloadColumn("ProductionOrder"));
	
	Query.Text =
	"SELECT TOP 1000 DISTINCT
	|
	|	Products_1.Products        AS Products,
	|	Products_1.Characteristic      AS Characteristic,
	|	Products_1.Warehouse               AS Warehouse,
	|	Products_1.Purpose          AS Purpose,
	|	Products_1.ProductionOrder AS ProductionOrder
	|
	|FROM
	|	InformationRegister.OrderStructure AS Products_1
	|WHERE
	|	Products_1.ProductionOrder IN (&PortionOfCalculation)
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS Jobs
	|		WHERE
	|			Jobs.Queue >= 0
	|			AND Jobs.Products = Products_1.Products
	|			AND Jobs.Characteristic = Products_1.Characteristic
	|			AND Jobs.Warehouse = Products_1.Warehouse
	|			AND Jobs.Purpose = Products_1.Purpose
	|
	|		UNION ALL
	|
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS TaskBuffer
	|		WHERE
	|			TaskBuffer.Queue >= 0
	|			AND TaskBuffer.Products = Products_1.Products
	|			AND TaskBuffer.Characteristic = Products_1.Characteristic
	|			AND TaskBuffer.Warehouse = Products_1.Warehouse
	|			AND TaskBuffer.Purpose = Products_1.Purpose)
	|
	|	AND NOT TRUE IN
	|		(SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationProtocol AS Table
	|		WHERE
	|			Table.ProductionOrder = Products_1.ProductionOrder
	|			AND Table.ErrorType IN (
	|				VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.ExplosionError),
	|				VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenSelectingBOMs),
	|				VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.AnErrorOccurredWhenFillingTheBOMData))
	|
	|		UNION ALL
	|
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			InformationRegister.OrderStructureCalculationProtocol AS Table
	|		WHERE
	|			Table.ErrorType IN
	|				(VALUE(Enum.ErrorsTypesOfProductionOrderStructureCalculation.InventoryAllocationError)))
	|
	|GROUP BY
	|	Products_1.Products,
	|	Products_1.Characteristic,
	|	Products_1.Warehouse,
	|	Products_1.Purpose,
	|	Products_1.ProductionOrder,
	|	Products_1.KeyProducts
	|
	|HAVING
	|	SUM(Products_1.Ordered + Products_1.ToSupply - Products_1.Replaced) > 0
	|";
	
	QueryResult = Query.Execute();
	
	While Not
		QueryResult.IsEmpty() Do
		
		InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasksToNextQueue(QueryResult.Unload(), ActionParameters.Queue);
		
		QueryResult = Query.Execute();
		
	EndDo;
	
	InformationRegisters.OrderStructureCalculationJobsProductionSchedule.AddTasks(ActionParameters.PortionOfCalculation);
	
EndProcedure

Procedure RemoveBatchesFromStructureBySetKeys(List) Export
	
	Total = List.Count();
	IndexOf = 0;
	
	ErrorCounter = 1;
	
	While Total > IndexOf Do
		
		BeginTransaction();
		Try
			
			RecordSet = InformationRegisters.OrderStructure.CreateRecordSet();
			RecordSet.Filter.KeySet.Set(List[IndexOf].KeySet);
			RecordSet.Write(True);
			
			RecordSet = InformationRegisters.OrderStructureLaborCosts.CreateRecordSet();
			RecordSet.Filter.KeySet.Set(List[IndexOf].KeySet);
			RecordSet.Write(True);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ErrorText = DetailErrorDescription(ErrorInfo());
			
			If ErrorCounter < NumberOfWriteAttempts() Then
				OrderStructure.RecordUnsuccessfulAttemptToWriteToLog(ErrorCounter, ErrorText);
				ErrorCounter = ErrorCounter + 1;
				Continue;
			EndIf;
			
			Raise ErrorText;
			
		EndTry;
		
		IndexOf = IndexOf + 1;
		ErrorCounter = 1;
		
	EndDo;

EndProcedure
	
#EndRegion

#Region FillingInDocuments

// Returns data for the formation of documents "Order for the movement of goods" Or "Movement of goods" according to the production plan.
//
// Parameters:
//  RowsIDs - Array - a list of keys indicating the items in the shipment of goods.
//  OnlyInStock - Boolean - flag, if true, then the list of items planned to be moved will be filtered by the availability of the shipment in the warehouse.
// Returns:
//  ValueTable - contains the structure of the replacement parameters:
//  	* Products			 - CatalogRef.Products				 - Nomenclature.
//  	* Characteristic		 - CatalogRef.ItemsCharacteristics	 - Characteristics of the item.
//  	* OriginWarehouse			 - CatalogRef.Warehouses						 - shipping warehouse.
//  	* WarehouseForReceipt		 - CatalogRef.Warehouses						 - receipt warehouse.
//  	* Purpose			 - CatalogRef.Assignments					 - purpose.
//  	* Count			 - Number										 - quantity per unit of storage of the goods.
//
Function TabularPartMovingProductsAccordingToNomenclaturePlan(RowsIDs, OnlyInStock = False) Export
	
	Query = New Query;
	Query.SetParameter("ProductListKeys", RowsIDs);
	Query.SetParameter("OnlyInStock", OnlyInStock);
	Query.Text =
	"SELECT
	|
	|	Plan.Products           AS Products,
	|	Plan.Characteristic         AS Characteristic,
	|	Plan.Purpose             AS Purpose,
	|	Plan.Warehouse                  AS Warehouse,
	|	Plan.ProductionOrder    AS ProductionOrder,
	|	Plan.KeyProducts       AS KeyProducts,
	|	Plan.KeyLot             AS KeyLot,
	|	SUM(Plan.Scheduled)   AS Scheduled
	|	
	|INTO Receipt
	|FROM
	|	InformationRegister.OrderStructure AS Plan
	|	
	|WHERE
	|	Plan.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Move)
	|	AND Plan.KeyProducts IN (&ProductListKeys)
	|
	|GROUP BY
	|
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Purpose,
	|	Plan.Warehouse,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts,
	|	Plan.KeyLot
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	KeyLot
	|;
	|
	|SELECT
	|
	|	Plan.Products           AS Products,
	|	Plan.Characteristic         AS Characteristic,
	|	Plan.Purpose             AS Purpose,
	|	Plan.Warehouse                  AS Warehouse,
	|	Plan.ProductionOrder    AS ProductionOrder,
	|	Plan.KeyProducts       AS KeyProducts,
	|	Plan.KeyLot             AS KeyLot,
	|	Plan.StructureAssignment    AS StructureAssignment,
	|
	|	SUM(Plan.ToSupply - Plan.Replaced) AS Required2,
	|
	|	SUM(Plan.AllocatedFromAvailableInventory)            AS AllocatedFromAvailableInventory,
	|	SUM(Plan.AllocatedFromAvailableInventoryWithAssignment) AS AllocatedFromAvailableInventoryWithAssignment
	|	
	|INTO Expense
	|FROM
	|	InformationRegister.OrderStructure AS Plan
	|	
	|WHERE
	|	
	|	(Plan.Products, Plan.Characteristic, Plan.Purpose, Plan.KeyLot) IN
	|		(SELECT
	|			Products,
	|			Characteristic,
	|			Purpose,
	|			KeyLot
	|		FROM
	|			Receipt AS DD)
	|
	|	 AND Plan.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Reserved))
	|	 AND Plan.DateOfReceipt    = DATETIME(1,1,1)
	|	 AND Plan.ReceiptOrder = UNDEFINED
	|
	|GROUP BY
	|
	|	Plan.Products,
	|	Plan.Characteristic,
	|	Plan.Purpose,
	|	Plan.Warehouse,
	|	Plan.ProductionOrder,
	|	Plan.KeyProducts,
	|	Plan.KeyLot,
	|	Plan.StructureAssignment
	|
	|INDEX BY
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	KeyLot
	|;
	|
	|SELECT
	|
	|	Receipt.Products           AS Products,
	|	Receipt.Characteristic         AS Characteristic,
	|	Expense.Purpose             AS Purpose,
	|
	|	Receipt.Warehouse AS DestinationWarehouse,
	|	Expense.Warehouse AS SourceWarehouse,
	|
	|	ISNULL(RegulatorySchedule.Begin, DATETIME(1,1,1)) AS ShipmentStart,
	|	ISNULL(RegulatorySchedule.Ending, DATETIME(1,1,1)) AS ReceiptEnd,
	|
	|	CASE
	|		WHEN &OnlyInStock
	|			THEN Expense.AllocatedFromAvailableInventory ELSE Expense.Required2
	|	END AS Count
	|
	|FROM
	|	Receipt AS Receipt
	|	
	|	INNER JOIN Expense AS Expense
	|	ON Receipt.Products   = Expense.Products
	|	 AND Receipt.Characteristic = Expense.Characteristic
	|	 AND Receipt.Purpose     = Expense.Purpose
	|	 AND Receipt.KeyLot     = Expense.KeyLot
	|
	|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS RegulatorySchedule
	|	ON Receipt.KeyLot        = RegulatorySchedule.KeyLot
	|	 AND RegulatorySchedule.Stage   = VALUE(Catalog.ProductionStages.EmptyRef)
	|
	|WHERE
	|	CASE
	|		WHEN &OnlyInStock
	|			THEN Expense.AllocatedFromAvailableInventory ELSE Expense.Required2
	|	END > 0
	|
	|UNION ALL
	|
	|SELECT
	|
	|	Receipt.Products           AS Products,
	|	Receipt.Characteristic         AS Characteristic,
	|	Expense.StructureAssignment    AS Purpose,
	|
	|	Receipt.Warehouse AS DestinationWarehouse,
	|	Expense.Warehouse AS SourceWarehouse,
	|
	|	ISNULL(RegulatorySchedule.Begin, DATETIME(1,1,1)) AS ShipmentStart,
	|	ISNULL(RegulatorySchedule.Ending, DATETIME(1,1,1)) AS ReceiptEnd,
	|
	|	Expense.AllocatedFromAvailableInventoryWithAssignment AS Count
	|
	|FROM
	|	Receipt AS Receipt
	|	
	|	INNER JOIN Expense AS Expense
	|	ON Receipt.Products   = Expense.Products
	|	 AND Receipt.Characteristic = Expense.Characteristic
	|	 AND Receipt.Purpose     = Expense.Purpose
	|	 AND Receipt.KeyLot     = Expense.KeyLot
	|
	|	LEFT JOIN InformationRegister.TargetOrderStructureSchedule AS RegulatorySchedule
	|	ON Receipt.KeyLot        = RegulatorySchedule.KeyLot
	|	 AND RegulatorySchedule.Stage   = VALUE(Catalog.ProductionStages.EmptyRef)
	|
	|WHERE
	|	&OnlyInStock AND Expense.AllocatedFromAvailableInventoryWithAssignment > 0
	|
	|";
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#Region Other

Function BlockPayment() Export
	ApplicationStartupParameter = SessionParameters.ClientParametersAtServer.Get("LaunchParameter");
	Return StrFind(ApplicationStartupParameter, "BlockCalculationOfOrderStructure") > 0;
EndFunction

// Parameters:
// 	ProductionOrder - DocumentRef.ProductionOrder2_2
// Returns:
// 	Structure - LongDesc:
// * Begin - Date
// * Ending - Date
Function BoundariesOfRegulatorySchedulePeriod(ProductionOrder) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Schedule.Begin AS Begin,
		|	Schedule.Ending AS Ending
		|FROM
		|	InformationRegister.TargetOrderStructureSchedule AS Schedule
		|WHERE
		|	Schedule.ProductionOrder = &ProductionOrder
		|	AND Schedule.KeyLot = &EmptyLinkKey
		|	AND Schedule.Stage = VALUE(Catalog.ProductionStages.EmptyRef)";
	
	Query.SetParameter("ProductionOrder", ProductionOrder);
	Query.SetParameter("EmptyLinkKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	QueryResult = Query.Execute();
	
	Selection= QueryResult.Select();
	
	Boundaries = New Structure("Begin, Ending", '00010101', '00010101');
	
	If Selection.Next() Then
		FillPropertyValues(Boundaries, Selection);
	EndIf;
	
	Return Boundaries;
	
EndFunction

// The text of the request for the formation of the temporary table "Order queue".
// 
// Parameters:
//  TemporaryTableNameSource - String - Temporary Table Name Source
//  TemporaryTableNameReceiver - String - Temporary Table Name Receiver
// 
// Returns:
//  String - Request Text Temporary Table Order Queue
Function RequestTextTemporaryTableOrderQueue(TemporaryTableNameSource, TemporaryTableNameReceiver = "Queue") Export

	QueryText =
		"SELECT TOP 1000000000
		|
		|	Table.Ref AS Ref,
		|	RECORDAUTONUMBER() AS QueueNumber
		|
		|INTO TemporaryTableNameReceiver_Preliminary
		|FROM
		|	TemporaryTableNameSource AS Table
		|
		|ORDER BY
		|	Table.Ref.Priority.AddlOrderingAttribute,
		|	Table.Ref.Department.AddlOrderingAttribute,
		|	Table.Ref.Queue,
		|	Table.Ref
		|;
		|SELECT
		|
		|	Table.Ref AS Ref,
		|	Table.QueueNumber AS QueueNumber
		|
		|INTO TemporaryTableNameReceiver
		|FROM
		|	TemporaryTableNameReceiver_Preliminary AS Table
		|
		|INDEX BY
		|	Ref
		|;
		|DROP TemporaryTableNameReceiver_Preliminary;
		|";
	QueryText = StrReplace(QueryText, "TemporaryTableNameSource", TemporaryTableNameSource);
	QueryText = StrReplace(QueryText, "TemporaryTableNameReceiver", TemporaryTableNameReceiver);
	
	Return QueryText;

EndFunction

// Calculates tasks for changing the order structure after changing the order queue.
//
// Parameters:
//  Jobs - ValueTable - the columns correspond to the measurements, resources and Attributes of the register of information
//                              "Universal queue of operational tasks", there are also service columns:
//             * Object                 - DocumentRef          - link to the production order
//             * RecordID    - UUID -
//             * RecordDate             - Date                    -
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
Procedure UpdateOrderStructureONChangingPlaceInQueue(
			Jobs,
			IdsOfUnprocessedRecords,
			AdditionalProperties = Undefined) Export	
	
	SetPrivilegedMode(True);
	
	Query = New Query();
	Query.SetParameter("ProductionOrders", Jobs.UnloadColumn("Object"));
	Query.Text =
	"SELECT DISTINCT
	|
	|	RegisterRecords.Products   AS Products,
	|	RegisterRecords.Characteristic AS Characteristic,
	|	RegisterRecords.Warehouse          AS Warehouse,
	|	RegisterRecords.Purpose     AS Purpose
	|
	|FROM
	|	InformationRegister.OrderStructure AS RegisterRecords
	|WHERE
	|	RegisterRecords.ProductionOrder IN (&ProductionOrders)
	|		AND RegisterRecords.ProductionOrder <> ISNULL(RegisterRecords.Purpose.OrderDocument, VALUE(Document.ProductionOrder2_2.EmptyRef))
	|		AND RegisterRecords.LineKind IN (
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption),
	|				VALUE(Enum.KindsOfProductionOrderStructureLines.AvailableRelease))
	|;
	|";
	
	StartCalculation = False;
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		InformationRegisters.OrderStructureCalculationTasksInventoryAllocation.AddTasks(QueryResult.Unload());
		StartCalculation = True;
		
	EndIf;
	
	If StartCalculation Then
		
		OrderStructure.StartCalculation();
		
	EndIf;

EndProcedure

Function NumberOfWriteAttempts() Export
	
	Return ?(TransactionActive(), 1, 3);

EndFunction

Function CalculationIsRunning() Export
	
	SearchKey = New Structure("Key, State", Metadata.ScheduledJobs.CalculateProductionOrderStructure.Key, BackgroundJobState.Active);
	
	SetPrivilegedMode(True);
	Jobs = BackgroundJobs.GetBackgroundJobs(SearchKey);
	SetPrivilegedMode(False);
	
	Return (Jobs.Count() > 0 And Jobs[0].State = BackgroundJobState.Active);
	
EndFunction

Procedure CheckRunOrderStructureCalculationBackgroundTask() Export
	
	If CalculationIsRunning() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TRUE
	|WHERE
	|	CASE
	|			WHEN TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.TasksOfBOMOrderStructureCalculation AS T)
	|					OR TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.BufferOfTasksOfBOMOrderStructureCalculation AS T)
	|					OR TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.OrderStructureCalculationTasksInventoryAllocation AS T)
	|					OR TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.BufferOfOrderStructureCalculationTasksInventoryAllocation AS T)
	|					OR TRUE IN
	|						(SELECT TOP 1
	|							TRUE
	|						FROM
	|							InformationRegister.OrderStructureCleanupTasks AS T)
	|				THEN TRUE
	|			ELSE FALSE
	|		END";
	
	SetPrivilegedMode(True);
	
	If Not Query.Execute().IsEmpty() Then
		OrderStructure.StartCalculation();
	EndIf;
	
	SetPrivilegedMode(False);
	
EndProcedure

Procedure PerformActionsAtEndOfCalculationCycle(CalculationBoundary) Export
	
	DeferredJobs.Run("JobsToReflectOrderState");
	
	If ProductionManagementCached.TheProductionScheduleIsUsed() Then
		Query = New Query(
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	InformationRegister.OrderStructureCalculationJobsProductionSchedule AS Jobs
			|WHERE
			|	Jobs.Queue > 0 AND Jobs.Queue <= &CalculationBoundary");
		Query.SetParameter("CalculationBoundary", CalculationBoundary);
		QueryResult = Query.Execute();
		
		If Not QueryResult.IsEmpty() Then
			OrderStructureProductionSchedule.RunCalculationOfLotReferenceSchedule(CalculationBoundary);
		EndIf;
	Else
		InformationRegisters.TargetOrderStructureSchedule.StartCalculation();
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
