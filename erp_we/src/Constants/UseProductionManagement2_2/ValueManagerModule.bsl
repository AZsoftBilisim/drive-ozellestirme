#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// If the option is disabled, if production 2.1 is enabled, and the Cur option of separation in production is by stage or order.
	If Not ThisObject.Value And Constants.UseProductionManagement.Get()
		And (Constants.OptionOfMaterialAssignmentInProduction.Get() =
			Enums.OptionsOfMaterialAssignmentInProduction.ProductionOrder
			Or Constants.OptionOfMaterialAssignmentInProduction.Get() =
				Enums.OptionsOfMaterialAssignmentInProduction.ProductionStage) Then
		
		Constants.OptionOfMaterialAssignmentInProduction.Set(Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts);
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	ServiceConstants_ = New Structure;
	ServiceConstants_.Insert("UseOperationManagement",   False);
	ServiceConstants_.Insert("UseManufacturingExecutionSystem", False);
	ServiceConstants_.Insert("UseShiftTasks",             False);
	
	Catalogs.BusinessStructure.FillInManagementTechniquesUsed(ServiceConstants_);
	If Not AdditionalProperties.Property("UseProduction") Then
		
		ConstantValue = Value Or Constants.UseProductionManagement.Get();
		
		ValueManager = Constants.UseProduction.CreateValueManager();
		ValueManager.Read();
		If ValueManager.Value <> ConstantValue Then
			ValueManager.Value = ConstantValue;
			ValueManager.AdditionalProperties.Insert("UseProductionManagement2_2");
			ValueManager.Write();
		EndIf;
		
	EndIf;
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = Constants.UseProductionManagement2_2.Get();
	
	PropertyManager.SetPropertySetParameters("Catalog_ProductionLots", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_BackflushProduction", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_RecyclableWasteAllocation", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_ProductionOrder2_2", SetParameters);
	PropertyManager.SetPropertySetParameters("Document_ProductionStage2_2", SetParameters);
EndProcedure

#EndRegion

#EndIf
#EndIf
