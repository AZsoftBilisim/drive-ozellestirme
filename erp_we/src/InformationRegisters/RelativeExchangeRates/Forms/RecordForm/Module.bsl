
#Region FormEventHandlers

&AtClient
Procedure AfterWrite(WriteParameters)
	Notify("Write_RelativeExchangeRates", WriteParameters, Record);
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not GetFunctionalOption("UseMultipleCurrencies") Then
		Record.BaseCurrency = Catalogs.Currencies.GetDefaultCurrency();
	EndIf;
	
EndProcedure

#EndRegion