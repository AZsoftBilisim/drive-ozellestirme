#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then		
		
		Return;
		
	EndIf;
	
	ConstantValue = Constants.UseDigitalSignatureSaaS.Get();
	AdditionalProperties.Insert("CurrentValue", ConstantValue);
			
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then		
		
		Return;
		
	EndIf;
	
	If AdditionalProperties.CurrentValue <> Value Then
		
		RefreshReusableValues();
		
		If Value Then			
			DigitalSignatureSaaSOverridable.WhenEnablingCryptographyService();			
		EndIf;
		
	EndIf;
			
EndProcedure

#EndRegion

#EndIf