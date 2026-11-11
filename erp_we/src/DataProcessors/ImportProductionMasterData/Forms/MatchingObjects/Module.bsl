
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
		
		StartUpdatingObjectCountersForMatching();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DataSourceOnChange(Item)
	
	DataSourceWhenModifiedOnServer();
	
	StartUpdatingObjectCountersForMatching();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDataTypes

&AtClient
Procedure DataTypesOnActivateRow(Item)
	
	AttachIdleHandler("Attachable_DataTypesOnActivateRow", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMatchingObjects

&AtClient
Procedure MatchingObjectsOnChange(Item)
	
	StartUpdatingObjectCountersForMatching(Items.DataTypes.CurrentData.MetadataObject);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FillIDs(Command)
	
	Notification = New CallbackDescription("FillIDsCompletion", ThisObject);
	
	ShowQueryBox(Notification,
		NStr("vi = 'Sẽ điền tên định danh đối tượng từ tệp dữ liệu để so sánh tiếp theo.
			| Giao dịch có thể mất nhiều thời gian. Tiếp tục?';
			|ru = 'Будет произведено заполнение идентификаторов объектов из файлов данных для последующего сопоставления.
			|Операция может занять длительное время. Продолжить?';
			|en = 'Object IDs will be filled from the data files and mapped afterwards.
			|The operation might take some time. Continue?'; fa = 'Object IDs will be filled from the data files and mapped afterwards.
			|The operation might take some time. Continue?';
			|it = 'Будет произведено заполнение идентификаторов объектов из файлов данных для последующего сопоставления.
			|Операция может занять длительное время. Продолжить?';
			|pl = 'Object IDs will be filled from the data files and mapped afterwards.
			|The operation might take some time. Continue?';
			|tr = 'Veri dosyalarındaki nesne tanımlayıcıları daha sonra eşleştirmek için doldurulacaktır.
			|İşlem uzun sürebilir. Devam et?'"),
		QuestionDialogMode.YesNo)
	
EndProcedure

&AtClient
Procedure DataTypesUpdateList(Command)
	
	UpdateData1();
	
EndProcedure

&AtClient
Procedure DataTypesShow(Command)
	
	SetTagOfItemInGroupOfCommands(Items.DataTypesGroupShow, Command.Name);
	
	ConfigureDependentFormElements(ThisObject, "DataTypesSelection");
	
EndProcedure

&AtClient
Procedure MatchingObjectsShow(Command)
	
	SetTagOfItemInGroupOfCommands(Items.MatchingObjectsGroupShow, Command.Name);
	
	ConfigureDependentFormElements(ThisObject, "MatchingObjectsSelection");
	
EndProcedure

&AtClient
Procedure LoadMappedObjectsFromFile(Command)
	
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure ImportStateMonitoring(Command)
	
	OpenForm("DataProcessor.ImportProductionMasterData.Form.ImportStateMonitoring",
		New Structure("DataSource", DataSource),,
		DataSource);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.DataTypesNumberOfObjects.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("DataTypes.UpdateIsBeingMade");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Text", "refreshenabled...");
	Item.Appearance.SetParameterValue("Font", StyleFonts.ObliqueTypeImportMasterData);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	If ValueIsFilled(Parameters.DataSource) Then
		Items.DataSource.ReadOnly = True;
		Title = StrTemplate(NStr("vi = 'So sánh các đối tượng của nguồn ""%1""';
								|ru = 'Соответствие объектов источника ""%1""';
								|en = 'Map objects of the ""%1"" source'; fa = 'Map objects of the ""%1"" source';
								|it = 'Соответствие объектов источника ""%1""';
								|pl = 'Map objects of the ""%1"" source';
								|tr = 'Kaynak nesne eşleşmesi ""%1""'"), DataSource);
	EndIf;
	
	SetTagOfItemInGroupOfCommands(Items.DataTypesGroupShow,           Commands.DataTypesAreAll.Name);
	SetTagOfItemInGroupOfCommands(Items.MatchingObjectsGroupShow, Commands.MatchingObjectsAll.Name);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("DataSource")
		Or Initialize Then
		
		Items.DataTypesFillIDs.Enabled = Not Form.DataSource.IsEmpty();
		Items.DataTypesDataTypesUpdateList.Enabled = Not Form.DataSource.IsEmpty();
		Items.DataTypesGroupShow.Enabled = Not Form.DataSource.IsEmpty();
		
	EndIf;
	
	If AttributesStructure1.Property("DataTypesSelection")
		Or Initialize Then
			
		For Each Item In Form.Items.DataTypesGroupShow.ChildItems Do
			If Item.Check Then
				If Item.CommandName = "DataTypesAreAll" Then
					RowFilter = New FixedStructure;
				Else
					RowFilter = New FixedStructure("Downloadable", Item.CommandName = "DataTypesToLoad");
				EndIf;
				Items.DataTypes.RowFilter = RowFilter;
				Items.DataTypesGroupShow.Title = StrTemplate(NStr("vi = 'Hiển thị: %1';
																	|ru = 'Показать: %1';
																	|en = 'Show: %1'; fa = 'Show: %1';
																	|it = 'Показать: %1';
																	|pl = 'Show: %1';
																	|tr = 'Göster: %1'"), Item.Title);
				Break;
			EndIf;
		EndDo;
			
	EndIf;
	
	If AttributesStructure1.Property("MatchingObjectsSelection")
		Or Initialize Then
		
		For Each Item In Items.MatchingObjectsGroupShow.ChildItems Do
			If Item.Check Then
				CommonClientServer.SetDynamicListFilterItem(
					Form.MatchingObjects,
					"Matched",
					(Item.CommandName = "MatchingObjectsMatched"),
					DataCompositionComparisonType.Equal,,
					Not (Item.CommandName = "MatchingObjectsAll"));
				Items.MatchingObjectsGroupShow.Title = StrTemplate(NStr("vi = 'Hiển thị: %1';
																		|ru = 'Показать: %1';
																		|en = 'Show: %1'; fa = 'Show: %1';
																		|it = 'Показать: %1';
																		|pl = 'Show: %1';
																		|tr = 'Göster: %1'"), Item.Title);
				Break;
			EndIf;
		EndDo;
		
	EndIf;
	
	If AttributesStructure1.Property("DataTypes")
		Or Initialize Then
		
		CurrentRow = Items.DataTypes.CurrentRow;
		If CurrentRow <> Undefined Then
			CurrentData = Form.DataTypes.FindByID(CurrentRow);
			For Each FilterField In StrSplit("DataSource,MetadataObject",",") Do
				CommonClientServer.SetDynamicListFilterItem(
					Form.MatchingObjects,
					FilterField,
					?(CurrentData.Property(FilterField), CurrentData[FilterField], Form[FilterField]),
					DataCompositionComparisonType.Equal,,
					True);
			EndDo;
			RegisterParameters = ProductDataManagementClientServer.ParametersOfCorrespondenceRegister(CurrentData.MetadataObject);
			For Each Item In Items.MatchingObjectsGroupObject.ChildItems Do
				Item.Visible = RegisterParameters.ObjectFieldsAvailable.Find(StrSplit(Item.Name,"_")[1]) <> Undefined;
			EndDo;
			Items.MatchingObjects_ObjectReference.Title = ?(
				IsBlankString(CurrentData.ObjectPresentation), CurrentData.Presentation, CurrentData.ObjectPresentation);
			Items.GroupPagesObjects.CurrentPage = Items.GroupPageMappedObjects;
		Else
			Items.GroupPagesObjects.CurrentPage = Items.PageGroupIsEmpty;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	LongTermOperationsStructure = New Structure("FillingInIds,UpdatingTags");
	
	FillInAttributesForSource();
	
EndProcedure

&AtServer
Procedure FillInAttributesForSource()
	
	FillInDataTypes();
	
EndProcedure

&AtServer
Procedure DataSourceWhenModifiedOnServer()
	
	FillInAttributesForSource();
	
	SetTagOfItemInGroupOfCommands(Items.DataTypesGroupShow,           Commands.DataTypesAreAll.Name);
	SetTagOfItemInGroupOfCommands(Items.MatchingObjectsGroupShow, Commands.MatchingObjectsAll.Name);
	
EndProcedure

&AtServer
Procedure FillInDataTypes()
	
	DataTypes.Clear();
	
	If DataSource.IsEmpty() Then
		Return;
	EndIf;
	
	DataSourceSettings = Catalogs.SourcesToImportProductionMasterData.DataSourceSettings(DataSource);
	
	DescriptionOfUploadedData = ProductDataManagement.DescriptionOfUploadedData(DataSourceSettings);
	
	Filter = New Structure;
	Filter.Insert("ExcludeWaysToSetValue", CommonClientServer.ValueInArray(Enums.ImportMasterDataMethodsToSetAttributeValue.SetValueTo));
	
	SettingUpSourceAttributes = Catalogs.SourcesToImportProductionMasterData.SourceAttributeSettings(
		DataSource, DescriptionOfUploadedData, Filter);
	
	Table = DataTypes.Unload();
	For Each StringAttribute In SettingUpSourceAttributes Do
		For Each StringTypeDescription In StringAttribute.AttributeDetails.RefTypesDetails Do
			NewRow = Table.Add();
			NewRow.MetadataObject     = StringTypeDescription.MetadataObject;
			NewRow.Presentation        = StringTypeDescription.Synonym;
			NewRow.ObjectPresentation = StringTypeDescription.ObjectPresentation;
			NewRow.FullTypeName        = StringTypeDescription.FullName;
			NewRow.Downloadable          = DescriptionOfUploadedData.Property(StringTypeDescription.Name);
		EndDo;
	EndDo;
	
	Table.GroupBy("MetadataObject,Presentation,ObjectPresentation,FullTypeName,Downloadable");
	Table.Sort("Presentation");
	
	DataTypes.Load(Table);
	
EndProcedure

&AtClient
Procedure Attachable_DataTypesOnActivateRow()
	
	CurrentData = Items.DataTypes.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	DataTypesWhenActivatingRowOnServer();
	
EndProcedure

&AtServer
Procedure DataTypesWhenActivatingRowOnServer()
	
	CurrentData = DataTypes.FindByID(Items.DataTypes.CurrentRow);
	
	CurrentMetadataObject1 = CurrentData.MetadataObject;
	
	SetPropertiesOfMatchingObjectsList(CurrentData);
	
	ConfigureDependentFormElements(ThisObject, "DataTypes");
	
EndProcedure
	
&AtServer
Procedure SetPropertiesOfMatchingObjectsList(CurrentData)
	
	RegisterParameters = ProductDataManagementClientServer.ParametersOfCorrespondenceRegister(CurrentData.MetadataObject);
	
	QueryText = "
	|SELECT
	|	Table.DataSource                 AS DataSource,
	|	Table.Id                  AS Id,
	|	Table.ExternalSystemPresentation    AS ExternalSystemPresentation,
	|	Table.RecordDate                     AS RecordDate,
	|	Table.Matched                   AS Matched,
	|	&ObjectFieldsRedefinition
	|FROM
	|	&TableName AS Table
	|
	|";
	
	ObjectFieldsRedefinition = New Array;
	For Each KeyAndValue In RegisterParameters.ObjectFieldsRedefinition Do
		FieldText = ?(ValueIsFilled(KeyAndValue.Value), KeyAndValue.Value, KeyAndValue.Key);
		FieldText = StrReplace(FieldText, "&TableName", "Table");
		FieldText = StrReplace(FieldText, "&TypeName", CurrentData.FullTypeName);
		ObjectFieldsRedefinition.Add(StrTemplate("%1 AS %2", FieldText, KeyAndValue.Key));
	EndDo;
	
	QueryText = StrReplace(QueryText, "&TableName", RegisterParameters.TableName);
	QueryText = StrReplace(QueryText, "&ObjectFieldsRedefinition", StrConcat(ObjectFieldsRedefinition,","));
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = RegisterParameters.TableName;
	ListProperties.QueryText    = QueryText;
	Common.SetDynamicListProperties(Items.MatchingObjects, ListProperties);
	
EndProcedure
	
&AtClientAtServerNoContext
Procedure SetTagOfItemInGroupOfCommands(CommandGroup, CommandName)
	
	For Each Item In CommandGroup.ChildItems Do
		Item.Check = (Item.CommandName = CommandName);
	EndDo;
	
EndProcedure

&AtClient
Procedure RestorePositionInListOfDataTypes()
	
	If CurrentMetadataObject1 <> Undefined Then
		FoundRows = DataTypes.FindRows(New Structure("MetadataObject", CurrentMetadataObject1));
		If ValueIsFilled(FoundRows) Then
			Items.DataTypes.CurrentRow = FoundRows[0].GetID();
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure UpdateData1()
	
	FillInDataTypes();
	
	RestorePositionInListOfDataTypes();
	
	StartUpdatingObjectCountersForMatching();
	
	Items.MatchingObjects.Refresh();
	
EndProcedure

#Region LoadingIds

&AtClient
Procedure FillIDsCompletion(Result, AddlParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		
		StartFillingInIdsFromDataFiles();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure StartFillingInIdsFromDataFiles()
	
	If LongTermOperationsStructure.FillingInIds <> Undefined Then
		Return;
	EndIf;
	
	StartFillingInIdsFromDataFilesOnServer();
	
	If LongTermOperationsStructure.FillingInIds <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"FillingInIdsFromDataFilesEnd", ThisObject);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = True;
		IdleParameters.MessageText = NStr("vi = 'Đang điền tên định danh từ tệp dữ liệu.';
											|ru = 'Производится заполнение идентификаторов из файлов данных.';
											|en = 'Filling IDs from the data files.'; fa = 'Filling IDs from the data files.';
											|it = 'Производится заполнение идентификаторов из файлов данных.';
											|pl = 'Filling IDs from the data files.';
											|tr = 'Tanımlayıcılar veri dosyalarından doldurulur.'");
		TimeConsumingOperationsClient.WaitCompletion(
			LongTermOperationsStructure.FillingInIds,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartFillingInIdsFromDataFilesOnServer()
	
	ActionName = DataProcessors.ImportProductionMasterData.ActionFillInIds();
	
	If DataProcessors.ImportProductionMasterData.ActionIsAlreadyInProgress(DataSource, ActionName) Then
		Common.MessageToUser(StrTemplate(NStr("vi = 'Đang điền tên định danh theo nguồn ""%1""';
												|ru = 'Заполнение идентификаторов по источнику ""%1"" уже выполняется';
												|en = 'IDs by the ""%1"" source are already being filled'; fa = 'IDs by the ""%1"" source are already being filled';
												|it = 'Заполнение идентификаторов по источнику ""%1"" уже выполняется';
												|pl = 'IDs by the ""%1"" source are already being filled';
												|tr = 'Tanımlayıcıların ""%1"" kaynağa göre doldurulması artık yapılıyor'"), DataSource));
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
	
	LongTermOperationsStructure.FillingInIds = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ImportProductionMasterData.PerformActionInBackground",
		ProcedureParameters, ExecutionParameters);
	
EndProcedure

&AtClient
Procedure FillingInIdsFromDataFilesEnd(TimeConsumingOperation, AdditionalParameters) Export
	
	LongTermOperationsStructure.FillingInIds = Undefined;
	
	If TimeConsumingOperation <> Undefined Then
		
		TextTitle_ = NStr("vi = 'Điền tên định danh';
							|ru = 'Заполнение идентификаторов';
							|en = 'Fill IDs'; fa = 'Fill IDs';
							|it = 'Заполнение идентификаторов';
							|pl = 'Fill IDs';
							|tr = 'Tanımlayıcıların doldurulması'");
		MessageText = "";
		Picture       = Undefined;
		
		If TimeConsumingOperation.Status = "Completed2" Then
			
			Result = ProcessResultOfFillingInIds(TimeConsumingOperation);
			
			ErrorsCount         = Result.ErrorsCount;
			IdsFilledIn = Result.StructureOfCounters.IdsFilledIn;
			
			If ErrorsCount > 0 Then
				MessageText = NStr("vi = 'Khi điền tên định danh đã xảy ra lỗi.
					|Chi tiết xem trong chỗ làm việc ""Màn hình trạng thái kết nhập"" hoặc trong nhật ký sự kiện.';
					|ru = 'При заполнении идентификаторов возникли ошибки.
					|Подробности см. в рабочем месте ""Мониторинг состояния загрузки"" или в журнале регистрации.';
					|en = 'Errors occurred when filling IDs.
					|For more information, see the ""Import state monitoring"" workspace or the event log.'; fa = 'Errors occurred when filling IDs.
					|For more information, see the ""Import state monitoring"" workspace or the event log.';
					|it = 'При заполнении идентификаторов возникли ошибки.
					|Подробности см. в рабочем месте ""Мониторинг состояния загрузки"" или в журнале регистрации.';
					|pl = 'Errors occurred when filling IDs.
					|For more information, see the ""Import state monitoring"" workspace or the event log.';
					|tr = 'Tanımlayıcılar doldurulurken hatalar oluştu.
					|Ayrıntılar için ""İndirme durumunun izlenmesi"" çalışma alanına veya kayıt günlüğüne bak.'");
				Picture = PictureLib.Error32;
			ElsIf IdsFilledIn > 0 Then
				MessageText = StrTemplate(NStr("vi = 'Đã hoàn tất thành công việc điền tên định danh.
					|Tên định danh mới để so sánh: %1';
					|ru = 'Заполнение идентификаторов успешно завершено.
					|Новых идентификаторов для сопоставления: %1';
					|en = 'IDs are filled.
					|New IDs to map: %1'; fa = 'IDs are filled.
					|New IDs to map: %1';
					|it = 'Заполнение идентификаторов успешно завершено.
					|Новых идентификаторов для сопоставления: %1';
					|pl = 'IDs are filled.
					|New IDs to map: %1';
					|tr = 'Tamamlayıcıların doldurulması başarıyla tamamlandı.
					|Karşılaştırma için yeni kimlikler: %1'"), IdsFilledIn);
				Picture = PictureLib.Success32;
			Else
				MessageText = NStr("vi = 'Đã điền xong tên định danh.';
									|ru = 'Заполнение идентификаторов завершено.';
									|en = 'IDs are filled.'; fa = 'IDs are filled.';
									|it = 'Заполнение идентификаторов завершено.';
									|pl = 'IDs are filled.';
									|tr = 'Tanımlayıcıların doldurulması tamamlandı.'");
				Picture = PictureLib.Information32;
			EndIf;
		
		ElsIf TimeConsumingOperation.Status = "Error" Then
			MessageText = NStr("vi = 'Không thể điền tên định danh.
				|Chi tiết xem trong chỗ làm việc ""Màn hình trạng thái kết nhập"" hoặc trong nhật ký sự kiện.';
				|ru = 'Не удалось заполнить идентификаторы.
				|Подробности см. в рабочем месте ""Мониторинг состояния загрузки"" или в журнале регистрации.';
				|en = 'Cannot fill IDs.
				|For more information, see the ""Import state monitoring"" workspace or the event log.'; fa = 'Cannot fill IDs.
				|For more information, see the ""Import state monitoring"" workspace or the event log.';
				|it = 'Не удалось заполнить идентификаторы.
				|Подробности см. в рабочем месте ""Мониторинг состояния загрузки"" или в журнале регистрации.';
				|pl = 'Cannot fill IDs.
				|For more information, see the ""Import state monitoring"" workspace or the event log.';
				|tr = 'Tanımlayıcılar doldurulamadı.
				|Ayrıntılar için ""Yükleme durumu izleme"" çalışma alanına veya olay günlüğüne bak.'");
			Picture = PictureLib.Error32;
		EndIf;
		
		If Not IsBlankString(MessageText) Then
			ShowUserNotification(TextTitle_,,MessageText, Picture);
		EndIf;
		
	EndIf;
	
	UpdateData1();
	
EndProcedure

&AtServer
Function ProcessResultOfFillingInIds(TimeConsumingOperation)
	
	Return GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
EndFunction

#EndRegion

#Region UpdatingObjectCountersForMatching

&AtClient
Procedure StartUpdatingObjectCountersForMatching(MetadataObjects = Undefined)
	
	If LongTermOperationsStructure.UpdatingTags <> Undefined Then
		Return;
	EndIf;
	
	MetadataObjectsArray = New Array;

	For Each String In DataTypes Do
		If MetadataObjects = Undefined 
			Or MetadataObjects = String.MetadataObject
			Or (TypeOf(MetadataObjects) = Type("Array") And MetadataObjects.Find(String.MetadataObject) <> Undefined) Then
			String.UpdateIsBeingMade = True;
			String.QuantityToMatch = 0;
			MetadataObjectsArray.Add(String.MetadataObject);
		EndIf;
	EndDo;
	
	If MetadataObjectsArray.UBound() = -1 Then
		Return;
	EndIf;
	
	StartUpdatingObjectCountersForMatchingOnServer(MetadataObjectsArray);
	
	If LongTermOperationsStructure.UpdatingTags <> Undefined Then
		
		CallbackDescription = New CallbackDescription(
			"UpdatingObjectCountersForMatchingCompletion", ThisObject);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		TimeConsumingOperationsClient.WaitCompletion(
			LongTermOperationsStructure.UpdatingTags,
			CallbackDescription,
			IdleParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure StartUpdatingObjectCountersForMatchingOnServer(MetadataObjects)
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground              = True;
	ExecutionParameters.WaitCompletion           = 0;
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật bộ đếm đối tượng đã so sánh.';
														|ru = 'Обновление счетчиков сопоставленных объектов.';
														|en = 'Update the counters of mapped objects.'; fa = 'Update the counters of mapped objects.';
														|it = 'Обновление счетчиков сопоставленных объектов.';
														|pl = 'Update the counters of mapped objects.';
														|tr = 'Eşleşen nesneler için sayaçları güncelleme.'");
	
	ProcedureParameters = New Structure;
	ProcedureParameters.Insert("DataSource", DataSource);
	ProcedureParameters.Insert("MetadataObjects", MetadataObjects);
	
	LongTermOperationsStructure.UpdatingTags = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.ImportProductionMasterData.MetadataObjectsToMatchInBackground",
		ProcedureParameters, ExecutionParameters);
	
EndProcedure

&AtClient
Procedure UpdatingObjectCountersForMatchingCompletion(TimeConsumingOperation, AdditionalParameters) Export
	
	LongTermOperationsStructure.UpdatingTags = Undefined;
	
	If TimeConsumingOperation <> Undefined And TimeConsumingOperation.Status = "Completed2" Then
		
		ProcessResultOfUpdatingObjectCountersForMatching(TimeConsumingOperation);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessResultOfUpdatingObjectCountersForMatching(TimeConsumingOperation)
	
	Result = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
	
	For Each String In DataTypes Do
		Count = Result.Get(String.MetadataObject);
		If Count <> Undefined Then
			String.QuantityToMatch = Count;
		EndIf;
		String.UpdateIsBeingMade = False;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion
