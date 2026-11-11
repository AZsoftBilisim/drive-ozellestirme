
#Region FormEventHandlers 

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	InitializeFormData();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ProcessUploadFileChange();
	InstallAssistantNavigator(ThisObject);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers 

&AtClient
Procedure AssistantNavigatorDecorationURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	ClearMessages();
	
	StandardProcessing = False;
	
	Cancel = False;
	
	If Cancel Then
		Return;
	EndIf;
	
	If FormattedStringURL = "GoToHomePage" Then
		
		GoToAssistantPage("PageStart");
		
	ElsIf FormattedStringURL = "GoToSettingsPage" Then 
		
		GoToAssistantPage("ImportSetupPage");
		
	ElsIf FormattedStringURL = "GoToGlossaryPage" Then 
		
		GoToAssistantPage("DownloadSettingsPageGlossary");
		
	ElsIf FormattedStringURL = "GoToCompareAndMergePage" Then 
		
		GoToAssistantPage("PageComparisonAssociation");
		
	ElsIf FormattedStringURL = "GoToResultsPage" Then
		
		GoToAssistantPage("PageLoaded"); 
		
	EndIf;
	
	InstallAssistantNavigator(ThisObject);
	
EndProcedure

#Region PageStart

&AtClient
Procedure ImportFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentFile", ImportFile);
	NotificationAfterProcessingSelection = New CallbackDescription("AfterProcessingSelectionOfUploadFileChange", ThisObject, AdditionalParameters);
	
	DemoScenariosClient.ProcessingStartOfFileSelection(ThisObject, 
	                                                          FileDialogMode.Open, 
	                                                          "ImportFile",
	                                                          False,
	                                                          NotificationAfterProcessingSelection);
	
EndProcedure

&AtClient
Procedure UploadMethodAsIsOnChange(Item)
	
	InstallAssistantNavigator(ThisObject);
	
EndProcedure 

&AtClient
Procedure MethodOfLoadingComparisonCombiningOnChange(Item)
	
	InstallAssistantNavigator(ThisObject);
	
EndProcedure 

&AtClient
Procedure ImportFileOnChange(Item)
	
	 ProcessUploadFileChange();
	
EndProcedure

#EndRegion

#Region ImportSetupPage

&AtClient
Procedure ChangesFilterStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ExcludedValues = New ValueList;
	
	If OptionOfSettingUpForSupport = 0 Then
		
		ExcludedValues.Add(PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.HasChanges"));
		
	Else
		
		ExcludedValues.Add(PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.ChangedByVendorAndInInfobase"));
		ExcludedValues.Add(PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.ChangedOnlyInInfobase"));
		ExcludedValues.Add(PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.ChangedOnlyByVendor"));
		
	EndIf;
	
	MultipleListSelectionStartSelection(ThisObject,
	                                     Item,
	                                     ChangesFilter,
	                                     Type("EnumRef.ComparisonStatusesOfProcessDetailsFiles"),
	                                     NStr("vi = 'Những thay đổi đã chọn';
												|ru = 'Выбранные изменения';
												|en = 'Selected changes'; fa = 'Selected changes';
												|it = 'Выбранные изменения';
												|pl = 'Selected changes';
												|tr = 'Seçili değişiklikler'"),
	                                     ExcludedValues);
	
EndProcedure 

&AtClient
Procedure ActionChoiceStart(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ExcludedValues = New ValueList;
	If ThisIsPartialUpload Then
		ExcludedValues.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Delete"));
		ExcludedValues.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.NotShouldDelete"));
	EndIf;
	
	MultipleListSelectionStartSelection(ThisObject,
	                                     Item,
	                                     ActionFilter,
	                                     Type("EnumRef.ActionOptionsWhileImportingProcessDetails"),
	                                     NStr("vi = 'Những thao tác đã chọn';
												|ru = 'Выбранные действия';
												|en = 'Selected actions'; fa = 'Selected actions';
												|it = 'Выбранные действия';
												|pl = 'Selected actions';
												|tr = 'Seçili eylemler'"),
	                                     ExcludedValues);
	
EndProcedure

&AtClient
Procedure ChangesFilterOnChange(Item)
	
	SetFilters();
	
EndProcedure

&AtClient
Procedure ActionFilterOnChange(Item)
	
	SetFilters();
	
EndProcedure

#EndRegion

#EndRegion 

#Region FormTableItemsEventHandlersLoadingSettingsProcessDescriptions

&AtClient
Procedure LoadingSettingsProcessDescriptionsOnActivateRow(Item)
	
	CreateSelectionListOfWhatToDo(Items.LoadingSettingsProcessDescriptionsWhatToDo, "LoadingSettingsProcessDescriptions");
	
EndProcedure

&AtClient
Procedure LoadingSettingsProcessDescriptionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "LoadingSettingsProcessDescriptionsWhatToDo" Then
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	If Field.Name = "LoadingSettingsProcessDescriptionsPresentation" Then
		
		WhenDoubleClickingOnPresentationOfScript(CurrentData, StandardProcessing);
		
	EndIf;
	
EndProcedure 

&AtClient
Procedure LoadingSettingsProcessDescriptionsOnActivateField(Item)
	
	WhenActivatingDownloadSettingsField(Item, "LoadingSettingsProcessDescriptions", "LoadingSettingsProcessDescriptions");
	
EndProcedure

&AtClient
Procedure LoadingSettingsProcessDescriptionsOnChange(Item)
	
	WhenChangingCollectionUploadSettings();
	
EndProcedure

#EndRegion 

#Region FormTableItemsEventHandlersDownloadSettingsGlossary

&AtClient
Procedure DownloadSettingsGlossarySelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "DownloadSettingsGlossaryWhatToDo" Then
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	If Field.Name = "DownloadSettingsGlossaryPresentation" Then
		
		WhenDoubleClickingOnGlossaryPresentation(CurrentData, StandardProcessing);
		
	EndIf;
	
EndProcedure 

&AtClient
Procedure DownloadSettingsGlossaryOnActivateRow(Item)
	
	CreateSelectionListOfWhatToDo(Items.DownloadSettingsGlossaryWhatToDo, "DownloadSettingsGlossary");
	
EndProcedure

&AtClient
Procedure DownloadSettingsGlossaryOnActivateField(Item)
	
	WhenActivatingDownloadSettingsField(Item, "DownloadSettingsGlossary", "DownloadSettingsGlossary");
	
EndProcedure

&AtClient
Procedure DownloadSettingsGlossaryOnChange(Item)
	
	WhenChangingCollectionUploadSettings();
	
EndProcedure

#EndRegion 

#Region FormTableItemsEventHandlersDownloadSettingsGlossarySelection

&AtClient
Procedure DownloadSettingsGlossarySelectionOnActivateField(Item)
	
	WhenActivatingDownloadSettingsField(Item, "DownloadSettingsGlossarySelection", "DownloadSettingsGlossarySelection");
	
EndProcedure

&AtClient
Procedure DownloadSettingsGlossarySelectionOnActivateRow(Item)
	
	CreateSelectionListOfWhatToDo(Items.DownloadSettingsGlossarySelectionWhatToDo, "DownloadSettingsGlossarySelection");
	
EndProcedure

&AtClient
Procedure DownloadSettingsGlossarySelectionSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "DownloadSettingsGlossarySelectionWhatToDo" Then
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	If Field.Name = "DownloadSettingsGlossarySelectionPresentation" Then
		
		WhenDoubleClickingOnGlossaryPresentation(CurrentData, StandardProcessing);
		
	EndIf
	
EndProcedure

&AtClient
Procedure DownloadSettingsGlossarySelectionOnChange(Item)
	
	WhenChangingCollectionUploadSettings();
	
EndProcedure

&AtClient
Procedure DownloadSettingsGlossarySelectionWhatToDoOnChange(Item)
	
	CurrentData = Items.DownloadSettingsGlossarySelection.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ChangeDataOfGlossaryUploadSettingsAfterChangingSelection(CurrentData);
	
	FillFilterTable();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLoadingSettingsProcessDescriptionsSelection

&AtClient
Procedure LoadingSettingsProcessDescriptionsSelectionSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "LoadingSettingsProcessDescriptionsSelectionWhatToDo" Then
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	If Field.Name = "LoadingSettingsProcessDescriptionsSelectionPresentation" Then
		
		WhenDoubleClickingOnPresentationOfScript(CurrentData, StandardProcessing);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadingSettingsProcessDescriptionsSelectionOnActivateField(Item)
	
	WhenActivatingDownloadSettingsField(Item, "LoadingSettingsProcessDescriptionsSelection", "LoadingSettingsProcessDescriptionsSelection");
	
EndProcedure 

&AtClient
Procedure LoadingSettingsProcessDescriptionsSelectionOnActivateRow(Item)
	
	CreateSelectionListOfWhatToDo(Items.LoadingSettingsProcessDescriptionsSelectionWhatToDo, "LoadingSettingsProcessDescriptionsSelection");
	
EndProcedure 

&AtClient
Procedure LoadingSettingsProcessDescriptionsSelectionWhatToDoOnChange(Item)
	
	CurrentData = Items.LoadingSettingsProcessDescriptionsSelection.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ChangeDataLoadingSettingsProcessDescriptionsAfterChangingSelection(CurrentData);
	
	SetFilters();
	
EndProcedure 

&AtClient
Procedure LoadingSettingsProcessDescriptionsSelectionOnChange(Item)
	
	WhenChangingCollectionUploadSettings();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersComparisonAssociation

&AtClient
Procedure ComparisonAssociationSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	If Field.Name = "ComparisonAssociationPresentation" Then
		
		WhenDoubleClickingOnPresentationOfScript(CurrentData, StandardProcessing);
		
	ElsIf Field.Name =  "ComparisonAssociationUploadFileDirectory" Then
		
		If Not DemoScenariosClientServer.FolderOnDiskExists(CurrentData.UploadFileDirectory) Then
			Return;
		EndIf;
		
		FileSystemClient.OpenExplorer(CurrentData.UploadFileDirectory);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ComparisonAssociationNameOfFileToUploadStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CurrentData = Items.ComparisonAssociation.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	AttributeData = New Structure;
	AttributeData.Insert("TabularSectionName",   "ComparisonAssociation");
	AttributeData.Insert("String_Id", CurrentData.GetID());
	AttributeData.Insert("AttributeName",        "FileToUpload");
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentData", CurrentData);
	NotificationAfterProcessingSelection = New CallbackDescription("AfterProcessingSelectionOfResultingFile", ThisObject, AdditionalParameters);
	
	DemoScenariosClient.ProcessingStartOfFileSelection(ThisObject, 
	                                                          FileDialogMode.Open, 
	                                                          AttributeData,
	                                                          False,
	                                                          NotificationAfterProcessingSelection, 
	                                                          CurrentData.UploadFileDirectory);

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers 

&AtClient
Procedure ToImport(Command)
	
	SetActionOption(Command.Name);
	
EndProcedure

&AtClient
Procedure NotToImport(Command)
	
	SetActionOption(Command.Name);
	
EndProcedure

&AtClient
Procedure CompareAndMerge(Command)
	
	SetActionOption(Command.Name);
	
EndProcedure

&AtClient
Procedure ShouldDelete(Command)
	
	SetActionOption(Command.Name);
	
EndProcedure

&AtClient
Procedure NotShouldDelete(Command)
	
	SetActionOption(Command.Name);
	
EndProcedure

&AtClient
Procedure UploadPathsToMergedFiles(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(PathMaskForMergedFiles) Then
		
		CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ ra mẫu tìm kiếm tệp kết quả';
										|ru = 'Не указана маска поиска результирующих файлов';
										|en = 'The search mask of the resulting files is not specified'; fa = 'The search mask of the resulting files is not specified';
										|it = 'Не указана маска поиска результирующих файлов';
										|pl = 'The search mask of the resulting files is not specified';
										|tr = 'Ortaya çıkan dosyaların arama maskesi belirtilmedi'"),, "PathMaskForMergedFiles");
		
		Return;
		
	EndIf;
	
	FindMergedFilesByMask();
	
EndProcedure 

&AtClient
Procedure Next(Command)
	
	NavigateThroughPages(Command);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	NavigateThroughPages( Command);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

#EndRegion 

#Region Private

#Region InitializeForm

&AtServer
Procedure SetConditionalAppearance()
	
	FontHyperlink = StyleFonts.FontHyperlink;
	ConditionalAppearance.Items.Clear();
	
	ValuesHaveChanges = New ValueList;
	ValuesHaveChanges.Add(Enums.ComparisonStatusesOfProcessDetailsFiles.HasChanges);
	ValuesHaveChanges.Add(Enums.ComparisonStatusesOfProcessDetailsFiles.ChangedByVendorAndInInfobase);
	ValuesHaveChanges.Add(Enums.ComparisonStatusesOfProcessDetailsFiles.ChangedOnlyInInfobase);
	ValuesHaveChanges.Add(Enums.ComparisonStatusesOfProcessDetailsFiles.ChangedOnlyByVendor);
	
#Region LoadingSettingsProcessDescriptionsStatusOfFiles
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptions.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NoChanges;
	
	Item.Appearance.SetParameterValue("Text", ""); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptions.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValuesHaveChanges;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font", FontHyperlink); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptions.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightCoral);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptions.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink);
	
#EndRegion
	
#Region LoadingSettingsProcessDescriptionsWhatToDo
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptions.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.NotToImport;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptions.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.ToImport;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptions.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.Union;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptions.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.Delete;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightCoral); 
	
#EndRegion

#Region LoadingSettingsProcessDescriptionsSelectionStatusOfFiles
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsSelectionStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptionsSelection.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NoChanges;
	
	Item.Appearance.SetParameterValue("Text", ""); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsSelectionStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptionsSelection.StatusOfFiles");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValuesHaveChanges;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsSelectionStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptionsSelection.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightCoral);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsSelectionStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptionsSelection.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink);
	
#EndRegion

#Region LoadingSettingsProcessDescriptionsSelectionWhatToDo
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsSelectionWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptionsSelection.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.NotToImport;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsSelectionWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptionsSelection.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.ToImport;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsSelectionWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptionsSelection.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.Union;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("LoadingSettingsProcessDescriptionsSelectionWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("LoadingSettingsProcessDescriptionsSelection.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.Delete;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightCoral); 
	
#EndRegion

#Region DownloadSettingsGlossaryStatusOfFiles
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossaryStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossary.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NoChanges;
	
	Item.Appearance.SetParameterValue("Text", ""); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossaryStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossary.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValuesHaveChanges;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossaryStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossary.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightCoral);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossaryStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossary.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink);
	
#EndRegion

#Region DownloadSettingsGlossarySelectionStatusOfFiles
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossarySelectionStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossarySelection.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NoChanges;
	
	Item.Appearance.SetParameterValue("Text", ""); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossarySelectionStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossarySelection.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.InList;
	ItemFilter.RightValue = ValuesHaveChanges;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossarySelectionStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossarySelection.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInImport;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightCoral);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossarySelectionStatusOfFiles");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossarySelection.StatusOfFiles");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	Item.Appearance.SetParameterValue("Font",      FontHyperlink);
	
#EndRegion

#Region DownloadSettingsGlossaryWhatToDo
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossaryWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossary.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.NotToImport;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossaryWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossary.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.ToImport;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossaryWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossary.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.Union;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossaryWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossary.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.Delete;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightCoral); 
	
#EndRegion

#Region DownloadSettingsGlossarySelectionWhatToDo
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossarySelectionWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossarySelection.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.NotToImport;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument); 
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossarySelectionWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossarySelection.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.ToImport;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.Seagreen);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossarySelectionWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossarySelection.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.Union;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("DownloadSettingsGlossarySelectionWhatToDo");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DownloadSettingsGlossarySelection.WhatToDo");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ActionOptionsWhileImportingProcessDetails.Delete;
	
	Item.Appearance.SetParameterValue("TextColor", WebColors.LightCoral); 
	
#EndRegion

EndProcedure

&AtServer
Procedure InitializeFormData()
	
	Items.WizardPages.CurrentPage                       = Items.PageStart; 
	Items.PagesFooter.CurrentPage                          = Items.ClickNextPage;
	
	ReadInformationAboutSupportSettingsInCurDatabase();
	
EndProcedure

&AtServer
Procedure ReadInformationAboutSupportSettingsInCurDatabase()
	
	ReadingResult = DemoScenarios.ResultOfReadingProcessDescriptionConstantsOnSupport(); 
	
	TextIsOnSupport = "";
	
	If Not IsBlankString(ReadingResult.DataOfConfiguration) 
		And Not IsBlankString(ReadingResult.Vendor) Then
		
		TextIsOnSupport = DemoScenariosClientServer.DeliveryDescriptionText(ReadingResult.DataOfConfiguration, ReadingResult.Vendor);
		
	EndIf;
	
	If IsBlankString(TextIsOnSupport) Then 
		
		ExplanationText = StringFunctions.FormattedString("<span style=""color: NoteText "">%1</span>",
		                                                              NStr("vi = 'Không có thông tin hỗ trợ trong cơ sở thông tin. Sẽ không thể thay đổi thông tin';
																			|ru = 'Информация о поддержке в текущей базе отсутствует. Она изменена не будет';
																			|en = 'The support information is missing in the current infobase. It will not be changed'; fa = 'The support information is missing in the current infobase. It will not be changed';
																			|it = 'Информация о поддержке в текущей базе отсутствует. Она изменена не будет';
																			|pl = 'The support information is missing in the current infobase. It will not be changed';
																			|tr = 'Mevcut veri tabanında destek hakkında bilgi bulunmamaktadır. Değiştirilmeyecektir'"));
		
	Else
		
		ExplanationText = StringFunctions.FormattedString("<span style=""color: NoteText "">%1 : <b>%2</b></span>",
		                                                        NStr("vi = 'Vẫn còn hỗ trợ mô tả quy trình';
																	|ru = 'Описания процессов останутся на поддержке';
																	|en = 'Process details will remain on support'; fa = 'Process details will remain on support';
																	|it = 'Описания процессов останутся на поддержке';
																	|pl = 'Process details will remain on support';
																	|tr = 'Süreç ayrıntıları destekte durur'"),
		                                                        TextIsOnSupport);
		
	EndIf;
	
	Items.DecorationExplanationDoNotChangeSettingOptionForSupport.Title = ExplanationText;
	VendorInformationCurBase = TextIsOnSupport;
	
EndProcedure

#EndRegion

#Region FilesOperations

&AtClient
Procedure AfterProcessingSelectionOfUploadFileChange(Result, AdditionalParameters) Export
	
	If TypeOf(Result) <> Type("String") Then
		Return;
	EndIf;
	
	If Result <> AdditionalParameters.CurrentFile Then
		ProcessUploadFileChange();
	EndIf;
	
EndProcedure 

&AtClient
Procedure ProcessUploadFileChange()

	If IsBlankString(ImportFile) Then
		
		ParsingResult = NewResultOfParsingDownloadFile();
		ParsingResult.UploadFileIsSelectedCorrectly = False;
		ParsingResult.ErrorMessage = NStr("vi = 'Chưa chọn tệp kết nhập';
											|ru = 'Файл загрузки не выбран';
											|en = 'Import file not selected'; fa = 'Import file not selected';
											|it = 'Файл загрузки не выбран';
											|pl = 'Import file not selected';
											|tr = 'İçe aktarma dosyası seçili değil'");
		
		DisplayInformationOnFormBasedOnResultsOfAnalysisOfDownloadFile(ParsingResult);

	Else
		
		GenerateInformationAboutUploadFile(BinaryDataOfDownloadFile());
		
	EndIf; 
	
	ThereIsGlossaryToDownload = False;
	ThereAreScriptsToDownload  = False;
	
	InstallAssistantNavigator(ThisObject);

EndProcedure

&AtServer
Procedure GenerateInformationAboutUploadFile(BinaryDataOfDownloadFile)
	
	Try
		ObjectReading = New ZipFileReader(DemoScenarios.InMemoryStreamOfBinaryData(BinaryDataOfDownloadFile));
	Except
		
		FillInFormDataAccordingToUploadDescription(Undefined ,NStr("vi = 'Không thể phân tích thông tin về dữ liệu được kết nhập.';
																	|ru = 'Не удалось разобрать информацию о загружаемых данных.';
																	|en = 'Cannot parse the information about the data to import.'; fa = 'Cannot parse the information about the data to import.';
																	|it = 'Не удалось разобрать информацию о загружаемых данных.';
																	|pl = 'Cannot parse the information about the data to import.';
																	|tr = 'İndirilen verilerle ilgili bilgileri ayrıştırmak mümkün olmadı.'"));
		Return;
		
	EndTry;
	
	If ObjectReading.Items.Count() <> 0 Then
		
		FileNameUploadDescription = DemoScenariosClientServer.FileNameUploadDescription();
		
		DownloadDescriptionData = ObjectReading.Items.Find(FileNameUploadDescription);
		
		If DownloadDescriptionData = Undefined Then
			
			FillInFormDataAccordingToUploadDescription(Undefined ,NStr("vi = 'Tệp đã chọn không chứa mô tả dữ liệu được kết nhập.';
																		|ru = 'Выбранный файл не содержит описания загружаемых данных.';
																		|en = 'The selected file does not contain details of the data to import.'; fa = 'The selected file does not contain details of the data to import.';
																		|it = 'Выбранный файл не содержит описания загружаемых данных.';
																		|pl = 'The selected file does not contain details of the data to import.';
																		|tr = 'Seçili dosya, yüklenen verilerin ayrıntılarını içermemektedir.'"));
			
		Else
			UploadFileIsSelectedCorrectly = True;
			
			ResultOfCreatingFolder = DemoScenarios.ResultOfCreatingDirectoryForUnzippingUploading(); 
			
			If Not ResultOfCreatingFolder.Success Then
				Return;
			EndIf;
			
			DirectoryOfUnzippedFiles = ResultOfCreatingFolder.DirectoryName;
			
			ObjectReading.Extract(DownloadDescriptionData, DirectoryOfUnzippedFiles, ZIPRestoreFilePathsMode.DontRestore); 
				
			TextReader   = New TextReader(DirectoryOfUnzippedFiles + FileNameUploadDescription, , , , False);
			DescriptionData  = TrimAll(TextReader.Read());
			TextReader.Close(); 
			
			ReadingErrorText = "";
			
			ReadingResult = ResultOfReadingJSONString(DescriptionData, ReadingErrorText);
			
			If Not ReadingResult.Success Then
				
				UploadFileIsSelectedCorrectly = False;
				Common.MessageToUser(ReadingResult.ErrorText,, ImportFile); 
				
				Return;
				
			EndIf;
			
			FillInFormDataAccordingToUploadDescription(ReadingResult.Data,ReadingErrorText);
				
		EndIf;
			
	EndIf;
	
EndProcedure

&AtServerNoContext
Function ResultOfReadingJSONString(DescriptionData, ReadingErrorText)
	
	Return DemoScenarios.ResultOfReadingJSONString(DescriptionData, ReadingErrorText);
	
EndFunction

&AtServer
Procedure FillInFormDataAccordingToUploadDescription(DownloadFileDescriptionData, ReadingErrorText)
	
	ParsingResult = NewResultOfParsingDownloadFile();
	
	If Not IsBlankString(ReadingErrorText) Then
		
		ParsingResult.UploadFileIsSelectedCorrectly = False;
		ParsingResult.ErrorMessage = StrTemplate(NStr("vi = 'Khi đọc tệp mô tả kết xuất, đã xảy ra lỗi: %1';
														|ru = 'Чтение файла описания выгрузки завершилось с ошибкой: %1';
														|en = 'Reading the export details file completed with an error: %1'; fa = 'Reading the export details file completed with an error: %1';
														|it = 'Чтение файла описания выгрузки завершилось с ошибкой: %1';
														|pl = 'Reading the export details file completed with an error: %1';
														|tr = 'Dışa aktarma ayrıntıları dosyasının okunması hata ile sonlandı: %1'"), ReadingErrorText); 
		
	Else
	
		ErrorTextInvalidFormat = NStr("vi = 'Tệp đã chọn không phải là tệp kết xuất mô tả quy trình';
										|ru = 'Выбранный файл не является файлом выгрузки описаний процессов';
										|en = 'The selected file is not a process details export file'; fa = 'The selected file is not a process details export file';
										|it = 'Выбранный файл не является файлом выгрузки описаний процессов';
										|pl = 'The selected file is not a process details export file';
										|tr = 'Seçili dosya, süreç ayrıntılarının dışa aktarma dosyası değildir'");
		
		If Not CommonClientServer.HasAttributeOrObjectProperty(DownloadFileDescriptionData, "ConfigurationDescription") Then
			ParsingResult.UploadFileIsSelectedCorrectly = False;
			ParsingResult.ErrorMessage           = ErrorTextInvalidFormat;
		Else
			DescriptionOfLoadedDelivery = DownloadFileDescriptionData.ConfigurationDescription;
		EndIf;
		
		If Not CommonClientServer.HasAttributeOrObjectProperty(DownloadFileDescriptionData, "Supplier") Then
			ParsingResult.UploadFileIsSelectedCorrectly  = False;
			ParsingResult.ErrorMessage            = ErrorTextInvalidFormat;
		Else
			VendorOfDownloadableDelivery =  DownloadFileDescriptionData.Supplier;
		EndIf;
		
		If Not CommonClientServer.HasAttributeOrObjectProperty(DownloadFileDescriptionData, "Partial") Then
			ParsingResult.UploadFileIsSelectedCorrectly = False;
			ParsingResult.ErrorMessage            = ErrorTextInvalidFormat;
		Else
			ThisIsPartialUpload =  DownloadFileDescriptionData.Partial;
		EndIf;
	
	EndIf;
	
	DisplayInformationOnFormBasedOnResultsOfAnalysisOfDownloadFile(ParsingResult);
	
EndProcedure

&AtServer
Procedure DisplayInformationOnFormBasedOnResultsOfAnalysisOfDownloadFile(ParsingResult) 
	
	If ParsingResult.UploadFileIsSelectedCorrectly Then
		
		UploadFileIsSelectedCorrectly = True;
		FileReadingIsRequired       = True;
		
		Items.PagesWhetherUploadFileIsCorrectOrNot.CurrentPage = Items.PageCorrectUploadFileIsSelected;
		
		InformationOfDownloadedFile = DemoScenariosClientServer.DeliveryDescriptionText(DescriptionOfLoadedDelivery, VendorOfDownloadableDelivery);
		
		If ThisIsPartialUpload Then
			
			Items.GroupWarningPartialUpload.Visible                  = True;
			OptionOfSettingUpForSupport                                               = 1; 
			Items.GroupSupportOptionSelection.ReadOnly                       = True;
			Items.MethodOfLoadingComparisonCombining.ExtendedTooltip.Title = NStr("vi = 'Có thể tùy chỉnh dữ liệu nào được kết nhập, dữ liệu nào không';
																					|ru = 'Можно будет настроить, какие данные загружать, а какие нет';
																					|en = 'You will be able to configure which data to import and which not to import'; fa = 'You will be able to configure which data to import and which not to import';
																					|it = 'Можно будет настроить, какие данные загружать, а какие нет';
																					|pl = 'You will be able to configure which data to import and which not to import';
																					|tr = 'Hangi verilerin yüklenip hangilerinin yüklenmeyeceğini ayarlamak mümkün olacaktır'");
			
			Items.DoNotDeleteDownloadSettings.Visible                                                 = False;
			Items.UploadSettingsDelete.Visible                                                   = False; 
			Items.UploadSettingsGlossaryDelete.Visible                                          = False;
			Items.DonTDeleteGlossaryUploadSettings.Visible                                        = False;
			Items.LoadingSettingsProcessDescriptionsContextMenuShouldDelete.Visible                   = False;
			Items.LoadingSettingsProcessDescriptionsContextMenuNotShouldDelete.Visible                 = False;
			Items.LoadingSettingsProcessDescriptionsSelectionContextMenuShouldDelete.Visible              = False;
			Items.LoadingSettingsProcessDescriptionsSelectionContextMenuNotShouldDelete.Visible            = False;
			Items.DownloadSettingsGlossaryContextMenuShouldDelete.Visible                           = False;
			Items.DownloadSettingsGlossaryContextMenuNotShouldDelete.Visible                         = False;
			Items.DownloadSettingsGlossarySelectionContextMenuShouldDelete.Visible                      = False;
			Items.DownloadSettingsGlossarySelectionContextMenuShouldDelete.Visible                      = False;
			
		Else
			
			Items.GroupWarningPartialUpload.Visible                  = False;
			Items.GroupSupportOptionSelection.ReadOnly                       = False;
			Items.MethodOfLoadingComparisonCombining.ExtendedTooltip.Title = NStr("vi = 'Có thể tùy chỉnh dữ liệu nào được kết nhập, dữ liệu nào không. Có thể sử dụng các chương trình của bên thứ ba để so sánh và hợp nhất dữ liệu đã tải xuống với dữ liệu trong cơ sở thông tin';
																					|ru = 'Можно будет настроить, какие данные загружать, а какие нет. Будет возможность при помощи сторонних программ сравнить и объединить загружаемые данные с данными в информационной базе';
																					|en = 'You will be able to configure which data to import and which not to import. You will be able to compare and merge data to import with data in the infobase using third-party programs'; fa = 'می‌توانید پیکربندی کنید که کدام داده‌ها وارد شوند و کدام وارد نشوند. می‌توانید داده‌های ورودی را با داده‌های پایگاه اطلاعات با استفاده از برنامه‌های شخص ثالث مقایسه و ادغام کنید';
																					|it = 'Можно будет настроить, какие данные загружать, а какие нет. Будет возможность при помощи сторонних программ сравнить и объединить загружаемые данные с данными в информационной базе';
																					|pl = 'You will be able to configure which data to import and which not to import. You will be able to compare and merge data to import with data in the infobase using third-party programs';
																					|tr = 'Hangi verilerin yüklenip hangilerinin yüklenmeyeceğini ayarlamak mümkün olacaktır. Üçüncü taraf programları kullanarak yüklenen verileri infobase üzerindeki verilerle karşılaştırmak ve birleştirmek mümkün olacaktır'");
			
			Items.DoNotDeleteDownloadSettings.Visible                                                 = True;
			Items.UploadSettingsDelete.Visible                                                   = True;
			Items.UploadSettingsGlossaryDelete.Visible                                          = True;
			Items.DonTDeleteGlossaryUploadSettings.Visible                                        = True;
			Items.LoadingSettingsProcessDescriptionsContextMenuShouldDelete.Visible                   = True;
			Items.LoadingSettingsProcessDescriptionsContextMenuNotShouldDelete.Visible                 = True;
			Items.LoadingSettingsProcessDescriptionsSelectionContextMenuCompareAndMerge.Visible  = True;
			Items.LoadingSettingsProcessDescriptionsSelectionContextMenuShouldDelete.Visible              = True;
			Items.LoadingSettingsProcessDescriptionsSelectionContextMenuNotShouldDelete.Visible            = True;
			Items.DownloadSettingsGlossaryContextMenuShouldDelete.Visible                           = True;
			Items.DownloadSettingsGlossaryContextMenuNotShouldDelete.Visible                         = True;
			Items.DownloadSettingsGlossarySelectionContextMenuShouldDelete.Visible                      = True;
			Items.DownloadSettingsGlossarySelectionContextMenuShouldDelete.Visible                      = True;

		EndIf;
		
		ExplanationText = StringFunctions.FormattedString("<span style=""color: NoteText "">%1: <b>%2</b></span>",
		                                                        NStr("vi = 'Thông tin về phiên bản và dữ liệu của nhà cung cấp sẽ được cập nhật đến';
																	|ru = 'Информация о версии и данных поставщика будет обновлена на';
																	|en = 'The information on the version and vendor data will be updated to'; fa = 'The information on the version and vendor data will be updated to';
																	|it = 'Информация о версии и данных поставщика будет обновлена на';
																	|pl = 'The information on the version and vendor data will be updated to';
																	|tr = 'Sağlayıcı sürümü ve verileri hakkındaki bilgilerin güncelleneceği adres'"),
		                                                        InformationOfDownloadedFile);
		
		Items.DecorationExplanationOptionOfSettingUpForSupportFromDownloadedFile.Title = ExplanationText;
		
		DeliveryInformationDownloadableFile = InformationOfDownloadedFile; 
		
	Else 
		
		Items.PagesWhetherUploadFileIsCorrectOrNot.CurrentPage = Items.PageCorrectUploadFileIsNotSelected;
		Items.DecorationExplanationOfFileSelection.Title              = ParsingResult.ErrorMessage;
		
		If IsBlankString(ImportFile) Then
			
			Items.PagesFileNotSelectedInvalidFile.CurrentPage = Items.PageFileNotSelected;
			
		Else
			
			Items.PagesFileNotSelectedInvalidFile.CurrentPage = Items.IncorrectFileSelectedPage;
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function NewResultOfParsingDownloadFile()
	
	ParsingResult = New Structure;
	ParsingResult.Insert("UploadFileIsSelectedCorrectly",True);
	ParsingResult.Insert("ErrorMessage",           ""); 
	
	Return ParsingResult;
	
EndFunction

#EndRegion

#Region NavigatingAssistant

&AtClientAtServerNoContext
Procedure InstallAssistantNavigator(Form)
	
	Items = Form.Items;

	StartPageLine    = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'Bắt đầu';
																						|ru = 'Начало';
																						|en = 'Start'; fa = 'شروع';
																						|it = 'Начало';
																						|pl = 'Start';
																						|tr = 'Başlangıç'"), 
	                                                                                              "GoToHomePage",
	                                                                                              True,
	                                                                                              Items.WizardPages.CurrentPage = Items.PageStart); 
	
	SettingRow            = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'Tùy chỉnh mô tả';
																							|ru = 'Настройка описаний';
																							|en = 'Details setup'; fa = 'Details setup';
																							|it = 'Настройка описаний';
																							|pl = 'Details setup';
																							|tr = 'Ayrıntı ayarı'"),
	                                                                                              "GoToSettingsPage",
	                                                                                              Form.UploadFileIsSelectedCorrectly And Form.ThereAreScriptsToDownload,
	                                                                                              Items.WizardPages.CurrentPage = Items.ImportSetupPage);
	
	GlossarySettingsLine   = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'Tùy chỉnh thuật ngữ';
																							|ru = 'Настройка глоссария';
																							|en = 'Glossary setup'; fa = 'Glossary setup';
																							|it = 'Настройка глоссария';
																							|pl = 'Glossary setup';
																							|tr = 'Terim sözlüğü ayarı'"),
	                                                                                              "GoToGlossaryPage",
	                                                                                              Form.UploadFileIsSelectedCorrectly And Form.ThereIsGlossaryToDownload,
	                                                                                              Items.WizardPages.CurrentPage = Items.DownloadSettingsPageGlossary);
	
	StringResults           = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'Kết quả kết xuất';
																							|ru = 'Результаты загрузки';
																							|en = 'Import results'; fa = 'Import results';
																							|it = 'Результаты загрузки';
																							|pl = 'Import results';
																							|tr = 'Yükleme sonuçları'"),
	                                                                                              "GoToResultsPage",
	                                                                                              Form.ImportIsCompleted,
	                                                                                              Items.WizardPages.CurrentPage = Items.PageLoaded);
	
	StringComparisonUnion = DemoScenariosClientServer.TitleOfNavigatorPartOfAssistant(NStr("vi = 'So sánh và hợp nhất';
																							|ru = 'Сравнение и объединение';
																							|en = 'Comparison and merging'; fa = 'Comparison and merging';
																							|it = 'Сравнение и объединение';
																							|pl = 'Comparison and merging';
																							|tr = 'Karşılaştırma ve birleştirme'"),
	                                                                                              "GoToCompareAndMergePage",
	                                                                                              Form.PreparationForComparisonAndUnificationHasBeenCompleted,
	                                                                                              Items.WizardPages.CurrentPage = Items.PageComparisonAssociation);
	
	LineBetweenPages = " -> ";
	
	ArrayFormattedString = New Array;
	ArrayFormattedString.Add(StartPageLine);
	ArrayFormattedString.Add(LineBetweenPages);
	If Form.LoadMethod > 0 Then
		
		If Form.ThereAreScriptsToDownload Then
			ArrayFormattedString.Add(SettingRow);
			ArrayFormattedString.Add(LineBetweenPages);
		EndIf;
		If Form.ThereIsGlossaryToDownload Then
			ArrayFormattedString.Add(GlossarySettingsLine);
			ArrayFormattedString.Add(LineBetweenPages);
		EndIf;
		
	EndIf;
	If Form.LoadMethod > 0
		And Form.ThereIsSomethingToCombine Then
		ArrayFormattedString.Add(StringComparisonUnion);
		ArrayFormattedString.Add(LineBetweenPages); 
	EndIf;
	
	Items.DownloadSettingsCompareAndMerge.Visible = (Form.LoadMethod = 1);
	
	ArrayFormattedString.Add(StringResults);
	
	Items.AssistantNavigatorDecoration.Title = New FormattedString(ArrayFormattedString);
	
EndProcedure

&AtClient
Procedure GoToAssistantPage(PageName)

	If PageName = "PageStart" Then
		
		Items.WizardPages.CurrentPage = Items.PageStart;
		Items.PagesFooter.CurrentPage    = Items.ClickNextPage;
		Items.Next.DefaultButton           = True;
		
	ElsIf PageName = "ImportSetupPage" Then
		
		If FileReadingIsRequired Then
			
			StartReadingFiles();
			
		Else
			
			GoToUploadSettingsPage(ThisObject);
			
		EndIf;
		
	ElsIf PageName = "DownloadSettingsPageGlossary" Then
		
		GoToDownloadSettingsGlossaryPage(ThisObject);
		
	ElsIf PageName = "PageLoaded" Then
		
		If FileReadingIsRequired Then
			
			StartReadingFiles();
			
		ElsIf ItRequiresReadingResultsComparingCombining Then
			
			GetResultingFiles();
			GoToLoadedPage();
			AttachIdleHandler("StartLoadingScripts", 0.5, True);
		
		ElsIf ImportRequired Then
			
			GoToLoadedPage();
			AttachIdleHandler("StartLoadingScripts", 0.5, True);
			
		Else
			
			GoToLoadedPage();
			
		EndIf; 
		
	ElsIf PageName = "PageComparisonAssociation" Then
		
		If ComparisonIsRequiredUnion Then
			
			StartPreparingForComparisonAndMerging();
			
		Else
			
			GoToCompareAndMergePage();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToCompareAndMergePage()
	
	Items.WizardPages.CurrentPage = Items.PageComparisonAssociation;
	Items.PagesFooter.CurrentPage    = Items.BackNextButtonPage;
	Items.FurtherBackFurther.DefaultButton = True;
	
EndProcedure

&AtClient
Procedure GoToLoadedPage()
	
	Items.WizardPages.CurrentPage = Items.PageLoaded;
	Items.PagesFooter.CurrentPage    = Items.TheDoneButtonPage;
	Items.NextFinish.DefaultButton     = True;
	
	If ImportRequired Then
		
		Items.PagesLoadedLoaded.CurrentPage = Items.PageIsLoading;
		Items.NextFinish.Enabled                      = False;
		
	Else
		
		Items.PagesLoadedLoaded.CurrentPage = Items.PageLoadingFinished;
		Items.NextFinish.Enabled           = True;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure GoToUploadSettingsPage(Form) 
	
	Items = Form.Items;
	
	Items.WizardPages.CurrentPage = Items.ImportSetupPage;
	Items.PagesFooter.CurrentPage    = Items.BackNextButtonPage;
	Items.FurtherBackFurther.DefaultButton = True;
	
EndProcedure

&AtClientAtServerNoContext
Procedure GoToDownloadSettingsGlossaryPage(Form)
	
	Items = Form.Items;
	
	Items.WizardPages.CurrentPage = Items.DownloadSettingsPageGlossary;
	Items.PagesFooter.CurrentPage    = Items.BackNextButtonPage;
	Items.FurtherBackFurther.DefaultButton = True;
	
EndProcedure 

&AtClient
Procedure NavigateThroughPages(Command)
	
	ClearMessages();
	
	CommandName = Command.Name;
	Cancel      = False;
	
	CheckAbilityToNavigateThroughPages(CommandName, Cancel);
	
	If Cancel Then
		Return;
	EndIf;
	
	PerformNecessaryActionsWhenNavigatingThroughPages(CommandName);
	
EndProcedure 

&AtClient
Procedure PerformNecessaryActionsWhenNavigatingThroughPages(CommandName)

	If CommandName = "Next" Then
		GotoNextPage();
	Else
		GoToThePreviousPage();
	EndIf;
	
	InstallAssistantNavigator(ThisObject);

EndProcedure

&AtClient
Procedure GotoNextPage()
	
	If Items.WizardPages.CurrentPage = Items.PageStart Then
		
		If LoadMethod = 0 Then
			
			GoToAssistantPage("PageLoaded");
			
		Else
			
			GoToAssistantPage("ImportSetupPage");
			
		EndIf; 
		
	ElsIf Items.WizardPages.CurrentPage = Items.ImportSetupPage Then
		
		If ThereIsGlossaryToDownload Then
			
			GoToAssistantPage("DownloadSettingsPageGlossary");
			
		ElsIf ThereIsSomethingToCombine(ThisObject) Then
			
			GoToAssistantPage("PageComparisonAssociation");
			
		Else
			
			ComparisonIsRequiredUnion                  = False;
			ItRequiresReadingResultsComparingCombining = False;
			GoToAssistantPage("PageLoaded");
			
		EndIf; 
		
	ElsIf Items.WizardPages.CurrentPage = Items.DownloadSettingsPageGlossary Then
		
		If ThereIsSomethingToCombine(ThisObject) Then
			
			GoToAssistantPage("PageComparisonAssociation");
			
		Else
			
			ComparisonIsRequiredUnion                  = False;
			ItRequiresReadingResultsComparingCombining = False;
			GoToAssistantPage("PageLoaded");
			
		EndIf;
		
	ElsIf Items.WizardPages.CurrentPage = Items.PageComparisonAssociation Then
		
		GoToAssistantPage("PageLoaded");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToThePreviousPage()

	If Items.WizardPages.CurrentPage = Items.ImportSetupPage Then 
		
		GoToAssistantPage("PageStart"); 
		
	ElsIf Items.WizardPages.CurrentPage = Items.DownloadSettingsPageGlossary Then 
		
		If LoadingSettingsProcessDescriptions.GetItems().Count() > 0 Then
			
			GoToAssistantPage("ImportSetupPage");
			
		Else
			
			GoToAssistantPage("PageStart");
			
		EndIf; 
		
	ElsIf Items.WizardPages.CurrentPage = Items.PageComparisonAssociation Then 
		
		If DownloadSettingsGlossary.GetItems().Count() > 0 Then
			
			GoToAssistantPage("DownloadSettingsPageGlossary");
			
		Else
			
			GoToAssistantPage("ImportSetupPage");
			
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Procedure CheckAbilityToNavigateThroughPages(CommandName, Cancel)

	If Items.WizardPages.CurrentPage = Items.PageStart
		And CommandName = "Next" Then
		
		If IsBlankString(ImportFile) Then
			
			MessageText = NStr("vi = 'Chưa chỉ định tệp kết xuất';
								|ru = 'Файл загрузки не указан';
								|en = 'Import file is not specified'; fa = 'Import file is not specified';
								|it = 'Файл загрузки не указан';
								|pl = 'Import file is not specified';
								|tr = 'İçe aktarma dosyası belirtilmedi'");
			
			CommonClient.MessageToUser(MessageText,, "ImportFile",, Cancel);
			
		ElsIf Not UploadFileIsSelectedCorrectly Then
			
			MessageText = NStr("vi = 'Đã chọn sai tệp kết nhập';
								|ru = 'Выбран не корректный файл загрузки';
								|en = 'Incorrect import file is selected'; fa = 'Incorrect import file is selected';
								|it = 'Выбран не корректный файл загрузки';
								|pl = 'Incorrect import file is selected';
								|tr = 'Yanlış yükleme dosyası seçildi'");
			
			CommonClient.MessageToUser(MessageText,, "ImportFile",, Cancel);
			
		EndIf;
		
	ElsIf Items.WizardPages.CurrentPage = Items.ImportSetupPage
		And CommandName = "Next" Then
		
		If Not ThereAreActionsRequiredToBePerformed() Then
			
			MessageText = NStr("vi = 'Chưa chọn thao tác nào cần thực hiện khi kết nhập';
								|ru = 'Не выбрано ни одного действия, которое требуется выполнить при загрузке';
								|en = 'No action to perform upon import is selected'; fa = 'No action to perform upon import is selected';
								|it = 'Не выбрано ни одного действия, которое требуется выполнить при загрузке';
								|pl = 'No action to perform upon import is selected';
								|tr = 'Yükleme sırasında gerçekleştirilmesi gereken herhangi bir eylem seçilmedi'");
			
			CommonClient.MessageToUser(MessageText,, "TabularSectionName",, Cancel);
			
		EndIf; 
		
	ElsIf Items.WizardPages.CurrentPage = Items.PageComparisonAssociation
		And CommandName = "Next" Then 
		
		LineNumber = 1;
		
		For Each TableRow In ComparisonAssociation Do
			
			If IsBlankString(TableRow.NameOfFileToUpload) Then 
				
				ErrorText = StrTemplate(NStr("vi = 'Chưa chỉ định ""Tên tệp cần kết nhập"" trong dòng %1';
											|ru = 'Не указано  ""Имя файла к загрузке"" в строке %1';
											|en = 'In line %1, ""File name to import"" is not specified'; fa = 'In line %1, ""File name to import"" is not specified';
											|it = 'Не указано  ""Имя файла к загрузке"" в строке %1';
											|pl = 'In line %1, ""File name to import"" is not specified';
											|tr = '%1 satırında ""Yüklenecek dosya adı"" belirtilmedi'"), LineNumber);
				
				CommonClient.MessageToUser(
					ErrorText,
					,
					CommonClientServer.PathToTabularSection("ComparisonAssociation", LineNumber - 1, "NameOfFileToUpload"),
					,
					Cancel);
					
				LineNumber = LineNumber + 1;
				
			EndIf;
			
		EndDo;
		
	EndIf;

EndProcedure

#EndRegion 

#Region ReadingFiles

&AtClient
Procedure StartReadingFiles()
	
	Items.PagesWhetherUploadFileIsCorrectOrNot.CurrentPage = Items.PageIsReadingFiles;
	AttachIdleHandler("ReadDownloadedData", 1, True);
	
EndProcedure 

&AtClient
Procedure ReadDownloadedData()
	
	LoadingSettingsProcessDescriptions.GetItems().Clear();
	DownloadSettingsGlossary.GetItems().Clear();
	Screenshots.Clear();
	
	TimeConsumingOperation = ReadingArchiveFileIsLongOperation(UUID, BinaryDataOfDownloadFile());
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		ReadingDownloadArchiveFileEnds(TimeConsumingOperation, AdditionalParameters);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = NStr("vi = 'Kết nhập dữ liệu mô tả quy trình';
									|ru = 'Загрузка данных описаний процессов';
									|en = 'Import process details data'; fa = 'Import process details data';
									|it = 'Загрузка данных описаний процессов';
									|pl = 'Import process details data';
									|tr = 'Süreç ayrıntıları verilerinin yüklenmesi'");
		
		CallbackOnCompletion = New CallbackDescription("ReadingDownloadArchiveFileEnds", ThisObject, AdditionalParameters);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ReadingDownloadArchiveFileEnds(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessResultOfReadingFiles(Result, AdditionalParameters);
	EndIf;

EndProcedure

&AtClient
Procedure ProcessResultOfReadingFiles(Result, AdditionalParameters)

	If Not IsTempStorageURL(Result.ResultAddress) Then 
		Return;
	EndIf;
	
	ImportResult1 =  ResultOfProcessingReadingArchiveOnServer(Result.ResultAddress);
	
	If ImportResult1.Success Then
		
		ImportRequired             = True;
		FileReadingIsRequired         = False;
		ComparisonIsRequiredUnion = ThereIsSomethingToCombine(ThisObject);
		ThereIsSomethingToCombine             = ComparisonIsRequiredUnion; 
	
		Items.PagesWhetherUploadFileIsCorrectOrNot.CurrentPage = Items.PageCorrectUploadFileIsSelected;
		
		ThereIsGlossaryToDownload = DownloadSettingsGlossary.GetItems().Count();
		ThereAreScriptsToDownload  = LoadingSettingsProcessDescriptions.GetItems().Count();
		
		If LoadMethod = 1 Then
			
			If ThereAreScriptsToDownload Then
				GoToUploadSettingsPage(ThisObject);
			ElsIf ThereIsGlossaryToDownload Then
				GoToDownloadSettingsGlossaryPage(ThisObject);
			EndIf;
			
		Else
			
			GoToLoadedPage();
			AttachIdleHandler("StartLoadingScripts", 0.5, True);
			
		EndIf;
		
		InstallAssistantNavigator(ThisObject);
		
	EndIf;
	
EndProcedure

&AtServer
Function ResultOfProcessingReadingArchiveOnServer(ResultAddress)
	
	ProcessingResult = New Structure;
	ProcessingResult.Insert("Success",                True);
	ProcessingResult.Insert("ErrorsMessages",     New Array);
	
	ImportResult1 = GetFromTempStorage(ResultAddress);
	
	FillPropertyValues(ProcessingResult, ImportResult1);
	
	If Not ProcessingResult.Success Then
		Return ProcessingResult;
	EndIf;
	
	ValueToFormAttribute(ImportResult1.DownloadData.LoadingSettingsProcessDescriptions, "LoadingSettingsProcessDescriptions");
	ValueToFormAttribute(ImportResult1.DownloadData.DownloadSettingsGlossary,         "DownloadSettingsGlossary");
	ValueToFormAttribute(ImportResult1.DownloadData.Screenshots,                           "Screenshots");
	
	Return ProcessingResult;
	
EndFunction

&AtServer
Function ReadingArchiveFileIsLongOperation(Var_UUID, BinaryDataOfDownloadFile)
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Glossary",                      FormAttributeToValue("DownloadSettingsGlossary")); 
	GenerationParameters.Insert("ProcessDescriptionTree",        FormAttributeToValue("LoadingSettingsProcessDescriptions")); 
	GenerationParameters.Insert("Screenshots",                      FormAttributeToValue("Screenshots"));
	GenerationParameters.Insert("BinaryDataOfDownloadFile",    BinaryDataOfDownloadFile);
	GenerationParameters.Insert("ThisIsPartialUpload",           ThisIsPartialUpload);
	GenerationParameters.Insert("OptionOfSettingUpForSupport",   OptionOfSettingUpForSupport);
	GenerationParameters.Insert("UUID",        Var_UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Đọc tệp nén kết nhập mô tả quy trình';
														|ru = 'Чтение файлов архива загрузки описаний процессов';
														|en = 'Read archive files of process details import'; fa = 'Read archive files of process details import';
														|it = 'Чтение файлов архива загрузки описаний процессов';
														|pl = 'Read archive files of process details import';
														|tr = 'Süreç ayrıntılarının yüklendiği arşiv dosyalarının okunması'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DataProcessors.ProcessDetailsImport.ReadDownloadFileData",
	                                                       GenerationParameters, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Function BinaryDataOfDownloadFile()

	Return New BinaryData(ImportFile);

EndFunction

&AtClientAtServerNoContext
Function TreeStringSearchResult(WhereToFind,Value,Column,SearchSubordinateItems)
	
	TreeItems = WhereToFind.GetItems();
	
	For Each TreeItem In TreeItems Do
		If TreeItem[Column] = Value Then
			Return TreeItem.GetID();
		ElsIf  SearchSubordinateItems Then
			FoundRowID1 =  TreeStringSearchResult(TreeItem,Value,Column,SearchSubordinateItems);
			If FoundRowID1 >=0 Then
				Return FoundRowID1;
			EndIf;
		EndIf;
		
	EndDo;
	
	Return -1;
	
EndFunction

#EndRegion

#Region TextComparison

&AtClient
Procedure ShowTextComparisonWindow(Var_Parameters)
	
	Var_Parameters.Insert("PerformComparisonOfTwoTexts", True);
	
	OpenForm("DataProcessor.TextComparison.Form.TextComparison", Var_Parameters, ,,,,,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure OpenTextComparisonWindowByTreeLine(CurrentData, TableName)
	
	CompareParameters = New Structure;
	CompareParameters.Insert("TextForComparison1", CurrentData.DatabaseData);
	CompareParameters.Insert("TextDetails1",    NStr("vi = 'dữ liệu cơ sở thông tin';
													|ru = 'данные информационной базы';
													|en = 'infobase data'; fa = 'infobase data';
													|it = 'данные информационной базы';
													|pl = 'infobase data';
													|tr = 'infobase verileri'"));
	CompareParameters.Insert("TextForComparison2", CurrentData.FileData);
	CompareParameters.Insert("TextDetails2",    NStr("vi = 'dữ liệu của tệp kết nhập';
													|ru = 'данные загружаемого файла';
													|en = 'data of the file to import'; fa = 'data of the file to import';
													|it = 'данные загружаемого файла';
													|pl = 'data of the file to import';
													|tr = 'yüklenen dosyanın verileri'"));
	CompareParameters.Insert("FormCaption",     PresentationForTextComparison(CurrentData, TableName));
	
	If CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase")
		Or CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInImport") Then
		
		CompareParameters.Insert("InitialMapping", "DifferencesInOneWindow");
		
	EndIf;
	
	ShowTextComparisonWindow(CompareParameters);
	
EndProcedure

&AtClient
Function PresentationForTextComparison(CurrentData, TableName)
	
	If CurrentData.TypeOfUploadSettingsLine = "Scenario"
		Or TableName = "LoadingSettingsProcessDescriptionsSelection"
		Or TableName = "DownloadSettingsGlossarySelection" Then
		
		Return StrTemplate(NStr("vi = 'Mục tin mô tả %1';
								|ru = 'Реквизиты описания %1';
								|en = '%1 details attributes'; fa = '%1 details attributes';
								|it = 'Реквизиты описания %1';
								|pl = '%1 details attributes';
								|tr = '%1 ayrıntılarının öznitelikleri'"), CurrentData.Presentation);
		
	ElsIf CurrentData.TypeOfUploadSettingsLine = "LongDesc" Then
		
		ParentString = CurrentData.GetParent();
		
		If ParentString <> Undefined Then
			
			Return StrTemplate(NStr("vi = '%1 (%2)';
									|ru = '%1 (%2)';
									|en = '%1 (%2)'; fa = '%1 (%2)';
									|it = '%1 (%2)';
									|pl = '%1 (%2)';
									|tr = '%1 (%2)'"), ParentString.Presentation, CurrentData.LanguageCode);
			
		EndIf;
		
	EndIf;
	
EndFunction

#EndRegion

#Region Filters

&AtClient
Procedure CreateSelectionListOfWhatToDo(Item, TableName)
	
	Item.ChoiceList.Clear();
	
	CurrentData = Items[TableName].CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	If CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.ChangedOnlyByVendor")
		Or CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NoChanges")
		Or CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.HasChanges")
		Or CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.ChangedOnlyInInfobase") 
		Or CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.ChangedByVendorAndInInfobase")  Then
		
		Item.ChoiceList.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.ToImport"));
		Item.ChoiceList.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.NotToImport"));
		Item.ChoiceList.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Union"));
		
	ElsIf CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase")  Then
		
		Item.ChoiceList.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.ToImport"));
		Item.ChoiceList.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.NotToImport"));
		
	ElsIf CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInImport") Then
		
		Item.ChoiceList.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Delete"));
		Item.ChoiceList.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.NotShouldDelete"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenActivatingDownloadSettingsField(Item, ColumnPrefix, TableName)
	
	If Item.CurrentItem.Name = ColumnPrefix + "StatusOfFiles" Then
		
		CurrentData = Items[TableName].CurrentData;
		If CurrentData = Undefined Then
			Return;
		EndIf; 
		
		If CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NoChanges") Then
			Return;
		EndIf;
		
		OpenTextComparisonWindowByTreeLine(CurrentData, TableName);
		
		Item.CurrentItem = Items[ColumnPrefix + "WhatToDo"];
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MultipleListSelectionStartSelection(Form, Item, Values, TypeOfEnumeration, Var_Title, ExcludedValues = Undefined)

	OpeningParameters = New Structure;
	OpeningParameters.Insert("SelectionList",         Values);
	OpeningParameters.Insert("TypeOfEnumeration",     TypeOfEnumeration);
	OpeningParameters.Insert("Title",           Var_Title);
	OpeningParameters.Insert("ExcludedValues", ExcludedValues);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Item", Item);
	
	ClosingNotification1 = New CallbackDescription("FormOfMultipleSelectionOfListAfterClosing", Form, AdditionalParameters);
	OpenForm("DataProcessor.ProcessDetailsImport.Form.MultipleListFilter", OpeningParameters, Item,,,, ClosingNotification1);

EndProcedure

&AtClient
Procedure FormOfMultipleSelectionOfListAfterClosing(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	If AdditionalParameters.Item = Undefined Then
		Return;
	EndIf;
	
	If AdditionalParameters.Item = Items.ActionFilter
		Or AdditionalParameters.Item = Items.ActionGlossarySelection Then
		
		ActionFilter = Result;
		
	ElsIf AdditionalParameters.Item = Items.ChangesFilter
		Or AdditionalParameters.Item = Items.ChangesGlossarySelection Then
		
		ChangesFilter = Result;
		
	EndIf;
	
	SetFilters();

EndProcedure

&AtClient
Procedure SetFilters()

	HasFilter = ActionFilter.Count() > 0 
	            Or ChangesFilter.Count() > 0;
	
	If HasFilter Then
		
		FillFilterTable();
		
		Items.DownloadSettingsPagesSelectionWithoutSelection.CurrentPage          = Items.DownloadSettingsPageSelection;
		Items.PagesDownloadSettingsGlossarySelectionWithoutSelection.CurrentPage = Items.DownloadSettingsPageGlossarySelection;
		
	Else
		
		Items.DownloadSettingsPagesSelectionWithoutSelection.CurrentPage          = Items.DownloadSettingsPageWithoutSelection;
		Items.PagesDownloadSettingsGlossarySelectionWithoutSelection.CurrentPage = Items.GlossaryUploadSettingsPageWithoutSelection;
		
	EndIf;

EndProcedure

&AtClient
Procedure FillFilterTable()

	LoadingSettingsProcessDescriptionsSelection.Clear();
	DownloadSettingsGlossarySelection.Clear();
	
	For Each TreeRow In LoadingSettingsProcessDescriptions.GetItems() Do
		
		AddTreeLineIfItMatchesSelection(TreeRow, "LoadingSettingsProcessDescriptionsSelection");
		
	EndDo; 
	
	For Each TreeRow In DownloadSettingsGlossary.GetItems() Do
		
		AddTreeLineIfItMatchesSelection(TreeRow, "DownloadSettingsGlossarySelection");
		
	EndDo;
	
EndProcedure

&AtClient
Procedure AddTreeLineIfItMatchesSelection(TreeRow, TableName)
	
	MatchesFilter = True;
	
	If ChangesFilter.Count() > 0 Then
		
		If ChangesFilter.FindByValue(TreeRow.StatusOfFiles) = Undefined Then
			MatchesFilter = False;
		EndIf;
		
	EndIf;
	
	If ActionFilter.Count() > 0 Then
		
		If ActionFilter.FindByValue(TreeRow.WhatToDo) = Undefined Then
			MatchesFilter = False;
		EndIf;
		
	EndIf;
	
	If MatchesFilter Then
		
		NewRow = ThisObject[TableName].Add();
		FillInSelectionTreeLineBySettingsLine(TreeRow, NewRow, TableName);
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.GetItems() Do
		
		AddTreeLineIfItMatchesSelection(SubordinateRow, TableName);
		
	EndDo;

EndProcedure

&AtClient
Procedure FillInSelectionTreeLineBySettingsLine(TreeRow, NewRow, TableName)
	
	FillPropertyValues(NewRow, TreeRow);
	NewRow.TreeRowID = TreeRow.GetID();
	
	If TreeRow.TypeOfUploadSettingsLine = "Scenario" Then
		
		NewRow.Presentation = StrTemplate(NStr("vi = '%1 - %2';
												|ru = '%1 - %2';
												|en = '%1 - %2'; fa = '%1 - %2';
												|it = '%1 - %2';
												|pl = '%1 - %2';
												|tr = '%1 - %2'"), NStr("vi = 'Mục tin';
																		|ru = 'Рекв.';
																		|en = 'Attributes'; fa = 'ویژگی‌ها';
																		|it = 'Рекв.';
																		|pl = 'Attributes';
																		|tr = 'Özni.'"), TreeRow.Presentation)
		
	Else
		
		ParentString = TreeRow.GetParent();
		If ParentString <> Undefined Then
			NewRow.Presentation = StrTemplate(NStr("vi = '%1 - %2';
													|ru = '%1 - %2';
													|en = '%1 - %2'; fa = '%1 - %2';
													|it = '%1 - %2';
													|pl = '%1 - %2';
													|tr = '%1 - %2'"), TreeRow.LanguageCode, ParentString.Presentation); 
			
			If TableName = "LoadingSettingsProcessDescriptions" Then
				NewRow.Scenario  = ParentString.Scenario;
				NewRow.FullCode = ParentString.FullCode;
			ElsIf TableName = "DownloadSettingsGlossary" Then
				NewRow.Glossary  = ParentString.Glossary;
				NewRow.Code        = ParentString.Code;
			EndIf;
		EndIf;
		
	EndIf;

EndProcedure

&AtClient
Function NameOfTabularPartOfLoadingSettingsForCurrentPage()

	If Items.WizardPages.CurrentPage = Items.DownloadSettingsPageGlossary Then
		
		If Items.PagesDownloadSettingsGlossarySelectionWithoutSelection.CurrentPage = Items.GlossaryUploadSettingsPageWithoutSelection Then
			Return "DownloadSettingsGlossary";
		Else
			Return "DownloadSettingsGlossarySelection";
		EndIf;
		
	ElsIf Items.WizardPages.CurrentPage = Items.ImportSetupPage Then
		
		If Items.DownloadSettingsPagesSelectionWithoutSelection.CurrentPage = Items.DownloadSettingsPageWithoutSelection Then
			Return "LoadingSettingsProcessDescriptions";
		Else
			Return "LoadingSettingsProcessDescriptionsSelection";
		EndIf;
		
	EndIf;
	
EndFunction

&AtClient
Procedure WhenDoubleClickingOnPresentationOfScript(CurrentData, StandardProcessing)
	
	StandardProcessing = False;
	
	OpeningScenario = Undefined;
	
	If (CurrentData.TypeOfUploadSettingsLine = "Scenario"
		Or TypeOf(CurrentData) = Type("FormDataCollectionItem")) 
		And Not CurrentData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase") Then
		
			OpeningScenario = CurrentData.Scenario;
		
		ElsIf CurrentData.TypeOfUploadSettingsLine = "LongDesc"
			And TypeOf(CurrentData) = Type("FormDataTreeItem")Then
		
		ParentString = CurrentData.GetParent();
		
		If ParentString <> Undefined
			And Not ParentString.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase") Then
			
			OpeningScenario = ParentString.Scenario;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(OpeningScenario) Then
		
		ShowValue(, OpeningScenario);
		
	EndIf; 
		
EndProcedure 

&AtClient
Procedure WhenDoubleClickingOnGlossaryPresentation(CurrentData, StandardProcessing)
	
	StandardProcessing = False;
	
	GlossaryToOpen = Undefined;
	
	If CurrentData.TypeOfUploadSettingsLine = "Scenario"
		Or TypeOf(CurrentData) = Type("FormDataCollectionItem") Then
		
		GlossaryToOpen = CurrentData.Glossary;
		
	ElsIf CurrentData.TypeOfUploadSettingsLine = "LongDesc" Then
		
		ParentString = CurrentData.GetParent();
		
		If ParentString <> Undefined Then
			
			GlossaryToOpen = ParentString.Glossary;
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(GlossaryToOpen) Then
		
		ShowValue(, GlossaryToOpen);
		
	EndIf; 
		
EndProcedure

&AtClient
Procedure ChangeDataLoadingSettingsProcessDescriptionsAfterChangingSelection(LineDataSelection)
	
	TreeRow = LoadingSettingsProcessDescriptions.FindByID(LineDataSelection.TreeRowID);
	
	If TreeRow = Undefined Then
		Return;
	Else
		TreeRow.WhatToDo = LineDataSelection.WhatToDo;
	EndIf;
	
EndProcedure 

&AtClient
Procedure ChangeDataOfGlossaryUploadSettingsAfterChangingSelection(LineDataSelection)
	
	TreeRow = DownloadSettingsGlossary.FindByID(LineDataSelection.TreeRowID);
	
	If TreeRow = Undefined Then
		Return;
	Else
		TreeRow.WhatToDo = LineDataSelection.WhatToDo;
	EndIf;
	
EndProcedure

#EndRegion

#Region WhatToDoDownloadSettings

&AtClient
Procedure SetActionOption(CommandName)
	
	FormTableName = NameOfTabularPartOfLoadingSettingsForCurrentPage();
	
	NewAction = ActionNameByCommandName(CommandName);
	
	If NewAction = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[FormTableName].SelectedRows;
	
	RowsToChange = 0;
	StringsChanged   = 0; 
	
	For Each SelectedRow In SelectedRows Do
		
		RowsToChange = RowsToChange + 1;
		
		RowData = ThisObject[FormTableName].FindByID(SelectedRow);
		If RowData = Undefined Then 
			Continue;
		EndIf;
		
		If ChangingActionOptionIsAvailable(RowData, NewAction) Then
		
			RowData.WhatToDo = NewAction;
			StringsChanged   = StringsChanged + 1;
			If FormTableName = "LoadingSettingsProcessDescriptionsSelection" Then
				 ChangeDataLoadingSettingsProcessDescriptionsAfterChangingSelection(RowData);
			ElsIf FormTableName = "DownloadSettingsGlossarySelection" Then
				 ChangeDataOfGlossaryUploadSettingsAfterChangingSelection(RowData);
			EndIf;
			
		EndIf;
		
	EndDo; 
	
	If FormTableName = "LoadingSettingsProcessDescriptionsSelection" Then
		SetFilters();
	ElsIf FormTableName = "DownloadSettingsGlossarySelection" Then
		FillFilterTable();
	EndIf;
	
	ComparisonIsRequiredUnion            = ThereIsSomethingToCombine(ThisObject);
	ThereIsSomethingToCombine                        = ComparisonIsRequiredUnion;
	PreparationForComparisonAndUnificationHasBeenCompleted = False;
	InstallAssistantNavigator(ThisObject);
	
	DisplayAlertChangedWhatToDo(RowsToChange, StringsChanged);
	
EndProcedure

&AtClient
Procedure DisplayAlertChangedWhatToDo(RowsToChange, StringsChanged)
	
	NotificationTitle = NStr("vi = 'Thay đổi ""Làm gì""';
							|ru = 'Изменение ""Что делать""';
							|en = 'The ""What to do?"" change'; fa = 'The ""What to do?"" change';
							|it = 'Изменение ""Что делать""';
							|pl = 'The ""What to do?"" change';
							|tr = '""Ne yapmalı"" değişikliği'");
	
	If  RowsToChange = 0 Then
		
		MessageText = NStr("vi = 'Chưa chọn dòng nào để có thể thực hiện lệnh';
							|ru = 'Не выделено ни одной строки для которой может быть выполнена команда';
							|en = 'No lines are selected to run the command for'; fa = 'No lines are selected to run the command for';
							|it = 'Не выделено ни одной строки для которой может быть выполнена команда';
							|pl = 'No lines are selected to run the command for';
							|tr = 'Komutun gerçekleştirilebileceği herhangi bir satır seçilmedi'");
		
	ElsIf StringsChanged = 0 Then
		
		MessageText = StrTemplate(NStr("vi = '%1 dòng cần thay đổi, chưa thay đổi bất cứ dòng nào';
										|ru = 'Строк к изменению - %1, ни для одной строки изменение не выполнено';
										|en = 'Lines to change: %1. Changes are not made for any line'; fa = 'Lines to change: %1. Changes are not made for any line';
										|it = 'Строк к изменению - %1, ни для одной строки изменение не выполнено';
										|pl = 'Lines to change: %1. Changes are not made for any line';
										|tr = 'Değiştirilecek satırlar; %1, herhangi bir satır değişiklik yapılmadı'"), RowsToChange);
		
	Else
		
		MessageText = StrTemplate(NStr("vi = 'Đã thay đổi - %1 trong số %2';
										|ru = 'Изменено строк - %1 из %2';
										|en = 'Lines changed: %1 out of %2'; fa = 'Lines changed: %1 out of %2';
										|it = 'Изменено строк - %1 из %2';
										|pl = 'Lines changed: %1 out of %2';
										|tr = 'Değiştirilen satırlar; %2 üzerinden %1'"), StringsChanged, RowsToChange);
		
	EndIf;
	
	ShowUserNotification(NotificationTitle,, MessageText);
	
EndProcedure

&AtClient
Function ActionNameByCommandName(CommandName)
	
	NewAction = Undefined;
	
	If CommandName = "ToImport" Then
		
		NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.ToImport");
		
	ElsIf CommandName = "NotToImport"  Then
		
		NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.NotToImport");
		
	ElsIf CommandName = "NotShouldDelete"  Then
		
		NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.NotShouldDelete");
		
	ElsIf CommandName = "CompareAndMerge"  Then
		
		NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Union");
		
	ElsIf CommandName = "ShouldDelete"  Then
		
		NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Delete");
		
	EndIf;

	Return NewAction;
	
EndFunction

&AtClient
Function ChangingActionOptionIsAvailable(RowData, NewAction)
	
	If NewAction = RowData.WhatToDo Then
		Return False;
	EndIf;
	
	If NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.ToImport") Then
		
		If RowData.StatusOfFiles <> PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInImport") Then
			Return True;
		Else
			Return False;
		EndIf;
		
	ElsIf NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.NotToImport") Then
		
		If RowData.StatusOfFiles <> PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInImport") Then
			Return True;
		Else
			Return False;
		EndIf;
		
	ElsIf NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.NotShouldDelete") Then
		
		If RowData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInImport") Then
			Return True;
		Else
			Return False;
		EndIf;
		
	ElsIf NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Union") Then
		
		If RowData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInImport")
			Or RowData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInInfobase") Then
			Return False;
		Else
			Return True;
		EndIf;
		
	ElsIf NewAction = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Delete") Then
		
		If RowData.StatusOfFiles = PredefinedValue("Enum.ComparisonStatusesOfProcessDetailsFiles.NotInImport") Then
			Return True;
		Else
			Return False;
		EndIf
		
	EndIf;
	
EndFunction

&AtClient
Function ThereAreActionsRequiredToBePerformed() 
	
	If DownloadSettingsGlossary.GetItems().Count() > 0 Then
		Return True;
	EndIf;
	
	ThereAreActionsRequiredToBePerformed = False;
	RequiredActions = ArrayOfRequiredActions();
	
	For Each TreeRow In LoadingSettingsProcessDescriptions.GetItems() Do
		
		CheckIfThereAreRequiredActionsInTreeLine(TreeRow, ThereAreActionsRequiredToBePerformed, RequiredActions); 
		
		If ThereAreActionsRequiredToBePerformed Then
			Break;
		EndIf;
		
	EndDo;
	
	Return ThereAreActionsRequiredToBePerformed;
	
EndFunction

&AtClient
Procedure CheckIfThereAreRequiredActionsInTreeLine(TreeRow, ThereAreActionsRequiredToBePerformed, RequiredActions)
	
	If RequiredActions.Find(TreeRow.WhatToDo) <> Undefined Then
		
		ThereAreActionsRequiredToBePerformed = True;
		Return;
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.GetItems() Do
		
		CheckIfThereAreRequiredActionsInTreeLine(SubordinateRow, ThereAreActionsRequiredToBePerformed, RequiredActions)
		
	EndDo;
	
EndProcedure

&AtClient
Function ArrayOfRequiredActions()
	
	ActionsArray = New Array;
	ActionsArray.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.ToImport"));
	ActionsArray.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Union"));
	ActionsArray.Add(PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Delete"));
	
	Return ActionsArray;
	
EndFunction

&AtClient
Procedure WhenChangingCollectionUploadSettings()
	
	ComparisonIsRequiredUnion            = ThereIsSomethingToCombine(ThisObject);
	ThereIsSomethingToCombine                        = ComparisonIsRequiredUnion;
	PreparationForComparisonAndUnificationHasBeenCompleted = False;
	InstallAssistantNavigator(ThisObject);
	
EndProcedure

#EndRegion 

#Region ComparisonAssociation

&AtClientAtServerNoContext
Function ThereIsSomethingToCombine(Form)
	
	ThereIsSomethingToCombine = False;
	
	FoundRowID = TreeStringSearchResult(Form.LoadingSettingsProcessDescriptions, 
	                                                           PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Union"),
	                                                           "WhatToDo",
	                                                            True);
	
	If FoundRowID <> -1 Then
		
		ThereIsSomethingToCombine = True;
		
	Else
		
		FoundRowID = TreeStringSearchResult(Form.DownloadSettingsGlossary, 
		                                                           PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Union"),
		                                                          "WhatToDo",
		                                                            True);
		
		ThereIsSomethingToCombine = FoundRowID <> -1;
		
	EndIf;
	
	If Not ThereIsSomethingToCombine Then
		
		Form.ComparisonAssociation.Clear();
		
	EndIf;
		
	Return ThereIsSomethingToCombine;
	
EndFunction

&AtClient
Function UploadDirectoryForMerging()
	
	TempFileName = ImportFile; 
	PathSeparator = GetPathSeparator();
	ArrayOfDirectoryStrings = StrSplit(TempFileName, PathSeparator); 
	ArrayOfDirectoryStrings.Delete(ArrayOfDirectoryStrings.Count() - 1); 
	DirectoryOfFilesToMerge = StrConcat(ArrayOfDirectoryStrings, PathSeparator);
	DirectoryOfFilesToMerge = DirectoryOfFilesToMerge + PathSeparator + "ForMerge" + PathSeparator;
	
	If DemoScenariosClientServer.FolderOnDiskExists(DirectoryOfFilesToMerge) Then
		
		DeleteFiles(DirectoryOfFilesToMerge, "*.*");
		
	Else
		
		CreateDirectory(DirectoryOfFilesToMerge);
		
	EndIf;
	
	Return DirectoryOfFilesToMerge;
	
EndFunction

&AtClient
Procedure StartPreparingForComparisonAndMerging()
	
	UploadDirectoryForMerging = UploadDirectoryForMerging();
	
	If Not DemoScenariosClientServer.FolderOnDiskExists(UploadDirectoryForMerging) Then
		
		CreateDirectory(UploadDirectoryForMerging);
		
	Else
		
		DeleteFiles(UploadDirectoryForMerging, GetClientAllFilesMask());
		
	EndIf;
	
	PreparedDataForMerging = PreparedDataForMerging();
	UploadFilesToMergeOnClient(PreparedDataForMerging);
	
	ComparisonIsRequiredUnion                  = False;
	ItRequiresReadingResultsComparingCombining = True;
	PreparationForComparisonAndUnificationHasBeenCompleted       = True;
	InstallAssistantNavigator(ThisObject);
	GoToCompareAndMergePage();

EndProcedure

&AtServer
Function ParametersForPreparingJoinByTreeLine()
	
	PreparationParameters = New Structure;
	PreparationParameters.Insert("PropsNameLink", ""); 
	PreparationParameters.Insert("AttributeNameCode",    "");
	
	Return PreparationParameters;
	
EndFunction

&AtServer
Function PreparedDataForMerging()
	
	ResultOfPreparation = New Map;
	
	For Each TreeRow In LoadingSettingsProcessDescriptions.GetItems() Do
		
		PreparationParameters = ParametersForPreparingJoinByTreeLine();
		PreparationParameters.PropsNameLink = "Scenario";
		PreparationParameters.AttributeNameCode    = "FullCode";
		
		PrepareUnionDataForTreeRow(TreeRow, PreparationParameters, ResultOfPreparation);
		
	EndDo;
	
	For Each TreeRow In DownloadSettingsGlossary.GetItems() Do
		
		PreparationParameters = ParametersForPreparingJoinByTreeLine();
		PreparationParameters.PropsNameLink = "Glossary";
		PreparationParameters.AttributeNameCode    = "Code";
		
		PrepareUnionDataForTreeRow(TreeRow, PreparationParameters, ResultOfPreparation);
		
	EndDo; 
	
	Return ResultOfPreparation;

EndFunction

&AtServer
Procedure PrepareUnionDataForTreeRow(TreeRow, PreparationParameters, DataBeingPrepared)

	If TreeRow.WhatToDo = PredefinedValue("Enum.ActionOptionsWhileImportingProcessDetails.Union") Then
		
		NewRow = ComparisonAssociation.Add();
		FillInTreeLineCompareMergeBySettingsLine(TreeRow, NewRow, PreparationParameters);
		AddFileDataToMerge(DataBeingPrepared, NewRow);
		
	EndIf;
	
	For Each SubordinateRow In TreeRow.GetItems() Do
		
		PrepareUnionDataForTreeRow(SubordinateRow, PreparationParameters, DataBeingPrepared);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInTreeLineCompareMergeBySettingsLine(TreeRow, NewRow, PreparationParameters)
	
	FillPropertyValues(NewRow, TreeRow);
	NewRow.TreeRowID = TreeRow.GetID();
	
	If TreeRow.TypeOfUploadSettingsLine = "Scenario" Then
		
		NewRow.Scenario                = TreeRow[PreparationParameters.PropsNameLink];
		NewRow.FullCode               = TreeRow[PreparationParameters.AttributeNameCode];
		NewRow.DataTypePresentation = NStr("vi = 'Mục tin';
											|ru = 'Рекв.';
											|en = 'Attributes'; fa = 'ویژگی‌ها';
											|it = 'Рекв.';
											|pl = 'Attributes';
											|tr = 'Özni.'");
		
	Else
		
		ParentString = TreeRow.GetParent();
		If ParentString <> Undefined Then
			NewRow.Presentation           = ParentString.Presentation;
			NewRow.Scenario                = ParentString[PreparationParameters.PropsNameLink];
			NewRow.FullCode               = ParentString[PreparationParameters.AttributeNameCode];
			NewRow.DataTypePresentation = TreeRow.LanguageCode;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddFileDataToMerge(DataBeingPrepared, NewRow)

	FileDataByLine = New Structure;
	FileDataByLine.Insert("FileData", Undefined);
	FileDataByLine.Insert("DatabaseData",  Undefined);
	
	TempFileName = GetTempFileName(); 
	PathSeparator = GetPathSeparator();
	ArrayOfDirectoryStrings = StrSplit(TempFileName, PathSeparator); 
	ArrayOfDirectoryStrings.Delete(ArrayOfDirectoryStrings.Count() - 1); 
	DirectoryForPreparingUploadFiles = StrConcat(ArrayOfDirectoryStrings, PathSeparator);
	DirectoryForPreparingUploadFiles = DirectoryForPreparingUploadFiles + PathSeparator + "DesriptionsForMerge" + PathSeparator;
	
	If DemoScenariosClientServer.FolderOnDiskExists(DirectoryForPreparingUploadFiles) Then
		
		DeleteFiles(DirectoryForPreparingUploadFiles, "*.*");
		
	Else
		
		CreateDirectory(DirectoryForPreparingUploadFiles);
		
	EndIf;
	
	TempFileName = DirectoryForPreparingUploadFiles + "TempForMerge";
	
	TextWriter = New TextWriter(TempFileName);
	TextWriter.Write(NewRow.DatabaseData);
	TextWriter.Close();
	
	FileDataByLine.DatabaseData = PutToTempStorage(New BinaryData(TempFileName), UUID); 
	
	DeleteFiles(TempFileName);
	
	TextWriter = New TextWriter(TempFileName);
	TextWriter.Write(NewRow.FileData);
	TextWriter.Close();
	
	FileDataByLine.FileData = PutToTempStorage(New BinaryData(TempFileName), UUID);
	
	DataBeingPrepared.Insert(NewRow.GetID(), FileDataByLine);
	
EndProcedure

&AtClient
Procedure UploadRowDataForMerging(TreeRow, DataToMerge)
	
	FullCodeInString = StrReplace(TreeRow.FullCode, ".", "_");
	
	If TreeRow.TypeOfUploadSettingsLine = "Scenario"  Then
		
		DirectoryName = "Requisites_" + FullCodeInString;
		
	Else
		
		DirectoryName = TreeRow.LanguageCode + "_" + FullCodeInString;
		
	EndIf;
	
	TreeRow.UploadFileDirectory = UploadDirectoryForMerging + DirectoryName + GetPathSeparator();
	
	If Not DemoScenariosClientServer.FolderOnDiskExists(TreeRow.UploadFileDirectory) Then
		
		CreateDirectory(TreeRow.UploadFileDirectory);
		
	EndIf;
	
	UploadFilesToMerge(TreeRow, DataToMerge); 
	
EndProcedure  

&AtClient
Procedure UploadFilesToMerge(TreeRow, DataToMerge)
	
	FilePostfix = ?(TreeRow.TypeOfUploadSettingsLine = "Scenario", ".json",".html");
	
	FileNameInDatabase    = TreeRow.UploadFileDirectory + "InBase" + FilePostfix;
	ImportFileName = TreeRow.UploadFileDirectory + "Upload" + FilePostfix;
	
	FileSavingParameters              = FileSystemClient.FileSavingParameters();
	FileSavingParameters.Interactively = False;
	
	DescriptionOfNotificationAfterSavingMergeFile = New CallbackDescription("AfterSavingFilesForMerging", ThisObject);
	
	FilesToSave = New Array;
	FilesToSave.Add(New TransferableFileDescription(ImportFileName, DataToMerge.Value.FileData));
	FilesToSave.Add(New TransferableFileDescription(FileNameInDatabase, DataToMerge.Value.DatabaseData));
	
	FileSystemClient.SaveFiles(DescriptionOfNotificationAfterSavingMergeFile, FilesToSave, FileSavingParameters);
	
EndProcedure

&AtClient
Procedure AfterSavingFilesForMerging(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadFilesToMergeOnClient(PreparedDataForMerging)
	
	For Each DataToMerge In PreparedDataForMerging Do
		
		TreeRow = ComparisonAssociation.FindByID(DataToMerge.Key);
		If TreeRow = Undefined Then
			Continue;
		EndIf;
		
		UploadRowDataForMerging(TreeRow, DataToMerge);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure FindMergedFilesByMask()
	
	For Each TableRow In ComparisonAssociation Do
		
		FilesData = FindFiles(TableRow.UploadFileDirectory, PathMaskForMergedFiles);
		
		If FilesData.Count() = 1 Then
			
			TableRow.FileToUpload     = FilesData[0].FullName;
			TableRow.NameOfFileToUpload = FilesData[0].Name; 
			
		Else
			
			TableRow.FileToUpload     = "";
			TableRow.NameOfFileToUpload = "";
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure AfterProcessingSelectionOfResultingFile(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FilesFound = FindFiles(AdditionalParameters.CurrentData.FileToUpload);
	
	If FilesFound.Count() = 1 Then
		AdditionalParameters.CurrentData.NameOfFileToUpload = FilesFound[0].Name;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GetResultingFiles()
	
	BinaryFilesData = New Array;
	
	For Each TableRow In ComparisonAssociation Do
		
		MergedFileData = New Structure;
		MergedFileData.Insert("RowID", TableRow.GetID());
		MergedFileData.Insert("BinaryData",      New BinaryData(TableRow.FileToUpload));
		
		BinaryFilesData.Add(MergedFileData);

	EndDo;
	
	If BinaryFilesData.Count() > 0 Then
		
		GetResultingFilesOnServer(BinaryFilesData);
		
	EndIf;
	
	ComparisonIsRequiredUnion                  = False;
	ItRequiresReadingResultsComparingCombining = False;
	
EndProcedure

&AtServer
Procedure GetResultingFilesOnServer(BinaryFilesData)
	
	TempFileName          = GetTempFileName(); 
	PathSeparator             = GetPathSeparator();
	ArrayOfDirectoryStrings         = StrSplit(TempFileName, PathSeparator); 
	ArrayOfDirectoryStrings.Delete(ArrayOfDirectoryStrings.Count() - 1); 
	DirectoryOfFilesToMerge = StrConcat(ArrayOfDirectoryStrings, PathSeparator);
	DirectoryOfFilesToMerge = DirectoryOfFilesToMerge + PathSeparator + "ResultOfMerge" + PathSeparator;
	
	For Each FileData In BinaryFilesData Do
		
		RowOfJoinTable = ComparisonAssociation.FindByID(FileData.RowID);
			
		If RowOfJoinTable = Undefined Then
			Continue;
		EndIf; 
		
		If TypeOf(RowOfJoinTable.Scenario) = Type("CatalogRef.DemoScenarios") Then
			
			TableName = "LoadingSettingsProcessDescriptions"
			
		ElsIf TypeOf(RowOfJoinTable.Scenario) = Type("CatalogRef.Glossary") Then
			
			TableName = "DownloadSettingsGlossary" 
			
		Else
			
			Continue;
			
		EndIf;
		
		SettingsTreeRow = ThisObject[TableName].FindByID(RowOfJoinTable.TreeRowID);
		SettingsTreeRow.MergeResult = GetStringFromBinaryData(FileData.BinaryData);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Load

&AtClient
Procedure StartLoadingScripts()
	
	GoToLoadedPage();
	
	TimeConsumingOperation = LoadingDataIntoInformationDatabaseIsLongTermOperation(UUID);
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		UploadingProcessDescriptionsToInformationDatabaseCompletion(TimeConsumingOperation, AdditionalParameters);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.Title = NStr("vi = 'Kết nhập dữ liệu mô tả quy trình';
									|ru = 'Загрузка данных описаний процессов';
									|en = 'Import process details data'; fa = 'Import process details data';
									|it = 'Загрузка данных описаний процессов';
									|pl = 'Import process details data';
									|tr = 'Süreç ayrıntıları verilerinin yüklenmesi'");
		
		CallbackOnCompletion = New CallbackDescription("UploadingProcessDescriptionsToInformationDatabaseCompletion", ThisObject, AdditionalParameters);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;
	
EndProcedure 

&AtServer
Function LoadingDataIntoInformationDatabaseIsLongTermOperation(Var_UUID)
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Glossary",                      FormAttributeToValue("DownloadSettingsGlossary")); 
	GenerationParameters.Insert("ProcessDescriptionTree",        FormAttributeToValue("LoadingSettingsProcessDescriptions")); 
	GenerationParameters.Insert("Screenshots",                      FormAttributeToValue("Screenshots"));
	GenerationParameters.Insert("SupportPlacementParameters", SupportPlacementParameters());
	GenerationParameters.Insert("UUID",        Var_UUID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(Var_UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Kết nhập dữ liệu mô tả quy trình trong cơ sở thông tin';
														|ru = 'Загрузка данных описаний процессов в информационную базу';
														|en = 'Import process details data to the infobase'; fa = 'Import process details data to the infobase';
														|it = 'Загрузка данных описаний процессов в информационную базу';
														|pl = 'Import process details data to the infobase';
														|tr = 'Süreç ayrıntıları verilerinin infobase''e yüklenmesi'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DataProcessors.ProcessDetailsImport.UploadProcessDescriptionsToInformationDatabase",
	                                                       GenerationParameters, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction

&AtServer
Function SupportPlacementParameters()
	
	SupportPlacementParameters = New Structure;
	SupportPlacementParameters.Insert("OptionOfSettingUpForSupport", OptionOfSettingUpForSupport);
	SupportPlacementParameters.Insert("VendorOfDownloadableDelivery", VendorOfDownloadableDelivery);
	SupportPlacementParameters.Insert("DescriptionOfLoadedDelivery",  DescriptionOfLoadedDelivery);
	SupportPlacementParameters.Insert("ThisIsPartialUpload",         ThisIsPartialUpload);
	
	Return SupportPlacementParameters;
	
EndFunction

&AtClient
Procedure UploadingProcessDescriptionsToInformationDatabaseCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then
		ProcessResultOfLoadingProcessDescriptions(Result, AdditionalParameters);
	EndIf;

EndProcedure

&AtClient
Procedure ProcessResultOfLoadingProcessDescriptions(Result, AdditionalParameters)

	If Not IsTempStorageURL(Result.ResultAddress) Then 
		Return;
	EndIf;
	
	ImportResult1 = GetFromTempStorage(Result.ResultAddress);
	
	If ImportResult1.Success Then
		
		DisplayUploadResultsOnForm(ImportResult1);
		ImportRequired = False;
		ImportIsCompleted = True;
		InstallAssistantNavigator(ThisObject);
		GoToLoadedPage();
		
	EndIf;
	
EndProcedure

&AtClient
Function StringIsResultOfLoadingWithTransitionToList(NavigationCommand, LineWhat, Count )
	
	 PartTitle = StrTemplate("%1 - %2", LineWhat, Count);
	
	Return StringFunctionsClient.FormattedString("<a href=""%1"">%2</a>",
		                                                     NavigationCommand,
		                                                     PartTitle);
	
EndFunction

&AtClient
Procedure DisplayUploadResultsOnForm(ImportResult1)
	
	ResultingLine = New Array; 
	NavigationLinkProcessDescriptionList = "e1cib/command/Catalog.DemoScenarios.Command.DemoScenarios";
	NavigationLinkDescriptionListGlossary = "e1cib/command/Catalog.Glossary.Command.Glossary";
	StringDescription                            = NStr("vi = 'mô tả quy trình';
														|ru = 'описаний процессов';
														|en = 'process details'; fa = 'process details';
														|it = 'описаний процессов';
														|pl = 'process details';
														|tr = 'süreç ayrıntıları'");
	GlossaryLine                           = NStr("vi = 'phần tử thuật ngữ';
													|ru = 'элементов глоссария';
													|en = 'glossary items'; fa = 'glossary items';
													|it = 'элементов глоссария';
													|pl = 'glossary items';
													|tr = 'terim sözlüğü öğeleri'");

	NeedPeriod   = False;
	CommaRequired = False;
	
	ResultingLine.Add(NStr("vi = 'Đã kết nhập thành công.';
							|ru = 'Загрузка завершена.';
							|en = 'Import completed.'; fa = 'Import completed.';
							|it = 'Загрузка завершена.';
							|pl = 'Import completed.';
							|tr = 'Yükleme tamamlandı.'") + " ");
	DownloadData = ImportResult1.DownloadData;	
	
	If DownloadData.UploadedGlossary > 0 
		Or DownloadData.LoadedScripts > 0 Then
		
		ResultingLine.Add(StrTemplate("%1: ", NStr("vi = 'Đã kết nhập';
													|ru = 'Загружено';
													|en = 'Imported'; fa = 'واردشده';
													|it = 'Загружено';
													|pl = 'Imported';
													|tr = 'Yüklendi'")));
		
		If DownloadData.LoadedScripts > 0 Then
			
			ResultingLine.Add(
				StringIsResultOfLoadingWithTransitionToList(NavigationLinkProcessDescriptionList, StringDescription, DownloadData.LoadedScripts));
			
			NeedPeriod   = True;
			CommaRequired = True;
			
		EndIf;
		
		If DownloadData.UploadedGlossary > 0 Then
			
			AddCommaIfNecessary(ResultingLine, CommaRequired);
			
			ResultingLine.Add(
				StringIsResultOfLoadingWithTransitionToList(NavigationLinkDescriptionListGlossary, GlossaryLine, DownloadData.UploadedGlossary));
			
			NeedPeriod   = True;
			
		EndIf;
		
	EndIf;
	
	AddPointIfNecessary(ResultingLine, NeedPeriod); 
	
	If DownloadData.UpdatedGlossary > 0 
		Or DownloadData.UpdatedScripts > 0 Then
		
		ResultingLine.Add(StrTemplate("%1: ", NStr("vi = 'Đã cập nhật';
													|ru = 'Обновлено';
													|en = 'Updated'; fa = 'به‌روزرسانی شد';
													|it = 'Обновлено';
													|pl = 'Updated';
													|tr = 'Güncellendi'")));
		
		If ImportResult1.DownloadData.UpdatedScripts > 0 Then
			
			ResultingLine.Add(
				StringIsResultOfLoadingWithTransitionToList(NavigationLinkProcessDescriptionList, StringDescription, DownloadData.UpdatedScripts));
			
			NeedPeriod   = True;
			CommaRequired = True;
			
		EndIf;
		
		If DownloadData.UpdatedGlossary > 0 Then
			
			AddCommaIfNecessary(ResultingLine, CommaRequired);
			
			ResultingLine.Add(
				StringIsResultOfLoadingWithTransitionToList(NavigationLinkDescriptionListGlossary, GlossaryLine, DownloadData.UpdatedGlossary));
			
			NeedPeriod   = True;
			
		EndIf;
		
	EndIf;
	
	AddPointIfNecessary(ResultingLine, NeedPeriod);
	
	If DownloadData.DeletedScripts > 0 
		Or DownloadData.GlossaryRemoved > 0 Then
		
		ResultingLine.Add(StrTemplate("%1: ", NStr("vi = 'Đã xóa';
													|ru = 'Удалено';
													|en = 'Deleted'; fa = 'حذف‌شده';
													|it = 'Удалено';
													|pl = 'Deleted';
													|tr = 'Silindi'")));
		
		If ImportResult1.DownloadData.DeletedScripts > 0 Then
			
			ResultingLine.Add(
				StringIsResultOfLoadingWithTransitionToList(NavigationLinkProcessDescriptionList, StringDescription, DownloadData.DeletedScripts));
			
			NeedPeriod   = True;
			CommaRequired = True;
			
		EndIf;
		
		If DownloadData.GlossaryRemoved > 0 Then
			
			AddCommaIfNecessary(ResultingLine, CommaRequired);
			
			ResultingLine.Add(
				StringIsResultOfLoadingWithTransitionToList(NavigationLinkDescriptionListGlossary, GlossaryLine, DownloadData.GlossaryRemoved));
			
			NeedPeriod   = True;
			
		EndIf;
		
	EndIf;
	
	AddPointIfNecessary(ResultingLine, NeedPeriod);
	
	If DownloadData.UploadedGlossary = 0 
		And  DownloadData.LoadedScripts = 0
		And  DownloadData.UpdatedGlossary = 0
		And  DownloadData.UpdatedScripts = 0
		And  DownloadData.DeletedScripts = 0
		And  DownloadData.GlossaryRemoved = 0 Then
		
		ResultingLine.Add(NStr("vi = 'Chưa thay đổi trong cơ sở thông tin.';
								|ru = 'Изменения в информационной базе выполнены не были.';
								|en = 'No changes were made to the infobase.'; fa = 'No changes were made to the infobase.';
								|it = 'Изменения в информационной базе выполнены не были.';
								|pl = 'No changes were made to the infobase.';
								|tr = 'Infobase üzerinde değişiklikler gerçekleştirilmedi.'"));
		
	EndIf;
	
	ResultingLine =  New FormattedString(ResultingLine);
	
	Items.DecorationLoadingResults.Title = ResultingLine;
	
EndProcedure

&AtClient
Procedure AddCommaIfNecessary(ResultingLine, CommaRequired)
	
	If CommaRequired Then
		ResultingLine.Add(", ");
		CommaRequired = False;
	EndIf;
	
EndProcedure 

&AtClient
Procedure AddPointIfNecessary(ResultingLine, NeedPeriod)
	
	If NeedPeriod Then
		ResultingLine.Add(". ");
		NeedPeriod = False;
	EndIf;
	
EndProcedure

#EndRegion 

#EndRegion
