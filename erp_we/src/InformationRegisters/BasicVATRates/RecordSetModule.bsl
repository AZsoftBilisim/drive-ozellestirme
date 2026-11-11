#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		Constants.MainCountry.CheckFilling();
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
		
	If DataExchange.Load Then
		Return;
	EndIf;

	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		For Each Record In ThisObject Do
			Record.Country = SettingsValueClientServerCached.MainCountry();
		EndDo;
	EndIf;

EndProcedure

#EndRegion

#EndIf