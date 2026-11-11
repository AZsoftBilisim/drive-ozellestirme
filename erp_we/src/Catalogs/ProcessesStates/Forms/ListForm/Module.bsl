
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Filter.Property("Parent")
	   And Parameters.Filter.Parent = PredefinedValue("Catalog.ProcessesStates.SalesProcesses") Then
		Items.List.Representation = TableRepresentation.List;
		Title = NStr("vi = 'Các giai đoạn trong quy trình bán hàng';
					|ru = 'Этапы процессов продаж';
					|en = 'Sales process steps'; fa = 'Sales process steps';
					|it = 'Fasi dei processi di vendita';
					|pl = 'Etapy procesów sprzedaży';
					|tr = 'Satış süreci aşamaları'");
	EndIf;

	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.FormCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	If Not AccessRight("Update", Metadata.Catalogs.ProcessesStates) Then
		TMCommonUseClientServer.SetFormItemProperty(Items, 
		                                                               "SettingOrderOfElementsIsNormal", 
		                                                               "Visible", 
		                                                                False, 
		                                                                True);
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion
