///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Form command handler.
//
// Parameters:
//   Form - ClientApplicationForm - a form where the command is executed.
//   Command - FormCommand - a running command.
//   Source - FormTable
//            - FormDataStructure - an object or a form list with the Reference field.
//
Procedure StartCommandExecution(Form, Command, Val Source = Undefined) Export
	CommandName = Command.Name;
	SettingsAddress = Form.AttachableCommandsParameters.CommandsTableAddress;
	CommandDetails = AttachableCommandsClientCached.CommandDetails(CommandName, SettingsAddress);

	If Source = Undefined Then
		Source = AttachableCommandsClientServer.CommandOwnerByCommandName(CommandName, Form);
	EndIf;
	
	ExecutionParameters = CommandExecuteParameters();
	ExecutionParameters.CommandDetails = New Structure(CommandDetails);
	ExecutionParameters.Form           = Form;
	ExecutionParameters.Source        = Source;
	
	ExecutionParameters.IsObjectForm = TypeOf(Source) = Type("FormDataStructure");
	// Service parameters.
	ExecutionParameters.WritingRequired         = ExecutionParameters.IsObjectForm And CommandDetails.WriteMode <> "NotWrite";
	ExecutionParameters.PostingRequired = CommandDetails.WriteMode = "Post"
		And (Not ExecutionParameters.IsObjectForm Or Source.Property("Posted"));
	ExecutionParameters.FilesOperationsRequired = CommandDetails.FilesOperationsRequired;
	ExecutionParameters.CallServerThroughNotificationProcessing = True;
	
	ContinueCommandExecution(ExecutionParameters);
EndProcedure

// Form command handler.
//
// Parameters:
//   Form - ClientApplicationForm - a form where the command is executed.
//   Command - FormCommand - a running command.
//   Source - FormTable
//            - FormDataStructure
//            - AnyRef
//            - Array - an object or a form list with the Reference field,
//                       Reference or array of references.
//
Procedure ExecuteCommand(Form, Command, Source) Export
	CommandName = Command.Name;
	SettingsAddress = Form.AttachableCommandsParameters.CommandsTableAddress;
	CommandDetails = AttachableCommandsClientCached.CommandDetails(CommandName, SettingsAddress);
	
	ExecutionParameters = CommandExecuteParameters();
	ExecutionParameters.CommandDetails = New Structure(CommandDetails);
	ExecutionParameters.Form           = Form;
	ExecutionParameters.Source        = Source;
	ExecutionParameters.IsObjectForm = TypeOf(Source) = Type("FormDataStructure");
	// Service parameters.
	ExecutionParameters.WritingRequired  = ExecutionParameters.IsObjectForm And CommandDetails.WriteMode <> "NotWrite";
	ExecutionParameters.PostingRequired = CommandDetails.WriteMode = "Post"
		And (Not ExecutionParameters.IsObjectForm Or Source.Property("Posted"));
	ExecutionParameters.FilesOperationsRequired = CommandDetails.FilesOperationsRequired;
	
	ContinueCommandExecution(ExecutionParameters);
EndProcedure

// Updates the list of commands depending on the current form context.
//
// Parameters:
//  Form - ClientApplicationForm
//
Procedure StartCommandUpdate(Form) Export
	Form.DetachIdleHandler("Attachable_UpdateCommands");
	Form.AttachIdleHandler("Attachable_UpdateCommands", 0.2, True);
EndProcedure

// Continues executing the command if the execution was interrupted in the BeforeWrite form event handler.
//
// Parameters:
//  Form - ClientApplicationForm - a form where the command is executed.
//  Object - FormDataStructure
//         - AnyRef - a form object with the Reference field.
//  WriteParameters - Structure - arbitrary save parameters. See the AfterWrite event details in Syntax Assistant.
//
Procedure AfterWrite(Form, Object, WriteParameters) Export
	
	If TypeOf(WriteParameters) = Type("Structure") And WriteParameters.Property("AttachableCommandExecutionParameters") Then
		Context = WriteParameters.AttachableCommandExecutionParameters;
		Context.Insert("Form", Form);
		Context.Insert("Source", Object);
		
		Context.Form.AttachableCommandsParameters.Delete("TheCommandIsExecuted");
		
		ParameterName = "StandardSubsystems.AttachableCommands.AttachableCommandExecutionParameters";
		ApplicationParameters[ParameterName] = Context;
		AttachIdleHandler("ResumeAttachableCommandAfterWrittenOnForm", 0.1, True);
	EndIf;
	
EndProcedure

// Properties of the second handler parameter of the attachable command executed on the client.
//
// Returns:
//  Structure:
//   * CommandDetails - Structure - properties match the value table columns of the Commands parameter
///of the AttachableCommandsOverridable.OnDefineCommandsAttachedToObject procedure.
//                                   Key properties:
//      ** Id  - String - Command ID.
//      ** Presentation  - String - Command presentation in a form.
//      ** Name            - String - a command name on a form.
//      ** AdditionalParameters - Structure - additional properties defined by 
//                                   the kind of a specific command.
//   * Form - ClientApplicationForm - a form the command is called from.
//           - ManagedFormExtensionForDocuments
//   * IsObjectForm - Boolean - True if the command is called from the object form.
//   * Source - FormTable
//              - FormDataStructure - An object or a form list with the "Ref" field:
//     ** Ref - AnyRef
//
Function CommandExecuteParameters() Export
	Result = AttachableCommandsClientServer.CommandExecuteParameters();
	// Service parameters.
	Result.Insert("WritingRequired", False);
	Result.Insert("PostingRequired", False);
	Result.Insert("FilesOperationsRequired", False);
	Result.Insert("ReferencesArrray", New Array);
	Result.Insert("CallServerThroughNotificationProcessing", False);
	Result.Insert("UnpostedDocuments", New Array);
	Return Result;
EndFunction

#EndRegion

#Region Internal

// Checks the posting status of the passed documents and returns the unposted documents.
//
// Parameters:
//  Var_Documents - Array of DocumentRef - Documents to check.
//
// Returns:
//  Structure:
//    * UnpostedDocuments - Array of DocumentRef
//    * HasPostingRight - Boolean
//
Function DocsPostInfoRecords(Val Var_Documents) Export
	
	Return AttachableCommandsServerCall.DocsPostInfoRecords(Var_Documents);
	
EndFunction

#EndRegion

#Region Private

