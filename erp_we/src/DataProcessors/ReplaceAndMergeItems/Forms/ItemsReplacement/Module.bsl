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
//  RefSet - Array, ValueList - Items to be replaced with another Ref-type item.
//

#Region Variables

&AtClient
Var ReportsToSend; // Array of ErrorReport 

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.OpenByScenario Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	InitializeReferencesToReplace(RefArrayFromList(Parameters.RefSet));
	
	HasRightToDeletePermanently = AccessRight("DataAdministration", Metadata);
	ReplacementNotificationEvent        = DataProcessors.ReplaceAndMergeItems.ReplacementNotificationEvent();
	CurrentDeletionOption          = "Check";
	
	// Initializing a dynamic list on the form - selection form imitation.
	BasicMetadata = ReplacementItem.Metadata();
	List.CustomQuery = False;
	
	DynamicListParameters = Common.DynamicListPropertiesStructure();
	DynamicListParameters.MainTable = BasicMetadata.FullName();
	DynamicListParameters.DynamicDataRead = True;
	Common.SetDynamicListProperties(Items.List, DynamicListParameters);
	
	Items.List.ChangeRowOrder = False;
	Items.List.ChangeRowSet  = False;
	
	ItemsToReplaceList = New ValueList;
	ItemsToReplaceList.LoadValues(RefsToReplace.Unload().UnloadColumn("Ref"));
	CommonClientServer.SetDynamicListFilterItem(List, "Ref", ItemsToReplaceList,
		DataCompositionComparisonType.NotInList, NStr("vi = 'Không hiển thị phần tử được thay thế';
														|ru = 'Не показывать заменяемые';
														|en = 'Do not show replaceable items'; fa = 'Do not show replaceable items';
														|it = 'Non visualizzare sostituibili';
														|pl = 'Nie pokazuj wymienne';
														|tr = 'Değiştirileni gösterme'"), True, 
		DataCompositionSettingsItemViewMode.Inaccessible, "5bf5cd06-c1fd-4bd3-94b9-4e9803e90fd5");
	If ReferencesToReplaceCommonOwner <> Undefined Then 
		CommonClientServer.SetDynamicListFilterItem(List, "Owner", ReferencesToReplaceCommonOwner);
		Items.ListFilterTooltip.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Trong danh sách hiển thị các phương án phù hợp có bộ lọc: %2 = %3.';
				|ru = 'В списке показаны подходящие варианты с отбором: %2 = %3.';
				|en = 'The list contains suitable options with the filter: %2 = %3.'; fa = 'The list contains suitable options with the filter: %2 = %3.';
				|it = 'В списке показаны подходящие варианты с отбором: %2 = %3.';
				|pl = 'The list contains suitable options with the filter: %2 = %3.';
				|tr = 'Listede uygun filtreli seçenekler gösterildi: %2 = %3.'"),
			Common.ListPresentation(BasicMetadata),
			OwnerPresentation(BasicMetadata),
			Common.SubjectString(ReferencesToReplaceCommonOwner));
	Else
		Items.ListFilterTooltip.Visible = False;
	EndIf;
	
	If RefsToReplace.Count() > 1 Then
		Items.SelectedItemTypeLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hãy chọn một trong các phần tử ""%1"" mà các giá trị đã chọn (%2) cần thay thế:';
				|ru = 'Выберите один из элементов ""%1"", на который следует заменить выбранные значения (%2):';
				|en = 'Select one of the %1 items. The item will replace all %2 selected values:'; fa = 'Select one of the %1 items. The item will replace all %2 selected values:';
				|it = 'Selezionate uno degli elementi ""%1"", sul quale bisogna sostituire i valori selezionati (%2):';
				|pl = 'Wybierz jeden z elementów ""%1"", na który należy wymienić wybrane wartości (%2):';
				|tr = 'Seçilen değerlerin (%1) değiştirilmesi gereken ""%2"" öğelerinden birini seçin:'"),
			BasicMetadata.Presentation(), RefsToReplace.Count());
	Else
		Title = NStr("vi = 'Thay thế phần tử';
					|ru = 'Замена элемента';
					|en = 'Item replacement'; fa = 'جایگزینی قلم';
					|it = 'Sostituzione dell''elemento';
					|pl = 'Wymiana elementu';
					|tr = 'Öğe değiştirme'");
		Items.SelectedItemTypeLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Hãy chọn một trong các phần tử ""%1"" mà cần thay thế ""%2"":';
				|ru = 'Выберите один из элементов ""%1"", на который следует заменить ""%2"":';
				|en = 'Select one of the %1 items. The item will replace %2:'; fa = 'Select one of the %1 items. The item will replace %2:';
				|it = 'Selezionate uno degli elementi ""%1"", su quale bisogna sostituire  ""%2 "":';
				|pl = 'Wybierz jeden z elementów ""%1"",  na który należy wymienić ""%2"":';
				|tr = 'Aşağıdaki ile değiştirilmesi gereken ""%1"" öğelerden ""%2"" birini seçin:'"),
			BasicMetadata.Presentation(), RefsToReplace[0].Ref);
	EndIf;
	Items.ReplacementItemSelectionTooltip.Title = NStr("vi = 'Chưa chọn phần tử để thay thế.';
														|ru = 'Элемент для замены не выбран.';
														|en = 'Replacement item required.'; fa = 'Replacement item required.';
														|it = 'Elemento per la sostituzione non è stato selezionato.';
														|pl = 'Element do wymiany nie został wybrany.';
														|tr = 'Yedek öğe seçilmemiş.'");
	
	// Initialize the step-by-step wizard.
	WizardSettings = StepByStepWizardSettings(Items);
	
	// 1. Select main item.
	StepSelect = AddWizardStep(Items.ReplacementItemSelectionStep);
	StepSelect.BackButton.Visible = False;
	StepSelect.NextButton.Title = NStr("vi = 'Thay thế >';
										|ru = 'Заменить >';
										|en = 'Replace >'; fa = 'Replace >';
										|it = 'Sostituire>';
										|pl = 'Wymienić >';
										|tr = 'Değiştir >'");
	StepSelect.NextButton.ToolTip = NStr("vi = 'Bắt đầu thay thế phần tử';
										|ru = 'Начать замену элементов';
										|en = 'Start replacement.'; fa = 'Start replacement.';
										|it = 'Iniziare la sostituzione degli elementi';
										|pl = 'Rozpocząć wymianę elementów';
										|tr = 'Öğeleri değiştirmeye başla'");
	StepSelect.CancelButton.Title = NStr("vi = 'Hủy bỏ';
										|ru = 'Отмена';
										|en = 'Cancel'; fa = 'انصراف';
										|it = 'Annulla';
										|pl = 'Cancel';
										|tr = 'İptal'");
	StepSelect.CancelButton.ToolTip = NStr("vi = 'Từ chối thay thế phần tử';
											|ru = 'Отказаться от замены элементов';
											|en = 'Cancel replacement.'; fa = 'Cancel replacement.';
											|it = 'Rifiutare la sostituzione degli elementi';
											|pl = 'Zrezygnować z wymiany elementów';
											|tr = 'Öğeleri değiştirmeyi reddet'");
	
	// 2. Waiting for process.
	Step = AddWizardStep(Items.ReplacementStep);
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
	
	// 3. Reference replacement issues.
	Step = AddWizardStep(Items.RetryReplacementStep);
	Step.BackButton.Title = NStr("vi = '< Quay lại';
								|ru = '< Назад';
								|en = '< Back'; fa = '< بازگشت';
								|it = '< Indietro';
								|pl = '< Wróć';
								|tr = '< Geri'");
	Step.BackButton.ToolTip = NStr("vi = 'Quay lại chọn phần tử mục tiêu';
									|ru = 'Вернуться к выбору целевого элемента';
									|en = 'Return to selecting replacement item'; fa = 'Return to selecting replacement item';
									|it = 'Return to selecting replacement item';
									|pl = 'Return to selecting replacement item';
									|tr = 'Öğe zinciri seçimine döndürür'");
	Step.NextButton.Title = NStr("vi = 'Thay thế lại >';
								|ru = 'Повторить замену >';
								|en = 'Replace again >'; fa = 'Replace again >';
								|it = 'Ripetere la sostituzione >';
								|pl = 'Powtórzyć wymianę >';
								|tr = 'Değiştirmeyi tekrarla >'");
	Step.NextButton.ToolTip = NStr("vi = 'Thay thế lại phần tử';
									|ru = 'Повторить замену элементов';
									|en = 'Replace again.'; fa = 'Replace again.';
									|it = 'Ripetere la sostituzione degli elementi';
									|pl = 'Powtórzyć wymianę elementów';
									|tr = 'Öğe değişimini tekrarla'");
	Step.CancelButton.Title = NStr("vi = 'Đóng';
									|ru = 'Закрыть';
									|en = 'Close'; fa = 'بستن';
									|it = 'Chiudere';
									|pl = 'Close';
									|tr = 'Kapat'");
	Step.CancelButton.ToolTip = NStr("vi = 'Đóng biểu mẫu thay thế phần tử';
									|ru = 'Закрыть результаты замены элементов';
									|en = 'Close replacement results.'; fa = 'Close replacement results.';
									|it = 'Chiudere i risultati della sostituzione degli elementi';
									|pl = 'Zamknij wyniki wymiany elementów';
									|tr = 'Öğe değiştirmenin sonuçlarını kapatın'");
	
	// 4 Runtime errors.
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
	WizardSettings.CurrentStep = StepSelect;
	SetVisibilityAvailability(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	OnActivateWizardStep();
	ReportsToSend = New Map;
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.WizardSteps.CurrentPage <> Items.ReplacementStep
		Or Not WizardSettings.ShowDialogBeforeClose Then
		Return;
	EndIf;
	
	Cancel = True;
	If Exit Then
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Ngừng thay thế phần tử và đóng biểu mẫu?';
					|ru = 'Прервать замену элементов и закрыть форму?';
					|en = 'Do you want to abort replacing and close the form?'; fa = 'Do you want to abort replacing and close the form?';
					|it = 'Interrompere la sostituzione degli elementi e chiudere la forma?';
					|pl = 'Przerwać wymianę elementów i zamknąć formularz?';
					|tr = 'Öğe değiştirme iptal edilsin ve form kapatılsın mı?'");
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Abort, NStr("vi = 'Ngừng';
											|ru = 'Прервать';
											|en = 'Abort'; fa = 'توقف';
											|it = 'Interrompere';
											|pl = 'Abort';
											|tr = 'Durdur'"));
	Buttons.Add(DialogReturnCode.No,      NStr("vi = 'Không ngắt';
												|ru = 'Не прерывать';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Non interrompere';
												|pl = 'Nie przerywać';
												|tr = 'İptal etmemek'"));
	
	Handler = New CallbackDescription("AfterConfirmCancelJob", ThisObject);
	ShowQueryBox(Handler, QueryText, Buttons, , DialogReturnCode.No);
	
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
Procedure ReplacementItemSelectionTooltipURLProcessing(Item, Ref, StandardProcessing)
	
	StandardProcessing = False;
	
	If Ref = "SwitchDeletionMode" Then
		If CurrentDeletionOption = "Directly" Then
			CurrentDeletionOption = "Check" 
		Else
			CurrentDeletionOption = "Directly" 
		EndIf;
		
		GenerateReplacementItemAndTooltip(ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure DetailsRefClick(Item)
	StandardSubsystemsClient.ShowDetailedInfo(Undefined, Item.ToolTip);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("GenerateReplacementItemAndTooltipDeferred", 0.01, True);
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	StandardProcessing = False;
	StepReplacementItemSelectionOnClickNextButton();
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

// Initializes wizard structures.
// 
// Parameters:
//   Items - FormItems 
// 
// Returns:
//   Structure - Describes wizard settings.
//     Public wizard settings are:
//       * Steps - Array - description of wizard steps. Read only.
//           To add steps, use the AddWizardStep function.
//       * CurrentStep - See AddWizardStep.
//       * ShowDialogBeforeClose - Boolean - if True, a warning will be displayed before closing the form.
//           For changing.
//     Internal wizard settings:
//       * PagesGroup - String - a form item name that is passed to the PageGroup parameter.
//       * NextButton - String - a form item name that is passed to the NextButton parameter.
//       * BackButton - String - a form item name that is passed to the BackButton parameter.
//       * CancelButton - String - a form item name that is passed to the CancelButton parameter.
//
&AtServerNoContext
Function StepByStepWizardSettings(Items)
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
	
	Return WizardSettings;
EndFunction

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
//           ** Visible - Boolean - if True, the button is visible. Default value is True.
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
	
	If CurrentPage = Items.ReplacementItemSelectionStep Then
		
		GenerateReplacementItemAndTooltip(ThisObject);
		
	ElsIf CurrentPage = Items.ReplacementStep Then
		
		WizardSettings.ShowDialogBeforeClose = True;
		ReplacementItemResult = ReplacementItem; // Save start parameters.
		StartReplacingLinks();
		
	ElsIf CurrentPage = Items.RetryReplacementStep Then
		
		// Update number of failures.
		Unsuccessful = New Map;
		For Each Item In UnsuccessfulReplacements.GetItems() Do
			Unsuccessful.Insert(Item.Ref, True);
		EndDo;
		
		ReplacementsCount = RefsToReplace.Count();
		If ReplacementsCount > 1 Then 
			Items.UnsuccessfulReplacementsResult.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thay thế các mục (%1 từ %2). Ở một số nơi sử dụng, sẽ thay thế tự động bằng ""%3"":';
					|ru = 'Не удалось заменить элементы (%1 из %2). В некоторых местах использования не может быть произведена автоматическая замена на ""%3"":';
					|en = 'Cannot automatically replace some items to ""%3"". %1 out of %2 items were not replaced.'; fa = 'Cannot automatically replace some items to ""%3"". %1 out of %2 items were not replaced.';
					|it = 'Не удалось заменить элементы (%1 из %2). В некоторых местах использования не может быть произведена автоматическая замена на ""%3"":';
					|pl = 'Cannot automatically replace some items to ""%3"". %1 out of %2 items were not replaced.';
					|tr = 'Öğeler değiştirilemedi (%1/%2). Bazı kullanım yerlerinde ""%3"" ile otomatik değiştirme gerçekleşmeyebilir:'"),
				Unsuccessful.Count(),
				ReplacementsCount,
				ReplacementItem);
		Else
			Items.UnsuccessfulReplacementsResult.Title = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Không thể thay thế các mục. Ở một số nơi sử dụng, sẽ thay thế tự động bằng ""%1"":';
					|ru = 'Не удалось заменить элементы. В некоторых местах использования не может быть произведена автоматическая замена на ""%1"":';
					|en = 'Cannot automatically replace some items to ""%1"". Some items were not replaced.'; fa = 'Cannot automatically replace some items to ""%1"". Some items were not replaced.';
					|it = 'Не удалось заменить элементы. В некоторых местах использования не может быть произведена автоматическая замена на ""%1"":';
					|pl = 'Cannot automatically replace some items to ""%1"". Some items were not replaced.';
					|tr = 'Öğeler değiştirilemiyor ""%1"". Bazı kullanım yerlerinde, otomatik bir değiştirme işlemi yapılamaz.'"),
				ReplacementItem);
		EndIf;
		
		// Generating a list of successful replacements and clearing a list of items to replace.
		UpdatedItemsList = New Array;
		UpdatedItemsList.Add(ReplacementItem);
		For Number = 1 To ReplacementsCount Do
			ReverseIndex = ReplacementsCount - Number;
			Ref = RefsToReplace[ReverseIndex].Ref;
			If Ref <> ReplacementItem And Unsuccessful[Ref] = Undefined Then
				RefsToReplace.Delete(ReverseIndex);
				UpdatedItemsList.Add(Ref);
			EndIf;
		EndDo;
		
		// Notification of completed replacements.
		NotifyOfSuccessfulReplacement(UpdatedItemsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepNext()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.ReplacementItemSelectionStep Then
		StepReplacementItemSelectionOnClickNextButton();
	ElsIf CurrentPage = Items.RetryReplacementStep Then
		GoToWizardStep1(Items.ReplacementStep);
	Else
		CurrentStep = WizardSettings.CurrentStep; // See AddWizardStep
		GoToWizardStep1(CurrentStep.IndexOf + 1);
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepBack()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.RetryReplacementStep Then
		GoToWizardStep1(Items.ReplacementItemSelectionStep);
	Else
		Step = WizardSettings.CurrentStep; // See AddWizardStep
		GoToWizardStep1(Step.IndexOf - 1);
	EndIf;
	
EndProcedure

&AtClient
Procedure WizardStepCancel()
	
	CurrentPage = Items.WizardSteps.CurrentPage;
	If CurrentPage = Items.ReplacementStep Then
		WizardSettings.ShowDialogBeforeClose = False;
	EndIf;
	
	If IsOpen() Then
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region UtilityProceduresForReplaceAndMerge

&AtClient
Procedure StepReplacementItemSelectionOnClickNextButton()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf RefsToReplace.Count() = 1 And CurrentData.Ref = RefsToReplace.Get(0).Ref Then
		ShowMessageBox(, NStr("vi = 'Không thể thay thế phần tử thành chính phần tử đó.';
								|ru = 'Нельзя заменять элемент сам на себя.';
								|en = 'Cannot replace an item with itself.'; fa = 'Cannot replace an item with itself.';
								|it = 'Impossibile sostituire l''elemento su se stesso.';
								|pl = 'Nie wolno zmieniać element na samego siebie.';
								|tr = 'Bir öğe kendi ile değiştirilemez.'"));
		Return;
	ElsIf AttributeValue(CurrentData, "IsFolder", False) Then
		ShowMessageBox(, NStr("vi = 'Không thể thay thế phần tử thành nhóm.';
								|ru = 'Нельзя заменять элемент на группу.';
								|en = 'Cannot replace an item with a group.'; fa = 'Cannot replace an item with a group.';
								|it = 'Impossibile sostituire l''elemento per gruppo.';
								|pl = 'Nie można wymienić element na grupę.';
								|tr = 'Öğe grupla değiştirilemiyor.'"));
		Return;
	EndIf;
	
	CurrentOwner = AttributeValue(CurrentData, "Owner");
	If CurrentOwner <> ReferencesToReplaceCommonOwner Then
		Text = NStr("vi = 'Không thể thay thế bằng một mục cấp dưới của một chủ sở hữu khác.
			|Mục đã chọn có chủ sở hữu ""%1"", và thay thế - ""%2"".';
			|ru = 'Нельзя заменять на элемент, подчиненный другому владельцу.
			|У выбранного элемента владелец ""%1"", а у заменяемого - ""%2"".';
			|en = 'Cannot replace an item with the item that belongs to another owner.
			|Owner of the selected item:%1. Owner of the replacement item: %2.'; fa = 'Cannot replace an item with the item that belongs to another owner.
			|Owner of the selected item:%1. Owner of the replacement item: %2.';
			|it = 'Non è possibile sostituire all''elemento, subordinato ad un altro proprietario. 
			| L''elemento selezionato ha il proprietario ""%1"" quello da sostituire ha - ""%2"".';
			|pl = 'Nie można wymieniać na element podporządkowany innemu właścicielowi.
			|U wybranego elementu właściciel ""%1"", a u wymienianego - ""%2"".';
			|tr = 'Başka bir kullanıcıya bağlı nesneyle değiştirilemez. 
			|Seçilen öğenin ""%1"" sahibi, değiştirilen öğenin ""%2"" vardır.'");
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(Text, CurrentOwner, ReferencesToReplaceCommonOwner));
		Return;
	EndIf;
	
	If AttributeValue(CurrentData, "DeletionMark", False) Then
		// Attempt to replace with an item marked for deletion.
		Text = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đánh dấu xóa phần tử %1. Tiếp tục?';
				|ru = 'Элемент %1 помечен на удаление. Продолжить?';
				|en = 'Item %1 is marked for deletion. Continue?'; fa = 'Item %1 is marked for deletion. Continue?';
				|it = 'Elemento %1 è contrassegnato per l''eliminazione. Continuare?';
				|pl = 'Element %1 jest zaznaczony do usunięcia. Kontynuować?';
				|tr = 'Öğe %1 silinmek üzere işaretlenmiştir. Devam edilsin mi?'"),
			CurrentData.Ref);
		LongDesc = New CallbackDescription("ConfirmItemSelection", ThisObject);
		ShowQueryBox(LongDesc, Text, QuestionDialogMode.YesNo);
	Else
		// Additional check for applied data is required.
		AppliedAreaReplacementAvailabilityCheck();
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyOfSuccessfulReplacement(Val DataList)
	CommonClient.NotifyObjectsChanged(DataList);
EndProcedure

&AtClient
Procedure GenerateReplacementItemAndTooltipDeferred()
	GenerateReplacementItemAndTooltip(ThisObject);
EndProcedure

&AtClient
Procedure ConfirmItemSelection(Val QuestionResult, Val AdditionalParameters) Export
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	// Additional check by applied data.
	AppliedAreaReplacementAvailabilityCheck();
EndProcedure

&AtClient
Procedure AppliedAreaReplacementAvailabilityCheck()
	// Validate item replacement against application logic.
	ErrorText = CheckCanReplaceReferences();
	If Not IsBlankString(ErrorText) Then
		DialogSettings = New Structure;
		DialogSettings.Insert("PromptDontAskAgain", False);
		DialogSettings.Insert("Picture", PictureLib.DialogExclamation);
		DialogSettings.Insert("DefaultButton", 0);
		DialogSettings.Insert("Title", NStr("vi = 'Không thể thay thế phần tử';
											|ru = 'Невозможно заменить элементы';
											|en = 'Cannot replace items'; fa = 'Cannot replace items';
											|it = 'Impossibile sostituire gli elementi';
											|pl = 'Nie można wymienić elementy';
											|tr = 'Öğeler değiştirilemez'"));
		
		Buttons = New ValueList;
		Buttons.Add(0, NStr("vi = 'Đồng ý';
							|ru = 'ОК';
							|en = 'OK'; fa = 'تأیید';
							|it = 'OK';
							|pl = 'OK';
							|tr = 'Tamam'"));
		
		StandardSubsystemsClient.ShowQuestionToUser(Undefined, ErrorText, Buttons, DialogSettings);
		Return;
	EndIf;
	
	Step = WizardSettings.CurrentStep;// See AddWizardStep
	GoToWizardStep1(Step.IndexOf + 1);
EndProcedure

&AtClient
Procedure GenerateReplacementItemAndTooltip(Context)
	
	CurrentData = Context.Items.List.CurrentData;
	If CurrentData = Undefined Or AttributeValue(CurrentData, "IsFolder", False) Then
		Return;
	EndIf;
	Context.ReplacementItem = CurrentData.Ref;
	
	Count = Context.RefsToReplace.Count();
	If Count = 1 Then
		
		If Context.HasRightToDeletePermanently Then
			If Context.CurrentDeletionOption = "Check" Then
				ToolTipText = NStr("vi = 'Phần tử đã chọn sẽ được thay thế bởi ""[ReplacementItem]""
					|và <a href = ""[Hyperlink]"">bị đặt dấu xóa</a>.';
					|ru = 'Выбранный элемент будет заменен на ""[ReplacementItem]""
					|и <a href = ""[Hyperlink]"">помечен на удаление</a>.';
					|en = 'The selected item will be replaced with ""[ReplacementItem]""
					|and <a href = ""[Hyperlink]"">marked for deletion</a>.'; fa = 'The selected item will be replaced with ""[ReplacementItem]""
					|and <a href = ""[Hyperlink]"">marked for deletion</a>.';
					|it = 'Выбранный элемент будет заменен на ""[ReplacementItem]""
					|и <a href = ""[Hyperlink]"">помечен на удаление</a>.';
					|pl = 'The selected item will be replaced with ""[ReplacementItem]""
					|and <a href = ""[Hyperlink]"">marked for deletion</a>.';
					|tr = 'Seçilen öğe ""[ReplacementItem]""
					| ile değiştirilecek ve <a href = ""[Hyperlink]"">silinmek üzere işaretlenmiştir</a>.'");
			Else
				ToolTipText = NStr("vi = 'Phần tử đã chọn sẽ được thay thế bởi ""[ReplacementItem]""
					|và <a href = ""[Hyperlink]"">bị xóa vĩnh viễn</a>.';
					|ru = 'Выбранный элемент будет заменен на ""[ReplacementItem]""
					|и <a href = ""[Hyperlink]"">удален безвозвратно</a>.';
					|en = 'The selected item will be replaced with ""[ReplacementItem]""
					|and <a href = ""[Hyperlink]"">permanently deleted</a>.'; fa = 'The selected item will be replaced with ""[ReplacementItem]""
					|and <a href = ""[Hyperlink]"">permanently deleted</a>.';
					|it = 'Выбранный элемент будет заменен на ""[ReplacementItem]""
					|и <a href = ""[Hyperlink]"">удален безвозвратно</a>.';
					|pl = 'The selected item will be replaced with ""[ReplacementItem]""
					|and <a href = ""[Hyperlink]"">permanently deleted</a>.';
					|tr = 'Seçilen öğe ""[ReplacementItem]""
					| ile değiştirilecek ve <a href = ""[Hyperlink]"">kalıcı olarak silinecek</a>.'");
			EndIf;
		Else
			ToolTipText = NStr("vi = 'Phần tử đã chọn sẽ được thay thế bởi ""[ReplacementItem]""
				|và bị đặt dấu xóa.';
				|ru = 'Выбранный элемент будет заменен на ""[ReplacementItem]""
				|и помечен на удаление.';
				|en = 'The selected item will be replaced with ""[ReplacementItem]""
				|and marked for deletion.'; fa = 'The selected item will be replaced with ""[ReplacementItem]""
				|and marked for deletion.';
				|it = 'Elemento selezionato sarà sostituito al""[ReplacementItem]
				| e contrassegnato per l''eliminazione.';
				|pl = 'Wybrany element zostanie wymieniony na ""[ReplacementItem]""
				|i zaznaczony do usunięcia.';
				|tr = 'Seçilen öğe ""[ReplacementItem]""
				| ile değiştirilecek ve silinmek üzere işaretlenmiştir.'");
		EndIf;
		
		RowParameters = New Structure();
		RowParameters.Insert("ReplacementItem", Context.ReplacementItem);
		RowParameters.Insert("Hyperlink", "SwitchDeletionMode");
		
		ToolTipText = StringFunctionsClientServer.InsertParametersIntoString(ToolTipText, RowParameters);
		Context.Items.ReplacementItemSelectionTooltip.Title = StringFunctionsClient.FormattedString(ToolTipText);
		
	Else
		
		If Context.HasRightToDeletePermanently Then
			If Context.CurrentDeletionOption = "Check" Then
				ToolTipText = NStr("vi = 'Các phần tử được chọn (%1) sẽ bị thay thế bởi ""%2""
					|và <a href = ""[Action]"">bị đặt dấu xóa</a>.';
					|ru = 'Выбранные элементы (%1) будут заменены на ""%2""
					|и <a href = ""[Action]"">помечены на удаление</a>.';
					|en = 'Selected items (%1) will be replaced with ""%2""
					|and <a href = ""[Action]"">marked for deletion</a>.'; fa = 'Selected items (%1) will be replaced with ""%2""
					|and <a href = ""[Action]"">marked for deletion</a>.';
					|it = 'Выбранные элементы (%1) будут заменены на ""%2""
					|и <a href = ""[Action]"">помечены на удаление</a>.';
					|pl = 'Selected items (%1) will be replaced with ""%2""
					|and <a href = ""[Action]"">marked for deletion</a>.';
					|tr = 'Seçilen öğeler (%1) ""%2""
					| ile değiştirilecek ve <a href = ""[Action]"">silinmek üzere işaretlenecek</a>.'");
				RowParameters = New Structure("Action", "SwitchDeletionMode");
				ToolTipText = StringFunctionsClientServer.InsertParametersIntoString(ToolTipText, RowParameters);
			Else
				ToolTipText = NStr("vi = 'Các phần tử được chọn (%1) sẽ bị thay thế bởi ""%2""
					|và <a href = ""[Action]"">bị xóa vĩnh viễn</a>.';
					|ru = 'Выбранные элементы (%1) будут заменены на ""%2""
					|и <a href = ""[Action]"">удалены безвозвратно</a>.';
					|en = 'Selected items (%1) will be replaced with ""%2""
					|and <a href = ""[Action]"">permanently deleted</a>.'; fa = 'Selected items (%1) will be replaced with ""%2""
					|and <a href = ""[Action]"">permanently deleted</a>.';
					|it = 'Выбранные элементы (%1) будут заменены на ""%2""
					|и <a href = ""[Action]"">удалены безвозвратно</a>.';
					|pl = 'Selected items (%1) will be replaced with ""%2""
					|and <a href = ""[Action]"">permanently deleted</a>.';
					|tr = 'Seçilen öğeler (%1), ""%2""
					| ile değiştirilecek ve <a href = ""[Action]""> kalıcı olarak silinecek</a>.'");
				RowParameters = New Structure("Action", "SwitchDeletionMode");
				ToolTipText = StringFunctionsClientServer.InsertParametersIntoString(ToolTipText, RowParameters);
			EndIf;
		Else
			ToolTipText = NStr("vi = 'Các mục đã chọn (%1) sẽ được thay thế bằng ""%2""
				|và được đánh dấu để xóa.';
				|ru = 'Выбранные элементы (%1) будут заменены на ""%2""
				|и помечен на удаление.';
				|en = 'All %1 selected items will be replaced with %2
				|and marked for deletion.'; fa = 'All %1 selected items will be replaced with %2
				|and marked for deletion.';
				|it = 'Elementi selezionati (%1) saranno sostituiti al""%2""
				| e saranno contrassegnati per l''eliminazione.';
				|pl = 'Wybrane elementy (%1) zostaną wymienione na ""%2""
				|i zaznaczone do usunięcia.';
				|tr = 'Seçilen öğeler (%1), ""%2""
				| ile değiştirilecek ve silinmek üzere işaretlenmiştir.'");
		EndIf;
			
		ToolTipText = StringFunctionsClientServer.SubstituteParametersToString(ToolTipText, Count, Context.ReplacementItem);
		Context.Items.ReplacementItemSelectionTooltip.Title = StringFunctionsClient.FormattedString(ToolTipText);
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function OwnerPresentation(BasicMetadata)
	For Each Attribute In BasicMetadata.StandardAttributes Do
		If Attribute.Name = "Owner" Then
			Return Attribute.Synonym;	
		EndIf;
	EndDo;
	Return "";	
EndFunction

&AtClientAtServerNoContext
Function AttributeValue(Val Data, Val AttributeName, Val ValueIfNotFound = Undefined)
	// Gets an attribute value safely.
	Trial = New Structure(AttributeName);
	
	FillPropertyValues(Trial, Data);
	If Trial[AttributeName] <> Undefined Then
		// There is a value.
		Return Trial[AttributeName];
	EndIf;
	
	// Value in data might be set to Undefined.
	Trial[AttributeName] = True;
	FillPropertyValues(Trial, Data);
	If Trial[AttributeName] <> True Then
		Return Trial[AttributeName];
	EndIf;
	
	Return ValueIfNotFound;
EndFunction

&AtServer
Function CheckCanReplaceReferences()
	
	ReplacementPairs = New Map;
	For Each RefToReplace In RefsToReplace Do
		ReplacementPairs.Insert(RefToReplace.Ref, ReplacementItem);
	EndDo;
	
	ReplacementParameters = New Structure("DeletionMethod", CurrentDeletionOption);
	Return DuplicateObjectsDetection.CheckCanReplaceItemsString(ReplacementPairs, ReplacementParameters);
	
EndFunction

// Parameters:
//   References - ValueList of AnyRef
//          - Array of AnyRef
//          - ValueTable:
//        * Ref - AnyRef
// Returns:
//   Array
//
&AtServerNoContext
Function RefArrayFromList(Val References)
	// Converts an array, list of values, or collection to an array.
	
	ParameterType = TypeOf(References);
	If References = Undefined Then
		ReferencesArrray = New Array;
		
	ElsIf ParameterType  = Type("ValueList") Then
		ReferencesArrray = References.UnloadValues();
		
	ElsIf ParameterType = Type("Array") Then
		ReferencesArrray = References;
		
	Else
		ReferencesArrray = New Array;
		For Each Item In References Do
			ReferencesArrray.Add(Item.Ref);
		EndDo;
		
	EndIf;
	
	Return ReferencesArrray;
EndFunction

&AtServerNoContext
Function ObjectCode(Val Ref, MetadataCache)
	
	Meta = Ref.Metadata();
	HasCode = MetadataCache[Meta];
	
	If HasCode = Undefined Then
		// Checking whether the code exists.
		Test = New Structure("CodeLength", 0);
		FillPropertyValues(Test, Meta);
		HasCode = Test.CodeLength > 0;
		
		MetadataCache[Meta] = HasCode;
	EndIf;
	
	Return ?(HasCode, Common.ObjectAttributeValue(Ref, "Code"), Undefined);
EndFunction

&AtServer
Procedure InitializeReferencesToReplace(Val ReferencesArrray)
	
	RefsCount = ReferencesArrray.Count();
	If RefsCount = 0 Then
		Raise NStr("vi = 'Hãy chọn ít nhất một phần tử để thay thế.';
					|ru = 'Выберите хотя бы один элемент для замены.';
					|en = 'Select at least one item to replace.'; fa = 'Select at least one item to replace.';
					|it = 'Выберите хотя бы один элемент для замены.';
					|pl = 'Select at least one item to replace.';
					|tr = 'Yerini alacak bir öğe seçin.'");
	EndIf;
	
	ReplacementItem = ReferencesArrray[0];
	BasicMetadata = ReplacementItem.Metadata();
	VerifyAccessRights("Update", BasicMetadata);
	
	Characteristics = New Structure("Owners, Hierarchical, HierarchyType", New Array, False);
	FillPropertyValues(Characteristics, BasicMetadata);
	
	HasOwners = Characteristics.Owners.Count() > 0;
	HasGroups    = Characteristics.Hierarchical And Characteristics.HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems;
	
	QueryText =
		"SELECT
		|Ref AS Ref,
		|&Field_Owner AS Owner,
		|&IsFolder AS IsFolder
		|INTO RefsToReplace
		|FROM
		|	#TableName
		|WHERE
		|	Ref IN (&RefSet)
		|INDEX BY
		|	Owner,
		|	IsFolder
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	COUNT(DISTINCT Owner) AS OwnersCount,
		|	MIN(Owner)              AS CommonOwner,
		|	MAX(IsFolder)            AS HasGroups,
		|	COUNT(Ref)             AS RefsCount
		|FROM
		|	RefsToReplace
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED TOP 1
		|	DestinationTable2.Ref
		|FROM
		|	#TableName AS DestinationTable2
		|		LEFT JOIN RefsToReplace AS RefsToReplace
		|		ON DestinationTable2.Ref = RefsToReplace.Ref
		|WHERE
		|	RefsToReplace.Ref IS NULL
		|	AND &ConditionGroup
		|	AND &ConditionOwner";
	QueryText = StrReplace(QueryText, "#TableName", BasicMetadata.FullName());
	QueryText = StrReplace(QueryText, "&Field_Owner", ?(HasOwners, "Owner", "UNDEFINED"));
	QueryText = StrReplace(QueryText, "&IsFolder", ?(HasGroups, "IsFolder", "FALSE"));
	QueryText = StrReplace(QueryText, "&ConditionOwner", 
		?(HasOwners, "DestinationTable2.Owner = &Owner", "TRUE")); // @query-part-2
	QueryText = StrReplace(QueryText, "&ConditionGroup", 
		?(HasGroups, "NOT DestinationTable2.IsFolder", "TRUE")); // @query-part-2
		
	Query = New Query(QueryText);
	Query.SetParameter("RefSet", ReferencesArrray);
	If HasOwners Then
		Query.SetParameter("Owner", Common.ObjectAttributeValue(ReplacementItem, "Owner"));
	EndIf;
	
	Result = Query.ExecuteBatch();
	Conditions = Result[1].Unload()[0];
	If Conditions.HasGroups Then
		Raise NStr("vi = 'Một trong những mục đang được thay thế là nhóm.
			|Không thể thay thế các nhóm.';
			|ru = 'Один из заменяемых элементов является группой.
			|Группы не могут быть заменены.';
			|en = 'One of the items to replace is a group.
			|Groups cannot be replaced.'; fa = 'One of the items to replace is a group.
			|Groups cannot be replaced.';
			|it = 'Uno degli elementi sostituiti è un gruppo.
			| Gruppi non possono essere sostituiti.';
			|pl = 'Jeden z elementów do wymiany jest grupą.
			|Grupy nie mogą być wymieniane.';
			|tr = 'Birleştirilmiş öğelerden biri bir gruptur. 
			|Gruplar birleştirilemez.'");
	ElsIf Conditions.OwnersCount > 1 Then 
		Raise NStr("vi = 'Trong các phần tử được thay thế có đối tượng chủ khác nhau.
			|Không thể thay thế các phần tử này.';
			|ru = 'У заменяемых элементов разные владельцы.
			|Такие элементы не могут быть заменены.';
			|en = 'Items to replace have different owners.
			|They cannot be replaced.'; fa = 'Items to replace have different owners.
			|They cannot be replaced.';
			|it = 'Gli elementi sostituiti hanno diversi proprietari.
			|Tali elementi non possono essere sostituiti.';
			|pl = 'U wymienianych elementów są różne właściciele.
			|Takie elementy nie mogą być wymienione.';
			|tr = 'Değiştirilmiş öğelerin farklı sahipleri var. 
			|Bu tür maddeler birleştirilemez.'");
	ElsIf Conditions.RefsCount <> RefsCount Then
		Raise NStr("vi = 'Tất cả các phần tử được thay thế phải có cùng một kiểu.';
					|ru = 'Все заменяемые элементы должны быть одного типа.';
					|en = 'All items to replace must be of the same type.'; fa = 'All items to replace must be of the same type.';
					|it = 'Tutti gli elementi sostituiti devono essere dello stesso tipo.';
					|pl = 'Wszystkie wymieniane elementy muszą być tego samego rodzaju.';
					|tr = 'Tüm değiştirilebilir öğeler aynı tipte olmalıdır.'");
	EndIf;
	
	If Result[2].Unload().Count() = 0 Then
		If RefsCount > 1 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phần tử được chọn (%1) không thay thế gì, bởi vì không có phần tử phù hợp khác để thay thế.';
					|ru = 'Выбранные элементы (%1) не на что заменить, т.к. нет других подходящих элементов для замены.';
					|en = 'The selected items (%1) cannot be replaced as there are no suitable items for replacement.'; fa = 'The selected items (%1) cannot be replaced as there are no suitable items for replacement.';
					|it = 'Выбранные элементы (%1) не на что заменить, т.к. нет других подходящих элементов для замены.';
					|pl = 'The selected items (%1) cannot be replaced as there are no suitable items for replacement.';
					|tr = 'Seçilen öğeler (%1) bunun yerini alamaz, çünkü yerini almaya uygun başka öğe yok.'"), 
				RefsCount);
		Else
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phần tử được chọn ""%1"" không thay thế gì, bởi vì không có phần tử phù hợp khác để thay thế.';
					|ru = 'Выбранный элемент ""%1"" не на что заменить, т.к. нет других подходящих элементов для замены.';
					|en = 'The selected %1 item cannot be replaced as there are no suitable items for replacement.'; fa = 'The selected %1 item cannot be replaced as there are no suitable items for replacement.';
					|it = 'Выбранный элемент ""%1"" не на что заменить, т.к. нет других подходящих элементов для замены.';
					|pl = 'The selected %1 item cannot be replaced as there are no suitable items for replacement.';
					|tr = 'Seçilen öğeler ""%1"" bunun yerini alamaz, çünkü yerini almaya uygun başka öğe yok.'"), 
				Common.SubjectString(ReplacementItem));
		EndIf;
	EndIf;
	
	ReferencesToReplaceCommonOwner = ?(HasOwners, Conditions.CommonOwner, Undefined);
	For Each Item In ReferencesArrray Do
		RefsToReplace.Add().Ref = Item;
	EndDo;
	Items.List.Representation = ?(Conditions.HasGroups, TableRepresentation.HierarchicalList, TableRepresentation.List);
	
EndProcedure

#EndRegion

#Region TimeConsumingOperations1

&AtClient
Procedure StartReplacingLinks()
	
	ReportsToSend = New Map;
	
	MethodParameters = New Structure("ReplacementPairs, DeletionMethod");
	MethodParameters.ReplacementPairs = New Map;
	For Each RefToReplace In RefsToReplace Do
		MethodParameters.ReplacementPairs.Insert(RefToReplace.Ref, ReplacementItem);
	EndDo;
	MethodParameters.Insert("DeletionMethod", CurrentDeletionOption);
	
	Job = ReplaceReferences(MethodParameters, UUID);
	
	WaitSettings = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	WaitSettings.OutputIdleWindow = False;
	
	Handler = New CallbackDescription("AfterCompletionReplacingLinks", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(Job, Handler, WaitSettings);
	
EndProcedure

&AtServerNoContext
Function ReplaceReferences(Val MethodParameters, Val UUID)
	
	MethodDescription = NStr("vi = 'Tìm kiếm và xóa phần tử trùng lặp: Thay thế liên kết';
							|ru = 'Поиск и удаление дублей: Замена ссылок';
							|en = 'Duplicate cleaner: Replace references'; fa = 'Duplicate cleaner: Replace references';
							|it = 'Ricerca e eliminazione di doppi: Sostituzione dei link';
							|pl = 'Wyszukiwanie i usuwanie duplikatów: Wymiana linków';
							|tr = 'Kopya Temizleyici: Bağlantı değişimi'");
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = MethodDescription;
	
	Return TimeConsumingOperations.ExecuteInBackground("DuplicateObjectsDetection.ReplaceReferences",
		MethodParameters, StartSettings1);
	
EndFunction

&AtClient
Procedure AfterCompletionReplacingLinks(Job, AdditionalParameters) Export
	
	WizardSettings.ShowDialogBeforeClose = False;
	If Job = Undefined 
		Or Items.WizardSteps.CurrentPage = Items.ReplacementItemSelectionStep Then
		Return;
	EndIf;
	
	If Job.Status <> "Completed2" Then
		// Background job is completed with error.
		Brief1 = NStr("vi = 'Chưa thay thế phần tử do nguyên nhân:';
						|ru = 'Не выполнена замена элементов по причине:';
						|en = 'Items were not replaced due to:'; fa = 'Items were not replaced due to:';
						|it = 'Не выполнена замена элементов по причине:';
						|pl = 'Items were not replaced due to:';
						|tr = 'Öğenin yerine şu sebeple başka öğe getirilemedi:'") + Chars.LF + Job.BriefErrorDescription;
		More = Brief1 + Chars.LF + Chars.LF + Job.DetailErrorDescription;
		Items.ErrorTextLabel.Title = Brief1;
		Items.DetailsRef.ToolTip    = More;
		GoToWizardStep1(Items.ErrorOccurredStep);
		Activate();
		Return;
	EndIf;
	
	HasUnsuccessfulReplacements = FillUnsuccessfulReplacements(Job.ResultAddress);
	If HasUnsuccessfulReplacements Then
		// Partially successful: display the details.
		GoToWizardStep1(Items.RetryReplacementStep);
		Activate();
	Else
		// Completely successful: display the notification and close the form.
		Count = RefsToReplace.Count();
		If Count = 1 Then
			ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Phần tử ""%1""được thay thế bằng ""%2""';
					|ru = 'Элемент ""%1"" заменен на ""%2""';
					|en = 'Item %1 has been replaced with %2.'; fa = 'Item %1 has been replaced with %2.';
					|it = 'Elemento ""%1""  sostituito per ""%2""';
					|pl = 'Element ""%1"" został wymieniony na ""%2""';
					|tr = 'Öğe ""%1"" ""%2"" ile değiştirilecek'"),
				RefsToReplace[0].Ref,
				ReplacementItemResult);
		Else
			ResultingText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Các phần tử (%1) được thay thế bằng ""%2""';
					|ru = 'Элементы (%1) заменены на ""%2""';
					|en = '%1 items have been replaced with %2.'; fa = '%1 items have been replaced with %2.';
					|it = 'Elementi (%1) sostituiti per ""%2""';
					|pl = 'Elementy (%1) zostały wymienione na ""%2""';
					|tr = 'Öğeler (%1) ""%2"" ile değiştirilecek'"),
				Count,
				ReplacementItemResult);
		EndIf;
		ShowUserNotification(, GetURL(ReplacementItem),
			ResultingText, PictureLib.DialogInformation);
		UpdatedItemsList = New Array;
		For Each RefToReplace In RefsToReplace Do
			UpdatedItemsList.Add(RefToReplace.Ref);
		EndDo;
		NotifyOfSuccessfulReplacement(UpdatedItemsList);
		Close();
	EndIf
	
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
			TreeRow.Code    = String(ObjectCode(Ref, MetadataCache));
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
	If Response = DialogReturnCode.Abort
		And Items.WizardSteps.CurrentPage = Items.ReplacementStep Then
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