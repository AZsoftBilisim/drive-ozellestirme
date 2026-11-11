///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
	
	AdditionalProperties.Insert("CurrentValue", Constants.UseSeparationByDataAreas.Get());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		
		Return;
		
	EndIf;
	
	// The following constants are mutually exclusive as they belong to different functional options:
	//
	// "IsStandaloneWorkplace" ("StandaloneWorkplace")
	// "DoNotUseSeparationByDataAreas" ("LocalMode")
	// "UseSeparationByDataAreas" ("SaaSOperations")
	//
	// The constant names are retained for backward compatibility.
	
	If Value Then
		
		Constants.DoNotUseSeparationByDataAreas.Set(False);
		If Common.IsStandaloneWorkplace() Then
			
			ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
			ModuleStandaloneMode.DisablePropertyIB();
			
		EndIf;
		
	ElsIf Common.IsStandaloneWorkplace() Then
		
		Constants.DoNotUseSeparationByDataAreas.Set(False);
		
	Else
		
		Constants.DoNotUseSeparationByDataAreas.Set(True);
		
	EndIf;
	
	If AdditionalProperties.CurrentValue <> Value Then
		
		RefreshReusableValues();
		
		If Value Then
			
			SSLSubsystemsIntegration.OnEnableSeparationByDataAreas();
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("vi = 'Lần gọi không hợp lệ đối tượng trên Client.';
			|ru = 'Недопустимый вызов объекта на клиенте.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf