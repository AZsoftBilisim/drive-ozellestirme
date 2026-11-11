#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SelectionList = Items.FilterByState.ChoiceList;
	SelectionList.Clear();
	SelectionList.Add(Enums.MasterDataDuplicateDeletionStates.EmptyRef(), NStr("vi = 'Tất cả';
																				|ru = 'Все';
																				|en = 'All'; fa = 'همه';
																				|it = 'All';
																				|pl = 'All';
																				|tr = 'Tümü'"));
	SelectionList.Add(Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionAreSuspendedDueToErrors,
		NStr("vi = 'Việc thay thế và xóa liên kết đã bị tạm ngừng do lỗi';
			|ru = 'Замена ссылок и удаление приостановлена из-за ошибок';
			|en = 'Link replacement and deletion are suspended due to errors'; fa = 'جایگزینی پیوند و حذف به دلیل خطا معلق شده‌اند';
			|it = 'Link replacement and deletion are suspended due to errors';
			|pl = 'Link replacement and deletion are suspended due to errors';
			|tr = 'Bağlantıların değiştirilmesi ve silme işlemi hatalar nedeniyle duraklatıldı'"));
	SelectionList.Add(Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionIsScheduled,
		NStr("vi = 'Lập dự tính thay thế tham chiếu và xóa bỏ';
			|ru = 'Запланирована замена ссылок и удаление';
			|en = 'Link replacement and deletion is scheduled'; fa = 'جایگزینی پیوند و حذف زمان‌بندی شده است';
			|it = 'Link replacement and deletion is scheduled';
			|pl = 'Link replacement and deletion is scheduled';
			|tr = 'Bağlantıların değiştirilmesi ve silme işlemi planlandı'"));
	SelectionList.Add(Enums.MasterDataDuplicateDeletionStates.DeletionIsNotScheduled,
		NStr("vi = 'Không dự định xóa';
			|ru = 'Удаление не планируется';
			|en = 'Deletion is not scheduled'; fa = 'حذف زمان‌بندی نشده است';
			|it = 'Deletion is not scheduled';
			|pl = 'Deletion is not scheduled';
			|tr = 'Silme işlemi planlanmıyor'"));
	
	SavedValueOfType = Common.CommonSettingsStorageLoad(
		"DataProcessor.MasterDataDuplicates", "Workplace.CatalogType");
	If ValueIsFilled(SavedValueOfType) Then
		CatalogType = SavedValueOfType;
	EndIf;
	
	Items.DecorationRulesForFindingDuplicatesLink.Visible =
		AccessRight("Edit", Metadata.Catalogs.MasterDataDuplicateSearchRules);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit Then
		BeforeCloseAtServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateWorkplaceDeleteMasterDataDuplicates" Then
		If TypeOf(Parameter) = Type("CatalogRef.MetadataObjectIDs") Then
			CatalogType = Parameter;
		EndIf;
		
		AttachableTreeUpdate();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	AttachableTreeUpdate();
	AttachableUpdateOfSelectionsFromListOfMasterDataDuplicates();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CatalogTypeOnChange(Item)
	AttachableTreeUpdate(True);
	AttachableUpdateOfSelectionsFromListOfMasterDataDuplicates();
EndProcedure

&AtClient
Procedure FilterByStateOnChange(Item)
	AttachableUpdateOfSelectionsFromListOfMasterDataDuplicates();
EndProcedure

&AtClient
Procedure DecorationRulesForFindingDuplicatesLinkClick(Item)
	OpenForm("Catalog.MasterDataDuplicateSearchRules.ListForm");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTreeForConfirmation

&AtClient
Procedure TreeForConfirmationSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FieldName = Field.Name;
	
	If FieldName = "TreeForConfirmationDuplicatesGroup" Then
		ShowValueIfFilledIn(CurrentData.Duplicate1);
		
	ElsIf FieldName = "TreeForConfirmationRuleResponsible" Then
		ShowValueIfFilledIn(CurrentData.RuleResponsible);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfMasterDataDoubles

&AtServerNoContext
Procedure ListOfMasterDataDoublesOnGetDataAtServer(TagName, Settings, Rows)
	
	Duplicates = New Array;
	For Each Var_Key In Rows.GetKeys() Do
		Duplicates.Add(Var_Key.Duplicate1);
	EndDo;
	
	DeletionMarks = Common.ObjectsAttributeValue(Duplicates, "DeletionMark");
	DataProcessorModule = DataProcessors.MasterDataDuplicates;
	
	For Each StringDouble In Rows Do
		RowData = StringDouble.Value.Data;
		RowData.PictureIndex = Number(DeletionMarks[RowData.Duplicate1]) + 1;
		RowData.UsageInstancesCount = DataProcessorModule.PresentationOfPlacesOfUse(
			RowData.OccurrenceQuantity, RowData.OccurrenceSearchDate)
	EndDo;
	
EndProcedure

&AtClient
Procedure ListOfMasterDataDoublesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FieldName = Field.Name;
	
	If FieldName = "ListOfMasterDataDoublesReplacementErrors"
		And ValueIsFilled(CurrentData.ReplacementErrors) Then
		
		OpeningParameters = DoubleReplacementErrors(CurrentData.Duplicate1);
		OpenForm("DataProcessor.MasterDataDuplicates.Form.UnsuccessfulReplacements", OpeningParameters, , , , , ,
			FormWindowOpeningMode.LockOwnerWindow);
		
	ElsIf FieldName = "ListOfMasterDataDoublesDuplicate1" Then
		ShowValueIfFilledIn(CurrentData.Duplicate1);
		
	ElsIf FieldName = "ListOfMasterDataDoublesOriginal" Then
		ShowValueIfFilledIn(CurrentData.Original);
		
	ElsIf FieldName = "ListOfMasterDataDoublesEmployeeResponsible" Then
		ShowValueIfFilledIn(CurrentData.EmployeeResponsible);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CompareAndConfirm(Command)
	
	SelectedRows = Items.TreeForConfirmation.SelectedRows;
	
	If SelectedRows.Count() = 1 Then
		
		CurrentGroup = Items.TreeForConfirmation.CurrentData.GroupID;
		
	ElsIf SelectedRows.Count() > 1 Then
		
		CurrentGroup = Items.TreeForConfirmation.RowData(SelectedRows[0]).GroupID;
		For Each String In SelectedRows Do
			If Items.TreeForConfirmation.RowData(String).GroupID <> CurrentGroup Then
				Text = NStr("vi = 'Để hợp nhất, các bản trùng lặp phải nằm trong cùng một nhóm.';
							|ru = 'Для объединения дубли должны находиться в одной группе.';
							|en = 'To merge duplicates, they must be in the same group.'; fa = 'To merge duplicates, they must be in the same group.';
							|it = 'To merge duplicates, they must be in the same group.';
							|pl = 'To merge duplicates, they must be in the same group.';
							|tr = 'Birleştirme için yinelenen öğelerin aynı grupta olması gerekir.'");
				CommonClient.MessageToUser(Text);
				Return;
			EndIf;
		EndDo;
		
	Else
		
		Text = NStr("vi = 'Để hợp nhật bản trùng lặp, cần chọn ít nhất một phần tử.';
					|ru = 'Для объединения дублей необходимо выбрать хотя бы один элемент.';
					|en = 'To merge duplicates, select at least one item.'; fa = 'To merge duplicates, select at least one item.';
					|it = 'To merge duplicates, select at least one item.';
					|pl = 'To merge duplicates, select at least one item.';
					|tr = 'Yinelenen öğeleri birleştirmek için en az bir öğe seçilmelidir.'");
		CommonClient.MessageToUser(Text);
		Return;
		
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("GroupID", CurrentGroup);
	OpeningParameters.Insert("MetadataObjectID", CatalogType);
	OpenForm("DataProcessor.MasterDataDuplicates.Form.CompareAndConfirmDuplicates", OpeningParameters);
	
EndProcedure

&AtClient
Procedure RecalculatePlacesOfUse(Command)
	
	If Items.GroupPages.CurrentPage.Name = "ConfirmationPage" Then
		RecalculatePlacesOfUseOfTreeForConfirmation();
	ElsIf Items.GroupPages.CurrentPage.Name = "PageListOfDuplicates" Then
		RecalculatePlacesOfUseListOfMasterDataDuplicatesAtServer(DuplicatesOnSelectedLinesOfList());
		Items.ListOfMasterDataDoubles.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowUsageInstances(Command)
	
	References = New Array;
	For Each String In Items.ListOfMasterDataDoubles.SelectedRows Do
		RowData = Items.ListOfMasterDataDoubles.RowData(String);
		References.Add(RowData.Duplicate1);
	EndDo;
	
	DuplicateObjectsDetectionClient.ShowUsageInstances(References);
	
EndProcedure

&AtClient
Procedure ScheduleLinkReplacementAndDeletion(Command)
	
	CurrentData = Items.ListOfMasterDataDoubles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	ScheduleLinkReplacementAndDeletionAtServer(DuplicatesOnSelectedLinesOfList());
	Items.ListOfMasterDataDoubles.Refresh();
	
EndProcedure

&AtClient
Procedure NotShouldDelete(Command)
	
	CurrentData = Items.ListOfMasterDataDoubles.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	DoNotDeleteAtServer(DuplicatesOnSelectedLinesOfList());
	Items.ListOfMasterDataDoubles.Refresh();
	
EndProcedure

&AtClient
Procedure ExcludeDuplicatesFromList(Command)
	
	If Items.ListOfMasterDataDoubles.SelectedRows.Count() Then
		Buttons = New ValueList();
		Buttons.Add("ClearMark", NStr("vi = 'Bỏ đánh dấu';
										|ru = 'Снять пометку';
										|en = 'Clear mark'; fa = 'پاک کردن علامت';
										|it = 'Rimuovi il contrassegno';
										|pl = 'Usuń zaznaczenie';
										|tr = 'İşareti kaldır'"));
		Buttons.Add("DoNotTakePictures", NStr("vi = 'Không bỏ đặt dấu';
												|ru = 'Не снимать';
												|en = 'Keep checkmark'; fa = 'Keep checkmark';
												|it = 'Keep checkmark';
												|pl = 'Keep checkmark';
												|tr = 'İşareti kaldırma'"));
		
		ShowQueryBox(
			New CallbackDescription("AfterReplyAboutUncheckingTag", ThisObject),
			NStr("vi = 'Các đối tượng đã chọn sẽ được loại khỏi danh sách bản trùng lặp. Bạn có muốn bỏ đánh dấu xóa không?';
				|ru = 'Отмеченные элементы будут исключены из списка дублей. Снять пометку удаления?';
				|en = 'The selected items will be excluded from the list of duplicates. Clear the deletion mark?'; fa = 'The selected items will be excluded from the list of duplicates. Clear the deletion mark?';
				|it = 'The selected items will be excluded from the list of duplicates. Clear the deletion mark?';
				|pl = 'The selected items will be excluded from the list of duplicates. Clear the deletion mark?';
				|tr = 'İşaretlenen öğeler yinelenen öğeler listesinden çıkarılacaktır. Silme işareti kaldırılsın mı?'"),
			Buttons);
	EndIf;
	
EndProcedure

&AtClient
Procedure ScheduleOfReplacementOfDoubles(Command)
	
	ScheduledJobInfo = ScheduledJobInfo();
	
	Handler = New CallbackDescription("SetUpScheduleCompletion", ThisObject);
	
	If ScheduledJobInfo.DataSeparationEnabled Then
		Result = New Structure("Use,Schedule");
		FillPropertyValues(Result, ScheduledJobInfo);
		RunCallback(Handler, ScheduledJobInfo.Schedule);
	Else
		ScheduledJobDetails = ScheduledJobInfo.Schedule;
		Schedule = New JobSchedule;
		FillPropertyValues(Schedule, ScheduledJobDetails);
		Dialog = New ScheduledJobDialog(Schedule);
		Dialog.Show(Handler);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure AttachableTreeUpdate(OnlyUpdate = False)
	
	Items.CatalogType.Enabled = False;
	Items.WaitGroup.Visible = True;
	Items.TreeForConfirmation.Visible = False;
	
	If OnlyUpdate Then
		AttachIdleHandler("Attachable_TreeUpdate", 0.1, True);
	Else
		AttachIdleHandler("Attachable_TreeUpdateWhenOpened", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_TreeUpdateWhenOpened() Export
	
	WhenTreeUpdateIsDelayed();
	
	Items.CatalogType.Enabled = True;
	Items.WaitGroup.Visible = False;
	Items.TreeForConfirmation.Visible = True;
	
EndProcedure

&AtClient
Procedure Attachable_TreeUpdate() Export
	
	UpdateTreeForConfirmation();
	
	Items.CatalogType.Enabled = True;
	Items.WaitGroup.Visible = False;
	Items.TreeForConfirmation.Visible = True;
	
EndProcedure

&AtClient
Procedure AttachableUpdateOfSelectionsFromListOfMasterDataDuplicates()
	AttachIdleHandler("Attachable_UpdateSelectionsOfMasterDataListOfDuplicates", 0.1, True);
EndProcedure

&AtClient
Procedure Attachable_UpdateSelectionsOfMasterDataListOfDuplicates() Export
	UpdateSelectionsFromListOfMasterDataDuplicates();
EndProcedure

&AtServer
Procedure WhenTreeUpdateIsDelayed()
	
	ListType = Items.CatalogType.ChoiceList;
	ListType.Clear();
	TypesOfDubsWithQuantity = InformationRegisters.MasterDataDuplicatesToConfirm.TypesOfDubsWithQuantity();
	For Each String In TypesOfDubsWithQuantity Do
		MetadataObject = Common.MetadataObjectByID(String.RefType);
		ListType.Add(String.RefType, MetadataObject.Synonym + " (" + String.DuplicateCount + ")");
	EndDo;
	
	TypesOfDoublesWithoutQuantity = InformationRegisters.MasterDataDuplicates.DuplicatesTypes();
	For Each String In TypesOfDoublesWithoutQuantity Do
		If TypesOfDubsWithQuantity.Find(String.RefType) = Undefined Then
			MetadataObject = Common.MetadataObjectByID(String.RefType);
			ListType.Add(String.RefType, MetadataObject.Synonym);
		EndIf;
	EndDo;
	
	If ListType.Count() > 0 And Not ValueIsFilled(CatalogType) Then
		CatalogType = ListType[0].Value;
	EndIf;
	
	If ValueIsFilled(CatalogType) Then
		UpdateTreeForConfirmation();
	EndIf;
	
EndProcedure

&AtClient
Function DuplicatesOnSelectedLinesOfList()
	
	Array = New Array;
	For Each String In Items.ListOfMasterDataDoubles.SelectedRows Do
		RowData = Items.ListOfMasterDataDoubles.RowData(String);
		Array.Add(RowData.Duplicate1);
	EndDo;
	
	Return Array;
	
EndFunction

&AtServer
Procedure UpdateTreeForConfirmation()
	
	TreeForConfirmation.GetItems().Clear();
	
	DuplicateText =
		"SELECT
		|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|WHERE
		|	MasterDataDuplicatesToConfirm.RefType = &CatalogType";
		
	TextTree =
		"SELECT
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
		|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1,
		|	REFPRESENTATION(MasterDataDuplicatesToConfirm.Duplicate1) AS Duplicate1Presentation,
		|	MasterDataDuplicatesToConfirm.Source AS Source,
		|	MasterDataDuplicatesToConfirm.AddedOn AS AddedOn,
		|	MasterDataDuplicatesToConfirm.OccurrenceQuantity AS OccurrenceQuantity,
		|	MasterDataDuplicatesToConfirm.OccurrenceSearchDate AS OccurrenceSearchDate
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|WHERE
		|	MasterDataDuplicatesToConfirm.RefType = &CatalogType
		|TOTALS
		|	MAX(Source),
		|	MAX(DuplicatesGroup)
		|BY
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup";
		
	Query = New Query;
	TextSeparator_ = Common.QueryBatchSeparator();
	Query.Text = DuplicateText + TextSeparator_ + TextTree;
	Query.SetParameter("CatalogType", CatalogType);
	QueryResult = Query.ExecuteBatch();
	
	Duplicates = QueryResult[0].Unload().UnloadColumn("Duplicate1");
	SetPrivilegedMode(True);
	DeletionMarks = Common.ObjectsAttributeValue(Duplicates, "DeletionMark");
	SetPrivilegedMode(False);
	
	ItemsRoot = TreeForConfirmation.GetItems();
	SampleGroup = QueryResult[1].Select(QueryResultIteration.ByGroups);
	While SampleGroup.Next() Do
		
		GroupString = ItemsRoot.Add();
		GroupString.RuleResponsible = SampleGroup.Source;
		GroupString.GroupID = SampleGroup.DuplicatesGroup;
		
		PartsOfPresentationOfGroup = New Array;
		
		GroupItems1 = GroupString.GetItems();
		Selection = SampleGroup.Select();
		While Selection.Next() Do
			StringDouble = GroupItems1.Add();
			StringDouble.Duplicate1 = Selection.Duplicate1;
			StringDouble.AddedOn = Selection.AddedOn;
			StringDouble.PictureIndex = Number(DeletionMarks[Selection.Duplicate1]) + 1;
			StringDouble.GroupID = Selection.DuplicatesGroup;
			StringDouble.UsageInstancesCount = PresentationOfPlacesOfUse(
				Selection.OccurrenceQuantity, Selection.OccurrenceSearchDate);
			
			PartsOfPresentationOfGroup.Add(Selection.Duplicate1Presentation);
		EndDo;
		
		GroupString.DuplicatesGroup = GroupPresentation(PartsOfPresentationOfGroup);
	EndDo;
	
EndProcedure

&AtServer
Function PresentationOfPlacesOfUse(Count, Date)
	Return DataProcessors.MasterDataDuplicates.PresentationOfPlacesOfUse(Count, Date);
EndFunction

&AtServer
Function GroupPresentation(Array)
	
	Result = "";
	LengthLimitation = 100;
	
	For Each Item In Array Do
		Result = ?(IsBlankString(Result), "", Result + ", ") + Item;
		
		If StrLen(Result) > LengthLimitation Then
			Result = Left(Result, LengthLimitation) + "...";
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Procedure BeforeCloseAtServer()
	
	Common.CommonSettingsStorageSave(
		"DataProcessor.MasterDataDuplicates", "Workplace.CatalogType", CatalogType);
	
EndProcedure

&AtServer
Procedure UpdateSelectionsFromListOfMasterDataDuplicates()
	
	CommonClientServer.SetDynamicListFilterItem(
		ListOfMasterDataDoubles,
		"RefType",
		CatalogType,
		DataCompositionComparisonType.Equal,
		,
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		ListOfMasterDataDoubles,
		"DuplicateDeletionState",
		FilterByState,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterByState));
	
EndProcedure

&AtClient
Procedure RecalculatePlacesOfUseOfTreeForConfirmation()
	
	DuplicatesToUpdate = New Array;
	
	For Each LineNumber In Items.TreeForConfirmation.SelectedRows Do
		RowData = Items.TreeForConfirmation.RowData(LineNumber);
		
		If RowData.Duplicate1 = Undefined Then
			Continue;
		EndIf;
		
		DuplicatesToUpdate.Add(RowData.Duplicate1);
	EndDo;
	
	UpdateData = RecalculateUsageLocationsAtServer(CommonClientServer.CollapseArray(DuplicatesToUpdate));
	
	For Each LineNumber In Items.TreeForConfirmation.SelectedRows Do
		RowData = Items.TreeForConfirmation.RowData(LineNumber);
		RecordData = UpdateData[RowData.Duplicate1];
		
		If RecordData <> Undefined Then
			RowData.UsageInstancesCount = PresentationOfPlacesOfUse(
				RecordData.OccurrenceQuantity, RecordData.OccurrenceSearchDate);
		EndIf;
	EndDo;
	
EndProcedure

&AtServerNoContext
Function RecalculateUsageLocationsAtServer(DuplicatesToUpdate)
	Return InformationRegisters.MasterDataDuplicatesToConfirm.ReReadPlacesOfUse(DuplicatesToUpdate);
EndFunction

&AtServerNoContext
Procedure RecalculatePlacesOfUseListOfMasterDataDuplicatesAtServer(DuplicatesToUpdate)
	InformationRegisters.MasterDataDuplicates.RecalculatePlacesOfUse(DuplicatesToUpdate);
EndProcedure

&AtServer
Procedure ScheduleLinkReplacementAndDeletionAtServer(Duplicates)
	
	InformationRegisters.MasterDataDuplicates.ChangeStatusOfDeletingDuplicates(
		Duplicates,
		Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionIsScheduled);
	
EndProcedure

&AtServer
Procedure DoNotDeleteAtServer(Duplicates)
	
	InformationRegisters.MasterDataDuplicates.ChangeStatusOfDeletingDuplicates(
		Duplicates,
		Enums.MasterDataDuplicateDeletionStates.DeletionIsNotScheduled);
	
EndProcedure

&AtClient
Procedure AfterReplyAboutUncheckingTag(QuestionResult, AdditionalParameters) Export
	
	ClearMark = (QuestionResult = "ClearMark");
	
	ExcludeDuplicatesFromListAtServer(DuplicatesOnSelectedLinesOfList(), ClearMark);
	Items.ListOfMasterDataDoubles.Refresh();
	
EndProcedure

&AtServer
Procedure ExcludeDuplicatesFromListAtServer(Duplicates, ClearMark)
	
	BeginTransaction();
	Try
		InformationRegisters.MasterDataDuplicates.DeleteDuplicates(Duplicates, ClearMark);
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
EndProcedure

&AtServer
Function DoubleReplacementErrors(Duplicate1)
	Return InformationRegisters.MasterDataDuplicates.DoubleReplacementErrors(Duplicate1);
EndFunction

&AtClient
Procedure ShowValueIfFilledIn (Object)
	
	If ValueIsFilled(Object) Then
		ShowValue(, Object);
	EndIf;
	
EndProcedure

#Region JobSchedule

&AtClient
Procedure SetUpScheduleCompletion(Schedule, ExecutionParameters) Export
	
	If Schedule = Undefined Then
		Return;
	EndIf;
	
	SaveScheduleChange(New Structure("Schedule", Schedule));
	
EndProcedure

&AtServer
Function ScheduledJobInfo()
	
	Result = New Structure;
	Result.Insert("Use", False);
	Result.Insert("Schedule", CommonClientServer.ScheduleToStructure(
		New JobSchedule));
	Result.Insert("DataSeparationEnabled", Common.DataSeparationEnabled());
	
	Filter = New Structure;
	Filter.Insert("Metadata", Metadata.ScheduledJobs.ReplaceMasterDataDuplicates);
	Jobs = ScheduledJobsServer.FindJobs(Filter);
	If Jobs.Count() > 0 Then
		Job = Jobs[0];
		Result.Use = Job.Use;
		If Result.DataSeparationEnabled Then
			Result.Schedule = Job.Schedule;
		Else
			Result.Schedule = ScheduledJobsServer.JobSchedule(
				Job.UUID, True);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure SaveScheduleChange(Changes)
	
	If Not Users.IsFullUser( , , False) Then
		Raise(NStr("vi = 'Không đủ quyền để thực hiện giao dịch.';
					|ru = 'Недостаточно прав для выполнения операции.';
					|en = 'Insufficient rights to perform the operation.'; fa = 'Insufficient rights to perform the operation.';
					|it = 'Diritti insufficienti per eseguire l''operazione.';
					|pl = 'Niewystarczające uprawnienia do wykonania operacji.';
					|tr = 'İşlem için gerekli yetkiler yok.'"), ErrorCategory.AccessViolation);
	EndIf;
	
	NewSettings1 = New Structure;
	NewSettings1.Insert("Schedule", Changes.Schedule);
	JobID = ScheduledJobsServer.UUID(
		Metadata.ScheduledJobs.ReplaceMasterDataDuplicates);
	ScheduledJobsServer.ChangeJob(JobID, NewSettings1);
	
EndProcedure

#EndRegion

#EndRegion
