///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	If CommandParameter = Undefined Then
		ShowMessageBox(,NStr("vi = 'Chưa chọn nhiệm vụ.';
							|ru = 'Не выбраны задачи.';
							|en = 'Tasks are not selected.'; fa = 'Tasks are not selected.';
							|it = 'Obiettivi non selezionati.';
							|pl = 'Nie wybrane zadania.';
							|tr = 'Görevler seçilmedi.'"));
		Return;
	EndIf;
		
	ClearMessages();
	Result = PeformTasks(CommandParameter);
	ShowUserNotification(Result.MessageText, Result.URL, Result.Explanation);
	Notify("Write_PerformerTask", New Structure("Executed", True), CommandParameter);
	
EndProcedure

&AtServer
Function PeformTasks(Val Var_Tasks)
	
	Result = New Structure;
	Result.Insert("MessageText", NStr("vi = 'Đã thực hiện nhiệm vụ';
										|ru = 'Задачи выполнены';
										|en = 'Tasks are completed'; fa = 'Tasks are completed';
										|it = 'Tasks are completed';
										|pl = 'Tasks are completed';
										|tr = 'Görevler tamamlandı'"));
	Result.Insert("URL", Undefined);
	Result.Insert("Explanation", "");
	For Each Task In Var_Tasks Do
		BusinessProcessesAndTasksServer.ExecuteTask(Task, True);
		If Result.URL = Undefined Then
			Result.MessageText = NStr("vi = 'Đã thực hiện nhiệm vụ';
										|ru = 'Задача выполнена';
										|en = 'Task is completed'; fa = 'Task is completed';
										|it = 'Task completato';
										|pl = 'Zadanie zakończone';
										|tr = 'Görev tamamlandı'");
			Result.URL = GetURL(Task);
			Result.Explanation = String(Task);
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

#EndRegion