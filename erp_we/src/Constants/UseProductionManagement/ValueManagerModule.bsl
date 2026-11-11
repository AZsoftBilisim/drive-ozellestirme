#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	SetPrivilegedMode(True);
	
	If Not AdditionalProperties.Property("UseProduction") Then
		
		ConstantValue = Value Or Constants.UseProductionManagement2_2.Get();
		
		ValueManager = Constants.UseProduction.CreateValueManager();
		ValueManager.Read();
		If ValueManager.Value <> ConstantValue Then
			ValueManager.Value = ConstantValue;
			ValueManager.AdditionalProperties.Insert("UseProductionManagement");
			ValueManager.Write();
		EndIf;
		
	EndIf;
	
	
	ProductionPlanning.CheckDisableRoutineTaskProductionScheduleCalculation();
	
	OptionOfAssignment = Constants.OptionOfMaterialAssignmentInProduction.Get();
	If ThisObject.Value And Not Constants.UseProductionManagement2_2.Get()
		And OptionOfAssignment <> Enums.OptionsOfMaterialAssignmentInProduction.LineOfBusiness
		And OptionOfAssignment <> Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts Then
		
		Constants.OptionOfMaterialAssignmentInProduction.Set(
			Enums.OptionsOfMaterialAssignmentInProduction.AssignmentOfProducts);
		
	EndIf;
	
	SetPrivilegedMode(False);
EndProcedure

#EndRegion

#EndIf
#EndIf
