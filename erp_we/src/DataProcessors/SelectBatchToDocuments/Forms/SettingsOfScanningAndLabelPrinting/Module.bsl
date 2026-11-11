
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ProductsServer.LoadSeriesScanModeSetting(ThisForm);
	
	If Parameters.Property("PrintToPrinter") Then
		PrintToPrinter = Parameters.PrintToPrinter;
	Else
		Items.PrintToPrinter.Visible = False;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	ShouldSaveSettings();
	ReturnStructure = New Structure;
	ReturnStructure.Insert("SeriesScanMode",SeriesScanMode);
	ReturnStructure.Insert("PrintToPrinter",PrintToPrinter);
	Close(ReturnStructure);
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	ProductsServer.SaveSeriesScanModeSetting(ThisForm);

EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion
