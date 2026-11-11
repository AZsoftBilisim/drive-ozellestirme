#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If OfflinePeripheralsServerCallLocalization.ThisIsTypeOfOfflineEquipmentCashRegister(PeripheralType) Then
		NotCheckedAttributeArray.Add("UnitOfMeasureForWeight");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	AdditionalProperties.Insert(
		"RecordChanges",
		Not IsNew()
		And (UnitOfMeasureForWeight <> Common.ObjectAttributeValue(Ref, "UnitOfMeasureForWeight")));
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If AdditionalProperties.RecordChanges Then
		
		Query = New Query;
		
		QueryText =
		"SELECT
		|	Peripherals.InfobaseNode AS InfobaseNode,
		|	Peripherals.Ref AS Ref
		|FROM
		|	Catalog.Peripherals AS Peripherals
		|WHERE
		|	Peripherals.ExchangeRule = &ExchangeRule
		|	AND Peripherals.InfobaseNode <> VALUE(ExchangePlan.ExchangeWithOfflinePeripherals.EmptyRef)
		|";
		
		
		Query.Text = QueryText;
		Query.SetParameter("ExchangeRule", Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			ExchangePlans.RecordChanges(Selection.InfobaseNode, Metadata.InformationRegisters.ItemsIDOfPeripheralsOffline);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	Warehouse = SettingsValueCached.GetDefaultRetailWarehouse(Warehouse);
	
EndProcedure

#EndRegion

#EndIf
