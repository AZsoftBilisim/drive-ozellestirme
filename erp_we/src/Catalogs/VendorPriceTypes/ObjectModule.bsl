
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);	
	
EndProcedure

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	Currency = IncomeAndExpensesServer.GetCurrencyOfManagementAccounting(Currency);
	
EndProcedure

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf


