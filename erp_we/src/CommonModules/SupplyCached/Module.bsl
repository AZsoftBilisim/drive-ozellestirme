#Region Public

// Obtaining the inverted value of the constant to resolve the isolation of the goods from the need
// Returns:
//  Boolean - The inverted value of the constant resolves the isolation of the goods from the need.
Function ControlExcessOfSeparateProvision() Export
	
	SetPrivilegedMode(True);
	Return Not Constants.AllowAssignmentOfGoodsBeyondDemand.Get();
	
EndFunction

#EndRegion

#Region Private

// Returns a table of dependencies of software types on functional options and input documents.
//
// Returns:
//   ValueTable - Description of Dependencies:
//     * SupplyType - EnumRef.SupplyTypes - type of collateral (Purchase, Relocation, etc.).
//     * FunctionalOption - MetadataObjectFunctionalOption - the name of the functional option that controls the availability of the software type.
//     * AccessObject - MetadataObjectDocument - A document controlled by a functional option.
//     * PurposeUseKey - String - the key is to assign the use of needs assurance processing.
Function DescriptionOfAvailabilityOfSupplyTypes() Export 
	
	StringTypeDetails150 = Common.StringTypeDetails(150);
	DescriptionOfMetadataObjectType = New TypeDescription("MetadataObject");
	
	ReturnValue = New ValueTable;
	ReturnValue.Columns.Add("SupplyType", New TypeDescription("EnumRef.SupplyTypes"));
	ReturnValue.Columns.Add("FunctionalOption", DescriptionOfMetadataObjectType);
	ReturnValue.Columns.Add("AccessObject", DescriptionOfMetadataObjectType);
	ReturnValue.Columns.Add("PurposeUseKey", StringTypeDetails150);
	
	OrderKey = SupplyClientServer.KeyToPurposeOfUsingFormationOfOrdersAccordingToNeeds();
	KeyApplication = SupplyClientServer.KeyToPurposeOfUsingFormationOfApplicationsAccordingToNeeds();
	
	NewDescriptionOfSupplyType(
		ReturnValue,
		Enums.SupplyTypes.Purchase,
		Metadata.FunctionalOptions.UsePurchaseRequests,
		Metadata.Documents.PurchaseRequest,
		KeyApplication);
	
	NewDescriptionOfSupplyType(
		ReturnValue,
		Enums.SupplyTypes.Purchase,
		Metadata.FunctionalOptions.UsePurchaseOrders,
		Metadata.Documents.PurchaseOrder,
		OrderKey);
	
	NewDescriptionOfSupplyType(
		ReturnValue,
		Enums.SupplyTypes.Move,
		Metadata.FunctionalOptions.UseTransferOrders,
		Metadata.Documents.TransferOrder,
		OrderKey);
	NewDescriptionOfSupplyType(
		ReturnValue,
		Enums.SupplyTypes.Move,
		Metadata.FunctionalOptions.UseProductionManagement2_2,
		Metadata.Documents.OrderOfMaterialsForProduction,
		OrderKey);
	NewDescriptionOfSupplyType(
		ReturnValue,
		Enums.SupplyTypes.AssemblyDisassembly,
		Metadata.FunctionalOptions.UseAssemblyDisassemblyOrders,
		Metadata.Documents.ByAssemblyDisassemblyOrder,
		OrderKey);
	
	
	NewDescriptionOfSupplyType(
		ReturnValue,
		Enums.SupplyTypes.Production,
		Metadata.FunctionalOptions.UseProductionManagement2_2,
		Metadata.Documents.ProductionOrder2_2,
		OrderKey);
	NewDescriptionOfSupplyType(
		ReturnValue,
		Enums.SupplyTypes.ProductionByThirdParty,
		Metadata.FunctionalOptions.UseProductionByThirdParty2_5,
		Metadata.Documents.SubcontractOrder2_5,
		OrderKey);
	
	
	Return ReturnValue;
	
EndFunction

Function NewDescriptionOfSupplyType(TypeDescription, Type, FunctionalOption, AccessObject, PurposeUseKey)

	DetailsString = TypeDescription.Add();
	DetailsString.SupplyType = Type;
	DetailsString.FunctionalOption = FunctionalOption;
	DetailsString.AccessObject = AccessObject;
	DetailsString.PurposeUseKey = PurposeUseKey;
	
	Return DetailsString;

EndFunction

#EndRegion