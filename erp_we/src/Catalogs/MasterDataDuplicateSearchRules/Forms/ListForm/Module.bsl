
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Filters = New Structure("MetadataObject");
	FillPropertyValues(Filters, Parameters.Filter);
	If Filters.MetadataObject <> Undefined Then
		Catalog = Filters.MetadataObject;
	EndIf;
	FillInListOfReferenceSelection();
	If Not GetFunctionalOption("ControlItemUniquenessByCombinationValuesAttributes") Then
		ReferencesArrray = New Array;
		ReferencesArrray.Add(Catalogs.MasterDataDuplicateSearchRules.Catalog_Products_BySettingUniquenessOfTypeOfItem);
		ReferencesArrray.Add(Catalogs.MasterDataDuplicateSearchRules.Catalog_ItemsCharacteristics_BySettingUniquenessOfItemType);
		Filter = List.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("Ref");
		Filter.ComparisonType = DataCompositionComparisonType.NotInList;
		Filter.RightValue = ReferencesArrray;
		Filter.Use = True
	EndIf;
	ScheduledJob = FindScheduledJob("SearchForMasterDataDuplicates");
	If ScheduledJob <> Undefined Then
		FindingDuplicatesUsing = ScheduledJob.Use;
		SearchForDuplicatesSchedule    = ScheduledJob.Schedule;
		If FindingDuplicatesUsing Then
			Items.SearchForDuplicatesSchedule.Title = String(ScheduledJob.Schedule);
		EndIf;
	EndIf;
	ScheduledJob = FindScheduledJob("ReplaceMasterDataDuplicates");
	If ScheduledJob <> Undefined Then
		ReplacingDuplicatesUsing = ScheduledJob.Use;
		ReplacingDoublesSchedule    = ScheduledJob.Schedule;
		If ReplacingDuplicatesUsing Then
			ReplacingDoublesSchedule    = ScheduledJob.Schedule;
		EndIf;
	EndIf;
	CountingPlacesWhereDoublesAreUsed = Constants.SearchForMasterDataDuplicateOccurrences.Get();
	SetAvailability();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "RecordedRule" Then 
		FillInListOfReferenceSelection();
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CatalogOnChange(Item)
	Filter = List.Filter.Items;
	Filter.Clear();
	If ValueIsFilled(Catalog) Then
		NewFilter = Filter.Add(Type("DataCompositionFilterItem"));
		NewFilter.LeftValue = New DataCompositionField("MetadataObject");
		NewFilter.Use = True;
		NewFilter.ComparisonType = DataCompositionComparisonType.Equal;
		NewFilter.RightValue = Catalog;
	EndIf;
EndProcedure

