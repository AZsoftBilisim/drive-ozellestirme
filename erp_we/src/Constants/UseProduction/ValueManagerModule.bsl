#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Constants.AssemblyDisassemblyAndItemsBatchesAreUsed.Set(
		(Constants.UseAssemblyDisassembly.Get()
			Or Constants.UseProduction.Get()
			Or Constants.UseProductionByThirdParty2_5.Get()
			Or False)
		And Constants.UseItemsBatch.Get());
	SetValueOfRelatedConstants = Not AdditionalProperties.Property("UseProductionManagement2_2");
	
	If SetValueOfRelatedConstants Then
		
		
		ConstantValue = Value;
		
		ValueManager = Constants.UseProductionManagement2_2.CreateValueManager();
		ValueManager.Read();
		If ValueManager.Value <> ConstantValue Then
			ValueManager.Value = ConstantValue;
			ValueManager.AdditionalProperties.Insert("UseProduction");
			ValueManager.Write();
		EndIf;
		
	EndIf;
	
	ProductionServer.SetUseOfCatalogProperties();
EndProcedure

#EndRegion

#EndIf
#EndIf