
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	// If the option is disabled, we will set the default values for the separation options according to the direction of activity.
	If Not ThisObject.Value = True Then
		
		If Constants.OptionOfGoodsAssignmentInInventoryConsumption.Get() =
			Enums.OptionsOfGoodsAssignmentInInventoryConsumption.LineOfBusiness Then
			
			Constants.OptionOfGoodsAssignmentInInventoryConsumption.Set(Enums.OptionsOfGoodsAssignmentInInventoryConsumption.InventoryConsumptionOrder);
			
		EndIf;
		
		If Constants.OptionOfGoodslAssignmentInTransfer.Get() =
			Enums.OptionsOfGoodslAssignmentInTransfer.LineOfBusiness Then
			
			Constants.OptionOfGoodslAssignmentInTransfer.Set(Enums.OptionsOfGoodslAssignmentInTransfer.AssignmentRecipient);
			
		EndIf;
		
		If Constants.OptionOfGoodsAssignmentInSales.Get() =
			Enums.OptionsOfGoodsAssignmentInSales.LineOfBusiness Then
			
			Constants.OptionOfGoodsAssignmentInSales.Set(Enums.OptionsOfGoodsAssignmentInSales.SalesOrder);
			
		EndIf;
		
		If Constants.OptionOfGoodsAssignmentInAssembly.Get() =
			Enums.OptionsOfGoodsAssignmentInAssembly.LineOfBusiness Then
			
			Constants.OptionOfGoodsAssignmentInAssembly.Set(Enums.OptionsOfGoodsAssignmentInAssembly.AssignmentOfAssembledKit);
			
		EndIf;
		
		
		If Constants.OptionOfAssignmentAtTransferToSubcontractor2_5.Get() =
			Enums.OptionsOfAssignmentDuringTransferToProcessing.LineOfBusiness Then
			Constants.OptionOfAssignmentAtTransferToSubcontractor2_5.Set(
				Enums.OptionsOfAssignmentDuringTransferToProcessing.SubcontractOrder);
		EndIf;
		If Constants.OptionOfMaterialAssignmentInProduction.Get() =
			Enums.OptionsOfMaterialAssignmentInProduction.LineOfBusiness Then
			
			If Constants.UseProductionManagement2_2.Get() Then
				Constants.OptionOfMaterialAssignmentInProduction.Set(Enums.OptionsOfMaterialAssignmentInProduction.ProductionStage);
			Else
				Constants.OptionOfMaterialAssignmentInProduction.Set(Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts);
			EndIf;
			
		EndIf;
		
		If Constants.OptionOfMaterialAssignmentInRM.Get() =
			Enums.OptionsOfMaterialAssignmentInRM.LineOfBusiness Then
			
			Constants.OptionOfMaterialAssignmentInRM.Set(Enums.OptionsOfMaterialAssignmentInRM.RMOrder);
			
		EndIf;
		
		If Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Get() =
			Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.LineOfBusiness Then
			
			Constants.OptionOfMaterialAssignmentWhenTransferringToProduction.Set(Enums.OptionsOfMaterialAssignmentWhenTransferringToProduction.AssignmentRecipient);
			
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndIf