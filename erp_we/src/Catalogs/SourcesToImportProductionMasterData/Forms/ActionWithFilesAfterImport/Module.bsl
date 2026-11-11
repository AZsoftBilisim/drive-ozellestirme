
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ActionDetails = Undefined;
	If Not Parameters.Property("ActionDetails", ActionDetails) Then
		ActionDetails = ProductDataManagementClientServer.DescriptionOfActionWithConstructorFiles();
	Else
		Title = StrTemplate(NStr("vi = '%1 đối với trạng thái ""%2""';
								|ru = '%1 для состояния ""%2""';
								|en = '%1 for the ""%2"" state'; fa = '%1 for the ""%2"" state';
								|it = '%1 для состояния ""%2""';
								|pl = '%1 for the ""%2"" state';
								|tr = '""%2"" durumu için %1'"), Title, ActionDetails.State);
	EndIf;
	
	Parameters.Property("LocationOfData", LocationOfData);
	
	Action = ActionDetails.Action;
	If MoveAction(ThisObject) Then
		MovingDirectory = ActionDetails.Directory;
	Else
		MovingDirectory = LocationOfData;
	EndIf;
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		StandardProcessing = False;
		Cancel = True;
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'The data was changed. Do you want to save the changes?'; fa = 'The data was changed. Do you want to save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ActionOnChange(Item)
	
	Modified = True;
	
	ConfigureDependentFormElements(ThisObject, "Action")
	
EndProcedure

&AtClient
Procedure MovingDirectoryOnChange(Item)
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure MovingDirectoryStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	ChoiceDialog = New FileDialog(FileDialogMode.ChooseDirectory);
	ChoiceDialog.Multiselect = False;
	ChoiceDialog.Directory = MovingDirectory;
	ChoiceDialog.Title = NStr("vi = 'Hãy chọn thư mục vị trí tệp có dữ liệu';
								|ru = 'Выберите каталог расположения файлов с данными';
								|en = 'Select a data file directory'; fa = 'Select a data file directory';
								|it = 'Выберите каталог расположения файлов с данными';
								|pl = 'Select a data file directory';
								|tr = 'Veri dosyalarının konum dizinini seçin'");
	CallbackDescription = New CallbackDescription("MovingDirectoryStartChoiceCompletion", ThisObject);
	
	FileSystemClient.ShowSelectionDialog(CallbackDescription, ChoiceDialog);
	
EndProcedure


#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	//

	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Action")
		Or Initialize Then
			
			Items.MovingDirectory.Enabled = MoveAction(Form);
			Items.MovingDirectory.AutoMarkIncomplete = MoveAction(Form);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure MovingDirectoryStartChoiceCompletion(Result, AdditionalParameters) Export
	
	If ValueIsFilled(Result) Then
		MovingDirectory = Result[0];
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing()
	
	Cancel = False;
	
	If MoveAction(ThisObject) Then
		
		If IsBlankString(MovingDirectory) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Cần chỉ ra thư mục để di chuyển tệp';
					|ru = 'Необходимо указать каталог для перемещения файлов';
					|en = 'Specify a directory to move files'; fa = 'Specify a directory to move files';
					|it = 'Необходимо указать каталог для перемещения файлов';
					|pl = 'Specify a directory to move files';
					|tr = 'Dosyaları taşımak için dizin belirtmeniz gerekmektedir'"),,
				"MovingDirectory",,
				Cancel);
		EndIf;
		
		If Lower(CommonClientServer.AddLastPathSeparator(LocationOfData)) =
				Lower(CommonClientServer.AddLastPathSeparator(MovingDirectory)) Then
			CommonClient.MessageToUser(
				NStr("vi = 'Thư mục gốc vị trí tệp trùng với thư mục để di chuyển';
					|ru = 'Исходный каталог расположения файлов совпадает с каталогом для перемещения';
					|en = 'The source file directory is the same as the directory for moving files'; fa = 'The source file directory is the same as the directory for moving files';
					|it = 'Исходный каталог расположения файлов совпадает с каталогом для перемещения';
					|pl = 'The source file directory is the same as the directory for moving files';
					|tr = 'Dosya konumunun kaynak dizini taşınacak dizinle aynıdır'"),,
				"MovingDirectory",,
				Cancel);
		EndIf;
		
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	
	ActionDetails.Action = Action;
	ActionDetails.Directory  = ?(MoveAction(ThisObject), MovingDirectory, "");
	
	Close(ActionDetails)
	
EndProcedure

&AtClientAtServerNoContext
Function MoveAction(Form)
	
	Return Form.Action = PredefinedValue("Enum.ImportMasterDataActionsWithFiles.MoveTo");
	
EndFunction

#EndRegion