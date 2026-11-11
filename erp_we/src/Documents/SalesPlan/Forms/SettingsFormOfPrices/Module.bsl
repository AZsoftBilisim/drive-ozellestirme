
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("SettingsStructure") Then
		
		FillPropertyValues(ThisObject, Parameters.SettingsStructure);
		
		FillPropertyValues(ThisObject, SettingsStructure);
		
	EndIf;
	
	PricePopulationOption = "ItemsPrices";
	UsePriceType = True;
	
	If Not ValueIsFilled(PriceKind) Then
		PriceKind = PriceManagementSystemServerCall.PriceTypePriceList_();
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillInAndClose(Command)
	
	FillPropertyValues(SettingsStructure, ThisObject);
	
	EverythingIsFilled = CheckFilling();
	
	If EverythingIsFilled Then
		Close(SettingsStructure);
	EndIf;
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
