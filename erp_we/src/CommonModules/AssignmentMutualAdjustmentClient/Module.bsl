////////////////////////////////////////////////////////////////////////////////////
// The module "Counter-correction of the assignment of the client", contains procedures and functions for
// working with the mechanism of counter-correction.
//
////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

//Returns parameters for the counter adjustment of the destination
//
// Returns:
//  Structure - with keys:
//   * OrderDocument            - DocumentRef.ProductionOrder2_2 - 
//   * Products     - CatalogRef.Products - 
//   * Characteristic   - CatalogRef.ItemsCharacteristics - 
//   * Warehouse            - CatalogRef.Warehouses - 
//   * Purpose       - CatalogRef.Assignments - 
//   * KeyProducts - UUID - 
//   * KeyLot       - UUID - 
//
Function AssignmentCounterAdjustmentParameters() Export
	
	Parameters = New Structure;
	Parameters.Insert("OrderDocument");
	Parameters.Insert("Products");
	Parameters.Insert("Characteristic");
	Parameters.Insert("Warehouse");
	Parameters.Insert("Purpose");
	Parameters.Insert("KeyProducts");
	Parameters.Insert("KeyLot");
	
	Return Parameters;
	
EndFunction

//Fills in the parameters of the counter adjustment of the destination
//
// Parameters:
//  Parameters            - See AssignmentCounterAdjustmentParameters
//  RawData       - ValueTableRow, Structure - 
//  AdditionalData - Structure, Undefined - 
//
Procedure FillInParametersOfCounterAdjustmentOfAssignment(
			Parameters, RawData, AdditionalData = Undefined) Export
	
	FillPropertyValues(Parameters, RawData);
	
	If AdditionalData <> Undefined Then
		FillPropertyValues(Parameters, AdditionalData);
	EndIf;
	
EndProcedure

//Returns a description of the open form Processing command.Fill in the corrected values.Form.Formobject
//
// Parameters:
//  Form                        - ClientApplicationForm - 
//  Data                       - ValueTableRow, Structure - 
//  CounterAdjustmentData - See AssignmentMutualAdjustmentServerCall.DestinationCounterAdjustmentData
//
// Returns:
//  Structure - with keys:
//   * Form - ClientApplicationForm - 
//   * ObjectsOfBases - Array -
//   * Purpose - CatalogRef.Assignments -
//   * QuantityToPassForAssignment - Number - 
//   * AddressOfGoods - See AssignmentMutualAdjustment.DestinationCounterAdjustmentData
//
Function CommandDetails(Form, Data, CounterAdjustmentData) Export
	
	ObjectsOfBases = New Array;
	ObjectsOfBases.Add(Data.OrderDocument);
	
	CommandDetails = New Structure;
	CommandDetails.Insert("Form",            Form);
	CommandDetails.Insert("ObjectsOfBases", ObjectsOfBases);
	CommandDetails.Insert("Purpose",       Data.Purpose);
	CommandDetails.Insert("QuantityToPassForAssignment", CounterAdjustmentData.QuantityToPassForAssignment);
	CommandDetails.Insert("AddressOfGoods",     CounterAdjustmentData.AddressOfGoods);
	
	Return CommandDetails;
	
EndFunction

#EndRegion