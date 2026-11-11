#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing);  
	
	FileFormat = "PDF";
	AccountingObject = Parameters.AccountingObject;
	FillInListOfContractTemplates(AccountingObject);


EndProcedure  

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)  
	
	Template = Items.ContractTemplates.CurrentData;
	
	If Template = Undefined Then
		ShowMessageBox(, NStr("vi = 'Chưa chọn mẫu nào!
			|Để tùy chỉnh, hãy chuyển đến phân hệ ""Danh mục và quản trị""- 
			| - ""Quản trị"" - 
			|""Mẫu in, báo cáo và bộ xử lý"" - 
			|""Khuôn mẫu in"".';
			|ru = 'Не выбрано ни одного шаблона!
			|Для настройки перейдите в раздел ""НСИ и администрирование""- 
			| - ""Администрирование"" - 
			| - ""Печатные формы, отчеты и обработки"" - 
			| - ""Макеты печатных форм"".';
			|en = 'No templates are selected.
			|To configure, go to Master data and settings - 
			| - Administration - 
			| - Print forms, reports, and data processors - 
			| - Print form templates.'; fa = 'No templates are selected.
			|To configure, go to Master data and settings - 
			| - Administration - 
			| - Print forms, reports, and data processors - 
			| - Print form templates.';
			|it = 'Не выбрано ни одного шаблона!
			|Для настройки перейдите в раздел ""НСИ и администрирование""- 
			| - ""Администрирование"" - 
			| - ""Печатные формы, отчеты и обработки"" - 
			| - ""Макеты печатных форм"".';
			|pl = 'No templates are selected.
			|To configure, go to Master data and settings - 
			| - Administration - 
			| - Print forms, reports, and data processors - 
			| - Print form templates.';
			|tr = 'Hiçbir şablon seçili değil! 
			| Ayarları yapılandırmak için “NSI ve Yönetim”- 
			| - “Yönetim” - 
			| - “Formları, Raporları ve İşlemleri Yazdır” - 
			| - “Form Düzenlerini Yazdır” bölümüne gidin.'"));
		Return;
	EndIf;
	
	If FileFormat = "PDF" Then
				
		TimeConsumingOperation = StartSavingPDFTemplateFile(Template.Value);
		CallbackOnCompletion = New CallbackDescription("AtEndOfSavingPDFFile", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters()); 	
	
	EndIf;
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInListOfContractTemplates(LinkToContract) 
	
	If Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Return;
	EndIf;
	
	ModulePrintManager = Common.CommonModule("PrintManagement");
	
	ListOfObjects = New Array;
	ListOfObjects.Add(AccountingObject.Metadata());
	
	PrintCommands = ModulePrintManager.FormPrintCommands("Catalog.CounterpartyContracts.Form.ItemForm", ListOfObjects);
	
	For Each PrintForm In PrintCommands Do
		ContractTemplates.Add(PrintForm.Id, PrintForm.Presentation);
	EndDo; 
		
EndProcedure 


&AtServer
Function StartSavingPDFTemplateFile(Id)
	
	If Not Common.SubsystemExists("StandardSubsystems.Print") Then
		Return Undefined;
	EndIf;
	
	ModulePrintManager = Common.CommonModule("PrintManagement");
	
	ListOfObjects = New Array;
	ListOfObjects.Add(AccountingObject.Metadata());
	
	PrintCommands = ModulePrintManager.FormPrintCommands("Catalog.CounterpartyContracts.Form.ItemForm", ListOfObjects);		
	TemplateCommand = PrintCommands.FindRows(New Structure("Id", Id));
	
	ListOfObjects = New Array;
	ListOfObjects.Add(AccountingObject);	
   
	Result = Common.ValueTableRowToStructure(TemplateCommand[0]);
	
	StorageUUID = New UUID;
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(StorageUUID);
	ExecutionParameters.RunInBackground = True;
	Return TimeConsumingOperations.ExecuteFunction(ExecutionParameters, "PrintManagement.PrintToFile",
		Result, ListOfObjects, PrintManagement.SettingsForSaving());	
		
EndFunction

&AtClient
Function IdleParameters()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisForm);
	IdleParameters.MessageText = NStr("vi = 'Chuẩn bị mẫu in.';
										|ru = 'Подготовка печатных форм.';
										|en = 'Preparing print forms.'; fa = 'Preparing print forms.';
										|it = 'Подготовка печатных форм.';
										|pl = 'Preparing print forms.';
										|tr = 'Yazdırma formların hazırlanması.'");
	IdleParameters.UserNotification.Show = False;
	IdleParameters.OutputIdleWindow = True;
	IdleParameters.Interval = 0;
	IdleParameters.OutputMessages = False;
	Return IdleParameters;

EndFunction

&AtClient
Procedure AtEndOfSavingPDFFile(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		If Result.Status = "Error" Then
			Raise Result.BriefErrorDescription;
		EndIf;
		
		BackgroundOperationResult = GetResultOfBackgroundJobSavingPDFFile(Result);
		
		FileParameters = GetParametersForAddingFile();
		FileParameters.FilesOwner = AccountingObject;
		FileParameters.Author = UsersClient.CurrentUser();

		FileParameters.BaseName = BackgroundOperationResult.FileName;
		Address = PutToTempStorage(BackgroundOperationResult.BinaryData);
						
		FileRef = AddFileToContract(FileParameters, Address);
	EndIf; 

	Notify("Write_File");
	Close();

EndProcedure

	
&AtServer
Function GetResultOfBackgroundJobSavingPDFFile(Result)
	
	BackgroundOperationResult = GetFromTempStorage(Result.ResultAddress);
	
	ResultStructure1 = New Structure("FileName, BinaryData");
	ResultStructure1.FileName = BackgroundOperationResult[0].FileName;
	ResultStructure1.BinaryData = BackgroundOperationResult[0].BinaryData;
		
	Return ResultStructure1;
	
EndFunction


&AtServer
Function GetParametersForAddingFile()
	
	Return	FilesOperations.FileAddingOptions();
	
EndFunction

&AtServer
Function AddFileToContract(FileParameters, Address)

	FileRef = FilesOperations.AppendFile(FileParameters, Address);

	Return FileRef;
	
EndFunction

#EndRegion