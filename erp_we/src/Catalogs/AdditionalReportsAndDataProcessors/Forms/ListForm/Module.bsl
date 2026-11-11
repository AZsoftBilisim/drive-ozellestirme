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
	
	If Parameters.ChoiceMode Then
		WindowOpeningMode = FormWindowOpeningMode.LockOwnerWindow;
	EndIf;

	If ValueIsFilled(Parameters.Title) Then
		AutoTitle = False;
		Title = Parameters.Title;
	EndIf;
	If Parameters.Representation <> Undefined Then
		Items.List.Representation = TableRepresentation[Parameters.Representation];
	EndIf;
	
	PublicationsKindsList = Items.PublicationFilter.ChoiceList;
	
	KindUsed = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used;
	KindDebugMode = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode;
	
	AvaliablePublicationKinds = AdditionalReportsAndDataProcessorsCached.AvaliablePublicationKinds();
	
	AllPublicationsExceptDisabled = New Array;
	AllPublicationsExceptDisabled.Add(KindUsed);
	If AvaliablePublicationKinds.Find(KindDebugMode) <> Undefined Then
		AllPublicationsExceptDisabled.Add(KindDebugMode);
	EndIf;
	If AllPublicationsExceptDisabled.Count() > 1 Then
		ArrayPresentation = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 hoặc %2';
				|ru = '%1 или %2';
				|en = '%1 or %2'; fa = '%1 or %2';
				|it = '%1 oppure %2';
				|pl = '%1 lub %2';
				|tr = '%1 veya %2'"),
			String(AllPublicationsExceptDisabled[0]),
			String(AllPublicationsExceptDisabled[1]));
		PublicationsKindsList.Add(1, ArrayPresentation);
	EndIf;
	For Each EnumerationValue In Enums.AdditionalReportsAndDataProcessorsPublicationOptions Do
		If AvaliablePublicationKinds.Find(EnumerationValue) <> Undefined Then
			PublicationsKindsList.Add(EnumerationValue, String(EnumerationValue));
		EndIf;
	EndDo;
	
	If Parameters.Filter.Property("Publication") Then
		PublicationFilter = Parameters.Filter.Publication;
		Parameters.Filter.Delete("Publication");
		If PublicationsKindsList.FindByValue(PublicationFilter) = Undefined Then
			PublicationFilter = Undefined;
		EndIf;
	EndIf;
	
	ChoiceList = Items.KindFilter.ChoiceList;
	ChoiceList.Add(1, NStr("vi = 'Chỉ báo cáo';
							|ru = 'Только отчеты';
							|en = 'Reports only'; fa = 'Reports only';
							|it = 'Solo i report';
							|pl = 'Tylko raporty';
							|tr = 'Yalnızca raporlar'"));
	ChoiceList.Add(2, NStr("vi = 'Chỉ bộ xử lý';
							|ru = 'Только обработки';
							|en = 'Data processors only'; fa = 'Data processors only';
							|it = 'Solo le elaborazioni';
							|pl = 'Tylko przetwarzanie';
							|tr = 'Yalnızca veri işlemcileri'"));
	For Each EnumerationValue In Enums.AdditionalReportsAndDataProcessorsKinds Do
		ChoiceList.Add(EnumerationValue, String(EnumerationValue));
	EndDo;
	
	AddlReportsKinds = New Array;
	AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.AdditionalReport);
	AddlReportsKinds.Add(Enums.AdditionalReportsAndDataProcessorsKinds.Report);
	
	List.Parameters.SetParameterValue("PublicationFilter", PublicationFilter);
	List.Parameters.SetParameterValue("KindFilter",        KindFilter);
	List.Parameters.SetParameterValue("AddlReportsKinds",  AddlReportsKinds);
	List.Parameters.SetParameterValue("AllPublicationsExceptDisabled", AllPublicationsExceptDisabled);
	
	InsertRight1 = AdditionalReportsAndDataProcessors.InsertRight1();
	CommonClientServer.SetFormItemProperty(Items, "Create",              "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "CreateMenu",          "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "CreateFolder",        "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "CreateMenuGroup",    "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "Copy",          "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "CopyMenu",      "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "LoadFromFile",     "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "ExportFromMenuFile", "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "ExportToFile",       "Visible", InsertRight1);
	CommonClientServer.SetFormItemProperty(Items, "ExportToFileMenu",   "Visible", InsertRight1);
	
	If Not Common.SubsystemExists("StandardSubsystems.BatchEditObjects")
		Or Not AccessRight("Update", Metadata.Catalogs.AdditionalReportsAndDataProcessors) Then
		Items.ChangeSelectedItems.Visible = False;
		Items.ChangeSelectedItemsMenu.Visible = False;
	EndIf;
	
	If Parameters.Property("AdditionalReportsAndDataProcessorsCheck") Then
		Items.Create.Visible = False;
		Items.CreateFolder.Visible = False;
	EndIf;
	
	Items.NoteServiceGroup.Visible = Common.DataSeparationEnabled();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	If Not ValueIsFilled(PublicationFilter) Then
		PublicationFilter = Settings.Get("PublicationFilter");
		List.Parameters.SetParameterValue("PublicationFilter", PublicationFilter);
	EndIf;
	KindFilter = Settings.Get("KindFilter");
	List.Parameters.SetParameterValue("KindFilter", KindFilter);
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure PublicationFilterOnChange(Item)
	DCParameterValue = List.Parameters.Items.Find("PublicationFilter");
	If DCParameterValue.Value <> PublicationFilter Then
		DCParameterValue.Value = PublicationFilter;
	EndIf;
EndProcedure

&AtClient
Procedure KindFilterOnChange(Item)
	DCParameterValue = List.Parameters.Items.Find("KindFilter");
	If DCParameterValue.Value <> KindFilter Then
		DCParameterValue.Value = KindFilter;
	EndIf;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Copy Then
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ExportToFile(Command)
	RowData = Items.List.CurrentData;
	If RowData = Undefined Or Not ItemSelected(RowData) Then
		Return;
	EndIf;
	
	ExportingParameters = New Structure;
	ExportingParameters.Insert("Ref",   RowData.Ref);
	ExportingParameters.Insert("IsReport", RowData.IsReport);
	ExportingParameters.Insert("FileName", RowData.FileName);
	AdditionalReportsAndDataProcessorsClient.ExportToFile(ExportingParameters);
EndProcedure

&AtClient
Procedure ImportReportDataProcessorsFile(Command)
	RowData = Items.List.CurrentData;
	If RowData = Undefined Or Not ItemSelected(RowData) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Key", RowData.Ref);
	FormParameters.Insert("ShowImportFromFileDialogOnOpen", True);
	OpenForm("Catalog.AdditionalReportsAndDataProcessors.ObjectForm", FormParameters);
EndProcedure

&AtClient
Procedure ChangeSelectedItems(Command)
	ModuleBatchObjectsModificationClient = CommonClient.CommonModule("BatchEditObjectsClient");
	ModuleBatchObjectsModificationClient.ChangeSelectedItems(Items.List);
EndProcedure

&AtClient
Procedure PublicationAvailable(Command)
	EditPublication("Used");
EndProcedure

&AtClient
Procedure PublicationDisabled(Command)
	EditPublication("TurnedOff");
EndProcedure

&AtClient
Procedure PublicationDebugMode(Command)
	EditPublication("DebugMode");
EndProcedure

#EndRegion

#Region Private

&AtClient
Function ItemSelected(RowData)
	If TypeOf(RowData.Ref) <> Type("CatalogRef.AdditionalReportsAndDataProcessors") Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh trên đối tượng chỉ định.
			|Chọn báo cáo hoặc bộ xử lý bổ sung.';
			|ru = 'Команда не может быть выполнена для указанного объекта.
			|Выберите дополнительный отчет или обработку.';
			|en = 'Cannot run the command for the object.
			|Please select an additional report or data processor.'; fa = 'Cannot run the command for the object.
			|Please select an additional report or data processor.';
			|it = 'Il comando non può essere completato per l''oggetto indicato.
			|Selezionate un report o un elaborazione aggiuntiva.';
			|pl = 'Polecenie nie może być wykonane dla wskazanego obiektu.
			|Wybierz raport dodatkowy lub przetwarzanie.';
			|tr = 'Komut, belirtilen nesne için yürütülemiyor.
			|Ek rapor veya veri işlemcisi seçin.'"));
		Return False;
	EndIf;
	If RowData.IsFolder Then
		ShowMessageBox(, NStr("vi = 'Không thể thực hiện lệnh cho nhóm.
			|Chọn báo cáo hoặc bộ xử lý bổ sung.';
			|ru = 'Команда не может быть выполнена для группы.
			|Выберите дополнительный отчет или обработку.';
			|en = 'Cannot run the command for a group.
			|Please select an additional report or data processor.'; fa = 'Cannot run the command for a group.
			|Please select an additional report or data processor.';
			|it = 'Il comando non può essere completato per il gruppo.
			|Selezionate un report aggiuntivo o un elaborazione.';
			|pl = 'Polecenie nie może być wykonane dla grupy.
			|Wybierz raport dodatkowy lub przetwarzanie.';
			|tr = 'Komut grup için yürütülemiyor.
			|Ek rapor veya veri işlemcisi seçin.'"));
		Return False;
	EndIf;
	Return True;
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	//
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Publication");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	//
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Publication");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	
EndProcedure

&AtClient
Procedure EditPublication(PublicationOption)
	
	ClearMessages();
	
	SelectedRows = Items.List.SelectedRows;
	RowsCount = SelectedRows.Count();
	If RowsCount = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn bất kỳ báo cáo (bộ xử lý) bổ sung nào';
								|ru = 'Не выбран ни один дополнительный отчет (обработка)';
								|en = 'No additional report or data processor is selected.'; fa = 'No additional report or data processor is selected.';
								|it = 'Non è stato selezionato nessun report aggiuntivo (elaborazione)';
								|pl = 'Nie wybrano żadnego raportu dodatkowego (przetwarzanie)';
								|tr = 'Ek rapor veya veri işlemcisi seçilmedi.'"));
		Return;
	EndIf;
	
	EditingPublication(PublicationOption);
	
	If RowsCount = 1 Then
		MessageText = NStr("vi = 'Đã thay đổi đăng tải báo cáo (bộ xử lý) bổ sung ""%1""';
							|ru = 'Изменена публикация дополнительного отчета (обработки) ""%1""';
							|en = 'Availability for the additional report or data processor has been changed: %1.'; fa = 'Availability for the additional report or data processor has been changed: %1.';
							|it = 'Modificata pubblicazione del report aggiuntivo (dell''elaborazione) ""%1""';
							|pl = 'Publikacja raportu dodatkowego (przetwarzania) ""%1"" uległa zmianie';
							|tr = '""%1"" ek raporun (veri işlemcisinin) yayını değiştirildi'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, String(SelectedRows[0]));
	Else
		MessageText = NStr("vi = 'Đã thay đổi đăng tải đối với báo cáo (bộ xử lý) bổ sung: %1';
							|ru = 'Изменена публикация у дополнительных отчетов (обработок): %1';
							|en = 'Availability for the additional reports or data processors have been changed: %1.'; fa = 'Availability for the additional reports or data processors have been changed: %1.';
							|it = 'Modificata pubblicazione dei report aggiuntivi (delle elaborazioni): %1';
							|pl = 'Publikacja raportów dodatkowych (przetwarzania): ""%1"" uległa zmianie';
							|tr = '""%1"" ek raporların (veri işlemcilerin) yayını değiştirildi'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, RowsCount);
	EndIf;
	
	ShowUserNotification(NStr("vi = 'Đã thay đổi đăng tải';
								|ru = 'Изменена публикация';
								|en = 'Availability changed'; fa = 'Availability changed';
								|it = 'Modificata pubblicazione';
								|pl = 'Publikacja uległa zmianie';
								|tr = 'Yayın değiştirildi'"),, MessageText);
	
EndProcedure

&AtServer
Procedure EditingPublication(PublicationOption)
	
	Query = New Query;
	Query.SetParameter("SelectedRows", Items.List.SelectedRows);
	Query.Text =
		"SELECT
		|	AdditionalReportsAndDataProcessors.Ref
		|FROM
		|	Catalog.AdditionalReportsAndDataProcessors AS AdditionalReportsAndDataProcessors
		|WHERE
		|	AdditionalReportsAndDataProcessors.Ref IN (&SelectedRows)
		|	AND NOT AdditionalReportsAndDataProcessors.IsFolder";
	SelectedRows = Query.Execute().Unload().UnloadColumn("Ref");
	
	BeginTransaction();
	Try
		For Each AdditionalReportOrDataProcessor In SelectedRows Do
			LockDataForEdit(AdditionalReportOrDataProcessor);
			
			Block = New DataLock;
			LockItem = Block.Add("Catalog.AdditionalReportsAndDataProcessors");
			LockItem.SetValue("Ref", AdditionalReportOrDataProcessor);
			Block.Lock();
		EndDo;
		
		For Each AdditionalReportOrDataProcessor In SelectedRows Do
			Object = AdditionalReportOrDataProcessor.GetObject();
			If PublicationOption = "Used" Then
				Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.Used;
			ElsIf PublicationOption = "DebugMode" Then
				Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.DebugMode;
			Else
				Object.Publication = Enums.AdditionalReportsAndDataProcessorsPublicationOptions.TurnedOff;
			EndIf;
			
			Object.AdditionalProperties.Insert("ListCheck");
			If Not Object.CheckFilling() Then
				ErrorPresentation = "";
				ArrayOfMessages = GetUserMessages(True);
				For Each UserMessage In ArrayOfMessages Do
					ErrorPresentation = ErrorPresentation + UserMessage.Text + Chars.LF;
				EndDo;
				
				Raise ErrorPresentation;
			EndIf;
			
			Object.Write();
		EndDo;
		
		UnlockDataForEdit();
		CommitTransaction();
	Except
		RollbackTransaction();
		UnlockDataForEdit();
		Raise;
	EndTry;
	Items.List.Refresh();
	
EndProcedure

#EndRegion
