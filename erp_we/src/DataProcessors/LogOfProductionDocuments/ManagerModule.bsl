#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

Procedure AddReportCommands(ReportsCommands, Parameters) Export

EndProcedure

#EndRegion

#EndRegion

#Region Private

Procedure CreateHyperlinkToBackgroundTaskLayout(Parameters, StorageAddress) Export
	
	ToRegister = TMCommonUse.CreateHyperlinkToDesign(Parameters[0], Parameters[1]);
	PutToTempStorage(ToRegister, StorageAddress);
	
EndProcedure

#EndRegion

#EndIf