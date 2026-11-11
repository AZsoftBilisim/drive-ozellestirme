#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("RegistrationPeriod", RegistrationPeriod);
	Parameters.Property("Organization", Organization);
	If Organization.IsEmpty() Then
		CompanyArray = New Array();
		Parameters.Property("CompanyArray", CompanyArray);
		If CompanyArray.Count() <> 0 Then
			Organization = CompanyArray[0];
		EndIf;
	EndIf;
	
	RegistrationPeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(RegistrationPeriod);
	
	UpdateYourAccountPolicySettings();
	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateResearchList();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RegistrationPeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	CloseHandler	= New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters		= New Structure("Value, PeriodSelectionMode", RegistrationPeriod, "MONTH");
	
	OpenForm("CommonForm.PeriodSelection",
		FormParameters, 
		ThisObject, 
		UUID,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationTuning(Item, Direction, StandardProcessing)
	
	TMCommonUseClient.RegulationOfPresentationOfRegistrationPeriod(
		Direction,
		StandardProcessing,
		RegistrationPeriod,
		RegistrationPeriodPresentation);
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FINAccountPolicySettingsClick(Item)
		
	OpenForm("InformationRegister.FinancialAccountingPolicy.RecordForm",
		New Structure("Organization", Organization),
		ThisObject,,,,
		New CallbackDescription("AccountPolicySettingsClickFinish", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure AccountPolicySettingsBuhClick(Item)
	
		
	Return;
	
EndProcedure

&AtClient
Procedure CompaniesOnChange(Item)

	UpdateYourAccountPolicySettings();
	UpdateListOfStudiesAttributedToExpensesOnServer();
	UpdateYourAccountPolicySettings();
	
EndProcedure

#EndRegion

#Region EventHandlersFormTablesListOfStudiesToAllocateExpenses

&AtClient
Procedure ListOfResearchForExpenseAllocationSelection(Item, RowSelected, Field, StandardProcessing)

	If Field = Items.ListOfResearchForExpenseAllocationTopicResearchStage Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.TopicResearchStage, StandardProcessing);
	ElsIf Field = Items.ListOfResearchForExpenseAllocationRecognitionDocument Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.RecognitionDocument, StandardProcessing);
	ElsIf Field = Items.ListOfResearchForExpenseAllocationDepartment Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.Department, StandardProcessing);
	ElsIf Field = Items.ListOfResearchForExpenseAllocationExpenseItemAccounting Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.ExpenseItemAccounting, StandardProcessing);
	ElsIf Field = Items.ListOfResearchForExpenseAllocationExpensesDimensionAccounting Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.ExpensesDimensionAccounting, StandardProcessing);
	ElsIf Field = Items.ListOfResearchForExpenseAllocationLineOfBusiness Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.LineOfBusiness, StandardProcessing);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RefreshListOfResearchForExpenseAllocation(Command)
	
	UpdateResearchList();
	
EndProcedure

