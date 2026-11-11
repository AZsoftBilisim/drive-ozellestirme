#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoRefresh") Then
		AutoRefresh = Parameters.AutoRefresh;
		If Parameters.Property("AutoRefreshPeriod") Then
			AutoRefreshPeriod = Parameters.AutoRefreshPeriod;
		EndIf;
	EndIf;
	
	If Parameters.Property("InMinutes") Then
		InMinutes = Parameters.InMinutes;
	Else
		InMinutes = False;
	EndIf;
	
	If InMinutes Then
		Items.InscriptionSEC.Title = NStr("vi = 'phút.';
											|ru = 'мин.';
											|en = 'min.'; fa = 'دقیقه';
											|it = 'мин.';
											|pl = 'min.';
											|tr = 'dk.'");
	EndIf;
	
	Items.AutoRefreshPeriod.Enabled = AutoRefresh;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure AutoUpdateWhenChangesOccur(Item)
	
	Items.AutoRefreshPeriod.Enabled = AutoRefresh;
	
	// Default value if the period has not yet been set.
	If InMinutes Then
		If AutoRefreshPeriod < 1 Then
			AutoRefreshPeriod = 15; // Minutes.
		EndIf;
	Else
		If AutoRefreshPeriod < 10 Then
			AutoRefreshPeriod = 900; // Seconds.
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure AutoRefreshPeriodOnChange(Item)
	
	If InMinutes Then
		If AutoRefreshPeriod < 1 Then
			AutoRefreshPeriod = 1; // At least 1 minute.
		EndIf;
	Else
		If AutoRefreshPeriod < 10 Then
			AutoRefreshPeriod = 10; // At least 10 seconds.
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Set(Command)
	
	Result = New Structure;
	Result.Insert("AutoRefresh", AutoRefresh);
	Result.Insert("AutoRefreshPeriod", AutoRefreshPeriod);
	Close(Result);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion
