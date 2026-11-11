#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	IdOfDuplicates = Parameters.MetadataObjectID;
	If IdOfDuplicates.IsEmpty() Then
		RefType = Parameters.RefType;
		IdOfDuplicates = Common.MetadataObjectID(RefType);
	EndIf;
	
	GroupsIDs = InformationRegisters.MasterDataDuplicatesToConfirm.RelatedGroups(Parameters.GroupID);
	
	OnCreatReadAtServer(IdOfDuplicates, GroupsIDs);
	
	Items.CollapsePanel.Visible = False;
	Items.GroupDuplicates.Visible = False;
	Items.ExpandPanel.Visible = True;
	
	For Each TableRow In Duplicates Do
		TableRow.Check = True;
	EndDo;
	
	OptionOfComparingDoubles = "OnlyDifferences";
	
	ThereIsAccessToRules = AccessRight("Edit", Metadata.Catalogs.MasterDataDuplicateSearchRules);
	ThereIsAccessToUsers = AccessRight("View", Metadata.Catalogs.Users);
	HasFullRights = Users.IsFullUser();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	GenerateComparisonReport();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RelatedDuplicatesHaveBeenAddedToComparisonURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	TreeSourcesAndDuplicates = New Map;
	For Each DuplicatesRow In DoublesWithRepeatsInGroups Do
		If TreeSourcesAndDuplicates[DuplicatesRow.DuplicatesGroup] = Undefined Then
			TreeSourcesAndDuplicates.Insert(DuplicatesRow.DuplicatesGroup, New Array);
		EndIf;
		
		InformationAboutDouble = New Structure;
		InformationAboutDouble.Insert("Code", DuplicatesRow.Code);
		InformationAboutDouble.Insert("Duplicate1", DuplicatesRow.Duplicate1);
		InformationAboutDouble.Insert("Source", DuplicatesRow.Source);
		InformationAboutDouble.Insert("PictureIndex", DuplicatesRow.PictureIndex);
		TreeSourcesAndDuplicates[DuplicatesRow.DuplicatesGroup].Add(InformationAboutDouble);
	EndDo;
	
	OpeningParameters = New Structure("SourcesAndDuplicates", TreeSourcesAndDuplicates);
	OpenForm("DataProcessor.MasterDataDuplicates.Form.RelatedDuplicateGroups", OpeningParameters, , , , , , FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ComparisonReportDetailProcessing(Item, Details, StandardProcessing, AdditionalParameters)
	
	If TypeOf(Details) = Type("Structure") Then
		
		StandardProcessing = False;
		
		If Details.Property("DecryptionOfStatus") Then
			
			Statuses = New ValueList;
			Statuses.Add(SearchAndReplaceDuplicatesMasterDataClientServer.StatusDoubleReplace());
			Statuses.Add(SearchAndReplaceDuplicatesMasterDataClientServer.DoNotDeleteDoubleStatus());
			Statuses.Add(SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal());
			Statuses.Add(SearchAndReplaceDuplicatesMasterDataClientServer.StatusIsNotDouble());
			Statuses.Add(SearchAndReplaceDuplicatesMasterDataClientServer.StatusConfirmationRequired());
			
			NotificationOfEndOfSelection = New CallbackDescription("AfterSelectingStatusInReport", ThisObject, Details);
			ShowChooseFromMenu(NotificationOfEndOfSelection, Statuses);
			
		ElsIf Details.Property("DecodingPlacesOfUse") Then
			
			DuplicateObjectsDetectionClient.ShowUsageInstances(Details.Duplicate1);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OptionOfComparingDoublesOnChange(Item)
	OnChangingReportSettings();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDuplicates

&AtClient
Procedure DuplicatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.Duplicates.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field.Name = "DuplicatesUsageInstancesCount" Then
		StandardProcessing = False;
		DuplicateObjectsDetectionClient.ShowUsageInstances(CurrentData.Duplicate1);
	EndIf;
	
EndProcedure

&AtClient
Procedure DuplicatesOnActivateRow(Item)
	
	CurrentData = Items.Duplicates.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Source = CurrentData.Source;
	If ValueIsFilled(Source) Then
		
		If TypeOf(Source) = Type("CatalogRef.MasterDataDuplicateSearchRules") Then
			If ThereIsAccessToRules Or HasFullRights Then
				DuplicateFoundByRule = StringFunctionsClient.FormattedString(
					NStr("vi = 'Đã tìm thấy bản trùng lặp theo quy tắc <a href=""%1"">%2</a>';
						|ru = 'Дубль найден по правилу <a href=""%1"">%2</a>';
						|en = 'Duplicate is found according to the <a href=""%1"">%2</a> rule'; fa = 'Duplicate is found according to the <a href=""%1"">%2</a> rule';
						|it = 'Duplicate is found according to the <a href=""%1"">%2</a> rule';
						|pl = 'Duplicate is found according to the <a href=""%1"">%2</a> rule';
						|tr = 'Yinelenen öğe kurala göre bulundu <a href=""%1"">%2</a>'"),
					GetURL(Source),
					String(Source));
			Else
				DuplicateFoundByRule = StringFunctionsClient.FormattedString(
					NStr("vi = 'Đã tìm thấy bản trùng lặp theo quy tắc ""%1""';
						|ru = 'Дубль найден по правилу ""%1""';
						|en = 'Duplicate is found according to the ""%1"" rule'; fa = 'Duplicate is found according to the ""%1"" rule';
						|it = 'Duplicate is found according to the ""%1"" rule';
						|pl = 'Duplicate is found according to the ""%1"" rule';
						|tr = 'Yinelenen öğe ""%1"" kuralına göre bulundu'"), 
					String(Source));
			EndIf;
			
		ElsIf TypeOf(Source) = Type("CatalogRef.Users") Then
			If ThereIsAccessToUsers Or HasFullRights Then
				DuplicateFoundByRule = StringFunctionsClient.FormattedString(
					NStr("vi = 'Người sử dụng <a href=""%1"">%2</a> đã ghi nhận bản trùng lặp';
						|ru = 'Дубль зарегистрирован пользователем <a href=""%1"">%2</a>';
						|en = 'The duplicate is registered by user <a href=""%1"">%2</a>'; fa = 'The duplicate is registered by user <a href=""%1"">%2</a>';
						|it = 'The duplicate is registered by user <a href=""%1"">%2</a>';
						|pl = 'The duplicate is registered by user <a href=""%1"">%2</a>';
						|tr = 'Yinelenen öğe <a href=""%1"">%2</a>kullanıcısı tarafından kaydedildi'"), 
					GetURL(Source),
					String(Source));
			Else
				DuplicateFoundByRule = StringFunctionsClient.FormattedString(
					NStr("vi = 'Người sử dụng ""%1"" đã ghi nhận bản trùng lặp';
						|ru = 'Дубль зарегистрирован пользователем ""%1""';
						|en = 'The duplicate is registered by user ""%1""'; fa = 'The duplicate is registered by user ""%1""';
						|it = 'The duplicate is registered by user ""%1""';
						|pl = 'The duplicate is registered by user ""%1""';
						|tr = 'Yinelenen öğe ""%1"" kullanıcısı tarafından kaydedildi'"), 
					String(Source));
			EndIf;
			
		Else
			If HasFullRights Then
				DuplicateFoundByRule = StringFunctionsClient.FormattedString(
					NStr("vi = 'Đã ghi nhận bản trùng lặp <a href=""%1"">%2</a>';
						|ru = 'Дубль зарегистрирован <a href=""%1"">%2</a>';
						|en = 'The duplicate is registered <a href=""%1"">%2</a>'; fa = 'The duplicate is registered <a href=""%1"">%2</a>';
						|it = 'The duplicate is registered <a href=""%1"">%2</a>';
						|pl = 'The duplicate is registered <a href=""%1"">%2</a>';
						|tr = 'Yinelenen öğe kaydedildi <a href=""%1"">%2</a>'"),
					GetURL(Source),
					String(Source));
			Else
				DuplicateFoundByRule = StringFunctionsClient.FormattedString(
					NStr("vi = 'Đã ghi nhận bản trùng lặp ""%1""';
						|ru = 'Дубль зарегистрирован ""%1""';
						|en = 'The duplicate is registered ""%1""'; fa = 'The duplicate is registered ""%1""';
						|it = 'The duplicate is registered ""%1""';
						|pl = 'The duplicate is registered ""%1""';
						|tr = 'Yinelenen öğe kaydedildi ""%1""'"),
					String(Source));
			EndIf;
			
		EndIf;
		
	Else
		DuplicateFoundByRule = StringFunctionsClient.FormattedString(NStr("vi = 'Đã xác nhận bản trùng lặp';
																			|ru = 'Дубль подтвержден';
																			|en = 'The duplicate is confirmed'; fa = 'The duplicate is confirmed';
																			|it = 'The duplicate is confirmed';
																			|pl = 'The duplicate is confirmed';
																			|tr = 'Yinelenen öğe onaylandı'"));
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetAll(Command)
	SetTagValue(True);
EndProcedure

&AtClient
Procedure ClearAllIetmsCommand(Command)
	SetTagValue(False);
EndProcedure

&AtClient
Procedure ExpandPanel(Command)
	
	Items.ExpandPanel.Visible = False;
	Items.GroupDuplicates.Visible = True;
	Items.CollapsePanel.Visible = True;
	
EndProcedure

&AtClient
Procedure CollapsePanel(Command)
	
	Items.CollapsePanel.Visible = False;
	Items.GroupDuplicates.Visible = False;
	Items.ExpandPanel.Visible = True;
	
EndProcedure

&AtClient
Procedure SetStatusDoubleReplace(Command)
	SetStatusForSelected(SearchAndReplaceDuplicatesMasterDataClientServer.StatusDoubleReplace());
EndProcedure

&AtClient
Procedure SetStatusDoNotDeleteDuplicate(Command)
	SetStatusForSelected(SearchAndReplaceDuplicatesMasterDataClientServer.DoNotDeleteDoubleStatus());
EndProcedure

&AtClient
Procedure SetStatusOfOriginal(Command)
	SetStatusForSelected(SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal());
EndProcedure

&AtClient
Procedure SetStatusIsNotDouble(Command)
	SetStatusForSelected(SearchAndReplaceDuplicatesMasterDataClientServer.StatusIsNotDouble());
EndProcedure

&AtClient
Procedure SetStatusConfirmationRequired(Command)
	SetStatusForSelected(SearchAndReplaceDuplicatesMasterDataClientServer.StatusConfirmationRequired());
EndProcedure

&AtClient
Procedure ShowRef(Command)
	
	CurrentData = Items.Duplicates.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ShowValue(, CurrentData.Duplicate1);
	
EndProcedure

&AtClient
Procedure ConfirmDuplicates(Command)
	
	ConfirmationResultInfo = ResultOfConfirmingDuplicates();
	
	If ValueIsFilled(ConfirmationResultInfo.TextOfNonconformityWarning) Then
		
		ShowMessageBox(, ConfirmationResultInfo.TextOfNonconformityWarning);
		Return;
		
	ElsIf ValueIsFilled(ConfirmationResultInfo.TextOfWarningAboutRepeatedSearch) Then
		
		CallbackDescription = New CallbackDescription("AfterConfirmingReplacementOfDuplicates", ThisObject);
		Buttons = New ValueList;
		Buttons.Add("Continue", NStr("vi = 'Tiếp tục';
									|ru = 'Продолжить';
									|en = 'Continue'; fa = 'ادامه';
									|it = 'Continuare';
									|pl = 'Kontynuuj';
									|tr = 'Devam'"));
		Buttons.Add("Cancel", NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Anuluj';
									|tr = 'İptal'"));
		
		ShowQueryBox(CallbackDescription, ConfirmationResultInfo.TextOfWarningAboutRepeatedSearch, Buttons);
		Return;
		
	EndIf;
	
	Errors = ConfirmationResultInfo.StatusSelectionErrors;
	If TypeOf(Errors) = Type("Array") And Errors.Count() > 0 Then
		Items.ExpandPanel.Visible = False;
		Items.GroupDuplicates.Visible = True;
		Items.CollapsePanel.Visible = True;
		
		ClearMessages();
		For Each Error In Errors Do
			CommonClient.MessageToUser(Error.ErrorText, , Error.Field);
		EndDo;
	Else
		CompleteConfirmationOfDuplicates();
	EndIf;
	
EndProcedure

&AtClient
Procedure Generate(Command)
	GenerateComparisonReport();
EndProcedure

&AtClient
Procedure Cancel(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure OnCreatReadAtServer(IdOfDuplicates, GroupsIDs)
	
	Duplicates.Clear();
	DoublesWithRepeatsInGroups.Clear();
	
	DuplicatesFillingIn = DataProcessors.MasterDataDuplicates.DataFromFillingOutDuplicateComparisonForm(
		GroupsIDs, IdOfDuplicates);
	
	DuplicatesCollection = New Array;
	IndexesOfOriginals = New Array;
	For Each StringFilling In DuplicatesFillingIn Do
		DuplicatesCollection.Add(StringFilling.Duplicate1);
		FillPropertyValues(DoublesWithRepeatsInGroups.Add(), StringFilling);
		
		If Duplicates.FindRows(New Structure("Duplicate1", StringFilling.Duplicate1)).Count() = 0 Then
			FillPropertyValues(Duplicates.Add(), StringFilling);
		EndIf;
		
		If StringFilling.Status = SearchAndReplaceDuplicatesMasterDataClientServer.StatusOriginal() Then
			IndexesOfOriginals.Add(DuplicatesFillingIn.IndexOf(StringFilling));
		EndIf;
	EndDo;
	
	Sources = DuplicatesFillingIn.Copy(, "Source");
	Sources.GroupBy("Source");
	MultipleSources = (Sources.Count() > 1);
	Items.RelatedDuplicatesHaveBeenAddedToComparison.Visible = MultipleSources;
	
	If IndexesOfOriginals.Count() > 1 Then
		Items.ConfirmDuplicates.Enabled = False;
		
		MessageText = NStr("vi = 'Trong nhóm tồn tại một số bản gốc đã được xác nhận. Cần chờ kết thúc thủ tục thay thế bản trùng lặp';
							|ru = 'В группе существует несколько подтвержденных оригиналов. Необходимо дождаться окончания процедуры замены дублей';
							|en = 'There are several confirmed originals in the group. Wait for the duplicate replacement to complete.'; fa = 'There are several confirmed originals in the group. Wait for the duplicate replacement to complete.';
							|it = 'There are several confirmed originals in the group. Wait for the duplicate replacement to complete.';
							|pl = 'There are several confirmed originals in the group. Wait for the duplicate replacement to complete.';
							|tr = 'Grupta birden fazla onaylanmış orijinal kayıt var. Yinelenen öğeleri değiştirme prosedürünün tamamlanmasını beklemek gerekiyor'");
		Common.MessageToUser(MessageText);
	EndIf;
	
	DeletionMarks = Common.ObjectsAttributeValue(DuplicatesCollection, "DeletionMark");
	For Each StringDouble In Duplicates Do
		StringDouble.PictureIndex = Number(DeletionMarks[StringDouble.Duplicate1]) + 1;
	EndDo;
	For Each StringDouble In DoublesWithRepeatsInGroups Do
		StringDouble.PictureIndex = Number(DeletionMarks[StringDouble.Duplicate1]) + 1;
	EndDo;
	
EndProcedure

&AtClient
Procedure SetStatusForSelected(Status)
	
	For Each RowIndex In Items.Duplicates.SelectedRows Do
		Duplicates[RowIndex].Status = Status;
	EndDo;
	
	OnChangingReportSettings();
	
EndProcedure

&AtClient
Procedure SetTagValue(Value)
	
	SelectedRows = Items.Duplicates.SelectedRows;
	If SelectedRows.Count() = 1 Then
		For Each TableRow In Duplicates Do
			TableRow.Check = Value;
		EndDo;
	Else
		For Each RowIndex In SelectedRows Do
			Duplicates[RowIndex].Check = Value;
		EndDo;
	EndIf;
	
	OnChangingReportSettings();
	
EndProcedure

&AtClient
Procedure AfterSelectingStatusInReport(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		ReportArea = ComparisonReport.Area(AdditionalParameters.RowNum, AdditionalParameters.ColumnNumber);
		ReportArea.Value = Result.Value;
		
		Duplicate1 = Duplicates.FindRows(New Structure("Duplicate1", AdditionalParameters.Duplicate1))[0];
		Duplicate1.Status = Result.Value;
	EndIf;
	
EndProcedure

&AtServer
Function ResultOfConfirmingDuplicates()
	
	Result = DataProcessors.MasterDataDuplicates.ConfirmDuplicates(Duplicates, IdOfDuplicates);
	
	ErrorsTable = Result.StatusSelectionErrors;
	If TypeOf(ErrorsTable) = Type("ValueTable") Then
		Errors = New Array;
		For Each ErrorString In ErrorsTable Do
			ErrorStructure = New Structure("ErrorText,Field", ErrorString.ErrorText, ErrorString.Field);
			Errors.Add(ErrorStructure);
		EndDo;
		Result.StatusSelectionErrors = Errors;
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure AfterConfirmingReplacementOfDuplicates(ReturnCode, AdditionalParameters) Export
	
	If ReturnCode = "Continue" Then
		ProcessConfirmationOfDuplicatesATServer();
		CompleteConfirmationOfDuplicates();
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessConfirmationOfDuplicatesATServer()
	DataProcessors.MasterDataDuplicates.ConfirmDuplicates(Duplicates, IdOfDuplicates, False)
EndProcedure

&AtClient
Procedure CompleteConfirmationOfDuplicates()
	
	Notify("UpdateWorkplaceDeleteMasterDataDuplicates", IdOfDuplicates);
	Close();
	
EndProcedure

&AtClient
Procedure GenerateComparisonReport()
	
	TimeConsumingOperation = PrepareLengthyReportOfOperation();
	
	If TimeConsumingOperation <> Undefined Then
		Notification = New CallbackDescription("AfterReportIsGenerated", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, Notification);
	Else
		CommonClient.MessageToUser(
			NStr("vi = 'Để lập báo cáo về so sánh, cần chọn không ít hơn hai bản trùng lặp';
				|ru = 'Для построения отчета о сравнении необходимо выбрать не меньше двух дублей';
				|en = 'To generate a comparison report, select at least two duplicates'; fa = 'برای ایجاد گزارش مقایسه، حداقل دو مورد تکراری انتخاب کنید';
				|it = 'To generate a comparison report, select at least two duplicates';
				|pl = 'To generate a comparison report, select at least two duplicates';
				|tr = 'Karşılaştırma raporu oluşturmak için en az iki yinelenen öğe seçilmelidir'"),
				,
				"Duplicates[0].Check");
	EndIf;
	
EndProcedure

&AtServer
Function PrepareLengthyReportOfOperation()
	
	MarkedDoubles = Duplicates.FindRows(New Structure("Check", True));
	
	If MarkedDoubles.Count() > 1 Then
		BeforeGeneratingReportATServer();
		TimeConsumingOperation = StartGeneratingReportAtServer();
	Else
		TimeConsumingOperation = Undefined;
	EndIf;
	
	Return TimeConsumingOperation;
	
EndFunction

&AtServer
Function StartGeneratingReportAtServer()
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Lập báo cáo về so sánh bản trùng lặp của danh mục';
														|ru = 'Формирование отчета о сравнении дублей НСИ';
														|en = 'Generate a report on comparing master data duplicates'; fa = 'Generate a report on comparing master data duplicates';
														|it = 'Generate a report on comparing master data duplicates';
														|pl = 'Generate a report on comparing master data duplicates';
														|tr = 'Master veri yinelenen öğeleri karşılaştırma raporunun oluşturulması'");
	
	Return TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters,
		"DataProcessors.MasterDataDuplicates.ComparisonReport",
		IdOfDuplicates,
		Duplicates.Unload(),
		OptionOfComparingDoubles);
		
EndFunction

&AtClient
Procedure AfterReportIsGenerated(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	ComparisonReport = GetFromTempStorage(Result.ResultAddress);
	ReportCreated = True;
	SearchAndReplaceDuplicatesMasterDataClientServer.SetStateOfReportField(Items.ComparisonReport, False);
	
EndProcedure

&AtServer
Procedure BeforeGeneratingReportATServer()
	SearchAndReplaceDuplicatesMasterDataClientServer.SetStateOfReportField(Items.ComparisonReport, False);
EndProcedure

&AtClient
Procedure OnChangingReportSettings()
	
	If ReportCreated Then
		SearchAndReplaceDuplicatesMasterDataClientServer.SetStateOfReportField(Items.ComparisonReport, True);
	EndIf;
	
EndProcedure

#EndRegion
