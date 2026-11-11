////////////////////////////////////////////////////////////////////////////////
// OUP: Procedures of the subsystem of operational accounting of production
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Constructor of parameters for assigning a production of operation.
// 
// Parameters:
//  MultipleMode - Boolean - Multiple destination mode
// 
// Returns:
//  Structure - Parameters Of The Assignment Of The Production Operation Constructor:
// * ProductionArea - CatalogRef.ProductionSites
// * ShiftTask - DocumentRef.ShiftTask
// * WorkCenterType - CatalogRef.WorkCenterTypes
// * WorkCenter - CatalogRef.WorkCenters
// * SetupSettings - CatalogRef.SetupOptions
// * Performer - CatalogRef.Persons
// * Count - Number
Function ParametersOfAssignmentOfProductionOperationConstructor(MultipleMode = False) Export
	
	Result = New Structure(ParametersOfProductionOperationAssignmentList(MultipleMode));
	
	Return Result;
	
EndFunction

// List of Attributes to be filled in when assigning of operation
// 
// Parameters:
//  MultipleMode - Boolean - Multiple destination mode
// 
// Returns:
//  String
Function ParametersOfProductionOperationAssignmentList(MultipleMode = False) Export
	
	If MultipleMode Then
		Result = "ProductionArea,ShiftTask,WorkCenterType,WorkCenter,SetupSettings,Performer";
	Else
		Result = "ProductionArea,ShiftTask,WorkCenterType,WorkCenter,SetupSettings,Performer,Count,ActivityKinds";
	EndIf;
	
	Return Result;
	
EndFunction

// Constructor of the result of the formation of production of operations
// 
// Returns:
//  Structure - The Result Of The Formation Of Production of Operations Constructor:
// * TotalCount1 - Number
// * ProcessedItemsCount - Number
// * OperationsAreCreated - Array of DocumentRef.ProductionOperation2_2
// * UpdatedOperations - Array of DocumentRef.ProductionOperation2_2
// * SpecialTerms - Array of DocumentRef.ProductionOperation2_2
Function ResultOfFormationOfProductionOfOperationsConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("TotalCount1", 0);
	Result.Insert("ProcessedItemsCount", 0);
	Result.Insert("OperationsAreCreated", New Array);
	Result.Insert("UpdatedOperations", New Array);
	Result.Insert("SpecialTerms", New Array);
	
	Return Result;
	
EndFunction


#EndRegion

#Region Private


// Status of operation in the form of a link
// 
// Parameters:
//  Status - String,EnumRef.ProductionOperationStatuses
// 
// Returns:
//  EnumRef.ProductionOperationStatuses
Function StatusOfOperationLink(Status) Export
	
	If TypeOf(Status) = Type("String") Then
		Return PredefinedValue("Enum.ProductionOperationStatuses."+Status);
	Else
		Return Status;
	EndIf;
	
EndFunction

// Initial Status of operation.
// 
// Parameters:
//  Object - DocumentObject.ProductionOperation2_2
// 
// Returns:
//  EnumRef.ProductionOperationStatuses
Function InitialStatusOfProductionOfOperation(Object) Export
	
	Return ?(Object.BasedOnMasterData,
		PredefinedValue("Enum.ProductionOperationStatuses.CreatedOn_"),
		PredefinedValue("Enum.ProductionOperationStatuses.BeingGenerated"));
	
EndFunction

// Confirmation cancellation of indicators.
// 
// Returns:
//  String
Function Confirmation_CancellationOfIndicators() Export
	Return "CancellationOfIndicators";
EndFunction

// Confirmation creation of an individual Operation.
// 
// Returns:
//  String
Function Confirmation_CreatingIndividualOperation() Export
	Return "CreatingIndividualOperation";
EndFunction

// States of operations that have been started or completed
// 
// Returns:
//  Array of EnumRef.OperationStates
Function ActiveStatesOfOperations() Export
	
	Result = New Array;
	
	Result.Add(PredefinedValue("Enum.OperationStates.Executed"));
	Result.Add(PredefinedValue("Enum.OperationStates.RolledBack"));
	Result.Add(PredefinedValue("Enum.OperationStates.IsSkipped"));
	Result.Add(PredefinedValue("Enum.OperationStates.UnderRevision"));
	Result.Add(PredefinedValue("Enum.OperationStates.UnderControl"));
	Result.Add(PredefinedValue("Enum.OperationStates.Running"));
	Result.Add(PredefinedValue("Enum.OperationStates.Assigned_"));
	
	Return Result;
	