&AtClient
Procedure CatalogStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	StandardProcessing = False;
	CompositionSettings = New DataCompositionSettings;  
	
	FilterElement = CompositionSettings.Filter.Items.Add(Type("DataCompositionFilterItem"));
	FilterElement.LeftValue = New DataCompositionField("Ref");
	FilterElement.ComparisonType = DataCompositionComparisonType.InList;
	FilterElement.RightValue = FilterList;
	FilterElement.Use = True;

	FormParameters = New Structure;
	FormParameters.Insert("FixedSettings", CompositionSettings);
	FormParameters.Insert("ChoiceMode", True);
	OpenForm("Catalog.MetadataObjectIDs.ChoiceForm", FormParameters,Item);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShowDuplicatesByRule(Command)
	
	SelectedRows = Items.List.SelectedRows;
	If SelectedRows.Count() = 1 Then
		OpeningParameters = New Structure("Source", Items.List.CurrentData.Ref);
		OpenForm("InformationRegister.MasterDataDuplicatesToConfirm.Form.ListForm", OpeningParameters);
	ElsIf SelectedRows.Count() > 1 Then
		CommonClient.MessageToUser(NStr("ru = 'Необходимо выбрать одно правило';
										|vi = 'Select one rule';
										|en = 'Select one rule'; fa = 'Select one rule';
										|it = 'Select one rule';
										|pl = 'Select one rule';
										|tr = 'Bir kural seçilmelidir'"));
	Else 
		CommonClient.MessageToUser(NStr("ru = 'Не выбрано правило';
										|vi = 'Rule is not selected';
										|en = 'Rule is not selected'; fa = 'Rule is not selected';
										|it = 'Rule is not selected';
										|pl = 'Rule is not selected';
										|tr = 'Kural seçilmedi'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure FindAndRecordDoubles(Command)
	
	SelectedRows = Items.List.SelectedRows;
	If SelectedRows.Count() = 1 Then 
		FindAndRecordDuplicatesCheck(Items.List.CurrentData.Ref);
	ElsIf SelectedRows.Count() > 1 Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("ru = 'Необходимо выбрать одно правило';
										|vi = 'Select one rule';
										|en = 'Select one rule'; fa = 'Select one rule';
										|it = 'Select one rule';
										|pl = 'Select one rule';
										|tr = 'Bir kural seçilmelidir'"));
	Else
		ClearMessages();
		CommonClient.MessageToUser(NStr("ru = 'Не выбрано правило';
										|vi = 'Rule is not selected';
										|en = 'Rule is not selected'; fa = 'Rule is not selected';
										|it = 'Rule is not selected';
										|pl = 'Rule is not selected';
										|tr = 'Kural seçilmedi'"));
	EndIf;
EndProcedure

&AtClient
Procedure GenerateReport(Command)
	
	SelectedRows = Items.List.SelectedRows;
	If SelectedRows.Count() = 1 Then 
		
		ReportParameters = New Structure;
		ReportParameters.Insert("Rule", Items.List.CurrentData.Ref);
		ReportParameters.Insert("GenerateOnOpen", True);
		
		OpenForm("Report.MasterDataDuplicateReport.ObjectForm", ReportParameters);
		
	ElsIf SelectedRows.Count() > 1 Then
		ClearMessages();
		CommonClient.MessageToUser(NStr("ru = 'Отчет строится по одному правилу';
										|vi = 'The report is generated based on one rule';
										|en = 'The report is generated based on one rule'; fa = 'The report is generated based on one rule';
										|it = 'The report is generated based on one rule';
										|pl = 'The report is generated based on one rule';
										|tr = 'Rapor tek bir kurala göre oluşturulur'"));
	Else
		ClearMessages();
		CommonClient.MessageToUser(NStr("ru = 'Не выбрано правило для построения отчета';
										|vi = 'No rule is selected for generating the report';
										|en = 'No rule is selected for generating the report'; fa = 'No rule is selected for generating the report';
										|it = 'No rule is selected for generating the report';
										|pl = 'No rule is selected for generating the report';
										|tr = 'Rapor oluşturmak için kural seçilmedi'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInListOfReferenceSelection()
	Query = New Query;
	Query.Text =
	"SELECT DISTINCT
	|	Rules.MetadataObject AS Ref
	|FROM
	|	Catalog.MasterDataDuplicateSearchRules AS Rules
	|WHERE
	|	NOT Rules.MetadataObject = VALUE(Catalog.MetadataObjectIDs.EmptyRef)"; 
	Filter = Query.Execute().Unload().UnloadColumn("Ref");
	Items.Catalog.ChoiceList.LoadValues(Filter);
	CommonClientServer.SupplementArray(Filter, HierarchyGroups());
	FilterList.LoadValues(Filter);
EndProcedure

&AtClient
Procedure ScenerySetUpScheduleSearchForDuplicatesClick(Item)
	Dialog = New ScheduledJobDialog(SearchForDuplicatesSchedule);
	Dialog.Show(New CallbackDescription("SearchingForDuplicatesAfterScheduleChange", ThisObject));
EndProcedure

&AtClient
Procedure SearchingForDuplicatesAfterScheduleChange(Schedule, ExecutionParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	SearchForDuplicatesSchedule = Schedule;
	Items.SearchForDuplicatesSchedule.Title = String(SearchForDuplicatesSchedule);
	FindingDuplicatesUsing = True;
	WriteScheduledJob("SearchForMasterDataDuplicates", FindingDuplicatesUsing, 
		SearchForDuplicatesSchedule, "SearchForDuplicatesSchedule");
EndProcedure

&AtServer
Procedure WriteScheduledJob(PredefinedItemName, Use, Schedule, DataPathAttribute)
	ScheduledJob = FindScheduledJob(PredefinedItemName);
	
	JobParameters = New Structure;
	JobParameters.Insert("Use", Use);
	JobParameters.Insert("Schedule", Schedule);
	
	ScheduledJobsServer.ChangeJob(ScheduledJob, JobParameters);
	
	If DataPathAttribute <> Undefined Then
		SetAvailability(DataPathAttribute);
	EndIf;
EndProcedure

&AtServer
Function FindScheduledJob(PredefinedItemName)
	Filter = New Structure;
	Filter.Insert("Metadata", PredefinedItemName);
	
	SearchResult = ScheduledJobsServer.FindJobs(Filter);
	Return ?(SearchResult.Count() = 0, Undefined, SearchResult[0]);
EndFunction

&AtServer
Procedure SetAvailability(DataPathAttribute = "")
	If DataPathAttribute = "SearchForDuplicatesSchedule" Or DataPathAttribute = "" Then
		If FindingDuplicatesUsing Then
			SchedulePresentation = String(SearchForDuplicatesSchedule);
			Presentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			Presentation = NStr("ru = 'Настроить расписание';
								|vi = 'Set schedule';
								|en = 'Set schedule'; fa = 'تعیین زمان‌بندی';
								|it = 'Impostare l''orario';
								|pl = 'Ustaw harmonogram';
								|tr = 'Programı ayarlamak'");
		EndIf;
		Items.SearchForDuplicatesSchedule.Title = Presentation;
	EndIf;
	If DataPathAttribute = "ReplacingDoublesSchedule" Or DataPathAttribute = "" Then
		If ReplacingDuplicatesUsing Then
			SchedulePresentation = String(ReplacingDoublesSchedule);
			Presentation = Upper(Left(SchedulePresentation, 1)) + Mid(SchedulePresentation, 2);
		Else
			Presentation = NStr("ru = 'Настроить расписание';
								|vi = 'Set schedule';
								|en = 'Set schedule'; fa = 'تعیین زمان‌بندی';
								|it = 'Impostare l''orario';
								|pl = 'Ustaw harmonogram';
								|tr = 'Programı ayarlamak'");
		EndIf;
		Items.ReplacingDoublesSchedule.Title = Presentation;
	EndIf;
	SeparationDisabled = Not Common.DataSeparationEnabled();
	Items.List.ChangeRowSet = SeparationDisabled
EndProcedure

&AtClient
Procedure ReplacingDoublesScheduleClick(Item)
	Dialog = New ScheduledJobDialog(ReplacingDoublesSchedule);
	Dialog.Show(New CallbackDescription("ReplacingTakesAfterScheduleChange", ThisObject));
EndProcedure

&AtClient
Procedure ReplacingTakesAfterScheduleChange(Schedule, ExecutionParameters) Export
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	ReplacingDoublesSchedule = Schedule;
	Items.ReplacingDoublesSchedule.Title = String(ReplacingDoublesSchedule);
	ReplacingDuplicatesUsing = True;
	WriteScheduledJob("ReplaceMasterDataDuplicates", ReplacingDuplicatesUsing, 
		ReplacingDoublesSchedule, "ReplacingDoublesSchedule");
EndProcedure

&AtClient
Procedure FindingDuplicatesUsingOnChange(Item)
	WriteScheduledJob("SearchForMasterDataDuplicates", FindingDuplicatesUsing, 
		SearchForDuplicatesSchedule, "SearchForDuplicatesSchedule");
EndProcedure

&AtClient
Procedure ReplacingDuplicatesUsingOnChange(Item)
	WriteScheduledJob("ReplaceMasterDataDuplicates", ReplacingDuplicatesUsing, 
		ReplacingDoublesSchedule, "ReplacingDoublesSchedule");
EndProcedure

&AtClient
Procedure CountingPlacesWhereDoublesAreUsedOnChange(Item)
	ChangeValueOfConstant();
EndProcedure

&AtServer
Procedure ChangeValueOfConstant()
	Constants.SearchForMasterDataDuplicateOccurrences.Set(CountingPlacesWhereDoublesAreUsed);
EndProcedure

&AtClient
Procedure MasterDataDuplicates(Command)
	OpenForm("DataProcessor.MasterDataDuplicates.Form.Workplace");
EndProcedure

&AtServer
Function HierarchyGroups()
	Groups = New Array;
	Groups.Add(Catalogs.MetadataObjectIDs.FindByDescription("Catalogs"));
	Groups.Add(Catalogs.MetadataObjectIDs.FindByDescription("Plans kindsof features"));
	Return Groups;
EndFunction

&AtClient
Procedure FindAndRecordDuplicatesCheck(Rule)
	
	ThereAreDuplicatesAccordingToRule = CheckExistenceOfDuplicates(Rule);
	If ThereAreDuplicatesAccordingToRule Then
		QueryText = NStr("ru = 'По данному правилу ранее были зарегистрированы дубли. 
					|При повторном поиске все ранее найденные дубли будут удалены. Продолжить?';
					|vi = 'Duplicates were previously registered according to this rule.
					|If you repeat the search, all previously found duplicates will be deleted. Continue?';
					|en = 'Duplicates were previously registered according to this rule.
					|If you repeat the search, all previously found duplicates will be deleted. Continue?'; fa = 'Duplicates were previously registered according to this rule.
					|If you repeat the search, all previously found duplicates will be deleted. Continue?';
					|it = 'Duplicates were previously registered according to this rule.
					|If you repeat the search, all previously found duplicates will be deleted. Continue?';
					|pl = 'Duplicates were previously registered according to this rule.
					|If you repeat the search, all previously found duplicates will be deleted. Continue?';
					|tr = 'Bu kurala göre daha önce yinelenen öğeler kaydedilmiş. 
					|Tekrar arama yapıldığında daha önce bulunan tüm yinelenen öğeler silinecek. Devam edilsin mi?'");
		ShowQueryBox(New CallbackDescription("FindAndRecordDoublesCompletion", ThisObject, Rule),
					QueryText,
					QuestionDialogMode.YesNo,
					,,,);
	Else
		FindAndRecordDoublesServer(Rule);
		Notify("UpdateWorkplaceDeleteMasterDataDuplicates");
		ShowUserNotification(NStr("ru = 'Дубли найдены и записаны';
									|vi = 'Duplicates are found and saved';
									|en = 'Duplicates are found and saved'; fa = 'Duplicates are found and saved';
									|it = 'Duplicates are found and saved';
									|pl = 'Duplicates are found and saved';
									|tr = 'Yinelenen öğeler bulundu ve kaydedildi'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure FindAndRecordDoublesCompletion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		FindAndRecordDoublesServer(AdditionalParameters);
		Notify("UpdateWorkplaceDeleteMasterDataDuplicates");
		ShowUserNotification(NStr("ru = 'Дубли найдены и записаны';
									|vi = 'Duplicates are found and saved';
									|en = 'Duplicates are found and saved'; fa = 'Duplicates are found and saved';
									|it = 'Duplicates are found and saved';
									|pl = 'Duplicates are found and saved';
									|tr = 'Yinelenen öğeler bulundu ve kaydedildi'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CheckExistenceOfDuplicates(Rule)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	COUNT(DISTINCT MasterDataDuplicatesToConfirm.Duplicate1) AS DuplicateCount
	|FROM
	|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
	|WHERE
	|	MasterDataDuplicatesToConfirm.Source = &Rule";
	Query.SetParameter("Rule", Rule);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		ThereAreDuplicates = Selection.DuplicateCount > 0;
	Else
		ThereAreDuplicates = False;
	EndIf;
	
	Return ThereAreDuplicates;
	
EndFunction

&AtServer
Procedure FindAndRecordDoublesServer(Rule)
	SearchAndReplaceDuplicatesMasterData.ExecuteSearchForMasterDataDuplicates(Rule);
EndProcedure

#EndRegion