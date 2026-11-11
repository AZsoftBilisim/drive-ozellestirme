	   
#Region FormEventHandlers
	   
&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Constants.UseBankFeedsService.Set(True);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	RoleIsAvailable_SystemAdministrator  = ExchangeWithBankFeedsServer.HasRoleSystemAdministrator();
	
	SetVisibility1();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	#If WebClient Then
		
		If RoleIsAvailable_SystemAdministrator Then
			Items.KeyStorageCatalog.Visible = True; 
			Items.UploadKey.Visible = True;
		EndIf;	
		
	#EndIf
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	If Not Object.TestMode 
			And Not ValueIsFilled(Object.PathToCertificate) Then
		
		Cancel = True;
		
		Text = NStr("vi = 'Chưa điền trường ""Đường dẫn đến khóa đóng"".';
					|ru = 'Поле ""Путь к закрытому ключу"" не заполнен.';
					|en = 'The ""Private key path"" field is empty.'; fa = 'The ""Private key path"" field is empty.';
					|it = 'Поле ""Путь к закрытому ключу"" не заполнен.';
					|pl = 'The ""Private key path"" field is empty.';
					|tr = '""Özel Anahtar Yolu"" alanı doldurulmamış.'");
		Common.MessageToUser(
			Text,,
			"PathToCertificate",,
			Cancel);
			
	EndIf;	
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure TestModeOnChange(Item)

	SetVisibility1();
	Object.PathToCertificate = "";
		
	#If WebClient Then
		
		Items.KeyStorageCatalog.Visible = True; 
		Items.UploadKey.Visible = True;
		
	#EndIf
		
EndProcedure

&AtClient
Procedure PathToCertificateStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	OpenFileDialog = New FileDialog(FileDialogMode.Open);
	OpenFileDialog.Filter = NStr("vi = 'Tệp khóa đóng (*.pem)|*.pem';
								|ru = 'Файл закрытого ключа (*.pem)|*.pem';
								|en = 'Private key file (*.pem)|*.pem'; fa = 'Private key file (*.pem)|*.pem';
								|it = 'Файл закрытого ключа (*.pem)|*.pem';
								|pl = 'Private key file (*.pem)|*.pem';
								|tr = 'Özel anahtar dosyası (*.pem)|*.pem'");
	
	AdditionalParameters = New Structure;
	
	ChoiceNotification = New CallbackDescription("FileSelected", ThisObject, AdditionalParameters);
	
	FileSystemClient.ShowSelectionDialog(ChoiceNotification, OpenFileDialog);
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TestConnection(Command)

	If Not CheckFilling() Then
		Return;
	EndIf;	

	If Not ValueIsFilled(Object.Ref) 
		Or Modified Then
		
		QueryText = NStr("vi = 'Vẫn chưa ghi lại dữ liệu.
							|Chỉ có thể thực hiện thao tác sau khi ghi lại dữ liệu.
							|Ghi lại phần tử?';
							|ru = 'Данные еще не записаны.
							|Выполнение действия возможно только после записи данных.
							|Записать элемент?';
							|en = 'You have unsaved data.
							|You can perform the action only after you save the data.
							|Do you want to save the item?'; fa = 'You have unsaved data.
							|You can perform the action only after you save the data.
							|Do you want to save the item?';
							|it = 'Данные еще не записаны.
							|Выполнение действия возможно только после записи данных.
							|Записать элемент?';
							|pl = 'You have unsaved data.
							|You can perform the action only after you save the data.
							|Do you want to save the item?';
							|tr = 'Veriler henüz kaydedilmedi.
							|İşlemin yürütülmesi sadece veriler kaydedildikten sonra mümkündür.
							|Öğe kaydedilsin mi?'");
			
		ShowQueryBox(New CallbackDescription("ObjectIsNotRecordedEnd", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
		
	Else
		
		SendConnectionVerificationRequest();
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure UploadKey(Command)
	
	If Not ValueIsFilled(Object.KeyStorageCatalog) Then
		
		Text = NStr("vi = 'Chưa điền trường ""Thư mục lưu khóa trên server""';
					|ru = 'Поле ""Каталог хранения ключей на сервере"" не заполнен';
					|en = 'The ""Key storage directory on server"" field is empty'; fa = 'The ""Key storage directory on server"" field is empty';
					|it = 'Поле ""Каталог хранения ключей на сервере"" не заполнен';
					|pl = 'The ""Key storage directory on server"" field is empty';
					|tr = '“""Sunucudaki anahtar depolama kataloğu"" alanı doldurulmamış'");
		CommonClient.MessageToUser(
			Text,,
			"KeyStorageCatalog",,
			);
		
		Return;
	EndIf;	
	
	AdditionalParameters = New Structure();      
	FileName = "private.pem";
	
	CompletionNotification = New CallbackDescription("SelectAndSendFileToServerAfterChoiceInDialogCompletion", 
					ThisObject, AdditionalParameters);

	ImportParameters = FileSystemClient.FileImportParameters();
	ImportParameters.Dialog.Filter = NStr("vi = 'Khóa đóng(*.pem;)|*.pem';
											|ru = 'Закрытый ключ(*.pem;)|*.pem';
											|en = 'Private key(*.pem;)|*.pem'; fa = 'Private key(*.pem;)|*.pem';
											|it = 'Закрытый ключ(*.pem;)|*.pem';
											|pl = 'Private key(*.pem;)|*.pem';
											|tr = 'Özel anahtar (*.pem;)|*.pem'");
	ImportParameters.FormIdentifier = UUID;
	
	FileSystemClient.ImportFile_(CompletionNotification, ImportParameters, FileName);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SaveFileAtServer(Result)
	If Result.Location = Undefined Then 
		Return;
	EndIf;	
	
    BinaryFile = GetFromTempStorage(Result.Location);
	
	KeyStorageCatalog = CommonClientServer.AddLastPathSeparator(Object.KeyStorageCatalog);
	ParametersOfPath = CommonClientServer.ParseFullFileName(Result.Name, False);
	FileName = ParametersOfPath.Name;
	
	BinaryFile.Write(KeyStorageCatalog + FileName);	
	
	Object.PathToCertificate = KeyStorageCatalog + FileName;
	
EndProcedure

&AtClient
Procedure SelectAndSendFileToServerAfterChoiceInDialogCompletion(FileThatWasPut, AdditionalParameters) Export
	
	If FileThatWasPut = Undefined Then
		Return;
	EndIf;
	
	Result  = New Structure("Name, Location");
	Result.Name      = FileThatWasPut.Name;
	Result.Location = FileThatWasPut.Location;
	
	//We save it on the server  
	SaveFileAtServer(Result);   
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ObjectIsNotRecordedEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		Write();   
		SendConnectionVerificationRequest();
	EndIf;
	
EndProcedure   

&AtClient
Procedure SendConnectionVerificationRequest()
	
	FillParameters = New Structure();
	FillParameters.Insert("ServiceSettings", Object.Ref);

	ExchangeWithBankFeedsServiceClient.CheckServiceConnection(FillParameters, ThisObject);	
	
EndProcedure	

&AtClient
Procedure FileSelected(SelectedFiles, AdditionalParameters) Export
	
	If Not ValueIsFilled(SelectedFiles) Then
		Return;
	EndIf;
	
	Object.PathToCertificate = SelectedFiles[0];
	
EndProcedure

&AtServer
Procedure SetVisibility1()

	If Not RoleIsAvailable_SystemAdministrator Then

		Items.PathToCertificate.Visible = False;
		Items.DescriptionOfRequirementsForOperationOfTestMode.Visible = False;;
		Items.KeyStorageCatalog.Visible = False;;
		Items.UploadKey.Visible = False;
		Items.TestMode.Visible = False;
		Items.AppID.Visible = False;
		Items.Secret.Visible = False;
		Items.DescriptionOfRequirementsForOperationOfTestMode.Visible = False;
		
		Return;
	
	EndIf;

	Items.PathToCertificate.Enabled = Not Object.TestMode;
	Items.PathToCertificate.AutoMarkIncomplete = Not Object.TestMode;	
	Items.DescriptionOfRequirementsForOperationOfTestMode.Enabled = Not Object.TestMode;
	Items.KeyStorageCatalog.Enabled = Not Object.TestMode;
	Items.UploadKey.Enabled = Not Object.TestMode;
	
	If Common.FileInfobase() Then
		
		Items.KeyStorageCatalog.Visible = False; 
		Items.UploadKey.Visible = False;
		
	Else	
		Items.PathToCertificate.ChoiceButton = False;
		
	EndIf
	
EndProcedure	

#EndRegion


