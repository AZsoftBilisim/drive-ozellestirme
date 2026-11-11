#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not GetFunctionalOption("UseMultiCountryAccounting") And Not ValueIsFilled(Country) Then
		Country = SettingsValueClientServerCached.MainCountry();
	EndIf;
	
	If RateType = Enums.TypesOfExcisableCategoryRates.AdValoremRate Then
		Currency = Catalogs.Currencies.EmptyRef();
		UnitOfMeasure = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	EndIf;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If RateType = Enums.TypesOfExcisableCategoryRates.AdValoremRate Then
		NotCheckedAttributeArray.Add("UnitOfMeasure");
		NotCheckedAttributeArray.Add("Currency");
	EndIf;
	
	If Not GetFunctionalOption("UseMultiCountryAccounting") Then
		NotCheckedAttributeArray.Add("Country");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	If RateType = Enums.TypesOfExcisableCategoryRates.AdValoremRate Then
		
		DataLock = New DataLock();
		DataLockItem = DataLock.Add("InformationRegister.RatesOfExcisableGoodsCategories");
		DataLockItem.SetValue("ExcisableGoodsCategory", Ref);
		DataLockItem.Mode = DataLockMode.Exclusive;
		DataLock.Lock();
		
		RecordSet = InformationRegisters.RatesOfExcisableGoodsCategories.CreateRecordSet();
		RecordSet.Filter.ExcisableGoodsCategory.Set(Ref);
		RecordSet.Read();
		
		If RecordSet.Selected() Then
			RecordSet.Clear();
			RecordSet.Write();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf