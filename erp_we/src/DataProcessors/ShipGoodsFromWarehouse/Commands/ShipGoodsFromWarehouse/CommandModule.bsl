
#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	// &PerformanceMeasurement
	SuffixOfOperation = SuffixOfKeyOfOperation();
	KeyOperation = StrTemplate("DataProcessor.ShipGoodsFromWarehouse.Command.ShipGoodsFromWarehouse.%1", SuffixOfOperation);
	PerformanceMonitorClient.TimeMeasurement(KeyOperation);
	
	OpenForm("DataProcessor.ShipGoodsFromWarehouse.Form.Form",,,,CommandExecuteParameters.Window);	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function SuffixOfKeyOfOperation()
	
	If GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving") Then
		Suffix = "UseAcceptableDeviation";
	Else
		Suffix = "NotUseAcceptableDeviation";
	EndIf;
	
	Return Suffix;
	
EndFunction

#EndRegion
