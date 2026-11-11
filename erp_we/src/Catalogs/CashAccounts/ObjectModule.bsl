#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	// Skip the processing to ensure that the shape of the object is received when passing the "AutoTest" parameter.
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		If FillingData.Property("CashBook") And ValueIsFilled(FillingData.CashBook) Then
			FillingData.Insert("ThisIsCashAccountOfBranchOffice", 1);
		EndIf;
	
		If Not ValueIsFilled(CashCurrency) And FillingData.Property("Owner") Then
			CashCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Owner);
		EndIf;
		
	EndIf;
	
	CashServer.ProcessingCatalogFilling(ThisObject);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	If Not ThisIsCashAccountOfBranchOffice Then
		NotCheckedAttributeArray.Add("CashBook");
	EndIf;
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)

	If DataExchange.Load Then
		Return;
	EndIf;
	
	DeleteCashierIsProcessed = True;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	ThisIsBasic = GetFunctionalOption("BaseVersion");
	
	If Not GetFunctionalOption("UseMultipleCashAccounts") Then
		SetPrivilegedMode(True);
 		Query = New Query(
		"SELECT TOP 1
		|	CashAccounts.Ref
		|FROM
		|	Catalog.CashAccounts AS CashAccounts
		|WHERE
		|	CashAccounts.Ref <> &Ref
		|	AND NOT CashAccounts.DeletionMark");
		Query.SetParameter("Ref", Ref);
		If Not Query.Execute().IsEmpty() And Not ThisIsBasic Then
			Constants.UseMultipleCashAccounts.Set(True);
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
		
	RefreshReusableValues();
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	DetailsForRegistry = New Structure;
	DetailsForRegistry.Insert("DeletionMark");
	DetailsForRegistry.Insert("Description");
	DetailsForRegistry.Insert("Owner", "Organization");
	
	Result.Insert("Catalog.DocumentRegistryKeys", DetailsForRegistry);
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf