///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

// Form parameters are:
//     RefSet - Array of AnyRef - Items to be replaced with another Ref-type item.
//

#Region Variables

&AtClient
Var ReportsToSend; // Array of ErrorReport 

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetConditionalAppearance();
	
	InitializeReferencesToMerge(Parameters.RefSet);
	
	ObjectMetadata = MainItem.Metadata();
	HasRightToDeletePermanently = AccessRight("DataAdministration", Metadata) 
		Or AccessRight("InteractiveDelete", ObjectMetadata);
	ReplacementNotificationEvent        = DataProcessors.ReplaceAndMergeItems.ReplacementNotificationEvent();
	
	CurrentDeletionOption = "Check";
	
	// Initialize the step-by-step wizard.
	InitializeStepByStepWizardSettings();
	
	// 1. Search for occurrences by parameter.
	SearchStep = AddWizardStep(Items.SearchForUsageInstancesStep);
	SearchStep.BackButton.Visible = False;
	SearchStep.NextButton.Visible = False;
	SearchStep.CancelButton.Title = NStr("vi = 'Ngừng';
										|ru = 'Прервать';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Interrompere';
										|pl = 'Cancel';
										|tr = 'Durdur'");
	SearchStep.CancelButton.ToolTip = NStr("vi = 'Từ chối hợp nhất phần tử';
											|ru = 'Отказаться от объединения элементов';
											|en = 'Cancel merging.'; fa = 'Cancel merging.';
											|it = 'Rifiutare l''aggregazione degli elementi';
											|pl = 'Zrezygnować z łączenia elementów';
											|tr = 'Öğeleri birleştirmeyi reddet'");
	
	// 2. Select main item.
	Step = AddWizardStep(Items.MainItemSelectionStep);
	Step.BackButton.Visible = False;
	Step.NextButton.DefaultButton = True;
	Step.NextButton.Title = NStr("vi = 'Hợp nhất >';
								|ru = 'Объединить >';
								|en = 'Merge >'; fa = 'Merge >';
								|it = 'Aggregare >';
								|pl = 'Połączyć >';
								|tr = 'Birleştir >'");
	Step.NextButton.ToolTip = NStr("vi = 'Bắt đầu hợp nhất phần tử';
									|ru = 'Начать объединение элементов';
									|en = 'Run merging.'; fa = 'Run merging.';
									|it = 'Iniziare l''aggregazione degli elementi';
									|pl = 'Rozpocząć łączenie elementów';
									|tr = 'Öğeleri birleştirmeye başla'");
	Step.CancelButton.Title = NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'");
	Step.CancelButton.ToolTip = NStr("vi = 'Từ chối hợp nhất phần tử';
									|ru = 'Отказаться от объединения элементов';
									|en = 'Cancel merging.'; fa = 'Cancel merging.';
									|it = 'Rifiutare l''aggregazione degli elementi';
									|pl = 'Zrezygnować z łączenia elementów';
									|tr = 'Öğeleri birleştirmeyi reddet'");
	
	// 3. Waiting for process.
	Step = AddWizardStep(Items.MergeStep);
	Step.CancelButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.BackButton.Title = NStr("vi = 'Ngừng';
								|ru = 'Прервать';
								|en = 'Abort'; fa = 'توقف';
								|it = 'Interrompere';
								|pl = 'Abort';
								|tr = 'Durdur'");
	Step.BackButton.ToolTip = NStr("vi = 'Quay trở lại lựa chọn mục chính';
									|ru = 'Вернуться к выбору основного элемента';
									|en = 'Return to selection of the main item.'; fa = 'Return to selection of the main item.';
									|it = 'Tornare alla selezione dell''elemeno principale';
									|pl = 'Wróć do wyboru podstawowego elementu';
									|tr = 'Ana öğe seçimine geri dön'");
	
	// 4. Merged successfully.
	Step = AddWizardStep(Items.SuccessfulCompletionStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.DefaultButton = True;
	Step.CancelButton.Title = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Chiudere';
									|pl = 'Close';
									|tr = 'Kapat'");
	Step.CancelButton.ToolTip = NStr("vi = 'Đóng kết quả hợp nhất';
									|ru = 'Закрыть результаты объединения';
									|en = 'Close merge results.'; fa = 'Close merge results.';
									|it = 'Chiudere i risultati dell''aggregazione';
									|pl = 'Zamknij wyniki łączenia';
									|tr = 'Gruplama sonuçlarını kapat'");
	
	// 5. Reference replacement issues.
	Step = AddWizardStep(Items.RetryMergeStep);
	Step.BackButton.Title = NStr("vi = '< Về đầu';
								|ru = '< В начало';
								|en = '< To beginning'; fa = '< To beginning';
								|it = '< All''inizio';
								|pl = '< Na początek';
								|tr = '< Başa dön'");
	Step.BackButton.ToolTip = NStr("vi = 'Quay trở lại lựa chọn mục chính';
									|ru = 'Вернуться к выбору основного элемента';
									|en = 'Return to selection of the main item.'; fa = 'Return to selection of the main item.';
									|it = 'Tornare alla selezione dell''elemeno principale';
									|pl = 'Wróć do wyboru podstawowego elementu';
									|tr = 'Ana öğe seçimine geri dön'");
	Step.NextButton.DefaultButton = True;
	Step.NextButton.Title = NStr("vi = 'Lặp lại';
								|ru = 'Повторить';
								|en = 'Merge again'; fa = 'ادغام مجدد';
								|it = 'Ripetere';
								|pl = 'Merge again';
								|tr = 'Tekrarla'");
	Step.NextButton.ToolTip = NStr("vi = 'Hợp nhất lại';
									|ru = 'Повторить объединение';
									|en = 'Repeat merge'; fa = 'Repeat merge';
									|it = 'Ripetere l''aggregazione';
									|pl = 'Powtórzyć łączenie';
									|tr = 'Gruplamayı tekrarla'");
	Step.CancelButton.Title = NStr("vi = 'Hủy bỏ';
									|ru = 'Отмена';
									|en = 'Cancel'; fa = 'انصراف';
									|it = 'Annulla';
									|pl = 'Cancel';
									|tr = 'İptal'");
	Step.CancelButton.ToolTip = NStr("vi = 'Đóng kết quả hợp nhất';
									|ru = 'Закрыть результаты объединения';
									|en = 'Close merge results.'; fa = 'Close merge results.';
									|it = 'Chiudere i risultati dell''aggregazione';
									|pl = 'Zamknij wyniki łączenia';
									|tr = 'Gruplama sonuçlarını kapat'");
	
	// 6 Runtime errors.
	Step = AddWizardStep(Items.ErrorOccurredStep);
	Step.BackButton.Visible = False;
	Step.NextButton.Visible = False;
	Step.CancelButton.Title = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Chiudere';
									|pl = 'Close';
									|tr = 'Kapat'");
	
	// Update form items.
	WizardSettings.CurrentStep = SearchStep;
	SetVisibilityAvailability(ThisObject);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	OnActivateWizardStep();
	ReportsToSend = New Map;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	// References replacement is a critical step that requires confirmation of cancellation.
	If WizardSettings.ShowDialogBeforeClose
		And Items.WizardSteps.CurrentPage = Items.MergeStep Then
		
		Cancel = True;
		If Exit Then
			Return;
		EndIf;
		
		QueryText = NStr("vi = 'Ngừng hợp nhất các phần tử và đóng biểu mẫu?';
						|ru = 'Прервать объединение элементов и закрыть форму?';
						|en = 'Do you want to cancel merging and close the form?'; fa = 'Do you want to cancel merging and close the form?';
						|it = 'Interrompere l''aggregazione degli elementi e chiudere la forma?';
						|pl = 'Przerwać połączenie elementów i zamknąć formularz?';
						|tr = 'Öğelerin birleştirilmesi askıya alınsın ve form kapatılsın mı?'");
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Abort, NStr("vi = 'Ngừng';
												|ru = 'Прервать';
												|en = 'Cancel merging'; fa = 'Cancel merging';
												|it = 'Interrompere';
												|pl = 'Cancel merging';
												|tr = 'Durdur'"));
		Buttons.Add(DialogReturnCode.No,      NStr("vi = 'Không ngắt';
													|ru = 'Не прерывать';
													|en = 'Continue merging'; fa = 'Continue merging';
													|it = 'Non interrompere';
													|pl = 'Nie przerywać';
													|tr = 'İptal etmemek'"));
		
		Handler = New CallbackDescription("AfterConfirmCancelJob", ThisObject);
		ShowQueryBox(Handler, QueryText, Buttons, , DialogReturnCode.No);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)

	For Each UnsuccessfulReplacement In UnsuccessfulReplacements.GetItems() Do
		For Each DetailsOfReplacement In UnsuccessfulReplacement.GetItems() Do
			If DetailsOfReplacement.ErrorInfo = Undefined Then
				Continue;
			EndIf;
			ReportToSend = ReportsToSend[DetailsOfReplacement.ErrorInfo];
			If ReportToSend = Undefined Then
				ReportToSend = New ErrorReport(DetailsOfReplacement.ErrorInfo);
			EndIf;
			StandardSubsystemsClient.SendErrorReport(ReportToSend,
				DetailsOfReplacement.ErrorInfo);
		EndDo
	EndDo

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure MainItemSelectionTooltipURLProcessing(Item, URLValue, StandardProcessing)
	StandardProcessing = False;
	
	If URLValue = "SwitchDeletionMode" Then
		If CurrentDeletionOption = "Directly" Then
			CurrentDeletionOption = "Check" 
		Else
			CurrentDeletionOption = "Directly" 
		EndIf;
		GenerateMergeTooltip();
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsRefClick(Item)
	StandardSubsystemsClient.ShowDetailedInfo(Undefined, Item.ToolTip);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsageInstances

&AtClient
Procedure UsageInstancesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	Ref = UsageInstances.FindByID(RowSelected).Ref;
	
	If Field <> Items.UsageInstancesUsageInstancesCount Then
		ShowValue(, Ref);
		Return;
	EndIf;
	
	RefSet = New Array;
	RefSet.Add(Ref);
	DuplicateObjectsDetectionClient.ShowUsageInstances(RefSet);
	
EndProcedure

&AtClient
Procedure UsageInstancesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	Cancel = True;
	If Copy Then
		Return;
	EndIf;
	
	// Always add an item of the same type as the main one.
	ChoiceFormName = SelectionFormNameByReference(MainItem);
	If Not IsBlankString(ChoiceFormName) Then
		FormParameters = New Structure("MultipleChoice", True);
		If ReferencesToReplaceCommonOwner <> Undefined Then
			FormParameters.Insert("Filter", New Structure("Owner", ReferencesToReplaceCommonOwner));
		EndIf;
		OpenForm(ChoiceFormName, FormParameters, Item);
	EndIf;
EndProcedure

&AtClient
Procedure UsageInstancesBeforeDeleteRow(Item, Cancel)
	Cancel = True;
	
	CurrentData = Item.CurrentData;
	If CurrentData=Undefined Or UsageInstances.Count()<3 Then
		Return;
	EndIf;
	
	Ref = CurrentData.Ref;
	Code    = String(CurrentData.Code);
	
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xóa khỏi danh sách để hợp nhất phần tử ""%1""?';
			|ru = 'Удалить из списка для объединения элемент ""%1""?';
			|en = 'Delete item %1 from the merge list?'; fa = 'Delete item %1 from the merge list?';
			|it = 'Eliminare dall''elenco per l''aggregazione dell''elemento ""%1""?';
			|pl = 'Usunąć z listy do łączenia element ""%1""?';
			|tr = 'Öğe ""%1"" yenileme listesinden silinsin mi?'"),
		String(Ref) + ?(IsBlankString(Code), "", " (" + Code + ")" ));
	
	Notification = New CallbackDescription("UsageInstancesBeforeDeleteRowCompletion", ThisObject, New Structure);
	Notification.AdditionalParameters.Insert("CurrentRow", Item.CurrentRow);
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);
EndProcedure

&AtClient
Procedure UsageInstancesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	StandardProcessing = False;
	
	If TypeOf(ValueSelected) = Type("Array") Then
		ItemsToAdd = ValueSelected;
	Else
		ItemsToAdd = New Array;
		ItemsToAdd.Add(ValueSelected);
	EndIf;
	
	AddUsageInstancesRows(ItemsToAdd);
	GenerateMergeTooltip();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUnsuccessfulReplacements

&AtClient
Procedure UnsuccessfulReplacementsOnActivateRow(Item)

	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		FailureReasonDetails = "";	
		Items.DecorationSendErrorReport.Visible = False;
		Return;
	EndIf;
		
	FailureReasonDetails = CurrentData.DetailedReason;
	If CurrentData.ErrorInfo = Undefined Then
		Items.DecorationSendErrorReport.Visible = False;
	Else
		StandardSubsystemsClient.ConfigureVisibilityAndTitleForURLSendErrorReport(
			Items.DecorationSendErrorReport, CurrentData.ErrorInfo);
	EndIf;
	
EndProcedure

&AtClient
Procedure UnsuccessfulReplacementsSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	
	Ref = UnsuccessfulReplacements.FindByID(RowSelected).Ref;
	If Ref <> Undefined Then
		ShowValue(, Ref);
	EndIf;

EndProcedure

&AtClient
Procedure DecorationSendErrorReportClick(Item)

	CurrentData = Items.UnsuccessfulReplacements.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	ReportToSend = ReportsToSend[CurrentData.ErrorInfo];
	If ReportToSend = Undefined Then
		ReportToSend = New ErrorReport(CurrentData.ErrorInfo);
		ReportsToSend[CurrentData.ErrorInfo] = ReportToSend;
	EndIf;
	StandardSubsystemsClient.ShowErrorReport(ReportToSend);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WizardButtonHandler(Command)
	
	If Command.Name = WizardSettings.NextButton Then
		WizardStepNext();
	ElsIf Command.Name = WizardSettings.BackButton Then
		WizardStepBack();
	ElsIf Command.Name = WizardSettings.CancelButton Then
		WizardStepCancel();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenUsageInstancesItem(Command)
	CurrentData = Items.UsageInstances.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(, CurrentData.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure UsageInstances(Command)
	
	CurrentData = Items.UsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	RefSet = New Array;
	RefSet.Add(CurrentData.Ref);
	DuplicateObjectsDetectionClient.ShowUsageInstances(RefSet);
	
EndProcedure

&AtClient
Procedure AllUsageInstances(Command)
	
	If UsageInstances.Count() > 0 Then 
		DuplicateObjectsDetectionClient.ShowUsageInstances(UsageInstances);
	EndIf;
	
EndProcedure

&AtClient
Procedure MarkAsOriginal(Command)
	CurrentData = Items.UsageInstances.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	MainItem = CurrentData.Ref;
	GenerateMergeTooltip();
EndProcedure

&AtClient
Procedure OpenUnsuccessfulReplacementItem(Command)
	CurrentData = Items.UnsuccessfulReplacements.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(, CurrentData.Ref);
	EndIf;
EndProcedure

&AtClient
Procedure ExpandAllUnsuccessfulReplacements(Command)
	FormTree = Items.UnsuccessfulReplacements;
	For Each Item In UnsuccessfulReplacements.GetItems() Do
		FormTree.Expand(Item.GetID(), True);
	EndDo;
EndProcedure

&AtClient
Procedure CollapseAllUnsuccessfulReplacements(Command)
	FormTree = Items.UnsuccessfulReplacements;
	For Each Item In UnsuccessfulReplacements.GetItems() Do
		FormTree.Collapse(Item.GetID());
	EndDo;
EndProcedure

#EndRegion

#Region Private

#Region WizardPageNavigation

&AtServer
Procedure InitializeStepByStepWizardSettings()
	WizardSettings = New Structure;
	WizardSettings.Insert("Steps", New Array);
	WizardSettings.Insert("CurrentStep", Undefined);
	
	// Interface part IDs.
	WizardSettings.Insert("PagesGroup", Items.WizardSteps.Name);
	WizardSettings.Insert("NextButton",   Items.WizardStepNext.Name);
	WizardSettings.Insert("BackButton",   Items.WizardStepBack.Name);
	WizardSettings.Insert("CancelButton",  Items.WizardStepCancel.Name);
	
	// To process long-running operations.
	WizardSettings.Insert("ShowDialogBeforeClose", False);
	
	// Everything is disabled by default.
	Items.WizardStepNext.Visible  = False;
	Items.WizardStepBack.Visible  = False;
	Items.WizardStepCancel.Visible = False;
EndProcedure

// Adds a wizard step. Navigation between pages is performed according to the order the pages are added.
//
// Parameters:
//   Page - FormGroup - a page that contains step items.
//
// Returns:
//   Structure - Describes page settings, where:
//       * PageName - String - a page name.
//       * NextButton - Structure - description of "Next" button, where:
//           ** Title - String - a button title. The default value is "Next >".
//           ** ToolTip - String - button tooltip. Corresponds to the button title by default.
//           ** Visible - Boolean - if True, the button is visible. Default value is True.
//           ** Enabled - Boolean - if True, the button is clickable. Default value is True.
//           ** DefaultButton - Boolean - if True, the button is the main button of the form. Default value is True.
//       * BackButton - Structure - description of the "Back" button, where:
//           ** Title - String - a button title. Default value - "< Back".
//           ** ToolTip - String - button tooltip. Corresponds to the button title by default.
//           ** Visible - Boolean - if True, the button is visible. Default value is True.
//           ** Enabled - Boolean - if True, the button is clickable. Default value is True.
//           ** DefaultButton - Boolean - if True, the button is the main button of the form. Default value is False.
//       * CancelButton - Structure - description of the "Cancel" button, where:
//           ** Title - String - a button title. The default value is "Cancel".
//           ** ToolTip - String - button tooltip. Corresponds to the button title by default.
//           ** Visible - Boolean - if True, the button is visible. The default value is True.
//           ** Enabled - Boolean - if True, the button is clickable. Default value is True.
//           ** DefaultButton - Boolean - if True, the button is the main button of the form. Default value is False.
//
&AtServer
Function AddWizardStep(Val Page)
	StepDescription = New Structure;
	StepDescription.Insert("IndexOf", 0);
	StepDescription.Insert("PageName", "");
	StepDescription.Insert("BackButton", WizardButton());
	StepDescription.Insert("NextButton", WizardButton());
	StepDescription.Insert("CancelButton", WizardButton());
	StepDescription.PageName = Page.Name;
	
	StepDescription.BackButton.Title = NStr("vi = '< Quay lại';
											|ru = '< Назад';
											|en = '< Back'; fa = '< بازگشت';
											|it = '< Indietro';
											|pl = '< Wróć';
											|tr = '< Geri'");
	
	StepDescription.NextButton.DefaultButton = True;
	StepDescription.NextButton.Title = NStr("vi = 'Tiếp theo >';
											|ru = 'Далее >';
											|en = 'Next >'; fa = 'بعدی >';
											|it = 'Avanti >';
											|pl = 'Dalej >';
											|tr = 'İleri >'");
	
	StepDescription.CancelButton.Title = NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Annulla';
												|pl = 'Anuluj';
												|tr = 'İptal'");
	
	WizardSettings.Steps.Add(StepDescription);
	
	StepDescription.IndexOf = WizardSettings.Steps.UBound();
	Return StepDescription;
EndFunction

&AtClientAtServerNoContext
Procedure SetVisibilityAvailability(Form)
	
	Items = Form.Items;
	WizardSettings = Form.WizardSettings;
	CurrentStep = WizardSettings.CurrentStep;
	
	// Navigate to the page.
	Items[WizardSettings.PagesGroup].CurrentPage = Items[CurrentStep.PageName];
	
	// Update buttons.
	UpdateWizardButtonProperties(Items[WizardSettings.NextButton],  CurrentStep.NextButton);
	UpdateWizardButtonProperties(Items[WizardSettings.BackButton],  CurrentStep.BackButton);
	UpdateWizardButtonProperties(Items[WizardSettings.CancelButton], CurrentStep.CancelButton);
	
EndProcedure

// Navigates to the specified page.
//
// Parameters:
//   StepOrIndexOrFormGroup - Structure
//                              - Number
//                              - FormGroup - a page to navigate to.
//
&AtClient
Procedure GoToWizardStep1(Val StepOrIndexOrFormGroup)
	
	// Search for step.
	Type = TypeOf(StepOrIndexOrFormGroup);
	If Type = Type("Structure") Then
		StepDescription = StepOrIndexOrFormGroup;
	ElsIf Type = Type("Number") Then
		StepIndex = StepOrIndexOrFormGroup;
		If StepIndex < 0 Then
			Raise NStr("vi = 'Thử thoát khỏi bước đầu tiên trên bảng điều khiển';
						|ru = 'Попытка выхода назад из первого шага мастера';
						|en = 'Attempt to go back from the first step.'; fa = 'Attempt to go back from the first step.';
						|it = 'Tentativo di uscita indietro dal primo passo master';
						|pl = 'Próba wyjścia z powrotem z pierwszego kroku kreatora';
						|tr = 'İlk sihirbaz adımını aşma girişimi'");
		ElsIf StepIndex > WizardSettings.Steps.UBound() Then
			Raise NStr("vi = 'Thử thoát khỏi bước cuối cùng trên bảng điều khiển';
						|ru = 'Попытка выхода за последний шаг мастера';
						|en = 'Attempt to go next from the last step.'; fa = 'Attempt to go next from the last step.';
						|it = 'Tentativo di uscita indietro dal ultimo passo master';
						|pl = 'Próba wyjścia poza ostatnim krok kreatora';
						|tr = 'Son sihirbaz adımını aşma girişimi'");
		EndIf;
		StepDescription = WizardSettings.Steps[StepIndex];
	Else
		StepFound = False;
		RequiredPageName = StepOrIndexOrFormGroup.Name;
		For Each StepDescription In WizardSettings.Steps Do
			If StepDescription.PageName = RequiredPageName Then
				StepFound = True;
				Break;
			EndIf;
		EndDo;
		If Not StepFound Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không tìm thấy bước ""%1"".';
					|ru = 'Не найден шаг ""%1"".';
					|en = 'Step %1 is not found.'; fa = 'Step %1 is not found.';
					|it = 'Nessun passo trovato""%1"".';
					|pl = 'Nie znaleziono krok ""%1"".';
					|tr = 'Adım ""%1"" bulunamadı.'"),
				RequiredPageName);
		EndIf;
	EndIf;
	
	// Step switch.
	WizardSettings.CurrentStep = StepDescription;
	
	// Update visibility.
	SetVisibilityAvailability(ThisObject);
	OnActivateWizardStep();
	
EndProcedure

#EndRegion

#Region WizardEvents

&AtClient
Procedure OnActivateWizardStep()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	
	If CurrentPage = Items.SearchForUsageInstancesStep Then
		
		StartDeterminingUseLocations();
		
	ElsIf CurrentPage = Items.MainItemSelectionStep Then
		
		GenerateMergeTooltip();
		
	ElsIf CurrentPage = Items.MergeStep Then
		
		StartReplacingLinks();
		
	ElsIf CurrentPage = Items.SuccessfulCompletionStep Then
		
		Items.MergeResult.Title = CompleteMessage() + " """ + String(MainItem) + """";
		NotifyOfSuccessfulReplacement(PlacesofUseInArray());
		
	ElsIf CurrentPage = Items.RetryMergeStep Then
		
		GenerateUnsuccessfulReplacementLabel();
		NotifyOfSuccessfulReplacement(DeleteProcessedItemsFromUsageInstances());
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepNext()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	Step = WizardSettings.CurrentStep; // See AddWizardStep
	If CurrentPage = Items.MainItemSelectionStep Then
		
		ErrorText = CheckCanReplaceReferences();
		If Not IsBlankString(ErrorText) Then
			StandardSubsystemsClient.ShowQuestionToUser(Undefined, 
				StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Không thể kết hợp các mục vì một lý do:
					|%1';
					|ru = 'Невозможно объединить элементы по причине:
					|%1';
					|en = 'Cannot merge items due to:
					|%1'; fa = 'Cannot merge items due to:
					|%1';
					|it = 'Impossibile aggregare gli elementi a causa:
					| %1';
					|pl = 'Nie można połączyć elementy z powodu:
					|%1';
					|tr = 'Aşağıdaki nedenden dolayı öğeler birleştirilemedi: 
					|%1'"), ErrorText), QuestionDialogMode.OK);
			Return;
		EndIf;
		
		GoToWizardStep1(Step.IndexOf + 1);
		
	ElsIf CurrentPage = Items.RetryMergeStep Then
		GoToWizardStep1(Items.MergeStep);
	Else
		GoToWizardStep1(Step.IndexOf + 1);
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepBack()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.RetryMergeStep Then
		GoToWizardStep1(Items.SearchForUsageInstancesStep);
	Else
		Step = WizardSettings.CurrentStep;// See AddWizardStep
		GoToWizardStep1(Step.IndexOf - 1);
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepCancel()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.MergeStep Then
		WizardSettings.ShowDialogBeforeClose = False;
	EndIf;
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region ItemsMergeUtilityProcedures

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesMain.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = New DataCompositionField("MainItem");

	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesRef.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesCode.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageInstancesCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.Ref");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = New DataCompositionField("MainItem");

	Item.Appearance.SetParameterValue("Font", StyleFonts.MainListItem);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesNotUsed.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageInstancesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", True);
	Item.Appearance.SetParameterValue("Show", True);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesNotUsed.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageInstancesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageInstancesCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageInstancesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.LessOrEqual;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", False);
	Item.Appearance.SetParameterValue("Show", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UnsuccessfulReplacementsCode.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UnsuccessfulReplacements.Code");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UsageInstancesUsageInstancesCount.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsageInstances.UsageInstancesCount");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Greater;
	ItemFilter.RightValue = 0;

	Item.Appearance.SetParameterValue("Visible", True);
	Item.Appearance.SetParameterValue("Show", True);

EndProcedure

&AtServer
Procedure InitializeReferencesToMerge(Val ReferencesArrray)
	
	ReferencesToReplaceCommonOwner = CheckReferencesToMerge(ReferencesArrray);
	MainItem = ReferencesArrray[0];
	
	UsageInstances.Clear();
	For Each Item In ReferencesArrray Do
		UsageInstances.Add().Ref = Item;
	EndDo;
EndProcedure

&AtServerNoContext
Function CheckReferencesToMerge(Val RefSet)
	
	RefsCount = RefSet.Count();
	If RefsCount < 2 Then
		Raise NStr("vi = 'Để hợp nhất, hãy chỉ ra nhiều phần tử.';
					|ru = 'Для объединения укажите несколько элементов.';
					|en = 'Select more than one item to merge.'; fa = 'Select more than one item to merge.';
					|it = 'Per unire, indicare più elementi.';
					|pl = 'W celu połączenia wskaż kilka elementów.';
					|tr = 'Gruplamak için birkaç öğe belirtin.'");
	EndIf;
	
	TheFirstControl = RefSet[0];	
	BasicMetadata = TheFirstControl.Metadata();
	VerifyAccessRights("Update", BasicMetadata);
	
	Characteristics = New Structure("Owners, Hierarchical, HierarchyType", New Array, False);
	FillPropertyValues(Characteristics, BasicMetadata);
	
	HasOwners = Characteristics.Owners.Count() > 0;
	HasGroups    = Characteristics.Hierarchical And Characteristics.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems;
	
	QueryText = 
		"SELECT Ref AS Ref,
		|&Owner AS Owner,
		|&IsFolder AS IsFolder
		|INTO RefsToReplace
		|FROM #TableName WHERE Ref IN (&RefSet)
		|INDEX BY Owner, IsFolder
		|;
		|SELECT 
		|	COUNT(DISTINCT Owner) AS OwnersCount,
		|	MIN(Owner)              AS CommonOwner,
		|	MAX(IsFolder)            AS HasGroups,
		|	COUNT(Ref)             AS RefsCount
		|FROM
		|	RefsToReplace";
	QueryText = StrReplace(QueryText, "#TableName", BasicMetadata.FullName());
	QueryText = StrReplace(QueryText, "&Owner", ?(HasOwners, "Owner", "UNDEFINED"));
	QueryText = StrReplace(QueryText, "&IsFolder", ?(HasGroups, "IsFolder", "FALSE"));
	
	Query = New Query(QueryText);
	Query.SetParameter("RefSet", RefSet);
	
	Control = Query.Execute().Unload()[0];
	If Control.HasGroups Then
		Raise NStr("vi = 'Một trong các phần tử được hợp nhất là nhóm.
			|Không thể hợp nhất các nhóm.';
			|ru = 'Один из объединяемых элементов является группой.
			|Группы не могут быть объединены.';
			|en = 'One of the items to merge is a group.
			|Groups cannot be merged.'; fa = 'One of the items to merge is a group.
			|Groups cannot be merged.';
			|it = 'Uno degli elementi aggregati è un gruppo.
			| Gruppi non possono essere aggregati.';
			|pl = 'Jeden z łączonych elementów jest grupą.
			|Grupy nie mogą być łączone.';
			|tr = 'Birleştirilmiş öğelerden biri bir gruptur. 
			|Gruplar birleştirilemez.'");
	ElsIf Control.OwnersCount > 1 Then 
		Raise NStr("vi = 'Các phần tử hợp nhất có các đối tượng chủ khác nhau.
			|Không thể hợp nhất các phần tử như vậy.';
			|ru = 'У объединяемых элементов различные владельцы.
			|Такие элементы не могут быть объединены.';
			|en = 'Items to merge have different owners.
			|They cannot be merged.'; fa = 'Items to merge have different owners.
			|They cannot be merged.';
			|it = 'Gli elementi aggregati hanno diversi proprietari.
			| Tali elementi non possono essere aggregati.';
			|pl = 'U łączonych elementów są różne właściciele.
			|Takie elementy nie mogą być łączone.';
			|tr = 'Birleştirilmiş öğelerin farklı sahipleri var. 
			|Bu tür maddeler birleştirilemez.'");
	ElsIf Control.RefsCount <> RefsCount Then
		Raise NStr("vi = 'Tất cả các phần tử hợp nhất cần có cùng một kiểu.';
					|ru = 'Все объединяемые элементы должны быть одного типа.';
					|en = 'All items to merge must be of the same type.'; fa = 'All items to merge must be of the same type.';
					|it = 'Tutti gli elementi aggregati devono essere dello stesso tipo.';
					|pl = 'Wszystkie łączone elementy muszą być tego samego rodzaju.';
					|tr = 'Tüm birleştirilebilir öğeler aynı tipte olmalıdır.'");
	EndIf;

	Return ?(HasOwners, Control.CommonOwner, Undefined);
	
EndFunction

// Parameters:
//  QuestionResult - DialogReturnCode
//  AdditionalParameters - Structure
//
&AtClient
Procedure UsageInstancesBeforeDeleteRowCompletion(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	// Actual deletion from the table.
	String = UsageInstances.FindByID(AdditionalParameters.CurrentRow);
	If String = Undefined Then
		Return;
	EndIf;
	
	DeletedRowIndex = UsageInstances.IndexOf(String);
	CalculateMain     = String.Ref = MainItem;
	
	UsageInstances.Delete(String);
	If CalculateMain Then
		LastRowIndex = UsageInstances.Count() - 1;
		If DeletedRowIndex <= LastRowIndex Then 
			MainStringIndex = DeletedRowIndex;
		Else
			MainStringIndex = LastRowIndex;
		EndIf;
			
		MainItem = UsageInstances[MainStringIndex].Ref;
	EndIf;
	
	GenerateMergeTooltip();
EndProcedure

&AtServer
Procedure GenerateMergeTooltip()

	If HasRightToDeletePermanently Then
		If CurrentDeletionOption = "Check" Then
			ToolTipText = NStr("vi = 'Phần tử (%1) sẽ <a href = ""[Action]"">bị đặt dấu xóa</a> và được thay thế trong tất cả các chỗ
				|sử dụng bởi ""%2"" (đánh dấu mũi tên).';
				|ru = 'Элементы (%1) будут <a href = ""[Action]"">помечены на удаление</a> и заменены во всех местах
				|использования на ""%2"" (отмечен стрелкой).';
				|en = '%1 items will be <a href = ""[Action]"">marked for deletion</a>
				|and replaced with %2.'; fa = '%1 items will be <a href = ""[Action]"">marked for deletion</a>
				|and replaced with %2.';
				|it = 'Элементы (%1) будут <a href = ""[Action]"">помечены на удаление</a> и заменены во всех местах
				|использования на ""%2"" (отмечен стрелкой).';
				|pl = '%1 items will be <a href = ""[Action]"">marked for deletion</a>
				|and replaced with %2.';
				|tr = 'Öğeler (%1), <a href = ""[Action]""> silinmek üzere işaretlendi</a> ve (okla işaretli) tüm kullanım yerlerinde 
				| %2ile değiştirilecektir.'");
			RowParameters = New Structure("Action", "SwitchDeletionMode");
			ToolTipText = StringFunctionsClientServer.InsertParametersIntoString(ToolTipText, RowParameters);
		Else
			ToolTipText = NStr("vi = 'Phần tử (%1) sẽ bị <a href = ""[Action]"">xóa vĩnh viễn</a> và được thay thế trong tất cả chỗ
				|sử dụng bởi ""%2"" (đánh dấu mũi tên).';
				|ru = 'Элементы (%1) будут <a href = ""[Action]"">удалены безвозвратно</a> и заменены во всех местах
				|использования на ""%2"" (отмечен стрелкой).';
				|en = '%1 items will be <a href = ""[Action]"">permanently deleted</a>
				|and replaced with %2.'; fa = '%1 items will be <a href = ""[Action]"">permanently deleted</a>
				|and replaced with %2.';
				|it = 'Элементы (%1) будут <a href = ""[Action]"">удалены безвозвратно</a> и заменены во всех местах
				|использования на ""%2"" (отмечен стрелкой).';
				|pl = '%1 items will be <a href = ""[Action]"">permanently deleted</a>
				|and replaced with %2.';
				|tr = 'Öğeler (%1), <a href = ""[Action]""> kalıcı olarak silindi </a> ve tüm kullanım yerlerinde
				| (okla işaretlenmiş) ''''%2'''' ile değiştirildi.'");
			RowParameters = New Structure("Action", "SwitchDeletionMode");
			ToolTipText = StringFunctionsClientServer.InsertParametersIntoString(ToolTipText, RowParameters);
		EndIf;
	Else
		ToolTipText = NStr("vi = 'Yếu tố (%1) sẽ được đánh dấu để xóa và thay thế ở tất cả các nơi
			|sử dụng cho ""%2"" (được đánh dấu bằng một mũi tên).';
			|ru = 'Элементы (%1) будут помечены на удаление и заменены во всех местах
			|использования на ""%2"" (отмечен стрелкой).';
			|en = '%1 items will be marked for deletion
			|and replaced with %2.'; fa = '%1 items will be marked for deletion
			|and replaced with %2.';
			|it = 'Elementi (%1) saranno segnati per l''eliminazione e sostituiti in tutti i posti 
			| d''utilizzo per ""%2"" (contrassegnati da una freccia).';
			|pl = 'Elementy (%1) będą oznaczone do usunięcia i wymienione we wszystkich miejscach
			|wykorzystania na ""%2"" (zaznaczony strzałką).';
			|tr = 'Öğeler (%1) silinmek üzere işaretlenecek ve (okla işaretlenmiş) tüm kullanım %2 yerlerinde 
			| ile değiştirildi.'");
	EndIf;
	
	Items.MainItemSelectionTooltip.Title = StringFunctions.FormattedString(ToolTipText, UsageInstances.Count()-1, MainItem);
	
EndProcedure

&AtClient
Function CompleteMessage()
	Return StringFunctionsClientServer.StringWithNumberForAnyLanguage(
		NStr("vi = ';%1 phần tử được hợp nhất vào:;;%1 hai phần tử được hợp nhất vào:;%1 nhiều phần tử được hợp nhất vào:;%1 hai phần tử được hợp nhất vào:';
			|ru = ';%1 элемент объединен в:;;%1 элемента объединено в:;%1 элементов объединено в:;%1 элемента объединено в:';
			|en = ';%1 item was merged into:;;;;%1 items were merged into:'; fa = ';%1 item was merged into:;;;;%1 items were merged into:';
			|it = ';%1 elemento aggregato in :;;%1 elemento aggregato in:;;%1 elementi aggregati in :;;%1 elementi aggregati in:';
			|pl = ';%1 element połączony w:;;%1 elementy połączone w:;%1 elementów połączono w:;%1 elementy połączono w:';
			|tr = ';%1 öğe birleştirildi:;;%1 öğe birleştirildi:;%1 öğe birleştirildi:;%1 öğe birleştirildi:'"),
		UsageInstances.Count());
EndFunction

&AtClient
Procedure GenerateUnsuccessfulReplacementLabel()
	
	Items.UnsuccessfulReplacementsResult.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Chưa thực hiện hợp nhất các phần tử. Trong nhiều nơi sử dụng không thể tiến hành
			|tự động thay thế thành ""%1"".';
			|ru = 'Объединение элементов не выполнено. В некоторых местах использования не может быть произведена
			|автоматическая замена на ""%1"".';
			|en = 'Cannot merge the items. Cannot replace some items
			|to ""%1"".'; fa = 'Cannot merge the items. Cannot replace some items
			|to ""%1"".';
			|it = 'L''aggregazione degli elementi non è stata effettuata. In alcuni posti d''utilizzo non può essere effettuata 
			| la sostituzione automatica per  ""%1"".';
			|pl = 'Łączenie elementów nie zostało wykonane. W niektórych miejscach użytkowania nie może być wykonana
			| automatyczna wymiana na ""%1"".';
			|tr = 'Öğeler birleştirilemedi. Bazı kullanım yerlerinde ""%1"" ile otomatik değiştirme
			| yapılamaz.'"),
		MainItem);
	
EndProcedure

// Parameters:
//     DataList - Array of AnyRef
//
&AtClient
Procedure NotifyOfSuccessfulReplacement(Val DataList)
	CommonClient.NotifyObjectsChanged(DataList);
EndProcedure

&AtServerNoContext
Function SelectionFormNameByReference(Val Ref)
	Meta = Metadata.FindByType(TypeOf(Ref));
	Return ?(Meta = Undefined, Undefined, Meta.FullName() + ".ChoiceForm");
EndFunction

&AtServer
Procedure AddUsageInstancesRows(Val ReferencesArrray)
	LastItemIndex = Undefined;
	MetadataCache    = New Map;
	
	Filter = New Structure("Ref");
	For Each Ref In ReferencesArrray Do
		Filter.Ref = Ref;
		ExistingRows = UsageInstances.FindRows(Filter);
		If ExistingRows.Count() = 0 Then
			String = UsageInstances.Add();
			String.Ref = Ref;
			String.Code      = ObjectCode(Ref, MetadataCache);
			String.Owner = ObjectOfOwner(Ref, MetadataCache);
			String.UsageInstancesCount = -1;
			String.NotUsed    = NStr("vi = 'Chưa tính';
									|ru = 'Не рассчитано';
									|en = 'Locations not searched for'; fa = 'Locations not searched for';
									|it = 'Non calcolato';
									|pl = 'Nie obliczono ';
									|tr = 'Hesaplanmadı'");
		Else
			String = ExistingRows[0];
		EndIf;
		
		LastItemIndex = String.GetID();
	EndDo;
	
	If LastItemIndex <> Undefined Then
		Items.UsageInstances.CurrentRow = LastItemIndex;
	EndIf;
EndProcedure

// Returns:
//   String - Catalog code if specified, 
//   Undefined if there is no code.
//
&AtServerNoContext
Function ObjectCode(Val Ref, MetadataCache)
	Data = MetadataDetails(Ref, MetadataCache);
	Return ?(Data.HasCode, Ref.Code, Undefined);
EndFunction

// Returns:
//   CatalogRef - Catalog owner if specified, 
//   Undefined if there is no owner.
//
&AtServerNoContext
Function ObjectOfOwner(Val Ref, MetadataCache)
	Data = MetadataDetails(Ref, MetadataCache);
	Return ?(Data.HasOwner, Ref.Owner, Undefined);
EndFunction

&AtServerNoContext
Function MetadataDetails(Val Ref, MetadataCache)
	
	ObjectMetadata = Ref.Metadata();
	Data = MetadataCache[ObjectMetadata];
	
	If Data = Undefined Then
		Test = New Structure("CodeLength, Owners", 0, New Array);
		FillPropertyValues(Test, ObjectMetadata);
		
		Data = New Structure;
		Data.Insert("HasCode", Test.CodeLength > 0);
		Data.Insert("HasOwner", Test.Owners.Count() > 0);
		
		MetadataCache[ObjectMetadata] = Data;
	EndIf;
	
	Return Data;
EndFunction

&AtClient
Function DeleteProcessedItemsFromUsageInstances()
	Result = New Array;
	
	Unsuccessful = New Map;
	For Each Item In UnsuccessfulReplacements.GetItems() Do
		Unsuccessful.Insert(Item.Ref, True);
	EndDo;
	
	IndexOf = UsageInstances.Count() - 1;
	While IndexOf >= 0 Do
		Ref = UsageInstances[IndexOf].Ref;
		If Ref <> MainItem And Unsuccessful[Ref] = Undefined Then
			UsageInstances.Delete(IndexOf);
			Result.Add(Ref);
		EndIf;
		IndexOf = IndexOf - 1;
	EndDo;
	
	Return Result;
EndFunction

&AtServer
Function CheckCanReplaceReferences()
	
	RefSet = New Array;
	ReplacementPairs   = New Map;
	For Each UsageInstance1 In UsageInstances Do
		RefSet.Add(UsageInstance1.Ref);
		ReplacementPairs.Insert(UsageInstance1.Ref, MainItem);
	EndDo;
	
	Try
		CheckReferencesToMerge(RefSet);
	Except
		Return ErrorProcessing.BriefErrorDescription(ErrorInfo());
	EndTry;
	
	ReplacementParameters = New Structure("DeletionMethod", CurrentDeletionOption);
	Return DuplicateObjectsDetection.CheckCanReplaceItemsString(ReplacementPairs, ReplacementParameters);
	
EndFunction

#EndRegion

#Region TimeConsumingOperations1

&AtClient
Procedure StartDeterminingUseLocations()
	Job = DefineUsageInstances();
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New CallbackDescription("AfterCompleteDeterminingUseLocations", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function DefineUsageInstances()
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Tìm kiếm và xóa phần tử trùng lặp: Xác định những nơi sử dụng';
													|ru = 'Поиск и удаление дублей: Определение мест использования';
													|en = 'Duplicate cleaner: Find occurrences'; fa = 'Duplicate cleaner: Find occurrences';
													|it = 'Ricerca e eliminazione dei doppi: Determinazione dei posti di utilizzo';
													|pl = 'Wyszukiwanie i usuwanie duplikatów: Określenie miejsc użytkowania';
													|tr = 'Kopya Temizleyici: Kullanım konumlarını belirleme'");
	Return TimeConsumingOperations.ExecuteInBackground("DuplicateObjectsDetection.DefineUsageInstances", 
		UsageInstances.Unload(, "Ref").UnloadColumn(0), StartSettings1);
		
EndFunction

&AtClient
Procedure AfterCompleteDeterminingUseLocations(Job, AdditionalParameters) Export
	
	WizardSettings.ShowDialogBeforeClose = False;
	If Job = Undefined 
		Or Items.WizardSteps.CurrentPage = Items.MainItemSelectionStep Then
		GoToWizardStep1(Items.MainItemSelectionStep);
		Return;
	EndIf;
	
	If Job.Status <> "Completed2" Then
		Brief1 = NStr("vi = 'Không thể xác định nơi sử dụng các phần tử hợp nhất:';
						|ru = 'Не удалось определить места использования объединяемых элементов:';
						|en = 'Couldn''t find item occurrences:'; fa = 'Couldn''t find item occurrences:';
						|it = 'Non è stato possibile definite i posti di utilizzo degli elementi aggregati:';
						|pl = 'Nie udało się określić miejca użycia połączanych elementów:';
						|tr = 'Birleştirilen öğelerin kullanım yerleri belirlenemedi:'") 
			+ Chars.LF + Job.BriefErrorDescription;
		More = Brief1 + Chars.LF + Chars.LF + Job.DetailErrorDescription;
		Items.ErrorTextLabel.Title = Brief1;
		Items.DetailsRef.ToolTip    = More;
		GoToWizardStep1(Items.ErrorOccurredStep);
		Activate();
		Return;
	EndIf;
		
	FillUsageInstances(Job.ResultAddress);
	Step = WizardSettings.CurrentStep; // See AddWizardStep
	GoToWizardStep1(Step.IndexOf + 1);
	Activate();
		
EndProcedure

&AtClient
Procedure StartReplacingLinks()
	
	ReportsToSend = New Map;

	WizardSettings.ShowDialogBeforeClose = True;
	Job = ReplaceReferences();
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New CallbackDescription("AfterCompletionReplacingLinks", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
	
EndProcedure

&AtServer
Function ReplaceReferences()
	
	MethodParameters = New Structure("ReplacementPairs, DeletionMethod");
	MethodParameters.ReplacementPairs = New Map;
	For Each UsageInstance1 In UsageInstances Do
		MethodParameters.ReplacementPairs.Insert(UsageInstance1.Ref, MainItem);
	EndDo;
	MethodParameters.Insert("DeletionMethod", CurrentDeletionOption);

	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = NStr("vi = 'Tìm kiếm và xóa phần tử trùng lặp: Hợp nhất các phần tử';
													|ru = 'Поиск и удаление дублей: Объединение элементов';
													|en = 'Duplicate cleaner: Merge items'; fa = 'Duplicate cleaner: Merge items';
													|it = 'Ricerca e eliminazione dei doppi: Aggregazione degli elementi';
													|pl = 'Wyszukiwanie i usuwanie duplikatów: Łączenie elementów';
													|tr = 'Kopya Temizleyici: Öğeleri birleştir'");
	
	Return TimeConsumingOperations.ExecuteInBackground("DuplicateObjectsDetection.ReplaceReferences", 
		MethodParameters, StartSettings1);
EndFunction

&AtClient
Procedure AfterCompletionReplacingLinks(Job, AdditionalParameters) Export
	
	WizardSettings.ShowDialogBeforeClose = False;
	If Job = Undefined 
		Or Items.WizardSteps.CurrentPage = Items.MainItemSelectionStep Then
		GoToWizardStep1(Items.MainItemSelectionStep);
		Return;
	EndIf;
	
	If Job.Status <> "Completed2" Then
		Brief1 = NStr("vi = 'Không thể thay thế các phần tử:';
						|ru = 'Не удалось заменить элементы:';
						|en = 'Failed to replace items:'; fa = 'Failed to replace items:';
						|it = 'Non è stato possibile sostituire gli elementi:';
						|pl = 'Nie udało się zastąpić elementów:';
						|tr = 'Öğeler değiştirilemedi:'") + Chars.LF + Job.BriefErrorDescription;
		More = Brief1 + Chars.LF + Chars.LF + Job.DetailErrorDescription;
		Items.ErrorTextLabel.Title = Brief1;
		Items.DetailsRef.ToolTip    = More;
		GoToWizardStep1(Items.ErrorOccurredStep);
		Activate();
		Return;
	EndIf;
	
	HasUnsuccessfulReplacements = FillUnsuccessfulReplacements(Job.ResultAddress);
	If HasUnsuccessfulReplacements Then
		GoToWizardStep1(Items.RetryMergeStep);
		Activate();
	Else
		ShowUserNotification(CompleteMessage(), GetURL(MainItem),
			String(MainItem), PictureLib.DialogInformation);
		NotifyOfSuccessfulReplacement(PlacesofUseInArray());
		Close();
	EndIf
	
EndProcedure

&AtClient
Function PlacesofUseInArray()
	Result = New Array();
	For Each Item In UsageInstances Do
		Result.Add(Item.Ref);
	EndDo;
	Return Result;
EndFunction

&AtServer
Procedure FillUsageInstances(Val ResultAddress)
	UsageTable = GetFromTempStorage(ResultAddress); // See Common.ReplaceReferences
	
	NewUsageInstances = UsageInstances.Unload();
	NewUsageInstances.Indexes.Add("Ref");
	
	IsUpdate = NewUsageInstances.Find(MainItem, "Ref") <> Undefined;
	If Not IsUpdate Then
		NewUsageInstances = UsageInstances.Unload(New Array);
		NewUsageInstances.Indexes.Add("Ref");
	EndIf;
	
	MetadataCache = New Map;
	
	MaxReference = Undefined;
	MaxInstances   = -1;
	DeletionMarks = Common.ObjectsAttributeValue(
		UsageTable.UnloadColumn("Ref"), "DeletionMark");
	For Each TableRow In UsageTable Do
		
		UsageRow = NewUsageInstances.Find(TableRow.Ref, "Ref");
		If UsageRow = Undefined Then
			UsageRow = NewUsageInstances.Add();
			UsageRow.Ref = TableRow.Ref;
		EndIf;
		
		Instances = TableRow.Occurrences;
		If Instances > MaxInstances And Not DeletionMarks[TableRow.Ref] Then
			MaxReference = TableRow.Ref;
			MaxInstances   = Instances;
		EndIf;
		
		UsageRow.UsageInstancesCount = Instances;
		UsageRow.Code      = ObjectCode(TableRow.Ref, MetadataCache);
		UsageRow.Owner = ObjectOfOwner(TableRow.Ref, MetadataCache);
		
		UsageRow.NotUsed = ?(Instances = 0, NStr("vi = 'Không sử dụng ';
												|ru = 'Не используется';
												|en = 'Not applicable'; fa = 'Not applicable';
												|it = 'Non viene utilizzato';
												|pl = 'Nie używane';
												|tr = 'Kullanılmaz'"), "");
	EndDo;
	
	UsageInstances.Load(NewUsageInstances);
	
	If MaxReference <> Undefined Then
		MainItem = MaxReference;
	EndIf;
	
	// Refresh headers.
	Presentation = ?(MainItem = Undefined, "", MainItem.Metadata().Presentation());
	Title = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = 'Hợp nhất các phần tử %1 thành một';
																			|ru = 'Объединение элементов %1 в один';
																			|en = 'Merge %1 items into one item'; fa = 'Merge %1 items into one item';
																			|it = 'Unificazione degli elementi %1 in uno';
																			|pl = 'Łączenie elementów %1 w jeden';
																			|tr = 'Öğeleri tek bir öğeye birleştirme %1'"), Presentation);
EndProcedure

&AtServer
Function FillUnsuccessfulReplacements(Val ResultAddress)
	ReplacementResults = GetFromTempStorage(ResultAddress); // See Common.ReplaceReferences
	
	RootRows = UnsuccessfulReplacements.GetItems();
	RootRows.Clear();
	
	RowsMap = New Map;
	MetadataCache     = New Map;
	
	For Each ResultString1 In ReplacementResults Do
		Ref = ResultString1.Ref;
		
		ErrorsByReference = RowsMap[Ref];
		If ErrorsByReference = Undefined Then
			TreeRow = RootRows.Add();
			TreeRow.Ref = Ref;
			TreeRow.Data = String(Ref);
			TreeRow.Code    = String( ObjectCode(Ref, MetadataCache) );
			TreeRow.Pictogram = -1;
			
			ErrorsByReference = TreeRow.GetItems();
			RowsMap.Insert(Ref, ErrorsByReference);
		EndIf;
		
		ErrorString = ErrorsByReference.Add();
		ErrorString.Ref = ResultString1.ErrorObject;
		ErrorString.Data = ResultString1.ErrorObjectPresentation;
		
		ErrorType = ResultString1.ErrorType;
		If ErrorType = "UnknownData" Then
			ErrorString.Cause = NStr("vi = 'Đã tìm thấy các nơi sử dụng mà không có dự tính thay thế.';
									|ru = 'Обнаружены места использования, замена в которых не планировалась.';
									|en = 'Found instances whose replacement wasn''t intended.'; fa = 'Found instances whose replacement wasn''t intended.';
									|it = 'Обнаружены места использования, замена в которых не планировалась.';
									|pl = 'Found instances whose replacement wasn''t intended.';
									|tr = 'Değiştirmenin planlanmadığı kullanım yerleri keşfedildi.'");
			
		ElsIf ErrorType = "LockError" Then
			ErrorString.Cause = NStr("vi = 'Đã thay đổi dữ liệu trong các phiên làm việc khác, hãy thử lại thay thế.';
									|ru = 'Данные изменены в другом сеансе, повторите попытку замены.';
									|en = 'Another user updated some data. Retry replacement.'; fa = 'Another user updated some data. Retry replacement.';
									|it = 'Данные изменены в другом сеансе, повторите попытку замены.';
									|pl = 'Another user updated some data. Retry replacement.';
									|tr = 'Veriler başka bir oturumda değiştirildi, değiştirmeyi tekrar deneyin.'");
			
		ElsIf ErrorType = "DataChanged1" Then
			ErrorString.Cause = NStr("vi = 'Đã thay thế dữ liệu trong phiên làm việc khác.';
									|ru = 'Данные изменены в другом сеансе.';
									|en = 'Another user updated some data.'; fa = 'Another user updated some data.';
									|it = 'Данные изменены в другом сеансе.';
									|pl = 'Another user updated some data.';
									|tr = 'Veriler başka bir oturumda değiştirildi.'");
			
		ElsIf ErrorType = "WritingError" Then
			ErrorString.Cause = ?(ResultString1.ErrorInfo <> Undefined,
				ErrorProcessing.ErrorMessageForUser(ResultString1.ErrorInfo),
				ResultString1.ErrorText);
			
		ElsIf ErrorType = "DeletionError" Then
			ErrorString.Cause = NStr("vi = 'Không thể xóa dữ liệu.';
									|ru = 'Невозможно удалить данные.';
									|en = 'Cannot delete data.'; fa = 'Cannot delete data.';
									|it = 'Impossibile eliminare i dati.';
									|pl = 'Nie można usunąć dane.';
									|tr = 'Veriler si̇li̇nemi̇yor.'");
			
		Else
			ErrorString.Cause = NStr("vi = 'Tình huống bất thường.';
									|ru = 'Непредвиденная ситуация.';
									|en = 'Unexpected error.'; fa = 'Unexpected error.';
									|it = 'Непредвиденная ситуация.';
									|pl = 'Unexpected error.';
									|tr = 'Beklenmedik durum.'");
			
		EndIf;
		
		ErrorString.ErrorInfo = ResultString1.ErrorInfo;
		ErrorString.DetailedReason = ?(ResultString1.ErrorInfo <> Undefined,
			ErrorProcessing.ErrorMessageForUser(ResultString1.ErrorInfo),
			ResultString1.ErrorText);
	EndDo;
	
	Return RootRows.Count() > 0;
EndFunction

&AtClient
Procedure AfterConfirmCancelJob(Response, ExecutionParameters) Export
	If Response = DialogReturnCode.Abort Then
		WizardSettings.ShowDialogBeforeClose = False;
		Close();
	EndIf;
EndProcedure

#EndRegion

#Region WizardUtilityProceduresAndFunctions

// Description of wizard button settings.
//
// Returns:
//  Structure - Form's button settings, where:
//    * Title         - String - a button title.
//    * ToolTip         - String - button tooltip.
//    * Visible         - Boolean - if True, the button is visible. The default value is True.
//    * Enabled       - Boolean - if True, the button is clickable. The default value is True.
//    * DefaultButton - Boolean - if True, the button is the main button of the form. Default value is False.
//    * ExtendedTooltip - Structure:
//    ** Title - String
//
&AtClientAtServerNoContext
Function WizardButton()
	Result = New Structure;
	Result.Insert("Title", "");
	Result.Insert("ToolTip", "");
	
	Result.Insert("Enabled", True);
	Result.Insert("Visible", True);
	Result.Insert("DefaultButton", False);
	
	Return Result;
EndFunction

// Parameters:
//  WizardButton - See WizardButton
//  LongDesc - String
//
&AtClientAtServerNoContext
Procedure UpdateWizardButtonProperties(WizardButton, LongDesc)
	
	FillPropertyValues(WizardButton, LongDesc);
	WizardButton.ExtendedTooltip.Title = LongDesc.ToolTip;
	
EndProcedure

#EndRegion

#EndRegion