#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the name of the distribution database SCD. SKD is located in the layouts of this object.
// Parameters:
//	AllocationBase - EnumRef.TypesOfCostAllocatingBase - distribution base.
// Returns:
//	String - the name of the SKD.
Function NameOfDistributionBaseSchema(AllocationBase) Export
	
	If TypeOf(AllocationBase) = Type("String") Then
		Return AllocationBase;
	ElsIf Not TypesOfDistributionBasesByGroup("UsedMaterials").Find(AllocationBase) = Undefined Then
		Return "MaterialCosts";
	ElsIf Not TypesOfDistributionBasesByGroup("LaborCosts").Find(AllocationBase) = Undefined Then
		Return "LaborCosts";
	ElsIf Not TypesOfDistributionBasesByGroup("ManufacturedProduct").Find(AllocationBase) = Undefined Then
		Return "ManufacturedProduct";
	ElsIf Not TypesOfDistributionBasesByGroup("MaterialAndLaborCosts").Find(AllocationBase) = Undefined Then
		Return "MaterialAndLaborCosts";
	ElsIf Not TypesOfDistributionBasesByGroup("Goods").Find(AllocationBase) = Undefined Then
		Return "Goods";
	EndIf;
	
	Return "";
	
EndFunction

// Returns the value of the default distribution base type, depending on the purpose of the distribution rule
// Parameters:
//	AssignmentOfCostAllocationRules - EnumRef.AssignmentOfCostAllocationRules - appointments.
// Returns:
//	EnumRef.TypesOfCostAllocatingBase - the value of the default distribution base type.
Function DefaultValue(AssignmentOfCostAllocationRules) Export
	
	If AssignmentOfCostAllocationRules = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnInventoryCosts Then
		Return Enums.TypesOfCostAllocatingBase.GoodsQuantity;
	ElsIf AssignmentOfCostAllocationRules = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationOnManufacturingCostsByLots 
		Or AssignmentOfCostAllocationRules = Enums.AssignmentOfCostAllocationRules.ExpenseAllocationToProductionCost Then
		Return Enums.TypesOfCostAllocatingBase.ProductsQuantity;
	EndIf;
	
	Return Enums.TypesOfCostAllocatingBase.EmptyRef();
	
EndFunction

// Returns types of distribution bases depending on the specified group
// Parameters:
//	Group - String - The symbol of the guppa.
// Returns:
//	Array of EnumRef.TypesOfCostAllocatingBase - array of types of distribution bases.
Function TypesOfDistributionBasesByGroup(Group) Export
	
	TypesOfBases = New Array;
	
	If Group = "UsedMaterials" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.MaterialCostsAmount"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials"));
		
	EndIf;
		
	If Group = "LaborCosts" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds"));
		
	EndIf;

	If Group = "ManufacturedProduct" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantity"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeight"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolume"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCost"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases"));
		
	EndIf;

	If Group = "MaterialAndLaborCosts" Then
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts"));
		
	EndIf;
	
	If Group = "Goods" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.GoodsQuantity"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.GoodsVolume"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.GoodsWeight"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.InventoryCost"));
		
	EndIf;
	
	If Group = "Cost" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.MaterialCostsAmount"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCost"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts"));
		
	EndIf;
	
	If Group = "Count" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.QuantityOfSpecifiedMaterials"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.NumberOfWorksOfSpecifiedKinds"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantity"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases"));
		
	EndIf;
	
	If Group = "VolumeM3" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.VolumeOfSpecifiedMaterials"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolume"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases"));
		
	EndIf;
	
	If Group = "Weight" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.WeightOfSpecifiedMaterials"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeight"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases"));
		
	EndIf;
	
	If Group = "Sale" Then
		
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.SalesRevenue"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.GrossProfit"));
		TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.SaleCost"));
		
	EndIf;
	
	Return TypesOfBases;
	
EndFunction

#EndRegion

#Region Private

Function TypesOfDirectCostAllocationBases() Export
	
	TypesOfBases = New Array;
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantity"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsQuantityConsideringFutureReleases"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeight"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsWeightConsideringFutureReleases"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolume"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.ProductsVolumeConsideringFutureReleases"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.MaterialCostsAmount"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TotalPayrollExpenses"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.StandardRemunerationLevel"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.AmountOfMaterialAndLaborCosts"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCost"));
	TypesOfBases.Add(PredefinedValue("Enum.TypesOfCostAllocatingBase.TargetProductCostConsideringFutureReleases"));
	
	Return TypesOfBases;
	
EndFunction

#EndRegion

#EndIf
