
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ChooseAnArtist = Parameters.ChooseAnArtist;
	SelectABudgetPreparationStep = Parameters.SelectABudgetPreparationStep;
	BudgetingModel = Parameters.BudgetingModel;
	
	If Parameters.CreatingMultipleTasks Then
		FormCaption = NStr("vi = 'Lập nhiệm vụ liên quan';
							|ru = 'Формирование связанных задач';
							|en = 'Generation of linked tasks'; fa = 'Generation of linked tasks';
							|it = 'Generazione degli obiettivi correlati';
							|pl = 'Tworzenie powiązanych zadań';
							|tr = 'Görev bağlantısı oluşturma'");
		CreateIssueHeader = NStr("vi = 'Lập nhiệm vụ';
								|ru = 'Сформировать задачи';
								|en = 'Generate tasks'; fa = 'Generate tasks';
								|it = 'Generare gli obiettivi';
								|pl = 'Ukształtować zadania';
								|tr = 'Görevleri oluştur'");
		DonTFormIssueHeader = NStr("vi = 'Không tạo nhiệm vụ';
									|ru = 'Не формировать задачи';
									|en = 'Do not generate tasks'; fa = 'Do not generate tasks';
									|it = 'Non generare gli obiettivi';
									|pl = 'Nie kształtować zadania';
									|tr = 'Görevleri oluşturma'");
		HeaderGroupProcessStepSelection = NStr("vi = 'Tạo nhiệm vụ';
												|ru = 'Создать задачи в рамках';
												|en = 'Create tasks within'; fa = 'Create tasks within';
												|it = 'Crea gli obiettivi all''interno';
												|pl = 'Utwórz zadania w ramkach';
												|tr = 'Bu kapsamda görev oluştur'")
	Else
		FormCaption = NStr("vi = 'Lập nhiệm vụ liên quan';
							|ru = 'Формирование связанной задачи';
							|en = 'Generate linked task'; fa = 'تولید وظیفه مرتبط';
							|it = 'Generare un obiettivo correlato';
							|pl = 'Tworzenie powiązanego zadania';
							|tr = 'Görev bağlantısı oluşturma'");
		CreateIssueHeader = NStr("vi = 'Lập nhiệm vụ';
								|ru = 'Сформировать задачу';
								|en = 'Generate task'; fa = 'تولید وظیفه';
								|it = 'Generare un obiettivo';
								|pl = 'Ukształtować zadanie';
								|tr = 'Görevi oluştur'");
		DonTFormIssueHeader = NStr("vi = 'Không tạo nhiệm vụ';
									|ru = 'Не формировать задачу';
									|en = 'Do not generate task'; fa = 'عدم تولید وظیفه';
									|it = 'Non generare un obiettivo';
									|pl = 'Nie kształtować zadanie';
									|tr = 'Görevi oluşturma'");
		HeaderGroupProcessStepSelection = NStr("vi = 'Tạo một nhiệm vụ trong';
												|ru = 'Создать задачу в рамках';
												|en = 'Create a task within'; fa = 'Create a task within';
												|it = 'Crea un obiettivo all''interno';
												|pl = 'Utwórz zadanie w ramkach';
												|tr = 'Bu kapsamda görev oluştur'")
	EndIf;
	
	Title = ?(Not IsBlankString(Parameters.FormCaption), Parameters.FormCaption, FormCaption);
	Items.GenerateTask.Title = CreateIssueHeader;
	Items.DoNotGenerateATask.Title = DonTFormIssueHeader;
	Items.ProcessStepSelectionGroup.Title = HeaderGroupProcessStepSelection;
	
	Items.ProcessStepSelectionGroup.Visible = SelectABudgetPreparationStep;
	Items.Performer.Visible = ChooseAnArtist;
	
	FormControl();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If ValueIsFilled(TaskDueDate) And BegOfDay(TaskDueDate) < BegOfDay(CurrentSessionDate()) Then
		Common.MessageToUser(
			NStr("vi = 'Thời hạn của nhiệm vụ không thể nhỏ hơn ngày hiện tại';
				|ru = 'Срок исполнения задачи не может быть меньше текущей даты';
				|en = 'Task deadline cannot be less than the current date'; fa = 'Task deadline cannot be less than the current date';
				|it = 'Il periodo di esecuzione dell''obiettivo non può essere antecedente alla data corrente';
				|pl = 'Termin wykonania zadania nie może być krótszy, niż bieżąca data';
				|tr = 'Görev tamamlama süreci mevcut tarihten daha az olamaz'"), , , "TaskDueDate", Cancel);
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
	If OptionOfChoiceBudgetPreparationStage = 0 Then
		NotCheckedAttributeArray.Add("BudgetingStep");
	EndIf;
	
	If Not ChooseAnArtist Then
		NotCheckedAttributeArray.Add("Performer");
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BudgetingStepCurrent_OnChange(Item)
	
	BudgetingStep = Undefined;
	FormControl();
	
EndProcedure

&AtClient
Procedure BudgetPreparationStageSelectedOnChange(Item)
	
	FormControl();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GenerateTask(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = New Structure("Description, TaskDueDate, TaskDetails1");
	If ChooseAnArtist Then
		Result.Insert("Performer");
	EndIf;
	If OptionOfChoiceBudgetPreparationStage Then
		Result.Insert("BudgetingStep");
	EndIf;
	
	FillPropertyValues(Result, ThisObject);
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure DoNotGenerateATask(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FormControl()
	
	Items.BudgetingStep.Enabled = (OptionOfChoiceBudgetPreparationStage = 1);
	Items.BudgetingStep.AutoMarkIncomplete = (OptionOfChoiceBudgetPreparationStage = 1);
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