// Executes the command attached to the form.
//
// Parameters:
//  ExecutionParameters - See CommandExecuteParameters
// 
Procedure ContinueCommandExecution(ExecutionParameters)
	
	If ExecutionParameters.Form.ReadOnly And ExecutionParameters.CommandDetails.ChangesSelectedObjects Then
		ShowMessageBox(, NStr("vi = 'Để thực hiện thao tác này, cần cho phép chỉnh sửa trong biểu mẫu.';
								|ru = 'Для выполнения этого действия необходимо разрешить редактирование в форме.';
								|en = 'To perform this action, you must allow editing in the form.'; fa = 'To perform this action, you must allow editing in the form.';
								|it = 'Per l''esecuzione di questa azione è necessario consentire la modifica nel modulo.';
								|pl = 'W celu wykonania tego działania należy zezwolić edycję w formularzu.';
								|tr = 'Bu işlemi yürütmek için formda düzenlemeye izin verilmelidir.'"));
		Return;
	EndIf;
	
	Source = ExecutionParameters.Source;
	CommandDetails = ExecutionParameters.CommandDetails;
	
	// Install 1C:Enterprise Extension.
	If ExecutionParameters.FilesOperationsRequired Then
		ExecutionParameters.FilesOperationsRequired = False;
		Handler = New CallbackDescription("ContinueCommandExecutionAfterInstall1CEnterpriseExtension", ThisObject, ExecutionParameters);
		MessageText = NStr("vi = 'Để tiếp tục, hãy cài đặt phần mở rộng để làm việc với 1C:Enterprise.';
							|ru = 'Для продолжения установите расширение для работы с 1С:Предприятием.';
							|en = 'To continue, install 1C:Enterprise Extension.'; fa = 'To continue, install 1C:Enterprise Extension.';
							|it = 'Per continuare, installare l''estensione per il lavoro con 1C:Enterprise.';
							|pl = 'W celu kontynuowania zainstaluj rozszerzenie do pracy z 1C:Enterprise.';
							|tr = 'Devam etmek için 1C:Enterprise ile çalışma uzantısını yükleyin.'");
		FileSystemClient.Attach1CEnterpriseExtension(Handler, MessageText);
		Return;
	EndIf;
	
	ExecutionParameters.ReferencesArrray = ?(TypeOf(Source) = Type("FormDataStructure"),
		CommonClientServer.ValueInArray(Source.Ref),
		SelectedObjects(Source, CommandDetails));
	
	If CommandDetails.MultipleChoice Then
		CommandParameter = ExecutionParameters.ReferencesArrray;
	ElsIf ExecutionParameters.ReferencesArrray.Count() = 0 Then
		CommandParameter = Undefined;
	Else
		CommandParameter = ExecutionParameters.ReferencesArrray[0];
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.Print") Then
		ModulePrintManagerInternalClient = CommonClient.CommonModule("PrintManagementInternalClient");
		ModulePrintManagerInternalClient.BeforeExecutingCommand(CommandParameter, ExecutionParameters);
	EndIf;
	
	// Writing in the object form.
	If ExecutionParameters.WritingRequired Then
		ExecutionParameters.WritingRequired = False;
		ExecutionParameters.PostingRequired = ExecutionParameters.PostingRequired And Source.Property("Posted");
		
		If Source.Ref.IsEmpty()
			Or (CommandDetails.WriteMode <> "WriteNewOnly" And ExecutionParameters.Form.Modified)
			Or ExecutionParameters.PostingRequired And Not Source.Posted Then
			
			Buttons = New ValueList;
			If ExecutionParameters.PostingRequired Then
				QuestionTemplate = NStr("vi = 'Để thực hiện lệnh ""%1""
					|, chứng từ sẽ được kết chuyển. Tiếp tục?';
					|ru = 'Для выполнения команды ""%1""
					|документ будет проведен. Продолжить?';
					|en = 'The document will be posted in order to run the ""%1"" command.
					|Do you want to continue?'; fa = 'The document will be posted in order to run the ""%1"" command.
					|Do you want to continue?';
					|it = 'Per eseguire il comando !%1""
					| il documento verrà registrato. Continuare?';
					|pl = 'Aby wykonać polecenie ""%1""
					|dokument zostanie zatwierdzony. Kontynuować?';
					|tr = '""%1""
					|komutunun yürütülmesi için belge çevrilecektir. Devam edilsin mi?'");
				Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Kết chuyển và tiếp tục';
														|ru = 'Провести и продолжить';
														|en = 'Post and continue'; fa = 'Post and continue';
														|it = 'Pubblicare e continuare';
														|pl = 'Zatwierdzić i kontynuować';
														|tr = 'Kaydet ve devam et'"));
			Else
				QuestionTemplate = NStr("vi = 'Để thực hiện lệnh ""%1""
					|, dữ liệu sẽ được ghi lại. Tiếp tục?';
					|ru = 'Для выполнения команды ""%1""
					|данные будут записаны. Продолжить?';
					|en = 'To run the ""%1"" command,
					|the data will be saved. Do you want to continue?'; fa = 'To run the ""%1"" command,
					|the data will be saved. Do you want to continue?';
					|it = 'Per eseguire il comando ""%1""
					|i dati verranno salvati. Continuare?';
					|pl = 'W celu wykonania polecenia ""%1""
					|dane zostaną zapisane. Kontynuować?';
					|tr = '""%1""
					|komutunun yürütülmesi için veriler kaydedilecektir. Devam edilsin mi?'");
				Buttons.Add(DialogReturnCode.OK, NStr("vi = 'Ghi lại và tiếp tục';
														|ru = 'Записать и продолжить';
														|en = 'Save and continue'; fa = 'Save and continue';
														|it = 'Registrare e continuare';
														|pl = 'Zapisz i kontynuuj';
														|tr = 'Kaydet ve devam et'"));
			EndIf;
			Buttons.Add(DialogReturnCode.Cancel);
			
			QueryText = StringFunctionsClientServer.SubstituteParametersToString(QuestionTemplate, CommandDetails.Presentation);
			Handler = New CallbackDescription("ProceedRunningCommandAfterRecordConfirmed", ThisObject, ExecutionParameters);
			
			ShowQueryBox(Handler, QueryText, Buttons);
			Return;
		EndIf;
	EndIf;
	
	// Post documents.
	If ExecutionParameters.PostingRequired Then
		ExecutionParameters.PostingRequired = False;
		DocumentsInfo = DocsPostInfoRecords(ExecutionParameters.ReferencesArrray);
		If DocumentsInfo.UnpostedDocuments.Count() > 0 Then
			If DocumentsInfo.HasPostingRight Then
				If DocumentsInfo.UnpostedDocuments.Count() = 1 Then
					QueryText = NStr("vi = 'Để thực hiện lệnh, trước hết hãy kết chuyển chứng từ. Kết chuyển chứng từ và tiếp tục?';
									|ru = 'Для выполнения команды предварительно проведите документ. Выполнить проведение документа и продолжить?';
									|en = 'Cannot run the command for an unposted document. Do you want to post the document and continue?'; fa = 'Cannot run the command for an unposted document. Do you want to post the document and continue?';
									|it = 'Per eseguire il comando, pubblicare preventivamente il documento. Pubblicare il documento e continuare?';
									|pl = 'W celu wykonania polecenia wstępnie zatwierdź dokument. Wykonać zatwierdzenie dokumentu i kontynuować?';
									|tr = 'Komutu yürütmek için belgeyi önce onaylayın . Belge onaylansın ve devam edilsin mi?'");
				Else
					QueryText = NStr("vi = 'Để thực hiện lệnh, trước hết cần kết chuyển chứng từ. Kết chuyển chứng từ và tiếp tục?';
									|ru = 'Для выполнения команды предварительно проведите документы. Выполнить проведение документов и продолжить?';
									|en = 'Cannot run the command for unposted documents. Do you want to post the documents and continue?'; fa = 'Cannot run the command for unposted documents. Do you want to post the documents and continue?';
									|it = 'Per eseguire il comando, pubblicare preventivamente i documenti. Pubblicare i documenti e continuare?';
									|pl = 'W celu wykonania polecenia wstępnie zatwierdź dokumenty. Wykonać zatwierdzenie dokumentów i kontynuować?';
									|tr = 'Komutu yürütmek için belgeleri önce onaylayın. Belgeler onaylansın ve devam edilsin mi?'");
				EndIf;
				ExecutionParameters.UnpostedDocuments = DocumentsInfo.UnpostedDocuments;
				Handler = New CallbackDescription("ContinueCommandExecutionAfterConfirmPosting", 
					ThisObject, ExecutionParameters);
				Buttons = New ValueList;
				Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Kết chuyển và tiếp tục';
														|ru = 'Провести и продолжить';
														|en = 'Post and continue'; fa = 'Post and continue';
														|it = 'Pubblicare e continuare';
														|pl = 'Zatwierdzić i kontynuować';
														|tr = 'Kaydet ve devam et'"));
				Buttons.Add(DialogReturnCode.Cancel);
				ShowQueryBox(Handler, QueryText, Buttons);
			Else
				If DocumentsInfo.UnpostedDocuments.Count() = 1 Then
					WarningText = NStr("vi = 'Để thực hiện lệnh, trước hết cần kết chuyển chứng từ. Không đủ quyền để kết chuyển chứng từ.';
										|ru = 'Для выполнения команды предварительно проведите документ. Недостаточно прав для проведения документа.';
										|en = 'Cannot run the command for an unposted document. You are not authorized to post the document.'; fa = 'Cannot run the command for an unposted document. You are not authorized to post the document.';
										|it = 'Per eseguire il comando, pubblicare preventivamente i documenti. Diritti insufficienti per la pubblicazione del documento.';
										|pl = 'W celu wykonania polecenia wstępnie zatwierdź dokument. Niewystarczające uprawnienia do zatwierdzenia dokumentu.';
										|tr = 'Komutu yürütmek için belgeyi önce onaylayın. Belge onaylanması için yetersiz yetki.'");
				Else
					WarningText = NStr("vi = 'Để thực hiện lệnh, trước hết cần kết chuyển chứng từ. Không đủ quyền để kết chuyển chứng từ.';
										|ru = 'Для выполнения команды предварительно проведите документы. Недостаточно прав для проведения документов.';
										|en = 'Cannot run the command for unposted documents. You are not authorized to post the documents.'; fa = 'Cannot run the command for unposted documents. You are not authorized to post the documents.';
										|it = 'Per eseguire il comando, pubblicare preventivamente i documenti. Diritti insufficienti per la pubblicazione dei documenti.';
										|pl = 'W celu wykonania polecenia wstępnie zatwierdź dokumenty. Niewystarczające prawa do zatwierdzenia dokumentów.';
										|tr = 'Komutu yürütmek için belgeleri önce onaylayın. Belgelerin onaylanması için yetersiz yetki.'");
				EndIf;
				Raise(WarningText, ErrorCategory.AccessViolation);
			EndIf;
			Return;
		EndIf;
	EndIf;
	
	// Command runtime.
	If CommandDetails.ServerRoom Then
		Result = New Structure;
		
		ServerContext = New Structure;
		ServerContext.Insert("CommandParameter", CommandParameter);
		ServerContext.Insert("CommandNameInForm", CommandDetails.NameOnForm);
		ServerContext.Insert("Result", Result);
		
		If ExecutionParameters.CallServerThroughNotificationProcessing Then
			CallbackDescription = New CallbackDescription("Attachable_ContinueCommandExecutionAtServer", ExecutionParameters.Form);
			RunCallback(CallbackDescription, ServerContext);
			Result = ServerContext.Result;
		Else
			ExecutionParameters.Form.Attachable_ExecuteCommandAtServer(ServerContext, Result);
		EndIf;
		If ValueIsFilled(Result.Text) Then
			ShowMessageBox(, Result.Text);
		Else
			UpdateForm(ExecutionParameters);
		EndIf;
	Else
		If ValueIsFilled(CommandDetails.Handler) Then
			SubstringsArray = StrSplit(CommandDetails.Handler, ".");
			If SubstringsArray.Count() = 1 Then
				FormParameters = FormParameters(ExecutionParameters, CommandParameter);
				// ACC:65-off GetForm is intended to call the notification details handler.
				ModuleClient = GetForm(CommandDetails.FormName, FormParameters, ExecutionParameters.Form, True);
				// ACC:65-on
				ProcedureName = CommandDetails.Handler;
			Else
				ModuleClient = CommonClient.CommonModule(SubstringsArray[0]);
				ProcedureName = SubstringsArray[1];
			EndIf;
			Handler = New CallbackDescription(ProcedureName, ModuleClient, ExecutionParameters);
			RunCallback(Handler, CommandParameter);
		ElsIf ValueIsFilled(CommandDetails.FormName) Then
			FormParameters = FormParameters(ExecutionParameters, CommandParameter);
			OpenForm(CommandDetails.FormName, FormParameters, ExecutionParameters.Form, True);
		EndIf;
	EndIf;
EndProcedure

// The procedure branch that is going after the writing confirmation dialog.
// 
// Parameters:
//  Response - DialogReturnCode
//  Context - See CommandExecuteParameters
//
Procedure ProceedRunningCommandAfterRecordConfirmed(Response, Context) Export
	If Response = DialogReturnCode.OK Then
		ClearMessages();
		
		WriteMode = DocumentWriteMode.Write;
		If Context.PostingRequired Then
			Context.PostingRequired = False;
			WriteMode = DocumentWriteMode.Posting;
			Context.Form.Modified = True;
		EndIf;
		
		AttachableCommandExecutionParameters = CommonClient.CopyRecursive(Context); // Structure
		AttachableCommandExecutionParameters.Delete("Form");
		Context.Form.AttachableCommandsParameters.Insert("TheCommandIsExecuted");
		Context.Form.Write(New Structure("WriteMode,AttachableCommandExecutionParameters", WriteMode, AttachableCommandExecutionParameters));
		
		If Context.Source.Ref.IsEmpty() Or Context.Form.Modified Then
			Return; // Failed to write, the platform shows an error message.
		EndIf;
	ElsIf Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	If Context.Form.AttachableCommandsParameters.Property("TheCommandIsExecuted") Then
		ContinueCommandExecution(Context)
	EndIf;
EndProcedure

// The procedure branch that is going after the posting confirmation dialog.
Procedure ContinueCommandExecutionAfterConfirmPosting(Response, Context) Export
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	ClearMessages();
	UnpostedDocumentsData = CommonClient.PostDocuments(Context.UnpostedDocuments);
	MessageTemplate = NStr("vi = 'Chứng từ %1 chưa kết chuyển: %2';
							|ru = 'Документ %1 не проведен: %2';
							|en = 'Document %1 is not posted: %2'; fa = 'Document %1 is not posted: %2';
							|it = 'Documento %1 non è registrato: %2';
							|pl = 'Dokument %1 nie jest zaksięgowany: %2';
							|tr = '%1 belgesi kaydedilmedi: %2'");
	UnpostedDocuments = New Array;
	For Each DocumentInformation In UnpostedDocumentsData Do
		CommonClient.MessageToUser(
			StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate,
				String(DocumentInformation.Ref), DocumentInformation.ErrorDescription),
				DocumentInformation.Ref);
		UnpostedDocuments.Add(DocumentInformation.Ref);
	EndDo;
	Context.Insert("UnpostedDocuments", UnpostedDocuments);
	
	Context.ReferencesArrray = CommonClientServer.ArraysDifference(Context.ReferencesArrray, UnpostedDocuments);
	
	// Notifying form opening that the documents were posted.
	PostedDocumentTypes = New Map;
	For Each PostedDocument In Context.ReferencesArrray Do
		PostedDocumentTypes.Insert(TypeOf(PostedDocument));
	EndDo;
	For Each Type In PostedDocumentTypes Do
		NotifyChanged(Type.Key);
	EndDo;
	
	// If the command is called from a form, read the up-to-date (posted) copy from the infobase.
	If TypeOf(Context.Form) = Type("ClientApplicationForm") Then
		If Context.IsObjectForm Then
			Context.Form.Read();
		EndIf;
	EndIf;
	
	If UnpostedDocuments.Count() > 0 Then
		// Asking the user whether the procedure execution must be continued even if there are unposted documents.
		DialogText = NStr("vi = 'Không thể kết chuyển một hoặc nhiều chứng từ.';
							|ru = 'Не удалось провести один или несколько документов.';
							|en = 'Failed to post one or several documents.'; fa = 'Failed to post one or several documents.';
							|it = 'Non è possibile pubblicare uno o più documenti.';
							|pl = 'Nie udało się zaksięgować jeden lub kilka dokumentów.';
							|tr = 'Bir veya birkaç belge onaylanmaz.'");
		
		DialogButtons = New ValueList;
		If Context.ReferencesArrray.Count() = 0 Then
			DialogButtons.Add(DialogReturnCode.Cancel, NStr("vi = 'Đồng ý';
															|ru = 'ОК';
															|en = 'OK'; fa = 'تأیید';
															|it = 'OK';
															|pl = 'OK';
															|tr = 'Tamam'"));
		Else
			DialogText = DialogText + " " + NStr("vi = 'Tiếp tục?';
												|ru = 'Продолжить?';
												|en = 'Continue?'; fa = 'Continue?';
												|it = 'Continuare?';
												|pl = 'Kontynuować?';
												|tr = 'Devam edilsin mi?'");
			DialogButtons.Add(DialogReturnCode.Ignore, NStr("vi = 'Tiếp tục';
															|ru = 'Продолжить';
															|en = 'Continue'; fa = 'ادامه';
															|it = 'Continuare';
															|pl = 'Continue';
															|tr = 'Devam'"));
			DialogButtons.Add(DialogReturnCode.Cancel);
		EndIf;
		
		Handler = New CallbackDescription("ContinueCommandExecutionAfterConfirmContinuation", ThisObject, Context);
		ShowQueryBox(Handler, DialogText, DialogButtons);
		Return;
	EndIf;
	
	ContinueCommandExecution(Context);
EndProcedure

// The procedure branch that is going after the continuation confirmation dialog when unposted documents exist.
Procedure ContinueCommandExecutionAfterConfirmContinuation(Response, Context) Export
	If Response <> DialogReturnCode.Ignore Then
		Return;
	EndIf;
	ContinueCommandExecution(Context);
EndProcedure

// Branch of the procedure that triggers after 1C:Enterprise Extension is installed.
Procedure ContinueCommandExecutionAfterInstall1CEnterpriseExtension(FileSystemExtensionAttached1, Context) Export
	If Not FileSystemExtensionAttached1 Then
		Return;
	EndIf;
	ContinueCommandExecution(Context);
EndProcedure

// Gets a reference from the table row, checks whether the reference meets the type and adds it to the array.
Procedure AddRefToList(FormDataStructure, ReferencesArrray, ParameterType)
	Ref = CommonClientServer.StructureProperty(FormDataStructure, "Ref");
	If ParameterType <> Undefined And Not ParameterType.ContainsType(TypeOf(Ref)) Then
		Return;
	ElsIf Not ValueIsFilled(Ref) Or TypeOf(Ref) = Type("DynamicListGroupRow") Then
		Return;
	EndIf;
	ReferencesArrray.Add(Ref);
EndProcedure

// Generates form parameters of the attached object in the context of the command being executed.
Function FormParameters(Context, CommandParameter)
	Result = Context.CommandDetails.FormParameters;
	If TypeOf(Result) <> Type("Structure") Then
		Result = New Structure;
	EndIf;
	Context.CommandDetails.Delete("FormParameters");
	Result.Insert("CommandDetails", Context.CommandDetails);
	If IsBlankString(Context.CommandDetails.FormParameterName) Then
		Result.Insert("CommandParameter", CommandParameter);
	Else
		NamesArray = StrSplit(Context.CommandDetails.FormParameterName, ".", False);
		Node = Result;
		UBound = NamesArray.UBound();
		For IndexOf = 0 To UBound-1 Do
			Name = TrimAll(NamesArray[IndexOf]);
			If Not Node.Property(Name) Or TypeOf(Node[Name]) <> Type("Structure") Then
				Node.Insert(Name, New Structure);
			EndIf;
			Node = Node[Name];
		EndDo;
		Node.Insert(NamesArray[UBound], CommandParameter);
	EndIf;
	Return Result;
EndFunction

// Refreshes the destination object form when the command has been executed.
Procedure UpdateForm(Context)
	If Context.IsObjectForm And Context.CommandDetails.WriteMode <> "NotWrite" And Not Context.Form.Modified Then
		Try
			Context.Form.Read();
		Except
			// If the Read method is unavailable, printing was executed from a location other than the object form.
		EndTry;
	EndIf;
	If Context.CommandDetails.WriteMode <> "NotWrite" Then
		ModifiedObjectTypes = New Array;
		For Each Ref In Context.ReferencesArrray Do
			Type = TypeOf(Ref);
			If ModifiedObjectTypes.Find(Ref) = Undefined Then
				ModifiedObjectTypes.Add(Ref);
			EndIf;
		EndDo;
		For Each Type In ModifiedObjectTypes Do
			NotifyChanged(Type);
		EndDo;
	EndIf;
EndProcedure

Function SelectedObjects(Source, CommandDetails)
	
	Result = New Array;
	AllowedTypes = CommandDetails.ParameterType;
	
	If TypeOf(Source) = Type("FormDataStructure") Then
		AddRefToList(Source, Result, AllowedTypes);
	ElsIf AllowedTypes <> Undefined And AllowedTypes.ContainsType(TypeOf(Source)) Then
		Result.Add(Source);
	ElsIf TypeOf(Source) = Type("Array") Then
		If AllowedTypes = Undefined Then
			Result = Source;
		Else
			For Each Ref In Source Do
				If AllowedTypes.ContainsType(TypeOf(Ref)) Then
					Result.Add(Ref);
				EndIf;
			EndDo;
		EndIf;
	ElsIf Not CommandDetails.MultipleChoice Then
		If AllowedTypes <> Undefined And AllowedTypes.ContainsType(TypeOf(Source.CurrentRow)) Then
			Result.Add(Source.CurrentRow);
		Else
			AddRefToList(Source.CurrentData, Result, AllowedTypes);
		EndIf;
	Else
		For Each Id In Source.SelectedRows Do
			If AllowedTypes <> Undefined And AllowedTypes.ContainsType(TypeOf(Id)) Then
				Result.Add(Id);
			Else
				AddRefToList(Source.RowData(Id), Result, AllowedTypes);
			EndIf;
		EndDo;
	EndIf;
	
	If Not ValueIsFilled(Result) And CommandDetails.WriteMode <> "NotWrite" Then
		Raise NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng đã chọn.';
					|ru = 'Команда не может быть выполнена для указанного объекта.';
					|en = 'Cannot run the command for the object.'; fa = 'Cannot run the command for the object.';
					|it = 'Il comando non può essere eseguito per l''oggetto indicato.';
					|pl = 'Nie można wykonać polecenia dla określonego obiektu.';
					|tr = 'Komut, belirtilen nesne için yürütülemiyor.'");
	EndIf;
	
	Return Result;
	
EndFunction

Procedure AfterWriteContinued() Export
	
	ParameterName = "StandardSubsystems.AttachableCommands.AttachableCommandExecutionParameters";
	Context = ApplicationParameters[ParameterName];
	ApplicationParameters[ParameterName] = Undefined;
	
	If Context <> Undefined Then
		ContinueCommandExecution(Context);
	EndIf;
	
EndProcedure

#EndRegion
