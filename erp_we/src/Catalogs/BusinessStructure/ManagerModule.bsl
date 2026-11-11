#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public
	
// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	
	Return NotAttributesToEdit;
	
EndFunction

// Returns the names of the blocked details for the mechanism for blocking the BSP details
//
// Returns:
//	Array - names of the blocked details.
//
Function GetObjectAttributesToLock() Export
	
	Result = New Array;
	Result.Add("ProductionDispatcherBusinessUnit");
	
	Result.Add("PlanningInterval;
		|StartOfThePlanningIntervalDay, EndOfThePlanningIntervalDay,
		|StartOfThePlanningIntervalWeekDay, StartOfThePlanningIntervalWeekTime,
		|EndOfThePlanningIntervalWeekDay, EndOfThePlanningIntervalWeekTime");
	Result.Add("OperationSheetManagement");
	Result.Add("OperationManagementMethod");
	Result.Add("SemiFinishedProductsReceiptMethod");
	Result.Add("UseOperationManagement");
	Result.Add("UseMaterialsInOperations");
	Result.Add("UseFinishedProductsInOperations");
	Result.Add("UseManufacturingExecutionSystem");
	Result.Add("UseShiftTasks");
	Result.Add("UseProductionSites");
	Result.Add("OutputRegistrationFrequency");
	Result.Add("UseLPR");
	Result.Add("UseTariffRates");
	Result.Add("UseHoursWorked");
	Result.Add("UseTeamWorkOrders;
		|TypesOfBrigadeOutfits, TypesOfOutfitsEmployees, TypesOfOutfitsTeamsAndEmployees");
	Result.Add("UsePersonalWorkOrders;
		|TypesOfBrigadeOutfits, TypesOfOutfitsEmployees, TypesOfOutfitsTeamsAndEmployees");
	
	Result.Add("WorkScheduleSetupMethod");
	Result.Add("WorkSchedules; WorkScheduleCalendar");
	
	Result.Add("ProductionBusinessUnit");
	Result.Add("ProductionByOrders");
	Result.Add("BackflushProduction_");
	Result.Add("RecordingExpensesOnProcustCostIsUsed;
		|SeparateDocument, ByDistributionRules");
	
	Return Result;
	
EndFunction

// Gets the dispatcher division, if it is the only one in the IB
//  If the dispatcher division is not passed as a parameter, or an empty one is passed,
//  it returns the only dispatcher division in the information database.
//  If there are several dispatcher divisions in the database,
//  returns the dispatcher division from the user settings.
//  If the dispatcher division is not specified in the user settings,
//  it returns an empty division.
//
// Parameters:
//  User - CatalogRef.Users - link to the user.
// 
// Returns:
//  CatalogRef.BusinessStructure - the unit is the default dispatcher.
//
Function GetDefaultManagerDivision(Val User = Undefined) Export
	Query = New Query("
		|SELECT ALLOWED TOP 2
		|	BusinessStructure.Ref AS Department
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	NOT BusinessStructure.DeletionMark
		|	AND BusinessStructure.ProductionDispatcherBusinessUnit
		|	AND BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
		|");
		
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		
		Department = Selection.Department;
		
	ElsIf ValueIsFilled(User) Then
		
		Query = New Query("
			|SELECT
			|	Users.Department AS Department
			|FROM
			|	Catalog.Users AS Users
			|WHERE
			|	Users.Ref = &User
			|	AND ISNULL(Users.Department.ProductionDispatcherBusinessUnit, FALSE)
			|");
			
		Query.SetParameter("User", User);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			Department = Selection.Department;
		Else
			Department = Catalogs.BusinessStructure.EmptyRef();
		EndIf;
		
	Else
		Department = Catalogs.BusinessStructure.EmptyRef();
	EndIf;
	Return Department;

EndFunction

// Returns the number of dispatcher divisions.
// Does not take into account predefined and marked for deletion elements.
//
// Returns:
//     Number - the number of dispatcher units.
//
Function NumberOfDispatcherUnits() Export
	
	SetPrivilegedMode(True);
	
	Query = New Query(
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	NOT BusinessStructure.DeletionMark
		|	AND BusinessStructure.ProductionDispatcherBusinessUnit
		|	AND BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)");
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Count = Selection.Count;
	Else
		Count = 0;
	EndIf;
	
	Return Count;
	
EndFunction

// Returns the index of multiple units-controllers.
// 
// Returns:
//  Boolean - True if multiple dispatcher units are used.
//
Function MultipleDispatcherUnitsAreUsed() Export
	
	Return NumberOfDispatcherUnits() > 1;
	
EndFunction

// Checks the use of production parameters
//
// Parameters:
//  Parameters		- Structure - contains an object that you want to check for usage
//  StorageAddress	- String - address of the storage where the verification result will be placed.
//
Procedure CheckUseOfProductionParameters(Parameters, StorageAddress) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	SearchTable.Ref
	|FROM
	|	Document.MovementOfProductsAndMaterials AS SearchTable
	|WHERE
	|	SearchTable.Sender = &Department
	|	AND SearchTable.BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.TransferOfProductsFromProduction),
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseToWarehouse),
	|		VALUE(Enum.BusinessTransactions.ProductsReleaseToBusinessUnit))
	|	AND NOT SearchTable.ByReferences
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	WorkCenterTypes.Ref
	|FROM
	|	Catalog.WorkCenterTypes AS WorkCenterTypes
	|WHERE
	|	WorkCenterTypes.Department = &Department
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	ProductionStages.Ref
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.Department = &Department
	|	AND ProductionStages.PlanOperationsOfWorkCenterTypes
	|;
	|
	|
	|SELECT TOP 1
	|	ProductionOrder.Ref
	|FROM
	|	Document.ProductionOrder2_2 AS ProductionOrder
	|WHERE
	|	ProductionOrder.Department = &Department
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	ProductionStages.Ref
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.Department = &Department
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	SearchTable.Ref
	|FROM
	|	Document.ProductionStage2_2.ManufacturedProducts AS SearchTable
	|WHERE
	|	SearchTable.Department = &Department
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	SearchTable.Ref
	|FROM
	|	Document.ProductionStage2_2.SideAndIntermediateRelease AS SearchTable
	|WHERE
	|	SearchTable.Department = &Department
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	SearchTable.Ref
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS SearchTable
	|WHERE
	|	SearchTable.Department = &Department
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	SearchTable.Ref
	|FROM
	|	Document.ProductionStage2_2.LaborCosts AS SearchTable
	|WHERE
	|	SearchTable.Department = &Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	SearchTable.Ref
	|FROM
	|	Document.ProductionOperation2_2 AS SearchTable
	|WHERE
	|	SearchTable.Department = &Department
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	SearchTable.Ref
	|FROM
	|	Document.ShiftTask AS SearchTable
	|WHERE
	|	SearchTable.Department = &Department
	|
	|;
	|";
	
	Query.SetParameter("Department", Parameters.Object);
	
	SetPrivilegedMode(True);
	Result = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	CheckResult = New Structure;
	
	CheckResult.Insert("UsedForProductionWithoutOrders",       Not Result[0].IsEmpty());
	CheckResult.Insert("SchedulingIntervalIsUsed",            Not Result[1].IsEmpty());
	
	CheckResult.Insert("UsedAsDispatcher",                    Not Result[2].IsEmpty());
	
	CheckResult.Insert("UsedForCustomProduction",        Not Result[3].IsEmpty());
	
	CheckResult.Insert("PostOperativeStageManagementIsUsed", Not Result[4].IsEmpty());
	
	CheckResult.Insert("ShiftJobsAreUsed",                  Not Result[5].IsEmpty());
	
	
	PutToTempStorage(CheckResult, StorageAddress);
	
EndProcedure

// Defines the Department's shop storeroom
//
// Parameters:
//	Department	- CatalogRef.BusinessStructure - The division for which the storeroom is defined.
//
// Returns:
//		CatalogRef.Warehouses - Shop storeroom of the subdivision.
//
Function DefaultShopPantry(Department) Export

	If GetFunctionalOption("UseSeveralWarehouses") Then
		
		If Not ValueIsFilled(Department) Then
			Return Catalogs.Warehouses.EmptyRef();
		EndIf;
		
		QueryText = 
		"SELECT ALLOWED TOP 2
		|	Table.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Table
		|WHERE
		|	NOT Table.DeletionMark
		|	AND NOT Table.IsFolder
		|	AND Table.Department = &Department
		|	AND Table.ShopFloorStockroom";
		
	Else
		
		QueryText = 
		"SELECT ALLOWED TOP 2
		|	Table.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Table
		|WHERE
		|	NOT Table.DeletionMark
		|	AND NOT Table.IsFolder
		|	AND Table.ShopFloorStockroom";
		
	EndIf;
	
	Query = New Query(QueryText);
	Query.SetParameter("Department", Department);
	
	Selection = Query.Execute().Select();
	If Selection.Next() And Selection.Count() = 1 Then
		Warehouse = Selection.Warehouse;
	Else
		Warehouse = Catalogs.Warehouses.EmptyRef();
	EndIf;
	
	Return Warehouse;

EndFunction

// Returns the dates for which you need to fill in availability
//
// Parameters:
//  Department	- CatalogRef.BusinessStructure - unit for which you want to retrieve the data.
//
// Returns:
//   Structure   - The dates for which you need to fill in the availability.
//
Function AvailabilityYouNeedToFillInSoftware(Department) Export
	
	ScheduleAvailabilityShouldBeFilledInTo = '000101010000';
	WCScheduleToBeFilledInUntil = '000101010000';
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BusinessStructure.FillInAvailabilityForProductionScheduleReminderDays,
	|	BusinessStructure.FillInAvailabilityForWorkCenterTimetableReminderDays
	|FROM
	|	Catalog.BusinessStructure AS BusinessStructure
	|WHERE
	|	BusinessStructure.Ref = &Department";
	
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("Department", Department);
	
	Result = Query.Execute();
	Selection = Result.Select();
	If Selection.Next() Then
		CurrentSessionDate = BegOfDay(CurrentSessionDate());
		If Selection.FillInAvailabilityForProductionScheduleReminderDays <> 0 Then
			ScheduleAvailabilityShouldBeFilledInTo = CurrentSessionDate + Selection.FillInAvailabilityForProductionScheduleReminderDays * 86400;
		EndIf; 
		If Selection.FillInAvailabilityForWorkCenterTimetableReminderDays <> 0 Then
			WCScheduleToBeFilledInUntil = CurrentSessionDate + Selection.FillInAvailabilityForWorkCenterTimetableReminderDays * 86400;
		EndIf; 
	EndIf; 
	
	YouNeedToFillInSoftware = New Structure;
	YouNeedToFillInSoftware.Insert("ScheduleAvailabilityShouldBeFilledInTo", ScheduleAvailabilityShouldBeFilledInTo);
	YouNeedToFillInSoftware.Insert("WCScheduleToBeFilledInUntil", WCScheduleToBeFilledInUntil);
	
	Return YouNeedToFillInSoftware;

EndFunction

// Fills in service constants:
//	 - Ispolzovatblizhny,
//	 - Use the methodicoperation planning,
//	 - Use the methodicregistration of operations,
//	 - Use operation management,
//	 - Use operational planning.
//
// Parameters:
//  ServiceConstants_ - Undefined, Structure - the keys are the names of the service constants,
//                                                 if the corresponding service constant Attribute(s) of the Catalog
//                                                 is set, then the value is set to TRUE, otherwise FALSE.
//
Procedure FillInManagementTechniquesUsed(ServiceConstants_ = Undefined) Export
	
	SetPrivilegedMode(True);
	
	Tables = New Array;
	Fields    = New Array;
	
	If ValueIsFilled(ServiceConstants_) Then
		
		StructureOfServiceConstants = ServiceConstants_;
		
	Else
		
		StructureOfServiceConstants = New Structure;
		StructureOfServiceConstants.Insert("UseManufacturingExecutionSystem",         False);
		StructureOfServiceConstants.Insert("UseOperationManagement",           False);
		StructureOfServiceConstants.Insert("UseShiftTasks",                     False);
		
		
	EndIf;
	
	For Each ServiceConstant In StructureOfServiceConstants Do
		
		If ServiceConstant.Value Then
			Continue;
		EndIf;
		
		ConstantName = ServiceConstant.Key;
		
		If ConstantName = "UseOperationManagement" Then
			
			Fields.Add("
			|	CASE
			|		WHEN Production2_2.Value
			|			THEN TRUE IN
			|					(SELECT TOP 1
			|						TRUE
			|					FROM
			|						Catalog.BusinessStructure AS BusinessStructure
			|					WHERE
			|						BusinessStructure.UseOperationManagement
			|						AND NOT BusinessStructure.UseManufacturingExecutionSystem)
			|		ELSE FALSE
			|	END AS UseOperationManagement");
			
			If Tables.Find("Constant.UseProductionManagement2_2 AS Production2_2") = Undefined Then
				Tables.Add("Constant.UseProductionManagement2_2 AS Production2_2");
			EndIf;
			
		ElsIf ConstantName = "UseManufacturingExecutionSystem" Then
			
			Fields.Add("
			|	CASE
			|		WHEN Production2_2.Value AND NOT DynamicStructure.Value
			|			THEN TRUE IN
			|					(SELECT TOP 1
			|						TRUE
			|					FROM
			|						Catalog.BusinessStructure AS BusinessStructure
			|					WHERE
			|						BusinessStructure.UseOperationManagement
			|						AND BusinessStructure.UseManufacturingExecutionSystem)
			|		ELSE FALSE
			|	END AS UseManufacturingExecutionSystem");
			
			If Tables.Find("Constant.UseProductionManagement2_2 AS Production2_2") = Undefined Then
				Tables.Add("Constant.UseProductionManagement2_2 AS Production2_2");
			EndIf;
			
			Tables.Add("Constant.DynamicStructureOfProductionOrders AS DynamicStructure");
			
		ElsIf ConstantName = "UseShiftTasks" Then
			
			Fields.Add("
			|	CASE
			|		WHEN Production2_2.Value
			|			THEN TRUE IN
			|					(SELECT TOP 1
			|						TRUE
			|					FROM
			|						Catalog.BusinessStructure AS BusinessStructure
			|					WHERE
			|						BusinessStructure.UseShiftTasks)
			|		ELSE FALSE
			| 	END AS UseShiftTasks");
			
			If Tables.Find("Constant.UseProductionManagement2_2 AS Production2_2") = Undefined Then
				Tables.Add("Constant.UseProductionManagement2_2 AS Production2_2");
			EndIf;
			
			
		EndIf;
		
	EndDo;
	
	If Fields.Count() > 0 Then
		
		Separator = StrTemplate("%1%2", ",", Chars.LF);
		
		QueryText = 
		"SELECT
		|	Table.Value
		|FROM
		|	Table AS Table";
		
		QueryText = StrReplace(QueryText, "Table.Value",	StrConcat(Fields, Separator));
		QueryText = StrReplace(QueryText, "Table AS Table", StrConcat(Tables, Separator));
		
		Query = New Query;
		Query.Text = QueryText;
		
		QueryResult = Query.Execute();
		
	EndIf;
	
	BeginTransaction();
	
	Try
		
		Block = New DataLock;
		
		For Each ServiceConstant In StructureOfServiceConstants Do
			LockItem = Block.Add(StrTemplate("Constant.%1", ServiceConstant.Key));
			LockItem.Mode = DataLockMode.Exclusive;
		EndDo;
		
		Block.Lock();
		
		If Fields.Count() > 0 Then
			
			Selection = QueryResult.Select();
			Selection.Next();
			
		EndIf;
		
		For Each ServiceConstant In StructureOfServiceConstants Do
			
			ConstantName      = ServiceConstant.Key;
			ConstantValue = ?(ServiceConstant.Value, True, Selection[ConstantName]);
			
			If Constants[ConstantName].Get() <> ConstantValue Then
				Constants[ConstantName].Set(ConstantValue);
			EndIf;
			
		EndDo;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể ghi lại các phương thức quản lý sản xuất đang sử dụng.';
							|ru = 'Не удалось записать используемые методики управления производством';
							|en = 'Cannot save the used production management methods'; fa = 'Cannot save the used production management methods';
							|it = 'Non è stato possibile registrare i metodi di gestione della produzione utilizzate';
							|pl = 'Zapisywanie używanych metodyk zarządzania produkcją nie powiodło się';
							|tr = 'Kullanılan üretim kontrol uygulamaları kaydedilemedi'");
		
		EventLogEvent = 
			NStr("vi = 'Quản lý liên xưởng';
				|ru = 'Межцеховое управление';
				|en = 'Production scheduling and controlling'; fa = 'زمان‌بندی و کنترل تولید';
				|it = 'Gestione interna dei reparti';
				|pl = 'Zarządzanie międzyresortowe';
				|tr = 'Üretim planlama ve kontrolü'", CommonClientServer.DefaultLanguageCode())
			+ "."
			+ NStr("vi = 'Lỗi điền phương thức quản lý sản xuất';
					|ru = 'Ошибка заполнения методик управления производством';
					|en = 'Production management methods filling error'; fa = 'Production management methods filling error';
					|it = 'Errore di compilazione delle metodiche di gestione della produzione';
					|pl = 'Błąd wypełnienie metodyk zarządzania produkcją';
					|tr = 'Üretim yönetimi yöntemlerini doldururken hata'", CommonClientServer.DefaultLanguageCode());
		
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Warning,
			, 
			, 
			MessageText);
		
	EndTry;
	
EndProcedure

// Determines whether operational management of production stages is used in the division.
//
// Parameters:
//	Department	- CatalogRef.BusinessStructure - unit.
//
// Returns:
//		Boolean - True if the unit uses operational management.
//
Function UseOperationManagement(Department) Export
	
	Query = New Query(
	"SELECT
	|	TRUE
	|FROM
	|	Catalog.BusinessStructure AS BusinessStructure
	|WHERE
	|	BusinessStructure.Ref = &Ref
	|	AND BusinessStructure.UseOperationManagement
	|	AND NOT BusinessStructure.UseManufacturingExecutionSystem");
	Query.SetParameter("Ref", Department);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Determines whether operational planning of production stage operations is used in the division.
//
// Parameters:
//	Department	- CatalogRef.BusinessStructure - unit.
//
// Returns:
//		Boolean - True if the unit uses operational planning.
//
Function UseManufacturingExecutionSystem(Department) Export
	
	Query = New Query(
	"SELECT
	|	TRUE
	|FROM
	|	Catalog.BusinessStructure AS BusinessStructure
	|WHERE
	|	BusinessStructure.Ref = &Ref
	|	AND BusinessStructure.UseOperationManagement
	|	AND BusinessStructure.UseManufacturingExecutionSystem");
	Query.SetParameter("Ref", Department);
	
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// Returns default values for division parameters.
// 
// Returns:
//  Structure - Default:
//		* Ref - CatalogRef.BusinessStructure - Link to the Catalog element "Enterprise structure"
//		* OptionOfAssignedAccountingOfGoods - EnumRef.OptionsOfAssignedAccountingOfGoods - Option of separate accounting of goods
//		* ProductionBusinessUnit - Boolean - Production division attribute
//		* PlanningInterval - Undefined - the planning interval
//		* PlanningIntervalStart - Date - start of the planning interval
//		* PlanningIntervalEnd - Date - end of the planning interval
//		* WorkScheduleCalendar - CatalogRef.Calendars, Undefined - Work schedule of the division
//		* ProductionDispatcherBusinessUnit - Boolean - Division-dispatcher
//		* UseItemsBatch - Boolean - Use the series of the nomenclature
//		* UseCostAccountingByBatches - Boolean - Take into account the cost of the series
//		* ProductionByOrders - Boolean - Production by order
//		* BackflushProduction_ - Boolean - Production without orders
//		* RecordingExpensesOnProcustCostIsUsed - Boolean - The write-off of the output costs is used
//		* UseOperationManagement - Boolean - Use operational management
//		* UseMaterialsInOperations - Boolean - Use materials in operations
//		* UseFinishedProductsInOperations - Boolean - Use output products in operations
//		* UseManufacturingExecutionSystem - Boolean - Use the Manufacturing Execution System
//		* OutputRegistrationFrequency - Undefined - The time fence of the design of the work
//		* UseLPR - Boolean - Use CTU
//		* UseTariffRates - Boolean - Use tariff rates
//		* UseHoursWorked - Boolean - Use the time worked
//		* UseTeamWorkOrders - Boolean - Use brigade outfits
//		* UsePersonalWorkOrders - Boolean - Use personal outfits
//		* WorkScheduleSetupMethod - EnumRef.MethodsOfConfiguringBusinessUnitWorkSchedule - How to set up a work schedule
//		* UseShiftTasks - Boolean - Use shift tasks
//		* UseProductionSites - Boolean - Use production sites
//		* Status - EnumRef.BusinessUnitCompanyStatuses - Status of the division
Function DefaultValues() Export
	
	StructureOfValues = New Structure;
	
	StructureOfValues.Insert("Ref", Catalogs.BusinessStructure.EmptyRef());
	StructureOfValues.Insert("OptionOfAssignedAccountingOfGoods", Enums.OptionsOfAssignedAccountingOfGoods.NotKept);
	StructureOfValues.Insert("ProductionBusinessUnit", False);
	StructureOfValues.Insert("PlanningInterval", Undefined);
	StructureOfValues.Insert("PlanningIntervalStart", '00010101');
	StructureOfValues.Insert("PlanningIntervalEnd", '00010101');
	StructureOfValues.Insert("WorkScheduleCalendar", Undefined);
	StructureOfValues.Insert("ProductionDispatcherBusinessUnit", False);
	StructureOfValues.Insert("UseItemsBatch", False);
	StructureOfValues.Insert("UseCostAccountingByBatches", False);
	StructureOfValues.Insert("ProductionByOrders", False);
	StructureOfValues.Insert("BackflushProduction_", False);
	StructureOfValues.Insert("RecordingExpensesOnProcustCostIsUsed", False);
	StructureOfValues.Insert("UseOperationManagement", False);
	StructureOfValues.Insert("UseMaterialsInOperations", False);
	StructureOfValues.Insert("UseFinishedProductsInOperations", False);
	StructureOfValues.Insert("UseManufacturingExecutionSystem", False);
	StructureOfValues.Insert("OutputRegistrationFrequency", Undefined);
	StructureOfValues.Insert("UseLPR", False); 
	StructureOfValues.Insert("UseTariffRates", False);
	StructureOfValues.Insert("UseHoursWorked", False);
	StructureOfValues.Insert("UseTeamWorkOrders", False);
	StructureOfValues.Insert("UsePersonalWorkOrders", False);
	StructureOfValues.Insert("WorkScheduleSetupMethod", Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.MainEnterpriseCalendar);
	StructureOfValues.Insert("UseShiftTasks", False);
	StructureOfValues.Insert("UseProductionSites", False);
	StructureOfValues.Insert("Status", Enums.BusinessUnitCompanyStatuses.Valid);
	
	Return StructureOfValues
	
EndFunction

// Generates the current accounting parameters for sub-divisions.
//
// Parameters:
//	Departments - Array of CatalogRef.BusinessStructure, CatalogRef.BusinessStructure, Undefined - Departments
// 
// Returns:
//   ValueTable - Table of values with columns:
//		* Ref - CatalogRef.BusinessStructure - Link to the Catalog element "Enterprise structure"
//		* Presentation - String - Presentation of the unit
//		* OptionOfAssignedAccountingOfGoods - EnumRef.OptionsOfAssignedAccountingOfGoods - Option of separate accounting of goods
//		* ProductionBusinessUnit - Boolean - Production division attribute
//		* PlanningInterval - EnumRef.ProductionScheduleAccuracy - the planning interval
//		* PlanningIntervalStart - Date - start of the planning interval
//		* PlanningIntervalEnd - Date - end of the planning interval
//		* WorkScheduleCalendar - CatalogRef.Calendars - Work schedule of the division
//		* ProductionDispatcherBusinessUnit - Boolean - Division-dispatcher
//		* UseItemsBatch - Boolean - Use the series of the nomenclature
//		* UseCostAccountingByBatches - Boolean - Take into account the cost of the series
//		* ProductionByOrders - Boolean - Production by order
//		* BackflushProduction_ - Boolean - Production without orders
//		* RecordingExpensesOnProcustCostIsUsed - Boolean - The write-off of the output costs is used
//		* UseOperationManagement - Boolean - Use operational management
//		* UseMaterialsInOperations - Boolean - Use materials in operations
//		* UseFinishedProductsInOperations - Boolean - Use output products in operations
//		* UseManufacturingExecutionSystem - Boolean - Use the Manufacturing Execution System
//		* OutputRegistrationFrequency - EnumRef.FrequencyOfWorkOutputRegistration - The time fence of the design of the work
//		* UseLPR - Boolean - Use CTU
//		* UseTariffRates - Boolean - Use tariff rates
//		* UseHoursWorked - Boolean - Use the time worked
//		* UseTeamWorkOrders - Boolean - Use brigade outfits
//		* UsePersonalWorkOrders - Boolean - Use personal outfits
//		* WorkScheduleSetupMethod - EnumRef.MethodsOfConfiguringBusinessUnitWorkSchedule - How to set up a work schedule
//		* UseShiftTasks - Boolean - Use shift tasks
//		* UseProductionSites - Boolean - Use production sites
//		* Status - EnumRef.BusinessUnitCompanyStatuses - Status of the division
Function CurrentAccountingParameters(Departments = Undefined) Export
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED
		|	BusinessStructure.Ref AS Ref,
		|	BusinessStructure.Presentation AS Presentation,
		|	BusinessStructure.OptionOfAssignedAccountingOfGoods AS OptionOfAssignedAccountingOfGoods,
		|	BusinessStructure.ProductionBusinessUnit AS ProductionBusinessUnit,
		|	BusinessStructure.PlanningInterval AS PlanningInterval,
		|	BusinessStructure.PlanningIntervalStart AS PlanningIntervalStart,
		|	BusinessStructure.PlanningIntervalEnd AS PlanningIntervalEnd,
		|	BusinessStructure.WorkScheduleCalendar AS WorkScheduleCalendar,
		|	BusinessStructure.OperationManagementMethod AS OperationManagementMethod,
		|	BusinessStructure.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
		|	BusinessStructure.UseItemsBatch AS UseItemsBatch,
		|	BusinessStructure.UseCostAccountingByBatches AS UseCostAccountingByBatches,
		|	BusinessStructure.ProductionByOrders AS ProductionByOrders,
		|	BusinessStructure.BackflushProduction_ AS BackflushProduction_,
		|	BusinessStructure.RecordingExpensesOnProcustCostIsUsed AS RecordingExpensesOnProcustCostIsUsed,
		|	BusinessStructure.UseOperationManagement AS UseOperationManagement,
		|	BusinessStructure.UseMaterialsInOperations AS UseMaterialsInOperations,
		|	BusinessStructure.UseFinishedProductsInOperations AS UseFinishedProductsInOperations,
		|	BusinessStructure.UseManufacturingExecutionSystem AS UseManufacturingExecutionSystem,
		|	BusinessStructure.OutputRegistrationFrequency AS OutputRegistrationFrequency,
		|	BusinessStructure.UseLPR AS UseLPR,
		|	BusinessStructure.UseTariffRates AS UseTariffRates,
		|	BusinessStructure.UseHoursWorked AS UseHoursWorked,
		|	BusinessStructure.UseTeamWorkOrders AS UseTeamWorkOrders,
		|	BusinessStructure.UsePersonalWorkOrders AS UsePersonalWorkOrders,
		|	BusinessStructure.WorkScheduleSetupMethod AS WorkScheduleSetupMethod,
		|	BusinessStructure.UseShiftTasks AS UseShiftTasks,
		|	BusinessStructure.UseProductionSites AS UseProductionSites,
		|	BusinessStructure.Status AS Status
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	CASE
		|		WHEN &ByAll
		|			THEN TRUE
		|		ELSE BusinessStructure.Ref IN (&Departments)
		|	END
		|	AND BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
		|	AND NOT BusinessStructure.DeletionMark";
	
	Query.SetParameter("Departments", Departments);
	Query.SetParameter("ByAll", Departments = Undefined);
	QueryResult = Query.Execute().Unload();
	
	Return QueryResult;
EndFunction

// Generates a text description of the set parameters.
// 
// Parameters:
// 	Department - CatalogRef.BusinessStructure - link to the division.
// 	ValidityDate - Date - period of validity of settings.
// 	CurrentAccountingParameters - ValueTableRow of See CurrentAccountingParameters
// 	
// Returns:
// 	String - Description of the current parameters in a string.
Function DescriptionOfActiveParameters(Department, ValidityDate = Undefined, CurrentAccountingParameters = Undefined) Export
	
	If CurrentAccountingParameters = Undefined Then
		CurrentAccountingParametersByDivision = CurrentAccountingParameters(Department);
		If CurrentAccountingParametersByDivision.Count() > 0 Then
			CurrentAccountingParameters = CurrentAccountingParametersByDivision[0];
		Else
			CurrentAccountingParameters = DefaultValues();
		EndIf;
	EndIf;
	
	If ValidityDate = Undefined Then
		ValidityDate = CurrentSessionDate();
	EndIf;
	
	StringPattern_ = "%1: %2." + Chars.LF;
	StringPatternBoolean = "%1." + Chars.LF;
	
	SettingsDescriptionString = StrTemplate(StringPattern_, 
		NStr("vi = 'Trạng thái';
			|ru = 'Статус';
			|en = 'Status'; fa = 'وضعیت';
			|it = 'Status';
			|pl = 'Status';
			|tr = 'Durum'"),
		CurrentAccountingParameters.Status);
	
	If GetFunctionalOption("GenerateInventoryOwnerAttributesByBusinessUnitsAndManagers") Then
		SettingsDescriptionString = SettingsDescriptionString
			+ StrTemplate(StringPattern_, 
				NStr("vi = 'Quản lý đặt riêng hàng hóa được thực hiện theo bộ phận';
					|ru = 'Обособленный учет товаров по подразделению';
					|en = 'Goods assignment by business unit'; fa = 'Goods assignment by business unit';
					|it = 'Goods assignment by business unit';
					|pl = 'Goods assignment by business unit';
					|tr = 'Departmana göre ürün tahsisi'"),
				CurrentAccountingParameters.OptionOfAssignedAccountingOfGoods);
	EndIf;
	
	If GetFunctionalOption("UseProduction") Then
		
		If CurrentAccountingParameters.ProductionBusinessUnit Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Là bộ phận sản xuất';
					|ru = 'Подразделение является производственным';
					|en = 'Business unit is the production one'; fa = 'واحد تجاری تولیدی است';
					|it = 'Il reparto fa parte della produzione';
					|pl = 'Dział nie jest produkcyjnym';
					|tr = 'Departman bir üretim departmanıdır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Không phải là bộ phận sản xuất';
					|ru = 'Подразделение не является производственным';
					|en = 'This is not a production business unit'; fa = 'This is not a production business unit';
					|it = 'This is not a production business unit';
					|pl = 'This is not a production business unit';
					|tr = 'Departman, üretim departmanı değildir'"));
		EndIf;
		If CurrentAccountingParameters.ProductionDispatcherBusinessUnit Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Bộ phận-điều phối chịu trách nhiệm thực hiện đơn hàng sản xuất';
					|ru = 'Подразделение-диспетчер, ответственное за выполнение заказов на производство';
					|en = 'Dispatching unit responsible for fulfilling production orders'; fa = 'واحد دیسپچینگ مسئول اجرای سفارش‌های تولید';
					|it = 'Reparto-distributore responsabile dell''esecuzione degli ordini di produzione';
					|pl = 'Dział dyspozytorski, odpowiedzialny za wykonanie zleceń produkcyjnych';
					|tr = 'Üretim emirlerini yerine getirmekten sorumlu olan üretim planlama departmanı'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Không phải là bộ phận điều phối';
					|ru = 'Подразделение не является диспетчером';
					|en = 'This is not a dispatching business unit'; fa = 'This is not a dispatching business unit';
					|it = 'This is not a dispatching business unit';
					|pl = 'This is not a dispatching business unit';
					|tr = 'Departman, sevk departmanı değildir'"));
		EndIf;
		If CurrentAccountingParameters.WorkScheduleSetupMethod = Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.MainEnterpriseCalendar Then
			EnterpriseCalendar = Constants.MainEnterpriseCalendar.Get();
			If Not ValueIsFilled(EnterpriseCalendar) Then
				EnterpriseCalendar = NStr("vi = 'chưa đặt';
											|ru = 'не задан';
											|en = 'not specified'; fa = 'مشخص نشده';
											|it = 'non impostato';
											|pl = 'nie określono';
											|tr = 'belirtilmedi'");
			EndIf;
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_, 
					NStr("vi = 'Lịch biểu làm việc chính của tập đoàn';
						|ru = 'Основной график работы предпрития';
						|en = 'Main enterprise schedule'; fa = 'برنامه کاری اصلی سازمان';
						|it = 'Main enterprise schedule';
						|pl = 'Main enterprise schedule';
						|tr = 'İşletmenin ana çalışma takvimi'"),
					EnterpriseCalendar);
		ElsIf CurrentAccountingParameters.WorkScheduleSetupMethod = Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.PersonalSchedule Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_, 
					NStr("vi = 'Lịch biểu làm việc cá nhân';
						|ru = 'Индивидуальный график работы';
						|en = 'Individual schedule'; fa = 'زمان‌بندی جداگانه';
						|it = 'Individual schedule';
						|pl = 'Individual schedule';
						|tr = 'Bireysel çalışma takvimi'"),
					CurrentAccountingParameters.WorkScheduleCalendar);
		ElsIf CurrentAccountingParameters.WorkScheduleSetupMethod = Enums.MethodsOfConfiguringBusinessUnitWorkSchedule.Shifts Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Làm việc theo nhiều ca';
					|ru = 'Работа в несколько смен';
					|en = 'Work in several shifts'; fa = 'کار در چند شیفت';
					|it = 'Lavoro a turni';
					|pl = 'Praca w kilka zmian';
					|tr = 'Birden fazla vardiyada çalışma'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Chưa chỉ ra lịch biểu làm việc';
					|ru = 'Не указан график работы';
					|en = 'Work schedule is not specified'; fa = 'Work schedule is not specified';
					|it = 'Work schedule is not specified';
					|pl = 'Work schedule is not specified';
					|tr = 'Çalışma takvimi belirtilmedi'"));
		EndIf;
		If CurrentAccountingParameters.ProductionBusinessUnit Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPattern_, 
					NStr("vi = 'Khoảng thời gian lập kế hoạch';
						|ru = 'Интервал планирования';
						|en = 'Planning interval'; fa = 'بازه برنامه‌ریزی';
						|it = 'Intervallo di pianificazione';
						|pl = 'Okres planowania';
						|tr = 'Planlama aralığı'"),
					CurrentAccountingParameters.PlanningInterval);
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Chưa xác định khoảng thời gian lập kế hoạch';
					|ru = 'Интервал планирования не задан';
					|en = 'Planning interval is not set'; fa = 'Planning interval is not set';
					|it = 'Planning interval is not set';
					|pl = 'Planning interval is not set';
					|tr = 'Planlama aralığı belirtilmedi'"));
		EndIf;
		
		If CurrentAccountingParameters.UseProductionSites Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Sử dụng địa điểm sản xuất';
					|ru = 'Производственные участки используются';
					|en = 'Production sites are used'; fa = 'Production sites are used';
					|it = 'Production sites are used';
					|pl = 'Production sites are used';
					|tr = 'Üretim yerleri kullanılmaktadır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Không sử dụng địa điểm sản xuất';
					|ru = 'Производственные участки не используются';
					|en = 'Production sites are not used'; fa = 'Production sites are not used';
					|it = 'Production sites are not used';
					|pl = 'Production sites are not used';
					|tr = 'Üretim yerleri kullanılmamaktadır'"));
		EndIf;
		
		If CurrentAccountingParameters.UseOperationManagement Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Sử dụng quản lý vận hành các công đoạn sản xuất';
					|ru = 'Используется пооперационное управление этапами производства';
					|en = 'Operation management for production stages is used'; fa = 'Operation management for production stages is used';
					|it = 'Operation management for production stages is used';
					|pl = 'Operation management for production stages is used';
					|tr = 'Üretim aşamalarının operasyonel yönetimi kullanılmaktadır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Không sử dụng quản lý vận hành các công đoạn sản xuất';
					|ru = 'Пооперационное управление этапами производства не используется';
					|en = 'Operation management for production stages is not used'; fa = 'Operation management for production stages is not used';
					|it = 'Operation management for production stages is not used';
					|pl = 'Operation management for production stages is not used';
					|tr = 'Üretim aşamalarının operasyonel yönetimi kullanılmamaktadır'"));
		EndIf;
		
		If CurrentAccountingParameters.UseMaterialsInOperations Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Hạch toán nguyên liệu trong sản xuất';
					|ru = 'Ведется учет материалов в производственных операциях';
					|en = 'Records of materials in routing operations are kept'; fa = 'Records of materials in routing operations are kept';
					|it = 'Records of materials in routing operations are kept';
					|pl = 'Records of materials in routing operations are kept';
					|tr = 'Rota işlemlerinde malzemelerin muhasebesi tutulmaktadır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Không hạch toán nguyên vật liệu trong hoạt động sản xuất';
					|ru = 'Учет материалов в производственных операциях не ведется';
					|en = 'Records of materials in routing operations are not kept'; fa = 'Records of materials in routing operations are not kept';
					|it = 'Records of materials in routing operations are not kept';
					|pl = 'Records of materials in routing operations are not kept';
					|tr = 'Rota işlemlerinde malzemelerin muhasebesi tutulmamaktadır'"));
		EndIf;
		
		If CurrentAccountingParameters.UseFinishedProductsInOperations Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Hạch toán sản phẩm đầu ra trong giao dịch sản xuất';
					|ru = 'Ведется учет выходных изделий в производственных операциях';
					|en = 'Records of finished products in routing operations are kept'; fa = 'Records of finished products in routing operations are kept';
					|it = 'Records of finished products in routing operations are kept';
					|pl = 'Records of finished products in routing operations are kept';
					|tr = 'Rota işlemlerinde nihai ürünlerin muhasebesini tutulmaktadır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Không hạch toán sản phẩm đầu ra trong hoạt động sản xuất';
					|ru = 'Учет выходных изделий в производственных операциях не ведется';
					|en = 'Records of finished products in routing operations are not kept'; fa = 'Records of finished products in routing operations are not kept';
					|it = 'Records of finished products in routing operations are not kept';
					|pl = 'Records of finished products in routing operations are not kept';
					|tr = 'Rota işlemlerinde nihai ürünlerin muhasebesini tutulmamaktadır'"));
		EndIf;
		
		If CurrentAccountingParameters.UseShiftTasks Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Hoạt động sản xuất được hợp thành các nhiệm vụ theo ca';
					|ru = 'Производственные операции объединяются в сменные задания';
					|en = 'Production operations are combined into shift tasks'; fa = 'Production operations are combined into shift tasks';
					|it = 'Production operations are combined into shift tasks';
					|pl = 'Production operations are combined into shift tasks';
					|tr = 'Rota işlemleri vardiyalı görevler halinde birleştirilmektedir'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Hoạt động sản xuất không được hợp thành các nhiệm vụ theo ca';
					|ru = 'Производственные операции не объединяются в сменные задания';
					|en = 'Production operations are not combined into shift tasks'; fa = 'Production operations are not combined into shift tasks';
					|it = 'Production operations are not combined into shift tasks';
					|pl = 'Production operations are not combined into shift tasks';
					|tr = 'Rota işlemleri vardiyalı görevler halinde birleştirilmemektedir'"));
		EndIf;
		
		If CurrentAccountingParameters.UseManufacturingExecutionSystem Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Sử dụng lập kế hoạch vận hành các công đoạn sản xuất';
					|ru = 'Используется пооперационное планирование этапов производства';
					|en = 'Manufacturing execution system is used for production stages'; fa = 'Manufacturing execution system is used for production stages';
					|it = 'Manufacturing execution system is used for production stages';
					|pl = 'Manufacturing execution system is used for production stages';
					|tr = 'Üretim aşamalarının üretim yürütme sistemi kullanılmaktadır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Không sử dụng lập kế hoạch vận hành các công đoạn sản xuất';
					|ru = 'Пооперационное планирование этапов производства не используется';
					|en = 'Manufacturing execution system is not used for production stages'; fa = 'Manufacturing execution system is not used for production stages';
					|it = 'Manufacturing execution system is not used for production stages';
					|pl = 'Manufacturing execution system is not used for production stages';
					|tr = 'Üretim aşamalarının üretim yürütme sistemi kullanılmamaktadır'"));
		EndIf;
		If CurrentAccountingParameters.ProductionBusinessUnit Then
			If CurrentAccountingParameters.UseTeamWorkOrders And CurrentAccountingParameters.UsePersonalWorkOrders Then
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean, 
					NStr("vi = 'Các đội và nhân viên được chỉ định là người thực hiện công việc';
						|ru = 'Исполнителями работ назначаются бригады и работники';
						|en = 'Work teams and employees are assigned as work performers'; fa = 'Work teams and employees are assigned as work performers';
						|it = 'Work teams and employees are assigned as work performers';
						|pl = 'Work teams and employees are assigned as work performers';
						|tr = 'Çalışma ekipleri ve işçiler işin icracıları olarak atanmaktadır'"));
			ElsIf CurrentAccountingParameters.UseTeamWorkOrders Then
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean, 
					NStr("vi = 'Các đội được chỉ định là người thực hiện công việc';
						|ru = 'Исполнителями работ назначаются бригады';
						|en = 'Work teams are assigned as work performers'; fa = 'Work teams are assigned as work performers';
						|it = 'Work teams are assigned as work performers';
						|pl = 'Work teams are assigned as work performers';
						|tr = 'Çalışma ekipleri işin icracıları olarak atanmaktadır'"));
			Else
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean, 
					NStr("vi = 'Nhân viên được chỉ định là người thực hiện công việc';
						|ru = 'Исполнителями работ назначаются работники';
						|en = 'Employees are assigned as work performers'; fa = 'Employees are assigned as work performers';
						|it = 'Employees are assigned as work performers';
						|pl = 'Employees are assigned as work performers';
						|tr = 'İşçiler işin icracıları olarak atanmaktadır'"));
			EndIf;
			
		EndIf;
		
		If CurrentAccountingParameters.UseLPR Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Công việc hoàn thành được phân bổ giữa các nhân viên của đội có tính đến hệ số lao động khu vực';
					|ru = 'Выполненные работы распределяются по работникам бригады с учетом коэффициентов трудового участия';
					|en = 'Performed works are allocated to work team members according to the labor participation rates'; fa = 'Performed works are allocated to work team members according to the labor participation rates';
					|it = 'Performed works are allocated to work team members according to the labor participation rates';
					|pl = 'Performed works are allocated to work team members according to the labor participation rates';
					|tr = 'Yapılan işler, işe katılım katsayıları dikkate alınarak çalışma ekibi çalışanları arasında dağıtılmaktadır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Công việc hoàn thành được phân bổ giữa các nhân viên của đội không tính đến hệ số lao động khu vực';
					|ru = 'Выполненные работы распределяются по работникам бригады без учета коэффициентов трудового участия';
					|en = 'Performed works are allocated to work team members without taking into account the labor participation rates'; fa = 'Performed works are allocated to work team members without taking into account the labor participation rates';
					|it = 'Performed works are allocated to work team members without taking into account the labor participation rates';
					|pl = 'Performed works are allocated to work team members without taking into account the labor participation rates';
					|tr = 'Yapılan işler, işe katılım katsayıları dikkate alınmadan çalışma ekibi çalışanları arasında dağıtılmaktadır'"));
		EndIf;
		
		If CurrentAccountingParameters.UseHoursWorked Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Công việc hoàn thành được phân bổ giữa các nhân viên của đội, có tính đến giờ làm việc';
					|ru = 'Выполненные работы распределяются по работникам бригады с учетом отработанного времени';
					|en = 'Performed works are allocated to work team members according to hours worked'; fa = 'Performed works are allocated to work team members according to hours worked';
					|it = 'Performed works are allocated to work team members according to hours worked';
					|pl = 'Performed works are allocated to work team members according to hours worked';
					|tr = 'Yapılan işler, çalışılan zaman dikkate alınarak çalışma ekibi çalışanları arasında dağıtılmaktadır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Công việc hoàn thành được phân bổ giữa các nhân viên của đội, không tính đến giờ làm việc';
					|ru = 'Выполненные работы распределяются по работникам бригады без учета отработанного времени';
					|en = 'Performed works are allocated to work team members without taking into account hours worked'; fa = 'Performed works are allocated to work team members without taking into account hours worked';
					|it = 'Performed works are allocated to work team members without taking into account hours worked';
					|pl = 'Performed works are allocated to work team members without taking into account hours worked';
					|tr = 'Yapılan işler, çalışılan zaman dikkate alınmadan çalışma ekibi çalışanları arasında dağıtılmaktadır'"));
		EndIf;
		
		If CurrentAccountingParameters.UseTariffRates Then
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Công việc hoàn thành được phân bổ giữa các nhân viên của đội, có tính đến các mức lương';
					|ru = 'Выполненные работы распределяются по работникам бригады с учетом тарифных ставок';
					|en = 'Performed works are allocated to work team members according to the tariff rates'; fa = 'Performed works are allocated to work team members according to the tariff rates';
					|it = 'Performed works are allocated to work team members according to the tariff rates';
					|pl = 'Performed works are allocated to work team members according to the tariff rates';
					|tr = 'Yapılan işler, tarife oranları dikkate alınarak çalışma ekibi çalışanları arasında dağıtılmaktadır'"));
		Else
			SettingsDescriptionString = SettingsDescriptionString
				+ StrTemplate(StringPatternBoolean, 
				NStr("vi = 'Công việc hoàn thành được phân bổ giữa các nhân viên của đội, không tính đến các mức lương';
					|ru = 'Выполненные работы распределяются по работникам бригады без учета тарифных ставок';
					|en = 'Performed works are allocated to work team members without taking into account tariff rates'; fa = 'Performed works are allocated to work team members without taking into account tariff rates';
					|it = 'Performed works are allocated to work team members without taking into account tariff rates';
					|pl = 'Performed works are allocated to work team members without taking into account tariff rates';
					|tr = 'Yapılan işler, tarife oranları dikkate alınmadan çalışma ekibi çalışanları arasında dağıtılmaktadır'"));
		EndIf;
		If Constants.UseOutputRegistrationFrequency.Get() Then
			If ValueIsFilled(CurrentAccountingParameters.OutputRegistrationFrequency) Then
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPattern_, 
						NStr("vi = 'Sản lượng của nhân viên được thực hiện';
							|ru = 'Выработка сотрудников оформляется';
							|en = 'Timesheets charge is registered'; fa = 'محاسبه کارکرد ثبت می‌شود';
							|it = 'Produttività dei lavoratori viene eseguita';
							|pl = 'Wydajność pracowników jest sporządzana ';
							|tr = 'Zaman çizelgesi bazlı ücretlendirme düzenleniyor'"),
						CurrentAccountingParameters.OutputRegistrationFrequency);
			Else
				SettingsDescriptionString = SettingsDescriptionString
					+ StrTemplate(StringPatternBoolean, 
					NStr("vi = 'Chưa chỉ định tần suất lập sản lượng của nhân viên';
						|ru = 'Периодичность оформления выработка сотрудников не указана';
						|en = 'Frequency of timesheets charge registration is not specified'; fa = 'Frequency of timesheets charge registration is not specified';
						|it = 'Frequency of timesheets charge registration is not specified';
						|pl = 'Frequency of timesheets charge registration is not specified';
						|tr = 'Zaman çizelgesi bazlı ücretlendirme düzenleme sıklığı belirtilmedi'"));
			EndIf;
		EndIf;
	EndIf;
	
	Return SettingsDescriptionString
	
EndFunction

#Region Commands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = Documents.InstructionForShippingAgent.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.WriteMode = "";
	EndIf;
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// StandardSubsystems.AccessManagement

// See AccessManagementOverridable.OnFillListsWithAccessRestriction.
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Ref)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	If Parameters.Property("Filter") And (Parameters.Filter.Property("BusinessUnitIsProductionDispatcherOrProductionShopfloor") 
		Or Parameters.Filter.Property("ProductionBusinessUnit")) Then
		ProductionServerCall.EnterpriseStructureProcessingOfSelectionDataAcquisition(
					ChoiceData, 
					Parameters, 
					StandardProcessing);
		Return;	
	EndIf; 
	StandardProcessing = False;
	If ValueIsFilled(Parameters.SearchString) Then
		
		Query = New Query;
		Query.Text = 
		"SELECT ALLOWED TOP 51
		|	BusinessStructure.Ref AS Ref,
		|	BusinessStructure.DeletionMark AS DeletionMark,
		|	BusinessStructure.Description AS Description,
		|	CASE
		|		WHEN BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.NotValid)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS NotValid,
		|	BusinessStructure.Code AS Code,
		|	FALSE AS SelectionByCode
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	BusinessStructure.Description LIKE &Text
		|	AND NOT BusinessStructure.DeletionMark
		|	AND &SelectionInParameters 
		|
		|UNION ALL
		|
		|SELECT TOP 51
		|	BusinessStructure.Ref,
		|	BusinessStructure.DeletionMark,
		|	BusinessStructure.Description AS Description,
		|	CASE
		|		WHEN BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.NotValid)
		|			THEN TRUE
		|		ELSE FALSE
		|	END,
		|	BusinessStructure.Code,
		|	TRUE
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	BusinessStructure.Code LIKE &Text
		|	AND NOT BusinessStructure.DeletionMark
		|	AND &SelectionInParameters 
		|
		|ORDER BY
		|	Description";
		
		Query.SetParameter("Text", "%" + TrimAll(Parameters.SearchString) + "%");
		
		If NationalLanguageSupportServer.IsAdditionalLangUsed("1") 
			Or NationalLanguageSupportServer.IsAdditionalLangUsed("2") Then
			
			AttributesNames = NationalLanguageSupportServer.AttributesNamesConsideringLangCode("Description");
			
			ReplacementTemplate = StrReplace("BusinessStructure.%1", "%1", AttributesNames["Description"]);
			Query.Text = StrReplace(Query.Text, "BusinessStructure.Description",
				ReplacementTemplate);
			
		EndIf;
		
		PartsOfSelection = New Array;
		For Each Filter In Parameters.Filter Do
			If Common.HasObjectAttribute(Filter.Key, Metadata.Catalogs.BusinessStructure) Then
				PartsOfSelection.Add(Filter.Key + " = &" + Filter.Key + Chars.LF);
				Query.SetParameter(Filter.Key, Filter.Value);
			EndIf;
		EndDo;
		If PartsOfSelection.Count() Then
			AddtlFilter = StrConcat(PartsOfSelection, " And ");
		Else 
			AddtlFilter = "TRUE";
		EndIf;
		Query.Text = StrReplace(Query.Text, "&SelectionInParameters", AddtlFilter);

		Result = Query.Execute();
		Selection = Result.Select();
		
		ChoiceData = New ValueList;
		While Selection.Next() Do       
			TemplateOfPresentation = "%1 (%2)";
			If Selection.SelectionByCode Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation,
					Selection.Code, Selection.Description);
			Else
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateOfPresentation,
					Selection.Description, Selection.Code);
			EndIf;
					
			If Selection.NotValid Then 
				Item = New Structure;
				Item.Insert("Value", Selection.Ref);
				Item.Insert("DeletionMark", Selection.DeletionMark);
				WarningText = NStr("vi = 'Đã chọn bộ phận không còn hiệu lực.';
									|ru = 'Выбрано недействующее подразделение.';
									|en = 'An inactive business unit is selected.'; fa = 'An inactive business unit is selected.';
									|it = 'Выбрано недействующее подразделение.';
									|pl = 'An inactive business unit is selected.';
									|tr = 'Aktif olmayan bir departman seçilmiş.'"); 
				Item.Insert("Warning", WarningText);
				ChoiceData.Add(Item, Presentation);
			Else
				ChoiceData.Add(Selection.Ref, Presentation);
			EndIf;
		EndDo; 
	EndIf;
	
EndProcedure

#EndIf

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationFieldsGetProcessing(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	NationalLanguageSupportClientServer.PresentationGetProcessing(Data, Presentation, StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

#EndRegion

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.BusinessStructure.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.24.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("3729d747-7cb7-426a-afb4-002f38ef369c");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.BusinessStructure.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Cập nhật danh mục ""Bộ phận"":';
								|ru = 'Обновление справочника ""Подразделение"":';
								|en = 'Update the ""Business unit"" catalog:'; fa = 'Update the ""Business unit"" catalog:';
								|it = 'Update the ""Business unit"" catalog:';
								|pl = 'Update the ""Business unit"" catalog:';
								|tr = '""Departman"" kataloğunun güncellenmesi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	
	Handler.Comment = StrConcat(ListOfDescriptions, Chars.LF);
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.BusinessStructure.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.BusinessStructure.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.BusinessStructure.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = EmptyRef().Metadata().FullName();
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	AdditionalLanguagesAreUsed = False;
	For Each AdditionalLanguageIsUsed In NationalLanguageSupportServer.LanguagesInfo().Used Do
		
		If AdditionalLanguageIsUsed.Value = True Then
			
			AdditionalLanguagesAreUsed = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	If Not AdditionalLanguagesAreUsed Then
		
		Return;
		
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BusinessStructure.Ref AS Ref
	|FROM
	|	Catalog.BusinessStructure AS BusinessStructure
	|WHERE
	|	NOT BusinessStructure.Description = """"
	|	AND BusinessStructure.DescriptionLanguage1 = """"
	|	
	|UNION 
	|
	|SELECT
	|	BusinessStructure.Ref AS Ref
	|FROM
	|	Catalog.BusinessStructure AS BusinessStructure
	|WHERE
	|	NOT BusinessStructure.Description = """"
	|	AND BusinessStructure.DescriptionLanguage2 = """"";
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// The update handler
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.AdditionalMultithreadProcessingDataSelectionParameters 
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	Parameters.ProcessingCompleted = False;
	
	FullObjectName = EmptyRef().Metadata().FullName();
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		
		Parameters.ProcessingCompleted =
			InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
		Return;
		
	EndIf;
	
	ObjectsProcessed = 0;
	ObjectsWithIssuesCount = 0;
	ExceptionsWhenUpdating = New Array;
	
	ListOfDescriptions = New Array;
	ListOfDescriptions.Add(NStr("vi = 'Không thể xử lý danh mục ""Bộ phận"" theo hàm sự kiện:';
								|ru = 'Не удалось обработать справочник ""Подразделение"" по обработчику:';
								|en = 'Cannot process the ""Business unit"" catalog by the handler:'; fa = 'Cannot process the ""Business unit"" catalog by the handler:';
								|it = 'Cannot process the ""Business unit"" catalog by the handler:';
								|pl = 'Cannot process the ""Business unit"" catalog by the handler:';
								|tr = 'İşleyici tarafından ""Departman"" kataloğu işlenemedi:'"));
	ListOfDescriptions.Add(NStr("vi = '- Điền mục tin đa ngôn ngữ của danh mục';
								|ru = '- Заполнение мультиязычных реквизитов справочника';
								|en = '- Fill multilingual catalog attributes'; fa = '- Fill multilingual catalog attributes';
								|it = '- Fill multilingual catalog attributes';
								|pl = '- Fill multilingual catalog attributes';
								|tr = '- Kataloğun çok dilli özniteliklerinin doldurulması'"));
	Query = New Query;
	Query.Text = 
	"SELECT
	|	DataForUpdate.Ref AS Ref
	|INTO TT
	|FROM
	|	&DataForUpdate AS DataForUpdate
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT.Ref AS Ref,
	|	BusinessStructure.DataVersion AS DataVersion
	|FROM
	|	TT AS TT
	|		LEFT JOIN Catalog.BusinessStructure AS BusinessStructure
	|		ON TT.Ref = BusinessStructure.Ref";
	
	Query.SetParameter("DataForUpdate", UpdatedData);
	
	Catalog = Query.Execute().Select();
	
	While Catalog.Next() Do
		
		ExceptionReason = 0;
		Recommendation = "";
		
		BeginTransaction();
		
		Try
			
			ExceptionReason = 1; // IObjectLock
			
			Block = New DataLock;
			
			LockItem = Block.Add(FullObjectName);
			LockItem.SetValue("Ref", Catalog.Ref);
			LockItem.Mode = DataLockMode.Exclusive;
			
			Block.Lock();
			
			CatalogObject = InfobaseUpdateTM.CheckGetObject(
				Catalog.Ref, Catalog.DataVersion, Parameters.Queue); // CatalogObject
			
			ExceptionReason = 2; // BadData
			Recommendation = NStr("vi = 'Hãy kiểm tra thủ công dữ liệu của danh mục.';
									|ru = 'Проверьте данные справочника вручную.';
									|en = 'Check the catalog data manually.'; fa = 'Check the catalog data manually.';
									|it = 'Проверьте данные справочника вручную.';
									|pl = 'Check the catalog data manually.';
									|tr = 'Dizin verilerini manuel olarak kontrol edin.'");
			
			ObjectModified = False;
			
			If CatalogObject <> Undefined Then
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage1) Then
					
					CatalogObject.DescriptionLanguage1 = CatalogObject.Description;
					
				EndIf;
				
				If Not ValueIsFilled(CatalogObject.DescriptionLanguage2) Then
					
					CatalogObject.DescriptionLanguage2 = CatalogObject.Description;
					
				EndIf;
				
				ObjectModified = True;
				
			EndIf;
			
			ExceptionReason = 3; // Record
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Catalog.Ref);
			EndIf;
			
			ObjectsProcessed = ObjectsProcessed + 1;
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			ObjectsWithIssuesCount = ObjectsWithIssuesCount + 1;
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Catalog.Ref);
			
			If ExceptionReason = 2 Then
				
				IssueDetails = InfobaseUpdateTM.DataProblem(
					Catalog.Ref, Recommendation, ErrorInfo());
				ExceptionsWhenUpdating.Add(IssueDetails);
				
			ElsIf ExceptionReason = 3 Then
				
				InfobaseUpdateTM.RecordBadData(
					ExceptionsWhenUpdating, ObjectsProcessed, Parameters);
				Raise StrConcat(ListOfDescriptions, Chars.LF);
				
			EndIf;
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted =
		InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
#EndIf
