#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	ParameterDetails_ = GeneralPurposeTMServerCall.ObjectAttributesValues(CommandParameter, "IsFolder, Owner");
	If ParameterDetails_.IsFolder Then
		ShowMessageBox(Undefined, NStr("vi = 'Bạn chỉ có thể tạo các nhiệm vụ dựa trên các giai đoạn chuẩn bị ngân sách';
										|ru = 'Создавать задачи можно только на основании этапов подготовки бюджетов';
										|en = 'You can only create tasks based on the budgeting steps'; fa = 'You can only create tasks based on the budgeting steps';
										|it = 'Gli obiettivi possono essere creati solo in base alle fasi di preparazione dei budget';
										|pl = 'Możesz tworzyć zadania tylko na podstawie etapów przygotowania budżetów';
										|tr = 'Görev sadece ana bütçe hazırlama aşamalarında oluşturulabilir'"));
		Return;
	EndIf;
	Basis = CommandParameter;
	
	FormParameters = New Structure("Basis", Basis);
	If TypeOf(CommandParameter) = Type("TaskRef.BudgetTask") Then
		FormParameters.Insert("MainTask_", CommandParameter);
	EndIf;
	OpenForm("Task.BudgetTask.Form.BusinessTaskForm", FormParameters, CommandExecuteParameters.Source,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion