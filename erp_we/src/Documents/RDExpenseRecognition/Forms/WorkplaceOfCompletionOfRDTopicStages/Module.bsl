#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	// Installation of selections.
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);

	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Organization", Organization);
		QuickFilterStructure.Property("RegistrationPeriod", RegistrationPeriod);
	EndIf;
	
	RegistrationPeriodPresentation = TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(RegistrationPeriod);

	SetConditionalAppearance();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	UpdateListOfTopics();

	EstablishSelectionInListOfStudiesForExpenditureAllocation();

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CompaniesOnChange(Item)

	UpdateListOfTopicsToBeCompletedOnServer();

EndProcedure

&AtClient
Procedure RadioButtonsTopicsForRegistrationOnChange(Item)
	
	EstablishSelectionInListOfStudiesForExpenditureAllocation();

EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoice(Item, ChoiceData, StandardProcessing)
		
	StandardProcessing = False;
	
	CloseHandler = New CallbackDescription("RegistrationPeriodPresentationStartChoiceCompletion", ThisObject);
	FormParameters 	   = New Structure("Value, PeriodSelectionMode", RegistrationPeriod, "MONTH");
	
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

#EndRegion

#Region EventHandlersFormTablesListOfTopicsThatCanBeAttributedToExpenses

&AtClient
Procedure ListOfTopicsStagesForExpenseAllocationSelection(Item, RowSelected, Field, StandardProcessing)

	If Field = Items.ListOfTopicsStagesToAssignExpensesTopicResearchStage
			Or Field = Items.ListOfTopicsStagesToAssignExpensesCompletionDate
			Or Field = Items.ListOfTopicsStagesForExpenseAllocationCompleted Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.TopicStage, StandardProcessing);
	ElsIf Field = Items.ListOfTopicsStagesForExpenseAllocationCompletionDocument Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.CompletionDocument, StandardProcessing);
	ElsIf Field = Items.ListOfTopicsStagesForExpenseAllocationOrganization Then
		StandardProcessing = False;
		OpenObject(Item.CurrentData.Organization, StandardProcessing);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateTheListOfTopicsOfTheStagesToComplete(Command)

	UpdateListOfTopics();
	
EndProcedure

#EndRegion

#Region Private

#Region TimeConsumingOperations

&AtClient
Procedure UpdateListOfTopics()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("EventName", "UpdateTheListOfTopicsOfTheStagesToComplete");
		
	TimeConsumingOperation = UpdateListOfTopicsToBeCompletedOnServer();
	
	DisplayingStateOfLongRunningOperation(ThisForm, True);
		
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	CallbackDescription = New CallbackDescription("AfterUpdatingListOfTopicsStagesToCompletion", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	
EndProcedure

&AtServer
Function UpdateListOfTopicsToBeCompletedOnServer()

	ListOfTopicsStagesForExpenseAllocation.Clear();
	
	FillParameters = Documents.RDExpenseRecognition.FillParameters();
	FillParameters.BeginOfPeriod = RegistrationPeriod;
	FillParameters.EndOfPeriod = EndOfMonth(RegistrationPeriod);
	FillParameters.Organization = Organization;
	FillParameters.BusinessOperation = Enums.BusinessTransactions.CompletionOfResearchAndDevelopmentStages;
	
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

EndFunction

&AtClient
Procedure AfterUpdatingListOfTopicsStagesToCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
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
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure DisplayingStateOfLongRunningOperation(Form, PerformingTransaction)
	
	Items = Form.Items;

	Items.GroupFilters.Enabled = Not PerformingTransaction;
	Items.GroupPerformingCalculationInTheBackground.Visible = PerformingTransaction;
	
EndProcedure

&AtServer
Procedure LoadPreparedData(ResultAddress, AdditionalParameters)
	
	Data = GetFromTempStorage(ResultAddress);
	
	For Each String In Data Do
		TableRow = ListOfTopicsStagesForExpenseAllocation.Add();
		FillPropertyValues(TableRow, String);
	EndDo;	
	
EndProcedure

#EndRegion

&AtClient
Procedure OpenObject(Ref, StandardProcessing)

	If ValueIsFilled(Ref) Then
		ShowValue(Undefined, Ref);
	EndIf;

EndProcedure

&AtClient
Procedure GenerateACompletionDocument(Command)

	ClearMessages();

	TheListForRegistration = Items.ListOfTopicsStagesForExpenseAllocation;
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
	
	CurrentCompany = CurLineToDesign.Organization;

	TopicsStagesToCompletion = New Array();

	For Each CurLineToDesign In TheListForRegistration.SelectedRows Do

		CurRowData = TheListForRegistration.RowData(CurLineToDesign);
		If CurRowData.Organization = CurrentCompany Then
			If CurRowData.CompletionDocument.IsEmpty() Then
				TopicsStagesToCompletion.Add(CurRowData.TopicStage);
			Else
				MessageText = NStr("vi = 'Đối với %1 đã nhập chứng từ kết thúc. Phần tử không thể nằm trong thành phần chứng từ mới';
									|ru = 'Для %1 уже введен документ завершения. Элемент не может быть включен в состав нового документа';
									|en = 'The completion document has already been entered for %1. The item cannot be included in the new document'; fa = 'The completion document has already been entered for %1. The item cannot be included in the new document';
									|it = 'Per %1 è già stato inserito un documento di completamento. L''elemento non può essere incluso nel nuovo documento';
									|pl = 'Dla %1 już został wprowadzony dokument zakończenia. Element nie może być dołączony do zawartości nowego dokumentu';
									|tr = '%1 için zaten bir tamamlama belgesi girilmiş. Eleman yeni bir belgeye dahil edilemez'");
				CommonClient.MessageToUser(
					StrTemplate(MessageText, CurRowData.TopicStage),,
					"ListOfTopicsStagesForExpenseAllocation[" + ListOfTopicsStagesForExpenseAllocation.IndexOf(CurLineToDesign) + "].TopicStage");
			EndIf;
		EndIf;
	EndDo;

	If TopicsStagesToCompletion.Count() > 0 Then
		FillingValues = New Structure;
		FillingValues.Insert("TopicsStages", TopicsStagesToCompletion);
		FillingValues.Insert("Organization", CurrentCompany);
		FillingValues.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.CompletionOfResearchAndDevelopmentStages"));

		OpenForm("Document.RDExpenseRecognition.Form.DocumentForm", New Structure("FillingValues", FillingValues), , True, , , New CallbackDescription("GenerateACompletionDocumentCompletion", ThisObject));
	Else
		WarningText = NStr("vi = 'Không thể thực hiện lệnh, bởi vì không có chủ đề hợp lệ để kết thúc.';
							|ru = 'Команда не может быть выполнена, так как нет доступных тем к завершению.';
							|en = 'Cannot execute command because there are no topics available for completion.'; fa = 'Cannot execute command because there are no topics available for completion.';
							|it = 'Il comando non può essere eseguito perché non ci sono oggetti da completare.';
							|pl = 'Polecenie nie może być wykonane, ponieważ jest brak dostępnych tematów do zakończenia.';
							|tr = 'Tamamlanacak konu olmadığından komut yürütülemiyor.'");
		ShowMessageBox(Undefined, WarningText);
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateACompletionDocumentCompletion(Result, AdditionalParameters) Export
	
	UpdateListOfTopics();
	
EndProcedure

&AtClient
Procedure UpdateListOfTopicsRelatedToExpenses()
	
	UpdateListOfTopicsToBeCompletedOnServer();
	
EndProcedure

&AtClient
Procedure EstablishSelectionInListOfStudiesForExpenditureAllocation()
	
	If RadioButtonsTopicsForRegistration = 0 Then
		Items.ListOfTopicsStagesForExpenseAllocation.RowFilter = New FixedStructure("CompletionDocumentGenerated", False);
	Else
		Items.ListOfTopicsStagesForExpenseAllocation.RowFilter = New FixedStructure();
	EndIf;
	
EndProcedure

&AtClient
Procedure RegistrationPeriodPresentationStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod <> Undefined Then
		
		RegistrationPeriod = SelectedPeriod;
		RegistrationPeriodPresentation =
			TMCommonUseClientServer.GetPresentationOfRegistrationPeriod(RegistrationPeriod);
		
	EndIf;
	
	UpdateListOfTopicsRelatedToExpenses();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfTopicsStagesForExpenseAllocation.Name);
	
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfTopicsStagesForExpenseAllocation.CompletionDocumentGenerated");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);

EndProcedure

#EndRegion




