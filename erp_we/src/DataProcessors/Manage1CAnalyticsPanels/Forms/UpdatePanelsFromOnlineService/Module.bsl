
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If TypeOf(Parameters.PanelData) <> Type("Array") Then
		Cancel = True;
		Return;
	EndIf;
	
	For Each Panel In Parameters.PanelData Do
		FillPropertyValues(InternetServicePanels.Add(), Panel);
	EndDo;
	
	Structure = Common.CommonSettingsStorageLoad(
		"DataProcessor.Manage1CAnalyticsPanels", "UpdatePanelsFromOnlineService");
	
	If TypeOf(Structure) = Type("Structure") Then
		For Each String In InternetServicePanels Do
			Structure.Property(String.Id, String.Check)
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit Then
		BeforeCloseAtServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersInternetServicePanels

&AtClient
Procedure InternetServicePanelsOnActivateField(Item)
	
	CurColumnName = Item.CurrentItem.Name;
	LinkToITS = Item.CurrentData.MoreOnITS;
	
	If CurColumnName = "InternetServicePanelsMoreOnITS" Then
		If ValueIsFilled(LinkToITS) Then
			FileSystemClient.OpenURL(LinkToITS);
		EndIf;
		Item.CurrentItem = Items[NameOfCurrentFormElement];
	Else
		NameOfCurrentFormElement = CurColumnName;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure LoadSelectedPanels(Command)
	
	Result = New Structure;
	
	For Each String In InternetServicePanels Do
		If String.Check Then
			Result.Insert(String.IdOfPanelVersion, StrSplit(String.VersionIdsOfAdditionalSources, ",", False));
		EndIf;
	EndDo;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure SelectAllCommand(Command)
	MarkTableElements(True);
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	MarkTableElements(False);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure BeforeCloseAtServer()
	
	Structure = New Structure;
	For Each String In InternetServicePanels Do
		Structure.Insert(String.Id, String.Check);
	EndDo;
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.Manage1CAnalyticsPanels", "UpdatePanelsFromOnlineService", Structure);
	
EndProcedure

&AtClient
Procedure MarkTableElements(Check) 
	For Each String In InternetServicePanels Do
		String.Check = Check;
	EndDo;
EndProcedure

#EndRegion
