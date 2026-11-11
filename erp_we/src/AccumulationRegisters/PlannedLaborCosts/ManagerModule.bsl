#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// The function returns the Query Text of the formation of a temporary Pricing table, with up-to-date labor costs,
//		for each date of generated labor costs.
// Parameters:
//	RequestForOnePlannedCalculation - Boolean - The defining attribute is that the Query Text is needed for one planned calculation or for many.
//
// Returns:
//	String - the generated Query Text based on current labor costs.
//
Function QueryTextOfLaborCostsPricing(RequestForOnePlannedCalculation) Export

	ArrayOfRequestTexts = New Array();
	QueryText = "SELECT DISTINCT
		|	PlannedLaborCosts.WorkKind AS WorkKind,
		|	PlannedLaborCosts.WorkKind.JobTitle AS JobTitle,
		|	PlannedLaborCosts.WorkKind.RateAccordingToPayScale AS RateAccordingToPayScale,
		|	PlannedLaborCosts.WorkKind.LaborGrade AS LaborGrade,
		|	PlannedLaborCosts.WorkKind.LaborInput AS LaborInput,
		|	PlannedLaborCosts.WorkKind.LaborInputMultiplier AS LaborInputMultiplier,
		|	PlannedLaborCosts.WorkKind.RatePerHourWorked AS RatePerHourWorked,
		|	PlannedLaborCosts.Department AS Department,
		|	PlannedLaborCosts.StandardCostEstimate AS StandardCostEstimate,
		|	PlannedLaborCosts.StandardCostEstimate.Organization AS Organization,
		|	PlannedLaborCosts.Period AS Period
		|INTO ActivityKinds
		|FROM
		|	AccumulationRegister.PlannedLaborCosts AS PlannedLaborCosts";
		
	If RequestForOnePlannedCalculation Then
		QueryText = QueryText + "
		|WHERE PlannedLaborCosts.StandardCostEstimate = &StandardCostEstimate";
	Else
		QueryText = QueryText + "
		|WHERE PlannedLaborCosts.StandardCostEstimate IN (&ArrayOfPlannedCalculations)";
	EndIf;
	
	ArrayOfRequestTexts.Add(QueryText);
	

	QueryText = "SELECT
				|	ActivityKinds.StandardCostEstimate AS StandardCostEstimate,
				|	ActivityKinds.Department AS Department,
				|	ActivityKinds.Organization AS Organization,
				|	ActivityKinds.WorkKind AS WorkKind,
				|	EmployeeActivityRates.LaborGrade AS LaborGrade,
				|	ActivityKinds.Period AS Period,
				|	MAX(ActivityKinds.LaborInput) AS LaborInput,
				|	MAX(ActivityKinds.LaborInputMultiplier) AS LaborInputMultiplier,
				|	MAX(EmployeeActivityRates.Period) AS PricingPeriod,
				|	MAX(ActivityKinds.RatePerHourWorked) AS RatePerHourWorked
				|INTO PricingDates
				|FROM
				|	ActivityKinds AS ActivityKinds
				|		LEFT JOIN InformationRegister.EmployeeActivityRates AS EmployeeActivityRates
				|		ON EmployeeActivityRates.WorkKind = ActivityKinds.WorkKind
				|			AND NOT ActivityKinds.RateAccordingToPayScale
				|			AND EmployeeActivityRates.Period <= ActivityKinds.Period
				|			AND (NOT &UseLaborGradesOfEmployeeActivityRates
				|				OR EmployeeActivityRates.LaborGrade = ActivityKinds.LaborGrade)
				|
				|GROUP BY
				|	ActivityKinds.StandardCostEstimate,
				|	ActivityKinds.WorkKind,
				|	EmployeeActivityRates.LaborGrade,
				|	ActivityKinds.Period,
				|	ActivityKinds.Department,
				|	ActivityKinds.Organization
				|"; //@Query-part
	ArrayOfRequestTexts.Add(QueryText);

	QueryText = "SELECT
				|	PricingDates.StandardCostEstimate AS StandardCostEstimate,
				|	PricingDates.Department AS Department,
				|	PricingDates.Organization AS Organization,
				|	PricingDates.WorkKind AS WorkKind,
				|	PricingDates.Period AS Period,
				|	MIN(EmployeeActivityRates.Rate_
				|		*
				|		CASE WHEN PricingDates.RatePerHourWorked
				|			THEN PricingDates.LaborInput / PricingDates.LaborInputMultiplier
				|			ELSE 1
				|		END) AS Rate_
				|INTO RatesPreliminary
				|FROM
				|	PricingDates AS PricingDates
				|		INNER JOIN InformationRegister.EmployeeActivityRates AS EmployeeActivityRates
				|		ON PricingDates.WorkKind = EmployeeActivityRates.WorkKind
				|			AND (NOT &UseLaborGradesOfEmployeeActivityRates
				|				OR PricingDates.LaborGrade = EmployeeActivityRates.LaborGrade)
				|			AND PricingDates.PricingPeriod = EmployeeActivityRates.Period
				|
				|WHERE &AddlCondition
				|
				|GROUP BY
				|	PricingDates.StandardCostEstimate,
				|	PricingDates.WorkKind,
				|	PricingDates.Period,
				|	PricingDates.Department,
				|	PricingDates.Organization
				|
				|HAVING
				|	MIN(EmployeeActivityRates.Rate_) <> 0
				|"; //@Query-part
	
	AddlCondition = "TRUE"; //@Query-part
	
	
	QueryText = StrReplace(QueryText, "&AddlCondition", AddlCondition); //@Query-part
	ArrayOfRequestTexts.Add(QueryText);
	
	QueryText = "
		|SELECT
		|	DD.StandardCostEstimate AS StandardCostEstimate,
		|	DD.WorkKind AS WorkKind,
		|	DD.Period AS Period,
		|	DD.Department AS Department,
		|	DD.Organization AS Organization,
		|	MIN(DD.Rate_) AS Rate_
		|INTO Rates
		|FROM RatesPreliminary AS DD
		|GROUP BY
		|	DD.StandardCostEstimate,
		|	DD.WorkKind,
		|	DD.Period,
		|	DD.Department,
		|	DD.Organization
		|INDEX BY
		|	Department,
		|	WorkKind,
		|	Period"; 

	ArrayOfRequestTexts.Add(QueryText);
	ArrayOfRequestTexts.Add("DROP PricingDates"); //@Query-part
	ArrayOfRequestTexts.Add("DROP RatesPreliminary"); //@Query-part
	
	
	Return StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
	
EndFunction

// The function returns the Query Text of the formation of a temporary table in the Labor costcompensation of the latest,
//		with current labor cost rates, is formed through a slice of the latest, for one required date.
//
// Returns:
//	String - the generated Query Text based on current labor costs.
//
Function QueryTextTTRatesOfLaborCostsCrossSectionOfLatter() Export
	
	ArrayOfRequestTexts = New Array();
	
	QueryTextTTFilters = "
		|SELECT DISTINCT
		|	ActivityKinds.Ref AS WorkKind,
		|	ActivityKinds.JobTitle AS JobTitle,
		|	ActivityKinds.RateAccordingToPayScale AS RateAccordingToPayScale,
		|	ActivityKinds.LaborGrade AS LaborGrade,
		|	ActivityKinds.LaborInput AS LaborInput,
		|	ActivityKinds.LaborInputMultiplier AS LaborInputMultiplier,
		|	ActivityKinds.RatePerHourWorked AS RatePerHourWorked,
		|	DD.Stage AS Stage,
		|	CASE WHEN ISNULL(Companies.Ref, VALUE(Catalog.Companies.EmptyRef)) = VALUE(Catalog.Companies.EmptyRef)
		|		THEN &Organization
		|		ELSE Companies.Ref
		|	END AS Organization,
		|	DD.StageSubdivision AS Department
		|
		|INTO TTSelections
		|	FROM TTBillOfMaterialsLaborCosts AS DD
		|		LEFT JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
		|			ON DD.WorkKind = ActivityKinds.Ref
		|
		|		LEFT JOIN Catalog.ProductionStages AS ProductionStages
		|			ON DD.Stage = ProductionStages.Ref
		|		
		|		LEFT JOIN Catalog.Companies AS Companies
		|			ON ProductionStages.Partner = Companies.Ref
		|
		|
		|INDEX BY SETS
		|(
		|	(
		|		LaborGrade,
		|		Organization,
		|		Department
		|	)
		|	,
		|	(WorkKind)
		|)
		|"; //@Query-part
		
	AddlCondition = "TRUE"; //@Query-part
	
	
	QueryTextTTFilters = StrReplace(QueryTextTTFilters, "&AddlCondition", AddlCondition); //@Query-part
	ArrayOfRequestTexts.Add(QueryTextTTFilters);
	
	
	QueryText = "
		|
		|
		|SELECT
		|	TTSelections.Stage AS Stage,
		|	TTSelections.Organization AS Organization,
		|	EmployeeActivityRatesSliceLast.WorkKind AS WorkKind,
		|	TTSelections.Department AS Department,
		|	EmployeeActivityRatesSliceLast.Rate_
		|		* CASE WHEN TTSelections.RatePerHourWorked
		|			THEN TTSelections.LaborInput / TTSelections.LaborInputMultiplier
		|			ELSE 1	END
		|	AS Rate_
		|INTO TTLaborCostsPreliminary
		|FROM
		|	InformationRegister.EmployeeActivityRates.SliceLast(
		|		&Period,
		|		CASE WHEN &UseLaborGradesOfEmployeeActivityRates
		|			THEN (WorkKind, LaborGrade) IN (SELECT T.WorkKind, T.LaborGrade
		|														FROM TTSelections AS T
		|														WHERE NOT T.RateAccordingToPayScale)
		|			ELSE WorkKind IN (SELECT T.WorkKind
		|								FROM TTSelections AS T
		|								WHERE NOT T.RateAccordingToPayScale)
		|		END
		|		AND &AddlCondition
		|
		|	) AS EmployeeActivityRatesSliceLast
		|
		|	INNER JOIN TTSelections AS TTSelections
		|	ON EmployeeActivityRatesSliceLast.WorkKind = TTSelections.WorkKind
		|";
		
	AddlCondition = "";
	QueryText = StrReplace(QueryText, "AND &AddlCondition", AddlCondition); //@Query-part
	
	
	ArrayOfRequestTexts.Add(QueryText);
	
	QueryText = "
		|SELECT
		|	DD.Stage AS Stage,
		|	DD.Organization AS Organization,
		|	DD.WorkKind AS WorkKind,
		|	DD.Department AS Department,
		|	MIN(DD.Rate_) AS Rate_
		|INTO TTRatesOfLaborCostsCutOfLatter
		|FROM TTLaborCostsPreliminary AS DD
		|
		|GROUP BY
		|	DD.WorkKind,
		|	DD.Department,
		|	DD.Stage,
		|	DD.Organization
		|
		|INDEX BY
		|	WorkKind,
		|	Department
		|";
	
	ArrayOfRequestTexts.Add(QueryText);
	ArrayOfRequestTexts.Add("DROP TTSelections"); //@Query-part
	ArrayOfRequestTexts.Add("DROP TTLaborCostsPreliminary"); //@Query-part
		
	Return StrConcat(ArrayOfRequestTexts, Common.QueryBatchSeparator());
