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

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
		
		If Parameters <> Undefined And Parameters.Property("OpenByScenario") Then
			StandardProcessing = False;
			InformationKind = Parameters.ContactInformationKind;
			SelectedForm = ContactInformationInputFormName(InformationKind);
			
			If SelectedForm = Undefined Then
				Raise  StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Loại địa chỉ chưa được xử lý: ""%1""';
						|ru = 'Не обрабатываемый тип адреса: ""%1""';
						|en = 'Unprocessable address type: ""%1""'; fa = 'Unprocessable address type: ""%1""';
						|it = 'Tipo di indirizzo non elaborabile: ""%1""';
						|pl = 'Nie przetwarzany typ adresu: ""%1""';
						|tr = 'İşlenemeyen adres türü: ""%1""'"), InformationKind);
			EndIf;
		EndIf;
		
#EndIf
	
EndProcedure

#EndRegion

#Region Private

// Returns a name of the form used to edit contact information type.
//
// Parameters:
//      InformationKind - EnumRef.ContactInformationTypes
//                    - CatalogRef.ContactInformationKinds -
//                      Requested type.
//
// Returns:
//      String - Form full name.
//
Function ContactInformationInputFormName(Val InformationKind)
	
	InformationType = ContactsManagerInternalCached.ContactInformationKindType(InformationKind);
	
	If InformationType = PredefinedValue("Enum.ContactInformationTypes.Address") Then
		
		AdvancedContactInformationInput = Metadata.DataProcessors.Find("AdvancedContactInformationInput");
		If AdvancedContactInformationInput = Undefined Then
			Return Metadata.DataProcessors.ContactInformationInput.Forms.AddressInput.FullName();
		Else
			Return AdvancedContactInformationInput.Forms.Find("AddressInput").FullName();
		EndIf;
		
	ElsIf InformationType = PredefinedValue("Enum.ContactInformationTypes.Phone")
		  Or InformationType = PredefinedValue("Enum.ContactInformationTypes.Fax") Then
		Return Metadata.DataProcessors.ContactInformationInput.Forms.PhoneInput.FullName();
	ElsIf InformationType = PredefinedValue("Enum.ContactInformationTypes.WebPage") Then
		Return Metadata.DataProcessors.ContactInformationInput.Forms.Website;
	
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndIf


