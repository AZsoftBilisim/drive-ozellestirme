#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Mode = Parameters.Mode;
		
	If Mode = "Validation" Then		
		Items.DecorationInscriptionVerification.Visible = True;
		Items.VerificationButtonGroup.Visible = True;
	Else
		Items.DecorationInscriptionSelection.Visible = True;
		Items.SelectionButtonGroup.Visible = True;
	EndIf;
		
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If UsedFormServer = UsedServer.Main Then
		// Peripherals
		If Source = "Peripherals" And IsInputAvailable() Then 
			
			ThereIsRawEvent = MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent();
			
			If EventName = "ScanData" And ThereIsRawEvent Then
				
				If Mode = "Validation" Then
					Close("Pick");
				Else
					Close("DoNotShip");
				EndIf;
				
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion 


#Region FormCommandsEventHandlers

&AtClient
Procedure Get_(Command)
	
	Close("Pick");
	
EndProcedure

&AtClient
Procedure ReducedAmount(Command)
	
	Close("ShipComplete");

EndProcedure

&AtClient
Procedure CompleteWithoutVerification(Command)
	
	Close("ShipWithoutVerification");
		
EndProcedure

&AtClient
Procedure ContinueChecking(Command)
	
	Close("Continue");
	
EndProcedure

&AtClient
Procedure CancelShipment(Command)
	
	Close("DoNotShip");
	
EndProcedure

&AtClient
Procedure OrderForSelection(Command)
	
	Close("ForPicking");

EndProcedure

&AtClient
Procedure ContinueSelection(Command)
	
	Close("Continue");
	
EndProcedure

#EndRegion