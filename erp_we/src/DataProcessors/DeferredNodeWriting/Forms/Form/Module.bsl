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
	
	If Not Parameters.Property("Node") Then
		Raise NStr("vi = 'Bộ xử lý không được dùng để sử dụng trực tiếp.';
					|ru = 'Обработка не предназначена для непосредственного использования.';
					|en = 'The data processor cannot be opened manually.'; fa = 'The data processor cannot be opened manually.';
					|it = 'L''elaborazione non è destinata all''uso diretto.';
					|pl = 'Przetwarzanie nie jest przeznaczone do bezpośredniego używania.';
					|tr = 'Bu veri işlemcisi manuel kullanıma yönelik değildir.'");
	EndIf;
	
	Node = Parameters.Node;
	NodeStructureAddress = Parameters.NodeStructureAddress;
	
	IsStandaloneWorkstation = DataExchangeCached.IsStandaloneWorkstationNode(Node);
	
	TitleTemplate1 = NStr("vi = 'Bản ghi của nút ""%1""';
							|ru = 'Запись узла ""%1""';
							|en = 'Saving the ""%1"" node'; fa = 'Saving the ""%1"" node';
							|it = 'Registrazione nodo ""%1""';
							|pl = 'Zapisywanie węzła ""%1""';
							|tr = 'Ünite kaydı ""%1""'");
	Title = StrTemplate(TitleTemplate1, String(Node)); 
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	TimeConsumingOperation = StartProcedureExecution();
	
	CallbackOnCompletion = New CallbackDescription("ProcessResult", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters());

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure DoneCommand(Command)
	Close();
EndProcedure

&AtClient
Procedure CloseCommand(Command)
	Close();
EndProcedure

#EndRegion

#Region Private

&AtClient
Function IdleParameters()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = "";
	IdleParameters.OutputProgressBar = False;
	IdleParameters.OutputIdleWindow = False;
	IdleParameters.OutputMessages = False;
	Return IdleParameters;
	
EndFunction

&AtServer
Function StartProcedureExecution()
	
	ExecutionParameters = TimeConsumingOperations.ProcedureExecutionParameters();
	DescriptionTemplate = NStr("vi = '""Bản ghi kéo dài của nút """"%1""""';
								|ru = '""Длительная запись узла """"%1""""';
								|en = '""Long """"%1"""" node saving'; fa = '""Long """"%1"""" node saving';
								|it = '""Registrazione del nodo ampliata """"%1""""';
								|pl = '""Długotrwałe zapisywanie węzła """"%1""""';
								|tr = '""Uzun süreli ünite kaydı """"%1""""'");
	ExecutionParameters.BackgroundJobDescription = StrTemplate(DescriptionTemplate, String(Node));
	ExecutionParameters.BackgroundJobKey = "DeferredNodeWriting";
	
	StructureNode = GetFromTempStorage(NodeStructureAddress);
	Return TimeConsumingOperations.ExecuteProcedure(ExecutionParameters, "DataProcessors.DeferredNodeWriting.WriteANode", Node, StructureNode);
		
EndFunction

&AtClient
Procedure ProcessResult(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		
		Items.PanelMain.CurrentPage = Items.EndPage;
		
		If IsStandaloneWorkstation Then
			Notify("Write_StandaloneWorkstation");
		Else
			Notify("Write_ExchangePlanNode");
		EndIf;
		
	ElsIf Result.Status = "Error" Then
		
		CommonClient.MessageToUser(Result.BriefErrorDescription);
		Items.PanelMain.CurrentPage = Items.ErrorPage;
		
	EndIf;
	
EndProcedure 

#EndRegion
