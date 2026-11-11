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
	
	IsNewGroup = Parameters.IsNewGroup;
	If IsNewGroup Then
		
		ObjectValue = Catalogs[Parameters.FilesStorageCatalogName].CreateFolder();
		If Parameters.Parent <> Undefined
			And TypeOf(Parameters.Parent) = TypeOf(ObjectValue.Ref) Then
			
			ParentProperties = Common.ObjectAttributesValues(Parameters.Parent, "IsFolder,Parent");
			If ParentProperties.IsFolder Then
				ObjectValue.Parent = Parameters.Parent;
			ElsIf ParentProperties.Parent <> Undefined
				And TypeOf(ParentProperties.Parent) = TypeOf(ObjectValue.Ref) Then
				
				ObjectValue.Parent = ParentProperties.Parent; // As the first parent, the reference to the item was passed.
			EndIf;
			
		Else
			ObjectValue.Parent = Undefined;
		EndIf;
		
		ObjectValue.FileOwner = Parameters.FileOwner;
		ObjectValue.CreationDate  = CurrentSessionDate();
		ObjectValue.Author         = Users.AuthorizedUser();
		ObjectValue.ChangedBy       = ObjectValue.Author;
		
	ElsIf ValueIsFilled(Parameters.CopyingValue) Then
		
		ObjectToCopy        = Parameters.CopyingValue.GetObject();
		ObjectValue          = Catalogs[ObjectToCopy.Metadata().Name].CreateFolder();
		ObjectValue.Parent = Parameters.Parent;
		
		FillPropertyValues(ObjectValue, ObjectToCopy,
			"FileOwner, CreationDate, LongDesc, Description, UniversalModificationDate, ChangedBy");
		
		ObjectValue.Author = Users.AuthorizedUser();
		
	Else
		
		If ValueIsFilled(Parameters.AttachedFile) Then
			ObjectValue = Parameters.AttachedFile.GetObject();
		ElsIf ValueIsFilled(Parameters.Key) Then
			ObjectValue = Parameters.Key.GetObject();
		Else
			Raise NStr("vi = 'Không thể tạo nhóm tệp trực tiếp.';
						|ru = 'Не предусмотрено непосредственное создание группы файлов.';
						|en = 'You cannot create a file group.'; fa = 'You cannot create a file group.';
						|it = 'Не предусмотрено непосредственное создание группы файлов.';
						|pl = 'You cannot create a file group.';
						|tr = 'Doğrudan dosya grubu oluşturulamaz.'");
		EndIf;
		
	EndIf;
	ObjectValue.Fill(Undefined);
	
	CatalogName = ObjectValue.Metadata().Name;
	
	SetUpFormObject(ObjectValue);
	
	If ReadOnly
		Or Not AccessRight("Update", ThisObject.Object.FileOwner.Metadata()) Then
		
		Items.FormStandardWrite.Enabled                  = False;
		Items.FormStandardSaveAndClose.Enabled          = False;
		Items.FormStandardMarkForDeletion.Enabled = False;
		
	EndIf;
	
	If Not ReadOnly
		And Not CurrentRefToFileServer().IsEmpty() Then
		
		LockDataForEdit(CurrentRefToFileServer(), , UUID);
	EndIf;
	
	RefreshTitle();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		
		Cancel = True;
		ResponseNotification = New CallbackDescription("CloseFormAfterAnswerQuestion", ThisObject);
		ShowQueryBox(ResponseNotification, NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
												|ru = 'Данные были изменены. Сохранить изменения?';
												|en = 'The data has been changed. Do you want to save the changes?'; fa = 'The data has been changed. Do you want to save the changes?';
												|it = 'I dati sono stati modificati. Salvare le modifiche?';
												|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
												|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'"), QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure StandardWrite(Command)
	HandleFileRecordCommand();
EndProcedure

&AtClient
Procedure StandardSaveAndClose(Command)
	
	If HandleFileRecordCommand() Then
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure StandardReread(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	If Not Modified Then
		RereadDataFromServer();
		Return;
	EndIf;
	
	QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Đọc lại dữ liệu?';
					|ru = 'Данные изменены. Перечитать данные?';
					|en = 'The data has been changed. Do you want to refresh the data?'; fa = 'The data has been changed. Do you want to refresh the data?';
					|it = 'I dati sono stati modificati. Rileggere i dati?';
					|pl = 'Dane zostały zmienione. Przeliczyć dane?';
					|tr = 'Veri değişti. Tekrar okunsun mu?'");
	
	CallbackDescription = New CallbackDescription("StandardRereadAnswerReceived", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure StandardCopy(Command)
	
	If IsNew() Then
		Return;
	EndIf;
	
	FormParameters = New Structure("CopyingValue", CurrentRefToFile());
	OpenForm("DataProcessor.FilesOperations.Form.FilesGroup", FormParameters);
	
EndProcedure

&AtClient
Procedure StandardShowInList(Command)
	
	StandardSubsystemsClient.ShowInList(CurrentRefToFile(), Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetUpFormObject(Val NewObject)
	
	NewObjectType = New Array;
	NewObjectType.Add(TypeOf(NewObject));
	
	NewAttribute = New FormAttribute("Object", New TypeDescription(NewObjectType));
	NewAttribute.StoredData = True;
	
	AttributesToBeAdded = New Array;
	AttributesToBeAdded.Add(NewAttribute);
	
	ChangeAttributes(AttributesToBeAdded);
	
	ValueToFormAttribute(NewObject, "Object");
	
	For Each Item In Items Do
		If TypeOf(Item) = Type("FormField")
			And StrStartsWith(Item.DataPath, "PrototypeObject[0].")
			And StrEndsWith(Item.Name, "0") Then
			
			TagName = Left(Item.Name, StrLen(Item.Name) -1);
			If Items.Find(TagName) <> Undefined Then
				Continue;
			EndIf;
			
			NewItem = Items.Insert(TagName, TypeOf(Item), Item.Parent, Item);
			NewItem.DataPath = "Object." + Mid(Item.DataPath, StrLen("PrototypeObject[0].") + 1);
			
			If Item.Type = FormFieldType.LabelField Then
				PropertiesToExclude = "Name, DataPath";
			Else
				PropertiesToExclude = "Name, DataPath, SelectedText, TypeLink";
			EndIf;
			FillPropertyValues(NewItem, Item, , PropertiesToExclude);
			
			Item.Visible = False;
		EndIf;
	EndDo;
	
	CreatedStatus = StringFunctions.FormattedString(NStr("vi = '<a href=""%1"">%2</a>';
														|ru = '<a href=""%1"">%2</a>';
														|en = '<a href=""%1"">%2</a>'; fa = '<a href=""%1"">%2</a>';
														|it = '<a href=""%1"">%2</a>';
														|pl = '<a href=""%1"">%2</a>';
														|tr = '<a href=""%1"">%2</a>'"),
		GetURL(ThisObject["Object"].Author), String(ThisObject["Object"].Author));
	
	RefreshInformationAboutChange();
	
	If Parameters.Parent <> Undefined
			And TypeOf(Parameters.Parent) = TypeOf(NewObject.Ref) Then
		NewObject.Parent = Parameters.Parent;
	EndIf;
	
	If Not NewObject.IsNew() Then
		URL = GetURL(NewObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure RefreshTitle()
	
	CurrentRefToFile = CurrentRefToFileServer();
	If ValueIsFilled(CurrentRefToFile) Then
		Title = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = '%1 (Nhóm tệp)';
				|ru = '%1 (Группа файлов)';
				|en = '%1 (File group)'; fa = '%1 (File group)';
				|it = '%1 (Gruppo di file)';
				|pl = '%1 (Grupa plików)';
				|tr = '%1 (Dosya grubu)'"), String(CurrentRefToFile));
	Else
		Title = NStr("vi = 'Nhóm tệp (Tạo mới)';
					|ru = 'Группа файлов (Создание)';
					|en = 'File group (Create)'; fa = 'File group (Create)';
					|it = 'Gruppo di file (Creazione)';
					|pl = 'Grupa plików (Tworzenie)';
					|tr = 'Dosya grubu (Oluştur)'")
	EndIf;
	
EndProcedure

&AtClient
Function HandleFileRecordCommand()
	
	ClearMessages();
	
	If IsBlankString(ThisObject.Object.Description) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Để tiếp tục, hãy chỉ ra tên tệp.';
				|ru = 'Для продолжения укажите имя файла.';
				|en = 'To proceed, please provide the file name.'; fa = 'To proceed, please provide the file name.';
				|it = 'Per continuare indicate il nome del file.';
				|pl = 'Aby kontynuować, wskaż nazwę pliku.';
				|tr = 'Devam etmek için dosya adını belirtin.'"), , "Description", "Object");
		Return False;
	EndIf;
	
	Try
		FilesOperationsInternalClient.CorrectFileName(ThisObject.Object.Description);
	Except
		CommonClient.MessageToUser(
			ErrorProcessing.BriefErrorDescription(ErrorInfo()), ,"Description", "Object");
		Return False;
	EndTry;
	
	If Not WriteFile() Then
		Return False;
	EndIf;
	
	Modified = False;
	RepresentDataChange(ThisObject.Object.Ref, DataChangeType.Update);
	NotifyChanged(ThisObject.Object.Ref);
	FileWriteNotificationParameters = FilesOperationsInternalClient.FileWriteNotificationParameters();
	FileWriteNotificationParameters.IsNew = FileCreated;
	Notify("Write_File", FileWriteNotificationParameters, ThisObject.Object.Ref);
	
	Return True;
	
EndFunction

&AtClient
Function IsNew()
	
	Return CurrentRefToFile().IsEmpty();
	
EndFunction

&AtServer
Function WriteFile(Val ParameterObject = Undefined)
	
	If ParameterObject = Undefined Then
		ObjectToWrite = FormAttributeToValue("Object"); //CatalogObject
	Else
		ObjectToWrite = ParameterObject;
	EndIf;
	
	BeginTransaction();
	Try
		ObjectToWrite.ChangedBy                      = Users.AuthorizedUser();
		ObjectToWrite.UniversalModificationDate = CurrentUniversalDate();
		ObjectToWrite.Write();
		
		CommitTransaction();
	Except
		
		RollbackTransaction();
		WriteLogEvent(NStr("vi = 'Tệp.Lỗi ghi nhóm tệp đính kèm';
							|ru = 'Файлы.Ошибка записи группы присоединенных файлов';
							|en = 'Files.Error writing group of attachments'; fa = 'Files.Error writing group of attachments';
							|it = 'I file.Errore di scrittura del gruppo file allegati';
							|pl = 'Pliki.Błąd zapisu grupy załączników';
							|tr = 'Dosyalar. Ekli dosyalar grubunun kayıt hatası'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()) );
		Raise;
		
	EndTry;
	
	If ParameterObject = Undefined Then
		ValueToFormAttribute(ObjectToWrite, "Object");
	EndIf;
	
	RefreshTitle();
	RefreshInformationAboutChange();
	
	Return True;
	
EndFunction

&AtClient
Procedure StandardRereadAnswerReceived(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		RereadDataFromServer();
		Modified = False;
	EndIf;
	
EndProcedure

&AtServer
Procedure RereadDataFromServer()
	
	FileObject1 = CurrentRefToFileServer().GetObject();
	ValueToFormAttribute(FileObject1, "Object");
	
	RefreshInformationAboutChange();

EndProcedure

&AtServer
Procedure RefreshInformationAboutChange()
	
	ChangedStatus = StringFunctions.FormattedString(NStr("vi = '<a href=""%1"">%2</a>';
														|ru = '<a href=""%1"">%2</a>';
														|en = '<a href=""%1"">%2</a>'; fa = '<a href=""%1"">%2</a>';
														|it = '<a href=""%1"">%2</a>';
														|pl = '<a href=""%1"">%2</a>';
														|tr = '<a href=""%1"">%2</a>'"),
		GetURL(ThisObject.Object.ChangedBy), String(ThisObject.Object.ChangedBy));
	
EndProcedure

&AtClient
Procedure CloseFormAfterAnswerQuestion(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes
		And HandleFileRecordCommand() Then
		Close();
	ElsIf Response = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Function CurrentRefToFile()
	
	FormObject = ThisObject.Object; // CatalogObject
	Return FormObject.Ref;
	
EndFunction

&AtServer
Function CurrentRefToFileServer()

	FormObject = ThisObject.Object; // CatalogObject
	Return FormObject.Ref;

EndFunction

#EndRegion