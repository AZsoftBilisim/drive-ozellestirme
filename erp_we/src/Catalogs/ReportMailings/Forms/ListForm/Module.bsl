///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If ValueIsFilled(Parameters.Representation) Then
		Items.List.Representation = TableRepresentation[Parameters.Representation];
	EndIf;
	
	ErrorTextOnOpen = ReportMailing.CheckAddRightErrorText();
	If ValueIsFilled(ErrorTextOnOpen) Then
		Raise ErrorTextOnOpen;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		ModuleObjectsVersioning.OnCreateAtServer(ThisObject);
	EndIf;
	// End StandardSubsystems.ObjectsVersioning
	
	// Set dynamic list filters.
	CommonClientServer.SetDynamicListFilterItem(
		List, "ExecuteOnSchedule", False,
		DataCompositionComparisonType.Equal, , False,
		DataCompositionSettingsItemViewMode.Normal);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "SchedulePeriodicity", ,
		DataCompositionComparisonType.Equal, , False,
		DataCompositionSettingsItemViewMode.Normal);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "IsPrepared", False,
		DataCompositionComparisonType.Equal, , False,
		DataCompositionSettingsItemViewMode.Normal);
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Author", ,
		DataCompositionComparisonType.Equal, , False,
		DataCompositionSettingsItemViewMode.Normal);
	
	Items.List.ChoiceMode = Parameters.ChoiceMode;
	Items.List.ChoiceFoldersAndItems = ?(Parameters.ChoiceFoldersAndItems <> Undefined, Parameters.ChoiceFoldersAndItems, Items.List.ChoiceFoldersAndItems);
	Items.List.MultipleChoice = Parameters.MultipleChoice;
	Items.List.CurrentRow = ?(Parameters.CurrentRow <> Undefined, Parameters.CurrentRow, Items.List.CurrentRow);
	
	If Not AccessRight("Update", Metadata.Catalogs.ReportMailings) Then
		// Show only personal mailing. Groups and excess columns are hidden.
		Items.List.Representation = TableRepresentation.List;
		CommonClientServer.SetDynamicListFilterItem(List, "IsFolder", False, , , True,
			DataCompositionSettingsItemViewMode.Inaccessible);
	EndIf;
	
	ReportFilter = Parameters.Report;
	SetFilter(False);

	List.Parameters.SetParameterValue("DateEmpty", '00010101');
	List.Parameters.SetParameterValue("NewStatePresentation", NStr("vi = 'Mởi';
																	|ru = 'Новая';
																	|en = 'New'; fa = 'جدید';
																	|it = 'Nuovo';
																	|pl = 'New';
																	|tr = 'Yeni'"));
	List.Parameters.SetParameterValue("NotCompletedStatePresentation", NStr("vi = 'Chưa thực hiện';
																			|ru = 'Не выполнена';
																			|en = 'Not completed'; fa = 'تکمیل نشده';
																			|it = 'Non eseguito';
																			|pl = 'Nie wykonana';
																			|tr = 'Uygulanmadı'"));
	List.Parameters.SetParameterValue("CompletedWithErrorsStatePresentation", NStr("vi = 'Đã thực hiện một phần';
																					|ru = 'Выполнена частично';
																					|en = 'Partially completed'; fa = 'تکمیل جزئی';
																					|it = 'Выполнена частично';
																					|pl = 'Partially completed';
																					|tr = 'Kısmen tamamlandı'"));
	List.Parameters.SetParameterValue("CompletedStatePresentation", NStr("vi = 'Đã thực hiện';
																		|ru = 'Выполнена';
																		|en = 'Completed'; fa = 'تکمیل‌شده';
																		|it = 'Completata';
																		|pl = 'Completed';
																		|tr = 'Tamamlandı'"));
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects")
		Or Not AccessRight("Update", Metadata.Catalogs.ReportMailings) Then
		Items.ChangeSelectedItems.Visible = False;
		Items.ChangeSelectedItemsList.Visible = False;
	EndIf;
	
	If Not AccessRight("EventLog", Metadata) Then
		Items.MailingEvents.Visible = False;
	EndIf;
	
	ShowHintReportDistributionsCanBeAccelerated();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	SetListFilter(Settings);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StateFilterOnChange(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure ReportFilterOnChange(Item)
	SetFilter();
EndProcedure

&AtClient
Procedure EmployeeResponsibleFilterOnChange(Item)
	SetFilter();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListDrag(Item, DragParameters, StandardProcessing, String, Field)
	If String = PredefinedValue("Catalog.ReportMailings.PersonalMailings") Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandUpdate(ThisObject);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	ModuleBatchObjectsModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
	ModuleBatchObjectsModificationClient.ChangeSelectedItems(Items.List);
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.LastRun", Items.LastRun.Name);
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.SuccessfulStart", Items.SuccessfulStart.Name);

	ConditionalAppearanceItem = List.ConditionalAppearance.Items.Add();
	ConditionalAppearanceItem.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	// Unprepared report distribution.
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("IsFolder");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	DataFilterItem.LeftValue = New DataCompositionField("IsPrepared");
	DataFilterItem.ComparisonType = DataCompositionComparisonType.Equal;
	DataFilterItem.RightValue = False;
	DataFilterItem.Use = True;
	
	AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("TextColor");
	AppearanceColorItem.Value = Metadata.StyleItems.InaccessibleCellTextColor.Value;
	AppearanceColorItem.Use = True;
	
EndProcedure

&AtServer
Procedure SetFilter(ClearFixedFilters = True)
	
	If ClearFixedFilters Then
		List.Filter.Items.Clear();
	EndIf;
	FilterParameters = New Map();
	FilterParameters.Insert("WithErrors", StateFilter);
	FilterParameters.Insert("Report", ReportFilter);
	FilterParameters.Insert("Author", EmployeeResponsibleFilter);
	SetListFilter(FilterParameters);
EndProcedure

&AtServer
Procedure SetListFilter(FilterParameters)
	
	CommonClientServer.SetDynamicListFilterItem(List, "Author", FilterParameters["Author"],,,
		Not FilterParameters["Author"].IsEmpty());
	CommonClientServer.SetDynamicListFilterItem(List, "WithErrors", FilterParameters["WithErrors"] = "Incomplete",,, 
		FilterParameters["WithErrors"] <> "All" And ValueIsFilled(FilterParameters["WithErrors"]));
	CommonClientServer.SetDynamicListParameter(List, "ReportFilter", FilterParameters["Report"],
		ValueIsFilled(FilterParameters["Report"]) And Not FilterParameters["Report"].IsEmpty());
	
EndProcedure

&AtServer
Procedure ShowHintReportDistributionsCanBeAccelerated()
	
	If Common.FileInfobase() Or Common.DataSeparationEnabled() Then
		Items.GroupDistributionsCanBeAccelerated.Visible = False;
	Else
		If FileSystem.SharedDirectoryOfTemporaryFiles() = TempFilesDir() Then
			Items.GroupDistributionsCanBeAccelerated.Visible = True;
			If Users.IsFullUser() 
			   And Common.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
				Items.TitleDistributionAcceleration.Hyperlink = True;
				Items.TitleDistributionAcceleration.SetAction("Click", "Attachable_TitleDistributionAccelerationClick");
			EndIf;
		Else
			Items.GroupDistributionsCanBeAccelerated.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_TitleDistributionAccelerationClick(Item)
	If CommonClient.SubsystemExists("StandardSubsystems.ApplicationSettings") Then
		AppSettingsModuleClient = CommonClient.CommonModule("ApplicationSettingsClient");
		AppSettingsModuleClient.OpenCommonSettings();
	EndIf;
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	If Common.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommands = Common.CommonModule("AttachableCommands");
		ModuleAttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
	EndIf;
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClientServer = CommonClient.CommonModule("AttachableCommandsClientServer");
		ModuleAttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	EndIf;
EndProcedure

// End StandardSubsystems.AttachableCommands

#EndRegion
