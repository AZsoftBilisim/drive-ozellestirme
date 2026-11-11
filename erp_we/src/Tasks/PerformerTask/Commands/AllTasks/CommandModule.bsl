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
	
	OpenForm(
		"Task.PerformerTask.ListForm",
		New Structure("FormCaption", NStr("vi = 'Tất cả nhiệm vụ';
											|ru = 'Все задачи';
											|en = 'All tasks'; fa = 'همه وظایف';
											|it = 'Tutti gli obiettivi';
											|pl = 'Wszystkie zadania';
											|tr = 'Tüm görevler'")),
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window);
	
EndProcedure

#EndRegion