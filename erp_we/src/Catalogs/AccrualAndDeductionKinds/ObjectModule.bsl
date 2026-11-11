#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
 	NotCheckedAttributeArray = New Array();	
	
	//++WE 
	If GetFunctionalOption("PayrollAndHumanResourcesWE") Then

		CheckedAttributes.Add("AccrualMethod");
		CheckedAttributes.Add("PayCode");
		
		If ItIsADeduction Then
		
			NotCheckedAttributeArray.Add("AccrualMethod");
			NotCheckedAttributeArray.Add("PayCode");
		Else
		
			If AccrualMethod <> Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToDaysWorked
				And AccrualMethod <> Enums.AccrualMethodsPayrollAndHumanResources.BaseSalaryInProportionToHoursWorked
				And AccrualMethod <> Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerDay
				And AccrualMethod <> Enums.AccrualMethodsPayrollAndHumanResources.SpecifiedAmountPerHour Then
			
				NotCheckedAttributeArray.Add("PayCode");
		
			EndIf; 
		EndIf; 
		
	EndIf;
	
	//--WE
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes,NotCheckedAttributeArray);
	
	Return;

EndProcedure

#EndRegion

#Region Internal

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#EndIf