&AtClient
Procedure CreateRecognitionDocument(Command)
	
	ClearMessages();

	TheListForRegistration = Items.ListOfResearchForExpenseAllocation;
	CurLineToDesign = TheListForRegistration.CurrentData;

	If CurLineToDesign = Undefined Then
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
							|ru = 'Команда не может быть выполнена для указанного объекта.';
							|en = 'Cannot execute the command for the object.'; fa = 'Cannot execute the command for the object.';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
							|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
							|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;

	StudiesTowardsRecognition = New Array();

	For Each CurLineToDesign In TheListForRegistration.SelectedRows Do

		CurRowData = TheListForRegistration.RowData(CurLineToDesign);

		If CurRowData.RecognitionDocument.IsEmpty() Then
			StudiesTowardsRecognition.Add(CurRowData.TopicResearchStage);
		Else
			MessageText = NStr("vi = 'Đối với %1 đã nhập chứng từ kết thúc. Phần tử không thể nằm trong thành phần chứng từ mới';
								|ru = 'Для %1 уже введен документ завершения. Элемент не может быть включен в состав нового документа';
								|en = 'The completion document has already been entered for %1. The item cannot be included in the new document'; fa = 'The completion document has already been entered for %1. The item cannot be included in the new document';
								|it = 'Per %1 è già stato inserito un documento di completamento. L''elemento non può essere incluso nel nuovo documento';
								|pl = 'Dla %1 już został wprowadzony dokument zakończenia. Element nie może być dołączony do zawartości nowego dokumentu';
								|tr = '%1 için zaten bir tamamlama belgesi girilmiş. Eleman yeni bir belgeye dahil edilemez'");
			CommonClient.MessageToUser(
				StrTemplate(MessageText, CurRowData.TopicResearchStage),,
				"ListOfResearchForExpenseAllocation[" + ListOfResearchForExpenseAllocation.IndexOf(CurLineToDesign) + "].TopicResearchStage");
		EndIf;

	EndDo;

	If StudiesTowardsRecognition.Count() > 0 Then
		FillingValues = New Structure;
		FillingValues.Insert("TopicsStages", StudiesTowardsRecognition);
		FillingValues.Insert("Organization", Organization);
		FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.RecognitionOfResearchExpenses"));

		OpenForm("Document.RDExpenseRecognition.Form.DocumentForm", New Structure("FillingValues", FillingValues), , True, , , New CallbackDescription("GenerateRecognitionDocumentCompletion", ThisObject));
	Else
		WarningText = NStr("vi = 'Không thể thực hiện lệnh, bởi vì không có chủ đề hợp lệ để xác nhận.';
							|ru = 'Команда не может быть выполнена, так как нет доступных тем к признанию.';
							|en = 'Cannot execute command because there are no topics available for recognition.'; fa = 'Cannot execute command because there are no topics available for recognition.';
							|it = 'Il comando non può essere eseguito perché non ci sono oggetti da riconoscere.';
							|pl = 'Polecenie nie może być wykonane, ponieważ jest brak dostępnych tematów do uznania.';
							|tr = 'Komut yürütülemiyor çünkü tanınacak konu yok.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private


#Region TimeConsumingOperations

&AtClient
Procedure UpdateResearchList()

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("EventName", "UpdateResearchList");
		
	TimeConsumingOperation = UpdateListOfStudiesAttributedToExpensesOnServer();
	
	DisplayingStateOfLongRunningOperation(ThisForm, True);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackDescription = New CallbackDescription("AfterUpdatingResearchList", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);

EndProcedure

&AtServer
Function UpdateListOfStudiesAttributedToExpensesOnServer()

	ListOfResearchForExpenseAllocation.Clear();

	If ValueIsFilled(Organization) Then

		FillParameters = Documents.RDExpenseRecognition.FillParameters();
		FillParameters.BeginOfPeriod = RegistrationPeriod;
		FillParameters.EndOfPeriod = EndOfMonth(RegistrationPeriod);
		FillParameters.Organization = Organization;
		FillParameters.BusinessOperation = Enums.BusinessTransactions.RecognitionOfResearchExpenses;
		FillParameters.RecognizeAC = RecognizeAC;
		FillParameters.RecognizeMA = RecognizeMA;
	
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Cập nhật danh sách chủ đề và các giai đoạn cần hoàn thành';
															|ru = 'Обновление списка тем и этапов к завершению';
															|en = 'Updating list of topics and stages for completion'; fa = 'Updating list of topics and stages for completion';
															|it = 'Aggiornamento dell''elenco di oggetti e fasi da completare';
															|pl = 'Aktualizacja listy tematów i etapów do zakończenia';
															|tr = 'Tamamlanacak konu ve aşamaların listesini güncelleştirme'");
		
		ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
			"Documents.RDExpenseRecognition.TopicsRelatedToExpenses",
			FillParameters, ExecutionParameters);
		
		Return ExecutionResult;
		
	EndIf;

EndFunction

&AtClient
Procedure AfterUpdatingResearchList(Result, AdditionalParameters) Export
	
	If Result.Status = "Error" Then
		DisplayingStateOfLongRunningOperation(ThisForm, False);
		MessageText = NStr("vi = 'Đã xảy ra lỗi cập nhật danh sách:';
							|ru = 'Произошла ошибка обновления списка:';
							|en = 'Error when updating list:'; fa = 'Error when updating list:';
							|it = 'Si è verificato un errore di aggiornamento di elenco:';
							|pl = 'Zaistniał błąd aktualizacji listy:';
							|tr = 'Listeyi güncellerken bir hata oluştu:'") + Chars.LF + Result.BriefErrorDescription;
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	LoadPreparedData(Result.ResultAddress, AdditionalParameters);
	DisplayingStateOfLongRunningOperation(ThisForm, False);
	
EndProcedure

&AtServer
Procedure LoadPreparedData(ResultAddress, AdditionalParameters)
	
	Data = GetFromTempStorage(ResultAddress);
	
	For Each String In Data Do
		TableRow = ListOfResearchForExpenseAllocation.Add();
		FillPropertyValues(TableRow, String);
	EndDo;	
	
EndProcedure

&AtClientAtServerNoContext
Procedure DisplayingStateOfLongRunningOperation(Form, PerformingTransaction)
	
	Items = Form.Items;

	Items.GroupFilters.Enabled = Not PerformingTransaction;
	Items.GroupPerformingCalculationInTheBackground.Visible = PerformingTransaction;
	
EndProcedure

#EndRegion

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		
		RegistrationPeriod = SelectedPeriod;
		RegistrationPeriodPresentation =
			TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(RegistrationPeriod);
		
	EndIf;
	
	UpdateListOfStudiesAttributedToExpensesOnServer();
	UpdateYourAccountPolicySettings();
	
EndProcedure

&AtClient
Procedure OpenObject(Ref, StandardProcessing)

	If ValueIsFilled(Ref) Then
		ShowValue(Undefined, Ref);
	EndIf;

EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	//Conditional design of the fields "by accounting policy settings"
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpensesDimensionManagementAccounting.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpensesDimensionAccounting.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpenseItemAccounting.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpenseItemManagementAccounting.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfResearchForExpenseAllocation.DistributionDisplayParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "AccordingToParametersOfUP";

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<theo tùy chỉnh chính sách kế toán>';
																		|ru = '<по настройкам учетной политики>';
																		|en = '<by accounting policy settings>'; fa = '<by accounting policy settings>';
																		|it = '<per impostazioni di politica contabile>';
																		|pl = '<wg ustawień polityki ewidencyjnej>';
																		|tr = '<muhasebe politikasının ayarlarına göre>'"));
	
	//Conditional design of fields "by the current value"
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationDepartment.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationLineOfBusiness.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfResearchForExpenseAllocation.DistributionDisplayParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "AccordingToParametersOfUP";

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<theo giá trị hiện tại>';
																		|ru = '<по текущему значению>';
																		|en = '<by current value>'; fa = '<by current value>';
																		|it = '<per valore corrente>';
																		|pl = '<wg bieżącej wartości>';
																		|tr = '<geçerli değerde>'"));
	
	//Conditional design of fields "by distribution"
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpensesDimensionAccounting.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpenseItemAccounting.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationDepartment.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationLineOfBusiness.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpensesDimensionManagementAccounting.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpenseItemManagementAccounting.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfResearchForExpenseAllocation.DistributionDisplayParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "ByDocument";

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<theo phân bổ>';
																		|ru = '<по распределению>';
																		|en = '<by distribution>'; fa = '<by distribution>';
																		|it = '<per distribuzione>';
																		|pl = '<wg podziału>';
																		|tr = '<dağıtıma göre>'"));
	
	//Conditional registration of the division "according to the current value"
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationDepartment.Name);
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(ConditionalAppearanceItem.Filter.Items,
		"ByLineDivision",
		DataCompositionFilterItemsGroupType.AndGroup);
	ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
		"ListOfResearchForExpenseAllocation.DistributionDisplayParameter",
		DataCompositionComparisonType.Equal,
		"ByDocumentLine");
	ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
		"ListOfResearchForExpenseAllocation.Department",
		DataCompositionComparisonType.Equal,
		Catalogs.BusinessStructure.EmptyRef());
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<theo giá trị hiện tại>';
																		|ru = '<по текущему значению>';
																		|en = '<by current value>'; fa = '<by current value>';
																		|it = '<per valore corrente>';
																		|pl = '<wg bieżącej wartości>';
																		|tr = '<geçerli değerde>'"));
	
	//Conditional registration of the direction of activity "according to the current value"
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationLineOfBusiness.Name);
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(ConditionalAppearanceItem.Filter.Items,
		"ByLineDirectionOfActivity",
		DataCompositionFilterItemsGroupType.AndGroup);
	ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
		"ListOfResearchForExpenseAllocation.DistributionDisplayParameter",
		DataCompositionComparisonType.Equal,
		"ByDocumentLine");
	ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
		"ListOfResearchForExpenseAllocation.LineOfBusiness",
		DataCompositionComparisonType.Equal,
		Catalogs.LinesOfBusiness.EmptyRef());
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<theo giá trị hiện tại>';
																		|ru = '<по текущему значению>';
																		|en = '<by current value>'; fa = '<by current value>';
																		|it = '<per valore corrente>';
																		|pl = '<wg bieżącej wartości>';
																		|tr = '<geçerli değerde>'"));
	
	//Conditional registration of BU fields "recognition is not performed"
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpenseItemAccounting.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpensesDimensionAccounting.Name);
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(ConditionalAppearanceItem.Filter.Items,
		"ByDocumentLineAC",
		DataCompositionFilterItemsGroupType.AndGroup);
	ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
		"ListOfResearchForExpenseAllocation.DistributionDisplayParameter",
		DataCompositionComparisonType.Equal,
		"ByDocumentLine");
	ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
		"ListOfResearchForExpenseAllocation.ExpenseRecognitionTypeAC",
		DataCompositionComparisonType.Equal,
		Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa thực hiện ghi nhận>';
																		|ru = '<не выполняется признание>';
																		|en = '<not recognized>'; fa = '<not recognized>';
																		|it = '<riconoscimento non viene eseguito>';
																		|pl = '<uznanie nie jest wykonywane>';
																		|tr = '<denklik yerine getirilmedi>'"));
	
	//Conditional registration of the fields of the UU "recognition is not performed"
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpenseItemManagementAccounting.Name);
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpensesDimensionManagementAccounting.Name);
	
	FilterGroup = CommonClientServer.CreateFilterItemGroup(ConditionalAppearanceItem.Filter.Items,
		"ByDocumentLineMa",
		DataCompositionFilterItemsGroupType.AndGroup);
	ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
		"ListOfResearchForExpenseAllocation.DistributionDisplayParameter",
		DataCompositionComparisonType.Equal,
		"ByDocumentLine");
	ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
		"ListOfResearchForExpenseAllocation.ExpenseRecognitionTypeMA",
		DataCompositionComparisonType.Equal,
		Enums.RDExpenseRecognitionTypes.DoNotRecognizeExpenses);
	
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<chưa thực hiện ghi nhận>';
																		|ru = '<не выполняется признание>';
																		|en = '<not recognized>'; fa = '<not recognized>';
																		|it = '<riconoscimento non viene eseguito>';
																		|pl = '<uznanie nie jest wykonywane>';
																		|tr = '<denklik yerine getirilmedi>'"));
	
	//Conditional registration of the UU fields "coincides with accounting"
	If RecognizeAC = True Then
		
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpenseItemManagementAccounting.Name);
		ItemField = ConditionalAppearanceItem.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ListOfResearchForExpenseAllocationExpensesDimensionManagementAccounting.Name);
		
		FilterGroup = CommonClientServer.CreateFilterItemGroup(ConditionalAppearanceItem.Filter.Items,
			"ByDocumentLineMa",
			DataCompositionFilterItemsGroupType.AndGroup);
		ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
			"ListOfResearchForExpenseAllocation.DistributionDisplayParameter",
			DataCompositionComparisonType.Equal,
			"ByDocumentLine");
		ItemFilter = CommonClientServer.AddCompositionItem(FilterGroup,
			"ListOfResearchForExpenseAllocation.ExpenseRecognitionTypeMA",
			DataCompositionComparisonType.NotFilled);
		
		ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
		ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<trùng với kế toán doanh nghiệp>';
																			|ru = '<совпадает с бухгалтерским учетом>';
																			|en = '<matches local accounting data>'; fa = '<matches local accounting data>';
																			|it = '<coincide con la contabilità generale>';
																			|pl = '<jest zgodne z ewidencją księgową>';
																			|tr = '<muhasebe ile örtüşüyor>'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateRecognitionDocumentCompletion(Result, AdditionalParameters) Export
	
	UpdateListOfStudiesAttributedToExpensesOnServer();
	
