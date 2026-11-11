
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SelectedRouteMapsAddress = Undefined;
	If Parameters.Property("SelectedRouteMapsAddress", SelectedRouteMapsAddress)
		And IsTempStorageURL(SelectedRouteMapsAddress) Then
		
		CommonClientServer.SetDynamicListFilterItem(
			List,
			"Ref",
			GetFromTempStorage(SelectedRouteMapsAddress),
			DataCompositionComparisonType.InList,,
			True);
		
	EndIf;
	
	List.QueryText = StrReplace(
		List.QueryText,
		"&TextSelectionOfRouteMaps",
		DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.TextOfMainRouteMapSelection());
	
	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.GlobalCommandsGroup;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

	//

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TheSetStatusInDevelopmentCommand(Command)
	
	SetStatus("UnderDevelopment", NStr("vi = 'Đang phát triển';
										|ru = 'В разработке';
										|en = 'Under development'; fa = 'در حال توسعه';
										|it = 'In elaborazione';
										|pl = 'W opracowaniu';
										|tr = 'Geliştirme aşamasında'"));
	
EndProcedure

&AtClient
Procedure TheSetStatusCommandIsActive(Command)
	
	SetStatus("Valid", NStr("vi = 'Có hiệu lực';
							|ru = 'Действует';
							|en = 'Valid'; fa = 'معتبر';
							|it = 'In vigore';
							|pl = 'Aktualne';
							|tr = 'Aktif'"));
	
EndProcedure

&AtClient
Procedure TheSetStatusClosedCommand(Command)
	
	SetStatus("Closed_", NStr("vi = 'Đã đóng';
								|ru = 'Закрыта';
								|en = 'Closed'; fa = 'بسته‌شده';
								|it = 'Chiusa';
								|pl = 'Zamknięta';
								|tr = 'Kapalı'"));
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtClient
Procedure SetStatus(StatusValue, StatusPresentation)

	HighlightedLinks = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List);
	
	ProductDataManagementClient.SetRouteMapStatus(StatusValue, StatusPresentation, HighlightedLinks);

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	Catalogs.RouteSheets.SetConditionalAppearanceOfRouteMapList(List.ConditionalAppearance);
	
EndProcedure

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

#EndRegion

#EndRegion