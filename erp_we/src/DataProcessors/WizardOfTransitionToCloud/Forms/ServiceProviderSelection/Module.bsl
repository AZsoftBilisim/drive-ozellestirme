
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ServiceAddress = Parameters.CloudServiceAddress;
	DataProcessorObject = FormAttributeToValue("Object");
	QueryOptions = New Structure;
	QueryOptions.Insert("Key", UUID);
	QueryOptions.Insert("Address", ServiceAddress);
	QueryOptions.Insert("ServiceAddress", ServiceAddress);
	QueryOptions.Insert("Method", "search-terms");
	
	ResultAddress = PutToTempStorage(Undefined, UUID);
	Result = DataProcessorObject.GetData(QueryOptions, ResultAddress);
	If Result.Error Then
		Items.SearchErrorGroup.Visible = True;
		Items.ErrorText.Title = StringFunctions.FormattedString(
			NStr("vi = '<b>Lỗi trong tùy chỉnh dịch vụ</b>
			|Hãy liên hệ với nhà cung cấp dịch vụ để khắc phục lỗi.
			|
			|Nội dung lỗi:
			|%1';
			|ru = '<b>Ошибка в настройках сервиса</b>
			|Обратитесь к провайдеру сервиса для устранения ошибки.
			|
			|Текст ошибки:
			|%1';
			|en = '<b>An error occurred in the service settings</b>
			|Contact the service owner to fix it.
			|
			|Error text:
			|%1'; fa = '<b>An error occurred in the service settings</b>
			|Contact the service owner to fix it.
			|
			|Error text:
			|%1';
			|it = '<b>Ошибка в настройках сервиса</b>
			|Обратитесь к провайдеру сервиса для устранения ошибки.
			|
			|Текст ошибки:
			|%1';
			|pl = '<b>An error occurred in the service settings</b>
			|Contact the service owner to fix it.
			|
			|Error text:
			|%1';
			|tr = '<b>Hizmet ayarlarında hata</b>
			|Hatayı çözmek için servis sağlayıcıyla iletişime geçin.
			|
			|Hata metni:
			|%1'"), Result.ErrorMessage);
		Items.SearchBar_3.Visible = False;
		Items.Pages.Visible = False;
		Return;
	EndIf; 
	
	ChoiceList = Items.SearchCriteria.ChoiceList;
	For Each Item In Result.Data.searchTerms Do
		ChoiceList.Add(Item.id, Item.name);
	EndDo;
	
	If ChoiceList.Count() > 0 Then
		SearchCriteria = ChoiceList[0].Value;
	EndIf; 
	Items.SearchValue.Enabled = Not SearchCriteria = SearchCriteriaAll();
	
	QueryOptions.Insert("Method", "support-companies");
	StartBackgroundJobOnServer("GetData", QueryOptions, StorageAddress, JobID);	
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("CheckDataReceipt", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SearchCriteriaOnChange(Item)
	
	Items.SearchValue.Enabled = Not SearchCriteria = SearchCriteriaAll();
	If SearchCriteria = SearchCriteriaAll() Then
		SearchValue = "";
		StartSearchingForBusinesses();
	EndIf; 
	
EndProcedure

#EndRegion 

#Region FormTableItemsEventHandlersServiceCompanies

&AtClient
Procedure ServiceCompaniesSelection(Item, RowSelected, Field, StandardProcessing)

	If Field.Name = "ServiceCompaniesWebsite1" Then
		StandardProcessing = False;
		LinkToWebsite = Items.ServiceCompanies.CurrentData.Website1;
		GotoURL(?(Left(LinkToWebsite, 4) = "http", LinkToWebsite, StrTemplate("http://%1", LinkToWebsite)));
		Return;
	EndIf; 
	
	ChoiceData = Items.ServiceCompanies.CurrentData;
	SelectionResult = New Structure("Description, Code, City, Phone, Mail, Website1");
	FillPropertyValues(SelectionResult, ChoiceData);
	Close(SelectionResult);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure FindOrganizations(Command)
	
	StartSearchingForBusinesses();

EndProcedure

#EndRegion 

#Region Private

&AtClient
Procedure StartSearchingForBusinesses()
	
	Items.Pages.CurrentPage = Items.PageWait;
	QueryOptions = New Structure;
	QueryOptions.Insert("Key", UUID);
	QueryOptions.Insert("Address", ServiceAddress);
	QueryOptions.Insert("ServiceAddress", ServiceAddress);
	QueryOptions.Insert("SearchCriteria", SearchCriteria);
	QueryOptions.Insert("SearchValue", SearchValue);
	StartSearchQuery(QueryOptions, StorageAddress, JobID);
	AttachIdleHandler("CheckDataReceipt", 1, True);

EndProcedure

&AtServerNoContext
Procedure StartSearchQuery(QueryOptions, StorageAddress, JobID)
	
	QueryOptions.Insert("Method", StrTemplate("support-companies?term=%1&value=%2", 
		QueryOptions.SearchCriteria, QueryOptions.SearchValue));
	StartBackgroundJobOnServer("GetData", QueryOptions, StorageAddress, JobID);	
	
EndProcedure
	
&AtServerNoContext
Procedure StartBackgroundJobOnServer(MethodName, QueryOptions, StorageAddress, JobID)
	
	ProcessingParameters_ = New Structure;
	ProcessingParameters_.Insert("Address", QueryOptions.ServiceAddress);
	ProcessingParameters_.Insert("Method", QueryOptions.Method);
	
	DataProcessorName = "WizardOfTransitionToCloud";
	
	JobParameters = New Structure;
	JobParameters.Insert("DataProcessorName", DataProcessorName);
	JobParameters.Insert("MethodName", MethodName);
	JobParameters.Insert("ExecutionParameters", ProcessingParameters_);
	JobParameters.Insert("IsExternalDataProcessor", False);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(QueryOptions.Key);
	ExecutionParameters.BackgroundJobDescription = StrTemplate("WizardOfTransitionToCloud.%1", MethodName);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.Insert("FormIdentifier", QueryOptions.Key); 
	
	MethodToExecute = "TimeConsumingOperations.RunDataProcessorObjectModuleProcedure"; // We perform the procedure from the object module
	Result =  TimeConsumingOperations.ExecuteInBackground(MethodToExecute, JobParameters, ExecutionParameters);
	
	StorageAddress = Result.ResultAddress;
	JobID = Result.JobID;
	
EndProcedure

&AtClient
Procedure CheckDataReceipt()
	
	If Not CheckDataReceptionOnServer() Then
		AttachIdleHandler("CheckDataReceipt", 1, True);
	Else
		Items.Pages.CurrentPage = Items.ListPage;
	EndIf;
	
EndProcedure

&AtServer
Function CheckDataReceptionOnServer()
	
	Result = CheckQueryResultOnServer(JobID, StorageAddress);
	If Result = Undefined Then
		Return False;
	Else
		FillForm(Result);
		Return True;
	EndIf; 
	
EndFunction

&AtServer
Procedure FillForm(Result)
	
	ServiceCompanies.Clear();
	If Result.Error Then
		Items.SearchErrorGroup.Visible = True;
		Items.ErrorText.Title = StringFunctions.FormattedString(
			NStr("vi = '<b>Lỗi trong tùy chỉnh dịch vụ</b>
			|Hãy liên hệ với nhà cung cấp dịch vụ để khắc phục lỗi.
			|
			|Nội dung lỗi:
			|%1';
			|ru = '<b>Ошибка в настройках сервиса</b>
			|Обратитесь к провайдеру сервиса для устранения ошибки.
			|
			|Текст ошибки:
			|%1';
			|en = '<b>An error occurred in the service settings</b>
			|Contact the service owner to fix it.
			|
			|Error text:
			|%1'; fa = '<b>An error occurred in the service settings</b>
			|Contact the service owner to fix it.
			|
			|Error text:
			|%1';
			|it = '<b>Ошибка в настройках сервиса</b>
			|Обратитесь к провайдеру сервиса для устранения ошибки.
			|
			|Текст ошибки:
			|%1';
			|pl = '<b>An error occurred in the service settings</b>
			|Contact the service owner to fix it.
			|
			|Error text:
			|%1';
			|tr = '<b>Hizmet ayarlarında hata</b>
			|Hatayı çözmek için servis sağlayıcıyla iletişime geçin.
			|
			|Hata metni:
			|%1'"), Result.ErrorMessage);
		Return;
	EndIf; 
	
	Data = Result.Data.supportCompanies;
	For Each String In Data Do
		NewRow = ServiceCompanies.Add();
		NewRow.Code = String.id;
		NewRow.Description = String.name;
		NewRow.City = String.city;
		NewRow.Phone = String.phone;
		NewRow.Website1 = String.site;
		NewRow.Mail = String.email;
	EndDo; 
	
EndProcedure

&AtClientAtServerNoContext
Function SearchCriteriaAll()
	
	Return "all";
	
EndFunction

&AtServerNoContext
Function CheckQueryResultOnServer(JobID, StorageAddress)
	
	BackgroundJob = BackgroundJobs.FindByUUID(JobID);
	
	If BackgroundJob <> Undefined And BackgroundJob.State = BackgroundJobState.Active Then
		Return Undefined;
	
	ElsIf BackgroundJob <> Undefined And BackgroundJob.State = BackgroundJobState.Completed Then
		Return GetFromTempStorage(StorageAddress);
	ElsIf BackgroundJob <> Undefined And BackgroundJob.State = BackgroundJobState.Failed Then
		ErrorText = CloudTechnology.DetailedErrorText(BackgroundJob.ErrorInfo);
		Messages = BackgroundJob.GetUserMessages();
		For Each Message In Messages Do
			ErrorText = Message.Text + Chars.LF + ErrorText;
		EndDo;
		Raise ErrorText;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

#EndRegion 