EndFunction

#Region AttributesOfWorkCenter

// Attributes of the constructor work center.
// 
// Returns:
//  Structure - Attributes of the Work Center Constructor:
// * WorkCenterType - CatalogRef.WorkCenterTypes - 
// * WorkCenter - CatalogRef.WorkCenters - 
// * UseSetupSettings - Boolean - 
// * WorkTimeFactor - Number - 
// * ParallelLoad - Boolean - 
// * UnitOfMeasureOfLoad - String - 
Function AttributesOfWorkCenterConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("WorkCenterType", PredefinedValue("Catalog.WorkCenterTypes.EmptyRef"));
	Result.Insert("WorkCenter", PredefinedValue("Catalog.WorkCenters.EmptyRef"));
	Result.Insert("UseSetupSettings", False);
	Result.Insert("WorkTimeFactor", 1);
	Result.Insert("ParallelLoad", False);
	Result.Insert("UnitOfMeasureOfLoad", "");
	
	Return Result;
	
EndFunction

#EndRegion

#Region CalculationOfTimeOfProductionOperations

// Calculates the operation execution time based on the unit time and the time of the PO. 
// Unit time and PZ time must be in the same unit of measurement.
//
// Parameters:
//  Count			 - Number - the number of operations.
//  NumberOfPieces	 - Number - the number of operations per batch.
//  TimePerPiece		 - Number - unit operation time.
//  SetupTime				 - Number - preparatory and final time.
//  ParallelLoad - Boolean - indicates whether parallel loading of the RC type on which the operation is performed is allowed.
//  WorkTimeFactor - Number - the coefficient of change in the standard working time.
//  
// Returns:
//  Number - the time of the operation.
//
Function CalculateOperationTimeFromQuantity(Count, NumberOfPieces, TimePerPiece, SetupTime, ParallelLoad, WorkTimeFactor) Export
	
	Result = 0;
	
	If ParallelLoad Then
		Result = TimePerPiece * WorkTimeFactor + SetupTime;
	ElsIf NumberOfPieces <> 0 Then
		Result = TimePerPiece * Count * WorkTimeFactor / NumberOfPieces + SetupTime;
	EndIf;
	
	Return Result;
	
EndFunction

// Calculates the number of production operations based on time.
// Time, unit time, and PZ time must be in the same unit of measurement.
//
// Parameters:
//  Time				 - Number - the duration of the operation
//  TimePerPiece		 - Number - unit operation time.
//  SetupTime				 - Number - preparatory and final time.
//  NumberOfPieces	 - Number - the number of operations per batch.
//  WorkTimeFactor - Number - the coefficient of change in the standard working time.
// 
// Returns:
//  Number - the number of operations.
//
Function CalculateAmountOfOperationFromTime(Time, TimePerPiece, SetupTime, NumberOfPieces, WorkTimeFactor) Export
	
	If TimePerPiece <> 0 Then
		Return (Time - SetupTime) * NumberOfPieces / (TimePerPiece * WorkTimeFactor);
	Else
		Return 0;
	EndIf;
	
EndFunction

// Calculates the total operation execution time based on the unit time and time of the PO. 
// The unit of measurement for total time is set to the largest of the two units:
// the unit time and the PZ time.
//
// Parameters:
//  CurrentData - Arbitrary - collection containing the data required for the calculation:
//		* TimePerPiece - Number - time to complete the operation for a single unit / batch of items.
//		* TimePerPieceUnitOfMeasure - EnumRef.TimeMeasureUnits - unit of unit time.
//		* SetupTime - Number - preparatory and final time.
//		* SetupTimeUnitOfMeasure - EnumRef.TimeMeasureUnits - unit of measurement for the preparatory and final time.
//		* RunTime - Number - the total time of the operation.
//		* ExecutionTimeUnitOfMeasure - EnumRef.TimeMeasureUnits - unit of measurement for total time.
//		* ParallelLoad - Boolean - flag for parallel loading of the work center.
//		* WorkTimeFactor - Number - the coefficient of change in the standard working time.
//	UnitsOfBatchesOfProducts - Number - the number of units/batches of products produced.
//
Procedure CalculateTotalOperationTime(CurrentData, UnitsOfBatchesOfProducts) Export
	
	If Not CurrentData.ParallelLoad Then
		PartyTime = CurrentData.TimePerPiece * UnitsOfBatchesOfProducts;
	Else
		PartyTime = CurrentData.TimePerPiece;
	EndIf;
	
	SetupTime = CurrentData.SetupTime;
	
	PartyTime = ProductionPlanningClientServer.GetTimeInSeconds(PartyTime, CurrentData.TimePerPieceUnitOfMeasure);
	SetupTime     = ProductionPlanningClientServer.GetTimeInSeconds(SetupTime, CurrentData.SetupTimeUnitOfMeasure);
	
	ExecutionTimeUnitOfMeasure = UnitOfTotalTime(CurrentData);
	
	CurrentData.ExecutionTimeUnitOfMeasure = ExecutionTimeUnitOfMeasure;
	CurrentData.RunTime      = ProductionPlanningClientServer.GetTimeInUnit(
		PartyTime*CurrentData.WorkTimeFactor + SetupTime, ExecutionTimeUnitOfMeasure);
	
