#Region FormCommandsEventHandlers

&AtClient
Procedure EnterArea(Command)

	RowData = Items.List.CurrentData;
	If RowData = Undefined Then
		ShowMessageBox(, "Not selected_5 area for entrance!", 180);
		Return;
	EndIf;
	
	ExitDataArea();
	LoginAreaAtServer(RowData.DataAreaAuxiliaryData);
	CompletionProcessing = New CallbackDescription(
		"ContinuingToEnterDataAreaAfterActionsBeforeStartingSystem", ThisObject);
	
	StandardSubsystemsClient.BeforeStart(CompletionProcessing);
	Notify("LoggedOnToDataArea");

EndProcedure

&AtClient
Procedure ExitArea(Command)

	ExitDataArea();
	Notify("LoggedOffFromDataArea");

EndProcedure

&AtClient
Procedure OpenEnterAreaForm(Command)

	RowData = Items.List.CurrentData;
	If RowData = Undefined Then
		ShowMessageBox(, "Not selected_5 area for entrance!", 180);
		Return;
	EndIf;
	
	OpenForm("CommonForm.LoginDataArea",
		New Structure("DataArea", RowData.DataAreaAuxiliaryData),
		ThisObject);

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ExitDataArea()

	ExitDataAreaOnServer();
	RefreshInterface();
	StandardSubsystemsClient.SetAdvancedApplicationCaption(True);

EndProcedure

&AtServer
Procedure LoginAreaAtServer(DataArea)

	SetPrivilegedMode(True);
	SaaSOperations.SignInToDataArea(DataArea);

EndProcedure

&AtServer
Procedure ExitDataAreaOnServer()
	
	SetPrivilegedMode(True);
	
	If Not SaaSOperations.SessionSeparatorUsage() Then
		Return;
	EndIf;
	
	// Restoring split desktop forms.
	StandardSubsystemsServerCall.HideDesktopOnStart(False);
	StandardSubsystemsServer.SetBlankFormOnBlankHomePage();
	SaaSOperations.SignOutOfDataArea();
	
EndProcedure

&AtClient
Procedure ContinuingToEnterDataAreaAfterActionsBeforeStartingSystem(Result, Context) Export
	
	If Result.Cancel Then
		ExitDataArea();
		Activate();
	Else
		CompletionProcessing = New CallbackDescription(
			"ContinuingToEnterDataAreaAfterActionsAtStartOfSystem", ThisObject);
		
		StandardSubsystemsClient.OnStart(CompletionProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure ContinuingToEnterDataAreaAfterActionsAtStartOfSystem(Result, Context) Export
	
	If Result.Cancel Then
		ExitDataArea();
	EndIf;
	
	RefreshInterface();
	Activate();
	
	Notify("LoggedOnToDataArea");
	
EndProcedure

#EndRegion