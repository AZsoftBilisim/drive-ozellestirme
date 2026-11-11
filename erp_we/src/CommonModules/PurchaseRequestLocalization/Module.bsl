
#Region Public

#Region GenerationCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Supplements the Query Text describing the relationship between supplier orders and purchase requests.
// 
// Parameters:
//  QueryText - String - The Query Text to which the merge request will be added with the fields: "Order to the supplier" and "Order to purchase"
//  AvailableSelections - Structure:
//   * PurchaseRequest - String - The text for selection for purchase applications will be set.
//   * PurchaseOrder - String - The selection text for orders to suppliers will be set.
//   * OrderWasCreatedBasedOnRequest - String - The text will be set for selecting orders generated based on purchase requests.
//   * OrderPosted - String - The text will be set for selecting only completed orders.
Procedure CompleteQueryTextOfOrders(QueryText, AvailableSelections) Export
	
	
	Return;
	
EndProcedure

#EndRegion