EndProcedure


// Returns a structure containing the data necessary for calculating the total time of operation execution.
// 
// Returns:
//   - Structure - data structure.
//
Function StructureOfCalculationOfTotalExecutionTime() Export
	
	Return New Structure(
					"TimePerPiece,
					|TimePerPieceUnitOfMeasure,
					|SetupTime,
					|SetupTimeUnitOfMeasure,
					|ParallelLoad,
					|RunTime,
					|ExecutionTimeUnitOfMeasure,
					|WorkTimeFactor");
	
EndFunction

Function UnitOfTotalTime(CurrentData)
	
	ThereIsPieceTime = ValueIsFilled(CurrentData.TimePerPiece) And ValueIsFilled(CurrentData.TimePerPieceUnitOfMeasure);
	ThereIsTimePZ = ValueIsFilled(CurrentData.SetupTime) And ValueIsFilled(CurrentData.SetupTimeUnitOfMeasure);
	
	If ThereIsPieceTime And ThereIsTimePZ Then
		
		If CurrentData.TimePerPieceUnitOfMeasure = CurrentData.SetupTimeUnitOfMeasure Then
			
			Result = CurrentData.TimePerPieceUnitOfMeasure;
			
		Else
			
			QuantityPiece = ProductionPlanningClientServer.GetTimeInSeconds(1, CurrentData.TimePerPieceUnitOfMeasure);
			PZValue = ProductionPlanningClientServer.GetTimeInSeconds(1, CurrentData.SetupTimeUnitOfMeasure);
			Result = ?(QuantityPiece>PZValue, CurrentData.TimePerPieceUnitOfMeasure, CurrentData.SetupTimeUnitOfMeasure);
			
		EndIf;
		
	Else
		
		Result = ?(ThereIsTimePZ,
			CurrentData.SetupTimeUnitOfMeasure,
			CurrentData.TimePerPieceUnitOfMeasure);
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region ExecutionAndControlOfProductionOperations

// Constructor of a new protocol entry
// 
// Parameters:
// NameOfEvent- String - Event name
// 
// Returns:
//  Structure - Record Protocol Constructor:
// * Date - Date
// * EmployeeResponsible - CatalogRef.Users
// * Event - EnumRef.RoutingOperationProtocolEvents
// * Count - Number
// * Comment - String
// * PreviousState - String
Function RecordProtocolConstructor(NameOfEvent = "") Export
	
	Result = New Structure;
	
	Event = PredefinedValue("Enum.RoutingOperationProtocolEvents.EmptyRef");
	PreviousState = "QuantityToPerform";
	
	If Not IsBlankString(NameOfEvent) Then
		
		If NameOfEvent = "Control"
			Or NameOfEvent = "SendForRevision"
			Or NameOfEvent = "DefectiveGoods" Then
			PreviousState = "FollowUp";
		ElsIf NameOfEvent = "PresentForControl" Then
			PreviousState = "QuantityUnderRevision";
		EndIf;
		
		Event = PredefinedValue(StrTemplate("Enum.RoutingOperationProtocolEvents.%1", NameOfEvent));
		
	EndIf;
	
	Result.Insert("Date",                Date(1,1,1));
	Result.Insert("Event",             Event);
	Result.Insert("EmployeeResponsible",       PredefinedValue("Catalog.Users.EmptyRef"));
	Result.Insert("Count",          0);
	Result.Insert("Comment",         "");
	Result.Insert("PreviousState", PreviousState);
	
	Return Result;
	
EndFunction

// Constructor for the structure of the protocol results
// 
// Parameters:
// Object - DocumentObject.ProductionOperation2_2
// InitializationByObjectOnly - Boolean - initialization only
// 
// Returns:
//  Structure - Structure of Results Constructor:
// * Count - Number
// * QuantityToPerform - Number
// * FollowUp - Number
// * QuantityUnderRevision - Number
// * DefectiveGoodsCount - Number
// * CountReal - Number
// * CountCanceled - Number
Function StructureOfResultsConstructor(Object = Undefined, InitializationByObjectOnly = False) Export
	
	Result = New Structure;
	
	Result.Insert("Count",            0);
	Result.Insert("QuantityToPerform", 0);
	Result.Insert("FollowUp",  0);
	Result.Insert("QuantityUnderRevision", 0);
	Result.Insert("DefectiveGoodsCount",        0);
	Result.Insert("CountCanceled",    0);
	Result.Insert("CountReal",        0);
	
	If Object <> Undefined Then
		
		If Not InitializationByObjectOnly Then
			FillPropertyValues(Result, Object);
		EndIf;
		
		Result.Count            = Object.Count;
		Result.QuantityToPerform = QuantityToPerform(Result);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the available quantity to be executed
// 
// Parameters:
//  Object - DocumentObject.ProductionOperation2_2
// 
// Returns:
//  Number
Function QuantityToPerform(Object) Export
	
	Result = Object.Count
		- Object.FollowUp
		- Object.QuantityUnderRevision
		- Object.DefectiveGoodsCount
		- Object.CountCanceled
		- Object.CountReal;
		
	Return ?(Result > 0, Result, 0);
	
EndFunction

// Determines whether any actions have been performed with the Operation that change its indicators
// 
// Parameters:
//  Object - FormDataStructure
// 
// Returns:
//  Boolean
Function ThereAreAccumulatedPerformanceIndicators(Object) Export
	
	Return Object.Protocol.Count() > 0
		Or Object.FollowUp > 0
		Or Object.QuantityUnderRevision > 0
		Or Object.DefectiveGoodsCount > 0
		Or Object.CountCanceled > 0
		Or Object.CountReal > 0;
	
EndFunction

// Text of the option of operation according to the standard
// 
// Parameters:
//  TechnicalProcess - CatalogRef.RouteSheets,CatalogRef.TechnologicalProcesses,CatalogRef.BillsOfMaterials
// 
// Returns:
//  String
Function TextFillingOptionAccordingToStandard(TechnicalProcess) Export
	
	Result = "";
	
	If TypeOf(TechnicalProcess) = Type("CatalogRef.RouteSheets") Then
		Result = NStr("vi = 'theo sơ đồ lộ trình';
						|ru = 'по маршрутной карте';
						|en = 'by route sheet'; fa = 'by route sheet';
						|it = 'per scheda di lavorazione';
						|pl = 'według karty technologicznej';
						|tr = 'Rotaya göre'");
	ElsIf TypeOf(TechnicalProcess) = Type("CatalogRef.TechnologicalProcesses") Then
		Result = NStr("vi = 'theo quy trình công nghệ';
						|ru = 'по технологическому процессу';
						|en = 'by technological process'; fa = 'by technological process';
						|it = 'by technological process';
						|pl = 'by technological process';
						|tr = 'teknolojik sürece göre'");
	ElsIf TypeOf(TechnicalProcess) = Type("CatalogRef.BillsOfMaterials") Then
		Result = NStr("vi = 'theo bảng kê chi tiết';
						|ru = 'по спецификации';
						|en = 'by bill of materials'; fa = 'by bill of materials';
						|it = 'per specifica';
						|pl = 'wg specyfikacji';
						|tr = 'ürün reçetesine göre'");
	Else
		Result = NStr("vi = 'theo danh mục';
						|ru = 'по НСИ';
						|en = 'by master data'; fa = 'by master data';
						|it = 'by master data';
						|pl = 'by master data';
						|tr = 'master veriye göre'");
	EndIf;
	
	Return Result;
	
EndFunction

Function ControlOptionsForIndividualOfOperation(CurrentValue = Undefined) Export
	
	Result = New Array;
	
	Result.Add(PredefinedValue("Enum.ManufacturingOperationControlOptions.NotRequired"));
	Result.Add(PredefinedValue("Enum.ManufacturingOperationControlOptions.Required2"));
	If CurrentValue = PredefinedValue("Enum.ManufacturingOperationControlOptions.RequiredForSubsequentOperations") Then
		Result.Add(CurrentValue);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
