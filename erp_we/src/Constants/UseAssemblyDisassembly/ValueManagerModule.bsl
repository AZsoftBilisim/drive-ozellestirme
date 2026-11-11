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
	
EndProcedure

#EndRegion

#EndIf