
#Region Public

// This procedure adds
// roles for operational planning to the local Manager profile description.
//
// Parameters:
//	ProfileDetails - See AccessManagement.NewAccessGroupProfileDescription
//
Procedure AddLocalDispatcherRoles(ProfileDetails) Export
	
	// Registers, reading.
	ProfileDetails.Roles.Add("ReadOperationTimetable2_2");
	
	// Registers, adding change.
	ProfileDetails.Roles.Add("AddEditOperationTimetable2_2");
	
	// Processing, reports.
	ProfileDetails.Roles.Add("UseOperationExecutionWhilePlanning");
	
EndProcedure

// Initialization of the background task for calculating the operational schedule in accordance with the parameters of the planning models.
//
// Parameters:
//  PlanningParameters - Structure - 
//	CalculationResults - Array - contains unique identifiers - addresses of temporary stores
//		where the result of the method will be placed.
//
Procedure CalculateScheduleOfModelsInBackground(PlanningParameters, CalculationResults) Export
	
	DataProcessors.ManufacturingExecutionSystem2_2.CalculateScheduleOfModelsInBackground(PlanningParameters, CalculationResults);
	
EndProcedure

// Initialization of the background task for calculating the operational schedule in accordance with the parameters of a specific planning model.
//
// Parameters:
//  PlanningParameters - Structure -
//  StorageAddress - UUID - address of the temporary storage where the result of the method will be placed.
//
Procedure CalculateModelScheduleInBackground(PlanningParameters, StorageAddress) Export
	
	DataProcessors.ManufacturingExecutionSystem2_2.CalculateModelScheduleInBackground(PlanningParameters, StorageAddress);
	
EndProcedure

// Filling in the table structure using register metadata.
//
// Parameters:
//	RegisterType_ - String
//	RegisterName - String
//	Table - ValueTable - a table whose structure should be filled in based on the register metadata.
//
Procedure FillInTableStructureByRegisterMetadata(Val RegisterType_, Val RegisterName, Table) Export
	
	Basis = Metadata[RegisterType_][RegisterName];
	
	For Each Dimension In Basis.Dimensions Do
		If Table.Columns.Find(Dimension.Name) = Undefined Then
			Table.Columns.Add(Dimension.Name, Dimension.Type);
		EndIf;
	EndDo;
	For Each Resource In Basis.Resources Do
		If Table.Columns.Find(Resource.Name) = Undefined Then
			Table.Columns.Add(Resource.Name, Resource.Type);
		EndIf;
	EndDo;
	For Each Attribute In Basis.Attributes Do
		If Table.Columns.Find(Attribute.Name) = Undefined Then
			Table.Columns.Add(Attribute.Name, Attribute.Type);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion