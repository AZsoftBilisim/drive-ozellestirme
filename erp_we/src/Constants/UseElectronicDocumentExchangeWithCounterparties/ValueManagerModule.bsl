#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Common.SubsystemExists("ElectronicInteraction.ExchangeWithCounterparties.AutomaticReceiptOfEDI") Then
		GeneralModuleAutomaticReceiptEDI = Common.CommonModule("AutomaticReceiptOfEDI");
		GeneralModuleAutomaticReceiptEDI.WhenWritingConstantsUseEDExchange(Value);
	EndIf;
	
EndProcedure

#EndRegion

#EndIf