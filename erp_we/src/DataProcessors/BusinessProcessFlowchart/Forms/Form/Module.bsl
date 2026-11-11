///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If ValueIsFilled(Parameters.BusinessProcess) Then
		BusinessProcess = Parameters.BusinessProcess;
	EndIf;
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	UpdateFlowchart();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessProcessOnChange(Item)
	UpdateFlowchart();
EndProcedure

&AtClient
Procedure FlowchartSelection(Item)
	OpenRoutePointTasksList();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RefreshExecute(Command)
	UpdateFlowchart();   
EndProcedure

&AtClient
Procedure TasksExecute(Command)
	OpenRoutePointTasksList();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateFlowchart()
	
	If ValueIsFilled(BusinessProcess) Then
		Flowchart = BusinessProcess.GetObject().GetFlowchart();
	ElsIf BusinessProcess <> Undefined Then
		Flowchart = BusinessProcesses[BusinessProcess.Metadata().Name].GetFlowchart();
		Return;
	Else
		Flowchart = New GraphicalSchema;
		Return;
	EndIf;
	
	HasState = BusinessProcess.Metadata().Attributes.Find("State") <> Undefined;
	BusinessProcessProperties = Common.ObjectAttributesValues(
		BusinessProcess, "Author,Date,CompletedOn,Completed,Started" 
		+ ?(HasState, ",State", ""));
	FillPropertyValues(ThisObject, BusinessProcessProperties);
	If BusinessProcessProperties.Completed Then
		Status = NStr("vi = 'Đã kết thúc';
						|ru = 'Завершен';
						|en = 'Completed'; fa = 'تکمیل‌شده';
						|it = 'Completato';
						|pl = 'Zakończony';
						|tr = 'Tamamlandı'");
		Items.StatusGroup.CurrentPage = Items.CompletedGroup;
	ElsIf BusinessProcessProperties.Started Then
		Status = NStr("vi = 'Khởi động';
						|ru = 'Стартован';
						|en = 'Started'; fa = 'شروع‌شده';
						|it = 'Iniziato';
						|pl = 'Wystartowano';
						|tr = 'Başladı'");
		Items.StatusGroup.CurrentPage = Items.NotCompletedGroup;
	Else	
		Status = NStr("vi = 'Chưa khởi động';
						|ru = 'Не стартован';
						|en = 'Not started'; fa = 'شروع‌نشده';
						|it = 'Non iniziato';
						|pl = 'Nie wszczęty';
						|tr = 'Başlamadı'");
		Items.StatusGroup.CurrentPage = Items.NotCompletedGroup;
	EndIf;
	If HasState Then
		Status = Status + ", " + Lower(State);
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenRoutePointTasksList()

#If WebClient Or MobileClient Then
	ShowMessageBox(, NStr("vi = 'Thao tác không khả dụng trong web-client hoặc trong mobile client.
		|Hãy khởi động thin client.';
		|ru = 'Действие недоступно в веб-клиенте или в мобильном клиенте.
		|Запустите тонкий клиент.';
		|en = 'Cannot perform the operation in web client or mobile client.
		|Start thin client.'; fa = 'Cannot perform the operation in web client or mobile client.
		|Start thin client.';
		|it = 'L''azione non è disponibile nel web client o nel client mobile.
		|Avviare thin client.';
		|pl = 'Działanie jest niedostępne w kliencie webowym lub kliencie mobilnym.
		|Uruchom klient cienki.';
		|tr = 'Eylem, web veya mobil istemcide mevcut değil. 
		|İnce istemciyi başlatın.'"));
	Return;
#EndIf
	ClearMessages();
	CurItem = Items.Flowchart.CurrentItem;

	If Not ValueIsFilled(BusinessProcess) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Hãy chỉ ra quy trình nghiệp vụ.';
				|ru = 'Укажите бизнес-процесс.';
				|en = 'Specify a business process.'; fa = 'Specify a business process.';
				|it = 'Indicare processo aziendale.';
				|pl = 'Wskaż proces biznesowy.';
				|tr = 'İş sürecini belirtin.'"),,
			"BusinessProcess");
		Return;
	EndIf;
	
	If CurItem = Undefined 
		Or	Not (TypeOf(CurItem) = Type("GraphicalSchemaItemActivity")
		Or TypeOf(CurItem) = Type("GraphicalSchemaItemSubBusinessProcess")) Then
		
		CommonClient.MessageToUser(
			NStr("vi = 'Để xem danh sách nhiệm vụ, hãy chọn điểm hiệu lực hoặc quy trình nghiệp vụ lồng trong của thẻ lộ trình.';
				|ru = 'Для просмотра списка задач выберите точку действия или вложенный бизнес-процесс карты маршрута.';
				|en = 'To view the task list, select an action point or a nested business process of the flowchart.'; fa = 'To view the task list, select an action point or a nested business process of the flowchart.';
				|it = 'Per visualizzare l''elenco dei compiti, selezionare il punto di azione o il processo aziendale nidificato della carta di percorso.';
				|pl = 'Aby przejrzeć listę zadań wybierz punkt działania lub wbudowany proces biznesowy mapy trasy.';
				|tr = 'Görev listesini görebilmek için, eylem noktası veya akış çizelgesinden gömülü bir iş süreci seçin.'"),,
			"Flowchart");
		Return;
	EndIf;

	FormCaption = NStr("vi = 'Nhiệm vụ theo điểm lộ trình quy trình nghiệp vụ';
						|ru = 'Задачи по точке маршрута бизнес-процесса';
						|en = 'Business process route point tasks'; fa = 'Business process route point tasks';
						|it = 'I task per la tappa di percorso del processo aziendale';
						|pl = 'Zadania według punktu biznesowego procesu';
						|tr = 'İş akışının yol noktalarına göre görevler'");
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", New Structure("BusinessProcess,RoutePoint", BusinessProcess, CurItem.Value));
	FormParameters.Insert("FormCaption", FormCaption);
	FormParameters.Insert("ShowTasks", 0);
	FormParameters.Insert("FiltersVisibility", False);
	FormParameters.Insert("OwnerWindowLock", FormWindowOpeningMode.LockOwnerWindow);
	FormParameters.Insert("Task", String(CurItem.Value));
	FormParameters.Insert("BusinessProcess", String(BusinessProcess));
	OpenForm("Task.PerformerTask.ListForm", FormParameters, ThisObject, BusinessProcess);

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
