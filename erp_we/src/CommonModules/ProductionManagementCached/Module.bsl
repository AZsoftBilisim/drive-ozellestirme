////////////////////////////////////////////////////////////////////////////////
// Production management (repeat.isp.): contains procedures for production management.
// The module is part of the "Enterprise Management" subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region SubsystemSettings

// Determines whether the production schedule is used.
// 
// Returns:
//   Boolean - True if the production schedule is used.
//
Function TheProductionScheduleIsUsed() Export
	
	Return ProductionManagement.TheProductionScheduleIsUsed();
	
EndFunction

// Determines whether production resource planning is used
// 
// Returns:
//   Boolean - True if production resource planning is used.
//
Function PlanningByProductionResourcesIsUsed() Export
	
	Return Constants.UsePlanningByProductionResources.Get();
	
EndFunction

// Determines whether material resource planning is used
// 
// Returns:
//   Boolean - True if material resource planning is used.
//
Function PlanningByMaterialResourcesIsUsed() Export
	
	Return Constants.UsePlanningByMaterialResources.Get();
	
EndFunction

// Determines whether work center scheduling is used
// 
// Returns:
//   Boolean - True if work center scheduling is used
//
Function UseWorkCenterWorkPlanning() Export
	
	Return ProductionManagement.UseWorkCenterWorkPlanning();
	
EndFunction

#EndRegion

#Region Other

// Details of the manufacturing order
//
// Parameters:
//  Ref	 - DocumentRef.ProductionOrder2_2 - production order.
// 
// Returns:
//  Structure - the values of the key details of the production order.
//
Function ProductionOrderData(Ref) Export
	
	Result = Common.ObjectAttributesValues(
		Ref,
		"Number,
		|Date,
		|ProductionProcessType,
		|BusinessOperation,
		|LineOfBusiness,
		|OrderForActivity,
		|Organization,
		|Partner,
		|Contract,
		|ProductionScheduling,
		|AssignmentProducts,
		|Ref");
	
	Return Result;
	
EndFunction

// The value of the key details of the production order used in the formation of production stages.
//
// Parameters:
//  AssignmentProducts	 - CatalogRef.Assignments - assigning products from the order header.
// 
// Returns:
//  CatalogRef.LinesOfBusiness - the direction of activity of the destination of the products.
//
Function DirectionOfActivityPurposeOfProduction(AssignmentProducts) Export
	
	ReferencesArrray = New Array;
	ReferencesArrray.Add(AssignmentProducts);
	LinesOfBusiness = Catalogs.Assignments.AreasOfActivityOfAppointments(ReferencesArrray);
	Return LinesOfBusiness[AssignmentProducts];
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Other

Function DataForFillingNewProductionBatch(ReferenceOrder, AssignmentProducts) Export
	
	Return ProductionManagement.DataForFillingNewProductionBatch(ReferenceOrder, AssignmentProducts);
	
EndFunction

// Specifies the date from which the operation is used as a production order.
// 
// Returns:
//   Date - the moment from which the operation is used as a production order.
//
Function StartDateOfAccountingForOutputByOperations() Export
	
	SetPrivilegedMode(True);
	Result = Constants.StartDateOfAccountingForOutputByOperations.Get();
	SetPrivilegedMode(False);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion
