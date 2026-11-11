/////////////////////////////////////////////////////////////////////////
// The module "Document Statessclientserver" contains procedures and functions
// for working with the document State mechanism.
//
/////////////////////////////////////////////////////////////////////////

#Region Public

// Sets the visibility of the order State form elements.
// 
// Parameters:
//  Items - FormItems - 
//  NameOfElementState - String -
//  GroupNameStateIsCalculated - String -
//  ThereAreTasksToReflectStateOfOrders - Boolean - 
//
Procedure SetItemsVisibility(
			Items,
			NameOfElementState = "State",
			GroupNameStateIsCalculated = "GroupStateIsCalculated",
			ThereAreTasksToReflectStateOfOrders = False) Export
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		NameOfElementState,
		"Visible",
		Not ThereAreTasksToReflectStateOfOrders);
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items,
		GroupNameStateIsCalculated,
		"Visible",
		ThereAreTasksToReflectStateOfOrders);
	
EndProcedure

#EndRegion