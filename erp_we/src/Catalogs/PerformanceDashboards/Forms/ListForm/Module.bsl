
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	#If Not MobileStandaloneServer Then
		User = Users.CurrentUser();
	#Else
		InformationSecurityUserSUID = InfoBaseUsers.CurrentUser().UUID;
		User = Catalogs.Users.FindByAttribute("IBUserID",
																New UUID(InformationSecurityUserSUID));
		SetConditionalDesignBasedOnAvailabilityOfOfflineReport();
	#EndIf
	
	List.Parameters.SetParameterValue("CurrentUser", User);
	
	#If Not MobileStandaloneServer Then
		// StandardSubsystems.AttachableCommands
		TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(
			New DataCompositionField("Ref")).Type;
		PlacementParameters = AttachableCommands.PlacementParameters();
		PlacementParameters.Sources = TypesList;
		PlacementParameters.CommandBar = Items.List.ContextMenu;
		
		AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
		// End StandardSubsystems.AttachableCommands
	#EndIf

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	#If Not MobileClient Then
		Items.List.CommandBarLocation = FormItemCommandBarLabelLocation.None;
		CommandBarLocation = FormCommandBarLabelLocation.Auto;
	#Else
	If MainServerAvailable() = False Then
		Items.List.CommandBarLocation = FormItemCommandBarLabelLocation.None;
	EndIf;
	#EndIf
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	#If MobileClient Then
	StandardProcessing = False;
	If MainServerAvailable() = False Then
		OpenForm("InformationRegister.ReportsSnapshots.Form.ReportViewForm",
			New Structure("Dashboard", RowSelected));
	Else
		OpenForm("Report.PerformanceDashboard.Form.PerformanceDashboardForm", New Structure("Dashboard",
			RowSelected));
	EndIf;
	#EndIf
	
EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	ImageMarkedForDeletion = PutToTempStorage(PictureLib.ItemMarkedForDeletion);
	
	For Each String In Rows Do
		ListLine = String.Value.Data;
		If ListLine.DeletionMark Then
			ListLine.Icon = ImageMarkedForDeletion;
		Else
			ListLine.Icon = GetURL(String.Key, "Icon");
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	#If Not MobileClient Then
		AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
	#Else
		If MainServerAvailable() <> False Then
			Execute("AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List)");
		EndIf;
	#EndIf
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	#If Not MobileStandaloneServer Then
		AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
	#EndIf
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	#If Not MobileClient Then
		AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	#Else
		If MainServerAvailable() <> False Then
			Execute("AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List)");
		EndIf;
	#EndIf
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalDesignBasedOnAvailabilityOfOfflineReport()

	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.List.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ThereIsOfflineReport");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.InactiveLineColor);

EndProcedure

#EndRegion
