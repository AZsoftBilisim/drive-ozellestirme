#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnCopy(CopiedObject)
	
	AccountNumber = "";
	DigitalRoubleAccountID = "";
	Description = "";
	
	CompaniesBankAccountsLocalization.OnCopy(ThisObject, CopiedObject);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	// Skip the processing to ensure that the shape of the object is received when passing the "AutoTest" parameter.
	If FillingData = "AutoTest_2" Then
		Return;
	EndIf;
	
	If Not IsFolder
		And (TypeOf(FillingData) <> Type("Structure") Or Not FillingData.Property("CashCurrency")) Then
		If Not ValueIsFilled(CashCurrency) And TypeOf(FillingData) = Type("Structure") And FillingData.Property("Owner") Then
			
			If TypeOf(FillingData.Owner) = Type("CatalogRef.Companies") Then
				CashCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(FillingData.Owner);
			ElsIf TypeOf(FillingData.Owner) = Type("ValueList") Then
				
				Companies = FillingData.Owner.UnloadValues();
				CurrenciesOfOrganizations = Common.ObjectsAttributeValue(Companies, "LocalAccountingCurrency");
					
				If FillingData.Owner.Count() = 1 Then
					CashCurrency = CurrenciesOfOrganizations[Companies[0]];
				EndIf;
				
			EndIf;
			
		EndIf;
	EndIf;
	
	CashServer.ProcessingCatalogFilling(ThisObject);
	
	CompaniesBankAccountsLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	AttributesNotToCheck = New Array;
	
	More = New Structure;
	More.Insert("UseMultipleCompanies", GetFunctionalOption("UseMultipleCompanies"));
	More.Insert("UseMultipleCurrencies", GetFunctionalOption("UseMultipleCurrencies"));
	More.Insert("CurrencyAccount", (ValueIsFilled(CashCurrency)
		And CashCurrency <> SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Owner)));
	More.Insert(
		"InternationalBankAccountDetails", GetFunctionalOption("InternationalBankAccountDetails"));
	More.Insert(
		"NationalBankAccountDetails", GetFunctionalOption("NationalBankAccountDetails"));
	More.Insert(
		"SettlementBankUsed",
		ValueIsFilled(TransferBank)
		Or ValueIsFilled(TransferBankBIC)
		Or ValueIsFilled(BankSWIFTCodeForPayments));
	
	FieldSettings = Catalogs.CompaniesBankAccounts.FormFieldSettings();
	ItemsProperties = CashClientServer.PropertiesOfFormElements(ThisObject, FieldSettings,,, More);
	CashServer.DisableVerificationOfObjectDetails(ItemsProperties, AttributesNotToCheck);
	ThisObject.AdditionalProperties.Insert("ItemsProperties", ItemsProperties);
	
	If Not DigitalRoubleAccount Then
		AttributesNotToCheck.Add("DigitalRoubleAccountID");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, AttributesNotToCheck);
	
	CompaniesBankAccountsLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If IsFolder Then
		Return;
	EndIf;
	
	AccountNumber = Upper(StrReplace(StrReplace(TrimAll(AccountNumber), " ", ""), ".", ""));
	
	If Not GetFunctionalOption("UseMultipleBankAccounts") Then
		SetPrivilegedMode(True);
		Query = New Query(
		"SELECT TOP 1
		|	CompaniesBankAccounts.Ref
		|FROM
		|	Catalog.CompaniesBankAccounts AS CompaniesBankAccounts
		|WHERE
		|	CompaniesBankAccounts.Ref <> &Ref");
		Query.SetParameter("Ref", Ref);
		If Not Query.Execute().IsEmpty() Then
			Constants.UseMultipleBankAccounts.Set(True);
		EndIf;
		SetPrivilegedMode(False);
	EndIf;
	
	If ThisObject.AdditionalProperties.Property("ItemsProperties") Then
		
		ExceptionAttributes = New Array;
		ExceptionAttributes.Add("MonthDisplayOption");
		ExceptionAttributes.Add("ManualBankDetailsChange");
		ExceptionAttributes.Add("TransferBankDetailsManualEdit");
		ExceptionAttributes.Add("Encoding");
		
		CashServer.ClearUnusedObjectDetails(
			ThisObject, ThisObject.AdditionalProperties.ItemsProperties, ExceptionAttributes);
	EndIf;
	
	RefreshReusableValues();
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());
	
	CompaniesBankAccountsLocalization.BeforeWrite(ThisObject, Cancel);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;

	If IsFolder Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);
	
	CompaniesBankAccountsLocalization.OnWrite(ThisObject, Cancel);
	
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
