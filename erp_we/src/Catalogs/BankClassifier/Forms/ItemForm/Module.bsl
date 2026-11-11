///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.BankOperationsDiscontinuedPages.Visible = Object.OutOfBusiness Or Users.IsFullUser();
	Items.BankOperationsDiscontinuedPages.CurrentPage = ?(Users.IsFullUser(),
		Items.BankOperationsDiscontinuedCheckBoxPage, Items.BankOperationsDiscontinuedLabelPage);
		
	If Object.OutOfBusiness Then
		WindowOptionsKey = "OutOfBusiness";
		Items.BankOperationsDiscontinuedLabel.Title = BankManager.InvalidBankNote(Object.Ref);
	EndIf;

	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		Items.CountryCode.Visible = False;
	Else
		Items.Country.Visible = False;
	EndIf;
	
	If Common.IsMobileClient() Then
		Items.HeaderGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.DomesticPaymentsDetailsGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
		Items.InternationalPaymentsDetailsGroup.ItemsAndTitlesAlign = ItemsAndTitlesAlignVariant.ItemsRightTitlesLeft;
	EndIf;
	
	If Not ValueIsFilled(Country)
		And Not ValueIsFilled(Object.CountryCode)
		And Not ValueIsFilled(Object.Ref) Then
		Country = Constants.MainCountry.Get();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	If Common.SubsystemExists("StandardSubsystems.SaaSOperations.DataExchangeSaaS") Then
		ModuleStandaloneMode = Common.CommonModule("StandaloneMode");
		ModuleStandaloneMode.ObjectOnReadAtServer(CurrentObject, ReadOnly);
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		ModuleContactsManager = Common.CommonModule("ContactsManager");
		WorldCountryData = ModuleContactsManager.WorldCountryData(CurrentObject.CountryCode);
		If ValueIsFilled(WorldCountryData) Then
			Country = WorldCountryData.Ref;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then
		If ValueIsFilled(Country) Then
			CurrentObject.CountryCode = Common.ObjectAttributeValue(Country, "Code");
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion
