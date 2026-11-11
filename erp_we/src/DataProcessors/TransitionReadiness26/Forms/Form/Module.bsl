
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	SelectedModeColor = StyleColors.FormTextColor;
	UnselectedModeColor = StyleColors.HyperlinkColor;
	
	Items.HyperlinkAll.BackColor = StyleColors.SynchronizationTooltip;
	Items.HyperlinkAll.TextColor = SelectedModeColor;
	Items.StateHyperlinkIsUsed.TextColor = UnselectedModeColor;
	
	Title = NStr("vi = 'Sẵn sàng chuyển sang phiên bản 11.6';
				|ru = 'Готовность к переходу на редакцию 11.6';
				|en = 'Readiness to migrate to version 11.6'; fa = 'Readiness to migrate to version 11.6';
				|it = 'Readiness to migrate to version 11.6';
				|pl = 'Readiness to migrate to version 11.6';
				|tr = '11.6 revizyonuna geçişe hazırlık'");
	Title = NStr("vi = 'Sẵn sàng chuyển sang phiên bản 2.6';
				|ru = 'Готовность к переходу на редакцию 2.6';
				|en = 'Readiness to migrate to version 2.6'; fa = 'Readiness to migrate to version 2.6';
				|it = 'Readiness to migrate to version 2.6';
				|pl = 'Readiness to migrate to version 2.6';
				|tr = '2.6 revizyonuna geçişe hazırlık'");
	FileInfobase = Common.FileInfobase();
	
	FillInTable(FileInfobase);
	FillInTextOfInformationLine();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If FileInfobase Then
		UpdateFormAfterFillingOutTable();
	Else
		GetDataInLongOfOperation();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure HyperlinkAllClick(Item)
	
	SetFilter(True);
	
EndProcedure

&AtClient
Procedure StateHyperlinkIsUsedClick(Item)
	
	SetFilter(False);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFunctionalityTable

&AtClient
Procedure FunctionalityTableSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field.Name = "FunctionalityTableOpenRecommendation" Then
		StandardProcessing = False;
		curData = Items.FunctionalityTable.CurrentData;
		If curData.RecommendationRequiringAction Then
			OpenForm("DataProcessor.TransitionReadiness26.Form.RecommendationForm", New Structure("Text", curData.Recommendation)
				,,,,,,FormWindowOpeningMode.LockOwnerWindow);
		EndIf;
		
	EndIf;
	
	If Field.Name = "FunctionalityTableAction" Then
	
		CheckToClickThroughAction();
	
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RefreshCommand(Command)
	
	If FileInfobase Then
		FillInTable(True);
		UpdateFormAfterFillingOutTable();
	Else
		GetDataInLongOfOperation();
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GetDataInLongOfOperation()

	TimeConsumingOperation = GettingDataIsLongTermOperation();
	
	If TimeConsumingOperation = Undefined Then
		Return;
	EndIf;
	
	AdditionalParameters = New Structure;
	
	If TimeConsumingOperation.Status = "Completed2" Then
		
		GetDataInLongOfOperationCompletion(TimeConsumingOperation, AdditionalParameters);
		
	ElsIf TimeConsumingOperation.Status = "Running" Then
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		
		CallbackOnCompletion = New CallbackDescription("GetDataInLongOfOperationCompletion", ThisObject, AdditionalParameters);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
		
	EndIf;	

EndProcedure

&AtServer
Function GettingDataIsLongTermOperation()
	
	ProcedureParameters = New Structure;
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Nhận dữ liệu về chức năng cũ';
														|ru = 'Получение данных об устаревшей функциональности';
														|en = 'Get data on outdated functionality'; fa = 'Get data on outdated functionality';
														|it = 'Get data on outdated functionality';
														|pl = 'Get data on outdated functionality';
														|tr = 'Kullanım dışı işlevsellik hakkında bilgi alma'");
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground("DataProcessors.TransitionReadiness26.GettingDataFromOutdatedFunctionalityInBackground",
		ProcedureParameters, ExecutionParameters);
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure GetDataInLongOfOperationCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	If Result.Status = "Completed2" Then
		FillInData(Result.ResultAddress);
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInData(ResultAddress)

	FunctionalityTable.Clear();
	FillInTableFromRepository(ResultAddress);
	UpdateFormAfterFillingOutTable();

EndProcedure

&AtClient
Procedure UpdateFormAfterFillingOutTable()
	
	HideStateCalculationColumns();
	CheckToDisplayInscriptionAboutReadinessForTransition();
	
EndProcedure

&AtServer
Procedure CheckToDisplayInscriptionAboutReadinessForTransition()

	ActionsIsCompleted = FunctionalityTable.FindRows(New Structure("Status", StatusActionRequired())).Count() = 0;
	Items.GroupTransitionCompleted.Visible = ActionsIsCompleted;
	If ActionsIsCompleted Then
		
		MaxDate = Date(1,1,1);
		For Each SpecificationRow In FunctionalityTable Do
			If SpecificationRow.DocumentDate > MaxDate Then
				MaxDate = SpecificationRow.DocumentDate;
			EndIf;
		EndDo;
		
		If MaxDate <> Date(1, 1, 1) Then
			
			DateInFormat = Format(AddMonth(MaxDate, 2), "DF='MMMM yyyy'");
			Template = NStr("vi = 'Bạn sẵn sàng chuyển sang phiên bản 11.6. Ngày đề xuất: %1.';
							|ru = 'Вы готовы к переходу на редакцию 11.6. Рекомендуемая дата: %1.';
							|en = 'You are ready to migrate to version 11.6. Recommended date: %1.'; fa = 'You are ready to migrate to version 11.6. Recommended date: %1.';
							|it = 'You are ready to migrate to version 11.6. Recommended date: %1.';
							|pl = 'You are ready to migrate to version 11.6. Recommended date: %1.';
							|tr = '11.6 revizyonuna geçişe hazırsınız. Önerilen tarih: %1.'");
			Template = NStr("vi = 'Bạn sẵn sàng chuyển sang phiên bản 2.6. Ngày đề xuất: %1.';
							|ru = 'Вы готовы к переходу на редакцию 2.6. Рекомендуемая дата: %1.';
							|en = 'You are ready to migrate to version 2.6. Recommended date: %1.'; fa = 'You are ready to migrate to version 2.6. Recommended date: %1.';
							|it = 'You are ready to migrate to version 2.6. Recommended date: %1.';
							|pl = 'You are ready to migrate to version 2.6. Recommended date: %1.';
							|tr = '2.6 revizyonuna geçişe hazırsınız. Önerilen tarih: %1.'");
			StringText = StringFunctionsClientServer.SubstituteParametersToString(Template, DateInFormat);
			
		Else
			
			StringText = NStr("vi = 'Bạn sẵn sàng chuyển sang phiên bản 11.6.';
								|ru = 'Вы готовы к переходу на редакцию 11.6.';
								|en = 'You are ready to migrate to version 11.6.'; fa = 'You are ready to migrate to version 11.6.';
								|it = 'You are ready to migrate to version 11.6.';
								|pl = 'You are ready to migrate to version 11.6.';
								|tr = '11.6 revizyonuna geçişe hazırsınız.'");
			StringText = NStr("vi = 'Bạn sẵn sàng chuyển sang phiên bản 2.6.';
								|ru = 'Вы готовы к переходу на редакцию 2.6.';
								|en = 'You are ready to migrate to version 2.6.'; fa = 'You are ready to migrate to version 2.6.';
								|it = 'You are ready to migrate to version 2.6.';
								|pl = 'You are ready to migrate to version 2.6.';
								|tr = '2.6 revizyonuna geçişe hazırsınız.'");
		EndIf;
		
		DoneInformationLine = New FormattedString(
			StringText,,
			StyleColors.SuccessResultColor);
		
	EndIf;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FunctionalityTable.Name);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FunctionalityTable.OutdatedFunctionalityIsUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FunctionalityTable.NewFunctionalityIsUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FunctionalityTable.ThereIsDataOnOutdatedFunctionality");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FunctionalityTable.ItIsRequiredToCalculateState");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

&AtClient
Procedure HideStateCalculationColumns()

	Items.FunctionalityTableCalculatedState.Visible = False;
	Items.FunctionalityTableCalculatedState1.Visible = False;
	Items.FunctionalityTableCalculatedState2.Visible = False;

EndProcedure

&AtServer
Procedure FillInTextOfInformationLine()
	
	Template = NStr("vi = 'Chức năng này đã lỗi thời và sẽ bị loại bỏ trong phiên bản 11.6. Cần chuyển sang sử dụng chức năng mới.
			|Sau khi tắt chức năng cũ, trước khi nâng cấp lên phiên bản 11.6, nên thực hiện ít nhất 2 lần đóng tháng.
			|Trong phiên bản 11.6, sẽ không thể điều chỉnh các kỳ đã khóa sổ mà hệ thống trước đó đã vận hành bằng chức năng cũ.';
			|ru = 'Функциональность устарела и будет удалена в редакции 11.6. Необходимо выполнить переход на новую функциональность.
			|После отключения устаревшей функциональности рекомендуется до перехода на редакцию 11.6 выполнить как минимум 2 закрытия месяца.
			|Корректировка закрытых периодов, в которых система работала на старой функциональности, будет невозможна в редакции 11.6.';
			|en = 'The functionality is outdated and will be removed in version 11.6. Migrate to the new functionality.
			|After disabling the outdated functionality, it is recommended that you perform at least 2 month-end closings before migrating to version 11.6.
			|You will not be able to adjust closed periods in which the system operated on the old functionality in version 11.6.'; fa = 'The functionality is outdated and will be removed in version 11.6. Migrate to the new functionality.
			|After disabling the outdated functionality, it is recommended that you perform at least 2 month-end closings before migrating to version 11.6.
			|You will not be able to adjust closed periods in which the system operated on the old functionality in version 11.6.';
			|it = 'The functionality is outdated and will be removed in version 11.6. Migrate to the new functionality.
			|After disabling the outdated functionality, it is recommended that you perform at least 2 month-end closings before migrating to version 11.6.
			|You will not be able to adjust closed periods in which the system operated on the old functionality in version 11.6.';
			|pl = 'The functionality is outdated and will be removed in version 11.6. Migrate to the new functionality.
			|After disabling the outdated functionality, it is recommended that you perform at least 2 month-end closings before migrating to version 11.6.
			|You will not be able to adjust closed periods in which the system operated on the old functionality in version 11.6.';
			|tr = 'Bu işlevsellik artık kullanılmıyor ve 11.6 revizyonundan kaldırılacak. Yeni işlevselliğe geçiş yapılması gerekiyor.
			|Daha önceki işlevselliğin devre dışı bırakılmasından sonra, 11.6 revizyonuna geçmeden önce en az 2 ay sonu kapanışı yapılması önerilir.
			|Sistemin daha önceki işlevsellikle çalıştığı kapatılmış dönemlerin düzeltmeleri, 11.6 revizyonunda yapılamayacaktır.'");
	Template = NStr("vi = 'Chức năng này đã lỗi thời và sẽ bị loại bỏ trong phiên bản 2.6. Cần chuyển sang sử dụng chức năng mới.
			|Sau khi tắt chức năng cũ, trước khi nâng cấp lên phiên bản 2.6, nên thực hiện ít nhất 2 lần đóng tháng.
			|Trong phiên bản 2.6, sẽ không thể điều chỉnh các kỳ đã khóa sổ mà hệ thống trước đó đã vận hành bằng chức năng cũ.';
			|ru = 'Функциональность устарела и будет удалена в редакции 2.6. Необходимо выполнить переход на новую функциональность.
			|После отключения устаревшей функциональности рекомендуется до перехода на редакцию 2.6 выполнить как минимум 2 закрытия месяца.
			|Корректировка закрытых периодов, в которых система работала на старой функциональности, будет невозможна в редакции 2.6.';
			|en = 'The functionality is outdated and will be removed in version 2.6. Migrate to the new functionality.
			|After disabling the outdated functionality, it is recommended that you perform at least 2 month-end closings before migrating to version 2.6.
			|You will not be able to adjust closed periods in which the system operated on the old functionality in version 2.6.'; fa = 'The functionality is outdated and will be removed in version 2.6. Migrate to the new functionality.
			|After disabling the outdated functionality, it is recommended that you perform at least 2 month-end closings before migrating to version 2.6.
			|You will not be able to adjust closed periods in which the system operated on the old functionality in version 2.6.';
			|it = 'The functionality is outdated and will be removed in version 2.6. Migrate to the new functionality.
			|After disabling the outdated functionality, it is recommended that you perform at least 2 month-end closings before migrating to version 2.6.
			|You will not be able to adjust closed periods in which the system operated on the old functionality in version 2.6.';
			|pl = 'The functionality is outdated and will be removed in version 2.6. Migrate to the new functionality.
			|After disabling the outdated functionality, it is recommended that you perform at least 2 month-end closings before migrating to version 2.6.
			|You will not be able to adjust closed periods in which the system operated on the old functionality in version 2.6.';
			|tr = 'Bu işlevsellik artık kullanılmıyor ve 11.6 revizyonundan kaldırılacak. Yeni işlevselliğe geçiş yapılması gerekiyor.
			|Daha önceki işlevselliğin devre dışı bırakılmasından sonra, 11.6 revizyonuna geçmeden önce en az 2 ay sonu kapanışı yapılması önerilir.
			|Sistemin daha önceki işlevsellikle çalıştığı kapatılmış dönemlerin düzeltmeleri, 11.6 revizyonunda yapılamayacaktır.'");
	InformationBar = New FormattedString(Template,, StyleColors.TextColorWarning);
	Items.InfoBarPages.CurrentPage = Items.InfoBarPageDisplay;

EndProcedure

&AtServer
Procedure FillInTable(CalculateState)

	TableOfOutdatedFunctionality = DataProcessors.TransitionReadiness26.TableOfOutdatedFunctionality(CalculateState);
	FunctionalityTable.Load(TableOfOutdatedFunctionality);
	
EndProcedure

&AtServer
Procedure FillInTableFromRepository(ResultAddress)

	TableOfOutdatedFunctionality = GetFromTempStorage(ResultAddress);
	FunctionalityTable.Load(TableOfOutdatedFunctionality);
	
EndProcedure

&AtClient
Procedure CheckToClickThroughAction()
	
	ClearMessages();
	curData = Items.FunctionalityTable.CurrentData;
	
	If IsBlankString(curData.Action) Then
		Return;
	EndIf;
	
	If Not ThereIsRightOfTransition(curData.Id) Then
		
		Text = NStr("vi = 'Không đủ quyền để chuyển đổi, hãy liên hệ với người quản trị.';
					|ru = 'Недостаточно прав для перехода, обратитесь к администратору.';
					|en = 'Insufficient rights to migrate. Please contact the administrator.'; fa = 'Insufficient rights to migrate. Please contact the administrator.';
					|it = 'Insufficient rights to migrate. Please contact the administrator.';
					|pl = 'Insufficient rights to migrate. Please contact the administrator.';
					|tr = 'Yeni bir revizyona geçmek için yetersiz haklar. Yöneticinize başvurun.'");
		CommonClient.MessageToUser(Text);
		
		Return;
	
	EndIf;
	
	If curData.Id = 1 Then
	ElsIf curData.Id = 2 Then
	ElsIf curData.Id = 3 Then
	ElsIf curData.Id = 4 Then
		If OnlyProduction22IsUsed() Then
			OpenForm("DataProcessor.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog.Form.Form",, ThisObject, UUID);
		Else
			Text = NStr("vi = 'Trước khi chuyển sang ""Thao tác trong bảng kê chi tiết các nguồn lực sản xuất"", cần hoàn tất chuyển sang ""Quản lý sản xuất, phiên bản 2.2"".';
						|ru = 'Перед переходом на ""Операции в производственных спецификациях"" необходимо завершить переход на ""Управление производством, версия 2.2"".';
						|en = 'Before migrating to ""Operations in BOMs"", complete the migration to ""Production management, version 2.2"".'; fa = 'Before migrating to ""Operations in BOMs"", complete the migration to ""Production management, version 2.2"".';
						|it = 'Before migrating to ""Operations in BOMs"", complete the migration to ""Production management, version 2.2"".';
						|pl = 'Before migrating to ""Operations in BOMs"", complete the migration to ""Production management, version 2.2"".';
						|tr = '""Üretim ürün reçetelerindeki işlemler""e geçmeden önce ""Üretim yönetimi (sürüm 2.2)""ye geçişi tamamlamanız gerekiyor.'");
			CommonClient.MessageToUser(Text);
		EndIf
	ElsIf curData.Id = 5 Then
		OpenForm("DataProcessor.LogOfSalesDocuments.Form.DocumentsList",, ThisObject, UUID);
	ElsIf curData.Id = 6 Then
		OpenForm("DataProcessor.AssistantOfMigrationToPriceManagementSystemVersion25.Form.MigrationToPriceManagementSystemVersion25",, ThisObject, UUID);
	ElsIf curData.Id = 7 Then
		OpenForm("DataProcessor.TMAdministrationPanel.Form.TreasuryAndARAPAccounting",, ThisObject, UUID);
	ElsIf curData.Id = 8 Then
	ElsIf curData.Id = 9 Then
		//
	ElsIf curData.Id = 10 Then
	ElsIf curData.Id = 11 Then
		OpenForm("DataProcessor.TMAdministrationPanel.Form.TreasuryAndARAPAccounting",, ThisObject, UUID);
	ElsIf curData.Id = 12 Then
		// No action required
	ElsIf curData.Id = 13 Then
		OpenForm("DataProcessor.SSLAdministrationPanel.Form.UsersAndRightsSettings",, ThisObject, UUID);
	EndIf;

EndProcedure

&AtServerNoContext
Function ThereIsRightOfTransition(Id)
	
	If Id = 1 Then
	ElsIf Id = 2 Then
	ElsIf Id = 3 Then
	ElsIf Id = 4 Then
		Return AccessRight("Use", Metadata.DataProcessors.AssistantForTransferringTechnologicalOperationsToBillsOfMaterialsCatalog);
	ElsIf Id = 5 Then
		Return AccessRight("Use", Metadata.DataProcessors.LogOfSalesDocuments);
	ElsIf Id = 6 Then
		Return AccessRight("Use", Metadata.DataProcessors.AssistantOfMigrationToPriceManagementSystemVersion25);
	ElsIf Id = 7 Then
		Return AccessRight("Use", Metadata.DataProcessors.TMAdministrationPanel);
	ElsIf Id = 8 Then
	ElsIf Id = 9 Then
	ElsIf Id = 10 Then
	ElsIf Id = 11 Then
		Return AccessRight("Use", Metadata.DataProcessors.TMAdministrationPanel);
	ElsIf Id = 12 Then
		// No action required
		Return False;
	ElsIf Id = 13 Then
		Return AccessRight("Use", Metadata.DataProcessors.SSLAdministrationPanel);
	EndIf;
	
	Return False;

EndFunction
&AtServerNoContext
Function OnlyProduction22IsUsed()
	
	Return GetFunctionalOption("UseProductionManagement2_2")
			And Not GetFunctionalOption("UseProductionManagement");
	
EndFunction

&AtServer
Procedure SetFilter(DisplayAll)
	
	BackColor = StyleColors.SynchronizationTooltip;
	BackgroundOfForm = New Color();
	
	Items.HyperlinkAll.BackColor = ?(DisplayAll, BackColor, BackgroundOfForm);
	Items.HyperlinkAll.TextColor = ?(DisplayAll, SelectedModeColor, UnselectedModeColor);
	Items.StateHyperlinkIsUsed.BackColor = ?(DisplayAll, BackgroundOfForm, BackColor);
	Items.StateHyperlinkIsUsed.TextColor = ?(DisplayAll, UnselectedModeColor, SelectedModeColor);
	
	If DisplayAll Then
		Items.FunctionalityTable.RowFilter = Undefined;
	Else
		Items.FunctionalityTable.RowFilter = New FixedStructure("Status", StatusActionRequired());
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function StatusActionRequired()
	Return 1;
EndFunction

#EndRegion