EndFunction

#EndRegion

#Region Private

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.PlannedLaborCosts.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.24";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("1be4bc37-f30b-4610-9ef9-8085cdf5bbe4");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.PlannedLaborCosts.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Chuyển đổi kiểu cột ""Khóa lô hàng"" trong biểu ghi tích lũy ""Chi phí lao động dự tính"".';
							|ru = 'Конвертация типа колонки ""Ключ партия"" регистра накопления ""Плановые трудозатраты"".';
							|en = 'Conversion of the ""Key lot"" column type of the ""Planned labor costs"" accumulation register.'; fa = 'Conversion of the ""Key lot"" column type of the ""Planned labor costs"" accumulation register.';
							|it = 'Conversion of the ""Key lot"" column type of the ""Planned labor costs"" accumulation register.';
							|pl = 'Conversion of the ""Key lot"" column type of the ""Planned labor costs"" accumulation register.';
							|tr = '""Planlanan İş Gücü Maliyetleri"" birikim kayıt tablosunun ""Anahtar Lot"" sütun tipinin dönüştürülmesi.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.AccumulationRegisters.PlannedLaborCosts.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.AccumulationRegisters.PlannedLaborCosts.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.AccumulationRegisters.PlannedLaborCosts.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();

	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "AccumulationRegisters.PlannedLaborCosts.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "After";
	
EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.PlannedLaborCosts";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	QueryText = "SELECT DISTINCT
	|	DD.Recorder AS Recorder
	|FROM
	|	AccumulationRegister.PlannedLaborCosts AS DD
	|
	|WHERE
	// It makes sense to convert column values only for those documents that have the Keyparty value filled in at least one line.
	|	DD.DeleteKeyLot IS NOT NULL
	|	AND DD.DeleteKeyLot <> &EmptyUID";
	
	Query = New Query(QueryText);
	Query.SetParameter("EmptyUID", CommonClientServer.BlankUUID());
	
	Recorders = Query.Execute().Unload().UnloadColumn("Recorder");
	InfobaseUpdate.MarkRecordersForProcessing(
		Parameters,
		Recorders,
		FullRegisterName);
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - parameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.PlannedLaborCosts";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	For Each Selection In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			DataLock = New DataLock;
			
			LockItem = DataLock.Add("AccumulationRegister.PlannedLaborCosts.RecordSet");
			LockItem.SetValue("Recorder", Selection.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			DataLock.Lock();
			
			RecordSet = AccumulationRegisters.PlannedLaborCosts.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(Selection.Recorder);
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				Record.KeyLot = String(Record.DeleteKeyLot);
			EndDo;
			
			InfobaseUpdate.WriteRecordSet(RecordSet);
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			MessageText = StrTemplate(
					NStr("vi = 'Không thể ghi dữ liệu vào biểu ghi tích lũy ""Chi phí nguyên vật liệu dự tính"" theo bảng giá thành dự tính ""%1"", do nguyên nhân: %2';
						|ru = 'Не удалось записать данные в регистр накопления ""Плановые трудозатраты"" по плановой калькуляции ""%1"", по причине: %2';
						|en = 'Cannot write data to the ""Planned labor costs"" accumulation register based on the ""%1"" product standard cost. Reason: %2'; fa = 'Cannot write data to the ""Planned labor costs"" accumulation register based on the ""%1"" product standard cost. Reason: %2';
						|it = 'Cannot write data to the ""Planned labor costs"" accumulation register based on the ""%1"" product standard cost. Reason: %2';
						|pl = 'Cannot write data to the ""Planned labor costs"" accumulation register based on the ""%1"" product standard cost. Reason: %2';
						|tr = '""%1"" standart ürün maliyeti için ""Planlanan İş Gücü Maliyetleri"" birikim kayıt tablosuna şu nedenden dolayı veri yazılamadı: %2'"),
					Selection.Recorder,
					ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
			WriteLogEvent(
				InfobaseUpdate.EventLogEvent(),
				EventLogLevel.Warning,
				Metadata.AccumulationRegisters.PlannedLaborCosts,,
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