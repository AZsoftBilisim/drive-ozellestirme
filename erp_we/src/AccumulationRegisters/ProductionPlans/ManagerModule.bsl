#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the query text for the dynamic list of semi-finished products, used in the "production Plan" document form"
//
// Parameters:
//  FiltersList	 - Structure	 - list of predefined dynamic list selections
// 
// Returns:
//  String - Query text
//
Function RequestTextForDynamicListOfSemiFinishedProducts(FiltersList) Export
	
	QueryText =
	"SELECT
	|	ProductionPlans.Recorder AS Recorder,
	|	ProductionPlans.LineNumber AS LineNumber,
	|
	|	ProductionPlans.ProductionPlan AS ProductionPlan,
	|	ProductionPlans.Period           AS Period,
	|	ProductionPlans.Products     AS Products,
	|	ProductionPlans.Characteristic   AS Characteristic,
	|	ProductionPlans.Purpose       AS Purpose,
	|	ProductionPlans.BillOfMaterials     AS BillOfMaterials,
	|
	|	ProductionPlans.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	ProductionPlans.DateOfOrderReleaseAndProductionIssue AS DateOfOrderReleaseAndProductionIssue,
	|
	|	ProductionPlans.Count AS Count,
	|	ProductionPlans.ToOrder AS ToOrder,
	|
	|	ProductionPlans.Products.ItemsType AS ItemsType,
	|	CASE
	|		WHEN ProductionPlans.Products.UseVariants IN (
	|												VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|												VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|												VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                          AS ItemVariantsAreUsed,
	|
	|	ProductionPlans.ManualAdjustment AS ManualAdjustment,
	|	ProductionPlans.AdjustmentDate   AS AdjustmentDate,
	|	ProductionPlans.AdjustmentAuthor  AS AdjustmentAuthor,
	|	ProductionPlans.Comment         AS Comment
	|FROM
	|	AccumulationRegister.ProductionPlans AS ProductionPlans
	|WHERE
	|	ProductionPlans.ProductionPlan = &ProductionPlan AND ProductionPlans.ToPlan
	|	AND &ThereIsSelectionForOccurrencesOfSemiFinishedProducts";
	
	If FiltersList.Property("ThereIsSelectionForOccurrencesOfSemiFinishedProducts") And FiltersList.ThereIsSelectionForOccurrencesOfSemiFinishedProducts Then
		QueryText =
		"SELECT DISTINCT
		|	ProductionPlans.Recorder AS Recorder,
		|	ProductionPlans.LineNumber AS LineNumber
		|INTO TTSelectionByOccurrencesOfSemiFinishedProduct
		|FROM
		|	AccumulationRegister.ProductionPlans AS ProductionPlans
		|		INNER JOIN AccumulationRegister.MaterialConsumptionPlans AS MaterialConsumptionPlans
		|		ON ProductionPlans.ProductionPlan = MaterialConsumptionPlans.ProductionPlan
		|		 AND ProductionPlans.Period           = MaterialConsumptionPlans.ProductionDate
		|		 AND ProductionPlans.BillOfMaterials     = MaterialConsumptionPlans.ProductBOM
		|		 AND ProductionPlans.Purpose       = MaterialConsumptionPlans.AssignmentOfProducts
		|		 AND ProductionPlans.Characteristic   = MaterialConsumptionPlans.ItemVariant
		|WHERE
		|	MaterialConsumptionPlans.ProductionPlan = &ProductionPlan
		|	AND MaterialConsumptionPlans.Period         = &ProductionIssueDateOfIntermediateProducts
		|	AND MaterialConsumptionPlans.Purpose     = &Purpose
		|	AND MaterialConsumptionPlans.Products   = &Products
		|	AND MaterialConsumptionPlans.Characteristic = &Characteristic
		|" + "
		|;
		|" + QueryText;
		QueryText = StrReplace(QueryText, "&ThereIsSelectionForOccurrencesOfSemiFinishedProducts", "
			|(ProductionPlans.Recorder, ProductionPlans.LineNumber) 
			|IN 
			|(SELECT
			|		FilterTable.Recorder AS Recorder,
			|		FilterTable.LineNumber AS LineNumber
			|	FROM
			|		TTSelectionByOccurrencesOfSemiFinishedProduct AS FilterTable
			|)");
	Else
		QueryText = StrReplace(QueryText, "&ThereIsSelectionForOccurrencesOfSemiFinishedProducts", "TRUE");
	EndIf;
	
	Return QueryText
	
EndFunction

// Calculates the number of semi-finished products, used when displaying the number of rows in the dynamic list of semi-finished products
//
// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan - link to the production plan document
// 
// Returns:
//  Number - number of rows 
//
Function CalculateNumberOfSemiFinishedProducts(ProductionPlan) Export
	
	Query = New Query(
	"SELECT
	|	COUNT(*) AS RowsCount
	|FROM
	|	AccumulationRegister.ProductionPlans AS ProductionPlans
	|WHERE
	|	ProductionPlans.ProductionPlan = &ProductionPlan
	|	AND ProductionPlans.ToPlan
	|");
	Query.SetParameter("ProductionPlan", ProductionPlan);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.RowsCount;
	
EndFunction

// Returns register data for the specified plan.
//
// Parameters:
//  Ref					 - DocumentRef.ProductionPlan - the plan whose data needs to be read.
//  GetProducts		 - Boolean - True if you want to get a plan for the production of finished products.
//  GetSemiFinishedProducts	 - Boolean - True if you want to get a plan for the production of semi-finished products.
// 
// Returns:
//  ValueTable - register data.
//
Function ReadProductionPlan(Ref, GetProducts = True, GetSemiFinishedProducts = True) Export
	
	If Not GetProducts And Not GetSemiFinishedProducts Then
		ExceptionText = NStr("vi = 'Lỗi đọc dữ liệu kế hoạch sản xuất. Các tham số không chính xác được chuyển đến thủ tục.';
							|ru = 'Ошибка чтения данных плана производства. В процедуру переданы некорректные параметры.';
							|en = 'An error occurred while reading production plan data. Invalid parameters were passed to the procedure.'; fa = 'An error occurred while reading production plan data. Invalid parameters were passed to the procedure.';
							|it = 'Errore nella lettura dei dati del piano di produzione. Nella procedura sono stati immessi parametri scorretti.';
							|pl = 'Błąd odczytu danych planu produkcji. Do procedury zostały przekazane nieprawidłowe parametry.';
							|tr = 'Üretim planı verilerinin okunmasında hata oluştu. Transfer prosedüründe yanlış parametreler girilmiş.'");
		Raise ExceptionText;
	EndIf;
	
	QueryText = 
		"SELECT
		|	ProductionPlans.*
		|FROM
		|	AccumulationRegister.ProductionPlans AS ProductionPlans
		|WHERE
		|	ProductionPlans.Recorder = &Ref
		|	AND &SemiFinishedProducts_";
		
	If GetProducts And GetSemiFinishedProducts Then
		ConditionText = "TRUE";
	ElsIf GetProducts Then
		ConditionText = "ProductionPlans.ToPlan = FALSE";
	ElsIf GetSemiFinishedProducts Then
		ConditionText = "ProductionPlans.ToPlan = TRUE";
	EndIf;
	
	QueryText = StrReplace(QueryText, "&SemiFinishedProducts_", ConditionText);
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns a list of products that consume the specified semi-finished product.
//
// Parameters:
//  ProductionPlan - DocumentRef.ProductionPlan			 - Production plan
//  DemandDate	 - Date										 - demand date (production date, semi-finished product release date)
//  Purpose		 - CatalogRef.Assignments				 - Purpose
//  Products	 - CatalogRef.Products			 - Products
//  Characteristic	 - CatalogRef.ItemsCharacteristics	 - Characteristic
// 
// Returns:
//  ValueTable - data on consumers of semi-finished products.
//
Function SemiFinishedProductsAreIncludedInProducts(ProductionPlan, DemandDate, Purpose, Products, Characteristic) Export
	
	Query = New Query(
	"SELECT DISTINCT
	|	ProductionPlans.Products AS Products,
	|	ProductionPlans.Characteristic AS Characteristic,
	|	ProductionPlans.Purpose AS Purpose,
	|	ProductionPlans.BillOfMaterials AS BillOfMaterials
	|FROM
	|	AccumulationRegister.ProductionPlans AS ProductionPlans
	|		INNER JOIN AccumulationRegister.MaterialConsumptionPlans AS MaterialConsumptionPlans
	|		ON ProductionPlans.ProductionPlan = MaterialConsumptionPlans.ProductionPlan
	|		 AND ProductionPlans.Period           = MaterialConsumptionPlans.ProductionDate
	|		 AND ProductionPlans.BillOfMaterials     = MaterialConsumptionPlans.ProductBOM
	|		 AND ProductionPlans.Purpose       = MaterialConsumptionPlans.AssignmentOfProducts
	|		 AND ProductionPlans.Characteristic   = MaterialConsumptionPlans.ItemVariant
	|WHERE
	|	MaterialConsumptionPlans.ProductionPlan = &ProductionPlan
	|	AND MaterialConsumptionPlans.Period         = &DemandDate
	|	AND MaterialConsumptionPlans.Purpose     = &Purpose
	|	AND MaterialConsumptionPlans.Products   = &Products
	|	AND MaterialConsumptionPlans.Characteristic = &Characteristic
	|	AND ( MaterialConsumptionPlans.ThisIsASemiFinishedProduct
	|		AND NOT ProductionPlans.ThisIsASemiFinishedProduct )
	|");
	Query.SetParameter("ProductionPlan", ProductionPlan);
	Query.SetParameter("DemandDate",  DemandDate);
	Query.SetParameter("Purpose",       Purpose);
	Query.SetParameter("Products",     Products);
	Query.SetParameter("Characteristic",   Characteristic);
	
	Result = Query.Execute().Unload();
	Return Result;
	
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
	|	ValueAllowed(Department)
	|	AND ValueAllowed(Scenario)
	|	AND ValueAllowed(PlanProfile)";

EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

#Region Adjusting

Procedure SaveManualAdjustmentsWhenRecording(Recorder, TempTablesManager) Export
	
	Query = New Query(
	"SELECT
	|	OldRegisteredRecords.ProductionPlan AS ProductionPlan,
	|	OldRegisteredRecords.Products AS Products,
	|	OldRegisteredRecords.Characteristic AS Characteristic,
	|	OldRegisteredRecords.Purpose AS Purpose,
	|	OldRegisteredRecords.BillOfMaterials AS BillOfMaterials,
	|	CASE
	|		WHEN OldRegisteredRecords.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN OldRegisteredRecords.Period
	|		ELSE OldRegisteredRecords.DateOfOrderReleaseAndProductionIssue
	|	END AS StartDate2,
	|	CASE
	|		WHEN OldRegisteredRecords.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN OldRegisteredRecords.DateOfOrderReleaseAndProductionIssue
	|		ELSE OldRegisteredRecords.Period
	|	END AS DateOfProduction,
	|	OldRegisteredRecords.ProductionIssueDateOfIntermediateProducts AS ProductionIssueDateOfIntermediateProducts,
	|	OldRegisteredRecords.ToPlan AS ToPlan,
	|	OldRegisteredRecords.ThisIsASemiFinishedProduct AS ThisIsASemiFinishedProduct,
	|	OldRegisteredRecords.Count AS Count,
	|	OldRegisteredRecords.ToOrder AS ToOrder,
	|	OldRegisteredRecords.AdjustmentDate AS AdjustmentDate,
	|	OldRegisteredRecords.AdjustmentAuthor AS AdjustmentAuthor,
	|	OldRegisteredRecords.Comment AS Comment
	|FROM
	|	ListOfAdjustmentsBeforeWrite AS OldRegisteredRecords
	|		LEFT JOIN AccumulationRegister.ProductionPlans AS NewRegisteredRecords_
	|		ON NewRegisteredRecords_.Recorder = &Recorder
	|			AND OldRegisteredRecords.Period = NewRegisteredRecords_.Period
	|			AND OldRegisteredRecords.Scenario = NewRegisteredRecords_.Scenario
	|			AND OldRegisteredRecords.Products = NewRegisteredRecords_.Products
	|			AND OldRegisteredRecords.Characteristic = NewRegisteredRecords_.Characteristic
	|			AND OldRegisteredRecords.Department = NewRegisteredRecords_.Department
	|			AND OldRegisteredRecords.ProductionPlan = NewRegisteredRecords_.ProductionPlan
	|			AND OldRegisteredRecords.BillOfMaterials = NewRegisteredRecords_.BillOfMaterials
	|			AND OldRegisteredRecords.Purpose = NewRegisteredRecords_.Purpose
	|			AND OldRegisteredRecords.ProductionIssueDateOfIntermediateProducts = NewRegisteredRecords_.ProductionIssueDateOfIntermediateProducts
	|			AND OldRegisteredRecords.DateOfOrderReleaseAndProductionIssue = NewRegisteredRecords_.DateOfOrderReleaseAndProductionIssue
	|			AND OldRegisteredRecords.ToPlan = NewRegisteredRecords_.ToPlan
	|			AND OldRegisteredRecords.ManualAdjustment = NewRegisteredRecords_.ManualAdjustment
	|WHERE
	|	OldRegisteredRecords.ManualAdjustment AND NewRegisteredRecords_.Products IS NULL");
	
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("Recorder", Recorder);
	
	InformationRegisters.CancelProductionPlanAdjustingEntries.RecordAdjustments(Query.Execute().Unload(), Recorder);
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// Adds information security update procedures to the list for all supported library versions or configurations.
// 
// Called before the start of updating the information security data to build an update plan.
//
//  Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
// Example of adding a handler procedure to the list:
//  Handler = Handlers.Add();
//  Handler.Version = "1.1.0.0";
//  Handler.Procedure = "Update".Re-ITERATION_1_1_0_0";
//  Handler.Monopoly Mode = False;
//  
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "AccumulationRegisters.ProductionPlans.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.18.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e95e31fb-68bd-48dc-b479-41a3939ad47a");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "AccumulationRegisters.ProductionPlans.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Đang điền mục tin ""Lập kế hoạch"" bằng giá trị từ mục tin ""Đây là bán thành phẩm"".';
							|ru = 'Заполняет реквизит ""Запланировать"" значением из реквизита ""Это полуфабрикат"".';
							|en = 'Fills the ""Schedule"" attribute with the value from the ""This is a semi-finished product"" attribute.'; fa = 'Fills the ""Schedule"" attribute with the value from the ""This is a semi-finished product"" attribute.';
							|it = 'Заполняет реквизит ""Запланировать"" значением из реквизита ""Это полуфабрикат"".';
							|pl = 'Fills the ""Schedule"" attribute with the value from the ""This is a semi-finished product"" attribute.';
							|tr = '""Planla"" özniteliğini ""Bu yarı mamul üründür"" özniteliğindeki değerle doldurur.'");
	Handler.ObjectsToRead = Metadata.AccumulationRegisters.ProductionPlans.FullName();
	Handler.ObjectsToChange = Metadata.AccumulationRegisters.ProductionPlans.FullName();
	
EndProcedure

// Parameters:
//  Parameters - See InfobaseUpdate.MainProcessingMarkParameters
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = "AccumulationRegister.ProductionPlans";
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.OrderingFieldsOnUserOperations.Add("Period DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("Period DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RegisterRecordersSelectionMethod();
	
	Query = New Query;
	Query.Text = "
	|SELECT DISTINCT
	|	ProductionPlans.Recorder AS Ref
	|FROM
	|	AccumulationRegister.ProductionPlans AS ProductionPlans
	|	LEFT JOIN Document.ProductionPlan AS DocumentPlan
	|	ON ProductionPlans.ProductionPlan = DocumentPlan.Ref
	|	INNER JOIN Catalog.PlanProfiles AS PlanProfiles
	|	ON PlanProfiles.Ref = DocumentPlan.PlanProfile
	|	AND PlanProfiles.PlanSemiFinishedProductsAutomatically
	|WHERE
	|	ProductionPlans.ThisIsASemiFinishedProduct
	|	AND NOT ProductionPlans.ToPlan";
	Recorders = Query.Execute().Unload().UnloadColumn("Ref");
	InfobaseUpdate.MarkRecordersForProcessing(Parameters, Recorders, FullRegisterName);
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.AccumulationRegisters.ProductionPlans.FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
			Parameters.Queue, FullRegisterName);
		Return;
	EndIf;
	
	For Each CurrentData In UpdatedData Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			
			LockItem = Block.Add("AccumulationRegister.ProductionPlans.RecordSet");
			LockItem.SetValue("Recorder", CurrentData.Recorder);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			RecordSet = AccumulationRegisters.ProductionPlans.CreateRecordSet();
			RecordSet.Filter.Recorder.Set(CurrentData.Recorder);
			RecordSet.Read();
			
			For Each Record In RecordSet Do
				If Record.ThisIsASemiFinishedProduct Then
					Record.ToPlan = True;
				EndIf;
			EndDo;
			
			If RecordSet.Modified() Then
				InfobaseUpdate.WriteData(RecordSet);
			Else
				InfobaseUpdate.MarkProcessingCompletion(RecordSet);
			EndIf;
			
			CommitTransaction();
			
		Except
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), CurrentData.Recorder);
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
