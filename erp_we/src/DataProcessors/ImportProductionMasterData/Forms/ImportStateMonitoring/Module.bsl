
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If ValueIsFilled(Parameters.DataSource) Then
		DataSource = Parameters.DataSource;
	Else
		InformationRecords = Catalogs.SourcesToImportProductionMasterData.InformationAboutModeOfWorkingWithSources();
		DataSource = InformationRecords.DataSource;
	EndIf;
	
	FillInServiceDetails();
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	DataSourceSaved = Settings.Get("DataSource");
	
	If DataSourceSaved <> Undefined Then
		If Not ValueIsFilled(DataSource)
				And Common.RefExists(DataSourceSaved) Then
			DataSource = DataSourceSaved;
			FillInAttributesForSource();
			ConfigureDependentFormElements(ThisObject, "DataSource");
		EndIf;
		Settings.Delete("DataSource");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not DataSource.IsEmpty() Then
		
		StartUpdatingErrorCounters();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = ProductDataManagementClientServer.EventNameLoadingEnd()
			And Source = DataSource Then
		
		FillInAttributesForSource();
		
		StartUpdatingErrorCounters();
		
		Items.ErrorList.Refresh();
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataSourceOnChange(Item)
	
	DataSourceWhenModifiedOnServer();
	
	StartUpdatingErrorCounters();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClient
Procedure DisplayReviewedOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "FilterErrors1");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGroupingErrors

&AtClient
Procedure GroupingWhenRowIsActivated(Item)
	
	AttachIdleHandler("Attachable_GroupingWhenRowIsActivated", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersErrorList

&AtClient
Procedure ErrorListOnActivateRow(Item)
	
	AttachIdleHandler("Attachable_ErrorListOnActivateRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure ErrorListOnChange(Item)
	
	StartUpdatingErrorCounters(Items.GroupingErrors.CurrentData.GroupingValue);
	
EndProcedure

&AtServerNoContext
Procedure ErrorListOnGetDataAtServer(TagName, Settings, Rows)
	
	DataProcessors.ImportProductionMasterData.SetDateLayoutInList(Rows, "OccurrenceDate");
	
	CurValueOfDimension = Undefined;
	If Settings.AdditionalProperties.Property("CurValueOfDimension", CurValueOfDimension)
			And (CurValueOfDimension = Enums.ImportMasterDataIssueTypes.ObjectsMapping
				Or CurValueOfDimension = Enums.ImportMasterDataIssueTypes.SearchForObject) Then
		SetLayoutOfDataTypeInList(Rows);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GroupingErrorsWhenChanging(Command)
	
	SetTagOfItemInGroupOfCommands(Items.GroupTypeOfGrouping, Command.Name);
	
	FillInErrorGroupingTable();
	
	StartUpdatingErrorCounters();
	
	ConfigureDependentFormElements(ThisObject, "GroupingErrors");
	
EndProcedure

&AtClient
Procedure GroupingErrorsUpdateList(Command)
	
	FillInErrorGroupingTable();
	
	RestorePositionInErrorGroupingTable(ThisObject);
	
	StartUpdatingErrorCounters();
	
EndProcedure

&AtClient
Procedure GroupingErrorsClearList(Command)
	
	ClearListOfErrors();
	
	Items.ErrorList.Refresh();
	
EndProcedure

&AtClient
Procedure ListOfErrorsReviewed(Command)
	
	SelectedRows = Items.ErrorList.SelectedRows;
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	MarkAsConsidered(SelectedRows);
	
	Items.ErrorList.Refresh();
	
EndProcedure

&AtClient
Procedure ListOfErrorsOpenObject(Command)
	
	CurrentData = Items.ErrorList.CurrentData;
	
	If CurrentData <> Undefined
			And ValueIsFilled(CurrentData.ObjectReference)
			And RefExists(CurrentData.ObjectReference) Then
		ShowValue(, CurrentData.ObjectReference);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListOfErrorsToMatch(Command)
	
	CurrentData = Items.ErrorList.CurrentData;
	
	If CurrentData <> Undefined Then
		
		ValueType = TypeOf(CurrentData.MetadataObject);
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("DataSource",       DataSource);
		AdditionalParameters.Insert("CurrentID", CurrentData.Id);
		AdditionalParameters.Insert("MetadataObject",     CurrentData.MetadataObject);
		AdditionalParameters.Insert("ErrorRecordingKey",     Items.ErrorList.CurrentRow);
		
		FormParameters = New Structure;
		FormParameters.Insert("ChoiceMode", True);
		FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.FoldersAndItems);
		If ValueType = Type("CatalogRef.ObjectsPropertiesValues")
				And ValueIsFilled(CurrentData.ValuesOwner) Then
			FormParameters.Insert("Filter", New Structure("Owner", CurrentData.ValuesOwner));
		EndIf;
		
		Notification = New CallbackDescription("ListOfErrorsToMatchCompletion",
			ThisObject, AdditionalParameters);
		
		OpenForm(NameOfMetadataObjectSelectionForm(ValueType),
			FormParameters,
			ThisObject,,,,
			Notification,
			FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ExecuteImport(Command)
	
	StartDownloadingData();
	
EndProcedure

&AtClient
Procedure MatchingObjects(Command)
	
	OpenForm("DataProcessor.ImportProductionMasterData.Form.MatchingObjects",
		New Structure("DataSource", DataSource),,
		DataSource);
	
EndProcedure

&AtClient
Procedure EventLog(Command)
	
	FormParameters = LogOpeningParameters(DataSource);
	OpenForm("DataProcessor.EventLog.Form", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.GroupingNumberOfErrors.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("GroupingErrors.UpdateIsBeingMade");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "refreshenabled...");
	Item.Appearance.SetParameterValue("Font", StyleFonts.ObliqueTypeImportMasterData);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	//
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.ErrorList.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ErrorList.Discussed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	If ValueIsFilled(Parameters.DataSource) Then
		Items.DataSource.ReadOnly = True;
		Title = StrTemplate(NStr("vi = 'Màn hình kiểm soát trạng thái kết nhập từ nguồn ""%1""';
								|ru = 'Мониторинг состояния загрузки из источника ""%1""';
								|en = 'Monitor the import state from the ""%1"" source'; fa = 'Monitor the import state from the ""%1"" source';
								|it = 'Мониторинг состояния загрузки из источника ""%1""';
								|pl = 'Monitor the import state from the ""%1"" source';
								|tr = 'İndirme durumunu kaynaktan izleme ""%1""'"), DataSource);
	EndIf;
	
	SetTagOfItemInGroupOfCommands(Items.GroupTypeOfGrouping, Commands.GroupingByDataType.Name);
	
	FillInErrorGroupingTable();
	
	SetUpListOfErrors();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("DataSource")
		Or Initialize Then
		
		DataSourceIsFull = Not Form.DataSource.IsEmpty();
		
		Items.GroupingUpdateList.Enabled = DataSourceIsFull;
		Items.GroupClear.Enabled       = DataSourceIsFull;
		Items.GroupTypeOfGrouping.Enabled      = DataSourceIsFull;
		Items.ExecuteImport.Enabled         = DataSourceIsFull;
		Items.EventLog.Enabled         = DataSourceIsFull;
		
	EndIf;
	
	If AttributesStructure1.Property("GroupingErrors")
		Or Initialize Then
		
		Items.GroupTypeOfGrouping.Title = Items[CurCurrentErrorGroupingMode(Form)].Title;
		
	EndIf;
	
	If AttributesStructure1.Property("FilterErrors1")
		Or Initialize Then
		
		CurrentRow = Items.GroupingErrors.CurrentRow;
		If CurrentRow <> Undefined Then
			
			CurrentData = Form.GroupingErrors.FindByID(CurrentRow);
			
			ListParameters = ErrorListParameters(Form, CurrentData);
			
			ArrayOfSelections = CommonClientServer.FindFilterItemsAndGroups(
				Form.ErrorList.SettingsComposer.FixedSettings.Filter, , "GroupingField");
			If ArrayOfSelections.UBound() <> -1 Then
				ArrayOfSelections[0].LeftValue = New DataCompositionField(ListParameters.GroupingField);
				ArrayOfSelections[0].RightValue = CurrentData.GroupingValue;
			Else
				CommonClientServer.SetDynamicListFilterItem(
					Form.ErrorList,
					ListParameters.GroupingField,
					CurrentData.GroupingValue,
					DataCompositionComparisonType.Equal,
					"GroupingField",
					True);
			EndIf;
			CommonClientServer.SetDynamicListFilterItem(
				Form.ErrorList,
				"Discussed",
				Form.DisplayReviewed,
				DataCompositionComparisonType.Equal,,
				Not Form.DisplayReviewed);
			CommonClientServer.SetDynamicListFilterItem(
				Form.ErrorList,
				"DataSource",
				Form.DataSource,
				DataCompositionComparisonType.Equal,,
				True);
			
			// Type of problem
			Items.ErrorListIssueType.Visible = Not CurCurrentErrorGroupingMode(Form) = GroupingModeByIssueType();
			
			// metadata object
			Items.ErrorListMetadataObject.Visible =
				Form.CurValueOfDimension = PredefinedValue("Enum.ImportMasterDataIssueTypes.ObjectsMapping")
					Or Form.CurValueOfDimension = PredefinedValue("Enum.ImportMasterDataIssueTypes.SearchForObject");
			
			// object reference
			Items.ErrorListObjectReference.Visible =
				Not (Form.CurValueOfDimension = PredefinedValue("Enum.ImportMasterDataIssueTypes.DataFileFormat"))
					And Not (Form.CurValueOfDimension = PredefinedValue("Enum.ImportMasterDataIssueTypes.ObjectsMapping"))
					And Not (Form.CurValueOfDimension = PredefinedValue("Enum.ImportMasterDataIssueTypes.SearchForObject"))
					And Not (Form.CurValueOfDimension = PredefinedValue("Enum.ImportMasterDataIssueTypes.DataSourceSettings"));
			Items.ErrorListObjectReference.Title = ListParameters.ObjectPresentation;
				
			Items.InformationLineErrorsDetected.Visible = True;
			Items.DisplayReviewed.Visible = True;
			Items.PageGroupErrorList.CurrentPage = Items.GroupPageErrorListMain;
			
		Else
			Items.InformationLineErrorsDetected.Visible = False;
			Items.DisplayReviewed.Visible = False;
			Items.PageGroupErrorList.CurrentPage = Items.ErrorListGroupPageIsEmpty;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	LongTermOperationsStructure = New Structure("UpdatingTags,DataImport");
	
	FillInAttributesForSource();
	
EndProcedure

&AtServer
Procedure DataSourceWhenModifiedOnServer()
	
	FillInAttributesForSource();
	
EndProcedure

&AtServer
Procedure FillInAttributesForSource()
	
	FillInErrorGroupingTable();
	
	RestorePositionInErrorGroupingTable(ThisObject);
	
	UpdateStateInformation();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTagOfItemInGroupOfCommands(CommandGroup, CommandName)
	
	For Each Item In CommandGroup.ChildItems Do
		Item.Check = (Item.CommandName = CommandName);
	EndDo;
	
EndProcedure

&AtServer
Procedure InterruptLongTermOperation(JobID)
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
EndProcedure

&AtServer
Procedure UpdateStateInformation()
	
	InformationLineLastExecution = "";
	InformationLineErrorsDetected    = "";
	
	If ValueIsFilled(DataSource) Then
		ImportState = InformationRegisters.MasterDataImportSettings.ImportState(DataSource)[0];
		StateProperties = Enums.ImportMasterDataStates.LoadingStateProperties(ImportState.State);
		If StateProperties.State <> Enums.ImportMasterDataStates.DoNotPerformed
				And ValueIsFilled(ImportState.EndDate) Then
			InformationLineLastExecution = StrTemplate(NStr("vi = 'Lần thực hiện gần nhất: %1';
															|ru = 'Последнее выполнение: %1';
															|en = 'Last execution: %1'; fa = 'Last execution: %1';
															|it = 'Последнее выполнение: %1';
															|pl = 'Last execution: %1';
															|tr = 'Son gerçekleştirme: %1'"),
				DataProcessors.ImportProductionMasterData.PresentationOfEventDateInInterface(ImportState.EndDate));
			InformationLineErrorsDetected    = StrTemplate(NStr("vi = 'Lỗi xem xét: %1, vào lần thực hiện gần nhất: %2';
																|ru = 'Ошибок рассмотреть: %1, при последнем выполнении: %2';
																|en = 'Errors to review: %1. Upon the last execution: %2'; fa = 'Errors to review: %1. Upon the last execution: %2';
																|it = 'Ошибок рассмотреть: %1, при последнем выполнении: %2';
																|pl = 'Errors to review: %1. Upon the last execution: %2';
																|tr = 'Hataları incelemek: %1, son gerçekleştirme sırasında: %2'"),
				GroupingErrors.Total("ErrorsCount"),
				ImportState.ErrorsCount);
		EndIf;
		StateInformationLine = StringFunctions.FormattedString(
			NStr("vi = 'Trạng thái kết nhập: <span style=""color: %1""> %2</span>';
				|ru = 'Состояние загрузки: <span style=""color: %1""> %2</span>';
				|en = 'Import state: <span style=""color: %1""> %2</span>'; fa = 'Import state: <span style=""color: %1""> %2</span>';
				|it = 'Состояние загрузки: <span style=""color: %1""> %2</span>';
				|pl = 'Import state: <span style=""color: %1""> %2</span>';
				|tr = 'İndirme durumu: <span style=""color: %1""> %2</span>'"),
			StateProperties.Color,
			StateProperties.State);
	Else
		StateInformationLine = StringFunctions.FormattedString(NStr("vi = 'Chưa chọn nguồn';
																	|ru = 'Источник не выбран';
																	|en = 'Source is not selected'; fa = 'Source is not selected';
																	|it = 'Источник не выбран';
																	|pl = 'Source is not selected';
																	|tr = 'Kaynak seçilmedi'"));
	EndIf;
	
EndProcedure

&AtServerNoContext
Function NameOfMetadataObjectSelectionForm(ValueType)
	
	If ValueType = Type("CatalogRef.Products")
			And GetFunctionalOption("UseItemVariants") Then
		FormName = "DataProcessor.ImportProductionMasterData.Form.ItemMapping";
	Else
		FormName = StrTemplate("%1.ChoiceForm" , Metadata.FindByType(ValueType).FullName());
	EndIf;
	
	Return FormName;
	
EndFunction

&AtClient
Procedure ListOfErrorsToMatchCompletion(Value, ParametersStructure) Export
	
	If Value <> Undefined Then
		
		If RunMapping(Value, ParametersStructure) Then
			
			ShowUserNotification(
				NStr("vi = 'Đã so sánh';
					|ru = 'Сопоставление выполнено';
					|en = 'Mapped'; fa = 'نگاشت‌شده';
					|it = 'Сопоставление выполнено';
					|pl = 'Mapped';
					|tr = 'Karşılaştırma tamamlandı'"));
			
			Items.ErrorList.Refresh();
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Function RunMapping(Value, ParametersStructure)
	
	RegisterParameters = ProductDataManagementClientServer.ParametersOfCorrespondenceRegister(ParametersStructure.MetadataObject);
	
	RecordMatching = InformationRegisters[RegisterParameters.RegisterName].CreateRecordManager(); // InformationRegisterRecord.ItemMappingToImportMasterData, InformationRegisterRecord.ObjectMappingToImportMasterData
	RecordMatching.DataSource = ParametersStructure.DataSource;
	RecordMatching.Id  = ParametersStructure.CurrentID;
	
	If TypeOf(Value) = Type("Structure") Then
		FillPropertyValues(RecordMatching, Value);
	Else
		RecordMatching.MetadataObject = ParametersStructure.MetadataObject;
		RecordMatching.ObjectReference   = Value;
	EndIf;
	
	RecordingError = InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.CreateRecordManager();
	FillPropertyValues(RecordingError, ParametersStructure.ErrorRecordingKey);
	RecordingError.Read();
	RecordingError.Discussed = True;
	
	BeginTransaction();
	Try
		RecordMatching.Write();
		RecordingError.Write();
		Result = True;
		CommitTransaction();
	Except
		RollbackTransaction();
		ErrorPresentation = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Common.MessageToUser(StrTemplate(NStr("vi = 'Không thể ghi lại sự so sánh do nguyên nhân: %1';
												|ru = 'Не удалось записать соответствие по причине: %1';
												|en = 'Cannot save the mapping. Reason: %1'; fa = 'Cannot save the mapping. Reason: %1';
												|it = 'Не удалось записать соответствие по причине: %1';
												|pl = 'Cannot save the mapping. Reason: %1';
												|tr = 'Şu nedenlerle uygunluk kaydedilemedi: %1'"), ErrorPresentation));
		Result = False;
	EndTry;
	
	If Result Then
		CurrentData = GroupingErrors.FindByID(Items.GroupingErrors.CurrentRow);
		If CurrentData <> Undefined Then
			CurrentData.ErrorsCount = CurrentData.ErrorsCount - 1;
			UpdateStateInformation();
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Function LogOpeningParameters(DataSource)
	
	Result = New Structure;
	
	EventsToFilter = New Array;
	EventsToFilter.Add(DataProcessors.ImportProductionMasterData.LogEventKey(DataSource));
	Result.Insert("EventLogEvent", EventsToFilter);
		
	ImportState = InformationRegisters.MasterDataImportSettings.ImportState(DataSource)[0];
	If ValueIsFilled(ImportState.StartDate) Then
		Result.Insert("StartDate", ImportState.StartDate);
	EndIf;
	
	Return Result;
	
EndFunction

#Region GroupingErrors

&AtClient
Procedure Attachable_GroupingWhenRowIsActivated()
	
	CurrentData = Items.GroupingErrors.CurrentData;
	If CurrentData = Undefined Then
		FileFields.Clear();
		Return;
	EndIf;
	
	CurValueOfDimension = CurrentData.GroupingValue;
	
	ListSettings = ErrorList.SettingsComposer.Settings;
	ListSettings.AdditionalProperties.Insert("CurValueOfDimension", CurValueOfDimension);
	
	ConfigureDependentFormElements(ThisObject, "FilterErrors1");
	
EndProcedure

&AtServer
Procedure FillInErrorGroupingTable()
	
	CurCurrentErrorGroupingMode = CurCurrentErrorGroupingMode(ThisObject);
	GroupingErrors.Clear();
	
	If DataSource.IsEmpty() Then
		Return;
	EndIf;
	
	DataSourceSettings = Catalogs.SourcesToImportProductionMasterData.DataSourceSettings(DataSource);
	
	DescriptionOfUploadedData = ProductDataManagement.DescriptionOfUploadedData(DataSourceSettings);
	
	ErrorGroupingTable = GroupingErrors.Unload();
	
	If CurCurrentErrorGroupingMode = GroupingModeByDataTypes() Then
		SettingUpSourceAttributes = Catalogs.SourcesToImportProductionMasterData.SourceAttributeSettings(
			DataSource, DescriptionOfUploadedData);
		For Each StringAttribute In SettingUpSourceAttributes Do
			For Each StringTypeDescription In StringAttribute.AttributeDetails.RefTypesDetails Do
				NewRow = ErrorGroupingTable.Add();
				NewRow.GroupingValue      = StringTypeDescription.MetadataObject;
				NewRow.GroupPresentation = StringTypeDescription.Synonym;
				NewRow.ObjectPresentation     = StringTypeDescription.ObjectPresentation;
				NewRow.FullTypeName            = StringTypeDescription.FullName;
			EndDo;
		EndDo;
		AdditionalReferenceBooks = New Structure;
		AdditionalReferenceBooks.Insert("ProductionStages",          True);
		AdditionalReferenceBooks.Insert("ManufacturingOperations",    True);
		AdditionalReferenceBooks.Insert("ItemsCharacteristics", GetFunctionalOption("UseItemVariants"));
		For Each KeyAndValue In AdditionalReferenceBooks Do
			If KeyAndValue.Value Then
				CatalogMetadata = Metadata.Catalogs.Find(KeyAndValue.Key);
				NewRow = ErrorGroupingTable.Add();
				NewRow.GroupingValue      = Catalogs[KeyAndValue.Key].EmptyRef();
				NewRow.GroupPresentation = CatalogMetadata.Synonym;
				NewRow.ObjectPresentation     = CatalogMetadata.ObjectPresentation;
				NewRow.FullTypeName            = CatalogMetadata.FullName();
			EndIf;
		EndDo;
		NewRow = ErrorGroupingTable.Add();
		NewRow.GroupingValue      = Undefined;
		NewRow.GroupPresentation = NStr("vi = 'Dạng khác';
										|ru = 'Прочее';
										|en = 'Other'; fa = 'سایر';
										|it = 'Прочее';
										|pl = 'Other';
										|tr = 'Diğer'");
		NewRow.Order                  = 1;
		ErrorGroupingTable.GroupBy("Order,GroupingValue,GroupPresentation,FullTypeName,ObjectPresentation");
	ElsIf CurCurrentErrorGroupingMode = GroupingModeByIssueType() Then
		For Each IssueType In Enums.ImportMasterDataIssueTypes Do
			NewRow = ErrorGroupingTable.Add();
			NewRow.GroupingValue = IssueType;
			NewRow.GroupPresentation = String(IssueType);
			NewRow.Order = ?(IssueType = Enums.ImportMasterDataIssueTypes.Other, 1, 0);
		EndDo;
	ElsIf CurCurrentErrorGroupingMode = GroupingModeByFiles() Then
		SectionsArray = ProductDataManagementClientServer.OrderOfProcessingSectionsOfSource(DataSourceSettings);
		For IndexOf = 0 To SectionsArray.UBound() Do
			NewRow = ErrorGroupingTable.Add();
			NewRow.Order = IndexOf;
			NewRow.GroupingValue = SectionsArray[IndexOf];
			NewRow.GroupPresentation = ProductDataManagementClientServer.PresentationOfDataFileByPartitionKey(SectionsArray[IndexOf]);
		EndDo;
		NewRow = ErrorGroupingTable.Add();
		NewRow.GroupingValue      = "";
		NewRow.GroupPresentation = NStr("vi = 'Dạng khác';
										|ru = 'Прочее';
										|en = 'Other'; fa = 'سایر';
										|it = 'Прочее';
										|pl = 'Other';
										|tr = 'Diğer'");
		NewRow.Order                  = ErrorGroupingTable.Count();
	EndIf;
	
	ErrorGroupingTable.Sort("Order,GroupPresentation");
	GroupingErrors.Load(ErrorGroupingTable);
	
EndProcedure

&AtClientAtServerNoContext
Procedure RestorePositionInErrorGroupingTable(Form)
	
	If Form.CurValueOfDimension <> Undefined Then
		FoundRows = Form.GroupingErrors.FindRows(New Structure("GroupingValue", Form.CurValueOfDimension));
		If ValueIsFilled(FoundRows) Then
			Form.Items.GroupingErrors.CurrentRow = FoundRows[0].GetID();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ClearListOfErrors()
	
	ListParameters = ErrorListParameters(ThisObject);
	
	For Each SelectedRow In Items.GroupingErrors.SelectedRows Do
		
		RowData = GroupingErrors.FindByID(SelectedRow);
		RowData.ErrorsCount = 0;
		
		RecordSet = InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.CreateRecordSet();
		RecordSet.Filter[ListParameters.GroupingField].Set(RowData.GroupingValue);
		RecordSet.Write();
		
	EndDo;
	
	UpdateStateInformation();
	
EndProcedure

&AtClientAtServerNoContext
Function CurCurrentErrorGroupingMode(Form)
	
	Result = Undefined;
	
	For Each Item In Form.Items.GroupTypeOfGrouping.ChildItems Do
		If Item.Check Then
			Result = Item.Name;
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Function GroupingModeByDataTypes()
	
	Return "GroupingByDataType";
	
EndFunction

&AtClientAtServerNoContext
Function GroupingModeByIssueType()
	
	Return "GroupingByIssueType";
	
EndFunction

&AtClientAtServerNoContext
Function GroupingModeByFiles()
	
	Return "GroupingByFiles";
	
EndFunction

#EndRegion

#Region ErrorList

&AtClient
Procedure Attachable_ErrorListOnActivateRow()
	
	CurrentRow = Items.ErrorList.CurrentRow;
	If CurrentRow = Undefined Then
		FileFields.Clear();
		Return;
	EndIf;
	
	ListOfErrorsWhenActivatingLineOnServer(CurrentRow);
	
EndProcedure

&AtServer
Procedure ListOfErrorsWhenActivatingLineOnServer(RowID)
	
	Record = InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.CreateRecordManager();
	FillPropertyValues(Record, RowID);
	Record.Read();
	
	ConfigureActionCommandsWithError(Record);
	
	FillInFileFieldTable(Record);
	
EndProcedure

&AtServer
Procedure FillInFileFieldTable(DataOfError)
	
	StructureOfFileFields = DataOfError.FileFields.Get(); // Structure
	
	FileFields.Load(InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.TableOfFileFields(StructureOfFileFields));
	
EndProcedure

&AtServer
Procedure MarkAsConsidered(SelectedRows)
	
	CurrentData = GroupingErrors.FindByID(Items.GroupingErrors.CurrentRow);
	
	For Each SelectedRow In SelectedRows Do
		Record = InformationRegisters.ErrorsThatOccurredWhenImportingProductionMasterData.CreateRecordManager();
		FillPropertyValues(Record, SelectedRow);
		Record.Read();
		Record.Discussed = True;
		Record.Write();
	EndDo;
	
	CurrentData.ErrorsCount = CurrentData.ErrorsCount - SelectedRows.Count();
	
	UpdateStateInformation();
	
EndProcedure

&AtServer
Procedure SetUpListOfErrors()
	
	FieldList = New Array;
	FieldList.Add("MetadataObject");
	
	ErrorList.SetRestrictionsForUseInOrder(FieldList);
	ErrorList.SetRestrictionsForUseInGroup(FieldList);
	
EndProcedure

&AtServerNoContext
Procedure SetLayoutOfDataTypeInList(Rows)
	
	ColumnName       = "MetadataObject";
	CacheOfSubmittedInformation = New Map;
	
	For Each KeyAndValue In Rows Do
		
		ListLine = KeyAndValue.Value;
		If ListLine.Appearance.Get(ColumnName) <> Undefined Then
			
			ValueType   = TypeOf(ListLine.Data[ColumnName]);
			Presentation = CacheOfSubmittedInformation.Get(ValueType);
			
			If Presentation = Undefined Then
				MetadataObjectDetails = Metadata.FindByType(ValueType);
				Presentation = MetadataObjectDetails.Synonym;
				CacheOfSubmittedInformation.Insert(ValueType, Presentation);
			EndIf;
			
			ListLine.Appearance[ColumnName].SetParameterValue("Text", Presentation);
			
		Else
			
			Break;
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ConfigureActionCommandsWithError(DataOfError = Undefined)
	
	If DataOfError <> Undefined Then
		If ValueIsFilled(DataOfError.ObjectReference) Then
			Items.ListOfErrorsOpenObject.Enabled = True;
			Items.ErrorListOpenObjectContext.Enabled = True;
		Else
			Items.ListOfErrorsOpenObject.Enabled = False;
			Items.ErrorListOpenObjectContext.Enabled = False;
		EndIf;
		If DataOfError.IssueType = Enums.ImportMasterDataIssueTypes.ObjectsMapping Then
			Items.ListOfErrorsToMatch.Enabled = True;
			Items.ListOfErrorsMatchContext.Enabled = True;
		Else
			Items.ListOfErrorsToMatch.Enabled = False;
			Items.ListOfErrorsMatchContext.Enabled = False;
		EndIf;
		Items.ListOfErrorsReviewed.Enabled   = True;
	Else
		Items.ListOfErrorsOpenObject.Enabled = False;
		Items.ListOfErrorsToMatch.Enabled   = False;
		Items.ListOfErrorsReviewed.Enabled   = False;
	EndIf;
	
EndProcedure

&AtServer
Function RefExists(ObjectReference)
	
	Return ValueIsFilled(ObjectReference) And Common.RefExists(ObjectReference);
	
EndFunction

#EndRegion

#Region UpdatingErrorCounters

&AtClient
Procedure StartUpdatingErrorCounters(GroupingValue = Undefined)
	
	If LongTermOperationsStructure.UpdatingTags <> Undefined Then
		InterruptLongTermOperation(LongTermOperationsStructure.UpdatingTags.JobID);
	EndIf;
	
	For Each String In GroupingErrors Do
		If GroupingValue = Undefined
			Or String.GroupingValue = GroupingValue Then
			String.UpdateIsBeingMade = True;
			String.ErrorsCount = 0;
		EndIf;
	EndDo;
	
	StartUpdatingErrorCountersOnServer(GroupingValue);
	
	If LongTermOperationsStructure.UpdatingTags <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"UpdatingErrorCountersCompletion", ThisObject);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		TimeConsumingOperationsClient.WaitCompletion(
			LongTermOperationsStructure.UpdatingTags,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartUpdatingErrorCountersOnServer(GroupingValue)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật bộ đếm lỗi.';
														|ru = 'Обновление счетчиков количества ошибок.';
														|en = 'Update error counters.'; fa = 'Update error counters.';
														|it = 'Обновление счетчиков количества ошибок.';
														|pl = 'Update error counters.';
														|tr = 'Hata miktarı sayaçları güncelleme.'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("DataSource",      DataSource);
	ProcedureParameters.Insert("GroupField",     ErrorListParameters(ThisObject).GroupingField);
	ProcedureParameters.Insert("GroupingValue", GroupingValue);
	
	LongTermOperationsStructure.UpdatingTags = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ImportProductionMasterData.NumberOfErrorsByDimensionsInBackground",
		ProcedureParameters, ExecutionParameters);
	
EndProcedure

&AtClient
Procedure UpdatingErrorCountersCompletion(TimeConsumingOperation, AdditionalParameters) Export
	
	LongTermOperationsStructure.UpdatingTags = Undefined;
	
	If TimeConsumingOperation <> Undefined And TimeConsumingOperation.Status = "Completed2" Then
		
		ProcessResultUpdateErrorCounters(TimeConsumingOperation); 
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultUpdateErrorCounters(TimeConsumingOperation)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	For Each String In GroupingErrors Do
		GroupingValue = ?(String.GroupingValue = Undefined,
			Enums.ImportMasterDataIssueTypes.Other,
			String.GroupingValue);
		Count = Result.Get(GroupingValue);
		If Count <> Undefined Then
			String.ErrorsCount = Count;
		EndIf;
		String.UpdateIsBeingMade = False;
	EndDo;
	
	UpdateStateInformation();
	
EndProcedure

&AtClientAtServerNoContext
Function ErrorListParameters(Form, CurrentData = Undefined)
	
	Result = New Structure;
	Result.Insert("GroupingField");
	Result.Insert("ObjectPresentation");
	
	CurCurrentErrorGroupingMode = CurCurrentErrorGroupingMode(Form);
	
	If CurCurrentErrorGroupingMode = GroupingModeByDataTypes() Then
		Result.GroupingField = "MetadataObject";
		If CurrentData <> Undefined Then
			Result.ObjectPresentation = ?(IsBlankString(CurrentData.ObjectPresentation),
				CurrentData.GroupPresentation,
				CurrentData.ObjectPresentation);
		EndIf;
	ElsIf CurCurrentErrorGroupingMode = GroupingModeByIssueType() Then
		Result.GroupingField = "IssueType";
	ElsIf CurCurrentErrorGroupingMode = GroupingModeByFiles() Then
		Result.GroupingField = "SectionKey";
	EndIf;
	
	If Not ValueIsFilled(Result.ObjectPresentation) Then
		Result.ObjectPresentation = NStr("vi = 'Đối tượng';
										|ru = 'Объект';
										|en = 'Object'; fa = 'شیء';
										|it = 'Объект';
										|pl = 'Object';
										|tr = 'Nesne'");
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region RunDataImport

&AtClient
Procedure StartDownloadingData()
	
	If LongTermOperationsStructure.DataImport <> Undefined Then
		Return;
	EndIf;
	
	StartUploadingDataToServer();
	
	If LongTermOperationsStructure.DataImport <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"DataImportCompletion", ThisObject);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
		IdleParameters.MessageText = StrTemplate(NStr("vi = 'Đang kết nhập dữ liệu từ nguồn ""%1""';
														|ru = 'Выполняется загрузка данных из источника ""%1""';
														|en = 'Importing data from the ""%1"" source'; fa = 'Importing data from the ""%1"" source';
														|it = 'Выполняется загрузка данных из источника ""%1""';
														|pl = 'Importing data from the ""%1"" source';
														|tr = '""%1"" kaynağı üzerinden veriler yükleniyor'"), DataSource);
		TimeConsumingOperationsClient.WaitCompletion(
			LongTermOperationsStructure.DataImport,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartUploadingDataToServer()
	
	ActionName = DataProcessors.ImportProductionMasterData.UploadDataAction();
	
	If DataProcessors.ImportProductionMasterData.ActionIsAlreadyInProgress(DataSource, ActionName) Then
		Common.MessageToUser(StrTemplate(NStr("vi = 'Đang kết nhập dữ liệu từ nguồn ""%1';
												|ru = 'Загрузка данных из источника ""%1"" уже выполняется';
												|en = 'Data from the ""%1"" source is already being imported'; fa = 'Data from the ""%1"" source is already being imported';
												|it = 'Загрузка данных из источника ""%1"" уже выполняется';
												|pl = 'Data from the ""%1"" source is already being imported';
												|tr = '""%1"" kaynağı üzerinden veri yükleme zaten gerçekleştiriliyor'"), DataSource));
		Return;
	EndIf;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobKey         = DataProcessors.ImportProductionMasterData.KeyForPerformingActionInBackground(DataSource, ActionName);
	ExecutionParameters.BackgroundJobDescription = DataProcessors.ImportProductionMasterData.NameOfActionInBackground(ActionName);
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("ActionName",    ActionName);
	ProcedureParameters.Insert("DataSource", DataSource);
	
	LongTermOperationsStructure.DataImport = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ImportProductionMasterData.PerformActionInBackground",
		ProcedureParameters, ExecutionParameters);
		
EndProcedure

&AtClient
Procedure DataImportCompletion(TimeConsumingOperation, AdditionalParameters) Export
	
	LongTermOperationsStructure.DataImport = Undefined;
	
	If TimeConsumingOperation <> Undefined Then
		
		TextTitle_ = NStr("vi = 'Kết nhập dữ liệu';
							|ru = 'Загрузка данных';
							|en = 'Data import'; fa = 'ورود داده';
							|it = 'Download dei dati';
							|pl = 'Pobieranie danych';
							|tr = 'Veri yükleme'");
		MessageText = "";
		Picture       = Undefined;
		
		If TimeConsumingOperation.Status = "Error" Then
			
			MessageText = StrTemplate(NStr("vi = 'Đã hoàn tất kết nhập dữ liệu thất bại.
					|%1
					|Chi tiết xem tại chỗ làm việc ""Màn hình theo dõi trạng thái kết nhập"" hoặc trong nhật ký sự kiện.';
					|ru = 'Загрузка данных завершилась неудачно.
					|%1
					|Подробности см. в рабочем месте ""Мониторинг состояния загрузки"" или в журнале регистрации.';
					|en = 'Data is not imported.
					|%1
					|For more information, see the ""Import state monitoring"" workspace or the event log.'; fa = 'Data is not imported.
					|%1
					|For more information, see the ""Import state monitoring"" workspace or the event log.';
					|it = 'Загрузка данных завершилась неудачно.
					|%1
					|Подробности см. в рабочем месте ""Мониторинг состояния загрузки"" или в журнале регистрации.';
					|pl = 'Data is not imported.
					|%1
					|For more information, see the ""Import state monitoring"" workspace or the event log.';
					|tr = 'Veri yüklemesi başarısız oldu.
					|%1
					|Ayrıntılar için çalışma alanında ""Yükleme Durumunu İzleme""ye veya olay günlüğüne bakın.'"),
				TimeConsumingOperation.BriefErrorDescription);
			Picture = PictureLib.Error32;
			
		EndIf;
		
		If Not IsBlankString(MessageText) Then
			ShowUserNotification(TextTitle_,,MessageText, Picture);
		EndIf;
		
	EndIf;
	
	Notify(
		ProductDataManagementClientServer.EventNameLoadingEnd(),,
		DataSource);
	
EndProcedure

#EndRegion

#EndRegion