EndProcedure

&AtClient
Procedure AccountPolicySettingsClickFinish(Result, AdditionalParameters) Export

	UpdateYourAccountPolicySettings();

EndProcedure

&AtServer
Procedure UpdateYourAccountPolicySettings()

	Companies = New Array();
	Companies.Add(Organization);
	
	ResearchRecognitionSettings = RDExpensesAccounting.SettingsForRecognizingCompanyResearchExpenses(
		RegistrationPeriod,
		Companies);

	AccountPolicySettingsBuh = ResearchRecognitionSettings.Find("Accounting","AccountingPolicy");
	If AccountPolicySettingsBuh <> Undefined Then
		Items.AccountPolicySettingsBuh.Title = String(AccountPolicySettingsBuh.ExpenseItem)
			+ ?(ValueIsFilled(AccountPolicySettingsBuh.DimensionOfExpenses),", "+ AccountPolicySettingsBuh.DimensionOfExpenses,"");
		If Items.AccountPolicySettingsBuh.Title = "" Then
			Items.AccountPolicySettingsBuh.Title = NStr("vi = '<Chưa đặt tùy chỉnh>';
														|ru = '<Не заданы настройки>';
														|en = '<Settings are not specified>'; fa = '<Settings are not specified>';
														|it = '<Impostazioni non indicate>';
														|pl = '<ustawienia nie są określone>';
														|tr = '<Ayarlar ayarlanmadı>'");
		EndIf;
		Items.AccountingPolicySettingsGroupAC.Visible = True;
		Items.ListOfStudiesRelatedToExpensesBUGroup.Visible = True;
		RecognizeAC = True;
	Else
		Items.AccountingPolicySettingsGroupAC.Visible = False;
		Items.ListOfStudiesRelatedToExpensesBUGroup.Visible = False;
		RecognizeAC = False;
	EndIf;
	
	FINAccountPolicySettings = ResearchRecognitionSettings.Find("FinAccounting","AccountingPolicy");
	If FINAccountPolicySettings <> Undefined Then
		Items.FINAccountPolicySettings.Title = String(FINAccountPolicySettings.ExpenseItem)
			+ ?(ValueIsFilled(FINAccountPolicySettings.DimensionOfExpenses),", "+ FINAccountPolicySettings.DimensionOfExpenses,"");
		If Items.AccountPolicySettingsBuh.Title = "" Then
			Items.AccountPolicySettingsBuh.Title = NStr("vi = '<Chưa đặt tùy chỉnh>';
														|ru = '<Не заданы настройки>';
														|en = '<Settings are not specified>'; fa = '<Settings are not specified>';
														|it = '<Impostazioni non indicate>';
														|pl = '<ustawienia nie są określone>';
														|tr = '<Ayarlar ayarlanmadı>'");
		EndIf;
		Items.AccountingPolicySettingsGroupFA.Visible = True;
		Items.ListOfStudiesRelatedToTheAllocationOfExpensesUUGroup.Visible = True;
		RecognizeMA = True;
	Else
		Items.AccountingPolicySettingsGroupFA.Visible = False;
		Items.ListOfStudiesRelatedToTheAllocationOfExpensesUUGroup.Visible = False;
		RecognizeMA = False;
	EndIf;
	
	UpdateListOfStudiesAttributedToExpensesOnServer();
	
EndProcedure

#EndRegion
