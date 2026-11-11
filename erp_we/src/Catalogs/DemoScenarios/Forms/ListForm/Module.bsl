#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing) 
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject, ,"List");
	// End StandardSubsystems.Core
	
	Items.FormUpload_ProcessDescriptions.Visible = AccessRight("Use", Metadata.DataProcessors.ProcessDetailsExport);
	Items.FormUploadProcessDescriptions.Visible = AccessRight("Use", Metadata.DataProcessors.ProcessDetailsImport);
		
	DemoScenarios.LoadSettingForFormDisplayOption(
		ThisObject,
		DemoScenarios.AvailableDisplayOptions(False),
		Metadata.Catalogs.DemoScenarios);
		
	VisibilityManagement(ThisObject);
	
EndProcedure

#EndRegion 

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If FormDisplayOption = "View" Then
		Cancel = True;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveUp(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	MoveItem(CurrentData.Ref, CurrentData.Parent, True);
	
EndProcedure

&AtClient
Procedure MoveDown(Command)
	
	CurrentData = Items.List.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	MoveItem(CurrentData.Ref, CurrentData.Parent, False);
	
EndProcedure

&AtClient
Procedure TranslateSelectedItems(Command)
	
	HighlightedScenarios = ScenariosSelectedForTranslation();
	If HighlightedScenarios.Count() > 0 Then 
		
		NotificationAfterClosingTransferForm = New CallbackDescription("AfterClosingTransferForm", ThisObject);
		
		FormParameters  = New Structure;
		FormParameters.Insert("TranslatedObjects", HighlightedScenarios);
		OpenForm("Catalog.DemoScenarios.Form.TranslateSeveralScenarios", FormParameters,
		             ThisObject,,,, NotificationAfterClosingTransferForm);
		
	Else
		
		ShowMessageBox(,NStr("vi = 'Để thực hiện dịch, cần chọn một hoặc một số kịch bản';
							|ru = 'Для выполнения перевода необходимо выбрать один или несколько сценариев';
							|en = 'To translate, select one or several scenarios'; fa = 'To translate, select one or several scenarios';
							|it = 'Для выполнения перевода необходимо выбрать один или несколько сценариев';
							|pl = 'To translate, select one or several scenarios';
							|tr = 'Çeviriyi gerçekleştirmek için bir veya daha fazla senaryo seçmeniz gerekmektedir'"), 20);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessAlbum(Command)
	
	RowsSelected = Items.List.SelectedRows;
	
	ReportScenarios = New Array;
	
	For Each RowSelected In RowsSelected Do
		
		If TypeOf(RowSelected) = Type("CatalogRef.DemoScenarios") 
			And ValueIsFilled(RowSelected) Then
			
			ReportScenarios.Add(RowSelected);
			
		EndIf;
		
	EndDo;
	
	If ReportScenarios.Count() = 0 Then
		
		WarningText = DemoScenariosClientServer.MessageTextIncorrectProcessAlbumParameters();
		ShowMessageBox(, WarningText);
		Return;
		
	EndIf;
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement(
	"Catalog.DemoScenarios.Form.ListForm.CreatingAlbumOfProcesses");
	
	FormParameters = New Structure;
	FormParameters.Insert("ReportScenarios",          ReportScenarios);
	FormParameters.Insert("DoNotCallPrintCommand", True);
	
	OpenForm("Catalog.DemoScenarios.Form.ProcessAlbum",
	             FormParameters, 
	             ThisObject,
	             True);
	
EndProcedure

&AtClient
Procedure SearchAndReplaceInScripts(Command)
	
	OpenForm("Catalog.DemoScenarios.Form.SearchAndReplaceInAllScenarios",, 
	             ThisObject,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#Region ChangingTheDisplayMode

&AtClient
Procedure SetViewOption(Command)
	
	SwitchDisplayOption(ThisObject, "View");
	
EndProcedure

&AtClient
Procedure SetEditOption(Command)
	
	SwitchDisplayOption(ThisObject, "Edit");
	
EndProcedure

#EndRegion 

#Region LoadingAndUnloading

&AtClient
Procedure Upload_ProcessDescriptions(Command)
	
	OpenForm("DataProcessor.ProcessDetailsExport.Form.Main",, ThisObject, ,,,,FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure UploadProcessDescriptions(Command)
	
	OpenForm("DataProcessor.ProcessDetailsImport.Form.Main",, ThisObject, ,,,,FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion


#EndRegion

#Region Private

&AtServer
Procedure MoveItem(Ref, Parent, Up = True)
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	DemoScenarios.Ref AS Ref
	|FROM
	|	Catalog.DemoScenarios AS DemoScenarios
	|WHERE
	|	DemoScenarios.Parent = &Parent
	|
	|ORDER BY
	|	DemoScenarios.Code";
	
	Query.Parameters.Insert("Parent", Parent);
	
	Table = Query.Execute().Unload();
	RowsCount = Table.Count();
	
	If RowsCount < 2 Then
		Return;
	EndIf;
	
	CurrentIndex = Table.IndexOf(Table.Find(Ref, "Ref"));
	
	If Up Then
		NewIndex = CurrentIndex - 1;
	Else
		NewIndex = CurrentIndex + 1;
	EndIf;
	
	If NewIndex < 0 Or NewIndex > RowsCount - 1 Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		TheFirstControl = Table[CurrentIndex].Ref.GetObject();
		TheFirstControl.Lock();
		
		TheSecondControl = Table[NewIndex].Ref.GetObject();
		TheSecondControl.Lock();

		FirstCode = TheFirstControl.Code;
		TheFirstControl.Code = TheSecondControl.Code;
		TheSecondControl.Code = FirstCode;
		
		TheFirstControl.Write();
		TheFirstControl.Unlock();
		TheSecondControl.Write();
		TheSecondControl.Unlock();
	
	CommitTransaction();
	
	Except
		
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Chưa thực hiện điều chuyển. Không thể phong tỏa kịch bản';
							|ru = 'Перемещение не выполнено. Не удалось заблокировать сценарий';
							|en = 'The item is not transferred. Cannot lock the scenario'; fa = 'The item is not transferred. Cannot lock the scenario';
							|it = 'Перемещение не выполнено. Не удалось заблокировать сценарий';
							|pl = 'The item is not transferred. Cannot lock the scenario';
							|tr = 'Taşıma başarısız oldu. Senaryo dosyası engellenemedi'");
		Common.MessageToUser(MessageText);
		
		Return;
		
	EndTry;
	
	Items.List.Refresh();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SwitchDisplayOption(Form, NewOption)
	
	SwitchingParameters = DemoScenariosClientServer.NewDisplayOptionSwitchingOptions();
	SwitchingParameters.Form                          = Form;
	SwitchingParameters.NewOption                   = NewOption;
	
	DemoScenariosClientServer.SwitchDisplayOption(SwitchingParameters);
	
	VisibilityManagement(Form);
	
EndProcedure 

&AtClientAtServerNoContext
Procedure VisibilityManagement(Form)
	
	Items = Form.Items;
	
	ThisIsEditingMode = (Form.FormDisplayOption = "Edit");
	ThisIsViewMode       = (Form.FormDisplayOption = "View"); 
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormCreate",             "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormCreateFolder",       "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormCopy",         "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormMoveUp",    "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormMoveDown",     "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "LinkSearchAndReplacementForm",  "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "FormTranslateSelected", "Visible", ThisIsEditingMode);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "Status",      "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "Comment", "Visible", ThisIsEditingMode);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuMoveItem",                       "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuCopy",                            "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuCreate",                                "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuLevelUp",                           "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuLevelDown",                            "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuSetDeletionMark",              "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListContextMenuSearchAndReplaceLinks",                     "Visible", ThisIsEditingMode);
	TMCommonUseClientServer.SetFormItemProperty(Items, "ListCatalogDemoScriptsTranslateHighlighted", "Visible", ThisIsEditingMode);
	
	DemoScenariosClientServer.MarkCommandsForSwitchingFormDisplayOption(Form);
	
EndProcedure

#Region Translation

&AtClient
Function ScenariosSelectedForTranslation()
	
	HighlightedScenarios = New ValueList;
	
	For Each SelectedRow In Items.List.SelectedRows Do
		
		If TypeOf(SelectedRow) = Type("CatalogRef.DemoScenarios") Then
			
			HighlightedScenarios.Add(SelectedRow);
			
		EndIf;
		
	EndDo;
	
	Return HighlightedScenarios;

EndFunction

&AtClient
Procedure AfterClosingTransferForm(Result, AdditionalParameters) Export
	
	If Result = Undefined 
		Or Result = DialogReturnCode.Cancel Then
		
		Return; 
		
	EndIf;
	
	Result.Insert("UUID", UUID);
	
	TranslateScripts(Result);

EndProcedure 

&AtClient
Procedure TranslateScripts(SearchSettings1)
	
	ClearMessages();
	
	TimeConsumingOperation = MakeTranslationUsingSettingsLongTermOperation(SearchSettings1,
	                                                                    UUID);
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		TranslationBySettingsEnd(TimeConsumingOperation, Undefined);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		
		CallbackOnCompletion = New CallbackDescription("TranslationBySettingsEnd", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Function MakeTranslationUsingSettingsLongTermOperation(SearchSettings1, Var_UUID)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Dịch các kịch bản minh họa';
														|ru = 'Перевод демонстрационных сценариев';
														|en = 'Translate demo scenarios'; fa = 'Translate demo scenarios';
														|it = 'Перевод демонстрационных сценариев';
														|pl = 'Translate demo scenarios';
														|tr = 'Demo senaryolarının çevirisi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DemoScenarios.TranslateDemoScripts",
	                                                       SearchSettings1, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure TranslationBySettingsEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then 
		ProcessEndOfTranslationAccordingToSettings(Result.ResultAddress, AdditionalParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessEndOfTranslationAccordingToSettings(Result, AdditionalParameters)

	Result = GetFromTempStorage(Result);
	
	NotificationText1 = NStr("vi = 'Dịch các kịch bản minh họa';
							|ru = 'Перевод демонстрационных сценариев';
							|en = 'Translate demo scenarios'; fa = 'Translate demo scenarios';
							|it = 'Перевод демонстрационных сценариев';
							|pl = 'Translate demo scenarios';
							|tr = 'Demo senaryolarının çevirisi'"); 
	
	If Result.Translated = 0 Then
		
		ExplanationText = NStr("vi = 'Chưa dịch kịch bản nào';
								|ru = 'Ни один сценарий не переведен';
								|en = 'No scenario is translated'; fa = 'No scenario is translated';
								|it = 'Ни один сценарий не переведен';
								|pl = 'No scenario is translated';
								|tr = 'Herhangi bir senaryo çevrilmedi'");
		
	Else
		
		ExplanationText = StrTemplate(NStr("vi = 'Đã dịch các kịch bản %1 trong số %2 ';
											|ru = 'Переведено сценариев %1 из %2';
											|en = 'Translated %1 out of %2 scenarios'; fa = 'Translated %1 out of %2 scenarios';
											|it = 'Переведено сценариев %1 из %2';
											|pl = 'Translated %1 out of %2 scenarios';
											|tr = '%2 üzerindeki %1 senaryoları çevrildi'"), Result.Translated, Result.TotalObjectCount);
		
	EndIf;
	
	ShowUserNotification(NotificationText1, , ExplanationText, PictureLib.Information32);
	
	For Each DataOfError In Result.Errors Do
		
		CommonClient.MessageToUser(DataOfError.ErrorText, DataOfError.Scenario);
		
	EndDo;
	
EndProcedure 


#EndRegion

#EndRegion