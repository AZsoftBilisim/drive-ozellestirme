#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	GLAccountSettingsServer.ProcessingVerificationOfFillingInProductAccountingInvoices(ThisObject, Cancel, CheckedAttributes);
	Return; // The UT handler is empty
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If Cancel Or DataExchange.Load Then
		Return;
	EndIf;
	
	TMCommonUse.SyncKeys(ThisObject);
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	Result.Insert("Catalog.KeysForLotVendorAttributes", "DeletionMark");
	
	Return Result;
	
EndFunction

#EndRegion
#EndIf
