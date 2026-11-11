
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	#Region StandardMechanisms
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
		
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	Cancel = True;
	CommonClient.MessageToUser(NStr("vi = 'Cần nhập chứng từ nhập số dư về bán hàng trong kỳ trước từ chỗ làm việc ""Điền ban đầu"" trên thanh lệnh ""Danh mục và quản trị""';
									|ru = 'Документ ввод остатков о продажах за прошлые периоды необходимо вводить из рабочего места ""Начальное заполнение"" в панели ""НСИ и Администрирование""';
									|en = 'The document for OB entry of sales for previous periods must be entered from the ""Initial filling"" workplace in the ""Master data and settings"" panel'; fa = 'The document for OB entry of sales for previous periods must be entered from the ""Initial filling"" workplace in the ""Master data and settings"" panel';
									|it = 'Il documento di inserimento dei saldi sulle vendite per i periodi precedenti deve essere inserito dalla postazione di lavoro ""Compilazione iniziale"" nel pannello ""Informazioni di riferimento e Amministrazione""';
									|pl = 'Dokument wprowadzenie sald o sprzedaży za poprzednie okresy należy wprowadzać z miejsca pracy ""Wstępne wypełnienie"" w panelu ""Ustawienia""';
									|tr = 'Önceki dönemlere ait satış bakiyelerinin girilmesine ilişkin belge ""Master veri ve yönetim"" panelindeki ""İlk doldurma"" çalışma alanından girilmelidir'"));
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject);
	
EndProcedure

#EndRegion
